# 🚀 Quick Start Guide

Get your Sakha95 calibration running in 5 minutes!

## Prerequisites Checklist

- [ ] R installed (version ≥ 4.0)
- [ ] DSSAT 4.8 installed at `C:/DSSAT48`
- [ ] DSSAT-wrapper functions downloaded
- [ ] Field data files in place

## Step-by-Step Setup

### 1. Install R Packages (2 minutes)

```r
# Open R or RStudio
install.packages(c("nloptr", "dplyr", "ggplot2", "tidyr", "gridExtra"))
```

### 2. Download DSSAT-wrapper (1 minute)

```r
# Download from GitHub
download.file(
  "https://raw.githubusercontent.com/DrAhmedKheir/DSSAT-wrapper/main/R/DSSAT_wrapper.R",
  "DSSAT_wrapper.R"
)
download.file(
  "https://raw.githubusercontent.com/DrAhmedKheir/DSSAT-wrapper/main/R/read_obs.R",
  "read_obs.R"
)
```

### 3. Verify DSSAT Files (1 minute)

```r
# Check if files exist
file.exists("C:/DSSAT48/DSCSM048.EXE")              # Should be TRUE
file.exists("C:/DSSAT48/Wheat/GMZA2001.WHX")        # Should be TRUE
file.exists("C:/DSSAT48/Wheat/SIDS2001.WHX")        # Should be TRUE
file.exists("C:/DSSAT48/Genotype/WHCER048.CUL")     # Should be TRUE
```

### 4. Run Calibration (25 minutes)

```r
setwd("path/to/your/project")
source("calibrate_Sakha95_FINAL_CORRECTED.R")

# Wait for completion...
# You should see:
# ✓ Calibration successful!
# Improvement: 69.2%
```

### 5. Generate Visualizations (25 minutes)

```r
source("visualize_Sakha95_calibration.R")

# Creates plots in: Sakha95_CORRECTED_results/plots/
```

## Expected Output

```
Sakha95_CORRECTED_results/
├── plots/
│   ├── HWAM_scatter.png
│   ├── ADAT_scatter.png
│   ├── ALL_VARIABLES_scatter.png
│   └── ... (10+ plots)
├── calibrated_parameters.csv
├── statistics_summary.csv
└── calibration.RData
```

## Viewing Results

```r
# Load results
load("Sakha95_CORRECTED_results/calibration.RData")

# View parameter table
print(param_table)

# Open plots folder
shell.exec("Sakha95_CORRECTED_results/plots")  # Windows
# Or: system("open Sakha95_CORRECTED_results/plots")  # Mac
```

## Common Issues

### Issue 1: "Cannot find DSSAT_wrapper.R"

**Solution:**
```r
# Check current directory
getwd()

# List files
list.files(pattern = "DSSAT")

# If missing, re-download (see Step 2)
```

### Issue 2: "Calibration results not found"

**Cause:** Calibration script didn't complete successfully

**Solution:**
```r
# Run calibration first
source("calibrate_Sakha95_FINAL_CORRECTED.R")

# Then visualization
source("visualize_Sakha95_calibration.R")
```

### Issue 3: Long runtime (>1 hour)

**Check:**
```r
# Is DSSAT running?
# Open Task Manager (Windows) and look for DSCSM048.EXE

# Check for disk space
# DSSAT writes many temporary files
```

## Next Steps

1. **Review Documentation**: Read `CALIBRATION_COMPLETE_DOCUMENTATION.md`
2. **Analyze Results**: Check scatter plots and statistics
3. **Update Cultivar File**: Apply calibrated parameters to `WHCER048.CUL`
4. **Validate**: Test with independent data
5. **Publish**: Use plots in your manuscript

## Need Help?

- Check [Troubleshooting Guide](TROUBLESHOOTING.md)
- Review [Full Documentation](CALIBRATION_COMPLETE_DOCUMENTATION.md)
- Open a GitHub Issue

---

**Total Time: ~55 minutes (5 min setup + 25 min calibration + 25 min visualization)**

✅ You're ready to go!
