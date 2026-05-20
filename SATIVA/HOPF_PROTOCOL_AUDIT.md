# Hopf Protocol Audit

This note compares multiple reasonable metric protocols against the published headline values in Hopf et al. (2025).

Published abstract targets:

- aboveground biomass: `d = 0.91`, `RMSE = 482 kg ha-1`
- stem weight: `d = 0.83`, `RMSE = 430 kg ha-1`
- flowering difference range: `+4 to -5 days`

## Protocol comparison

- `CWAD` with `raw_replicates`: `n = 322`, `d = 0.962`, `RMSE = 971.1`
- `CWAD` with `date_means`: `n =  72`, `d = 0.987`, `RMSE = 573.7`
- `SWAD` with `raw_replicates`: `n = 260`, `d = 0.951`, `RMSE = 754.6`
- `SWAD` with `date_means`: `n =  64`, `d = 0.976`, `RMSE = 526.1`

## Site-year date-mean comparison

- `CWAD`, `PSREU 2021`: `n = 19`, `d = 0.993`, `RMSE = 426.0`
- `CWAD`, `PSREU 2022`: `n = 25`, `d = 0.983`, `RMSE = 726.1`
- `CWAD`, `WFREC 2021`: `n = 16`, `d = 0.993`, `RMSE = 287.6`
- `CWAD`, `WFREC 2022`: `n = 12`, `d = 0.982`, `RMSE = 691.7`
- `SWAD`, `PSREU 2021`: `n = 18`, `d = 0.984`, `RMSE = 427.4`
- `SWAD`, `PSREU 2022`: `n = 18`, `d = 0.988`, `RMSE = 420.0`
- `SWAD`, `WFREC 2021`: `n = 16`, `d = 0.983`, `RMSE = 274.3`
- `SWAD`, `WFREC 2022`: `n = 12`, `d = 0.934`, `RMSE = 915.0`

## Flowering-date comparison

- Current reproduced flowering range: `-7` to `+2` days

## Interpretation

- `date_means` produces lower RMSE and much higher `d` than the published abstract values.
- `raw_replicates` lowers `d` in the expected direction, but RMSE becomes much larger than the published values.
- The published protocol therefore appears to be more selective than simple pooled date means, but less noisy than raw replicate pooling.
- The paper text confirms that metrics were based on `observed and simulated periodic harvests`, while some non-destructive measurements were also collected on standing plants.
- That suggests the next accuracy step is to isolate the exact destructive-harvest subset used by the authors rather than pooling every compatible date-value pair.

## Most likely next refinement

Build a harvest-only comparison table from the raw `.HMT` observations by identifying dates where destructive biomass sampling occurred, then recompute `CWAD` and `SWAD` metrics on that restricted subset.
