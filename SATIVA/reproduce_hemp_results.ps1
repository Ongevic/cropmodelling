# Reproducible setup and smoke test for the hemp DSSAT experiments.
param(
    [string]$ProjectRoot = "C:\Users\chich\Downloads\DSSAT Files\DSSAT Files",
    [string]$DssatRoot = "C:\DSSAT48",
    [string]$SourceDataRoot = "C:\Users\chich\Downloads\DSSAT Files\DSSAT Files\dssat-csm-os\Data",
    [string]$Experiment = "UFHO0399",
    [int[]]$Treatments = @(1,2,3,4,5,6,7,8,9)
)

$ErrorActionPreference = "Stop"

function Ensure-ProfileEntry {
    param(
        [string]$ProfilePath,
        [string]$Entry
    )

    $content = Get-Content -LiteralPath $ProfilePath
    if ($content -notcontains $Entry) {
        Add-Content -LiteralPath $ProfilePath -Value $Entry
        Write-Host "Added DSSAT profile entry: $Entry"
    }
    else {
        Write-Host "DSSAT profile entry already present: $Entry"
    }
}

function Copy-ProjectFolder {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Missing source folder: $SourcePath"
    }

    New-Item -ItemType Directory -Force -Path $DestinationPath | Out-Null
    Get-ChildItem -LiteralPath $SourcePath -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $DestinationPath -Recurse -Force
    }
    Write-Host "Synced $SourcePath -> $DestinationPath"
}

function Sync-OptionalFile {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )

    if (Test-Path -LiteralPath $SourcePath) {
        Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
        Write-Host "Synced $SourcePath -> $DestinationPath"
    }
    else {
        Write-Host "Optional source file not found, leaving existing file in place: $SourcePath"
    }
}

$profilePath = Join-Path $DssatRoot "DSSATPRO.V48"
$hempDir = Join-Path $DssatRoot "Hemp"
$batchPath = Join-Path $hempDir "DSSBatch.V48"
$exePath = Join-Path $DssatRoot "DSCSM048.EXE"

if (-not (Test-Path -LiteralPath $profilePath)) {
    throw "Could not find DSSAT profile: $profilePath"
}

if (-not (Test-Path -LiteralPath $exePath)) {
    throw "Could not find DSSAT executable: $exePath"
}

Copy-ProjectFolder -SourcePath (Join-Path $ProjectRoot "Genotype") -DestinationPath (Join-Path $DssatRoot "Genotype")
Copy-ProjectFolder -SourcePath (Join-Path $ProjectRoot "Soil") -DestinationPath (Join-Path $DssatRoot "Soil")
Copy-ProjectFolder -SourcePath (Join-Path $ProjectRoot "Weather") -DestinationPath (Join-Path $DssatRoot "Weather")
Copy-ProjectFolder -SourcePath (Join-Path $ProjectRoot "Hemp") -DestinationPath $hempDir

Sync-OptionalFile -SourcePath (Join-Path $SourceDataRoot "SIMULATION.CDE") -DestinationPath (Join-Path $DssatRoot "SIMULATION.CDE")
Sync-OptionalFile -SourcePath (Join-Path $SourceDataRoot "DETAIL.CDE") -DestinationPath (Join-Path $DssatRoot "DETAIL.CDE")
Sync-OptionalFile -SourcePath (Join-Path $SourceDataRoot "DSSATPRO.v48") -DestinationPath $profilePath

Ensure-ProfileEntry -ProfilePath $profilePath -Entry "HMD C: \DSSAT48\Hemp"
Ensure-ProfileEntry -ProfilePath $profilePath -Entry "MHM C: \DSSAT48 DSCSM048.EXE CRGRO048"

$batchLines = @(
    '$BATCH',
    '@FILEX                                                                                        TRTNO     RP     SQ     OP     CO'
)

foreach ($treatment in $Treatments) {
    $batchLines += ('{0,-90}{1,6}{2,7}{3,7}{4,7}{5,7}' -f "$Experiment.HMX", $treatment, 1, 0, 0, 0)
}

Set-Content -LiteralPath $batchPath -Value $batchLines
Write-Host "Wrote batch file: $batchPath"

Push-Location $hempDir
try {
    $runOutput = & $exePath B "DSSBatch.V48" 2>&1 | Out-String
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "----- DSSAT run output -----"
Write-Host $runOutput.Trim()
Write-Host "----------------------------"
Write-Host ""

$warningPath = Join-Path $hempDir "WARNING.OUT"
$errorPath = Join-Path $hempDir "ERROR.OUT"

if (Test-Path -LiteralPath $warningPath) {
    $warningText = Get-Content -LiteralPath $warningPath -Raw
    if ($warningText -match "Crop code incompatible with model specified") {
        Write-Warning "The installed DSCSM048.EXE does not support the hemp crop code used by these experiments."
        Write-Warning "You still need the hemp-enabled DSSAT executable/build that created the original results."
        exit 2
    }
}

if (Test-Path -LiteralPath $errorPath) {
    $errorText = Get-Content -LiteralPath $errorPath -Raw
    if ($errorText -match "RUN-TIME ERRORS OUTPUT FILE" -and $errorText -notmatch "^\*RUN-TIME ERRORS OUTPUT FILE\s*$") {
        Write-Warning "DSSAT produced ERROR.OUT. Review: $errorPath"
        exit 1
    }
}

Write-Host "Smoke test completed without the hemp compatibility error."
