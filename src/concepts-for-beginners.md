# Concepts for Beginners

This chapter is for readers who are new to crop modeling, DSSAT, or both.

The goal is not to make you memorize jargon. The goal is to give you a working
mental model so that the rest of the book feels natural instead of cryptic.

## What a crop model is

A crop model is a mathematical description of how a crop grows through time
under a given environment and management system.

In plain language, a crop model tries to answer:

- when does the crop emerge?
- when does it flower?
- how much leaf, stem, root, and grain biomass does it produce?
- how do weather, soil, water, planting date, cultivar, and fertilizer change that outcome?

The model does not "see" the field directly. It only sees the numbers we give
it through input files and parameters.

## What DSSAT is

DSSAT stands for `Decision Support System for Agrotechnology Transfer`.

At a practical level, DSSAT is:

- a collection of crop models
- a file format ecosystem
- an executable that reads experiment files and writes outputs

That last point matters. DSSAT is not just one crop model. It is a family of
models that share a common workflow but differ in their crop-specific logic.

## Why wrappers exist

If DSSAT already runs, why build an R wrapper?

Because DSSAT by itself is not optimized for:

- large batch experimentation from code
- calibration loops
- sensitivity analysis
- automated validation
- reproducible research workflows

A wrapper lets us treat DSSAT as a callable engine inside a broader scientific
workflow.

## The basic logic of a DSSAT run

Every simulation needs four big ingredients:

1. `Weather`
   Daily minimum and maximum temperature, radiation, rainfall, and related variables.
2. `Soil`
   Layer-by-layer information about texture, water holding, bulk density, and initial conditions.
3. `Management`
   Planting date, planting density, irrigation, fertilizer, harvest rules, and other field operations.
4. `Genetics`
   Cultivar, ecotype, and species coefficients that tell the model how this crop behaves.

The experiment file ties those pieces together.

## Why the same crop can still have multiple models

This is one of the most important beginner ideas in this repo.

In DSSAT, "crop" and "model family" are related but not identical.

Examples:

- wheat can be run through `CERES` or `NWHEAT`
- sugarcane has multiple engines such as `CANEGRO`, `CASUPRO`, and `SAMUCA`
- cassava can involve `CSYCA` or `CSCAS`

That is exactly why the `DSSAT_omniwrapper()` exists. A single hard-coded
wrapper is not enough if we want to work across the broader DSSAT ecosystem.

## What calibration means

Calibration means adjusting uncertain model parameters so the model reproduces
observed field behavior more closely.

Typical targets include:

- flowering date
- maturity date
- aboveground biomass
- stem biomass
- grain yield
- leaf area

Calibration is not guessing until the curve looks nice. It should be guided by:

- real observations
- clearly defined objective functions
- a biologically sensible order of parameter adjustment

## A good beginner workflow

If you are starting from zero, this is the safest order:

1. Make the model run without errors.
2. Confirm that the correct crop family and module are being used.
3. Confirm that the experiment file points to the intended weather, soil, and management setup.
4. Confirm that observations are being read correctly.
5. Compare simulated and observed time series.
6. Only then start changing parameters.

That order sounds slow, but it prevents most confusing failures later.

## What success looks like

A successful workflow does not mean "the model matches perfectly."

It means:

- the run is reproducible
- the files and assumptions are transparent
- the comparison with observations is explicit
- improvements can be explained rather than guessed

That is the standard this book and this repo aim for.
