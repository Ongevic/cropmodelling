# Hopf Paper Case Study

This chapter explains how the wrapper can be used in a real reproduction task.

The example is the hemp paper:

Hopf et al. (2025), "Adaptation of the process-based CSM-CROPGRO model to
simulate the growth and development of industrial hemp for seed and fiber production."

## Why this case study matters

It is a good teaching example because it combines:

- a real publication
- real observed data files
- real genotype coefficients
- a model family that required install metadata to be consistent
- a workflow that can later inform work in other model frameworks

## The four key experiment files

In the local reproduction workspace, the exact paper experiment files came from
`dssat-csm-data/Hemp`:

- `UFCI2101.HMX`
- `UFCI2201.HMX`
- `UFJA2101.HMX`
- `UFJA2201.HMX`

Together they define the 15 Florida cases listed in the paper's experiment table.

## The matching observation files

Each experiment also had:

- a time-course observation file
- an anthesis or summary observation file

For hemp these appeared as:

- `.HMT`
- `.HMA`

That is exactly the kind of structure the wrapper's observation-reading logic
needs to support if it is going to help with paper reproduction.

## Why the observation-path fix mattered

Originally, the new wrapper could read observations only from the installed DSSAT
crop folder.

That was not enough for this paper workflow, because the exact paper experiment
files and observations lived in an external project directory.

The wrapper was updated so that observation files can be found relative to the
`project_file` directory when needed.

That small technical change is a good example of how real case studies improve
general wrapper design.

## First-pass reproduction logic

The reproduction workflow does this:

1. define the 15 paper cases explicitly
2. run each case through `DSSAT_omniwrapper()`
3. read the matching observations
4. join simulated and observed values on date
5. compute first-pass metrics such as `d` and `RMSE`
6. compare observed and simulated flowering dates

## What the first pass can and cannot claim

It can claim:

- the paper experiments rerun successfully
- the observed and simulated data can be aligned reproducibly
- the resulting performance metrics are strong enough to justify deeper analysis

It should not yet claim:

- that every published metric has been matched exactly
- that every figure in the paper has been rebuilt identically
- that every aggregation choice used by the authors has already been reproduced

That distinction is part of good scientific communication.

## Why this case study belongs in the book

Because it shows the difference between:

- building a wrapper in theory
- building one that survives contact with a real publication workflow

That is the level of evidence that helps a community trust a tool.
