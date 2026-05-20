# Worked Case Study: Weather, Soil, and Management Construction

This chapter is a fully worked teaching example.

It is meant to answer the beginner question:

"If someone hands me raw notes from a field experiment, how do I turn them into
the pieces DSSAT actually needs?"

## Important note before we start

This is an instructional case study, not a claim that every number below came
from a published hemp dataset.

The purpose is to show the workflow clearly and realistically:

- what information is needed
- what assumptions are acceptable
- what should be checked before running DSSAT

## The scenario

Imagine an intern receives the following field summary from a hemp trial.

### Raw field notes

Site:

- site name: `North Farm Block A`
- latitude: `29.70 N`
- longitude: `82.41 W`
- elevation: `32 m`

Crop:

- crop: industrial hemp
- cultivar: `IH Williams`
- purpose: fiber-focused biomass evaluation

Management notes:

- planting date: `2022-05-12`
- row spacing: `0.76 m`
- target population: `60 plants m-2`
- planting depth: `2.5 cm`
- nitrogen fertilizer:
  - `60 kg N ha-1` at planting
  - `120 kg N ha-1` on `2022-06-10`
- irrigation:
  - `20 mm` on `2022-05-14`
  - `25 mm` on `2022-06-01`
- biomass harvests:
  - `2022-06-20`
  - `2022-07-05`
  - `2022-07-22`
  - `2022-08-15`

Weather notes:

- automatic station near field
- daily data available for:
  - solar radiation
  - minimum temperature
  - maximum temperature
  - rainfall

Soil notes:

- sandy loam surface
- deeper layer becomes sandy clay loam
- effective rooting depth about `120 cm`
- bulk density measured for three depth ranges
- field team estimated initial soil water as "moderately moist"

At first glance, this is useful, but it is not yet a DSSAT-ready dataset.

The rest of the chapter shows how to transform it.

## Step 1: separate the problem into DSSAT input categories

The raw notes need to be reorganized into four modeling categories:

1. weather
2. soil
3. management
4. genotype

For this chapter we focus on the first three, because those are the pieces most
new interns struggle to construct from raw notes.

## Step 2: build the weather component

### What raw weather information must become

For DSSAT, the weather input must become:

- one station definition
- one daily time series
- consistent daily units
- continuous dates across the simulation period

### Example weather table before DSSAT formatting

Suppose the station export begins like this:

| Date | SolarRad_MJ_m2 | Tmin_C | Tmax_C | Rain_mm |
| --- | ---: | ---: | ---: | ---: |
| 2022-05-12 | 24.1 | 18.7 | 31.2 | 0.0 |
| 2022-05-13 | 22.9 | 19.2 | 30.5 | 4.3 |
| 2022-05-14 | 25.3 | 18.9 | 31.7 | 0.0 |
| 2022-05-15 | 23.8 | 20.1 | 32.0 | 1.2 |

Before writing this into a DSSAT weather file, the intern should ask:

- Are there any missing days?
- Are radiation units really `MJ m-2 day-1`?
- Are rainfall values daily totals?
- Are minimum and maximum temperatures ever swapped?

### Weather quality-control checklist

For this example, the intern should do all of the following:

1. confirm the file has every date from planting through the harvest period
2. confirm there are no duplicate rows
3. confirm `TMAX >= TMIN` for every day
4. inspect whether radiation values are physically plausible
5. inspect whether rainfall totals look reasonable relative to the site and season

### Station metadata

The station definition should also be made explicit:

| Item | Value |
| --- | --- |
| Station code | `NFBA` |
| Latitude | `29.70` |
| Longitude | `-82.41` |
| Elevation | `32` |

Even if the intern does not yet know the exact final `.WTH` syntax by memory,
they should already understand that DSSAT needs both:

- the station description
- the day-by-day weather values

### What matters scientifically

For hemp, weather is not just a background file. It affects:

- thermal accumulation
- photoperiod context through site location
- water balance through rainfall
- biomass opportunity through solar radiation

If flowering or biomass later look wrong, weather is one of the first things to
recheck.

## Step 3: build the soil component

### What the raw soil notes must become

The field notes said:

- sandy loam surface
- deeper layer becomes sandy clay loam
- effective rooting depth about `120 cm`
- bulk density measured for three depth ranges
- initial soil water moderately moist

That description must become a layered soil profile.

### Example layer table before DSSAT formatting

| Layer bottom (cm) | Texture | Bulk density (g cm-3) | Lower limit | Drained upper limit | Saturation | Organic C (%) |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 15 | Sandy loam | 1.42 | 0.08 | 0.20 | 0.39 | 1.20 |
| 30 | Sandy loam | 1.45 | 0.09 | 0.21 | 0.38 | 0.95 |
| 60 | Sandy clay loam | 1.48 | 0.12 | 0.26 | 0.40 | 0.70 |
| 90 | Sandy clay loam | 1.50 | 0.13 | 0.27 | 0.40 | 0.55 |
| 120 | Sandy clay loam | 1.52 | 0.14 | 0.28 | 0.41 | 0.45 |

