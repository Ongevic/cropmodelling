# Denmark ISIMIP Workflow Walkthrough

This chapter records what we actually did to build the Denmark weather
deliverables, which scripts were involved, where they lived on the remote HPC,
what outputs were produced, and how the soil side should be structured if we
later extend the Denmark project using the Ethiopia soil-first pattern.

The goal is not just to say "the files were made." The goal is to leave a
traceable map that another researcher or intern can follow.

## The main question we answered

The practical Denmark question was:

"Can we take ISIMIP climate data for Denmark and push it all the way to
DSSAT-ready weather outputs, using a workflow that can later be paired with a
proper soil pipeline?"

The answer became yes.

By the end of the work, we had:

- processed Denmark climate NetCDF files in crop-model units
- parquet zonal summaries
- TAV and AMP outputs
- DSSAT `.WTH` files
- repaired elevation headers
- validation of processed units

## The real project locations

### Denmark climate and weather project on HPC

- `/home/<user>/DEN`
- `/home/<user>/DEN/denmark`

The `denmark` folder was created as a clean project wrapper so we would not
have to move heavy climate data around unnecessarily.

### Ethiopia soil reference project on HPC

- `/home/<user>/Ethiopia`
- `/home/<user>/Ethiopia/soil_data`

This Ethiopia project is important because it already demonstrates the
soil-first pattern that we want future projects to follow.

## What already existed before the Denmark cleanup

Before the cleanup and restructuring, Denmark already had important raw and
processed ingredients:

- Denmark shapefiles under `/home/<user>/DEN/shapefiles`
- Denmark COP30 DEM tiles under `/home/<user>/DEN/COP30`
- processed ISIMIP climate NetCDFs under each model's `processed/` folder
- legacy zonal outputs under `/home/<user>/DEN/zonal_stats`

Those legacy zonal outputs were not yet in the Ethiopia-style parquet layout.
They existed mostly as per-grid Excel outputs.

## The Denmark wrapper we built

We created a clean wrapper at:

- `/home/<user>/DEN/denmark`

Inside that wrapper we organized:

- `/home/<user>/DEN/denmark/scripts`
- `/home/<user>/DEN/denmark/docs`
- `/home/<user>/DEN/denmark/config`
- `/home/<user>/DEN/denmark/deliverables`
- `/home/<user>/DEN/denmark/logs`

This mattered because it separated:

- large source data that already existed
- lightweight workflow code
- final deliverables
- validation outputs

## The Denmark scripts we used

These are the numbered workflow scripts we set up for Denmark:

- `/home/<user>/DEN/denmark/scripts/01_download_isimip.sh`
- `/home/<user>/DEN/denmark/scripts/02_prepare_shapefiles_and_grid.sh`
- `/home/<user>/DEN/denmark/scripts/03_create_denmark_grid.py`
- `/home/<user>/DEN/denmark/scripts/04_prepare_dem.sh`
- `/home/<user>/DEN/denmark/scripts/05_merge_clip_convert_climate.sh`
- `/home/<user>/DEN/denmark/scripts/06_compute_tav_amp.py`
- `/home/<user>/DEN/denmark/scripts/07_extract_zonal_stats_parquet.py`
- `/home/<user>/DEN/denmark/scripts/08_generate_wth_files.py`
- `/home/<user>/DEN/denmark/scripts/09_validate_outputs.py`
- `/home/<user>/DEN/denmark/scripts/10_run_model_scenario_weather.sh`
- `/home/<user>/DEN/denmark/scripts/11_submit_denmark_weather.sh`

## What each Denmark script did

### 01_download_isimip.sh

This is the placeholder entry for climate acquisition.

In practice, much of the Denmark climate data already existed under model
folders, so the project did not depend on a fresh redownload to finish the
weather pipeline.

### 02_prepare_shapefiles_and_grid.sh

This script represents the shapefile preparation stage.

Conceptually this stage ties together:

- Denmark extent
- Denmark 0.5 degree grid
- the grid-cell logic that later drives zonal extraction and WTH station IDs

### 03_create_denmark_grid.py

This is the grid-construction step.

It formalizes the Denmark climate grid as the geographic framework against which
climate and later soil can be mapped.

