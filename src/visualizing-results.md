# Visualizing Results

Running a model is only the first half of the job.

The second half is making the results interpretable.

## Why visualization matters in crop-model workflows

Good plots help you answer different kinds of questions:

- Did the model run at all?
- Are the observed and simulated values on the same scale?
- Is the mismatch systematic or occasional?
- Which treatments are hardest for the model?
- Are errors coming from timing, magnitude, or both?

Without plots, calibration can become blind.

## What to visualize first

For a beginner, the most useful first figures are:

1. observed vs simulated scatter plots
2. time-series overlays
3. flowering or stage-date comparisons
4. summary metric panels

That sequence moves from broad agreement to case-specific diagnosis.

## A practical pattern

For real projects, keep figure generation separate from the main run logic.

That separation makes it easier to:

- rerun figures without rerunning every simulation
- audit the data feeding each figure
- debug joins and aggregation choices

## The Hopf case-study figures

In the local reproduction workspace, a focused figure script was built around
the reproduction outputs rather than around older dashboard-specific code.

The idea is general:

- use the wrapper to generate clean outputs
- save joined time-series and metric tables
- build plots from those saved outputs

That pattern is more portable than a plotting script that is tightly coupled to
one personal machine layout.

## Common figure types in this project

### Observed vs simulated panels

Best for:

- quick agreement checks
- identifying bias
- comparing multiple variables side by side

### Time-series overlays

Best for:

- checking whether timing is right
- checking growth trajectory shape
- seeing whether the model diverges early or late

### Stage-date alignment plots

Best for:

- phenology validation
- identifying treatment-specific timing issues

### Metric summaries

Best for:

- reporting
- comparing variables at a glance
- identifying which variables need more work

## Advice for contributors

Treat plotting code as part of the reproducibility workflow, not as a cosmetic extra.

That means:

- keep inputs explicit
- save derived tables
- use consistent naming
- avoid hard-coded personal directories
- document what each figure is meant to prove
