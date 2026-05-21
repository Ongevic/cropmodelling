# pSIMS 2.0 — Windows Setup and Run Guide

**Status as of 2026-05-21: fully operational.**
All three models (DSSAT 4.8, STICS 10, APSIM-X) run successfully on Windows.

---

## Quick reference — what is where

| Thing | Path |
|---|---|
| pSIMS working directory | `C:\Users\<user>\Downloads\psims-release-2.0\` |
| Python (venv) | `psims-release-2.0\.venv\Scripts\python.exe` |
| DSSAT binary | `samples\dssat48_point_bundle\refdata\DSCSM048.EXE` (relative to pSIMS root) |
| STICS launcher | `C:\Users\<user>\Downloads\JavaSTICS-10.4.1-STICS-10.4.1\...\JavaSticsCmd.exe` |
| APSIM-X binary | `C:\Program Files\APSIM<version>\bin\Models.exe` |
| Sample data | `psims-release-2.0\samples\` |
| Params (Windows) | `psims-release-2.0\params.*.sample` (in root) |
| Outputs | `psims-release-2.0\outputs\` |

> **Important:** always run from the `psims-release-2.0\` directory.
> The params files use relative paths like `samples/...` and `pysims/...`
> that only resolve correctly when you start there.

---

## Prerequisites

These must already be installed on your machine. If any are missing,
install them before trying to run a model.

### 1. Python virtual environment

The venv lives at `psims-release-2.0\.venv\`. It is created once and
reused for all runs.

To create it (first time only):

```powershell
cd C:\Users\<user>\Downloads\psims-release-2.0
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Verify:

```powershell
.venv\Scripts\python.exe -c "import netCDF4, scipy, numpy; print('OK')"
```

### 2. DSSAT 4.8

The `DSCSM048.EXE` binary is bundled inside the repo at
`samples\dssat48_point_bundle\refdata\DSCSM048.EXE`. No separate
installation is needed for the sample test.

For a full installation, DSSAT 4.8 can be installed from the official
DSSAT website. pSIMS will use the binary path set in the params file.

### 3. STICS 10

Install from the JavaStics package. After installation, note the path to
`JavaSticsCmd.exe` — it will be something like:

```
C:\Users\<user>\Downloads\JavaSTICS-10.4.1-STICS-10.4.1\
  JavaSTICS-10.4.1-STICS-10.4.1\JavaSticsCmd.exe
```

The params file (`params.stics.point.sample`) needs both:
- `executable` — full path to `JavaSticsCmd.exe`
- `workdir` — directory *containing* `JavaSticsCmd.exe` (JavaStics must
  be run from its own folder)

### 4. APSIM-X (Next Generation)

Install APSIM Next Generation from the APSIM website. After installation,
the binary will be at:

```
C:\Program Files\APSIM<version>\bin\Models.exe
```

Check `params.apsimx.point.sample` for the exact version path that was
verified — update it if your installed version differs.

---

## Adjusting paths in params files

Before running, open each params file and confirm the executable paths
match your local installation.

**`params.dssat48.point.sample`** — no changes needed for the sample test.
DSSAT runs from the refdata directory using the bundled EXE.

**`params.stics.point.sample`** — set these two lines:

```yaml
executable:  "C:\\Users\\<user>\\Downloads\\JavaSTICS-10.4.1-STICS-10.4.1\\JavaSTICS-10.4.1-STICS-10.4.1\\JavaSticsCmd.exe"
workdir:     "C:\\Users\\<user>\\Downloads\\JavaSTICS-10.4.1-STICS-10.4.1\\JavaSTICS-10.4.1-STICS-10.4.1"
```

**`params.apsimx.point.sample`** — set:

```yaml
executable:  "C:\\Program Files\\APSIM<version>\\bin\\Models.exe"
```

Use double backslashes (`\\`) inside YAML quoted strings.

---

## Running a model — template command

Open **PowerShell** or **Git Bash**, `cd` to the pSIMS root, then:

```powershell
cd C:\Users\<user>\Downloads\psims-release-2.0

.venv\Scripts\python.exe pysims\pysims.py `
    --param  params.<model>.point.sample `
    --campaign samples\<model>_point_bundle\campaign `
    --tlatidx 0001 --tlonidx 0001 `
    --latidx  1    --lonidx  1
```

