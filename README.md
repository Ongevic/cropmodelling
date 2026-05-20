# cropmodelling

`cropmodelling` is an umbrella repository for learning, organizing, and
building crop-model workflows across models, wrappers, runners, and analysis
systems.

It is not meant to be "the DSSAT-wrapper repo copied into a bigger folder."

Instead, it is meant to grow into a broader crop-modeling environment that can
eventually include:

- multiple crop models
- multiple wrappers and runners
- shared training materials
- reproducible case studies
- ensemble modeling ideas
- a crop-model-agnostic workflow layer

## Current focus

Right now the repository emphasizes:

- beginner-friendly crop-modeling lessons
- DSSAT-oriented teaching materials
- a hemp case-study pathway
- examples of how raw field notes become model-ready inputs

## DSSAT-wrapper in this ecosystem

The DSSAT wrapper work is one module in the broader system, not the identity of
this repository.

It already has its own hosted documentation:

- [DSSAT-wrapper Guide](https://ongevic.github.io/DSSAT-wrapper/index.html)

In this repository, DSSAT-wrapper should be treated as:

- one lesson pathway
- one implementation example
- one bridge into broader crop-model workflow design

## Long-term direction

The long-term direction is broader than DSSAT alone.

This repository is intended to support future work such as:

- APSIM-focused lessons and runners
- STICS-focused lessons and runners
- model comparison workflows
- shared input-preparation pipelines
- ensemble modeling across multiple crop-model families
- a crop-model-agnostic orchestration layer

## What is included here now

- an `mdBook` learning site in `src/`
- a hemp case-study example folder in `examples/hopf-hemp-case-study/`
- public-facing training material for beginners, interns, and contributors

## What is deliberately not bundled

This repo does not bundle:

- private workspace dumps
- large generated outputs from one machine
- personal local datasets
- a DSSAT installation
- public model repositories cloned into the tree just for convenience

Users should bring their own model installations and public example-data clones
when needed.

## Audience

This repository is for:

- complete beginners
- interns learning crop modeling from scratch
- researchers building reproducible workflows
- contributors thinking beyond one model family

## Documentation

The book in `src/` is the main entry point.

It is designed to teach:

- basic crop-modeling concepts
- agronomy concepts relevant to modeling
- how weather, soil, management, and genotype inputs are built
- how a DSSAT hemp case study works
- how this can evolve toward broader model ecosystems
