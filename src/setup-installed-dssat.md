# Installed DSSAT Setup

This path is the simplest if DSSAT is already installed on your machine.

## Requirements

- a local DSSAT installation
- R
- the required R packages:
  - `DSSAT`
  - `dplyr`
  - `tidyr`
  - `lubridate`

Install the R packages if needed:

```r
install.packages(c("DSSAT", "dplyr", "tidyr", "lubridate"))
```

## Source the wrapper

From your local DSSAT-wrapper clone:

```r
source("C:/path/to/DSSAT-wrapper/R/DSSAT_omniwrapper.R")
```

## Minimal example

```r
result <- DSSAT_omniwrapper(
  model_options = list(
    DSSAT_path = "C:/path/to/DSSAT48",
    DSSAT_exe = "DSCSM048.EXE",
    project_file = "C:/path/to/DSSAT48/Wheat/KSAS8101.WHX",
    suppress_output = TRUE
  ),
  situation = "KSAS8101_1",
  var = "GSTD"
)
```

## What the wrapper needs

At minimum, the omniwrapper expects:

- `DSSAT_path`
- `project_file`

It can often infer:

- crop code
- crop folder
- default module
- genotype file names

## When to provide `Crop`

Provide `Crop` when the experiment file lives outside the installed DSSAT crop
folder and the wrapper should know which installed crop directory to stage
against.

## When to provide `module_code`

Provide `module_code` when you want to force an alternate engine instead of the
default module in the DSSAT profile. Examples:

- `MZIXM048`
- `WHAPS048`
- `TFAPS048`
- `SUOIL048`
- `SCCSP048`
- `SCSAM048`

## Basic validation

You can run the bundled smoke test:

```powershell
Rscript C:\path\to\DSSAT-wrapper\R\test_DSSAT_omniwrapper.R
```

And the broader family validator:

```powershell
Rscript C:\path\to\DSSAT-wrapper\R\validate_DSSAT_omniwrapper_families.R
```
