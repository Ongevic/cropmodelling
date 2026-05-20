# Denmark ISIMIP3b to DSSAT: Full Script Walkthrough

> **Full guide:** [github.com/Ongevic/cropmodelling](https://github.com/Ongevic/cropmodelling)

This chapter walks through every script that turned raw ISIMIP3b climate data
into DSSAT-ready weather files for Denmark.

It does not summarise the scripts. It goes through each one block by block,
explaining what the code does and why each decision was made.

By the end you should be able to reproduce the full pipeline from scratch, or
adapt it for any other country or climate dataset.

---

## What this pipeline produces

At the end of this workflow you have:

- `1160` DSSAT `.WTH` files covering all of Denmark
- `20` TAV/AMP summary CSVs
- `80` Parquet zonal-statistic files as intermediate data

That corresponds to:

- `5` climate models
- `4` scenarios per model (`historical`, `ssp126`, `ssp370`, `ssp585`)
- `58` Denmark grid cells per model-scenario combination

---

## The full data flow

```
ISIMIP data portal
        │
        │  01_download_isimip.sh
        ▼
Raw ISIMIP3b NetCDF files
(one file per model / scenario / variable / year-chunk)
        │
        │  05_merge_clip_convert_climate.sh
        ▼
Processed Denmark NetCDF files
(units converted, clipped to Denmark, one file per model/scenario/variable)
        │
        ├──── 06_compute_tav_amp.py ──────────► tav_amp/*.csv
        │
        ├──── 07_extract_zonal_stats_parquet.py ► *.parquet
        │     (also needs 02/03 shapefiles)
        │
        └──── 08_generate_wth_files.py ──────► *.WTH
              (also needs 04 DEM, parquet, shapefile)

Validation
        │
        │  09_validate_outputs.py
        ▼
Counts check + processed_units_validation.csv

Orchestration
        │
        │  10_run_model_scenario_weather.sh
        │  11_submit_denmark_weather.sh (Slurm)
        ▼
All 20 model-scenario combinations run on HPC in parallel
```

---

## Project directory layout on HPC

Everything lives under `/home/<user>/DEN`.

```
/home/<user>/DEN/
├── GFDL_ESM4/
│   ├── raw/                ← original downloaded NetCDF files
│   └── processed/          ← unit-converted, Denmark-clipped NetCDFs
├── IPSL-CM6A-LR/
│   ├── raw/
│   └── processed/
├── MPI-ESM1-2-HR/
│   ├── raw/
│   └── processed/
├── MRI-ESM2-0/
│   ├── raw/
│   └── processed/
├── UKESM1-0-LL/
│   ├── raw/
│   └── processed/
├── shapefiles/
│   ├── denmark_extent.shp
│   └── denmark_grid_05deg.shp
├── COP30/
│   └── *.tif               ← Copernicus 30m DEM tiles
└── denmark/                ← clean wrapper (scripts + deliverables)
    ├── scripts/
    ├── docs/
    ├── config/
    ├── logs/
    └── deliverables/
        ├── wth/
        ├── tav_amp/
        ├── parquet_zonal_stats/
        └── validation/
```

The large climate data files stay in place under each model folder.
The `denmark/` wrapper only holds scripts and final outputs.
That separation avoids expensive file copies on HPC.

---

## The five climate models

| Short name | Full CMIP6 identifier |
|---|---|
| GFDL_ESM4 | NOAA Geophysical Fluid Dynamics Lab |
| IPSL-CM6A-LR | Institut Pierre Simon Laplace |
| MPI-ESM1-2-HR | Max Planck Institute, high resolution |
| MRI-ESM2-0 | Meteorological Research Institute Japan |
| UKESM1-0-LL | UK Earth System Model |

These five are the standard ISIMIP3b bias-corrected set used by the
climate-impacts community.

---

## The five climate variables

| CMIP6 name | Meaning | DSSAT name | Target units |
|---|---|---|---|
| `pr` | Precipitation | `RAIN` | mm/day |
| `tasmax` | Daily maximum temperature | `TMAX` | °C |
| `tasmin` | Daily minimum temperature | `TMIN` | °C |
| `rsds` | Surface downwelling shortwave radiation | `SRAD` | MJ m⁻² day⁻¹ |
| `tas` | Mean temperature (used only for TAV/AMP) | — | °C |

DSSAT does not need `tas` directly in the weather file but the processed
`tas` NetCDF is validated as a consistency check.

---

## Script 01 — Download ISIMIP climate data

**File:** `01_download_isimip.sh`

```bash
#!/bin/bash
set -euo pipefail

exec /home/<user>/DEN/scripts/download_isimip.sh "$@"
```

### What this script does

This is a thin wrapper. It delegates immediately to the core download script
that lives in the parent project tree.

The real download logic is in:

```
/home/<user>/DEN/scripts/download_isimip.sh
```

That older script uses the ISIMIP data portal API to pull all model-scenario-
variable combinations to the `raw/` folders.

### Line-by-line breakdown

```bash
#!/bin/bash
```

The shebang. Tells the shell this file is a Bash script. This is the first
line of every shell script in this pipeline.

```bash
set -euo pipefail
```

Three safety flags in one line. Always include these at the top of any Bash
script you write.

- `-e` — stop the script immediately if any command returns a non-zero exit code
- `-u` — treat any unset variable as an error instead of silently expanding to empty
- `-o pipefail` — if any command in a pipeline fails, the whole pipeline is marked as failed

Without these, a failing download could silently continue and you would only
discover the problem much later when WTH generation crashes.

```bash
exec /home/<user>/DEN/scripts/download_isimip.sh "$@"
```

`exec` replaces the current process with the target script rather than forking
a child process. That means any Slurm job accounting stays with the real
script and there is no intermediate shell process sitting idle.

`"$@"` passes all arguments through unchanged. If you call this wrapper with
`--model GFDL_ESM4` those flags reach the real download script.

### Why the data were already present

For the Denmark project, the ISIMIP downloads had been completed in earlier
work. The pipeline could therefore proceed directly to the processing step
without waiting for a fresh download.

In a new project you would run this step first and let it finish before
anything else.

---

## Scripts 02 and 03 — Prepare shapefiles and grid

**File:** `02_prepare_shapefiles_and_grid.sh`

```bash
#!/bin/bash
set -euo pipefail

echo "Use existing Denmark shapefiles in /home/<user>/DEN/shapefiles"
echo "Grid builder source: /home/<user>/DEN/scripts/create_denmark_grid.py"
```

**File:** `03_create_denmark_grid.py`

```python
#!/usr/bin/env python3
import runpy

runpy.run_path("/home/<user>/DEN/scripts/create_denmark_grid.py",
               run_name="__main__")
```

### What these scripts do

These two scripts represent the geographic foundation.

The Denmark project needed two shapefiles:

1. `denmark_extent.shp` — the outer boundary of Denmark used for clipping
   climate grids
2. `denmark_grid_05deg.shp` — a 0.5-degree grid of polygons covering Denmark,
   with each polygon assigned a unique `grid_id`

The `grid_id` values in `denmark_grid_05deg.shp` become the station identifiers
in the final WTH filenames and headers.

### Why 0.5 degrees

ISIMIP3b bias-corrected climate data are delivered on a 0.5-degree global
grid. Building the Denmark analysis grid at the same resolution means every
grid polygon maps exactly to one or more NetCDF cells without interpolation.

Denmark spans roughly:
- latitude: 54.5 N to 57.8 N
- longitude: 8.0 E to 15.2 E

At 0.5-degree spacing that gives approximately 58 grid cells that contain
meaningful land area.

### The runpy pattern

```python
runpy.run_path("/home/<user>/DEN/scripts/create_denmark_grid.py",
               run_name="__main__")
```

`runpy.run_path` executes a Python file as if it were run directly from the
command line. Setting `run_name="__main__"` triggers any `if __name__ == "__main__":`
guard in the target file.

This pattern lets the numbered wrapper scripts stay lean while pointing to the
real logic files that already existed before the clean wrapper was built.

---

## Script 04 — Prepare the DEM

**File:** `04_prepare_dem.sh`

```bash
#!/bin/bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
unset PYTHONPATH || true
GEO_PY="/home/<user>/.conda/envs/mamba_env/envs/geo_env/bin/python"

BASE=/home/<user>/DEN
OUTDIR="$BASE/denmark/deliverables/validation"
mkdir -p "$OUTDIR"

echo "COP30 source tiles: $BASE/COP30" > "$OUTDIR/dem_status.txt"
find "$BASE/COP30" -maxdepth 1 -name '*.tif' | sort >> "$OUTDIR/dem_status.txt"
MERGED="$OUTDIR/denmark_dem_merged.tif"

if [ -f "$MERGED" ]; then
  echo "Merged DEM already exists: $MERGED" >> "$OUTDIR/dem_status.txt"
  exit 0
fi

$GEO_PY - <<'PY'
from pathlib import Path
import rasterio
from rasterio.merge import merge

base = Path("/home/<user>/DEN/COP30")
out = Path("/home/<user>/DEN/denmark/deliverables/validation/denmark_dem_merged.tif")
tiles = sorted(base.glob("*.tif"))
if not tiles:
    raise SystemExit("No COP30 tiles found")

srcs = [rasterio.open(tile) for tile in tiles]
mosaic, transform = merge(srcs)
meta = srcs[0].meta.copy()
meta.update(
    {
        "driver": "GTiff",
        "height": mosaic.shape[1],
        "width": mosaic.shape[2],
        "transform": transform,
    }
)

out.parent.mkdir(parents=True, exist_ok=True)
with rasterio.open(out, "w", **meta) as dst:
    dst.write(mosaic)

for src in srcs:
    src.close()

print(out)
PY

echo "Merged DEM: $MERGED" >> "$OUTDIR/dem_status.txt"
```

### What this script does

It merges individual Copernicus COP30 DEM tiles covering Denmark into one
single raster file.

That merged raster is later used by Script 08 to read the elevation of each
Denmark grid cell centroid, which goes into the `ELEV` field of every WTH
header.

### Why elevation matters in WTH files

The DSSAT weather file header looks like this:

```
@ INSI      LAT     LONG  ELEV   TAV   AMP REFHT WNDHT
     1    54.95     8.83     5   8.7  15.7   -99   -99
```

The `ELEV` field (here `5` metres) tells DSSAT how high above sea level the
station is. DSSAT uses this for atmospheric pressure adjustments and related
calculations.

If `ELEV = 0` for coastal grid cells that actually sit at 3 to 8 metres, the
header is technically wrong even if DSSAT can still run.

The DEM fixes that.

### Line-by-line breakdown

```bash
export PATH="$HOME/.local/bin:$PATH"
unset PYTHONPATH || true
GEO_PY="/home/<user>/.conda/envs/mamba_env/envs/geo_env/bin/python"
```

These three lines solve the most common HPC Python problem: the wrong
interpreter or the wrong package set gets loaded.

- `PATH` is extended so locally installed tools come first
- `PYTHONPATH` is cleared so no old project packages accidentally load
- `GEO_PY` points to the exact Python binary inside the `geo_env` conda
  environment, which has `rasterio` and `geopandas` installed

Always use the full interpreter path in HPC scripts. Never rely on `python3`
resolving to the right environment.

```bash
BASE=/home/<user>/DEN
OUTDIR="$BASE/denmark/deliverables/validation"
mkdir -p "$OUTDIR"
```

`BASE` is the root of the Denmark project. `OUTDIR` is where the merged DEM
and all validation outputs will go. `mkdir -p` creates the directory tree if
it does not already exist.

```bash
echo "COP30 source tiles: $BASE/COP30" > "$OUTDIR/dem_status.txt"
find "$BASE/COP30" -maxdepth 1 -name '*.tif' | sort >> "$OUTDIR/dem_status.txt"
```

Before doing any work, the script writes a log. It records where the source
tiles came from and lists each file. This gives you a permanent audit trail
without opening any tool.

```bash
MERGED="$OUTDIR/denmark_dem_merged.tif"

if [ -f "$MERGED" ]; then
  echo "Merged DEM already exists: $MERGED" >> "$OUTDIR/dem_status.txt"
  exit 0
fi
```

If the merged file already exists, the script skips the merge and exits
cleanly. This makes the script safe to rerun. Rerunning `04_prepare_dem.sh`
a second time never damages the output.

```bash
$GEO_PY - <<'PY'
...
PY
```

This runs a Python heredoc. The shell passes everything between `<<'PY'` and
`PY` directly to the Python interpreter as standard input. The single-quoted
`'PY'` delimiter means no shell variable expansion happens inside the Python
block.

Inside the Python block:

```python
tiles = sorted(base.glob("*.tif"))
if not tiles:
    raise SystemExit("No COP30 tiles found")
```

`sorted()` guarantees a consistent tile order. `raise SystemExit` gives a
clear error message if the COP30 folder is empty, rather than silently
producing a broken output.

```python
srcs = [rasterio.open(tile) for tile in tiles]
mosaic, transform = merge(srcs)
```

`rasterio.merge.merge` stitches the tiles together into a single array
(`mosaic`) and computes the combined geotransform (`transform`) that describes
where the merged raster sits on Earth.

```python
meta = srcs[0].meta.copy()
meta.update(
    {
        "driver": "GTiff",
        "height": mosaic.shape[1],
        "width": mosaic.shape[2],
        "transform": transform,
    }
)
```

The metadata dictionary from the first tile is copied and updated with the
new dimensions and transform. The driver stays as `GTiff` because the COP30
tiles are GeoTIFF files.

```python
with rasterio.open(out, "w", **meta) as dst:
    dst.write(mosaic)

for src in srcs:
    src.close()
```

The merged raster is written to disk. Then every source file handle is
closed. Forgetting to close file handles on HPC can leave locked files and
cause problems for later scripts.

### Practical check

After this script runs, confirm the merged DEM exists and has the right
extent:

```bash
gdalinfo /home/<user>/DEN/denmark/deliverables/validation/denmark_dem_merged.tif \
  | grep -E "Origin|Pixel Size|Size"
```

The corner coordinates should bracket Denmark. If the extent covers only part
of Denmark, some COP30 tiles were missing from the `COP30/` folder.

---

## Script 05 — Merge, clip, and convert climate data

**File:** `05_merge_clip_convert_climate.sh`

```bash
#!/bin/bash
set -euo pipefail

exec /home/<user>/DEN/scripts/merge_denmark.sh "$@"
```

### What this script does

Like Script 01, this is a thin wrapper. The real processing logic is in the
pre-existing script:

```
/home/<user>/DEN/scripts/merge_denmark.sh
```

That script does the three most important preprocessing steps for each
model-scenario-variable combination:

1. **Merge** — yearly or decade-chunked NetCDF files are concatenated into one
   continuous time series
2. **Clip** — the global or European climate field is cut to Denmark's bounding
   box using the extent shapefile
3. **Convert** — raw ISIMIP3b units are converted to DSSAT-ready units

### Why unit conversion is the critical step

ISIMIP3b delivers data in SI units (inherited from the underlying CMIP6 models):

| Variable | Raw ISIMIP3b unit | Meaning |
|---|---|---|
| `pr` | kg m⁻² s⁻¹ | precipitation flux |
| `tas`, `tasmax`, `tasmin` | K | temperature in Kelvin |
| `rsds` | W m⁻² | watts per square metre |

DSSAT expects:

| Variable | DSSAT unit |
|---|---|
| `RAIN` | mm/day |
| `TMAX`, `TMIN` | °C |
| `SRAD` | MJ m⁻² day⁻¹ |

The conversion formulas used are:

```
pr [mm/day]        = pr [kg/m²/s] × 86400
tas [°C]           = tas [K] − 273.15
tasmax [°C]        = tasmax [K] − 273.15
tasmin [°C]        = tasmin [K] − 273.15
rsds [MJ/m²/day]   = rsds [W/m²] × 0.0864
```

The 86400 factor for precipitation converts seconds to days (1 day = 86400 s).
The 0.0864 factor for radiation converts W/m² to MJ/m²/day
(1 W/m² × 86400 s/day ÷ 1,000,000 J/MJ = 0.0864).

### Output files produced

For each model and scenario, this step produces five NetCDF files:

```
/home/<user>/DEN/{MODEL}/processed/
    {MODEL}_{SCENARIO}_pr_denmark.nc
    {MODEL}_{SCENARIO}_tas_denmark.nc
    {MODEL}_{SCENARIO}_tasmax_denmark.nc
    {MODEL}_{SCENARIO}_tasmin_denmark.nc
    {MODEL}_{SCENARIO}_rsds_denmark.nc
```

Five models × four scenarios × five variables = **100 processed NetCDF files**
in total.

### A real problem we hit here

During production, two files for `MPI-ESM1-2-HR / ssp370` were found
corrupted:

```
MPI-ESM1-2-HR_ssp370_tasmin_denmark.nc
MPI-ESM1-2-HR_ssp370_rsds_denmark.nc
```

They had to be rebuilt from raw by rerunning the merge-clip-convert logic on
the raw source files. After rebuilding, the downstream WTH generation for that
model-scenario combination ran correctly.

If you see a model-scenario combination missing from the final WTH output,
always check whether its processed NetCDFs are intact first.

---

## Script 06 — Compute TAV and AMP

**File:** `06_compute_tav_amp.py`

```python
#!/usr/bin/env python3
from pathlib import Path
import argparse
import pandas as pd
import xarray as xr


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Compute Denmark TAV/AMP from processed NetCDFs."
    )
    parser.add_argument("--model", required=True)
    parser.add_argument("--scenario", required=True)
    parser.add_argument("--start-year", type=int)
    parser.add_argument("--end-year", type=int)
    args = parser.parse_args()

    base = Path("/home/<user>/DEN")
    tasmax = (
        base / args.model / "processed"
        / f"{args.model}_{args.scenario}_tasmax_denmark.nc"
    )
    tasmin = (
        base / args.model / "processed"
        / f"{args.model}_{args.scenario}_tasmin_denmark.nc"
    )
    if not tasmax.exists() or not tasmin.exists():
        raise SystemExit("Missing tasmax or tasmin processed NetCDF")

    dsx = xr.open_dataset(tasmax)
    dsn = xr.open_dataset(tasmin)
    tx = (
        dsx["tasmax"]
        .mean(dim=[d for d in dsx["tasmax"].dims if d != "time"])
        .to_series()
    )
    tn = (
        dsn["tasmin"]
        .mean(dim=[d for d in dsn["tasmin"].dims if d != "time"])
        .to_series()
    )
    df = pd.DataFrame(
        {"date": pd.to_datetime(tx.index), "tasmax": tx.values}
    ).merge(
        pd.DataFrame({"date": pd.to_datetime(tn.index), "tasmin": tn.values}),
        on="date",
        how="inner",
    )
    if args.start_year is not None:
        df = df[df["date"].dt.year >= args.start_year]
    if args.end_year is not None:
        df = df[df["date"].dt.year <= args.end_year]
    if df.empty:
        raise SystemExit("No overlapping tasmax/tasmin dates after filtering")

    tavg = (df["tasmax"] + df["tasmin"]) / 2.0
    tav_val = float(tavg.mean())
    monthly = (
        df.assign(month=df["date"].dt.month)
        .groupby("month")[["tasmax", "tasmin"]]
        .mean()
    )
    monthly_tavg = (monthly["tasmax"] + monthly["tasmin"]) / 2.0
    amp_val = float(monthly_tavg.max() - monthly_tavg.min())

    period = f"{df['date'].dt.year.min()}_{df['date'].dt.year.max()}"
    outdir = (
        base / "denmark" / "deliverables" / "tav_amp"
        / args.model / args.scenario / period
    )
    outdir.mkdir(parents=True, exist_ok=True)
    out = outdir / "tav_amp.csv"
    pd.DataFrame(
        [
            {
                "model": args.model,
                "scenario": args.scenario,
                "tav_degC": round(tav_val, 3),
                "amp_degC": round(amp_val, 3),
            }
        ]
    ).to_csv(out, index=False)
    dsx.close()
    dsn.close()
    print(out)


if __name__ == "__main__":
    main()
```

### What this script produces

For each model-scenario pair it writes one CSV file:

```
deliverables/tav_amp/GFDL_ESM4/historical/1971_2014/tav_amp.csv
```

That CSV contains two numbers:

```
model,scenario,tav_degC,amp_degC
GFDL_ESM4,historical,7.951,16.528
```

Those two numbers end up in the header of every WTH file for that
model-scenario combination.

### What TAV and AMP mean for DSSAT

**TAV** is the long-term mean annual temperature at the site in degrees
Celsius. DSSAT uses it for soil temperature initialisation.

**AMP** is the mean annual amplitude — the difference between the warmest
month's average temperature and the coldest month's average temperature. It
describes how strongly the site's temperature cycles through the year. A site
in Denmark has a large AMP (~16 °C) because summers and winters are very
different. A tropical site has a small AMP (3 to 5 °C).

### Line-by-line breakdown

```python
parser = argparse.ArgumentParser(
    description="Compute Denmark TAV/AMP from processed NetCDFs."
)
parser.add_argument("--model", required=True)
parser.add_argument("--scenario", required=True)
parser.add_argument("--start-year", type=int)
parser.add_argument("--end-year", type=int)
args = parser.parse_args()
```

The script takes four command-line arguments. `--model` and `--scenario` are
required. The year filters are optional — when omitted, the full time range
in the NetCDF is used.

This design means the script can be called for any model-scenario combination
without editing the code.

```python
tasmax = (
    base / args.model / "processed"
    / f"{args.model}_{args.scenario}_tasmax_denmark.nc"
)
tasmin = (
    base / args.model / "processed"
    / f"{args.model}_{args.scenario}_tasmin_denmark.nc"
)
if not tasmax.exists() or not tasmin.exists():
    raise SystemExit("Missing tasmax or tasmin processed NetCDF")
```

The script builds the expected file paths from the arguments and checks they
exist before trying to open them. A `SystemExit` with a clear message is
better than letting `xr.open_dataset` crash with a cryptic error.

```python
dsx = xr.open_dataset(tasmax)
dsn = xr.open_dataset(tasmin)
tx = (
    dsx["tasmax"]
    .mean(dim=[d for d in dsx["tasmax"].dims if d != "time"])
    .to_series()
)
```

This opens both NetCDF files and reduces the spatial dimensions to a single
Denmark-wide daily mean. The expression
`[d for d in dsx["tasmax"].dims if d != "time"]` builds a list of all
dimensions except `time` — typically `["lat", "lon"]` — and averages over
them. The result is a daily time series of the Denmark-mean maximum temperature.

Taking a spatial mean here is a simplification. It produces one TAV/AMP pair
per model-scenario combination rather than one per grid cell. The per-cell
TAV and AMP values are computed later inside Script 08 from the actual zone
data.

```python
df = pd.DataFrame(
    {"date": pd.to_datetime(tx.index), "tasmax": tx.values}
).merge(
    pd.DataFrame({"date": pd.to_datetime(tn.index), "tasmin": tn.values}),
    on="date",
    how="inner",
)
```

The two time series (tasmax and tasmin) are joined on date using an inner
merge. Inner merge means only dates present in both series are kept. This
protects against misaligned time coordinates between the two NetCDF files.

```python
if args.start_year is not None:
    df = df[df["date"].dt.year >= args.start_year]
if args.end_year is not None:
    df = df[df["date"].dt.year <= args.end_year]
if df.empty:
    raise SystemExit("No overlapping tasmax/tasmin dates after filtering")
```

The optional year filters are applied. If after filtering nothing remains
(the requested years are outside the NetCDF range), the script exits with a
clear error.

```python
tavg = (df["tasmax"] + df["tasmin"]) / 2.0
tav_val = float(tavg.mean())
```

TAV is the mean of the daily mean temperatures across the whole period. The
daily mean temperature is approximated as `(tasmax + tasmin) / 2`.

```python
monthly = (
    df.assign(month=df["date"].dt.month)
    .groupby("month")[["tasmax", "tasmin"]]
    .mean()
)
monthly_tavg = (monthly["tasmax"] + monthly["tasmin"]) / 2.0
amp_val = float(monthly_tavg.max() - monthly_tavg.min())
```

AMP is derived from monthly averages. Each month's mean maximum and minimum
are averaged, then AMP is the difference between the warmest and coldest
month. This is a 12-value lookup, not day-by-day.

```python
period = f"{df['date'].dt.year.min()}_{df['date'].dt.year.max()}"
outdir = (
    base / "denmark" / "deliverables" / "tav_amp"
    / args.model / args.scenario / period
)
outdir.mkdir(parents=True, exist_ok=True)
```

The output directory is constructed from the data itself. If the NetCDF
spans 1971 to 2014, `period` becomes `"1971_2014"`. This makes the output
path self-documenting and avoids hardcoding year ranges.

```python
pd.DataFrame(
    [
        {
            "model": args.model,
            "scenario": args.scenario,
            "tav_degC": round(tav_val, 3),
            "amp_degC": round(amp_val, 3),
        }
    ]
).to_csv(out, index=False)
dsx.close()
dsn.close()
print(out)
```

The output CSV has exactly one row. Values are rounded to 3 decimal places.
Both dataset handles are closed before the script exits. The path of the
output file is printed so the calling shell script can log it.

---

## Script 07 — Extract zonal statistics to Parquet

**File:** `07_extract_zonal_stats_parquet.py`

```python
#!/usr/bin/env python3
"""Convert Denmark processed NetCDF files into Ethiopia-style zonal parquet outputs."""

import argparse
from pathlib import Path

import geopandas as gpd
import numpy as np
import pandas as pd
import xarray as xr
from shapely.geometry import Point


def find_cells(geometry, lons, lats):
    bounds = geometry.bounds
    lon_idx = np.where((lons >= bounds[0]) & (lons <= bounds[2]))[0]
    lat_idx = np.where((lats >= bounds[1]) & (lats <= bounds[3]))[0]
    hits = []
    for yi in lat_idx:
        for xi in lon_idx:
            if geometry.contains(Point(lons[xi], lats[yi])):
                hits.append((yi, xi))
    return hits


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True)
    parser.add_argument("--scenario", required=True)
    parser.add_argument("--variable", required=True)
    parser.add_argument("--start-year", type=int)
    parser.add_argument("--end-year", type=int)
    args = parser.parse_args()

    base = Path("/home/<user>/DEN")
    nc_file = (
        base / args.model / "processed"
        / f"{args.model}_{args.scenario}_{args.variable}_denmark.nc"
    )
    shp = base / "shapefiles" / "denmark_grid_05deg.shp"
    gdf = gpd.read_file(shp)
    ds = xr.open_dataset(nc_file)
    var = ds[args.variable]
    lats = ds["lat"].values if "lat" in ds.coords else ds["latitude"].values
    lons = ds["lon"].values if "lon" in ds.coords else ds["longitude"].values
    times = pd.to_datetime(ds["time"].values)
    if args.start_year is not None:
        mask = times.year >= args.start_year
        var = var.isel(time=mask)
        times = times[mask]
    if args.end_year is not None:
        mask = times.year <= args.end_year
        var = var.isel(time=mask)
        times = times[mask]
    if len(times) == 0:
        raise SystemExit("No timesteps remain after filtering")
    period = f"{times.min().year}_{times.max().year}"
    out_dir = (
        base
        / "denmark"
        / "deliverables"
        / "parquet_zonal_stats"
        / args.model
        / args.scenario
        / period
        / args.variable
    )
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / f"{args.variable}.parquet"

    rows = []
    for idx, row in gdf.iterrows():
        zone_id = int(row.get("grid_id", idx + 1))
        cells = find_cells(row.geometry, lons, lats)
        if not cells:
            continue
        yi = [c[0] for c in cells]
        xi = [c[1] for c in cells]
        values = var.values[:, yi, xi]
        mean_values = np.nanmean(values, axis=1)
        counts = np.sum(~np.isnan(values), axis=1)
        rows.append(
            pd.DataFrame(
                {
                    "zone_id": zone_id,
                    "date": times,
                    "value": mean_values,
                    "cell_count": counts,
                }
            )
        )

    if not rows:
        raise SystemExit("No zonal rows created")

    pd.concat(rows, ignore_index=True).to_parquet(out_file, index=False)
    ds.close()
    print(out_file)


if __name__ == "__main__":
    main()
```

### What this script produces

For each model, scenario, variable, and period it writes one Parquet file:

```
deliverables/parquet_zonal_stats/
    GFDL_ESM4/
        historical/
            1971_2014/
                pr/pr.parquet
                tasmax/tasmax.parquet
                tasmin/tasmin.parquet
                rsds/rsds.parquet
```

Each Parquet file has one row per zone per day:

| zone_id | date | value | cell_count |
|---|---|---|---|
| 1 | 1971-01-01 | 0.0 | 1 |
| 1 | 1971-01-02 | 1.6 | 1 |
| ... | ... | ... | ... |
| 58 | 2014-12-31 | 2.3 | 1 |

### What Parquet is and why it is used here

Parquet is a column-oriented binary file format. Compared to CSV:

- much smaller file size for the same data
- much faster to read in Python with pandas or pyarrow
- stores data types exactly (no ambiguity between integers and strings)

For a daily time series over 58 zones and 44 years, a CSV would have
about 930,000 rows per variable. Parquet compresses this by 5 to 10 times
and reads it roughly 10 times faster.

### The `find_cells` function

```python
def find_cells(geometry, lons, lats):
    bounds = geometry.bounds
    lon_idx = np.where((lons >= bounds[0]) & (lons <= bounds[2]))[0]
    lat_idx = np.where((lats >= bounds[1]) & (lats <= bounds[3]))[0]
    hits = []
    for yi in lat_idx:
        for xi in lon_idx:
            if geometry.contains(Point(lons[xi], lats[yi])):
                hits.append((yi, xi))
    return hits
```

This function answers the question: which NetCDF grid points fall inside this
shapefile polygon?

**Step 1 — bounding box pre-filter:**

```python
bounds = geometry.bounds
lon_idx = np.where((lons >= bounds[0]) & (lons <= bounds[2]))[0]
lat_idx = np.where((lats >= bounds[1]) & (lats <= bounds[3]))[0]
```

`geometry.bounds` returns `(minx, miny, maxx, maxy)` for the polygon.
The numpy `where` calls find all longitude indices that fall within the
east-west range and all latitude indices that fall within the north-south
range. This pre-filter makes the full search much faster by limiting the
candidate cells before the slower point-in-polygon test.

**Step 2 — point-in-polygon test:**

```python
for yi in lat_idx:
    for xi in lon_idx:
        if geometry.contains(Point(lons[xi], lats[yi])):
            hits.append((yi, xi))
```

For each candidate cell, a `Point` is constructed from its longitude and
latitude and tested against the polygon using Shapely's `contains` method.
Only cells whose centre point falls strictly inside the polygon are kept.

The function returns a list of `(yi, xi)` index pairs — the row and column
indices into the NetCDF data array.

### Line-by-line breakdown of `main`

```python
lats = ds["lat"].values if "lat" in ds.coords else ds["latitude"].values
lons = ds["lon"].values if "lon" in ds.coords else ds["longitude"].values
```

Different ISIMIP providers use slightly different coordinate names. Some use
`lat`/`lon`, others use `latitude`/`longitude`. This one-liner handles both
without crashing.

```python
times = pd.to_datetime(ds["time"].values)
if args.start_year is not None:
    mask = times.year >= args.start_year
    var = var.isel(time=mask)
    times = times[mask]
```

The time dimension is converted to pandas DatetimeIndex immediately. Pandas
datetime operations (`.year`, `.month`, etc.) are simpler and more reliable
than xarray's own time filtering. The `isel` call selects only the time steps
that pass the year filter, keeping the data and times in sync.

```python
for idx, row in gdf.iterrows():
    zone_id = int(row.get("grid_id", idx + 1))
    cells = find_cells(row.geometry, lons, lats)
    if not cells:
        continue
    yi = [c[0] for c in cells]
    xi = [c[1] for c in cells]
    values = var.values[:, yi, xi]
    mean_values = np.nanmean(values, axis=1)
    counts = np.sum(~np.isnan(values), axis=1)
```

The outer loop iterates over every Denmark grid polygon. For each polygon:

- `find_cells` returns the NetCDF indices for all grid points inside it
- `var.values[:, yi, xi]` extracts a 2D array of shape `(n_days, n_cells)`
- `np.nanmean(..., axis=1)` averages across cells for each day, ignoring
  NaN values (ocean cells in the NetCDF return NaN)
- `counts` records how many non-NaN cells contributed to each day's average,
  which is useful for QC later

```python
rows.append(
    pd.DataFrame(
        {
            "zone_id": zone_id,
            "date": times,
            "value": mean_values,
            "cell_count": counts,
        }
    )
)
```

Each zone becomes one DataFrame with one row per day. All zone DataFrames
are collected in `rows`.

```python
pd.concat(rows, ignore_index=True).to_parquet(out_file, index=False)
```

All zone DataFrames are concatenated and written as a single Parquet file.
`ignore_index=True` resets the row index to 0, 1, 2, … so there are no
duplicate index values. `index=False` keeps the Parquet file clean by not
writing the index as an extra column.

---

## Script 08 — Generate DSSAT WTH files

**File:** `08_generate_wth_files.py`

```python
#!/usr/bin/env python3
"""Generate Denmark DSSAT WTH files from Denmark parquet zonal stats."""

from __future__ import annotations

import argparse
from pathlib import Path

import pandas as pd

VARIABLES = ["pr", "tasmax", "tasmin", "rsds"]
COLUMN_MAP = {"pr": "RAIN", "tasmax": "TMAX", "tasmin": "TMIN", "rsds": "SRAD"}
DEFAULT_DEM = Path(
    "/home/<user>/DEN/denmark/deliverables/validation/denmark_dem_merged.tif"
)
MIN_VALID_ELEV = 1.0


def load_zone_metadata(shapefile: Path, dem_raster: Path | None):
    import geopandas as gpd
    import rasterio
    from rasterstats import zonal_stats

    gdf = gpd.read_file(shapefile)
    extent_path = Path("/home/<user>/DEN/shapefiles/denmark_extent.shp")
    land_geom = None
    if extent_path.exists():
        extent_gdf = gpd.read_file(extent_path)
        land_geom = (
            extent_gdf.union_all()
            if hasattr(extent_gdf, "union_all")
            else extent_gdf.unary_union
        )
    meta = {}
    sample_points = []
    zone_ids = []
    land_shapes = []
    for idx, row in gdf.iterrows():
        zone_id = int(row.get("grid_id", idx + 1))
        geom = row.geometry
        if land_geom is not None:
            clipped = geom.intersection(land_geom)
            if not clipped.is_empty:
                geom = clipped
        centroid = geom.centroid
        meta[zone_id] = {"lat": float(centroid.y), "lon": float(centroid.x), "elev": 0.0}
        sample_points.append((float(centroid.x), float(centroid.y)))
        zone_ids.append(zone_id)
        land_shapes.append(geom)

    if dem_raster and dem_raster.exists():
        with rasterio.open(dem_raster) as src:
            nodata = src.nodata
            samples = list(src.sample(sample_points))
        stats = zonal_stats(land_shapes, dem_raster, stats=["mean", "max"], nodata=nodata)
        for zone_id, sample in zip(zone_ids, samples):
            elev = float(sample[0]) if sample is not None and len(sample) else 0.0
            if nodata is not None and elev == nodata:
                elev = 0.0
            meta[zone_id]["elev"] = elev
        for zone_id, stat in zip(zone_ids, stats):
            if meta[zone_id]["elev"] <= 0 and stat.get("mean") is not None:
                meta[zone_id]["elev"] = float(stat["mean"])
            if meta[zone_id]["elev"] <= 0 and stat.get("max") is not None:
                meta[zone_id]["elev"] = float(stat["max"])

        positive = [zid for zid in zone_ids if meta[zid]["elev"] >= MIN_VALID_ELEV]
        for zone_id in zone_ids:
            if meta[zone_id]["elev"] >= MIN_VALID_ELEV or not positive:
                continue
            lat = meta[zone_id]["lat"]
            lon = meta[zone_id]["lon"]
            nearest = min(
                positive,
                key=lambda zid: (meta[zid]["lat"] - lat) ** 2
                + (meta[zid]["lon"] - lon) ** 2,
            )
            meta[zone_id]["elev"] = meta[nearest]["elev"]
    return meta


def normalize_srad(series: pd.Series) -> pd.Series:
    max_val = float(series.max()) if not series.empty else 0.0
    if max_val > 10000:
        return series / 1_000_000.0
    if max_val > 100:
        return series * 0.0864
    return series


def write_wth(
    output_path: Path,
    zone_id: int,
    zone_df: pd.DataFrame,
    zone_meta: dict[str, float],
) -> None:
    tavg = (zone_df["TMAX"] + zone_df["TMIN"]) / 2.0
    tav = round(float(tavg.mean()), 1)
    monthly = (
        zone_df.assign(month=pd.to_datetime(zone_df["date"]).dt.month)
        .groupby("month")[["TMAX", "TMIN"]]
        .mean()
    )
    monthly_tavg = (monthly["TMAX"] + monthly["TMIN"]) / 2.0
    amp = round(float(monthly_tavg.max() - monthly_tavg.min()), 1)
    years = sorted(zone_df["year"].unique())
    start_year = years[0]

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", encoding="ascii", newline="\n") as h:
        h.write(f"*WEATHER DATA : {zone_id:04d} {start_year}\n")
        h.write("@ INSI      LAT     LONG  ELEV   TAV   AMP REFHT WNDHT\n")
        h.write(
            f"{zone_id:>6}"
            f"{zone_meta['lat']:>9.2f}"
            f"{zone_meta['lon']:>9.2f}"
            f"{zone_meta['elev']:>6.0f}"
            f"{tav:>6.1f}"
            f"{amp:>6.1f}"
            f"{-99:>6}"
            f"{-99:>6}\n"
        )
        h.write("@DATE  SRAD  TMAX  TMIN  RAIN\n")
        for year, doy, srad, tmax, tmin, rain in zone_df[
            ["year", "doy", "SRAD", "TMAX", "TMIN", "RAIN"]
        ].itertuples(index=False, name=None):
            h.write(
                f"{int(year) % 100:02d}{int(doy):03d}"
                f"{float(srad):6.1f}"
                f"{float(tmax):6.1f}"
                f"{float(tmin):6.1f}"
                f"{float(rain):6.1f}\n"
            )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True)
    parser.add_argument("--scenario", required=True)
    parser.add_argument("--period", required=True)
    parser.add_argument("--dem-raster", default=str(DEFAULT_DEM))
    args = parser.parse_args()

    base = Path("/home/<user>/DEN/denmark/deliverables")
    zonal_dir = base / "parquet_zonal_stats" / args.model / args.scenario / args.period
    out_dir = base / "wth" / args.model / args.scenario / args.period
    meta = load_zone_metadata(
        Path("/home/<user>/DEN/shapefiles/denmark_grid_05deg.shp"),
        Path(args.dem_raster) if args.dem_raster else None,
    )

    zone_data = {}
    for var in VARIABLES:
        pq = zonal_dir / var / f"{var}.parquet"
        if not pq.exists():
            raise SystemExit(f"Missing {pq}")
        zone_data[var] = pd.read_parquet(pq)

    merged = zone_data["pr"][["zone_id", "date", "value"]].rename(
        columns={"value": "RAIN"}
    )
    for var in VARIABLES[1:]:
        df = zone_data[var][["zone_id", "date", "value"]].rename(
            columns={"value": COLUMN_MAP[var]}
        )
        merged = merged.merge(df, on=["zone_id", "date"], how="inner")

    merged["date"] = pd.to_datetime(merged["date"])
    merged["SRAD"] = normalize_srad(merged["SRAD"])
    merged["year"] = merged["date"].dt.year
    merged["doy"] = merged["date"].dt.dayofyear

    for zone_id, zone_df in merged.groupby("zone_id"):
        years = sorted(zone_df["year"].unique())
        filename = f"{int(zone_id):04d}{years[0] % 100:02d}{len(years):02d}.WTH"
        write_wth(
            out_dir / filename,
            int(zone_id),
            zone_df.sort_values("date"),
            meta[int(zone_id)],
        )

    print(out_dir)


if __name__ == "__main__":
    main()
```

### What this script produces

One `.WTH` file per Denmark grid cell per model-scenario combination:

```
deliverables/wth/GFDL_ESM4/historical/1971_2014/
    00017144.WTH
    00027144.WTH
    ...
    05807144.WTH
```

The filename pattern is `{zone_id:04d}{yy:02d}{n_years:02d}.WTH`.

For zone 1, starting in 1971, spanning 44 years: `00017144.WTH`.

Each file looks like this:

```
*WEATHER DATA : 0001 1971
@ INSI      LAT     LONG  ELEV   TAV   AMP REFHT WNDHT
     1    54.95     8.83     5   8.7  15.7   -99   -99
@DATE  SRAD  TMAX  TMIN  RAIN
71001   1.2   2.6  -4.7   0.0
71002   2.9  -3.3  -7.4   0.0
...
```

### The module-level constants

```python
VARIABLES = ["pr", "tasmax", "tasmin", "rsds"]
COLUMN_MAP = {"pr": "RAIN", "tasmax": "TMAX", "tasmin": "TMIN", "rsds": "SRAD"}
DEFAULT_DEM = Path(
    "/home/<user>/DEN/denmark/deliverables/validation/denmark_dem_merged.tif"
)
MIN_VALID_ELEV = 1.0
```

Defining constants at the top of the file rather than buried in functions
makes them easy to find and change. `MIN_VALID_ELEV = 1.0` sets the
threshold below which an elevation value is considered suspect (likely a
water cell or a nodata misread). Any zone with elevation below 1 metre gets
the fallback logic.

### The `load_zone_metadata` function

This function returns a dictionary keyed by `zone_id`, with each value
containing the latitude, longitude, and elevation for that zone.

```python
land_geom = None
if extent_path.exists():
    extent_gdf = gpd.read_file(extent_path)
    land_geom = (
        extent_gdf.union_all()
        if hasattr(extent_gdf, "union_all")
        else extent_gdf.unary_union
    )
```

The Denmark extent shapefile is read and dissolved into a single geometry
representing all land area. This is used in the next block to clip the grid
polygons so coastal cells only sample elevation over their land portion.

`union_all` is the newer geopandas method; `unary_union` is the older one.
The `hasattr` check makes the script compatible with both.

```python
for idx, row in gdf.iterrows():
    zone_id = int(row.get("grid_id", idx + 1))
    geom = row.geometry
    if land_geom is not None:
        clipped = geom.intersection(land_geom)
        if not clipped.is_empty:
            geom = clipped
    centroid = geom.centroid
```

Each grid polygon is intersected with the land boundary. For a purely inland
grid cell the intersection returns the same polygon. For a coastal cell that
is half sea, the intersection returns only the land portion. The centroid is
then computed from the land-only shape, so it sits on land rather than in
the sea.

**The four-level elevation fallback:**

```python
# Level 1: DEM point sample at the land centroid
with rasterio.open(dem_raster) as src:
    nodata = src.nodata
    samples = list(src.sample(sample_points))
for zone_id, sample in zip(zone_ids, samples):
    elev = float(sample[0]) if sample is not None and len(sample) else 0.0
    if nodata is not None and elev == nodata:
        elev = 0.0
    meta[zone_id]["elev"] = elev

# Level 2 and 3: zonal mean, then max, if point sample failed
stats = zonal_stats(land_shapes, dem_raster, stats=["mean", "max"], nodata=nodata)
for zone_id, stat in zip(zone_ids, stats):
    if meta[zone_id]["elev"] <= 0 and stat.get("mean") is not None:
        meta[zone_id]["elev"] = float(stat["mean"])
    if meta[zone_id]["elev"] <= 0 and stat.get("max") is not None:
        meta[zone_id]["elev"] = float(stat["max"])

# Level 4: nearest valid neighbour
positive = [zid for zid in zone_ids if meta[zid]["elev"] >= MIN_VALID_ELEV]
for zone_id in zone_ids:
    if meta[zone_id]["elev"] >= MIN_VALID_ELEV or not positive:
        continue
    nearest = min(
        positive,
        key=lambda zid: (meta[zid]["lat"] - lat) ** 2
        + (meta[zid]["lon"] - lon) ** 2,
    )
    meta[zone_id]["elev"] = meta[nearest]["elev"]
```

Before this four-level fallback was added, many coastal Denmark grid cells
got `ELEV = 0` because their centroid fell in the sea and the DEM returned
nodata there. The fallback ensures every zone ends up with a physically
plausible elevation.

### The `normalize_srad` function

```python
def normalize_srad(series: pd.Series) -> pd.Series:
    max_val = float(series.max()) if not series.empty else 0.0
    if max_val > 10000:
        return series / 1_000_000.0
    if max_val > 100:
        return series * 0.0864
    return series
```

This function handles solar radiation unit ambiguity robustly.

ISIMIP3b data sometimes arrives as W/m² and sometimes the unit conversion
in Script 05 already applied the 0.0864 factor. The maximum value in the
series reveals which case we are in:

- If max > 10,000: the values are in J/m²/day (raw energy totals). Divide by
  1,000,000 to get MJ/m²/day.
- If max > 100: the values are in W/m². Multiply by 0.0864 to convert to
  MJ/m²/day.
- Otherwise: values are already in MJ/m²/day. Return unchanged.

This defensive approach prevents radiation values 1,000 times too large
from silently corrupting the WTH files.

### The `write_wth` function — building the WTH header

```python
tavg = (zone_df["TMAX"] + zone_df["TMIN"]) / 2.0
tav = round(float(tavg.mean()), 1)
monthly = (
    zone_df.assign(month=pd.to_datetime(zone_df["date"]).dt.month)
    .groupby("month")[["TMAX", "TMIN"]]
    .mean()
)
monthly_tavg = (monthly["TMAX"] + monthly["TMIN"]) / 2.0
amp = round(float(monthly_tavg.max() - monthly_tavg.min()), 1)
```

TAV and AMP are computed per zone from the actual zone data. These are
therefore slightly different from the domain-average TAV/AMP in Script 06.
The values written to the WTH header are the per-zone values here.

```python
with open(output_path, "w", encoding="ascii", newline="\n") as h:
    h.write(f"*WEATHER DATA : {zone_id:04d} {start_year}\n")
    h.write("@ INSI      LAT     LONG  ELEV   TAV   AMP REFHT WNDHT\n")
    h.write(
        f"{zone_id:>6}"
        f"{zone_meta['lat']:>9.2f}"
        f"{zone_meta['lon']:>9.2f}"
        f"{zone_meta['elev']:>6.0f}"
        f"{tav:>6.1f}"
        f"{amp:>6.1f}"
        f"{-99:>6}"
        f"{-99:>6}\n"
    )
```

Two things matter in this block:

1. `encoding="ascii"` — DSSAT reads weather files as plain ASCII. Using
   UTF-8 or Latin-1 can cause invisible character problems.
2. `newline="\n"` — DSSAT expects Unix-style line endings. If you let Python
   use the platform default on Windows, you get `\r\n` line endings, which
   can confuse DSSAT's fixed-width parser.

The format strings use right-aligned field widths (`>6`, `>9.2f`, etc.) to
match the exact column positions expected by DSSAT. Even one character off
can cause DSSAT to misread a value.

`-99` for `REFHT` and `WNDHT` is the DSSAT missing-value code, indicating
that reference height for humidity and wind height are not provided. DSSAT
handles this gracefully.

### Writing the daily data rows

```python
h.write("@DATE  SRAD  TMAX  TMIN  RAIN\n")
for year, doy, srad, tmax, tmin, rain in zone_df[
    ["year", "doy", "SRAD", "TMAX", "TMIN", "RAIN"]
].itertuples(index=False, name=None):
    h.write(
        f"{int(year) % 100:02d}{int(doy):03d}"
        f"{float(srad):6.1f}"
        f"{float(tmax):6.1f}"
        f"{float(tmin):6.1f}"
        f"{float(rain):6.1f}\n"
    )
```

`int(year) % 100` converts a 4-digit year to a 2-digit year: 1971 becomes
71, 2031 becomes 31. DSSAT's `@DATE` field is `YYDDD` format — two-digit
year plus three-digit day-of-year. So 1 January 1971 becomes `71001`.

`itertuples` is used instead of `iterrows` because it is significantly faster
when writing many rows. The `name=None` argument suppresses the named-tuple
wrapper for a small additional speed gain.

### Building the WTH filename

```python
filename = f"{int(zone_id):04d}{years[0] % 100:02d}{len(years):02d}.WTH"
```

For zone 1, starting in 1971, spanning 44 years: `00017144.WTH`.
- `0001` — zone ID, zero-padded to 4 digits
- `71` — two-digit start year (1971 % 100)
- `44` — number of years in the file

This naming convention is consistent with how DSSAT weather files are
typically named.

---

## Script 09 — Validate outputs

**File:** `09_validate_outputs.py`

```python
#!/usr/bin/env python3
from pathlib import Path

base = Path("/home/<user>/DEN/denmark/deliverables")
for label, pattern in [
    ("parquet", "parquet_zonal_stats/**/*.parquet"),
    ("wth", "wth/**/*.WTH"),
    ("tav_amp", "tav_amp/**/*.csv"),
]:
    print(label, len(list(base.rglob(pattern.split("**/")[-1]))))
```

### What this script does

It counts the deliverables produced.

After a full production run, running this script should print:

```
parquet 80
wth 1160
tav_amp 20
```

### Why those numbers

- **80 parquet files** = 5 models × 4 scenarios × 4 variables
- **1160 WTH files** = 5 models × 4 scenarios × 58 Denmark grid cells
- **20 TAV/AMP files** = 5 models × 4 scenarios

If any number is wrong, you know which layer of the pipeline to investigate.
If `parquet` is 76 instead of 80, four Parquet jobs failed. If `wth` is 1102
instead of 1160, one model-scenario combination's 58 WTH files are missing.

### The rglob trick

```python
base.rglob(pattern.split("**/")[-1])
```

`split("**/")[-1]` extracts just the filename extension pattern
(e.g. `*.parquet`). Then `rglob` searches recursively for all files
matching that pattern. This avoids needing to know the exact directory depth,
which changes between models and scenarios.

---

## Script 10 — Run one model-scenario combination

**File:** `10_run_model_scenario_weather.sh`

```bash
#!/bin/bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
unset PYTHONPATH || true
GEO_PY="/home/<user>/.conda/envs/mamba_env/envs/geo_env/bin/python"
GEO_ENV_ROOT="/home/<user>/.conda/envs/mamba_env/envs/geo_env"
if [ -d "$GEO_ENV_ROOT/share/proj" ]; then
  export PROJ_LIB="$GEO_ENV_ROOT/share/proj"
fi

if [ $# -ne 2 ]; then
  echo "Usage: $0 MODEL SCENARIO"
  exit 1
fi

MODEL="$1"
SCENARIO="$2"
BASE="/home/<user>/DEN/denmark"

echo "=================================================="
echo "DENMARK WEATHER PIPELINE"
echo "MODEL: $MODEL"
echo "SCENARIO: $SCENARIO"
echo "START: $(date)"
echo "=================================================="

read START_YEAR END_YEAR <<< "$($GEO_PY - <<PY
from pathlib import Path
import xarray as xr
base = Path("/home/<user>/DEN")
model = "$MODEL"
scenario = "$SCENARIO"
p = base / model / "processed" / f"{model}_{scenario}_pr_denmark.nc"
ds = xr.open_dataset(p)
t = ds["time"].values
print(str(t[0])[:4], str(t[-1])[:4])
ds.close()
PY
)"

$GEO_PY "$BASE/scripts/06_compute_tav_amp.py" \
  --model "$MODEL" \
  --scenario "$SCENARIO" \
  --start-year "$START_YEAR" \
  --end-year "$END_YEAR"

for VAR in pr tasmax tasmin rsds; do
  echo "Extracting parquet for $MODEL / $SCENARIO / $VAR"
  $GEO_PY "$BASE/scripts/07_extract_zonal_stats_parquet.py" \
    --model "$MODEL" \
    --scenario "$SCENARIO" \
    --variable "$VAR" \
    --start-year "$START_YEAR" \
    --end-year "$END_YEAR"
done

PERIOD="${START_YEAR}_${END_YEAR}"

echo "Generating WTH files for $MODEL / $SCENARIO / $PERIOD"
$GEO_PY "$BASE/scripts/08_generate_wth_files.py" \
  --model "$MODEL" \
  --scenario "$SCENARIO" \
  --period "$PERIOD"

echo "DONE: $MODEL / $SCENARIO at $(date)"
```

### What this script does

This is the main per-job orchestration script.

When you call:

```bash
./10_run_model_scenario_weather.sh GFDL_ESM4 historical
```

it runs Scripts 06, 07 (×4 variables), and 08 in sequence for that one
model-scenario combination.

### Line-by-line breakdown

```bash
GEO_PY="/home/<user>/.conda/envs/mamba_env/envs/geo_env/bin/python"
GEO_ENV_ROOT="/home/<user>/.conda/envs/mamba_env/envs/geo_env"
if [ -d "$GEO_ENV_ROOT/share/proj" ]; then
  export PROJ_LIB="$GEO_ENV_ROOT/share/proj"
fi
```

`PROJ_LIB` tells GDAL and rasterio where to find the PROJ projection
database. When this is not set correctly, geopandas operations involving
coordinate reference systems fail with cryptic messages about missing `proj.db`.

On the WUR HPC, this path inside the conda environment contains the correct
PROJ database. Setting it here prevents the problem.

```bash
if [ $# -ne 2 ]; then
  echo "Usage: $0 MODEL SCENARIO"
  exit 1
fi
```

`$#` is the number of arguments passed to the script. If not exactly 2, a
usage message is printed and the script exits. This catches typos before any
long-running computation starts.

```bash
read START_YEAR END_YEAR <<< "$($GEO_PY - <<PY
from pathlib import Path
import xarray as xr
base = Path("/home/<user>/DEN")
model = "$MODEL"
scenario = "$SCENARIO"
p = base / model / "processed" / f"{model}_{scenario}_pr_denmark.nc"
ds = xr.open_dataset(p)
t = ds["time"].values
print(str(t[0])[:4], str(t[-1])[:4])
ds.close()
PY
)"
```

This is the most complex line in the script. It:

1. Opens a Python heredoc that reads the precipitation NetCDF for this
   model-scenario
2. Extracts the first and last timestamps and prints their 4-digit years
3. Captures that printed output back into the shell
4. Uses `read START_YEAR END_YEAR` to split the two space-separated years
   into two shell variables

The result: `START_YEAR=1971`, `END_YEAR=2014` for the historical period —
without hardcoding those years anywhere.

This matters because the historical and future periods differ:
- historical: 1971–2014
- ssp scenarios: 2031–2100

Using the NetCDF itself as the source of truth means the same script works for
all scenarios without modification.

```bash
$GEO_PY "$BASE/scripts/06_compute_tav_amp.py" \
  --model "$MODEL" \
  --scenario "$SCENARIO" \
  --start-year "$START_YEAR" \
  --end-year "$END_YEAR"
```

Script 06 runs first because TAV and AMP are conceptually a summary of the
full period, and computing them at this stage is a useful early sanity check
before the heavier zonal extraction runs.

```bash
for VAR in pr tasmax tasmin rsds; do
  echo "Extracting parquet for $MODEL / $SCENARIO / $VAR"
  $GEO_PY "$BASE/scripts/07_extract_zonal_stats_parquet.py" \
    --model "$MODEL" \
    --scenario "$SCENARIO" \
    --variable "$VAR" \
    --start-year "$START_YEAR" \
    --end-year "$END_YEAR"
done
```

Script 07 runs four times — once per variable. The `echo` before each call
means the Slurm log file shows exactly which variable is being processed
and when.

```bash
PERIOD="${START_YEAR}_${END_YEAR}"

echo "Generating WTH files for $MODEL / $SCENARIO / $PERIOD"
$GEO_PY "$BASE/scripts/08_generate_wth_files.py" \
  --model "$MODEL" \
  --scenario "$SCENARIO" \
  --period "$PERIOD"
```

Script 08 runs last because it depends on the Parquet files from Script 07.
`PERIOD` is assembled from the same variables used in the Parquet output
paths, so the directory lookup in Script 08 always matches what Script 07
wrote.

---

## Script 11 — Submit all jobs to Slurm

**File:** `11_submit_denmark_weather.sh`

```bash
#!/bin/bash
set -euo pipefail

BASE="/home/<user>/DEN/denmark"
LOGDIR="$BASE/logs"
mkdir -p "$LOGDIR"

MODELS=("GFDL_ESM4" "IPSL-CM6A-LR" "MPI-ESM1-2-HR" "MRI-ESM2-0" "UKESM1-0-LL")
SCENARIOS=("historical" "ssp126" "ssp370" "ssp585")

MODELS_TO_RUN=("${MODELS[@]}")
SCENARIOS_TO_RUN=("${SCENARIOS[@]}")

if [ $# -ge 1 ] && [ -n "${1:-}" ]; then
  IFS=',' read -r -a MODELS_TO_RUN <<< "$1"
fi
if [ $# -ge 2 ] && [ -n "${2:-}" ]; then
  IFS=',' read -r -a SCENARIOS_TO_RUN <<< "$2"
fi

echo "Submitting DEM preparation job..."
DEM_MERGED="$BASE/deliverables/validation/denmark_dem_merged.tif"
DEPENDENCY_ARGS=()
if [ -f "$DEM_MERGED" ]; then
  echo "DEM already available: $DEM_MERGED"
else
  DEM_JOB=$(sbatch \
    --parsable \
    --job-name=den_dem \
    --partition=cpuq \
    --account=pr_climate \
    --time=01:00:00 \
    --cpus-per-task=2 \
    --mem=8G \
    --output="$LOGDIR/dem-%j.out" \
    --error="$LOGDIR/dem-%j.err" \
    --wrap="$BASE/scripts/04_prepare_dem.sh")
  echo "DEM job: $DEM_JOB"
  DEPENDENCY_ARGS=(--dependency="afterok:${DEM_JOB}")
fi

for MODEL in "${MODELS_TO_RUN[@]}"; do
  for SCENARIO in "${SCENARIOS_TO_RUN[@]}"; do
    JOBID=$(sbatch \
      --parsable \
      "${DEPENDENCY_ARGS[@]}" \
      --job-name="den_${MODEL}_${SCENARIO}" \
      --partition=cpuq \
      --account=pr_climate \
      --time=04:00:00 \
      --cpus-per-task=4 \
      --mem=24G \
      --output="$LOGDIR/${MODEL}_${SCENARIO}-%j.out" \
      --error="$LOGDIR/${MODEL}_${SCENARIO}-%j.err" \
      --wrap="$BASE/scripts/10_run_model_scenario_weather.sh $MODEL $SCENARIO")
    echo "$MODEL $SCENARIO $JOBID"
  done
done
```

### What this script does

It submits all 20 model-scenario combinations to the HPC cluster as separate
Slurm jobs, all running in parallel.

It also handles the DEM job as a mandatory prerequisite: if the merged DEM
does not yet exist, it submits the DEM job first and makes all weather jobs
depend on it.

### Line-by-line breakdown

```bash
MODELS=("GFDL_ESM4" "IPSL-CM6A-LR" "MPI-ESM1-2-HR" "MRI-ESM2-0" "UKESM1-0-LL")
SCENARIOS=("historical" "ssp126" "ssp370" "ssp585")

MODELS_TO_RUN=("${MODELS[@]}")
SCENARIOS_TO_RUN=("${SCENARIOS[@]}")
```

Two arrays define all models and scenarios. They are immediately copied to
`MODELS_TO_RUN` and `SCENARIOS_TO_RUN`. Those copies are what the loop
actually iterates. This pattern allows the full list to serve as
documentation while the run list can be overridden.

```bash
if [ $# -ge 1 ] && [ -n "${1:-}" ]; then
  IFS=',' read -r -a MODELS_TO_RUN <<< "$1"
fi
if [ $# -ge 2 ] && [ -n "${2:-}" ]; then
  IFS=',' read -r -a SCENARIOS_TO_RUN <<< "$2"
fi
```

Optional arguments let you run a subset. For example:

```bash
./11_submit_denmark_weather.sh "MPI-ESM1-2-HR" "ssp370,ssp585"
```

submits only the two broken-and-repaired combinations instead of all 20.

`IFS=','` sets the field separator so `read -a` splits on commas rather than
spaces. `${1:-}` uses an empty default so the variable is considered set even
if the argument is empty, avoiding the `-u` error.

```bash
DEM_MERGED="$BASE/deliverables/validation/denmark_dem_merged.tif"
DEPENDENCY_ARGS=()
if [ -f "$DEM_MERGED" ]; then
  echo "DEM already available: $DEM_MERGED"
else
  DEM_JOB=$(sbatch \
    --parsable \
    --job-name=den_dem \
    ...
    --wrap="$BASE/scripts/04_prepare_dem.sh")
  echo "DEM job: $DEM_JOB"
  DEPENDENCY_ARGS=(--dependency="afterok:${DEM_JOB}")
fi
```

The DEM check runs before the main loop. If the merged DEM already exists,
`DEPENDENCY_ARGS` stays as an empty array and the weather jobs start
immediately. If the DEM does not exist, `sbatch --parsable` returns only the
job ID number, which is captured in `DEM_JOB`. The dependency array then
holds `--dependency=afterok:12345`, meaning every weather job will only start
after job 12345 finishes successfully.

```bash
DEM_JOB=$(sbatch \
  --parsable \
  --job-name=den_dem \
  --partition=cpuq \
  --account=pr_climate \
  --time=01:00:00 \
  --cpus-per-task=2 \
  --mem=8G \
  --output="$LOGDIR/dem-%j.out" \
  --error="$LOGDIR/dem-%j.err" \
  --wrap="$BASE/scripts/04_prepare_dem.sh")
```

The DEM job is allocated 2 CPUs, 8 GB RAM, and 1 hour. The `%j` in the log
filenames is replaced by the Slurm job ID, so each run gets its own log file.

```bash
JOBID=$(sbatch \
  --parsable \
  "${DEPENDENCY_ARGS[@]}" \
  --job-name="den_${MODEL}_${SCENARIO}" \
  --partition=cpuq \
  --account=pr_climate \
  --time=04:00:00 \
  --cpus-per-task=4 \
  --mem=24G \
  --output="$LOGDIR/${MODEL}_${SCENARIO}-%j.out" \
  --error="$LOGDIR/${MODEL}_${SCENARIO}-%j.err" \
  --wrap="$BASE/scripts/10_run_model_scenario_weather.sh $MODEL $SCENARIO")
echo "$MODEL $SCENARIO $JOBID"
```

Each weather job gets 4 CPUs, 24 GB RAM, and 4 hours. The memory allocation
covers loading climate NetCDFs (which can be several GB) plus the geopandas
and xarray operations.

`"${DEPENDENCY_ARGS[@]}"` expands as either nothing (if DEM was already
present) or `--dependency=afterok:JOBID` (if it was just submitted). This
works because Bash expands an empty array to nothing rather than to an empty
string.

---

## The output files in detail

### A WTH file header

```
*WEATHER DATA : 0001 1971
@ INSI      LAT     LONG  ELEV   TAV   AMP REFHT WNDHT
     1    54.95     8.83     5   8.7  15.7   -99   -99
```

| Field | Value | Meaning |
|---|---|---|
| `INSI` | `1` | Station identifier (zone_id) |
| `LAT` | `54.95` | Latitude in decimal degrees |
| `LONG` | `8.83` | Longitude in decimal degrees |
| `ELEV` | `5` | Elevation in metres above sea level |
| `TAV` | `8.7` | Mean annual temperature (°C) |
| `AMP` | `15.7` | Mean annual amplitude (°C) |
| `REFHT` | `-99` | Humidity measurement height (not provided) |
| `WNDHT` | `-99` | Wind measurement height (not provided) |

### A WTH daily row

```
71001   1.2   2.6  -4.7   0.0
```

| Columns 1–5 | Col 6–11 | Col 12–17 | Col 18–23 | Col 24–29 |
|---|---|---|---|---|
| `71001` (YYDDD) | `1.2` SRAD | `2.6` TMAX | `-4.7` TMIN | `0.0` RAIN |

The date `71001` means year 1971, day 1 (1 January).

### A tav_amp CSV

```
model,scenario,tav_degC,amp_degC
GFDL_ESM4,historical,7.951,16.528
```

---

## Problems we hit and what fixed them

### 1. Wrong Python environment on HPC

**Symptom:** `ModuleNotFoundError: No module named 'geopandas'`

**Cause:** The job was using the system Python rather than the geo_env conda
environment.

**Fix:** Specify the full path to the Python binary in every script:

```bash
GEO_PY="/home/<user>/.conda/envs/mamba_env/envs/geo_env/bin/python"
```

Never use `python3` or `python` on HPC without knowing which environment
they resolve to.

### 2. PROJ database not found

**Symptom:** `ProjError: proj.db not found in proj search path`

**Cause:** `PROJ_LIB` was not set, so geopandas could not find the
coordinate reference system database.

**Fix:**

```bash
GEO_ENV_ROOT="/home/<user>/.conda/envs/mamba_env/envs/geo_env"
if [ -d "$GEO_ENV_ROOT/share/proj" ]; then
  export PROJ_LIB="$GEO_ENV_ROOT/share/proj"
fi
```

### 3. Corrupted processed NetCDF files

**Symptom:** `MPI-ESM1-2-HR ssp370` WTH files were missing.

**Cause:** Two processed NetCDF files had been damaged:

```
MPI-ESM1-2-HR_ssp370_tasmin_denmark.nc
MPI-ESM1-2-HR_ssp370_rsds_denmark.nc
```

**Fix:** Rebuild them from raw source files using the same merge-clip-convert
logic as Script 05. Once rebuilt, run Script 10 for that model-scenario only:

```bash
./10_run_model_scenario_weather.sh MPI-ESM1-2-HR ssp370
```

### 4. Zero-elevation coastal cells

**Symptom:** Many coastal Denmark WTH files had `ELEV = 0`.

**Cause:** The grid-cell centroid fell in the sea. The DEM returned its
nodata value there. The script was treating that as zero instead of
triggering a fallback.

**Fix:** The four-level elevation fallback in `load_zone_metadata` inside
Script 08 (described above).

### 5. Wrong line endings on Windows

**Symptom:** DSSAT could not parse the WTH file or returned strange
phenology results.

**Cause:** The WTH file was written with Windows `\r\n` line endings because
it was generated on a Windows machine.

**Fix:** Always open WTH files with `newline="\n"` in Python:

```python
with open(output_path, "w", encoding="ascii", newline="\n") as h:
```

---

## Final validated deliverable counts

| Deliverable | Count | Formula |
|---|---|---|
| Processed NetCDF files | 100 | 5 models × 4 scenarios × 5 variables |
| Parquet zonal files | 80 | 5 models × 4 scenarios × 4 WTH variables |
| TAV/AMP CSV files | 20 | 5 models × 4 scenarios |
| WTH files | 1160 | 5 models × 4 scenarios × 58 grid cells |

All 100 processed NetCDF files passed unit and range checks in
`processed_units_validation.csv`:

- `pr` mean: ~2.3–2.6 mm/day (plausible for Denmark)
- `tas` mean: ~8–11 °C (plausible for Denmark)
- `rsds` mean: ~10–11 MJ/m²/day (plausible for Denmark)

---

## How to re-run from scratch

If you need to rebuild everything, the sequence is:

```bash
# Step 1: download (if data not already present)
./01_download_isimip.sh

# Step 2: merge, clip, convert (if processed NetCDFs not present)
# (runs the underlying merge_denmark.sh for each model/scenario/variable)
./05_merge_clip_convert_climate.sh

# Step 3: submit all weather jobs to Slurm
./11_submit_denmark_weather.sh

# Step 4: check counts once jobs complete
python 09_validate_outputs.py
```

To re-run only one broken model-scenario without submitting everything:

```bash
./10_run_model_scenario_weather.sh MPI-ESM1-2-HR ssp370
```

---

## Script 14 — Fetch soil profiles and build DN.SOL

**File:** `14_fetch_soil_and_build_sol.py`

This script is the soil counterpart to the weather pipeline.

It queries the MSU Decision Support and Informatics Soil Query API for each
of the 60 Denmark grid centroids and assembles a complete DSSAT soil library
file `DN.SOL`.

### The API

The API is hosted by Michigan State University's Decision Support and
Informatics group:

```
https://dsiweb.cse.msu.edu/soil-query-api/soil
```

It holds 1,984,797 global soil profiles sourced from ISRIC SoilGrids combined
with the HC27 pedotransfer functions. A GET request with `lat`, `lon`, and
`format=json` returns a single nearest-match profile.

```
GET /soil-query-api/soil?lat=54.751&lon=8.750&format=json
```

Example response (truncated):

```json
{
  "profile": {
    "id": "DE01825304",
    "location": { "lat": 54.792, "lon": 8.708, "country_code": "DE" },
    "site": {
      "country_code_alpha3": "DEU",
      "scs_family": "HC_GEN0011",
      "texture": "Loam",
      "max_depth_cm": 200
    },
    "properties": {
      "scom": "BK", "salb": 0.1, "slu1": 6.0, "sldr": 0.5,
      "slro": 75.0, "slnf": 1.0, "slpf": 1.0,
      "smhb": "SA001", "smpx": "SA001", "smke": "SA001"
    },
    "layers": [
      { "slb": 5,  "slmh": "A",  "slll": 0.115, "sdul": 0.245, "ssat": 0.395,
        "srgf": 1.0, "ssks": 1.05, "sbdm": 1.26, "sloc": 4.01,
        "slcl": 18.87, "slsi": 40.46, "slcf": null, "slni": 0.12,
        "slhw": 6.13, "slhb": null,  "scec": 18.4, "sadc": null },
      ...5 more layers to 200 cm
    ],
    "metadata": { "source": "ISRIC soilgrids + HC27", "distance_km": 5.39 }
  }
}
```

The API also supports `format=sol`, which returns the profile already
formatted as a DSSAT SOL block. The script uses `format=json` instead so it
can assign Denmark-specific profile IDs (`DK0001` to `DK0060`) and add a
proper file header.

### About the API — source code and data origin

The full API source code is publicly available at:

```
https://github.com/eusojk/soil-query
```

It is a Rust application built with Axum and SQLite, deployed on Railway.

The underlying data is from the 2015 Harvard Dataverse publication:

> Han, Ines, and Koo — *Global High-Resolution Soil Profile Database for
> Crop Modeling Applications*

The database holds approximately 2 million profiles from 225 countries at
roughly 10 km resolution, combining ISRIC SoilGrids with HC27 pedotransfer
functions. Spatial lookups use an R-tree index and Haversine distance. Typical
query latency is under 50 milliseconds.

The three API endpoints are:

| Endpoint | What it does |
|---|---|
| `GET /health` | Returns `{"status":"ok","version":"0.1.0","profiles":1984797}` |
| `GET /soil?lat=&lon=&format=json` | Returns nearest profile as JSON |
| `GET /soil?lat=&lon=&format=sol` | Returns nearest profile as DSSAT SOL text |
| `GET /definitions` | Returns field abbreviation descriptions |

The `format=sol` option is convenient for quick inspection of one profile but
returns the API's own profile ID (e.g. `DE01825304`), not our Denmark grid ID.
The script uses `format=json` so it can assign the correct `DK0001`–`DK0060`
identifiers.

### One critical header requirement

A plain Python `requests.get` without extra headers returns an HTML page
instead of JSON. The CDN protecting the server blocks requests that do not
look like browser traffic.

The fix is two lines:

```python
HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0 Safari/537.36"
    ),
    "Referer": "https://dsiweb.cse.msu.edu/",
    "Accept": "application/json",
}
```

Without `User-Agent` and `Referer`, the request gets a 406 or an HTML page.
This is not documented — it was found by probing the server directly.

### The full script

```python
#!/usr/bin/env python3
"""
14_fetch_soil_and_build_sol.py
-------------------------------
Query the MSU DSI Soil Query API for each Denmark 0.5-degree grid centroid
and assemble a complete DSSAT-format DN.SOL file.

Usage (local Windows):
    python 14_fetch_soil_and_build_sol.py

Usage (HPC):
    /home/<user>/.conda/envs/mamba_env/envs/geo_env/bin/python \\
        /home/<user>/DEN/denmark/scripts/14_fetch_soil_and_build_sol.py

Inputs:
    denmark_grid_05deg_centroids.csv  (grid_id, lon, lat — 60 rows)

Outputs:
    deliverables/soil/DN.SOL               DSSAT soil library
    deliverables/soil/soil_fetch_report.csv  per-centroid QC report
"""

from __future__ import annotations

import csv
import sys
import time
from pathlib import Path

import requests

# ── Detect HPC vs local ────────────────────────────────────────────────────────
_HPC_CENTROIDS   = Path("/home/<user>/DEN/denmark_grid_05deg_centroids.csv")
_LOCAL_CENTROIDS = Path(
    r"C:\Users\chich\Downloads\denmark_wth_bundle\denmark_grid_05deg_centroids.csv"
)

if _HPC_CENTROIDS.exists():
    CENTROIDS_CSV       = _HPC_CENTROIDS
    _BASE_DELIVERABLES  = Path("/home/<user>/DEN/denmark/deliverables")
elif _LOCAL_CENTROIDS.exists():
    CENTROIDS_CSV       = _LOCAL_CENTROIDS
    _BASE_DELIVERABLES  = Path(__file__).resolve().parent.parent / "deliverables"
else:
    sys.exit(
        "Cannot find denmark_grid_05deg_centroids.csv.\n"
        f"Expected at:\n  {_HPC_CENTROIDS}\n  {_LOCAL_CENTROIDS}"
    )

OUT_SOL    = _BASE_DELIVERABLES / "soil" / "DN.SOL"
OUT_REPORT = _BASE_DELIVERABLES / "soil" / "soil_fetch_report.csv"

# ── API ────────────────────────────────────────────────────────────────────────
API_URL = "https://dsiweb.cse.msu.edu/soil-query-api/soil"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0 Safari/537.36"
    ),
    "Referer": "https://dsiweb.cse.msu.edu/",
    "Accept": "application/json",
}

REQUEST_TIMEOUT = 30
SLEEP_BETWEEN   = 0.6
MAX_RETRIES     = 3
MAX_DISTANCE_KM = 50.0
MISSING         = -99.0


# ── DSSAT SOL formatting ───────────────────────────────────────────────────────

def _fmt(val, width: int, dec: int) -> str:
    """Right-align a numeric value; substitute -99.0 for None."""
    v = MISSING if val is None else float(val)
    return f"{v:{width}.{dec}f}"


def build_sol_block(grid_id: int, lon: float, lat: float, profile: dict) -> str:
    loc    = profile.get("location",   {})
    site   = profile.get("site",       {})
    props  = profile.get("properties", {})
    layers = profile.get("layers",     [])
    meta   = profile.get("metadata",   {})

    profile_id = f"DK{grid_id:04d}"
    country_a3 = site.get("country_code_alpha3", "DNK")
    texture    = site.get("texture",     "Unknown")
    max_depth  = site.get("max_depth_cm", -99)
    source     = meta.get("source",      "MSU DSI API")
    api_lat    = loc.get("lat",  lat)
    api_lon    = loc.get("lon",  lon)
    scs_family = site.get("scs_family", "-99")

    scom = props.get("scom", "-99")
    salb = props.get("salb", MISSING)
    slu1 = props.get("slu1", MISSING)
    sldr = props.get("sldr", MISSING)
    slro = props.get("slro", MISSING)
    slnf = props.get("slnf", MISSING)
    slpf = props.get("slpf", MISSING)
    smhb = props.get("smhb", "SA001")
    smpx = props.get("smpx", "SA001")
    smke = props.get("smke", "SA001")

    lines: list[str] = []

    # Profile header
    lines.append(
        f"*{profile_id:<10}  {country_a3:<16} {texture:<8} {int(max_depth):>4}"
        f"    {source}"
    )

    # Site
    lines.append("@SITE        COUNTRY          LAT     LONG SCS Family")
    lines.append(
        f" {'-99':<12} {country_a3:<16}"
        f" {api_lat:>7.3f} {api_lon:>7.3f} {scs_family}"
    )

    # Properties
    lines.append(
        "@ SCOM  SALB  SLU1  SLDR  SLRO  SLNF  SLPF  SMHB  SMPX  SMKE"
    )
    lines.append(
        f"  {scom:>4}"
        f"{float(salb):>6.2f}"
        f"{float(slu1):>6.2f}"
        f"{float(sldr):>6.2f}"
        f"{float(slro):>6.2f}"
        f"{float(slnf):>6.2f}"
        f"{float(slpf):>6.2f}"
        f" {smhb:>5}"
        f" {smpx:>5}"
        f" {smke:>5}"
    )

    # Layers
    lines.append(
        "@  SLB  SLMH  SLLL  SDUL  SSAT  SRGF  SSKS  SBDM"
        "  SLOC  SLCL  SLSI  SLCF  SLNI  SLHW  SLHB  SCEC  SADC"
    )
    for lyr in layers:
        lines.append(
            f"{int(lyr.get('slb', 0)):>5} {str(lyr.get('slmh', '-99')):<5}"
            f"{_fmt(lyr.get('slll'), 6, 3)}"
            f"{_fmt(lyr.get('sdul'), 6, 3)}"
            f"{_fmt(lyr.get('ssat'), 6, 3)}"
            f"{_fmt(lyr.get('srgf'), 6, 2)}"
            f"{_fmt(lyr.get('ssks'), 6, 2)}"
            f"{_fmt(lyr.get('sbdm'), 6, 2)}"
            f"{_fmt(lyr.get('sloc'), 6, 2)}"
            f"{_fmt(lyr.get('slcl'), 6, 2)}"
            f"{_fmt(lyr.get('slsi'), 6, 2)}"
            f"{_fmt(lyr.get('slcf'), 6, 1)}"
            f"{_fmt(lyr.get('slni'), 6, 2)}"
            f"{_fmt(lyr.get('slhw'), 6, 2)}"
            f"{_fmt(lyr.get('slhb'), 6, 1)}"
            f"{_fmt(lyr.get('scec'), 6, 2)}"
            f"{_fmt(lyr.get('sadc'), 6, 1)}"
        )

    return "\n".join(lines)


# ── API fetch with retry ───────────────────────────────────────────────────────

def fetch_profile(lat: float, lon: float) -> dict | None:
    params = {"lat": round(lat, 6), "lon": round(lon, 6), "format": "json"}

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            resp = requests.get(
                API_URL, params=params, headers=HEADERS, timeout=REQUEST_TIMEOUT
            )
            if 400 <= resp.status_code < 500:
                print(f"HTTP {resp.status_code} (no retry)")
                return None
            resp.raise_for_status()
            return resp.json().get("profile")

        except requests.exceptions.Timeout:
            print(f"timeout (attempt {attempt}/{MAX_RETRIES})", end="  ")
        except requests.exceptions.JSONDecodeError:
            print("bad JSON — likely got HTML; check headers")
            return None
        except requests.exceptions.RequestException as exc:
            print(f"{exc} (attempt {attempt}/{MAX_RETRIES})", end="  ")

        if attempt < MAX_RETRIES:
            time.sleep(2.0 * attempt)

    return None


# ── Main ───────────────────────────────────────────────────────────────────────

def main() -> None:
    # 1. Read centroids
    centroids: list[dict] = []
    with open(CENTROIDS_CSV, newline="", encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            centroids.append(
                {"grid_id": int(row["grid_id"]),
                 "lon": float(row["lon"]),
                 "lat": float(row["lat"])}
            )

    print(f"Loaded {len(centroids)} centroids from {CENTROIDS_CSV.name}")
    print(f"Output SOL   : {OUT_SOL}")
    print(f"Output report: {OUT_REPORT}\n")

    # 2. Prepare output directory
    OUT_SOL.parent.mkdir(parents=True, exist_ok=True)

    # 3. Fetch profiles
    sol_blocks:  list[str]  = []
    report_rows: list[dict] = []

    for i, c in enumerate(centroids, 1):
        gid, lat, lon = c["grid_id"], c["lat"], c["lon"]

        print(
            f"[{i:>3}/{len(centroids)}]  grid={gid:>3}  "
            f"lat={lat:.5f}  lon={lon:.5f}  ",
            end="", flush=True,
        )

        profile = fetch_profile(lat, lon)

        if profile is None:
            print("FAILED — skipped")
            report_rows.append(dict(
                grid_id=gid, lat=lat, lon=lon,
                api_lat=None, api_lon=None,
                distance_km=None, n_layers=0,
                texture=None, max_depth_cm=None, status="API_FAILED",
            ))
            continue

        dist      = profile.get("metadata", {}).get("distance_km", 0.0)
        n_layers  = len(profile.get("layers", []))
        texture   = profile.get("site",     {}).get("texture",     "Unknown")
        max_depth = profile.get("site",     {}).get("max_depth_cm", None)
        api_lat   = profile.get("location", {}).get("lat", lat)
        api_lon   = profile.get("location", {}).get("lon", lon)
        status    = "OK" if dist <= MAX_DISTANCE_KM else "FAR"

        print(
            f"dist={dist:>6.1f} km  layers={n_layers}  "
            f"texture={texture:<10}  [{status}]"
        )

        sol_blocks.append(build_sol_block(gid, lon, lat, profile))
        report_rows.append(dict(
            grid_id=gid, lat=lat, lon=lon,
            api_lat=round(api_lat, 4), api_lon=round(api_lon, 4),
            distance_km=round(dist, 3), n_layers=n_layers,
            texture=texture, max_depth_cm=max_depth, status=status,
        ))

        time.sleep(SLEEP_BETWEEN)

    # 4. Write DN.SOL
    with open(OUT_SOL, "w", encoding="ascii", newline="\n") as fh:
        fh.write(
            "*SOILS: Denmark ISIMIP 0.5-deg Grid  "
            "[ISRIC SoilGrids + HC27 via MSU DSI Soil Query API]\n\n"
        )
        for block in sol_blocks:
            fh.write(block)
            fh.write("\n\n")

    # 5. Write QC report
    fields = [
        "grid_id", "lat", "lon", "api_lat", "api_lon",
        "distance_km", "n_layers", "texture", "max_depth_cm", "status",
    ]
    with open(OUT_REPORT, "w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        writer.writerows(report_rows)

    # 6. Summary
    n_ok     = sum(1 for r in report_rows if r["status"] == "OK")
    n_far    = sum(1 for r in report_rows if r["status"] == "FAR")
    n_failed = sum(1 for r in report_rows if r["status"] == "API_FAILED")

    print(f"\n{'='*60}")
    print(f"Profiles fetched        : {n_ok + n_far} / {len(centroids)}")
    print(f"  within {MAX_DISTANCE_KM:.0f} km (OK)   : {n_ok}")
    print(f"  beyond {MAX_DISTANCE_KM:.0f} km (FAR)  : {n_far}")
    print(f"Failed / skipped        : {n_failed}")
    print(f"SOL  file               : {OUT_SOL}")
    print(f"QC report               : {OUT_REPORT}")
    if n_far:
        print("\nFAR profiles (nearest match > 50 km):")
        for r in report_rows:
            if r["status"] == "FAR":
                print(
                    f"  grid_id={r['grid_id']:>3}  "
                    f"lat={r['lat']:.3f}  lon={r['lon']:.3f}  "
                    f"dist={r['distance_km']:.1f} km"
                )
    print("=" * 60)


if __name__ == "__main__":
    main()
```

### Line-by-line breakdown

#### The path detection block

```python
_HPC_CENTROIDS   = Path("/home/<user>/DEN/denmark_grid_05deg_centroids.csv")
_LOCAL_CENTROIDS = Path(
    r"C:\Users\chich\Downloads\denmark_wth_bundle\denmark_grid_05deg_centroids.csv"
)

if _HPC_CENTROIDS.exists():
    CENTROIDS_CSV      = _HPC_CENTROIDS
    _BASE_DELIVERABLES = Path("/home/<user>/DEN/denmark/deliverables")
elif _LOCAL_CENTROIDS.exists():
    CENTROIDS_CSV      = _LOCAL_CENTROIDS
    _BASE_DELIVERABLES = Path(__file__).resolve().parent.parent / "deliverables"
else:
    sys.exit("Cannot find denmark_grid_05deg_centroids.csv. ...")
```

The same script runs on both the HPC and a Windows laptop without editing.
It checks the HPC path first. If that does not exist it tries the local path.
If neither exists it exits immediately with a clear message rather than
crashing deep inside the fetch loop.

`Path(__file__).resolve().parent.parent` navigates from the script file
(`scripts/`) up two levels to the project root (`denmark/`) and then into
`deliverables/` — so the output paths stay consistent regardless of where you
launch the script from.

#### The `_fmt` helper

```python
def _fmt(val, width: int, dec: int) -> str:
    v = MISSING if val is None else float(val)
    return f"{v:{width}.{dec}f}"
```

Every soil field in the API response can be `null` (when a property was not
measured or estimated). DSSAT uses `-99.0` as its missing-value code. This
single helper applies that rule uniformly and right-aligns the value in a
fixed-width field, keeping the SOL file columns aligned.

Without this, you would need an `if val is None` branch for every single
field in every layer. With it, the layer formatter is a single readable block.

#### The `build_sol_block` function

This function converts one API response dictionary into a DSSAT SOL profile
block. It has four sections matching the DSSAT format exactly.

**Profile header line:**

```python
lines.append(
    f"*{profile_id:<10}  {country_a3:<16} {texture:<8} {int(max_depth):>4}"
    f"    {source}"
)
```

The `*` at the start marks a profile header to DSSAT. `profile_id` is
`DK0001` to `DK0060` — the `DK` prefix identifies Denmark and the 4-digit
number matches the `grid_id` in the centroids CSV and in the WTH filenames.
This means every soil profile can be linked back to its WTH file by number.

**Properties line:**

```python
lines.append(
    f"  {scom:>4}"
    f"{float(salb):>6.2f}"
    f"{float(slu1):>6.2f}"
    ...
)
```

`SALB` is albedo (dimensionless), `SLU1` is the upper limit of soil water
in the first layer (mm), `SLDR` is the drainage rate (fraction per day),
`SLRO` is the runoff curve number. These site-level properties come directly
from the API and do not need derivation.

**Layer lines:**

```python
lines.append(
    f"{int(lyr.get('slb', 0)):>5} {str(lyr.get('slmh', '-99')):<5}"
    f"{_fmt(lyr.get('slll'), 6, 3)}"
    f"{_fmt(lyr.get('sdul'), 6, 3)}"
    ...
)
```

`SLB` is the bottom depth of the layer in cm. `SLMH` is the master horizon
designation (A, AB, B, BC, C etc.). All remaining fields are hydraulic and
chemical properties. The column widths — 5 for `SLB`, 6 for hydraulic values
— match the DSSAT `.SOL` specification exactly. Even one character off
causes DSSAT to misread the field.

#### The `fetch_profile` function

```python
if 400 <= resp.status_code < 500:
    print(f"HTTP {resp.status_code} (no retry)")
    return None
resp.raise_for_status()
return resp.json().get("profile")
```

4xx responses are not retried. A 406 means the server rejected the request
format. A 404 means no profile exists near that coordinate (open ocean, for
example). Neither is worth retrying.

5xx responses and timeouts raise exceptions, which are caught and retried
up to `MAX_RETRIES` times with increasing wait between attempts.

`resp.json().get("profile")` extracts the nested profile object. If the
response structure ever changes and `"profile"` is missing, this returns
`None` cleanly instead of raising a `KeyError`.

#### The main loop

```python
for i, c in enumerate(centroids, 1):
    ...
    print(
        f"[{i:>3}/{len(centroids)}]  grid={gid:>3}  "
        f"lat={lat:.5f}  lon={lon:.5f}  ",
        end="", flush=True,
    )
    profile = fetch_profile(lat, lon)
    ...
    time.sleep(SLEEP_BETWEEN)
```

`end=""` keeps the cursor on the same line so the result (`dist=... [OK]`)
prints alongside the coordinate it refers to, giving a compact one-line-per-
centroid log.

`flush=True` forces the output buffer to write immediately. Without it, when
running in a Slurm job the log file shows nothing until the script finishes.

`time.sleep(SLEEP_BETWEEN)` waits 0.6 seconds between every request. The API
serves 1.9 million profiles to many users. Being polite costs you 36 seconds
on 60 centroids and keeps the service available for everyone.

#### Writing the SOL file

```python
with open(OUT_SOL, "w", encoding="ascii", newline="\n") as fh:
    fh.write(
        "*SOILS: Denmark ISIMIP 0.5-deg Grid  "
        "[ISRIC SoilGrids + HC27 via MSU DSI Soil Query API]\n\n"
    )
    for block in sol_blocks:
        fh.write(block)
        fh.write("\n\n")
```

`encoding="ascii"` and `newline="\n"` are the same two rules as Script 08.
DSSAT reads SOL files as plain ASCII with Unix line endings. Writing on
Windows with the default settings would produce `\r\n` endings that confuse
DSSAT's fixed-width parser.

The `*SOILS:` line is the file-level header. DSSAT skips it but it tells a
human reader what is in the file, where the data came from, and what
pedotransfer approach was used.

Two blank lines (`"\n\n"`) after each block separate profiles clearly.

### SOL format strings verified against the Rust source

Reading the upstream Rust source at
`crates/soil-query/src/parser.rs` reveals the exact format strings used by
`to_sol_format()`. The Python script translates these directly.

**Profile header line:**

```rust
// Rust
format!("*{:<14} {:<10} {:>10} {:>5}    {}\n", id, country_a3, texture, depth, source)
```

```python
# Python equivalent
f"*{profile_id:<14} {country_a3:<10} {texture:>10} {int(max_depth):>5}    {source}"
```

**Site data line:**

```rust
// Rust  — note: uses 2-letter location.country_code, NOT 3-letter country_code_alpha3
format!(" -99              {:>2} {:>11.3} {:>9.3}     {}\n",
        location.country_code, lat, lon, scs_family)
```

```python
# Python equivalent  — country_2 = loc.get("country_code"), NOT country_a3
f" -99              {country_2:>2} {api_lat:>11.3f} {api_lon:>9.3f}     {scs_family}"
```

**Properties line:**

```rust
// Rust
format!("    {} {:5.2} {:5.2} {:5.2} {:5.2} {:5.2} {:5.2} {} {} {}\n",
        scom, salb, slu1, sldr, slro, slnf, slpf, smhb, smpx, smke)
```

**Layer line — two different formatters:**

```rust
// Rust — fmt_layer_value (3 decimals) only for SLLL, SDUL, SSAT
let fmt_layer_value = |opt: Option<f64>| match opt {
    Some(val) => format!("{:5.3}", val),
    None      => "-99.0".to_string(),    // ← 5-char literal, NOT -99.00
};

// Rust — fmt_optional (2 decimals) for all other layer fields
let fmt_optional = |opt: Option<f64>| match opt {
    Some(val) => format!("{:5.2}", val),
    None      => "-99.0".to_string(),    // ← 5-char literal, NOT -99.00
};
```

```python
# Python equivalent
MISSING_STR = "-99.0"   # must be 5 chars — "-99.00" breaks DSSAT

def _fmt_water(val) -> str:   # SLLL, SDUL, SSAT only
    return MISSING_STR if val is None else f"{float(val):5.3f}"

def _fmt(val) -> str:         # everything else
    return MISSING_STR if val is None else f"{float(val):5.2f}"
```

The critical insight is that `None` maps to the **string** `"-99.0"`, not to
`f"{-99.0:5.2f}"` which would produce `"-99.00"` — six characters. That
extra character shifts every column to the right and causes DSSAT to misread
every value in the layer.

**Which fields get 3 decimals vs 2:**

| Field | Decimals | Reason |
|---|---|---|
| SLLL, SDUL, SSAT | 3 | Volumetric water content needs 3 sig figs (e.g. 0.115) |
| SRGF, SSKS, SBDM, SLOC, SLCL, SLSI, SLCF, SLNI, SLHW, SLHB, SCEC, SADC | 2 | 2 sig figs sufficient |

**Country code confusion — why there are two:**

```python
country_a3 = site.get("country_code_alpha3", "DNK")  # 3-letter → profile header
country_2  = loc.get("country_code",          "DK")   # 2-letter → site data line
```

The Rust `SiteProperties.country_code_alpha3` is 3-letter (from the SOL
header line). The `Location.country_code` is 2-letter ISO (from the database
record). The Rust `to_sol_format()` uses:
- `self.site.country_code_alpha3` on the profile header line
- `self.location.country_code` on the site data line

Denmark centroids often resolve to profiles stored as `DE` (Germany) because
the database does not store many profiles inside Denmark's borders and the
nearest land profile may be across the German border. That is expected — the
2-letter code reflects where the profile record came from, not where we
queried.

### What the output looks like

**DN.SOL** (first two profiles shown):

```
*SOILS: Denmark ISIMIP 0.5-deg Grid  [ISRIC SoilGrids + HC27 via MSU DSI Soil Query API]

*DK0001       DNK              Loam      200    ISRIC soilgrids + HC27
@SITE        COUNTRY          LAT     LONG SCS Family
 -99          DNK              54.792   8.708 HC_GEN0011
@ SCOM  SALB  SLU1  SLDR  SLRO  SLNF  SLPF  SMHB  SMPX  SMKE
    BK  0.10  6.00  0.50 75.00  1.00  1.00 SA001 SA001 SA001
@  SLB  SLMH  SLLL  SDUL  SSAT  SRGF  SSKS  SBDM  SLOC  SLCL  SLSI  SLCF  SLNI  SLHW  SLHB  SCEC  SADC
    5 A     0.115 0.245 0.395  1.00  1.05  1.26  4.01 18.87 40.46 -99.0  0.12  6.13 -99.0 18.40 -99.0
   15 A     0.126 0.256 0.399  0.85  0.89  1.28  3.40 20.69 39.68 -99.0  0.09  6.20 -99.0 16.10 -99.0
   30 AB    0.140 0.271 0.403  0.70  0.72  1.31  2.59 23.02 38.58 -99.0  0.07  6.29 -99.0 15.60 -99.0
   60 BA    0.153 0.284 0.408  0.50  0.59  1.36  1.66 25.26 37.26 -99.0  0.06  6.41 -99.0 16.30 -99.0
  100 B     0.153 0.282 0.407  0.38  0.60  1.42  0.96 25.27 36.68 -99.0  0.05  6.55 -99.0 16.50 -99.0
  200 BC    0.142 0.270 0.402  0.05  0.72  1.47  0.55 23.51 36.27 -99.0  0.05  6.73 -99.0 16.40 -99.0

*DK0002       DNK              Sandy loam 200    ISRIC soilgrids + HC27
...
```

**soil_fetch_report.csv** (first rows):

| grid_id | lat | lon | api_lat | api_lon | distance_km | n_layers | texture | max_depth_cm | status |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 54.75077 | 8.75 | 54.792 | 8.708 | 5.391 | 6 | Loam | 200 | OK |
| 2 | 54.75077 | 9.25 | 54.792 | 9.247 | 3.263 | 6 | Sandy loam | 200 | OK |

### What the DSSAT soil fields mean

| Field | Full name | Unit |
|---|---|---|
| `SLLL` | Lower limit (wilting point) | cm³/cm³ |
| `SDUL` | Drained upper limit (field capacity) | cm³/cm³ |
| `SSAT` | Saturation upper limit | cm³/cm³ |
| `SRGF` | Root growth factor | 0–1 |
| `SSKS` | Saturated hydraulic conductivity | cm/h |
| `SBDM` | Bulk density | g/cm³ |
| `SLOC` | Organic carbon | % |
| `SLCL` | Clay content | % |
| `SLSI` | Silt content | % |
| `SLCF` | Coarse fragments | % |
| `SLNI` | Total nitrogen | % |
| `SLHW` | pH in water | — |
| `SLHB` | pH in buffer | — |
| `SCEC` | Cation exchange capacity | cmol/kg |
| `SALB` | Albedo | fraction |
| `SLRO` | Runoff curve number | — |

### How to link soil profiles to WTH files

The profile ID `DK0001` in `DN.SOL` corresponds to `grid_id = 1` in the
centroids CSV. That same `grid_id` produces WTH filename prefix `0001`:

```
00017144.WTH   ← zone 1, start year 71, 44 years
```

And in the WTH file header:

```
@ INSI ...
     1    54.95  ...
```

The `INSI` value `1` matches the zone. In the DSSAT experiment file, you
link `WSTA = 0001` (the weather station) and `SOIL_ID = DK0001` (the soil
profile) to run a simulation at Denmark grid cell 1.

### Running the script

On the HPC:

```bash
GEO_PY="/home/<user>/.conda/envs/mamba_env/envs/geo_env/bin/python"
$GEO_PY /home/<user>/DEN/denmark/scripts/14_fetch_soil_and_build_sol.py
```

Locally (Windows):

```bash
python 14_fetch_soil_and_build_sol.py
```

Expected console output:

```
Loaded 60 centroids from denmark_grid_05deg_centroids.csv
Output SOL   : .../deliverables/soil/DN.SOL
Output report: .../deliverables/soil/soil_fetch_report.csv

[  1/ 60]  grid=  1  lat=54.75077  lon=8.75000   dist=   5.4 km  layers=6  Loam        [OK]
[  2/ 60]  grid=  2  lat=54.75077  lon=9.25000   dist=   3.3 km  layers=6  Sandy loam  [OK]
...
[ 60/ 60]  grid= 60  lat=57.75086  lon=10.75000  dist=   8.1 km  layers=6  Loam        [OK]

============================================================
Profiles fetched        : 60 / 60
  within 50 km (OK)   : 58
  beyond 50 km (FAR)  : 2
Failed / skipped        : 0
SOL  file               : .../deliverables/soil/DN.SOL
QC report               : .../deliverables/soil/soil_fetch_report.csv
============================================================
```

### What `FAR` means and what to do about it

A `FAR` flag means the nearest profile in the database was more than 50 km
from the Denmark centroid. This typically happens for grid cells that are
mostly open sea — the API found the nearest land-based soil record but that
record belongs to a coastal point or an island some distance away.

For those cells, you have three choices:

1. Accept the profile — the soil at 60 km distance may still be representative
   of the coastal fringe of Denmark.
2. Use the nearest `OK` profile from an adjacent grid cell instead.
3. Mark those cells as excluded and do not run DSSAT simulations for them.

The `soil_fetch_report.csv` lists all `FAR` cases with their actual distance,
so you can make an informed decision for each one.

---

## Why some centroids fall in water

If you plot the 60 Denmark grid cells on a map you will notice that several
centroids land in open sea — most visibly the cells around Bornholm (grid IDs
10 and 11, lon ~14.75–15.25 E, lat ~54.75 N) and the Kattegat cells
(IDs 22 and 23, lon ~14.75–15.25 E, lat ~55.25 N).

This is not a bug. It is a direct consequence of how the grid was built.

### How cells with water centroids enter the grid

`denmark_grid_05deg.shp` is built by overlaying a regular 0.5-degree global
grid on Denmark's administrative and territory boundary, then keeping **every
cell that has any geometric overlap with Danish territory** — even a single
pixel of coastline is enough to include the whole 0.5-degree polygon.

Bornholm island sits at roughly 14.9 E, 55.1 N, surrounded by open Baltic
Sea. Its 0.5-degree grid polygon is approximately 55 km × 35 km. The centroid
of that large polygon falls in the sea west of the island. But because the
polygon does touch Bornholm's coastline, the cell is included and gets a
`grid_id`. The same logic applies to any other cell that clips a sliver of
Danish coastal territory or outlying island.

```
Grid polygon (0.5° × 0.5°)
┌─────────────────────────────────┐
│                                 │
│        Open Baltic Sea          │
│                                 │
│    ×  ← centroid in water       │
│                                 │
│                    ███ Bornholm │ ← overlap keeps this cell
└─────────────────────────────────┘
```

The centroid is just the geometric centre of the polygon. It does not know
whether it is over land or sea.

### How the pipeline handled water-centroid cells at each stage

**Stage 1 — Climate (WTH files)**

ISIMIP3b climate grids cover the entire globe, land and ocean alike.
Every 0.5-degree cell in the world has values for temperature, precipitation,
radiation, and wind. When `07_extract_zonal_stats_parquet.py` does its
point-in-polygon extraction, it finds NetCDF grid points that fall inside the
polygon — and for a mostly-sea polygon it averages ocean climate signal. A
complete parquet file is produced and `08_generate_wth_files.py` writes a
valid `.WTH` file. DSSAT reads it without complaint.

The ocean-influenced climate signal for Bornholm cells is actually reasonable:
Bornholm's climate is genuinely maritime — warmer winters, cooler summers,
higher humidity than inland Denmark. Using the sea-cell climate to represent
the island is defensible.

**Stage 2 — Soil (SOL file)**

The MSU Soil API performs a nearest-neighbour spatial lookup. When the query
point is in the sea, the API walks outward through its R-tree index until it
finds a real soil profile on land. For cells 10 and 11 it found profiles
24–30 km away — still within the 50 km acceptance threshold — and returned
them as `OK`. The assigned profiles come from a land pixel near the coast or
on Bornholm itself, so they are geologically reasonable.

The `soil_fetch_report.csv` records the actual `distance_km` between your
query point and the profile that was returned:

```
grid_id,lat,lon,api_lat,api_lon,distance_km,...,status
10,54.75077,14.74999,54.958,15.042,29.67,...,OK
11,54.75077,15.24999,54.958,15.125,24.39,...,OK
```

A distance of 25–30 km means the profile came from a land location about that
far from your water centroid — entirely plausible for a coastal island.

### What this means for your DSSAT runs

Having a cell in the dataset does not mean you must simulate crops there.
The table below gives a practical decision framework:

| Cell type | Verdict | Rationale |
|---|---|---|
| Centroid in water, polygon covers a real island (e.g. Bornholm) | **Keep** | The polygon contains farmland; climate and soil are representative |
| Centroid in water, polygon covers a narrow coastal strip | **Review** | Climate is ocean-dominated; check whether the strip has agricultural land |
| Centroid is mostly open sea, minimal land | **Exclude** | Running DSSAT there produces output but it has no agronomic meaning |

A clean way to filter after the fact: cross the 60 cells with an agricultural
land-cover raster (e.g. ESA CCI land cover or MODIS MCD12Q1) and compute the
cropland fraction per cell. Cells where cropland fraction is below a threshold
(for example 5 %) can be dropped from the ensemble analysis without affecting
the representativeness of the results for actual Danish farmland.

The pipeline deliberately includes all overlapping cells and leaves this
scientific decision to the analyst. The numbered scripts produce outputs; the
analyst decides which outputs are meaningful.

---

## Beginner takeaway

The full pipeline is more than a collection of scripts.

It is a chain of decisions:

- which variables to download
- which units to convert to
- how to handle spatial averaging
- how to handle missing elevation
- how to format the output so DSSAT can read it

Each script in the chain has one clear job.

When something breaks, the numbering tells you where to look.
The logs from each Slurm job tell you what went wrong.
The validate script tells you whether the outputs are complete.

That combination of numbered scripts, explicit logging, and a final count
check is the discipline that makes a pipeline reproducible rather than just
runnable once.
