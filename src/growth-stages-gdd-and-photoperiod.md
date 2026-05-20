# Growth Stages, GDD, and Photoperiod

This chapter introduces several terms that confuse beginners very quickly:

- growth stage
- phenology
- GDD
- thermal time
- photoperiod
- photothermal day

They are closely related, but they are not the same thing.

## Growth stages

A crop does not behave the same way from planting to harvest.

It passes through recognizable developmental phases such as:

- sowing or planting
- emergence
- vegetative growth
- flowering
- seed fill
- maturity

These phases are called `growth stages` or `phenological stages`.

The exact names vary by crop and model family, but the basic idea is always the
same: stage affects what the plant can do and how the model treats it.

## Phenology

`Phenology` is the study or simulation of when these developmental stages occur.

In crop models, phenology is critical because it controls:

- how long the crop remains vegetative
- when it begins reproduction
- when partitioning rules change
- when final harvest components can accumulate

If phenology is wrong, many later variables can also be wrong even if the rest
of the model is reasonable.

## What is GDD?

`GDD` means `Growing Degree Days`.

It is a simple way to express how much useful warmth a crop experienced.

The broad idea is:

- crops develop faster on warmer days
- but only within a biologically meaningful range

A simple textbook version looks like:

`GDD = mean daily temperature - base temperature`

with rules to prevent unrealistic values when temperatures are too low or too
high.

This is only the basic concept. Real crop models may use more detailed thermal
response functions than this one-line formula.

## Why GDD matters

GDD helps explain why calendar days alone are not enough.

Two crops planted on the same date can accumulate very different development if
one season is cool and the other is warm.

That affects:

- emergence timing
- flowering timing
- maturity timing

## Thermal time versus GDD

People sometimes use these terms loosely, but `thermal time` is the broader
concept.

`GDD` is one common way of expressing thermal time.

In practice, when modelers say:

- "the crop needs more thermal time to flower"

they often mean the model needs more accumulated temperature-driven progress
before stage transition.

## Photoperiod

`Photoperiod` means daylength.

Some crops are sensitive to how long the day is, not only how warm it is.

For those crops, development may slow or accelerate depending on whether the day
is longer or shorter than the crop prefers.

This matters strongly in hemp because flowering behavior is often tied to
daylength response.

## Photothermal day

Some model formulations combine temperature and photoperiod into a single idea,
often called a `photothermal day` or something similar.

The exact equation depends on the model family, but the concept is:

- development is not driven by temperature alone
- temperature and daylength together shape progress toward flowering or later stages

This is especially important when comparing:

- different planting dates
- different latitudes
- different cultivars with different photoperiod sensitivity

## Why stage variables matter in outputs

When you see variables related to stages in DSSAT output, they are often trying
to summarize this development logic.

Even if you are mainly interested in biomass, stage-related outputs help answer:

- Did the model flower too early?
- Did it remain vegetative too long?
- Did reproductive development begin at the right time?

Those questions are often the key to understanding yield or biomass mismatches.

## A practical way to think about calibration

For a beginner, a useful rule is:

- first fix timing
- then fix size
- then fix partitioning

In other words:

1. get stage transitions roughly right
2. get total growth roughly right
3. get organ-specific biomass roughly right

Trying to fit stem or seed biomass while flowering timing is still wrong often
leads to misleading parameter changes.

## Common beginner confusion

### "The model has the right harvest date, so phenology must be fine"

Not necessarily.

It may still have the wrong:

- emergence date
- flowering date
- duration of vegetative growth
- duration of reproductive growth

### "More GDD always means better growth"

Not necessarily.

Too much heat, stress, or an unfavorable daylength response can still reduce
performance even if thermal accumulation is high.

### "Photoperiod only matters at flowering"

Often flowering is the most visible effect, but photoperiod sensitivity can
influence the whole developmental pathway around the transition to reproduction.

## Beginner takeaway

If you remember only one thing from this chapter, let it be this:

calendar date is not enough.

Crop models care deeply about how temperature and daylength accumulate through
time, because that is how they decide when the crop changes from one stage to
the next.
