# Denmark ISIMIP Technical Record

This chapter is the detailed project log for the Denmark ISIMIP work.

It is meant to answer the practical questions a future researcher will ask:

- where did the climate data come from
- what was already present
- which scripts were used
- what each script produced
- what broke and how it was repaired
- how the final weather and soil products were validated
- how the results were proven in a local DSSAT run

This is not just a conceptual workflow. It is the concrete record of the work
that was actually carried out across the HPC project tree and the local DSSAT
installation.

## Project locations

### Remote HPC project

- `/home/<user>/DEN`
- `/home/<user>/DEN/denmark`
- `/home/<user>/DEN/soil_data`

### Ethiopia soil reference on HPC

- `/home/<user>/Ethiopia`
- `/home/<user>/Ethiopia/soil_data`

### Local DSSAT environment

- `C:\DSSAT48`
- `C:\DSSAT48\Peanut`
- `C:\DSSAT48\Weather`
- `C:\DSSAT48\Soil`

### Local documentation workspace

- `C:\Users\chich\Downloads\cropmodelling`

## The main objective

The practical Denmark objective was to take ISIMIP climate inputs and build a
reproducible chain ending in DSSAT-ready weather files, while also testing a
first Denmark soil linkage strongly enough to prove the files could run in a
real DSSAT example.

By the end of the work, the project had:

- processed Denmark climate NetCDF files in crop-model units
- parquet zonal outputs
- TAV and AMP outputs
- DSSAT `.WTH` files
- repaired DEM-based elevation metadata
- a Denmark soil core sampled from ISIMIP soil input data
- a first Denmark `.SOL` file for local smoke testing
- a local DSSAT experiment proving Denmark weather and soil could execute

## Climate data source

The Denmark climate workflow was based on ISIMIP data already staged under the
model folders in `/home/<user>/DEN`.

The project worked with five climate models:

- `GFDL_ESM4`
- `IPSL-CM6A-LR`
- `MPI-ESM1-2-HR`
- `MRI-ESM2-0`
- `UKESM1-0-LL`

The scenario set used in the Denmark pipeline was:

- `historical`
- `ssp126`
- `ssp370`
- `ssp585`

The climate grid logic was based on the ISIMIP global `0.5 degree` grid, which
is why the Denmark project also used a `0.5 degree` Denmark grid.

## Soil data source

The soil source used for the Denmark test build came from ISIMIP3a soil input
data.

Two upstream soil products were considered:

- `ISIMIP3a/InputData/geo_conditions/soil/hwsd_soil_data_all_land.nc`
- `ISIMIP3a/InputData/geo_conditions/soil/hwsd_soil_data_on_cropland.nc`

For crop modeling, the preferred source became the cropland-focused product:

- `ISIMIP3a/InputData/geo_conditions/soil/hwsd_soil_data_on_cropland.nc`

The reasoning was simple:

- `all_land` represents dominant soil across land in a grid cell
- `on_cropland` represents soil conditions more relevant to agricultural use

The Denmark soil core was therefore built from the cropland product and the
all-land product was kept only as a comparison reference.

## What already existed before restructuring

Before the wrapper was created, Denmark already had many key ingredients in
place:

- shapefiles under `/home/<user>/DEN/shapefiles`
- DEM tiles under `/home/<user>/DEN/COP30`
- processed climate files under each model folder
- legacy zonal outputs under `/home/<user>/DEN/zonal_stats`

Important existing shapefiles included:

- `/home/<user>/DEN/shapefiles/denmark_grid_05deg.shp`
- `/home/<user>/DEN/shapefiles/denmark_extent.shp`

The large climate data were not moved during cleanup because copying them would
have been slow, heavy, and unnecessary on HPC.

## The wrapper created for the Denmark project

To make the work shareable and reproducible, a clean wrapper was created at:

- `/home/<user>/DEN/denmark`

Inside that wrapper, the project was organized into:

- `/home/<user>/DEN/denmark/scripts`
- `/home/<user>/DEN/denmark/docs`
- `/home/<user>/DEN/denmark/config`
- `/home/<user>/DEN/denmark/deliverables`
- `/home/<user>/DEN/denmark/logs`

This wrapper separated:

- heavy source inputs already present in the parent project
- workflow logic
- validation artifacts
- final deliverables for sharing

## Denmark weather workflow scripts

The numbered weather workflow scripts in the Denmark wrapper were:

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
- `/home/<user>/DEN/denmark/scripts/12_validate_weather_and_soil.py`

## What each Denmark weather script did

### `01_download_isimip.sh`

This is the top-level climate acquisition stage.

In practice, the Denmark project was able to proceed without a fresh bulk
download because the climate data were already present under the model folders
inside `/home/<user>/DEN`.

