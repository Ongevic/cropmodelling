# What Is Crop Modeling?

This chapter is written for a reader who may be strong in coding but new to
agronomy, or strong in agronomy but new to modeling.

The goal is simple:

understand what a crop model is trying to represent before worrying about file
formats, wrapper functions, or calibration metrics.

## A field is a process, not just an outcome

When a farmer or researcher looks at a field, they usually care about outcomes:

- emergence
- flowering
- yield
- fiber production
- grain production
- biomass

A crop model tries to represent the processes that create those outcomes.

That means the model asks questions like:

- How warm was each day?
- How long was the day?
- How much water could roots access?
- How much nitrogen was available?
- How fast could leaves expand?
- When did the plant switch from vegetative growth to reproductive growth?

The model does not "know" the plant the way a human observer does. It knows
only the processes and parameters encoded in its equations and inputs.

## What a crop model does each day

Most process-based crop models operate on a daily time step.

For each simulated day, the model takes inputs such as:

- weather
- soil water and soil nitrogen status
- crop development stage
- management events such as irrigation or fertilizer

Then it updates internal state variables such as:

- days since planting
- thermal time or photothermal time
- leaf area
- root growth
- dry matter production
- biomass partitioning to leaves, stems, roots, seed, or storage organs

The next day starts from the updated state of the previous day.

This is why one bad input or one poor parameter choice can affect the whole
season instead of only one date.

## Why process-based models are useful

Process-based models are useful because they let us reason beyond a single
observed season.

If the model captures the main processes reasonably well, we can ask:

- What if planting date changes?
- What if rainfall changes?
- What if the crop is grown at a different latitude?
- What if soil depth is shallower?
- What if cultivar photoperiod sensitivity is different?

That is why crop models are used in:

- agronomy
- breeding
- climate adaptation studies
- irrigation and fertilizer analysis
- systems research

## What a model is not

A crop model is not:

- a perfect copy of reality
- a replacement for field data
- an excuse to ignore measurement quality
- automatically transferable from one crop or location to another

A model is a disciplined simplification.

The useful question is not "Is the model true?"

The useful questions are:

- Is it transparent?
- Is it reproducible?
- Is it good enough for the question being asked?
- Do the errors make biological sense?

## The three big ingredients of crop-model quality

The quality of a simulation usually depends on three broad things:

1. input quality
2. parameter quality
3. model structure

### Input quality

If weather, soil, or management inputs are wrong, the model can fail even if
the equations are sensible.

### Parameter quality

If cultivar or ecotype coefficients are unrealistic, the crop may flower too
early, accumulate too little biomass, or partition biomass incorrectly.

### Model structure

Even with good data and reasonable parameters, a model can still struggle if
its underlying assumptions are not suitable for the crop or environment.

This matters a lot in new-crop work such as hemp adaptation.

## Why beginners often feel lost

Beginners often see file names first and biology second.

They encounter:

- `.WTH`
- `.SOL`
- `.CUL`
- `.ECO`
- `PlantGro.OUT`
- `GSTD`
- `CWAD`

and it feels like a codebase without a story.

The story is:

- weather drives daily opportunity and stress
- soil controls what roots can access
- management defines what the farmer did
- genetics defines how this crop behaves
- the model combines them to simulate growth through time

Once that story is clear, the file system starts to make sense.

## Where DSSAT fits in

DSSAT is a crop modeling platform that provides:

- crop-specific model engines
- standard file structures
- a simulation executable
- output conventions

This repository is not DSSAT itself.

This repository adds a wrapper around DSSAT so that the model can be used more
cleanly from R for:

- reproducible runs
- validation
- calibration
- paper reproduction
- multi-family experimentation

## How to read the rest of this book

If this chapter is your starting point, the safest next order is:

1. [How DSSAT Thinks Day by Day](how-dssat-thinks-day-by-day.md)
2. [Hemp Biology for Modelers](hemp-biology-for-modelers.md)
3. [Growth Stages, GDD, and Photoperiod](growth-stages-gdd-and-photoperiod.md)
4. [DSSAT File Anatomy](dssat-file-anatomy.md)

That path gives you the biology and process logic before you dive into files and
code.
