# Model Ecosystem Vision

This chapter explains the strategic direction of the repository.

## The core idea

This repository is not meant to stop at one wrapper around one model.

The broader goal is to support a crop-modeling ecosystem that can work across:

- model families
- crops
- calibration workflows
- data-preparation pipelines
- analysis and visualization layers

## Why this matters

In practice, crop-model work often becomes fragmented:

- one model has one workflow
- another model has a completely different runner
- data preparation is repeated by hand
- comparisons across models become difficult

That fragmentation makes teaching, reuse, and ensemble work harder than it
needs to be.

## The direction we want

Over time, this repository can grow toward a layered system:

1. learning materials
2. input-preparation workflows
3. model-specific wrappers and runners
4. shared evaluation and visualization tools
5. ensemble and comparison workflows
6. a crop-model-agnostic orchestration layer

## What "crop-model agnostic" means here

It does not mean every model is identical.

It means we aim to build shared concepts and workflow layers for things like:

- weather preparation
- soil preparation
- management encoding
- observation handling
- metric calculation
- plotting
- reproducibility checks

while still respecting that each model family has its own structure.

## Why wrappers still matter

Model-agnostic design does not eliminate model-specific wrappers.

Wrappers remain valuable because they provide clean entry points into each
system.

The point is to avoid stopping there.

We want to move from:

- one wrapper per model

to:

- one broader system that can work with several wrappers and models coherently

## Near-term examples

Today, the strongest implemented pathway is DSSAT.

Tomorrow, this repository may also include:

- APSIM-oriented lessons and runner logic
- STICS-oriented lessons and runner logic
- shared case studies expressed across multiple models

## Ensemble modeling

Ensemble modeling matters because no single crop model captures every process or
every uncertainty perfectly.

A stronger long-term system should eventually support:

- running multiple models on the same scenario
- comparing their outputs systematically
- understanding agreement and disagreement
- building ensemble summaries

That is one of the motivations for keeping the repo broader than one wrapper.
