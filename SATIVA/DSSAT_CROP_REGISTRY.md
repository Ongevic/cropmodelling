# DSSAT Crop Registry

Generated from:

- `C:\DSSAT48` install
- `dssat-csm-os\Data\SIMULATION.CDE`
- `dssat-csm-os\Data\DSSATPRO.v48`
- `dssat-csm-os\Plant\...` source families

## Summary

- Total model/crop combinations: 62
- Unique crop codes: 51
- Unique wrapper adapters proposed: 12

## Adapter Groups

- `ALOHA`: PI:PIALO
- `AROIDS`: TN:TNARO, TR:TRARO
- `CERES`: BA:CSCER, BS:BSCER, ML:MLCER, MZ:MZCER, MZ:MZIXM, RI:RICER, RY:CSCER, SG:SGCER, SW:SWCER, TF:TFCER, WH:CSCER
- `CROPGRO`: AM:CRGRO, BC:CRGRO, BG:CRGRO, BH:CRGRO, BN:CRGRO, BR:CRGRO, CB:CRGRO, CH:CRGRO, CI:CRGRO, CN:CRGRO, CO:CRGRO, CP:CRGRO, FA:CRGRO, FB:CRGRO, FX:CRGRO, GB:CRGRO, GY:CRGRO, HM:CRGRO, LT:CRGRO, NP:CRGRO, PE:CRGRO, PN:CRGRO, PP:CRGRO, PR:CRGRO, QU:CRGRO, SB:CRGRO, SF:CRGRO, SR:CRGRO, SU:CRGRO, TM:CRGRO, VB:CRGRO
- `CROPSIM`: BA:CSCRP, WH:CSCRP
- `CSCAS`: CS:CSCAS
- `CSYCA`: CS:CSYCA
- `FORAGE`: AL:PRFRM, BH:PRFRM, BM:PRFRM, BR:PRFRM, GG:PRFRM, PO:PRFRM
- `NWHEAT`: TF:TFAPS, WH:WHAPS
- `OILCROP`: SU:SUOIL
- `SUBSTOR`: PT:PTSUB
- `SUGARCANE`: SC:SCCAN, SC:SCCSP, SC:SCSAM

## Profile vs Source Notes

- `default_profile_module` is what DSSATPRO points to by default for a crop code.
- `is_default_profile_module = false` means the source exposes an alternate model variant that is not the default profile target.
- These cases matter for an omniwrapper because crop code alone is not always enough.

## Special Cases

- `BA` / `CSCRP` / `CSCRP048`: default profile points to CSCER048
- `BH` / `CRGRO` / `CRGRO048`: default profile points to PRFRM048
- `BR` / `CRGRO` / `CRGRO048`: default profile points to PRFRM048
- `CS` / `CSCAS` / `CSCAS048`: default profile points to CSYCA048
- `FA` / `CRGRO` / `CRGRO048`: no .ECO file
- `FX` / `CRGRO` / `CRGRO048`: no .ECO file
- `MZ` / `MZIXM` / `MZIXM048`: default profile points to MZCER048
- `NP` / `CRGRO` / `CRGRO048`: no .ECO file
- `PE` / `CRGRO` / `CRGRO048`: no .ECO file
- `PI` / `PIALO` / `PIALO048`: no .ECO file
- `PO` / `PRFRM` / `PRFRM048`: no .ECO file
- `RI` / `RICER` / `RICER048`: no .ECO file
- `RY` / `CSCER` / `CSCER048`: no .ECO file
- `SC` / `SCCSP` / `SCCSP048`: default profile points to SCCAN048
- `SC` / `SCSAM` / `SCSAM048`: default profile points to SCCAN048
- `SU` / `SUOIL` / `SUOIL048`: default profile points to CRGRO048
- `TF` / `TFCER` / `TFCER048`: no .ECO file; default profile points to TFAPS048
- `TN` / `TNARO` / `TNARO048`: no .ECO file
- `TR` / `TRARO` / `TRARO048`: no .ECO file
- `WH` / `CSCRP` / `CSCRP048`: default profile points to CSCER048
- `WH` / `WHAPS` / `WHAPS048`: default profile points to CSCER048
