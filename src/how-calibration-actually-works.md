# How Calibration Actually Works

Calibration is one of the most misunderstood parts of crop modeling.

Many beginners think calibration means:

"change numbers until the curve looks good."

That is not a reliable modeling strategy.

Calibration should be structured, biologically informed, and documented.

## What calibration is

Calibration means adjusting uncertain model parameters so that simulated behavior
agrees better with observed behavior for a defined dataset and question.

In crop-model work, common calibration targets include:

- emergence date
- flowering date
- maturity date
- biomass trajectory
- stem biomass
- grain yield
- leaf area

## What calibration is not

Calibration is not:

- hiding a bad weather file
- compensating for a wrong soil profile by changing genetics
- forcing every variable to match perfectly
- proof that the model is universally correct

A good calibration improves fit while preserving biological meaning.

## A safer calibration order

For many projects, especially beginner projects, the safest order is:

1. confirm the run and inputs are correct
2. calibrate timing and stage transitions
3. calibrate overall biomass trajectory
4. calibrate organ partitioning
5. evaluate on cases not used for adjustment when possible

This order follows process logic rather than aesthetic curve fitting.

## Why timing usually comes first

If flowering timing is wrong, many later outputs can be wrong for the wrong
reason.

For example:

- the crop may stop vegetative growth too early
- stem biomass may be too low simply because the crop transitioned too soon
- seed filling may begin at the wrong time

That is why phenology often deserves attention before final biomass.

## Why input checking comes before parameter changes

Before changing cultivar or ecotype parameters, confirm:

- weather is correct
- soil is plausible
- management matches the experiment
- observations are being read correctly
- the correct model family and module are actually running

Otherwise, you may calibrate around an avoidable input error.

## Objective functions

Calibration needs a way to judge whether one parameter set is better than
another.

Common criteria include:

- RMSE
- agreement indices such as Willmott's `d`
- bias
- visual fit of time series

No single metric tells the whole story, so it is often best to inspect both
numbers and plots.

## Multi-variable calibration

Real projects often fit more than one variable at once.

For hemp, this may include:

- flowering time
- total aboveground biomass
- stem biomass
- plant height

This creates tradeoffs. A parameter change that improves one variable may worsen
another.

That is why calibration should be guided by process understanding, not only by
one summary score.

## Validation after calibration

Calibration is stronger when you can test the calibrated model on:

- another season
- another site
- another treatment set

If the fit is good only on the exact data used for tuning, the model may be
overfit.

## Beginner takeaway

Calibration is best thought of as a scientific workflow:

- check inputs
- define targets
- adjust plausible parameters
- evaluate carefully
- document everything

That mindset is much more valuable than chasing a single perfect metric.
