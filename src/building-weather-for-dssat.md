# How to Build Climate Data for DSSAT

This chapter is about workflow rather than theory.

It explains how you go from real weather information to a weather file that
DSSAT can actually use.

## Where weather data usually come from

Common sources include:

- on-site weather stations
- nearby public weather stations
- gridded weather products
- satellite-supported products
- reanalysis products

The best source depends on:

- how close it is to the field
- whether it covers the full date range
- whether it provides the required variables
- whether its quality control is trustworthy

## The core rule: daily completeness matters

DSSAT usually needs a complete daily time series across the simulation period.

That means you should aim for:

- no missing dates
- consistent daily units
- no duplicated rows
- no accidental mixing of stations

Even if a source is scientifically reputable, your assembled file can still be
wrong if the processing pipeline is careless.

## A practical build workflow

### Step 1: define the site and period

Write down:

- station or site identifier
- latitude
- longitude
- elevation if available
- start date
- end date

These become the backbone of the weather file.

### Step 2: collect the daily variables

At minimum, assemble the variables required by your DSSAT workflow, often:

- daily solar radiation
- daily minimum temperature
- daily maximum temperature
- daily rainfall

If your source does not provide one of these directly, document how it was
derived.

### Step 3: standardize units

This is one of the most common failure points.

Before writing the file, make sure each variable is in the convention expected
by the DSSAT weather format you are targeting.

Never assume two data providers use the same units.

### Step 4: fill or flag missing values

If data are missing, decide explicitly whether to:

- gap-fill from another source
- interpolate where scientifically justified
- mark the series as unsuitable

Do not silently leave gaps in a file that is supposed to drive a daily
simulation.

### Step 5: run quality checks

Plot and inspect:

- rainfall through time
- min and max temperature through time
- radiation through time

Also check summary statistics such as:

- hottest day
- coldest day
- wettest day
- total seasonal rainfall

These quick checks often reveal transcription or unit errors immediately.

### Step 6: write the DSSAT weather file

Once the data are clean, write them into the required DSSAT structure with:

- correct station header information
- correct variable names
- one row per day

### Step 7: test with a known experiment

Before using the file in serious calibration, run a simple known experiment and
confirm:

- the simulation period is covered
- DSSAT reads the file
- no weather-related missing-data warnings appear

## When weather must be estimated

Sometimes field experiments do not have perfect station data.

In that case, you may use:

- nearby stations
- merged products
- satellite-supported products
- reanalysis products

The important thing is not to pretend the data are more direct than they are.
Document the source and any transformation clearly.

## A good habit for reproducibility

Keep a separate record of:

- source dataset names
- source URLs or citations
- download date
- unit conversions
- gap-filling rules
- final weather file name used in DSSAT

That record is often more valuable than the final file alone.

## Beginner takeaway

Building weather for DSSAT is not just "put climate in a text file."

It is a careful process of:

- sourcing
- cleaning
- standardizing
- validating
- documenting

That discipline is what makes later calibration and paper reproduction credible.