### `02_prepare_shapefiles_and_grid.sh`

This represents the shapefile staging step, linking the Denmark extent and the
Denmark `0.5 degree` climate grid.

### `03_create_denmark_grid.py`

This is the explicit grid-construction step used to formalize the Denmark
gridded geometry that later drives zonal extraction and WTH station creation.

### `04_prepare_dem.sh`

This step prepared the DEM support raster used for WTH elevation values.

The key merged raster produced by this logic was:

- `/home/<user>/DEN/denmark/deliverables/validation/denmark_dem_merged.tif`

### `05_merge_clip_convert_climate.sh`

This step transformed climate inputs into processed Denmark NetCDF files ready
for crop-model use.

Its logic included:

- merging yearly or chunked files
- clipping to Denmark extent
- converting variables into DSSAT-appropriate units

The target units were:

- `pr` to `mm/day`
- `tas` to `degC`
- `tasmax` to `degC`
- `tasmin` to `degC`
- `rsds` to `MJ m-2 day-1`

### `06_compute_tav_amp.py`

This script computed the two climatological values needed in DSSAT weather
headers:

- `TAV`
- `AMP`

Outputs were written under:

- `/home/<user>/DEN/denmark/deliverables/tav_amp/{MODEL}/{SCENARIO}/{PERIOD}/tav_amp.csv`

### `07_extract_zonal_stats_parquet.py`

This step converted processed climate grids into zone-level parquet outputs
following the same general logic used in the Ethiopia workflow.

Outputs were written under:

- `/home/<user>/DEN/denmark/deliverables/parquet_zonal_stats/{MODEL}/{SCENARIO}/{PERIOD}/pr/pr.parquet`
- `/home/<user>/DEN/denmark/deliverables/parquet_zonal_stats/{MODEL}/{SCENARIO}/{PERIOD}/tasmax/tasmax.parquet`
- `/home/<user>/DEN/denmark/deliverables/parquet_zonal_stats/{MODEL}/{SCENARIO}/{PERIOD}/tasmin/tasmin.parquet`
- `/home/<user>/DEN/denmark/deliverables/parquet_zonal_stats/{MODEL}/{SCENARIO}/{PERIOD}/rsds/rsds.parquet`

### `08_generate_wth_files.py`

This script assembled final DSSAT weather files by combining:

- rainfall from `pr`
- maximum temperature from `tasmax`
- minimum temperature from `tasmin`
- solar radiation from `rsds`
- `TAV`
- `AMP`
- DEM-based elevation

Outputs were written under:

- `/home/<user>/DEN/denmark/deliverables/wth/{MODEL}/{SCENARIO}/{PERIOD}`

### `09_validate_outputs.py`

This script was used for quick production counts of:

- parquet files
- WTH files
- TAV and AMP files

### `10_run_model_scenario_weather.sh`

This was the scenario-level orchestration script. It allowed a single
model-scenario combination to be rebuilt cleanly.

### `11_submit_denmark_weather.sh`

This was the cluster batch-submission wrapper used to launch the Denmark
weather production across the full model-scenario matrix.

### `12_validate_weather_and_soil.py`

This script validated two things together:

- the final weather files
- the Denmark soil core

It wrote:

- `/home/<user>/DEN/soil_data/reports/wth_validation.csv`
- `/home/<user>/DEN/soil_data/reports/soil_core_validation.csv`
- `/home/<user>/DEN/soil_data/reports/weather_soil_validation_summary.json`

## The main weather processing chain

The Denmark weather chain was:

1. use the processed climate files already staged in `/home/<user>/DEN/{MODEL}/processed`
2. confirm and repair unit conversions where needed
3. prepare a merged Denmark DEM
4. compute `TAV` and `AMP`
5. generate parquet zonal outputs
6. generate DSSAT `.WTH` files
7. validate unit metadata, counts, and final file sanity

## Major problems and repairs during the weather build

### Batch execution and dependency issues

Early submission attempts left jobs pending behind dependencies or failing for
environment reasons. The wrapper scripts were tightened so they launched with a
more explicit environment and clearer control flow.

### Corrupted processed climate files

One real data failure affected `MPI-ESM1-2-HR / ssp370`.

Two processed files were corrupted and had to be regenerated:

- `/home/<user>/DEN/MPI-ESM1-2-HR/processed/MPI-ESM1-2-HR_ssp370_tasmin_denmark.nc`
- `/home/<user>/DEN/MPI-ESM1-2-HR/processed/MPI-ESM1-2-HR_ssp370_rsds_denmark.nc`

After they were rebuilt from raw source, the missing Denmark WTH set completed
successfully.

### Mislabelled temperature metadata

Unit values across the processed climate outputs were checked after production.

