# Hopf Biomass Subset Forensics

This note tests whether the paper's headline biomass metrics are better explained by a smaller subset of the 15 selected Florida treatments than by all destructive-harvest summaries pooled together.

Published abstract targets:

- aboveground biomass (`CWAD` proxy): `d = 0.91`, `RMSE = 482 kg ha-1`
- stem weight (`SWAD`): `d = 0.83`, `RMSE = 430 kg ha-1`

## All 15 selected cases

- `CWAD`: `n = 72`, `d = 0.987`, `RMSE = 573.7`
- `SWAD`: `n = 64`, `d = 0.976`, `RMSE = 526.1`

These pooled values are systematically better in `d` than the paper and still somewhat higher in `RMSE`, so they do not look like the abstract numbers.

## Best treatment-level subset matches

- `subset_min_8`: `8` cases, `CWAD d = 0.987`, `CWAD RMSE = 474.4`, `SWAD d = 0.976`, `SWAD RMSE = 430.8`, score `0.196`.
  Excluded: UFCI2201_1; UFCI2201_2; UFCI2201_3; UFCI2201_4; UFJA2101_1; UFJA2101_2; UFJA2201_2
- `subset_min_10`: `10` cases, `CWAD d = 0.988`, `CWAD RMSE = 442.5`, `SWAD d = 0.978`, `SWAD RMSE = 413.1`, score `0.217`.
  Excluded: UFCI2201_1; UFCI2201_2; UFCI2201_3; UFJA2101_1; UFJA2201_2
- `subset_min_12`: `13` cases, `CWAD d = 0.987`, `CWAD RMSE = 551.4`, `SWAD d = 0.984`, `SWAD RMSE = 403.5`, score `0.257`.
  Excluded: UFJA2201_2; UFJA2201_4

## Leave-one-out checks

- `leave_one_out`: `14` cases, `CWAD d = 0.986`, `CWAD RMSE = 563.9`, `SWAD d = 0.982`, `SWAD RMSE = 412.4`, score `0.267`.
  Excluded: UFJA2201_2
- `leave_one_out`: `14` cases, `CWAD d = 0.991`, `CWAD RMSE = 425.1`, `SWAD d = 0.973`, `SWAD RMSE = 511.3`, score `0.295`.
  Excluded: UFCI2201_2
- `leave_one_out`: `14` cases, `CWAD d = 0.988`, `CWAD RMSE = 564.0`, `SWAD d = 0.978`, `SWAD RMSE = 515.6`, score `0.329`.
  Excluded: UFJA2201_1
- `leave_one_out`: `14` cases, `CWAD d = 0.988`, `CWAD RMSE = 562.3`, `SWAD d = 0.977`, `SWAD RMSE = 522.9`, score `0.337`.
  Excluded: UFJA2201_4
- `leave_one_out`: `14` cases, `CWAD d = 0.986`, `CWAD RMSE = 589.0`, `SWAD d = 0.975`, `SWAD RMSE = 527.9`, score `0.372`.
  Excluded: UFCI2101_1
- `leave_one_out`: `14` cases, `CWAD d = 0.987`, `CWAD RMSE = 581.2`, `SWAD d = 0.976`, `SWAD RMSE = 534.2`, score `0.373`.
  Excluded: UFJA2201_3
- `leave_one_out`: `14` cases, `CWAD d = 0.988`, `CWAD RMSE = 582.5`, `SWAD d = 0.976`, `SWAD RMSE = 537.2`, score `0.379`.
  Excluded: UFJA2101_4
- `leave_one_out`: `14` cases, `CWAD d = 0.987`, `CWAD RMSE = 587.1`, `SWAD d = 0.976`, `SWAD RMSE = 536.2`, score `0.383`.
  Excluded: UFJA2101_2

## Simple group checks

- `keep_site_year_PSREU_2021`: `3` cases, `CWAD d = 0.993`, `CWAD RMSE = 426.0`, `SWAD d = 0.984`, `SWAD RMSE = 427.4`, score `0.238`
- `keep_N0`: `7` cases, `CWAD d = 0.978`, `CWAD RMSE = 329.1`, `SWAD d = 0.952`, `SWAD RMSE = 315.5`, score `0.446`
- `keep_site_year_PSREU_2022`: `4` cases, `CWAD d = 0.983`, `CWAD RMSE = 726.1`, `SWAD d = 0.988`, `SWAD RMSE = 420.0`, score `0.547`
- `keep_site_year_WFREC_2021`: `4` cases, `CWAD d = 0.993`, `CWAD RMSE = 287.6`, `SWAD d = 0.983`, `SWAD RMSE = 274.3`, score `0.580`
- `keep_cultivar_NWG 2730`: `8` cases, `CWAD d = 0.978`, `CWAD RMSE = 320.5`, `SWAD d = 0.957`, `SWAD RMSE = 218.3`, score `0.619`
- `keep_Nplus`: `8` cases, `CWAD d = 0.984`, `CWAD RMSE = 679.4`, `SWAD d = 0.972`, `SWAD RMSE = 624.8`, score `0.639`
- `keep_cultivar_IH Williams`: `7` cases, `CWAD d = 0.985`, `CWAD RMSE = 676.0`, `SWAD d = 0.971`, `SWAD RMSE = 636.6`, score `0.655`
- `keep_site_year_WFREC_2022`: `4` cases, `CWAD d = 0.982`, `CWAD RMSE = 691.7`, `SWAD d = 0.934`, `SWAD RMSE = 915.0`, score `1.218`

## Most recurrent exclusions in top subsets

- `UFCI2201_2`: excluded in `15` top-ranked subsets for `subset_min_10`
- `UFJA2201_2`: excluded in `15` top-ranked subsets for `subset_min_10`
- `UFJA2201_2`: excluded in `15` top-ranked subsets for `subset_min_12`
- `UFCI2201_2`: excluded in `15` top-ranked subsets for `subset_min_8`
- `UFCI2201_3`: excluded in `15` top-ranked subsets for `subset_min_8`
- `UFJA2201_2`: excluded in `15` top-ranked subsets for `subset_min_8`
- `UFCI2201_1`: excluded in `13` top-ranked subsets for `subset_min_8`
- `UFCI2201_4`: excluded in `12` top-ranked subsets for `subset_min_8`

## Interpretation

- Treatment selection clearly matters for `RMSE`: the best subsets repeatedly exclude `UFCI2201_2` and `UFJA2201_2`, both 2022 `IH Williams` runs at `280 kg N ha-1`, and often other `PSREU 2022` cases as well.
- That pattern matches the paper's statement that lower N treatments were sometimes preferred when high N treatments performed worse or had fewer usable observations.
- But treatment selection alone does not explain the published headline metrics, because even the best treatment-level subsets keep `CWAD d` and `SWAD d` near `0.97-0.99`, far above the published `0.91` and `0.83`.
- The most likely conclusion is therefore: the abstract biomass metrics were probably not computed from all pooled destructive-harvest summaries, but they also were not produced by a simple smaller treatment subset alone.
- A different aggregation or weighting protocol is still needed, most likely one that changes how repeated harvest observations contribute to `d`, while the treatment selection mainly influences `RMSE`.
