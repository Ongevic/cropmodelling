# DSSAT in This Ecosystem

This chapter explains how DSSAT fits inside the broader `cropmodelling`
repository.

## DSSAT is one model ecosystem, not the whole repo

DSSAT is currently the most developed pathway in this project because:

- it is mature
- it has rich file structures
- it has real example data
- it has already been used in the hemp case-study work

But DSSAT is still one ecosystem among several that this repository aims to
support over time.

## Where the wrapper belongs

The DSSAT-wrapper work belongs in the project as:

- one implementation module
- one teaching pathway
- one reproducibility layer

It should not define the identity of the whole repository.

## Why the hosted wrapper site matters

The wrapper already has its own hosted documentation:

- [DSSAT-wrapper Guide](https://ongevic.github.io/DSSAT-wrapper/index.html)

That means this repository does not need to duplicate every wrapper-level detail
as if it were the only story.

Instead, this repository can:

- explain why the wrapper matters
- teach the beginner concepts around it
- link out to the dedicated wrapper site when deep DSSAT-wrapper detail is needed

## What DSSAT currently contributes here

DSSAT currently provides:

- the clearest end-to-end lesson path
- a rich example of weather, soil, management, and genotype interaction
- a hemp adaptation and paper-reproduction case study
- a concrete example of why wrappers and validation matter

## What comes later

As the project grows, the same pattern can be used for other ecosystems:

- APSIM section
- STICS section
- shared comparison sections

The important idea is that each model can be both:

- its own ecosystem
- part of a broader shared crop-modeling framework
