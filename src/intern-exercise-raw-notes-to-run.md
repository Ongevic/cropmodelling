# End-to-End Intern Exercise: From Raw Notes to a Finished Run

This exercise is designed for a beginner who knows little or nothing about:

- agronomy
- DSSAT
- hemp
- weather files
- soil profiles

The goal is not only to finish a run.

The goal is to learn how to think from raw field information all the way to a
traceable simulation result.

## Exercise goal

By the end of this exercise, the intern should be able to:

1. organize raw field notes into DSSAT input categories
2. identify missing information and explicit assumptions
3. build weather, soil, and management tables in a DSSAT-oriented way
4. connect those inputs to a project file
5. launch a run with the wrapper
6. inspect the outputs and explain what happened at a beginner level

## The starting packet

Imagine the intern receives this packet.

### Field note summary

Site:

- site code: `TRN1`
- latitude: `29.70 N`
- longitude: `82.41 W`
- elevation: `32 m`

Crop:

- crop: industrial hemp
- cultivar: `IH Williams`
- objective: evaluate stem and total biomass under moderate nitrogen

Management:

- planting date: `2022-05-12`
- population: `60 plants m-2`
- row spacing: `0.76 m`
- planting depth: `2.5 cm`
- nitrogen applied:
  - `60 kg N ha-1` on planting day
  - `120 kg N ha-1` on `2022-06-10`
- irrigation applied:
  - `20 mm` on `2022-05-14`
  - `25 mm` on `2022-06-01`

Observation dates:

- `2022-06-20`
- `2022-07-05`
- `2022-07-22`
- `2022-08-15`

Soil notes:

- sandy loam surface
- sandy clay loam subsoil
- profile depth `120 cm`
- moderate initial moisture

Weather source:

- nearby station export with daily radiation, minimum temperature, maximum temperature, and rainfall

## Part 1: organize the packet

### Task 1

Create a four-part note with headings:

- weather
- soil
- management
- genotype

### Expected result

The intern should place:

- station coordinates and daily weather under `weather`
- texture, depth, and water status clues under `soil`
- planting, fertilizer, irrigation, and observation dates under `management`
- cultivar name under `genotype`

### Why this matters

This is the first step in learning to think like a modeler rather than like a
reader of mixed field notes.

## Part 2: build a weather preparation sheet

### Task 2

Create a table with columns:

- `Date`
- `SRAD`
- `TMIN`
- `TMAX`
- `RAIN`

Populate it from the station export and check:

1. no missing dates
2. no duplicate dates
3. `TMAX >= TMIN`
4. rainfall units are daily totals
5. radiation units are consistent

### Deliverable

A cleaned daily weather table plus a one-paragraph note describing:

- source of data
- date coverage
- any corrections made

### Common beginner trap

Do not jump straight into a DSSAT weather file before doing the quality checks.

## Part 3: build a soil preparation sheet

### Task 3

Turn the soil notes into a layered table with at least five layers down to
`120 cm`.

Suggested columns:

- `Layer bottom`
- `Texture`
- `Bulk density`
- `LL`
- `DUL`
- `SAT`
- `Organic C`

### Deliverable

A provisional soil profile table plus a note that states clearly which values
were:

- measured
- estimated
- borrowed from standard references or nearby profiles

### Common beginner trap

Do not pretend estimated hydraulic values are measured truths.

## Part 4: build a management preparation sheet

### Task 4

Create separate tables for:

- planting
- fertilizer
- irrigation
- harvest or observation schedule

### Deliverable

A management packet that could later be encoded in an experiment file.

### Common beginner trap

Do not mix destructive biomass harvest dates with routine standing observations
without labeling the difference clearly.

## Part 5: document assumptions

### Task 5

Write a short list of assumptions such as:

- initial soil moisture estimated from field note "moderately moist"
- weather station assumed representative of the field
- cultivar name mapped to the intended DSSAT cultivar entry

### Deliverable

A plain-language assumptions log.

### Why this matters

Good model work is not about hiding uncertainty. It is about making uncertainty
visible and manageable.

## Part 6: prepare the run context

For the first execution exercise, the intern does not need to hand-author every
DSSAT file from scratch.

Instead, the intern should work from a known project template and inspect how
its file structure maps onto the prepared notes.

### Task 6

Open a known hemp project file and identify:

- weather linkage
- soil linkage
- planting section
- fertilizer section
- cultivar section
- simulation controls

### Deliverable

A short annotation note explaining where each of those pieces lives.

### Why this step is important

This builds the bridge between the preparation sheets and the real DSSAT file
ecosystem.

## Part 7: launch a first run

Once the intern has a valid project file and a working DSSAT installation, they
can launch a test run with the wrapper.

### Example run pattern

```r
source("C:/path/to/DSSAT-wrapper/R/DSSAT_omniwrapper.R")

result <- DSSAT_omniwrapper(
  model_options = list(
    DSSAT_path = "C:/path/to/DSSAT48",
    DSSAT_exe = "DSCSM048.EXE",
    project_file = "C:/path/to/project/Hemp/TRN1.HMX",
    suppress_output = TRUE
  ),
  situation = "TRN1_1",
  var = "CWAD"
)
```

### Task 7

Run the project and record:

- whether the wrapper returned without error
- how many rows were in the simulation output
- which variables were available
- the first and last simulated dates

### Deliverable

A short run note summarizing the simulation status.

## Part 8: perform a first interpretation

### Task 8

Look at the simulation output and answer:

1. Did the crop simulate through the intended season?
2. Is the requested biomass variable present?
3. Does the output look like a daily time series?
4. Does the timing appear plausible relative to planting and harvest dates?

### Deliverable

A one-page beginner interpretation note.

### Example interpretation language

Good:

- "The run completed and produced a daily biomass series through the expected season."
- "I still need to verify whether flowering timing and biomass magnitude are realistic."

Not good:

- "The model is correct because it ran."

## Part 9: optional observation comparison

If observation files are available, the intern can take one more step and read
them through the wrapper:

```r
obs <- DSSAT_omni_read_obs(
  model_options = list(
    DSSAT_path = "C:/path/to/DSSAT48",
    DSSAT_exe = "DSCSM048.EXE",
    project_file = "C:/path/to/project/Hemp/TRN1.HMX"
  ),
  situation = "TRN1_1",
  read_end_season = TRUE
)
```

### Task 9

Check whether observation data were found and whether their dates overlap with
the simulated series.

### Deliverable

A note answering:

- Were observations present?
- Were they in-season, end-season, or both?
- Are the dates aligned enough for later plotting or metrics?

## What a successful exercise submission should contain

A strong intern submission should include:

1. an organized raw-notes summary
2. a cleaned weather table
3. a layered soil table
4. a management table set
5. an assumptions log
6. a project-file annotation note
7. a run summary
8. a first interpretation note

## What this exercise is really teaching

This is not just a software exercise.

It teaches the intern how to move across four ways of thinking:

- field observation
- structured data preparation
- simulation setup
- scientific interpretation

That transition is the heart of practical crop-model work.
