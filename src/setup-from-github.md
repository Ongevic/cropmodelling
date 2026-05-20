# Using GitHub-Sourced Example Data

You do not need every experiment file to live inside the DSSAT installation
folder.

A common pattern is:

- keep DSSAT installed locally
- clone or download an example-data repository
- point `project_file` to the external experiment file
- optionally set `Crop`
- optionally set `module_code`

## Example layout

```text
C:/work/
  DSSAT48/
  dssat-csm-data/
```

## Example: alternate maize engine

```r
source("C:/path/to/DSSAT-wrapper/R/DSSAT_omniwrapper.R")

result <- DSSAT_omniwrapper(
  model_options = list(
    DSSAT_path = "C:/work/DSSAT48",
    DSSAT_exe = "DSCSM048.EXE",
    Crop = "Maize",
    project_file = "C:/work/dssat-csm-data/Maize/UFGA8201.MZX",
    module_code = "MZIXM048",
    suppress_output = TRUE
  ),
  situation = "UFGA8201_1",
  var = "CWAD"
)
```

## Example: wheat with NWHEAT

```r
result <- DSSAT_omniwrapper(
  model_options = list(
    DSSAT_path = "C:/work/DSSAT48",
    DSSAT_exe = "DSCSM048.EXE",
    Crop = "Wheat",
    project_file = "C:/work/dssat-csm-data/Wheat/KSAS8101.WHX",
    module_code = "WHAPS048",
    suppress_output = TRUE
  ),
  situation = "KSAS8101_1",
  var = "GSTD"
)
```

## Why this works

The omniwrapper stages a temporary run directory and copies in the files DSSAT
needs for that run:

- the experiment file
- companion `*.A` and `*.T` files when present
- genotype files from the local DSSAT installation or the project folder

That means your source-data checkout stays clean and DSSAT still runs from the
local executable.

## Good practice

- Keep DSSAT itself installed locally.
- Treat GitHub example repositories as input-data sources.
- Do not hard-code personal paths in scripts you plan to share.
- Use placeholders like `C:/path/to/...` in public documentation.
