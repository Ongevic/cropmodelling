# Repository Tour

This chapter explains what is in the repository and why each piece exists.

## Top-level structure

The key folders and files are:

- `src/`
  The `mdBook` source files for the learning site.
- `examples/`
  Public-safe example materials and case-study scripts.
- `.github/workflows/`
  GitHub Actions, including documentation deployment.
- `book.toml`
  The `mdBook` configuration.
- `README.md`
  The short project-facing introduction.

## The `src/` folder

This folder is the book.

Hosted documentation should not be treated as decoration. In a project like
this, the documentation is part of the reproducibility layer.

The purpose of the book is to:

- teach beginners how the system fits together
- explain why design decisions were made
- document validation status
- make onboarding easier for future contributors

## The `examples/` folder

This folder is where model-specific case studies can live without defining the
identity of the whole repository.

Right now it contains a hemp-oriented DSSAT case-study example.

Over time it could also contain:

- APSIM examples
- STICS examples
- cross-model comparison examples
- ensemble examples

## Where the wrapper source lives conceptually

The DSSAT-wrapper is part of the ecosystem, but it is not the identity of this
repository.

Its dedicated documentation lives separately here:

- [DSSAT-wrapper Guide](https://ongevic.github.io/DSSAT-wrapper/index.html)

This repository should link to such model-specific modules rather than
pretending they are the whole system.

## What is deliberately outside the repo

The umbrella cropmodelling repo is not the same thing as a full local runtime
workspace.

A local research workspace may also contain:

- a DSSAT installation such as `C:/path/to/DSSAT48`
- cloned example data such as `dssat-csm-data`
- APSIM installations
- STICS installations
- project-specific reproduction scripts
- temporary outputs and figures

The goal of this repo is to teach how to work with those pieces without
assuming that everyone has the same machine layout or the same preferred model.
