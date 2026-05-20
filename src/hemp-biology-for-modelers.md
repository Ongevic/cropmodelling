# Hemp Biology for Modelers

This chapter is not a full botany text.

Its purpose is narrower:

to give enough hemp biology that a new modeler understands what the model is
trying to reproduce.

## Why hemp is a special case in modeling

Hemp is not just "another generic broadleaf crop."

It can be grown for very different purposes:

- fiber
- seed or grain
- dual-purpose production
- sometimes floral biomass in other contexts

Those goals matter because they change what traits we care about:

- stem growth
- partitioning
- flowering timing
- plant height
- branching
- grain production

## Major growth phases in practical terms

For a beginner, it helps to think about hemp growth in broad stages:

1. germination and emergence
2. vegetative growth
3. floral initiation and flowering
4. seed set or reproductive filling
5. maturation or harvest stage

During vegetative growth, the plant is mostly building structure:

- leaves
- stems
- roots

Later, more of the plant's energy may shift toward reproductive structures and
seed production, depending on genotype and management.

## Why flowering timing matters so much

Hemp is often strongly sensitive to photoperiod, meaning daylength influences
when it transitions toward reproductive development.

This matters because flowering timing controls:

- how long the crop stays vegetative
- how much biomass can accumulate before reproduction
- how tall the crop becomes
- how much stem biomass is available for fiber
- how much time remains for seed filling

If a hemp model flowers too early, it may produce too little total biomass.
If it flowers too late, it may overgrow or miss the observed reproductive
pattern.

## Fiber versus seed logic

For fiber-oriented production, modelers often care especially about:

- stem dry weight
- plant height
- canopy development
- timing of flowering

For seed-oriented production, modelers may care more about:

- flowering and reproductive timing
- grain or seed biomass
- partitioning to reproductive organs
- maturation timing

The same crop model may be used in both contexts, but the most important target
variables and the most sensitive parameters can differ.

## Cultivar differences

Not all hemp cultivars respond the same way.

Differences may include:

- photoperiod sensitivity
- maturity type
- growth habit
- total biomass potential
- partitioning pattern
- height and canopy structure

That is why genotype coefficients matter so much in hemp adaptation work.

## Why latitude and planting date matter

Because daylength changes with latitude and season, planting date can change
hemp behavior dramatically.

Two crops planted in different places or on different dates may experience:

- different daylength trajectories
- different temperature accumulation
- different rainfall environments

That means a hemp model must usually represent both:

- temperature-driven development
- photoperiod-driven development

## What an intern should watch first

When inspecting hemp simulations, the most useful first questions are often:

- Is the crop flowering at roughly the right time?
- Is stem biomass tracking observations?
- Is total biomass trajectory plausible?
- Is plant height developing at a reasonable pace?
- Are differences among cultivars visible?

Those are often more informative early on than focusing immediately on every
single output column.

## Why hemp adaptation in DSSAT matters

When a crop is new to a modeling platform, the task is not only "make it run."

The task is to decide whether the platform's structure can represent:

- the right developmental signals
- the right partitioning behavior
- the right observed responses to environment and management

That is why the hemp case study in this repository is so valuable. It tests the
wrapper against a real adaptation problem rather than only against legacy crops.