The physical values were correct, but two files had temperature metadata still
labelled as Kelvin even though the values were already Celsius. Those metadata
labels were fixed so the final processed set was internally consistent.

### Zero-elevation WTH headers

Many coastal or water-dominated Denmark grid cells initially ended up with
`ELEV = 0`.

The elevation logic in `/home/<user>/DEN/denmark/scripts/08_generate_wth_files.py`
was improved so the fallback order became:

1. DEM sample at land-intersection centroid
2. land-polygon mean
3. land-polygon max
4. nearest grid cell with valid land-based elevation

After this repair, the final Denmark WTH outputs no longer carried zero
elevations in the production set.

## Final Denmark weather deliverables

The weather production finished with:

- `80` parquet files
- `20` TAV/AMP files
- `1160` WTH files

This corresponds to:

- `5` models
- `4` scenarios
- `20` model-scenario combinations
- `58` WTH files per combination

Important deliverables included:

- `/home/<user>/DEN/denmark/deliverables/wth`
- `/home/<user>/DEN/denmark/deliverables/parquet_zonal_stats`
- `/home/<user>/DEN/denmark/deliverables/tav_amp`
- `/home/<user>/DEN/denmark/deliverables/validation/processed_units_validation.csv`
- `/home/<user>/DEN/denmark/deliverables/validation/denmark_dem_merged.tif`
- `/home/<user>/DEN/denmark_wth_bundle.tar.gz`

## Processed climate validation

All processed Denmark climate files were checked across:

- `pr`
- `tas`
- `tasmax`
- `tasmin`
- `rsds`

The final validation result was:

- `100/100` processed NetCDF files passed

The expected final units were:

- `pr`: `mm/day`
- `tas`: `degC`
- `tasmax`: `degC`
- `tasmin`: `degC`
- `rsds`: `MJ m-2 day-1`

## Denmark soil build

The soil side did not begin as a full DSSAT `.SOL` project. It began with a
grid-aligned soil core sampled from ISIMIP soil input data.

The local and remote staging paths used for the Denmark soil work included:

- `/home/<user>/DEN/soil_data/raw`
- `/home/<user>/DEN/soil_data/processed`
- `/home/<user>/DEN/soil_data/reports`

### First downloaded soil source

The first downloaded source was:

- `/home/<user>/DEN/soil_data/raw/hwsd_soil_data_all_land.nc`

This was used to inspect the available fields and to test whether the Denmark
grid aligned naturally with the ISIMIP `0.5 degree` soil grid.

### Preferred soil source for crop modeling

The final preferred source became:

- `/home/<user>/DEN/soil_data/raw/hwsd_soil_data_on_cropland.nc`

because it better represents agricultural land within each cell.

### Soil properties extracted from ISIMIP

The core ISIMIP soil variables used in the Denmark build were:

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

## Denmark soil outputs produced on HPC

The two main processed Denmark soil-core tables created were:

- `/home/<user>/DEN/soil_data/processed/denmark_soil_core_all_land.csv`
- `/home/<user>/DEN/soil_data/processed/denmark_soil_core_cropland.csv`

The main reports created were:

- `/home/<user>/DEN/soil_data/reports/denmark_soil_core_summary.csv`
- `/home/<user>/DEN/soil_data/reports/denmark_soil_core_cropland_summary.csv`
- `/home/<user>/DEN/soil_data/reports/denmark_soil_all_land_vs_cropland.csv`

The cropland-core build became the preferred source of truth.

### Denmark soil-core validation status

The grid-aligned Denmark cropland core reached:

- `60` rows
- `55` direct land-centroid matches
- `5` nearest-valid fallbacks for tiny coastal cells
- `0` missing `soil_ph`
- `0` missing `bulk_density`
- `0` missing `awc`

This means the soil core was usable as an upstream Denmark soil backbone, even
though it was not yet a full layered DSSAT soil library by itself.

## Weather and soil joint validation

The combined Denmark weather and soil validation stage produced:

- `/home/<user>/DEN/soil_data/reports/wth_validation.csv`
- `/home/<user>/DEN/soil_data/reports/soil_core_validation.csv`
- `/home/<user>/DEN/soil_data/reports/weather_soil_validation_summary.json`

The main outcome was:

- `1160/1160` WTH files parsed successfully
- `60/60` Denmark soil-core rows passed the sanity checks

That proved:

- the weather files were structurally usable
- the soil core was numerically sane and aligned to the Denmark grid

It did not yet prove a final Denmark `.SOL` because the local DSSAT smoke test
had not been performed at that stage.

## Local DSSAT smoke-test build

To prove that Denmark weather and soil could actually be executed by DSSAT, a
local smoke test was built in the Windows DSSAT installation at `C:\DSSAT48`.

### Baseline example used for local DSSAT

