# DSSAT Wrapper Investigation

This note compares:

- your local wrapper: `C:\Users\chich\Downloads\calib\wrappers\DSSAT\DSSAT_SUBSTOR_wrapper.R`
- the general wrapper repo: `archive_work\DSSAT-wrapper-main\DSSAT-wrapper-main\R\DSSAT_wrapper.R`
- the Sakha95 calibration project: `archive_work\Sakha95-DSSAT-Calibration-DSSAT-Sakha95-CroptimizR--main`

## Short Answer

No, the current wrappers do **not** cover all DSSAT crops as-is.

An "omniwrapper" is possible, but it should not be a single flat wrapper with hard-coded assumptions. It should be a **meta-wrapper** with:

1. a shared core for launching DSSAT and reading generic outputs
2. crop-family adapters for genotype files, identifiers, observations, and outputs
3. optional crop-specific post-processors

## What Each Wrapper Really Is

### 1. General `DSSAT_wrapper.R`

This is the closest thing to a generic DSSAT wrapper, but it is only generic within limits.

Main assumptions visible in the code:

- requires `ecotype_filename` and `cultivar_filename`
- derives crop code from `ecotype_filename`
- edits `.ECO` and `.CUL` files directly
- identifies ecotype by `ECO#`
- identifies cultivar by `VAR-NAME`
- expects `PlantGro.OUT` as a core output
- adds wheat-specific handling for `PlantGr2.OUT`
- computes `Zadok1...Zadok100` from `GSTD`

Important code references:

- [DSSAT_wrapper.R](/C:/Users/chich/Downloads/DSSAT%20Files/DSSAT%20Files/archive_work/DSSAT-wrapper-main/DSSAT-wrapper-main/R/DSSAT_wrapper.R:122)
- [DSSAT_wrapper.R](/C:/Users/chich/Downloads/DSSAT%20Files/DSSAT%20Files/archive_work/DSSAT-wrapper-main/DSSAT-wrapper-main/R/DSSAT_wrapper.R:146)
- [DSSAT_wrapper.R](/C:/Users/chich/Downloads/DSSAT%20Files/DSSAT%20Files/archive_work/DSSAT-wrapper-main/DSSAT-wrapper-main/R/DSSAT_wrapper.R:174)
- [DSSAT_wrapper.R](/C:/Users/chich/Downloads/DSSAT%20Files/DSSAT%20Files/archive_work/DSSAT-wrapper-main/DSSAT-wrapper-main/R/DSSAT_wrapper.R:201)
- [DSSAT_wrapper.R](/C:/Users/chich/Downloads/DSSAT%20Files/DSSAT%20Files/archive_work/DSSAT-wrapper-main/DSSAT-wrapper-main/R/DSSAT_wrapper.R:265)
- [DSSAT_wrapper.R](/C:/Users/chich/Downloads/DSSAT%20Files/DSSAT%20Files/archive_work/DSSAT-wrapper-main/DSSAT-wrapper-main/R/DSSAT_wrapper.R:331)

What that means:

- It works best for crops that behave like the wheat example it was built around.
- It is not fully crop-agnostic.

### 2. Your `DSSAT_SUBSTOR_wrapper.R`

This is a specialized wrapper for SUBSTOR-Potato.

Main assumptions:

- title explicitly says `SUBSTOR-Potato`
- requires a `project_file`
- edits `.ECO` and `.CUL`
- identifies cultivar by `VAR#`, not `VAR-NAME`
- still expects `PlantGro.OUT`
- still computes Zadok-style outputs from `GSTD`
- maps `TWAD -> HWAM`
- maps `E#AD/E.AD -> TUBN`

Important code references:

- [DSSAT_SUBSTOR_wrapper.R](/C:/Users/chich/Downloads/calib/wrappers/DSSAT/DSSAT_SUBSTOR_wrapper.R:1)
- [DSSAT_SUBSTOR_wrapper.R](/C:/Users/chich/Downloads/calib/wrappers/DSSAT/DSSAT_SUBSTOR_wrapper.R:30)
- [DSSAT_SUBSTOR_wrapper.R](/C:/Users/chich/Downloads/calib/wrappers/DSSAT/DSSAT_SUBSTOR_wrapper.R:116)
- [DSSAT_SUBSTOR_wrapper.R](/C:/Users/chich/Downloads/calib/wrappers/DSSAT/DSSAT_SUBSTOR_wrapper.R:126)
- [DSSAT_SUBSTOR_wrapper.R](/C:/Users/chich/Downloads/calib/wrappers/DSSAT/DSSAT_SUBSTOR_wrapper.R:197)
- [DSSAT_SUBSTOR_wrapper.R](/C:/Users/chich/Downloads/calib/wrappers/DSSAT/DSSAT_SUBSTOR_wrapper.R:213)

What that means:

- It is more robust for your specific potato calibration case.
- It is not a universal wrapper.

### 3. Sakha95 project

The Sakha95 project does **not** provide a new generic wrapper.

It is a crop-specific wheat calibration workflow that sources an existing DSSAT wrapper:

