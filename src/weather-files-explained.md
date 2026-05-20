# DSSAT Weather Files Explained

Weather is one of the most important DSSAT inputs because it drives the crop
every single day.

If the weather data are poor, everything downstream can look coherent and still
be wrong.

## What a DSSAT weather file does

A weather file provides the daily atmospheric conditions the crop experiences.

Typical daily drivers include:

- solar radiation
- maximum temperature
- minimum temperature
- rainfall

Depending on workflow, other variables may also be relevant or derived.

## Why weather matters so much

Weather influences almost every major process:

- emergence
- phenology
- photosynthesis potential
- evapotranspiration
- soil water balance
- stress timing

Even a small issue such as missing rainfall on the wrong date can shift water
stress and therefore biomass or flowering patterns.

## The basic structure of a weather file

A DSSAT weather file typically contains:

- station metadata
- geographic information
- a header defining daily columns
- one row per day

The station metadata usually help DSSAT understand:

- where the site is
- what climate station identifier to use
- how to compute daylength and seasonal context

The daily rows provide the actual time series.

## Common weather variables

The exact names can vary, but beginners should understand the common concepts.

### Solar radiation

This represents incoming shortwave energy available to drive canopy
interception and photosynthesis-related processes.

If radiation is too low or too high, biomass can be strongly biased.

### Minimum and maximum temperature

These influence:

- development rate
- heat stress or cold stress
- evapotranspiration
- potential growth

Temperature errors often show up first as phenology errors.

### Rainfall

Rainfall feeds the soil water balance.

If rainfall timing is wrong, the model may create water stress at the wrong
stage even if seasonal rainfall totals look reasonable.

## Why location metadata matter

Latitude and longitude are not decoration.

They influence:

- daylength
- seasonal solar geometry
- sometimes weather interpretation choices

For crops with photoperiod sensitivity, such as hemp, location metadata can be
especially important.

## Common data-quality problems

Beginner workflows often run into:

- missing dates
- duplicate dates
- impossible temperatures
- negative radiation
- unit confusion
- station metadata copied from the wrong location

Any of these can damage a simulation quietly.

## How weather files relate to experiment files

The experiment file typically references a weather station identifier rather than
embedding the daily weather table directly.

That means debugging weather requires checking both:

- the weather file itself
- the station linkage used by the experiment file

## Practical checks before you trust a weather file

Before running calibration, check:

1. Does the file cover the full simulation period?
2. Are all dates present?
3. Do units match the expected DSSAT convention for that variable?
4. Do min and max temperatures look physically plausible?
5. Does rainfall timing look believable?
6. Does the station metadata match the intended site?

## Beginner takeaway

When a run looks biologically wrong, do not assume the genotype is the problem.

Weather is often the first major input to inspect because it drives development
and growth every day of the season.
