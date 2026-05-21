# pSIMS Explained for Crop Modellers

> **Who this is for:** you understand crop models (DSSAT, STICS, APSIM) and know what a
> simulation needs — climate, soil, management. You are not a software developer.
> This page explains what pSIMS does in plain language, what files it needs,
> what it produces, and how to run it.

---

## What Is pSIMS?

Normally, to run DSSAT you prepare `.WTH` weather files, `SOIL.SOL` soil profiles,
and `*.X` experiment files by hand. For one or two sites that is manageable.
For 1,000 sites across Ethiopia it becomes impossible.

**pSIMS is an assembly line that does all of that automatically.**

You give it:
- Climate data for every site (one standard file format)
- Soil data for every site (same format)
- Your experiment settings (planting date, cultivar, fertilizer — once)
- A config file saying which model to use

pSIMS then:
1. Extracts climate and soil for each site from those files
2. Converts them into whatever format the chosen model needs
3. Runs the model for every site
4. Pulls the outputs (yield, anthesis date, etc.) into one clean results file

The same climate and soil files work for DSSAT, STICS, or APSIM —
you just change one line in the config to switch models.

---

## The Assembly Line — Step by Step

When you run pSIMS, it executes these steps in order for each site:

```
1. Stage inputs     — copy climate and soil tiles to a working folder
2. Convert climate  — turn NetCDF climate tile → model weather file
                      (Psims2Wth for DSSAT, Psims2Met for APSIM, Psims2Stics for STICS)
3. Build experiment — merge your JSON experiment settings into the model input format
                      (Camp2Json → Jsons2Dssat / Jsons2Apsimx / Jsons2Stics)
4. Run model        — call DSSAT / APSIM / STICS binary
5. Collect output   — read model output → one standard NetCDF results file
6. Stage outputs    — move results to the outputs/ folder
```

Each step is a small Python class. If one step fails, pSIMS prints `False` for that step
and stops — you can see exactly where the problem is.

---

## Section 1 — Input Data

pSIMS needs **three kinds of input**.

### 1a. Climate data — the "tile" file

**File:** `clim_0001_0001.tile.nc4`

This is a NetCDF4 file (a scientific data format — think of it as a structured spreadsheet
that holds daily time series for one grid cell). It contains:

| Variable | What it is |
|---|---|
| `tmax` | Daily maximum air temperature (°C) |
| `tmin` | Daily minimum air temperature (°C) |
| `precip` | Daily precipitation (mm) |
| `solar` | Daily solar radiation (MJ/m²/day) |

One tile file = one grid cell (e.g. 0.5° × 0.5°) for the full climate period (e.g. 1980–2010).

You do **not** create these by hand. They come from processed climate products
(CMIP6 GCMs, ERA5, CHIRPS, etc.) that are already in pSIMS tile format.
For the Ethiopia ensemble, these are prepared by the climate pipeline (ws2 scripts).

### 1b. Soil data — the "tile" file

**File:** `soil_0001_0001.tile.nc4`

Same NetCDF4 format, but contains soil profile properties for the same grid cell:

| Variable | What it is |
|---|---|
| `slt` | Silt fraction per layer (%) |
| `cly` | Clay fraction per layer (%) |
| `snd` | Sand fraction per layer (%) |
| `soc` | Soil organic carbon (%) |
| `bd` | Bulk density (g/cm³) |
| `ph` | Soil pH |

Multiple soil layers are stored along a depth dimension.
For the Ethiopia ensemble, these come from SoilGrids via the soil pipeline (ws1 scripts).

### 1c. Experiment settings — the campaign file

**File:** `experiment.json` (for APSIM) or `exp_template.json` (for DSSAT)

This is where you describe your agronomy — the same information you would enter in
the DSSAT experiment file or APSIM manager script, but written in JSON format.

**APSIM example** (simple — 18 lines):
```json
{
  "StartDate":   "1980-01-01",
  "EndDate":     "2010-12-31",
  "Crop":        "Maize",
  "PlantingDate":"15-Apr",
  "Cultivar":    "B_110",
  "SowingDensity": 7.5,
  "RowSpacing":   750,
  "SowingDepth":  30
}
```