### 04_prepare_dem.sh

This script prepared the Denmark DEM support raster used for WTH elevation.

It produced the merged DEM used in the workflow:

- `/home/<user>/DEN/denmark/deliverables/validation/denmark_dem_merged.tif`

This step mattered because the WTH headers need defensible elevation values.

### 05_merge_clip_convert_climate.sh

This was the bridge from raw model outputs to processed Denmark climate files.

The underlying climate conversion logic matched the older project script:

- merge yearly files
- clip to Denmark extent
- convert variables to crop-model units

The effective unit targets were:

- `pr` -> `mm/day`
- `tas` -> `degC`
- `tasmax` -> `degC`
- `tasmin` -> `degC`
- `rsds` -> `MJ m-2 day-1`

### 06_compute_tav_amp.py

This script computed DSSAT header climatology summaries:

- TAV
- AMP

It reads processed `tasmax` and `tasmin`, aligns them by date, and writes:

- `/home/<user>/DEN/denmark/deliverables/tav_amp/{MODEL}/{SCENARIO}/{PERIOD}/tav_amp.csv`

### 07_extract_zonal_stats_parquet.py

This script converted processed Denmark NetCDF climate variables into
Ethiopia-style zonal parquet outputs.

It writes outputs such as:

- `/home/<user>/DEN/denmark/deliverables/parquet_zonal_stats/{MODEL}/{SCENARIO}/{PERIOD}/pr/pr.parquet`
- `/home/<user>/DEN/denmark/deliverables/parquet_zonal_stats/{MODEL}/{SCENARIO}/{PERIOD}/tasmax/tasmax.parquet`
- `/home/<user>/DEN/denmark/deliverables/parquet_zonal_stats/{MODEL}/{SCENARIO}/{PERIOD}/tasmin/tasmin.parquet`
- `/home/<user>/DEN/denmark/deliverables/parquet_zonal_stats/{MODEL}/{SCENARIO}/{PERIOD}/rsds/rsds.parquet`

This was the key format bridge that let us move from NetCDF to WTH generation.

### 08_generate_wth_files.py

This script assembled the final DSSAT weather files.

It merged the parquet variables:

- `pr`
- `tasmax`
- `tasmin`
- `rsds`

Then it wrote DSSAT `.WTH` files into:

- `/home/<user>/DEN/denmark/deliverables/wth/{MODEL}/{SCENARIO}/{PERIOD}`

It also handled:

- station header coordinates
- TAV and AMP
- DEM-based elevation

Later we repaired this script so that zero-elevation coastal cells would borrow
the nearest valid land-based elevation instead of remaining at `0 m`.

### 09_validate_outputs.py

This script counted the main deliverables:

- parquet files
- WTH files
- TAV and AMP files

It was useful for fast completeness checks during batch reruns.

### 10_run_model_scenario_weather.sh

This was the per-model, per-scenario orchestration script.

It did:

1. determine the time span from processed `pr`
2. compute TAV and AMP
3. build all parquet variables
4. generate WTH files

This script made it easy to re-run only one broken scenario after a repair.

### 11_submit_denmark_weather.sh

This was the batch submission wrapper for the cluster.

It was used to submit the multi-model, multi-scenario Denmark weather runs.

## The main climate processing logic we followed

The Denmark weather build followed this chain:

1. use the existing processed model folders under `/home/<user>/DEN`
2. ensure the processed NetCDF values were in DSSAT-ready units
3. prepare a merged Denmark DEM for elevation support
4. compute TAV and AMP
5. convert daily climate grids to zone-level parquet summaries
6. generate WTH files for each Denmark grid cell
7. validate units, counts, and headers

## Problems we had to repair

The work was not a simple one-pass run.

We had to repair real issues.

### 1. Broken batch dependencies and environment issues

Early jobs were stuck behind dependency logic or failed because the right
geospatial environment was not consistently activated.

We fixed that by making the wrapper scripts explicit about:

- Python interpreter
- `PROJ_LIB`
- `PATH`
- environment cleanup

### 2. Broken processed files for MPI-ESM1-2-HR ssp370

