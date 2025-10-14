## Master plan

**DSSAT File X master plan**

Welcome to the complete guide for mastering DSSAT File X. This native page uses MkDocs Material components (tabs, callouts, and code blocks) so it renders everywhere without custom HTML.

### Course overview

The lesson plan will guide you through structure, components, and best practices for creating and managing experiment files effectively.

!!! info "At a glance"
    - Duration: 4–6 hours
    - Level: Intermediate
    - Outcome: Mastery of File X

### Learning objectives

- Understand File X structure
- Configure simulation controls
- Design treatment structures
- Validate and troubleshoot

### Lessons

=== "Lesson 1: Introduction"

    #### What is DSSAT File X?

    File X is the experiment details file that defines experimental conditions, treatments, and simulation parameters.

    !!! tip "Key point"
        File X is the bridge between your experimental design and the crop simulation model.

    #### File naming convention

    ```
    INSTI + YEAR + EXNO + CROP + "." + EXT
    Example: UFGA8801.SBX
    - UFGA: Institution/Location Code
    - 88: Year (1988)
    - 01: Experiment Number
    - SB: Crop Code (Soybean)
    - .SBX: File Extension
    ```

    #### File organization

    ```
    *EXP.DETAILS  Experiment identification
    *GENERAL      Simulation timing and control
    *TREATMENTS   Treatment definitions and factor levels
    *CULTIVARS    Variety and genetic coefficients
    *FIELDS       Field conditions and soil references
    *INITIAL CONDITIONS  Starting soil conditions
    *PLANTING DETAILS    Planting information
    *IRRIGATION   Water management schedules
    *FERTILIZERS  Nutrient management plans
    *HARVEST DETAILS      Harvest timing and methods
    ```

=== "Lesson 2: File structure"

    #### Section headers and formatting

    ```
    *EXP.DETAILS: UFGA8801.SBX
    @INSI  . . . . . . . .  INSTI
    UFGA
    @LATI  . . . . . . . .  LATITUDE
    29.63
    @LONG  . . . . . . . .  LONGITUDE
    -82.37
    @ELEV  . . . . . . . .  ELEVATION
    40
    ```

    - `*` indicates section headers
    - `@` indicates variable header lines
    - `!` indicates comment lines
    - Blank lines are ignored

    #### Missing data handling

    !!! note "Conventions"
        - `-99` integer missing values
        - `-99.0` real missing values
        - Blank fields: missing or default
        - `NA` not applicable

=== "Lesson 3: Simulation controls"

    ```
    @N OPTIONS    WATER NITROGEN PHOSPHOR MINERAL DISEASES
    Y Y Y N N N
    
    @N METHODS    LIGHT INTERCEPTION EVAPOTRANSPIRATION
    1 1 1
    
    @N MANAGEMENT PLANTING IRRIGATION FERTILIZER RESIDUE HARVEST
    R R F R R
    
    @N OUTPUTS     DAILY SUMMARY GROWTH WATER NITROGEN
    Y Y Y Y Y
    ```

    - Management codes: R=Reported, A=Auto, F=Fixed, N=None
    - Output controls: choose frequency and processes

=== "Lesson 4: Treatments"

    ```
    @N TREATMENTS    6
    @N TRNO R O C TNAME
     1 1 1 1 1 T1: Control
     2 1 1 1 2 T2: High Density
     3 1 1 2 1 T3: Irrigated
     4 1 1 2 2 T4: High Density + Irrigation
     5 2 1 1 1 T5: Fertilized
     6 2 1 2 2 T6: Full Treatment
    ```

    - `TRNO` treatment number, `R` rep, `O` block, `C` rotation, `TNAME` description
    - Level numbers: 0=no data, 1=first entry, 2=second, n=nth

=== "Lesson 5: Advanced topics"

    #### Validation checklist

    - Verify headers (`*`, `@`)
    - Validate data alignment and formats
    - Confirm missing value codes
    - Confirm logical sequences and references

    #### Workflow integration

    ```
    1. Weather preparation (FILEW)
    2. Soil profile setup (FILES)
    3. Cultivar selection (FILEC)
    4. Experiment design (FILEX)
    5. Batch processing
    6. Output analysis
    ```

### Resources

- DSSAT docs: `https://dssat.net`
- DSSAT User Guide Vol. 1: `https://dssat.net/wp-content/uploads/2011/10/DSSAT-vol1.pdf`
- Source code: `https://github.com/DSSAT/dssat-csm-os`


