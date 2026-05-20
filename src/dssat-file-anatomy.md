# DSSAT File Anatomy

One of the biggest beginner hurdles in DSSAT is that everything seems to be
"just files." This chapter explains what those files do.

## The most important idea

The experiment file is the conductor.

It does not contain every piece of data itself. Instead, it points to:

- the crop setup
- the field and soil context
- the planting and fertilizer treatments
- the weather station
- the cultivar and ecotype identifiers

If you understand the experiment file, DSSAT becomes much easier to reason about.

## Experiment files

Examples:

- `*.WHX` for wheat examples
- `*.MZX` for maize examples
- `*.HMX` for hemp examples

An experiment file usually contains sections like:

- `*TREATMENTS`
- `*CULTIVARS`
- `*FIELDS`
- `*SOIL ANALYSIS`
- `*INITIAL CONDITIONS`
- `*PLANTING DETAILS`
- `*FERTILIZERS`
- `*HARVEST DETAILS`
- `*SIMULATION CONTROLS`

When you read an experiment file, think of it as a structured recipe rather than
a flat text file.

## Companion observation files

Two observation file types matter often:

- `*.T`
  Time-course observations.
- `*.A`
  End-of-season or summary observations.

In hemp case studies you may see:

- `.HMT`
- `.HMA`

Those are the crop-specific versions of the same idea.

## Genotype files

These usually live in the DSSAT `Genotype` folder.

Common file types:

- `.CUL`
  Cultivar coefficients.
- `.ECO`
  Ecotype coefficients.
- `.SPE`
  Species-level definitions.

Important caution:

Not all crop/model families use the exact same genotype structure. Some have no
`.ECO` file at all. That is one reason a truly universal wrapper cannot assume a
single fixed genotype pattern.

## Soil files

These define the physical and hydraulic context of the field.

Typical concerns include:

- layer depth
- bulk density
- lower and upper water limits
- saturation
- organic carbon
- initial water and nitrogen conditions

If biomass or stress behavior looks unrealistic, soil inputs are often one of
the first places to inspect.

## Weather files

Weather files are daily drivers. If the weather is wrong, the simulation can be
beautifully reproducible and still biologically wrong.

Typical variables include:

- solar radiation
- minimum temperature
- maximum temperature
- rainfall

Weather files should be checked for:

- missing dates
- unrealistic spikes
- unit consistency
- correct station linkage from the experiment file

## Metadata files in the DSSAT install

Two install-level files are especially important for this repo:

### `SIMULATION.CDE`

This provides model and crop metadata.

### `DSSATPRO.V48`

This maps crop codes to installed folders and default modules.

These files are crucial for the registry-driven wrapper because they let us
infer model context instead of forcing the user to hard-code everything.

## Outputs you will see often

### `PlantGro.OUT`

The main time-series output file for growth variables.

### `Evaluate.OUT`

Often provides end-of-run summary metrics and stage-related information.

### Other output files

Some families also write additional outputs or family-specific variables.

That is why the omniwrapper uses:

- a generic output reader
- variable alias logic
- fallback parsing where necessary

## Practical reading order

When debugging a run, a good order is:

1. experiment file
2. companion observation files
3. genotype files
4. install metadata
5. output files

That order helps you understand not only what happened, but why the wrapper
made the choices it made.
