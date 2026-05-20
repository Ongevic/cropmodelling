# Omniwrapper Family Coverage

Status meanings:
- `tested`: validated end-to-end through `DSSAT_omniwrapper.R`.
- `trace_only`: installed DSSAT examples ran successfully in the executable trace, but not yet through the omniwrapper.
- `trace_failures`: installed DSSAT examples were traced, but current runs fail and need family-specific fixes.
- `blocked_model_data`: the omniwrapper reaches the target model, but the current local data/model setup still stops inside DSSAT.
- `recognized_only`: present in the DSSAT registry and family map, but not yet validated by trace or wrapper test.

| Family | Status | Crop Codes | Model Codes | Tested | Trace Attempts | Trace Success | Trace Failures | Representative Example | Notes |
|---|---|---|---|---:|---:|---:|---:|---|---|
| ALOHA | tested | PI | PIALO | 1 | 3 | 3 | 0 | UHKN8901.PIX | Validated through DSSAT_omniwrapper with CWAD output. Includes crop code(s) without .ECO files: PI. |
| AROIDS | tested | TN, TR | TNARO, TRARO | 1 | 5 | 5 | 0 | IBHK8901.TRX | Validated through DSSAT_omniwrapper with CWAD output using fallback PlantGro parser. Includes crop code(s) without .ECO files: TN, TR. |
| CANEGRO | tested | SC | SCCAN | 1 | 8 | 8 | 0 | ESAL1401.SCX | Validated through DSSAT_omniwrapper with SCCAN048 and LAIGD output. |
| CASUPRO | tested | SC | SCCSP | 1 | 0 | 0 | 0 | ESAL1401.SCX | Validated through DSSAT_omniwrapper with SCCSP048 and LAIGD output. |
| CERES | tested | BA, BS, ML, MZ, RI, RY, SG, SW, TF, WH | BSCER, CSCER, MLCER, MZCER, RICER, SGCER, SWCER, TFCER | 1 | 41 | 41 | 0 | KSAS8101.WHX | Validated through DSSAT_omniwrapper with GSTD output. Includes crop code(s) without .ECO files: RI, RY, TF. |
| CERES-IXIM | tested | MZ | MZIXM | 1 | 0 | 0 | 0 | UFGA8201.MZX | Validated through DSSAT_omniwrapper with MZIXM048 and CWAD output. |
| CROPGRO | tested | AM, BC, BG, BH, BN, BR, CB, CH, CI, CN, CO, CP, FA, FB, FX, GB, GY, HM, LT, NP, PE, PN, PP, PR, QU, SB, SF, SR, SU, TM, VB | CRGRO | 2 | 139 | 139 | 0 | CLMO8501.SBX, UFDSS0301.HMX | Validated through DSSAT_omniwrapper with CWAD output. Validated through DSSAT_omniwrapper with CWAD output. Includes crop code(s) without .ECO files: FA, FX, NP, PE. |
| CROPSIM | tested | BA, WH | CSCRP | 1 | 0 | 0 | 0 | IEBR8201.BAX | Validated through DSSAT_omniwrapper with CSCRP048 and GSTD output. |
| CSCAS | blocked_model_data | CS | CSCAS | 0 | 0 | 0 | 0 | CCPA7801.CSX | Wrapper launch reaches CSCAS048, but the model exits with 'Missing ecotype coefficients. Fix ecotype input file. Error key: IPECO'. |
| CSYCA | tested | CS | CSYCA | 1 | 4 | 4 | 0 | CCPA7801.CSX | Validated through DSSAT_omniwrapper with CWAD output. |
| FORAGE | trace_failures | AL, BH, BM, BR, GG, PO | PRFRM | 0 | 13 | 0 | 13 | AGZG1219.ALX, AGZG1229.ALX, AGZG1501.ALX | Installed DSSAT examples were traced but currently fail before omniwrapper validation. Includes crop code(s) without .ECO files: PO. Current installed example failures are concentrated here and are linked to extra mowing inputs such as .MOW files. |
| NWHEAT | tested | TF, WH | TFAPS, WHAPS | 2 | 0 | 0 | 0 | ETGA0201.TFX, KSAS8101.WHX | Validated through DSSAT_omniwrapper with TFAPS048 and CWAD output. Validated through DSSAT_omniwrapper with WHAPS048 and GSTD output. |
| OILCROP | tested | SU | SUOIL | 1 | 0 | 0 | 0 | AUTA8101.SUX | Validated through DSSAT_omniwrapper with SUOIL048 and CWAD output. |
| SAMUCA | tested | SC | SCSAM | 1 | 0 | 0 | 0 | SAPO8601.SCX | Validated through DSSAT_omniwrapper with SCSAM048 and LAIGD output. |
| SUBSTOR | tested | PT | PTSUB | 1 | 10 | 10 | 0 | AUCB7001.PTX | Validated through DSSAT_omniwrapper with TWAD output. |

Key current result:
- The prototype is now proven across `ALOHA`, `AROIDS`, `CANEGRO`, `CASUPRO`, `CERES`, `CERES-IXIM`, `CROPGRO`, `CROPSIM`, `CSYCA`, `NWHEAT`, `OILCROP`, `SAMUCA`, and `SUBSTOR`.
- `CSCAS` is no longer a wrapper-design unknown; it is specifically blocked by a DSSAT-side ecotype error in the current local setup.
- The next highest-value unresolved family is `FORAGE`, where installed examples still fail around extra mowing inputs such as `.MOW` files.
