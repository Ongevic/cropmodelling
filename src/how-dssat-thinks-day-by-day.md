# How DSSAT Thinks Day by Day

This chapter gives a mental model of a daily DSSAT simulation.

If you understand this daily loop, many confusing terms become easier:

- thermal time
- phenology
- biomass accumulation
- partitioning
- stress
- stage transitions

## The daily loop

At a high level, DSSAT repeats a sequence like this:

1. read today's weather
2. update development progress
3. compute growth potential
4. reduce that potential if water, nitrogen, or temperature are limiting
5. partition new biomass among organs
6. update soil and plant states
7. move to the next day

That sounds simple, but each step contains real biology and many assumptions.

## Step 1: read today's weather

The model uses daily weather variables such as:

- solar radiation
- minimum temperature
- maximum temperature
- rainfall

Some models also depend strongly on:

- daylength
- vapor pressure or humidity-related effects
- potential evapotranspiration

These values set the opportunity for photosynthesis, development, and water
balance on that day.

## Step 2: update development progress

The model keeps track of where the crop is in its life cycle.

Examples of broad phases are:

- planting to emergence
- emergence to vegetative growth
- vegetative growth to flowering
- flowering to seed fill or maturation

The model uses rules such as:

- accumulated heat
- daylength sensitivity
- photothermal response
- stress effects

to decide how quickly the crop moves through these phases.

This is called `phenology`.

## Step 3: compute growth potential

Once the model knows the crop's stage and environment for that day, it estimates
how much dry matter the crop could produce under those conditions.

This is influenced by:

- intercepted radiation
- radiation use efficiency
- canopy size or leaf area
- temperature

Potential growth is what the crop could do before water, nitrogen, or other
constraints reduce it.

## Step 4: apply stress reductions

Real crops rarely grow at full potential every day.

The model therefore applies reductions based on stresses such as:

- too little water
- too much or too little temperature
- too little nitrogen
- other family-specific limitations

This is one reason the same cultivar can behave very differently in different
soils or seasons.

## Step 5: partition new biomass

New growth is not sent to one single pool.

The model decides how much of today's new biomass goes to:

- leaves
- stems
- roots
- grain
- flowers
- storage organs

The proportions depend on crop type and development stage.

This is called `partitioning`.

For a fiber-oriented hemp workflow, stem partitioning matters a lot.
For a seed-oriented workflow, reproductive partitioning matters more.

## Step 6: update soil and plant states

The model then updates internal state variables such as:

- total biomass
- leaf area
- root depth
- soil water
- soil nitrogen
- stage counters

These updated states are what the next simulated day starts from.

That is why calibration errors can accumulate through time. A mismatch in early
growth may still matter at flowering or harvest.

## Why outputs look the way they do

When DSSAT writes a time-series file such as `PlantGro.OUT`, it is recording
parts of this daily state.

Variables often represent:

- a stage or stage counter
- an organ biomass pool
- a morphological trait
- a stress-related progression value

If you treat outputs as random column names, the files feel opaque.

If you remember they are snapshots of a daily process loop, they become much
easier to read.

## Why this matters for debugging

Suppose biomass is too low.

That could happen because:

- the crop developed too quickly and ended vegetative growth early
- leaf area stayed too small
- radiation was too low
- water stress reduced growth
- nitrogen stress reduced growth
- partitioning moved too much biomass away from the organ you are studying

The point is that a final error at harvest is often the result of earlier daily
processes, not just one wrong coefficient.

## Why this matters for calibration

Calibration is much easier when you think in process order:

1. get emergence and phenology roughly right
2. get canopy and vegetative growth roughly right
3. get partitioning and harvest components right

Trying to fit final biomass before understanding the timing of stage transitions
usually creates confusion.

## The beginner takeaway

The most important thing to remember is this:

DSSAT is not jumping straight from planting date to final yield.

It is simulating a chain of daily decisions and state updates.

That is the logic behind almost everything else in this book.
