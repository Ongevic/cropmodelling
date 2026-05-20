# Troubleshooting

This chapter collects common failure modes and how to think through them.

## Problem: the wrapper cannot find a file

Likely causes:

- wrong `DSSAT_path`
- wrong `project_file`
- missing genotype files
- companion observation files not where the wrapper expects them

What to do:

1. run the self-check
2. inspect the reported paths
3. confirm whether the project lives in the DSSAT install or in an external directory

## Problem: the run exits with no `PlantGro.OUT`

Likely causes:

- DSSAT itself rejected the experiment
- the wrong module was used
- a required companion file is missing
- the experiment is valid only with a non-default engine

What to do:

1. inspect `ERROR.OUT`
2. inspect `WARNING.OUT`
3. confirm the intended `module_code`

## Problem: observations are not found

Likely causes:

- the observation files live beside the project file, not in the installed crop folder
- file suffixes differ from what you expected
- the requested experiment name does not match the actual observation filename stem

What to do:

1. check the project directory
2. check the installed crop folder
3. inspect the experiment stem and crop code suffix

## Problem: the variable you requested is missing

Likely causes:

- that family uses a different output variable name
- the variable is not written in that output file
- the run succeeded but your request needs an alias

What to do:

1. inspect the names returned by the simulation object
2. check whether another family-specific variable is the right target
3. extend alias handling if this is a legitimate recurring case

## Problem: the model launches but the biology looks wrong

That is a different class of problem.

Now you should inspect:

- weather linkage
- soil parameters
- planting density
- fertilizer schedule
- cultivar and ecotype choice
- target variable definition

At that stage, the wrapper may be working perfectly and the scientific setup
may still need revision.
