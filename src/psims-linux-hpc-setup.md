# pSIMS 2.0 — Linux HPC Setup and Run Guide

**Status as of 2026-05-21: fully operational.**
All three models (DSSAT 4.8, STICS 10, APSIM-X) run successfully on the HPC.

---

## Quick reference — what is where

| Thing | Path on HPC |
|---|---|
| pSIMS root | `~/psims_2.0/` |
| Python environment | `~/.conda/envs/mamba_env/envs/psims/bin/python` |
| DSSAT binary | `~/psims_2.0/tools/dssat48/dscsm048` |
| STICS JAR | `~/psims_2.0/tools/stics10/JavaSticsCmd.exe` |
| STICS Java runtime | `~/psims_2.0/tools/jdk-17.0.19+10-jre/bin/java` |
| APSIM-X wrapper | `~/psims_2.0/tools/apsimx/Models` |
| APSIM-X container | `~/crop-ensemble/containers/datamill.sif` |
| Sample data | `~/psims_2.0/samples/` |
| Params (Linux) | `~/psims_2.0/params/` |
| Outputs | `~/psims_2.0/outputs/` |

Replace `~` with `/home/<user>` if you need absolute paths.

---

## How to connect

```bash
ssh <user>@<hpc-host>
```

If you have an SSH alias configured (e.g. `hpc` in `~/.ssh/config`), you
can just run `ssh hpc`. See your SSH config for the actual hostname.

---

## Running a model — template command

All three models follow the same pattern:

```bash
cd ~/psims_2.0

~/.conda/envs/mamba_env/envs/psims/bin/python pysims/pysims.py \
    --param  params/<params-file>     \
    --campaign samples/<bundle>/campaign \
    --tlatidx 0001 --tlonidx 0001    \
    --latidx  1    --lonidx  1
```

The `--tlatidx`/`--tlonidx` flags choose which tile to read from disk.
`--latidx`/`--lonidx` choose the point within that tile.
For the single-point sample data both are always `0001` / `1`.

---

## Running each model

### DSSAT 4.8

```bash
cd ~/psims_2.0

~/.conda/envs/mamba_env/envs/psims/bin/python pysims/pysims.py \
    --param params/params.dssat48.point.linux.sample \
    --campaign samples/dssat48_point_bundle/campaign \
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

```bash
cd ~/psims_2.0

~/.conda/envs/mamba_env/envs/psims/bin/python pysims/pysims.py \
    --param params/params.stics.point.linux.sample \
    --campaign samples/stics_point_bundle/campaign \
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

**How STICS runs on Linux:**  
pSIMS invokes `java -jar JavaSticsCmd.exe --run <workspace> maize` using
the bundled JRE 17 (`tools/jdk-17.0.19+10-jre/`). The `java_executable`
param in the params file activates this mode. No system Java or JavaStics
installation is needed.

---

### APSIM-X (Next Generation)

```bash
cd ~/psims_2.0

~/.conda/envs/mamba_env/envs/psims/bin/python pysims/pysims.py \
    --param params/params.apsimx.point.linux.sample \
    --campaign samples/apsimx_point_bundle/campaign \
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

**How APSIM runs on Linux:**  
The file `tools/apsimx/Models` is a shell script that calls:
```bash
apptainer exec --bind "$(pwd):$(pwd)" \
  ~/crop-ensemble/containers/datamill.sif \
  Models "$@"
```
The `Models` binary lives inside the `datamill.sif` Apptainer container
(AgriScale v1.2.0). The container auto-binds `$HOME`, so all paths under
`~/psims_2.0/` are accessible to APSIM inside the container.

---

## Checking output values

After any run, the output is written to
`~/psims_2.0/outputs/output_0001_0001.psims.nc`.

```bash
cd ~/psims_2.0
~/.conda/envs/mamba_env/envs/psims/bin/python - << 'EOF'
import netCDF4
nc = netCDF4.Dataset('outputs/output_0001_0001.psims.nc')
for v in nc.variables:
    if v not in ('lon', 'lat', 'time', 'scen'):
        val = float(nc.variables[v][:].flatten()[0])
        print(f'  {v} = {val} {nc.variables[v].units}')
nc.close()
EOF
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

These values match exactly with the Windows runs — the pipeline is
deterministic across platforms for the sample data.

---

## Troubleshooting

### Any step shows `False`

Check the full output (remove `2>/dev/null` from your command). The failed
step will print a Python traceback. Common causes:

| Symptom | Likely cause | Fix |
|---|---|---|
| `FileNotFoundError` in `StageInputsSharedFS` | Missing sample data directory | Check `samples/<model>_point_bundle/` structure |
| `ApsimX` step fails | Apptainer can't find the container | Verify `~/crop-ensemble/containers/datamill.sif` exists |
| `Stics` step fails | Java not found | Check `tools/jdk-17.0.19+10-jre/bin/java` exists |
| `Dssat48` step fails | Binary not executable | Run `chmod +x tools/dssat48/dscsm048` |

### Output file not created

If the `Out2Psims` or `StageOutputsSharedFS` step shows `False`, the
output file will not exist. Fix the root cause and re-run. You can safely
delete `outputs/output_0001_0001.psims.nc` between runs.

### Conda environment not found

The activate step is not needed when using the full path:
```bash
~/.conda/envs/mamba_env/envs/psims/bin/python
```
If that path does not exist, check with:
```bash
conda env list
```

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

## Sample data layout

```
samples/
  dssat48_point_bundle/
    campaign/   Campaign.nc4 + exp_template.json
    weather/    0001/clim_0001_0001.tile.nc4
    soils/      0001/soil_0001_0001.tile.nc4
    refdata/    DSCSM048.EXE, CUL/ECO/SPE files, ...

  stics_point_bundle/
    campaign/   experiment.json
    weather/    0001/clim_0001_0001.tile.nc4
    soils/      0001/soil_0001_0001.tile.nc4
    refdata/    workspace_template/ (STICS XML files)

  apsimx_point_bundle/
    campaign/   experiment.json + Maize.apsimx
    weather/ →  symlink to dssat48_point_bundle/weather/
    soils/   →  symlink to dssat48_point_bundle/soils/
    refdata/    Maize.apsimx
```

The APSIM weather and soils directories are symlinks to the DSSAT bundle —
the pSIMS NetCDF tile format is the same for all models.

---

## Re-deploying after code changes

When you push pSIMS code changes from Windows, sync them to the HPC with:

```bash
# From your local machine (Git Bash or WSL)
rsync -av --exclude='*.pyc' --exclude='__pycache__' \
  /path/to/psims-release-2.0/pysims/ \
  <user>@<hpc-host>:~/psims_2.0/pysims/
```

Sample data and params files only need to be re-synced if they change.