**DSSAT example** (detailed — ~220 lines) includes:
- Planting date, density, depth
- Fertilizer applications (date, amount, type, placement)
- Irrigation schedule
- Harvest rule
- Simulation control flags (water balance method, N balance on/off, etc.)

> **Crop modeller note:** the JSON keys map 1-to-1 to the fields you already know
> from DSSAT X-files or APSIM manager. The values are the same numbers in the same units.
> The format is just different (JSON instead of fixed-width text).

---

## Section 2 — The Config File (params)

**File:** `params.dssat48.point.sample` (or similar name)

This is a YAML file — essentially a list of `key: value` settings.
It is the **only file you normally edit** when setting up a run.

Here are the most important settings, explained:

```yaml
# Which model to use
model: dssat48

# Where your climate tiles are
weather: samples/dssat48_point_bundle/weather

# Where your soil tiles are
soils: samples/dssat48_point_bundle/soils

# Where your experiment JSON is
campaign: samples/dssat48_point_bundle/campaign

# Path to the model executable
executable: /path/to/DSCSM048.EXE

# Grid cell size in arc-minutes (30 = 0.5 degrees)
delta: "30,30"

# How many grid cells in this run
num_lats: 1
num_lons: 1

# What output variables to extract
variables: harwt,adat,mdat,lai_max

# Reference year for the climate tiles
ref_year: 1980

# Output file name
out_file: dssat48-point
```

That is it. You set the paths, pick your variables, and run.

---

## Section 3 — Output Data

**File:** `outputs/output_0001_0001.psims.nc`

This is another NetCDF4 file. It contains one value per simulation year
for each variable you requested. For example, if your climate spans 1980–2010
(30 years), you get 30 yield values, 30 anthesis dates, 30 maturity dates.

| Variable | What it means | Units |
|---|---|---|
| `harwt` | Grain yield at harvest | kg/ha |
| `adat` | Anthesis (silking) date | day of year |
| `mdat` | Maturity date | day of year |
| `lai_max` | Maximum leaf area index | m²/m² |

### Opening the output

In Python:
```python
import netCDF4
nc = netCDF4.Dataset('outputs/output_0001_0001.psims.nc')
yield_kgha = nc.variables['harwt'][:]   # array of 30 values
print(yield_kgha)
nc.close()
```

In R:
```r
library(ncdf4)
nc <- nc_open('outputs/output_0001_0001.psims.nc')
yield <- ncvar_get(nc, 'harwt')
print(yield)
nc_close(nc)
```

### CSV output (easier for Excel/R)

Add `csv: true` in your params file and pSIMS also writes a `.csv` next to the NetCDF.
You can open that directly in Excel or read it with `read.csv()` in R.

---

## Section 4 — The Run Command, Decoded

```bash
python pysims/pysims.py \
    --param   params/params.dssat48.point.sample \
    --campaign samples/dssat48_point_bundle/campaign \
    --tlatidx  0001 \
    --tlonidx  0001 \
    --latidx   1 \
    --lonidx   1
```

| Piece | What it means |
|---|---|
| `python pysims/pysims.py` | Run the pSIMS pipeline script |
| `--param params/...` | Use this params file (your config) |
| `--campaign samples/.../campaign` | Use this folder for experiment JSON files |
| `--tlatidx 0001` | Which latitude tile to process (4-digit, zero-padded) |
| `--tlonidx 0001` | Which longitude tile to process |
| `--latidx 1` | Which row inside that tile (1-based) |
| `--lonidx 1` | Which column inside that tile |

For the sample data there is only one tile (`0001`) containing one point (`1, 1`).
For a 1,000-site ensemble you would loop over all tile/point combinations —
that is what the Slurm batch scripts handle automatically.

---

## Section 5 — Can a Bachelor Intern Run This?

**Honest answer: maybe, with a good setup guide and a mentor for the first session.**

Here is where interns will succeed and where they will struggle:

### Easy parts
- Editing the params file — it is just key-value pairs
- Reading outputs in R or Python — two lines of code
- Running the command once everything is installed — it is one command
- Understanding what each input means — it maps to familiar agronomy concepts

