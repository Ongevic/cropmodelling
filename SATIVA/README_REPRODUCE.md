# Reproducing the hemp DSSAT results

## Status

The hemp runs now work on this machine with the installed `C:\DSSAT48\DSCSM048.EXE`.

The key fix was not recompiling the model. The important missing pieces were newer DSSAT metadata files that register hemp as a valid CROPGRO crop:

- `SIMULATION.CDE`
- `DETAIL.CDE`
- `DSSATPRO.v48`

These were synced from the official open-source DSSAT repository cloned into:

- `C:\Users\chich\Downloads\DSSAT Files\DSSAT Files\dssat-csm-os`
- `C:\Users\chich\Downloads\DSSAT Files\DSSAT Files\dssat-csm-data`

## One-command reproducibility check

Run:

```powershell
& "C:\Users\chich\Downloads\DSSAT Files\DSSAT Files\reproduce_hemp_results.ps1"
```

The script will:

1. Sync `Genotype`, `Soil`, `Weather`, and `Hemp` into `C:\DSSAT48`
2. Sync the official DSSAT metadata files from `dssat-csm-os\Data` when available
3. Ensure the hemp profile entries exist in `DSSATPRO.V48`
4. Rebuild `C:\DSSAT48\Hemp\DSSBatch.V48`
5. Run the smoke test for `UFHO0399`

## Verified outputs

The run now completes and writes standard DSSAT outputs in `C:\DSSAT48\Hemp`, including:

- `Summary.OUT`
- `Overview.OUT`
- `PlantGro.OUT`
- `Weather.OUT`
- `SoilWat.OUT`

## What changed in the installed DSSAT folder

These installed files were updated to hemp-aware versions:

- `C:\DSSAT48\SIMULATION.CDE`
- `C:\DSSAT48\DETAIL.CDE`
- `C:\DSSAT48\DSSATPRO.V48`

## If you set this up on another machine

You should copy both:

- your project input folders (`Hemp`, `Genotype`, `Soil`, `Weather`)
- the newer DSSAT metadata files from the official source tree

If you only copy the hemp experiment files, DSSAT may reject crop code `HM` even though the executable itself can run it.
