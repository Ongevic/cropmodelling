# DSSAT Archive Notes

This note tracks the DSSAT-related zip files copied from:

`C:\Users\chich\Downloads\_Sorted\Archives_Zips`

and extracted into:

`C:\Users\chich\Downloads\DSSAT Files\DSSAT Files\archive_work`

## Big Picture

These archives are not all the same kind of thing.

- Some are **installers**.
- Some are **wrappers** that automate DSSAT from R or Python.
- Some are **calibration projects** built on top of DSSAT.
- Some are **post-processing tools** for DSSAT outputs.
- Some are **toy or example experiments**.

So far, none of the extracted helper archives appear to contain a separate hidden hemp-enabled executable. They mostly assume DSSAT is already installed and working.

## Highest-Value Archives

### `DSSAT_v4.8.5_Install_12_01_2024.zip`

What it is:

- Official DSSAT installer bundle.
- Contains `Install DSSAT v4.8.5.exe`, `Setup.exe`, documentation, and an R installer.

Why it matters:

- Good reference for a clean DSSAT install.
- Useful if we want to compare your current `C:\DSSAT48` against a fresh official installation.

What it probably does **not** do by itself:

- It does not obviously expose hemp as a separate add-on in the zip listing.

### `DSSAT-wrapper-main.zip`

What it is:

- An R wrapper for using DSSAT with `CroptimizR` and `CroPlotR`.

Why it matters:

- Useful later for parameter calibration and model evaluation.
- Good candidate once your hemp workflow is stable and we want formal calibration.

What it is **not**:

- Not a DSSAT replacement.
- Not a crop module installer.

### `AgMIP-Calibration-Phase-III-main.zip`

What it is:

- A calibration framework for crop-model wrappers in R.
- Includes a DSSAT-CERES wrapper example.

Why it matters:

- Helpful for learning how calibration workflows are structured.
- More advanced and more generic than what we need for first-run setup.

What it is **not**:

- Not a direct fix for getting hemp to execute.

### `dssat-py-batchrunner-main.zip`

What it is:

- A Python batch runner for large-scale DSSAT workflows.
- Focused on gridded weather, NetCDF conversion, weather-file writing, batch creation, and output parsing.

Why it matters:

- Strong candidate if you later want many runs, climate scenarios, or automated weather generation.
- Good reference for writing your own DSSAT automation in Python.

What it is **not**:

- Not a bundled DSSAT executable.
- Not a hemp crop module.

### `PPDssat-master.zip`

What it is:

- Pre/post-processing scripts for DSSAT in Python.
- Mentions soil, climate, masks, `.CDE` files, `DSSATPRO`, and batch files.

Why it matters:

- Good reference for how others prepare weather/soil inputs and post-process outputs.
- Mentions modifying DSSAT source in some cases, which is useful context if we ever need model-code changes.

What it is **not**:

- Not a turnkey Windows setup for your current hemp folder.

## Medium-Value Archives

### `DSSATcorncalibration-master.zip`

What it is:

- A maize calibration example with real DSSAT experiment files and a `DSSBatch.v47`.

Why it matters:

- Very useful as a concrete example of how a calibration project is laid out.
- Good for learning file roles: experiment file, cultivar file, ecotype file, weather files, batch file.

Why it is limited for your case:

- It is maize-focused, not hemp-focused.

### `Sakha95-DSSAT-Calibration-DSSAT-Sakha95-CroptimizR--main.zip`

What it is:

- A complete calibration project built around DSSAT and CroptimizR.

Why it matters:

- Good end-to-end example of documentation, calibration scripts, and output review.

Why it is limited for your case:

- Crop- and dataset-specific, so it is more of a pattern to copy than a ready-made hemp tool.

### `DSSAT-summary-master.zip`

What it is:

- A project centered on reading and indexing DSSAT outputs like `OVERVIEW.OUT` and `PlantGro.OUT`.

Why it matters:

- Useful after runs succeed and you want structured summaries.

Why it is limited for your case:

- It helps after execution, not before execution.

### `weaana-master.zip`

What it is:

- An R package for weather analysis.

Why it matters:

- Could be useful for weather QA before building DSSAT `.WTH` files.

Why it is limited for your case:

- Not DSSAT-specific enough to solve the current setup problem.

## Low-Value Archives For Current Goal

### `DSSAT_course-main.zip`

What it is:

- A lightweight course repo with a simple R project and weather spreadsheets.

Why it matters:

- Good for learning and quick examples.

Why it is limited:

- Does not look like the key to your hemp execution problem.

### `DSSAT_SPATIAL-main.zip`

What it is:

- Tiny spatial helper repo with a single Python script.

Why it matters:

- Possibly useful as a lightweight example.

Why it is limited:

- Too small to be a full solution.

### `ddd_DSSAT.zip`

What it is:

- A tiny generated example containing a barley experiment file, a batch file, and a text summary.

Why it matters:

- Good for understanding the minimum anatomy of a simple DSSAT experiment package.

Why it is limited:

- Example only. Not relevant to hemp support.

## What We Learned

- Your hemp setup issue was not hiding inside these helper repos.
- Most of these archives assume a working DSSAT installation.
- The most practical archives for us are:
  - the official installer bundle
  - the R wrapper/calibration repos
  - the Python batch-runner repo
- None of the inspected helper archives obviously ship a hemp-specific binary or add-on crop module.

## Recommended Next Order

1. Compare your current `C:\DSSAT48` against a fresh official 4.8.5 install from the installer zip.
2. Keep the hemp metadata sync we already fixed (`SIMULATION.CDE`, `DETAIL.CDE`, `DSSATPRO.V48`) as the baseline.
3. Use one wrapper repo later for calibration, not for first boot.
4. Use `dssat-py-batchrunner` later if you want many automated scenario runs.
5. Use maize/wheat calibration example repos only as templates for folder structure and workflow.