(In Git Bash, use forward slashes and `\` line continuation instead of
the PowerShell backtick.)

---

## Running each model

### DSSAT 4.8

```powershell
cd C:\Users\<user>\Downloads\psims-release-2.0

.venv\Scripts\python.exe pysims\pysims.py `
    --param params.dssat48.point.sample `
    --campaign samples\dssat48_point_bundle\campaign `
    --tlatidx 0001 --tlonidx 0001 --latidx 1 --lonidx 1
```

**Expected output** — every line ends with `True`:

```
0001/0001, StageInputsSharedFS, run_tile, ..., True
0001/0001, StageInputsSharedFS, run,      ..., True
0001/0001, Camp2Json,           run,      ..., True
0001/0001, Psims2Wth,           run,      ..., True
0001/0001, Jsons2Dssat,         run,      ..., True
0001/0001, Dssat48,             run,      ..., True
0001/0001, Out2Psims,           run,      ..., True
0001/0001, StageOutputsSharedFS,run,      ..., True
```

**Known harmless warning** (safe to ignore):
```
UserWarning: Real number is too long
```

---

### STICS 10

```powershell
cd C:\Users\<user>\Downloads\psims-release-2.0

.venv\Scripts\python.exe pysims\pysims.py `
    --param params.stics.point.sample `
    --campaign samples\stics_point_bundle\campaign `
    --tlatidx 0001 --tlonidx 0001 --latidx 1 --lonidx 1
```

**Expected output:**

```
0001/0001, StageInputsSharedFS, run_tile, ..., True
0001/0001, StageInputsSharedFS, run,      ..., True
0001/0001, Psims2Stics,         run,      ..., True
0001/0001, Jsons2Stics,         run,      ..., True
0001/0001, Stics,               run,      ..., True
0001/0001, Out2Psims,           run,      ..., True
0001/0001, StageOutputsSharedFS,run,      ..., True
```

**How STICS runs on Windows:**  
pSIMS calls `JavaSticsCmd.exe --run <workspace_abs_path> maize` from the
JavaStics install directory (`workdir`). JavaSticsCmd.exe bridges the
XML workspace format to the underlying `stics_modulo` binary.

---

### APSIM-X (Next Generation)

```powershell
cd C:\Users\<user>\Downloads\psims-release-2.0

.venv\Scripts\python.exe pysims\pysims.py `
    --param params.apsimx.point.sample `
    --campaign samples\apsimx_point_bundle\campaign `
    --tlatidx 0001 --tlonidx 0001 --latidx 1 --lonidx 1
```

**Expected output:**

```
0001/0001, StageInputsSharedFS, run_tile, ..., True
0001/0001, StageInputsSharedFS, run,      ..., True
0001/0001, Psims2Met,           run,      ..., True
0001/0001, Jsons2Apsimx,        run,      ..., True
0001/0001, ApsimX,              run,      ..., True
0001/0001, Out2Psims,           run,      ..., True
0001/0001, StageOutputsSharedFS,run,      ..., True
```

---

## Checking output values

After any run the output is written to
`psims-release-2.0\outputs\output_0001_0001.psims.nc`.

```powershell
cd C:\Users\<user>\Downloads\psims-release-2.0

.venv\Scripts\python.exe -c "
import netCDF4
nc = netCDF4.Dataset('outputs/output_0001_0001.psims.nc')
for v in nc.variables:
    if v not in ('lon', 'lat', 'time', 'scen'):
        val = float(nc.variables[v][:].flatten()[0])
        print(f'{v} = {val} {nc.variables[v].units}')
nc.close()
"
```

### Verified reference outputs (sample data, 1982 Gainesville FL)

| Model | Variable | Value | Units |
|---|---|---|---|
| DSSAT 4.8 | HWAM (grain yield) | 2283 | kg/ha |
| DSSAT 4.8 | PDAT (planting DOY) | 57 | DOY |
| DSSAT 4.8 | MDAT (maturity) | 128 | Days |
| STICS 10 | masec(n) (biomass) | 1.1875 | t/ha |
| STICS 10 | mafruit (grain) | 0.8032 | t/ha |
| APSIM-X | Yield | 2143.31 | kg/ha |

These match the HPC Linux runs exactly.

---

## Troubleshooting

### Any step shows `False`

The failed step will print a Python traceback above the result line.

| Symptom | Likely cause | Fix |
|---|---|---|
| `FileNotFoundError: DSCSM048.EXE` | Wrong executable path | Check `executable` in params file |
| `FileNotFoundError: JavaSticsCmd.exe` | Wrong STICS path | Update `executable` and `workdir` in params |
| `FileNotFoundError: Models.exe` | Wrong APSIM path or version | Check APSIM installation directory |
| `ModuleNotFoundError` | Wrong Python used | Make sure you use `.venv\Scripts\python.exe` |
| `FileNotFoundError` in `StageInputsSharedFS` | Running from wrong directory | `cd` to `psims-release-2.0\` first |

### "Real number is too long" warning

This comes from DSSAT's CUL/ECO file reader and is harmless. The run
completes correctly and values are read correctly.

### APSIM takes longer than expected

APSIM-X takes ~10–12 seconds on the first run (JIT warm-up). Subsequent
runs in the same session are faster. This is normal.

### Output values don't match reference

Possible causes:
1. Different APSIM version — APSIM results can vary slightly between
   versions. Check your installed version against what the params file
   references.
2. Different STICS version — same applies.
3. The run completed but with a different input — check that the campaign
   and weather tile are the same sample files.

---

## Architecture overview

```
params file  ─────────────────────────────────────────────┐
                                                           ▼
pysims.py → StageInputsSharedFS  (copy tiles to workdir)
          → [tappcmp]            (campaign → experiment.json)
          → tappwth              (climate tile → model weather file)
          → tappinp              (soil tile + experiment → model input)
          → model binary         (DSSAT / STICS / APSIM)
          → postprocess          (model output → psims.nc)
          → StageOutputsSharedFS (copy psims.nc to outputs/)
```

Each step is a Python class. The pipeline logs each step with its
runtime and a `True`/`False` pass flag.

---

## What is different between Windows and Linux

| Aspect | Windows | Linux HPC |
|---|---|---|
| Python | `.venv\Scripts\python.exe` | `~/.conda/envs/mamba_env/envs/psims/bin/python` |
| Working directory | `psims-release-2.0\` | `~/psims_2.0/` |
| DSSAT binary | `DSCSM048.EXE` (Windows PE) | `dscsm048` (Linux ELF) |
| STICS invocation | `JavaSticsCmd.exe` called directly | `java -jar JavaSticsCmd.exe` (bundled JRE 17) |
| APSIM invocation | `Models.exe` called directly | Shell wrapper → `apptainer exec datamill.sif Models` |
| Params location | root of working directory | `params/` subdirectory |
| Path separators | backslash (or forward slash in YAML) | forward slash only |

The pipeline code, sample data, and output format are identical on both
platforms.
