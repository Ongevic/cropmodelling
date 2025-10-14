## ICASA File X creation guide

This native page mirrors your ICASA guide with MkDocs Material components so it renders perfectly without raw HTML.

### Introduction to ICASA Standards

ICASA standards ensure consistency, interoperability, and proper documentation of agricultural field experiments.

!!! info "Why ICASA matters"
    - Consistency: standardized variable names and formats
    - Interoperability: share data across models and platforms
    - Documentation: complete metadata for reproducibility
    - Quality control: validation and error checking

### Quick start templates

Choose a template to get started quickly or follow the detailed guide below.

=== "Basic crop experiment"
    - Single crop variety
    - Basic weather data
    - Standard soil profile
    - Control treatment

=== "Irrigation study"
    - Multiple irrigation levels
    - Water stress analysis
    - Irrigation scheduling
    - Yield response

=== "Fertilizer trial"
    - Nitrogen rates
    - Application timing
    - Soil analysis
    - Economic analysis

=== "Variety comparison"
    - Multiple cultivars
    - Phenology tracking
    - Yield components
    - Adaptation analysis

### Step-by-step File X creation

#### 1) File setup and basic structure

```
*EXP.DETAILS: UFGA2024 soybean irrigation study
@INSI    . . . . . . . .  INSTITUTION
UFGA
@LONGLATI  . . . . . . .  LONGITUDE LATITUDE
-82.37 29.63
@ELEV  . . . . . . . .  ELEVATION
40
```

!!! note "ICASA naming convention"
    `INSTI + YEAR + EXNO + CROP + "." + EXT` (e.g., `UFGA2401.SBX`)

#### 2) General simulation controls

```
@N GENERAL
NYERS NREPS START SDATE RSEED
1 1 S 2024180 2150

@N OPTIONS
WATER NITROGEN PHOSPHOR MINERAL DISEASES
Y Y N N N

@N METHODS
LIGHT EVAPOTRANSPIRATION PHOTOSYNTHESIS
1 1 1

@N MANAGEMENT
PLANTING IRRIGATION FERTILIZER RESIDUE HARVEST
R R F R R

@N OUTPUTS
DAILY SUMMARY GROWTH WATER NITROGEN
Y Y Y Y Y
```

#### 3) Treatments

```
@N TREATMENTS    4
@N TRNO R O C TNAME
 1 1 1 1 1 Control - No irrigation
 2 1 1 1 2 Low irrigation - 50% ET
 3 1 1 1 3 Medium irrigation - 75% ET
 4 1 1 1 4 High irrigation - 100% ET
```

#### 4) Cultivars

```
@N CULTIVARS
@N CR INGENO CNAME
SB UF000001 McCurdy 84aa
```

#### 5) Fields

```
@N FIELDS
@N ID_FIELD WSTA....  FLSA  FLOB  FLDT  FLDD  FLDS  FLST
UFGA0001 UFGA2024      0     0 DR000  100    0    0
@N  SOIL_ID
UFGA0001
```

#### 6) Initial soil conditions

```
@N INITIAL CONDITIONS
@N PCR ICDAT  ICRT  ICND  ICRN  ICRE  ICWD  ICRTILL
MA 2024180  1000   -99     1     0    15   -99
@N  ICBL  SH2O  SNH4  SNO3
  5 0.25  1.5  8.2
 15 0.27  1.2  7.8
 30 0.30  1.0  6.5
 60 0.32  0.8  5.2
 90 0.35  0.6  4.1
```

#### 7) Planting details

```
@N PLANTING DETAILS
@N PDDATE EDATE  PPOP  PPOE  PLME  PLDS  PLRS  PLRD  PLDP  PLWT  PAGE  PENV  PLPH  SPRL
2024181   -99   12.   -99     S     R    61    -99     5   -99   -99   -99   -99   -99
```

#### 8) Irrigation

```
@N IRRIGATION
@N IMDATE IMTYPE  IMCOD  IIRRI  IMDEP  IMTHR  IMAMT  IMEA  IMEV  IMRO
2024190     IR     1      25    30    0.50    25     1.0   0.0   0.0
2024200     IR     1      25    30    0.50    25     1.0   0.0   0.0
2024210     IR     1      25    30    0.50    25     1.0   0.0   0.0
```

#### 9) Fertilizers

```
@N FERTILIZERS
@N FDATE  FMCD  FACD  FAMN  FAMP  FAMK  FAMC  FAMO  FLIT  FMDEP  FMTHR
2024180 FE005 AP002    30     0     0     0     0     0    10   -99
2024190 FE005 AP002    40     0     0     0     0     0    10   -99
```

#### 10) Harvest details

```
@N HARVEST DETAILS
@N HDATE  HASTC  HCOM  HPC  HBPC HPLW  HPLD  HPWD HARVNO
2024300     M     C    0     0   -99   -99   -99   -99
```

### Validation and testing

!!! tip "Syntax checklist"
    - `*` section headers present
    - `@` variable headers present
    - Proper spacing and alignment
    - Missing values use `-99`
    - Dates in `YYYYDDD` format

!!! warning "Common issues"
    - Treatment levels don't match section entries
    - Invalid date sequences
    - Missing required sections
    - Inconsistent units
    - Broken file references

### Best practices

- Use consistent naming conventions and version control
- Validate before running, check parameter ranges
- Share standard formats and document metadata

### Resources

- ICASA v2.0 Standards: `https://dssat.net/data/standards_v2/`
- ICASA Standards Paper: `https://dssat.net/wp-content/uploads/2014/02/White2013ICASA_V2_standards.pdf`
- Master Variable List: `https://agmip.github.io/ICASA.html`