The first step was to run the unmodified peanut example:

- `C:\DSSAT48\Peanut\UFGA7901.PNX`

This baseline run succeeded using:

- `C:\DSSAT48\DSCSM048.EXE MPN A UFGA7901.PNX`

That confirmed the local DSSAT installation was healthy before the Denmark
files were introduced.

### Local Denmark staging files

The Denmark local smoke-test staging area was:

- `C:\Users\chich\Downloads\DEN\local_test\source`
- `C:\Users\chich\Downloads\DEN\local_test\reports`

The remote Denmark files copied locally for this setup included:

- a validated Denmark WTH source file from HPC
- the Denmark cropland soil core CSV

### Local preparation script

The main local setup script written for this proof was:

- `C:\Users\chich\Downloads\DEN\denmark\scripts\13_prepare_local_dssat_smoke_test.py`

This script:

- created a local single-year DSSAT weather file from the Denmark WTH export
- built a first Denmark soil library at `C:\DSSAT48\Soil\DN.SOL`
- synchronized Denmark profiles into `C:\DSSAT48\Soil\SOIL.SOL`
- created a copied DSSAT peanut experiment linked to Denmark weather and soil
- wrote a local setup manifest

### Local DSSAT smoke-test outputs

The key local outputs were:

- `C:\DSSAT48\Weather\DK017101.WTH`
- `C:\DSSAT48\Soil\DN.SOL`
- `C:\DSSAT48\Peanut\UFGA7103.PNX`
- `C:\Users\chich\Downloads\DEN\local_test\reports\local_dssat_smoke_setup.json`

### Local DSSAT test logic

The test was intentionally conservative:

- keep the stock peanut example structure
- change only the weather and soil linkage to Denmark
- shift the experiment dates into a Denmark-compatible weather year
- refine the setup until DSSAT accepted the files and ran

### What happened in the local Denmark run

The local Denmark-linked peanut example eventually ran successfully.

That proved:

- the Denmark weather file was readable by DSSAT
- the Denmark soil file was readable by DSSAT
- DSSAT could execute an experiment using Denmark weather and the Denmark soil
  profile

### What the local smoke test did not prove

The smoke test used peanut because the objective was technical proof of file
execution, not agronomic realism.

The final run still showed freeze-related crop failure later in the season,
which is expected for a peanut example under Denmark conditions.

So the smoke test proved technical integration, not that peanut is an
appropriate Denmark production crop.

## Why the Ethiopia project still matters

The Ethiopia soil project remains the best architectural reference for what the
Denmark soil side should become.

The key confirmed Ethiopia files were:

- `/home/<user>/Ethiopia/soil_data/docs/soil_first_workflow.md`
- `/home/<user>/Ethiopia/soil_data/docs/soil_hydraulics_runoff.md`
- `/home/<user>/Ethiopia/soil_data/processed/soil_with_slro.csv`
- `/home/<user>/Ethiopia/soil_data/processed/horizon.csv`
- `/home/<user>/Ethiopia/soil_data/dssat/ET.SOL`
- `/home/<user>/Ethiopia/soil_data/stics/sols.xml`
- `/home/<user>/Ethiopia/soil_data/apsim/soils/*.json`

The design lesson is that Denmark should eventually have:

- one authoritative processed soil backbone
- model-specific exports derived from that backbone
- QC notes and fallback logic documented explicitly

## Recommended Denmark soil target structure

The future Denmark soil structure should look like:

- `/home/<user>/DEN/soil_data/raw`
- `/home/<user>/DEN/soil_data/processed`
- `/home/<user>/DEN/soil_data/docs`
- `/home/<user>/DEN/soil_data/reports`
- `/home/<user>/DEN/soil_data/dssat`
- `/home/<user>/DEN/soil_data/apsim`
- `/home/<user>/DEN/soil_data/stics`

At minimum, the authoritative processed tables should eventually include:

- `final_soil_profile_all_points.csv`
- `hydraulic_parameters_from_profile.csv`
- `soil_with_slro.csv`
- `horizon.csv`

And the model-specific outputs should include:

- `DN.SOL`
- APSIM soil exports
- STICS soil exports

## Final result summary

The Denmark climate and soil work reached a point where the pipeline is now
fully traceable.

The project now has:

- clearly identified upstream climate and soil sources
- a named HPC wrapper structure
- numbered workflow scripts
- documented repairs
- validated climate outputs
- validated grid-aligned soil core outputs
- a first Denmark DSSAT soil library
- a successful local DSSAT smoke test linking Denmark weather and soil

The most important practical conclusion is this:

the Denmark inputs are no longer just files sitting in folders. They are now a
documented, validated workflow with named scripts, named outputs, and a clear
record from source data to runnable DSSAT proof.
