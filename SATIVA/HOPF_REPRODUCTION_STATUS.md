# Hopf Reproduction Status

This workspace now contains a first reproducible rerun of the 15 Florida hemp cases reported in:

Hopf et al. (2025), "Adaptation of the process-based CSM-CROPGRO model to simulate the growth and development of industrial hemp for seed and fiber production".

## What is reproduced now

- The exact four paper experiment files from `dssat-csm-data/Hemp`:
  - `UFCI2101.HMX`
  - `UFCI2201.HMX`
  - `UFJA2101.HMX`
  - `UFJA2201.HMX`
- All 15 treatment cases listed in Table 2.
- Observed time-course and anthesis files from:
  - `.HMT`
  - `.HMA`
- A wrapper-based rerun through the refactored `DSSAT_omniwrapper`.

## Main script

- [hopf_reproduction.R](C:/Users/chich/Downloads/DSSAT%20Files/sativa/hopf_reproduction.R)

Run with:

```powershell
& "C:\Program Files\R\R-4.5.3\bin\x64\Rscript.exe" `
  "C:\Users\chich\Downloads\DSSAT Files\sativa\hopf_reproduction.R"
```

## Output files

Written to:

- [hopf_reproduction_outputs](C:/Users/chich/Downloads/DSSAT%20Files/sativa/hopf_reproduction_outputs)

Key files:

- [hopf_cases.csv](C:/Users/chich/Downloads/DSSAT%20Files/sativa/hopf_reproduction_outputs/hopf_cases.csv)
- [hopf_joined_timeseries.csv](C:/Users/chich/Downloads/DSSAT%20Files/sativa/hopf_reproduction_outputs/hopf_joined_timeseries.csv)
- [hopf_metrics_by_case.csv](C:/Users/chich/Downloads/DSSAT%20Files/sativa/hopf_reproduction_outputs/hopf_metrics_by_case.csv)
- [hopf_metrics_overall.csv](C:/Users/chich/Downloads/DSSAT%20Files/sativa/hopf_reproduction_outputs/hopf_metrics_overall.csv)
- [hopf_flowering_summary.csv](C:/Users/chich/Downloads/DSSAT%20Files/sativa/hopf_reproduction_outputs/hopf_flowering_summary.csv)

## First-pass results

These are direct pooled comparisons on matched observation dates from the current script:

- `CWAD`: `d = 0.987`, `RMSE = 573.7`
- `SWAD`: `d = 0.976`, `RMSE = 526.1`
- `CHTD`: `d = 0.956`, `RMSE = 0.290`
- flowering date difference range: `-7` to `+2` days
- flowering date mean difference: `-0.2` days

## Important caution

This is a strong reproduction of the model runs and observed-vs-simulated joins, but it should still be treated as a `first-pass reproduction`, not yet the final paper-faithful benchmark.

Why:

- the paper's exact metric protocol still needs to be matched carefully
- some published summaries may use selected subsets, different aggregation rules, or specific harvest groupings
- the two `UFJA2101` NWG 2730 cases currently show a `-7 day` flowering difference, which falls outside the paper abstract's stated `+4 to -5 days`

## Best next step

The next refinement should be to inspect the paper's exact evaluation protocol and then update the script so that:

- biomass metrics are calculated with the same observation subset rules as the paper
- stem and grain comparisons use the exact same harvest definitions
- flowering comparison uses the same event definition the authors used in their final tables and figures
