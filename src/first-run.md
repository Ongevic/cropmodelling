# Your First Run

This chapter shows the shortest useful path from a fresh machine to a working
DSSAT run from R.

## Step 1: Prepare the prerequisites

You need:

- R installed
- DSSAT installed locally
- this wrapper repository available locally

For example:

- DSSAT at `C:/path/to/DSSAT48`
- the repo in any local folder

## Step 2: Install R packages

Run:

```r
install.packages(c("DSSAT", "dplyr", "tidyr", "lubridate"))
```

These are the minimum packages used by the wrapper core.

## Step 3: Source the omniwrapper

This step assumes you have also cloned the DSSAT-wrapper module separately.

For example:

- `C:/path/to/DSSAT-wrapper`

```r
source("C:/path/to/DSSAT-wrapper/R/DSSAT_omniwrapper.R")
```

This loads the public function and the helper modules behind it.

## Step 4: Choose a known-good example

A good first example is a shipped DSSAT case that is already validated.

For instance:

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

## Step 5: Inspect the result

```r
names(result)
names(result$sim_list)
head(result$sim_list[["KSAS8101_1"]])
```

At this point, the main question is not yet "does the biology look perfect?"

The main question is:

"Did the wrapper successfully identify the model context, launch DSSAT, and read
the outputs back?"

## Step 6: Read observations if available

```r
obs <- DSSAT_omni_read_obs(
  model_options = list(
    DSSAT_path = "C:/path/to/DSSAT48",
    DSSAT_exe = "DSCSM048.EXE",
    project_file = "C:/path/to/DSSAT48/Wheat/KSAS8101.WHX"
  ),
  situation = "KSAS8101_1",
  read_end_season = TRUE
)
```

This is the bridge between "a run works" and "a run can be evaluated."

## Common beginner mistakes

### Using the wrong project file

Make sure the file extension and crop family make sense for the case you want to run.

### Pointing only to copied crop inputs

Some crops also require install-level metadata to be present and consistent.

### Confusing crop choice with module choice

Some crops have alternate engines. If a non-default engine is required, you may
need to provide `module_code`.

Example:

```r
module_code = "WHAPS048"
```

## What to do if the first run fails

Do not immediately start editing coefficients.

Instead:

1. run the self-check
2. verify the project file path
3. verify the DSSAT install path
4. verify that the required genotype files exist
5. check whether the example is supposed to use a non-default engine

That sequence saves a lot of time.