These files were genuinely corrupted and had to be rebuilt from raw inputs:

- `/home/<user>/DEN/MPI-ESM1-2-HR/processed/MPI-ESM1-2-HR_ssp370_tasmin_denmark.nc`
- `/home/<user>/DEN/MPI-ESM1-2-HR/processed/MPI-ESM1-2-HR_ssp370_rsds_denmark.nc`

They were reconstructed using the same logic as the main climate processing
step:

- merge raw decade files
- clip to Denmark
- convert to the correct units

### 3. Duplicate parquet and TAV/AMP test artifacts

During iteration we created a few stale outputs from older path logic.

These were later cleaned so the final deliverables reflected only the intended
production runs.

### 4. Zero-elevation WTH headers

Many coastal Denmark grid cells initially got `ELEV = 0`.

This happened because centroid sampling and some polygon means landed in very
water-dominated cells.

We fixed that by improving the elevation fallback logic in:

- `/home/<user>/DEN/denmark/scripts/08_generate_wth_files.py`

The final fallback order became:

1. land-intersection centroid DEM sample
2. land-polygon mean
3. land-polygon max
4. nearest grid cell with a valid land-based elevation

## Final Denmark weather results

The Denmark weather deliverables finished cleanly.

Final validated counts were:

- `80` parquet files
- `1160` WTH files
- `20` TAV/AMP files

That corresponds to:

- `5` models
- `4` scenarios each
- `20` model-scenario combinations
- `58` WTH files per combination

Key validation outputs:

- `/home/<user>/DEN/denmark/deliverables/validation/processed_units_validation.csv`
- `/home/<user>/DEN/denmark/deliverables/validation/denmark_dem_merged.tif`

Key bundled deliverables:

- `/home/<user>/DEN/denmark/deliverables/denmark_wth_bundle.tar.gz`

## What we proved about the processed climate files

We validated all `100` processed climate files across:

- `pr`
- `tas`
- `tasmax`
- `tasmin`
- `rsds`

Final result:

- `100/100` files passed unit and range checks

The final expected units were:

- `pr`: `mm/day`
- `tas`: `degC`
- `tasmax`: `degC`
- `tasmin`: `degC`
- `rsds`: `MJ m-2 day-1`

## The Ethiopia soil-first pattern we should imitate

The Ethiopia project is the best reference for how soil should be prepared in a
more model-agnostic and reusable way.

The core soil workflow is documented at:

- `/home/<user>/Ethiopia/soil_data/docs/soil_first_workflow.md`
- `/home/<user>/Ethiopia/soil_data/docs/soil_hydraulics_runoff.md`

Its core idea is simple:

- keep one authoritative processed soil backbone
- export DSSAT, APSIM, and STICS from that same backbone

Important precision note:

- in the current HPC tree, the documented Ethiopia soil workflow is easiest to
  confirm through the files under `/home/<user>/Ethiopia/soil_data`
  rather than through a complete set of matching upstream script files
- the docs clearly describe the producer scripts by name, but the present
  walkthrough only treats the existing `soil_data` files and docs as confirmed
  paths unless a script path was directly observed

### Ethiopia authoritative soil backbone

The files to treat as source of truth are:

- `/home/<user>/Ethiopia/soil_data/processed/final_soil_profile_all_points.csv`
- `/home/<user>/Ethiopia/soil_data/processed/HWSD2_hydraulic_parameters_from_profile.csv`
- `/home/<user>/Ethiopia/soil_data/processed/soil_with_slro.csv`
- `/home/<user>/Ethiopia/soil_data/processed/horizon.csv`

In the current Ethiopia tree we directly confirmed at least:

- `/home/<user>/Ethiopia/soil_data/processed/soil_with_slro.csv`
- `/home/<user>/Ethiopia/soil_data/processed/horizon.csv`

### Ethiopia downstream soil exports

- DSSAT soil file:
  `/home/<user>/Ethiopia/soil_data/dssat/ET.SOL`
- APSIM soils:
  `/home/<user>/Ethiopia/soil_data/apsim/soils/*.json`
- STICS soils:
  `/home/<user>/Ethiopia/soil_data/stics/sols.xml`

