# Self-Check and Validation

This chapter explains how the wrapper protects itself against common failures.

## Why a self-check matters

Many DSSAT failures happen before the biology starts:

- a required file is missing
- the wrong crop folder is assumed
- a genotype file is absent
- the project file lives outside the installed DSSAT crop folder
- the requested variable does not exist for that family

If we only discover those issues after a failed run, debugging becomes slow and noisy.

## `DSSAT_omni_self_check()`

The self-check is designed to fail early and readably.

It inspects things like:

- DSSAT executable
- `SIMULATION.CDE`
- `DSSATPRO.V48`
- project file
- genotype directory
- species, cultivar, and ecotype files when relevant
- companion observation files
- situation naming consistency
- requested variable availability

This check runs before `DSSAT_omniwrapper()` launches DSSAT.

## Why this is especially important in a multi-family wrapper

A crop-specific wrapper can rely on more fixed assumptions.

A multi-family wrapper cannot.

That means validation has to be more explicit because we are working across:

- different model engines
- different genotype patterns
- different output conventions
- different companion observation layouts

## Smoke tests vs broader validation

The repo uses more than one validation layer.

### Smoke tests

These confirm the core path is still alive.

Examples:

- `DSSAT-wrapper/R/test_DSSAT_omni_self_check.R`
- `DSSAT-wrapper/R/test_DSSAT_omniwrapper.R`
- `DSSAT-wrapper/R/test_DSSAT_omni_read_obs.R`

### Cross-family validation

This confirms the architecture still works across the broader supported set.

Example:

- `DSSAT-wrapper/R/validate_DSSAT_omniwrapper_families.R`

These validation scripts are designed for other users to run on their own
machines. They use:

- `DSSAT_PATH` for the local DSSAT installation
- `DSSAT_CSM_DATA` for an optional local clone of `dssat-csm-data`

If `DSSAT_PATH` is not set, the scripts try the common Windows default
`C:/DSSAT48`.

## Why validated families matter

There is a difference between:

- "the code recognizes this family"
- "the code can launch this family"
- "the code has been validated end-to-end"

The documentation should always keep those categories separate. That is how we
avoid overclaiming support.

## Practical workflow for contributors

When changing wrapper internals:

1. run the self-check test
2. run the smoke test
3. run the cross-family validator
4. if you touched observation logic, run the observation regression test too

That sequence should be treated as part of development, not as an afterthought.