### Hard parts

| Challenge | Why it is hard |
|---|---|
| Installation | Python virtual environment, model binaries, Java, paths — many steps, many ways to fail |
| Path errors | Relative vs absolute paths; running from the wrong directory causes cryptic errors |
| NetCDF format | Not familiar; requires a library; error messages are not beginner-friendly |
| Debugging `False` | When a pipeline step fails with `False`, finding the log and interpreting the traceback requires Python familiarity |
| Tile structure | Understanding `0001/clim_0001_0001.tile.nc4` naming convention is non-obvious |
| HPC | SSH, Slurm, modules, environment variables — a second learning curve on top of pSIMS |

**Verdict:** An intern can run pre-configured sample data successfully on their first day.
Building a new experiment from scratch (new crop, new region, new climate dataset) requires
2–3 weeks of guided work. Running the full HPC ensemble independently requires
several months of experience.

---

## Section 6 — Simplifications We Recommend

The following changes would make pSIMS significantly more intern-friendly
without breaking anything.

### 6a. A one-line run script per model

Instead of remembering the full command with 6 flags, create small shell scripts
in the pSIMS root:

```bash
# run_dssat.sh
#!/bin/bash
cd "$(dirname "$0")"
python pysims/pysims.py \
    --param   params/params.dssat48.point.sample \
    --campaign samples/dssat48_point_bundle/campaign \
    --tlatidx 0001 --tlonidx 0001 --latidx 1 --lonidx 1
```

Then an intern just types `bash run_dssat.sh`. Done.
Equivalent scripts: `run_stics.sh`, `run_apsim.sh`, `run_all.sh`.

### 6b. Simpler params file names

The current name `params.dssat48.point.sample` is not intuitive.
Rename (or add symlinks) to something like:

| Old name | Suggested name |
|---|---|
| `params.dssat48.point.sample` | `params_dssat_sample.yaml` |
| `params.stics10.point.sample` | `params_stics_sample.yaml` |
| `params.apsimx.point.linux.sample` | `params_apsim_linux_sample.yaml` |

### 6c. A "quick check" script

A one-page script that reads the output NetCDF and prints a readable summary:

```python
# check_output.py
import sys, netCDF4, numpy as np

nc = netCDF4.Dataset(sys.argv[1])
print(f"\n{'Variable':<12} {'Mean':>10} {'Min':>10} {'Max':>10}")
print("-" * 45)
for var in nc.variables:
    if var in ('lat','lon','time'): continue
    data = nc.variables[var][:].flatten()
    data = data[~np.isnan(data)]
    if len(data):
        print(f"{var:<12} {data.mean():>10.1f} {data.min():>10.1f} {data.max():>10.1f}")
nc.close()
```

Usage: `python check_output.py outputs/output_0001_0001.psims.nc`

### 6d. Cleaner error messages

When a pipeline step returns `False`, pSIMS currently prints only:
```
0001/0001, ApsimX, run, ..., False
```

A small patch to `pysims.py` could print the last few lines of the model's stderr,
which is what you actually need to diagnose the problem.

### 6e. A minimal DSSAT experiment template

The current `exp_template.json` is 220 lines covering every possible option.
For a standard rainfed maize run most of those lines are noise.
A "minimal template" with only the 10–15 fields that actually change between experiments
would be much less intimidating as a starting point.

---

## Summary

| What | Format | Tool to open |
|---|---|---|
| Climate input | NetCDF4 tile (`.tile.nc4`) | Python `netCDF4`, R `ncdf4`, Panoply |
| Soil input | NetCDF4 tile (`.tile.nc4`) | same |
| Experiment settings | JSON (`.json`) | any text editor |
| Config | YAML (`.yaml` or `.sample`) | any text editor |
| Results | NetCDF4 (`.psims.nc`) | Python, R, Panoply |
| Results (optional) | CSV (`.csv`) | Excel, R, Python |

The only files you edit for a new run:
1. `experiment.json` — your agronomy (planting date, cultivar, management)
2. `params_*.yaml` — your paths, model choice, and output variables

Everything else is infrastructure that, once set up, you do not touch.