- [calibrate_Sakha95_FINAL_CORRECTED.R](/C:/Users/chich/Downloads/DSSAT%20Files/DSSAT%20Files/archive_work/Sakha95-DSSAT-Calibration-DSSAT-Sakha95-CroptimizR--main/Sakha95-DSSAT-Calibration-DSSAT-Sakha95-CroptimizR--main/calibrate_Sakha95_FINAL_CORRECTED.R:29)
- [calibrate_Sakha95_FINAL_CORRECTED.R](/C:/Users/chich/Downloads/DSSAT%20Files/DSSAT%20Files/archive_work/Sakha95-DSSAT-Calibration-DSSAT-Sakha95-CroptimizR--main/Sakha95-DSSAT-Calibration-DSSAT-Sakha95-CroptimizR--main/calibrate_Sakha95_FINAL_CORRECTED.R:42)

It is valuable because it exposes another real-world problem:

- cultivar identifiers are not always handled the same way
- this script explicitly mentions `VRNAME` vs `VAR-NAME`

That is a warning sign for omniwrapper design.

## Why All Crops Are Not Covered

### Reason 1. Not all genotype packages share the same file pattern

From `C:\DSSAT48\Genotype`, many crops have:

- `.CUL`
- `.ECO`
- `.SPE`

But some do **not** have `.ECO`, for example:

- `PIALO048`
- `RICER048`
- `TFCER048`
- `TNARO048`
- `TRARO048`

So a wrapper that requires `ecotype_filename` is already excluding some crop families.

### Reason 2. Cultivar identifiers are inconsistent

The general wrapper looks up cultivar with `VAR-NAME`:

- [DSSAT_wrapper.R](/C:/Users/chich/Downloads/DSSAT%20Files/DSSAT%20Files/archive_work/DSSAT-wrapper-main/DSSAT-wrapper-main/R/DSSAT_wrapper.R:201)

Your local wrapper looks up cultivar with `VAR#`:

- [DSSAT_SUBSTOR_wrapper.R](/C:/Users/chich/Downloads/calib/wrappers/DSSAT/DSSAT_SUBSTOR_wrapper.R:126)

The Sakha95 workflow had to explicitly deal with `VRNAME` versus `VAR-NAME`.

So a true omniwrapper cannot assume one cultivar-key convention.

### Reason 3. Phenology/output assumptions are crop-family biased

The general wrapper computes `Zadok` stages from `GSTD`:

- [DSSAT_wrapper.R](/C:/Users/chich/Downloads/DSSAT%20Files/DSSAT%20Files/archive_work/DSSAT-wrapper-main/DSSAT-wrapper-main/R/DSSAT_wrapper.R:331)

That makes sense for cereals and similar workflows, but not as a universal abstraction for all DSSAT crops.

### Reason 4. Observation-file assumptions are narrow

`read_obs.R` builds crop code from `ecotype_filename` and expects `.T` and `.A` observations in a specific pattern:

- [read_obs.R](/C:/Users/chich/Downloads/DSSAT%20Files/DSSAT%20Files/archive_work/DSSAT-wrapper-main/DSSAT-wrapper-main/R/read_obs.R:52)
- [read_obs.R](/C:/Users/chich/Downloads/DSSAT%20Files/DSSAT%20Files/archive_work/DSSAT-wrapper-main/DSSAT-wrapper-main/R/read_obs.R:74)
- [read_obs.R](/C:/Users/chich/Downloads/DSSAT%20Files/DSSAT%20Files/archive_work/DSSAT-wrapper-main/DSSAT-wrapper-main/R/read_obs.R:82)

That is useful, but still not universal.

## Can We Build an Omniwrapper?

Yes, but the right design is:

- one **core engine**
- several **crop-family adapters**

### Suggested architecture

#### Layer 1. Core DSSAT runner

Responsibilities:

- create temp run directory
- copy experiment files
- write batch file
- run DSSAT executable
- collect output files
- report errors cleanly

This layer should know nothing about wheat, potato, hemp, rice, or Zadok stages.

#### Layer 2. Genotype adapter

Responsibilities:

- determine whether crop uses `.CUL` only or `.CUL + .ECO`
- locate cultivar and ecotype rows
- know whether cultivar key is `VAR#`, `VAR-NAME`, `VRNAME`, or something else
- apply parameter updates safely

This is where crop-family differences belong.

#### Layer 3. Observation adapter

Responsibilities:

- locate `.T`, `.A`, `.X`, or other relevant files
- map experiment/treatment naming
- normalize dates and variable names

#### Layer 4. Output adapter

Responsibilities:

- read `PlantGro.OUT`, `Evaluate.OUT`, and optional crop-specific outputs
- define crop-specific derived variables
- only compute Zadok stages for crops where that concept is valid

## Practical Conclusion

### What is realistic

Realistic:

- a shared DSSAT meta-wrapper covering many DSSAT crops
- a registry of crop adapters
- a fallback generic mode for simple crops

Not realistic:

- one tiny wrapper function with no crop-specific logic at all

### Best first target

A good first version would support:

1. CERES family
2. CROPGRO family
3. SUBSTOR family
4. APSIM-style odd cases later if needed

For your work, that would already be enough to cover a very large share of practical DSSAT use, including hemp if the genotype/output conventions are handled properly.

## Recommendation

If we build this, we should start with:

1. a clean shared core runner
2. a `CERES` adapter
3. a `CROPGRO` adapter
4. your `SUBSTOR` adapter folded in as a third family adapter
5. a crop registry table that maps crop code to:
   - crop folder
   - genotype files
   - identifier columns
   - default outputs
   - derived-variable rules

That would give us a real omniwrapper design instead of a fragile one-off script.