This is exactly the pattern worth copying.

## What the Denmark soil side should look like

If Denmark soil preparation is added later, it should not start from DSSAT
format first.

It should start from a model-agnostic processed soil core and then export to
model-specific products.

### Recommended Denmark soil project layout

- `/home/<user>/DEN/soil_data/raw`
- `/home/<user>/DEN/soil_data/processed`
- `/home/<user>/DEN/soil_data/docs`
- `/home/<user>/DEN/soil_data/reports`
- `/home/<user>/DEN/soil_data/dssat`
- `/home/<user>/DEN/soil_data/apsim`
- `/home/<user>/DEN/soil_data/stics`

### Recommended authoritative Denmark processed soil tables

At minimum, Denmark should end up with processed tables analogous to Ethiopia:

- `final_soil_profile_all_points.csv`
- `hydraulic_parameters_from_profile.csv`
- `soil_with_slro.csv`
- `horizon.csv`

### Recommended Denmark DSSAT output

One final DSSAT soil file such as:

- `DN.SOL`

or an equivalent country-specific `.SOL` file containing all Denmark station
profiles.

### Recommended Denmark per-station profile logic

Each station or grid cell should ultimately have:

- point or grid identifier
- coordinates
- layer bottoms
- sand, silt, clay
- bulk density
- organic carbon
- pH if available
- hydraulic limits such as lower limit, drained upper limit, saturation
- runoff/slope enrichment such as `SLRO`
- root-limiting depth or impermeable-layer depth where available

## What ISIMIP soil input data actually provides

For ISIMIP3 soil input data, the official DOI page states that two newer HWSD
1.2-based files are provided:

- `hwsd_soil_data_all_land.nc`
- `hwsd_soil_data_on_cropland.nc`

For agriculture work, the important one is usually:

- `hwsd_soil_data_on_cropland.nc`

because it represents the soil predominantly occurring on cropland within each
grid cell.

The DOI metadata also states that these files provide fields such as:

- `texture_class`
- `mu_global`
- `soil_ph`
- `soil_caco3`
- `bulk_density`
- `cec_soil`
- `oc`
- `root_obstacles`
- `impermeable_layer`
- `awc`
- `sand`
- `silt`
- `clay`
- `gravel`
- `ece`
- `bs_soil`
- `issoil`

That means ISIMIP soil input data is not already a DSSAT `.SOL` file.

It is an upstream static geographic soil dataset that still needs to be turned
into:

- a canonical processed soil table
- hydraulic estimates or pedotransfer outputs
- runoff or slope enrichments
- final model exports

## What that means for a Denmark soil build

If we want to build Denmark soil inputs inspired by the Ethiopia project, the
correct logic is:

1. start from an ISIMIP soil NetCDF, ideally cropland-focused if the target is
   crop modeling
2. sample the soil properties to the Denmark grid or station points
3. create a canonical processed table with one row per layer per station
4. derive hydraulic quantities that DSSAT needs
5. add slope/runoff support from the DEM if needed
6. create a final `horizon.csv` or equivalent initialization table
7. export a Denmark `.SOL` file for DSSAT
8. optionally export APSIM and STICS soils from the same processed backbone

## The key lesson from the Denmark weather work

The weather pipeline succeeded because it had a disciplined chain:

- one clear wrapper
- numbered scripts
- validated units
- validated counts
- explicit deliverables

The soil pipeline should follow the same discipline.

The strongest future design is therefore:

- weather: NetCDF -> parquet -> WTH
- soil: ISIMIP/HWSD-like source -> processed soil core -> `.SOL` and other
  model exports

## The practical answer to the soil question

If you want the soil data "prepared correctly" for a Denmark-style project,
motivated by Ethiopia, then the final soil deliverables should not only be a
single `.SOL` file.

They should be a package containing:

1. a raw source record showing which ISIMIP soil file was used
2. a processed canonical table with one row per layer per station or grid cell
3. a hydraulic-enriched soil table
4. a horizon or initial-condition table
5. a DSSAT `.SOL` export
6. QC notes describing fallback assumptions and missing values

That is the structure that makes the soil side auditable, reusable, and ready
for future models beyond DSSAT.