This is now much closer to DSSAT-ready thinking, because the soil is expressed
layer by layer rather than as a paragraph.

### What the intern should check

Before this becomes a DSSAT `.SOL` entry, the intern should confirm:

1. layer depths are continuous and increasing
2. saturation is greater than drained upper limit
3. drained upper limit is greater than lower limit
4. bulk density values are plausible for the textures listed
5. the effective rooting depth is consistent with the deepest useful layer

### Initial conditions

The field note "moderately moist" is not yet numeric enough for a simulation.

The intern needs to decide whether initial soil water will come from:

- direct measured layer water contents
- estimated fractions between lower limit and drained upper limit
- default assumptions documented in the experiment notes

For teaching purposes, a careful provisional assumption might be:

- upper two layers start near `75%` of plant-available water
- deeper layers start near `65%` of plant-available water

That is not perfect truth. It is an explicit assumption that can later be
replaced with measurements.

### Why this matters scientifically

If the soil profile holds too much water, the crop may look unrealistically
vigorous.

If it holds too little water, the crop may show water stress too early.

That is why soil should be checked before blaming cultivar coefficients.

## Step 4: build the management component

### Raw management notes

From the original notes:

- planting date: `2022-05-12`
- row spacing: `0.76 m`
- target population: `60 plants m-2`
- planting depth: `2.5 cm`
- nitrogen:
  - `60 kg N ha-1` at planting
  - `120 kg N ha-1` on `2022-06-10`
- irrigation:
  - `20 mm` on `2022-05-14`
  - `25 mm` on `2022-06-01`
- biomass harvests:
  - `2022-06-20`
  - `2022-07-05`
  - `2022-07-22`
  - `2022-08-15`

### Management interpretation table

| Concept | DSSAT-relevant interpretation |
| --- | --- |
| Planting date | planting operation date |
| Population | plants per square meter |
| Row spacing | row geometry affecting canopy setup |
| Planting depth | establishment input |
| Nitrogen applications | fertilizer events with date and amount |
| Irrigation applications | irrigation events with date and amount |
| Harvest dates | observation schedule and possibly harvest management |

### A management sheet the intern can draft

#### Planting

| Item | Value |
| --- | --- |
| Planting date | `2022-05-12` |
| Population | `60 plants m-2` |
| Row spacing | `0.76 m` |
| Depth | `2.5 cm` |

#### Fertilizer

| Date | Nutrient | Amount |
| --- | --- | ---: |
| 2022-05-12 | N | 60 kg ha-1 |
| 2022-06-10 | N | 120 kg ha-1 |

#### Irrigation

| Date | Amount |
| --- | ---: |
| 2022-05-14 | 20 mm |
| 2022-06-01 | 25 mm |

#### Harvest observations

| Date | Purpose |
| --- | --- |
| 2022-06-20 | destructive biomass sample |
| 2022-07-05 | destructive biomass sample |
| 2022-07-22 | destructive biomass sample |
| 2022-08-15 | destructive biomass sample |

This gives the intern a structured view before they ever touch DSSAT syntax.

## Step 5: connect the pieces in the experiment logic

At this point the intern has the three major non-genetic building blocks:

- a cleaned daily weather series
- a layered soil profile
- a structured management schedule

The next conceptual step is to connect them in one experiment description:

- the experiment references the weather station
- the field references the soil profile
- the treatment references the planting, fertilizer, irrigation, and harvest logic
- the treatment also references the cultivar choice

That connection is exactly why experiment files are the "conductor" of a DSSAT
run.

## Step 6: define what still remains uncertain

A realistic teaching case should not hide uncertainty.

For this example, open questions might still include:

- Were hydraulic limits measured or estimated?
- Was initial soil water measured or assumed?
- Were plant populations final established counts or target planting rates?
- Did the field station sit exactly at the plot location?

These are not embarrassments. They are part of honest model documentation.

## Step 7: what the intern should save as project artifacts

By the end of this construction phase, a careful intern should have:

1. a cleaned weather table
2. a weather metadata note
3. a layered soil table
4. a management summary table
5. a written list of assumptions and unresolved uncertainties

That package is often more important than the final DSSAT files alone.

## What this case study teaches

This example shows that "building DSSAT inputs" is really a chain of decisions:

- data collection
- unit checking
- structure definition
- assumption logging
- model-oriented formatting

That is the discipline that later makes calibration and paper reproduction
trustworthy.
