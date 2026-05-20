# How to Build Soil Profiles for DSSAT

This chapter focuses on workflow.

The goal is to help a beginner move from field or laboratory information to a
soil profile that DSSAT can use responsibly.

## Start with honesty about where the data came from

A soil profile can be:

- directly measured in the field and laboratory
- partly measured and partly estimated
- borrowed from a similar nearby site
- assembled from published or mapped information

These are not equally strong situations.

Always document which one applies.

## A practical build workflow

### Step 1: define the site and profile depth

Record:

- site identifier
- coordinates if available
- effective soil depth
- any known restrictive layer

If you do not know how deep roots can realistically explore, note that as an
uncertainty rather than hiding it.

### Step 2: define soil layers

Choose layers that reflect the real profile as well as the resolution supported
by your data.

Typical layer information includes:

- top and bottom depth
- texture or textural class
- bulk density
- hydraulic information
- carbon or organic matter

### Step 3: gather hydraulic information

DSSAT needs a reasonable description of water behavior.

This often includes values related to:

- lower water limit
- drained upper limit
- saturation

If these were not measured directly, document how they were estimated.

Pedotransfer functions or standard tables may be used, but they should not be
treated as exact field truth.

### Step 4: define initial conditions

A soil profile alone is not the whole story.

You also need to think about the starting condition at planting, such as:

- initial soil water
- initial mineral nitrogen
- residue or previous-crop effects if relevant

These may be represented partly in the experiment file rather than only in the
main soil profile.

### Step 5: check consistency

Common consistency questions include:

- Are layer depths continuous?
- Do hydraulic values increase or decrease in physically impossible ways?
- Is saturation greater than drained upper limit?
- Is drained upper limit greater than lower limit?
- Is bulk density plausible for the texture?

These checks catch many silent data problems.

### Step 6: write the DSSAT soil file

Once the profile is internally consistent, write it into the DSSAT format with:

- correct site identifier
- correct layer boundaries
- correct layer variables

### Step 7: sanity test in a simulation

Before using the profile for serious calibration, run a simple test and inspect:

- early growth
- stress behavior
- whether the crop appears unrealistically drought-limited or unstressed

If stress patterns look impossible, revisit the soil assumptions before changing
genetics.

## When borrowing a profile is acceptable

Sometimes the real site profile is unavailable.

Borrowing a profile may be acceptable if:

- the soil type is genuinely similar
- the climate and management context are not wildly different
- the borrowed profile is clearly labeled as provisional

Borrowed soil should be treated as a starting point, not as a final truth.

## Common calibration trap

One frequent mistake is trying to fix a soil problem by changing cultivar
coefficients.

For example:

- if soil water is too available, biomass may be too high
- if soil water is too restrictive, biomass may be too low

Changing phenology or partitioning coefficients to compensate can make the model
less biologically meaningful.

## Beginner takeaway

Building a DSSAT soil profile is part measurement, part estimation, and part
quality control.

The important thing is not pretending the file is perfect.
The important thing is making every assumption visible and internally
consistent.
