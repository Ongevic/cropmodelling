# Hopf Hemp Case Study

This folder contains a cleaned example workflow for reproducing and analyzing
the hemp case study associated with Hopf et al. (2025).

## What is included

- `hopf_reproduction.R`
- `hopf_harvest_parser.R`
- `hopf_protocol_audit.R`
- `hopf_subset_forensics.R`
- `build_hopf_figures.R`

These scripts are examples of a paper-reproduction workflow built on top of the
wrapper.

## What is not included

This folder does not bundle:

- a DSSAT installation
- `dssat-csm-data`
- the original paper PDF
- large generated output tables
- private local workspace artifacts

Users should provide their own local DSSAT installation and their own clone or
download of the public `dssat-csm-data` repository.

## Required environment variables

The scripts are designed to work from this folder when the following are
available:

- `DSSAT_PATH`
  Path to the DSSAT installation, for example `C:/DSSAT48`
- `DSSAT_CSM_DATA`
  Path to a local `dssat-csm-data` checkout
- `DSSAT_WRAPPER_REPO`
  Optional override for the wrapper repository root

If `DSSAT_WRAPPER_REPO` is not set, the scripts try to resolve the repository
root from their location in this repo.

## Typical run order

1. `hopf_reproduction.R`
2. `hopf_harvest_parser.R`
3. `hopf_protocol_audit.R`
4. `hopf_subset_forensics.R`
5. `build_hopf_figures.R`

## Why this folder exists

The purpose of this example is educational and reproducibility-focused:

- show how a crop-model paper workflow can be scripted
- demonstrate how the wrapper supports external project files and observations
- give contributors a realistic case study beyond simple smoke tests
