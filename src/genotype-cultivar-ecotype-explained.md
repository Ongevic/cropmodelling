# Genotype, Cultivar, and Ecotype in DSSAT

These terms are easy to confuse, especially for new modelers.

This chapter explains the practical meaning of each one in a DSSAT workflow.

## Why genotype information exists

Weather, soil, and management describe the environment around the crop.

Genotype-related files describe how this crop type responds within that
environment.

Without genotype coefficients, the model would have no crop-specific identity.

## Species, cultivar, and ecotype

In practical DSSAT usage, beginners often encounter three levels:

- species-level information
- cultivar-level information
- ecotype-level information

The exact details vary by family, but the broad idea is:

### Species

Species-level definitions often hold more general crop information shared across
many cultivars.

### Cultivar

Cultivar coefficients distinguish one named or coded cultivar from another.

These may affect:

- development timing
- partitioning
- morphology
- maturity behavior

### Ecotype

Ecotype coefficients often describe broader adaptation patterns related to
environmental response, especially development and phenology.

However, not all DSSAT families use ecotype files in the same way, and some do
not use `.ECO` files at all.

## Why this matters for a general wrapper

The original crop-specific wrapper could assume more about file patterns.

A broader omniwrapper cannot assume:

- every crop has `.ECO`
- every cultivar key is stored under the same column name
- every family matches genotype files the same way

That is why registry logic and family-aware parsing matter in this repository.

## What calibration usually changes

In many workflows, calibration focuses on cultivar or ecotype coefficients
rather than species-level definitions.

Typical goals may include improving:

- flowering date
- maturity timing
- biomass accumulation
- stem or grain partitioning
- leaf-area development

## Common beginner misunderstanding

Beginners sometimes think cultivar coefficients are just labels.

They are not.

They are part of the biological identity of the simulation.

Changing them is changing how the virtual crop behaves.

## Why coefficient changes should be disciplined

Because many coefficients interact, it is easy to create a nice-looking fit that
has poor biological meaning.

A better approach is to ask:

- Which process is wrong?
- Which parameter family controls that process?
- Is the change biologically plausible?

That is much safer than tuning everything at once.

## Beginner takeaway

Genotype files are where the model learns what kind of crop it is simulating.

If weather and soil describe the world around the plant, genotype coefficients
describe the plant's built-in behavior inside that world.
