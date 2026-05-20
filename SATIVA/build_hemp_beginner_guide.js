const fs = require("fs");
const path = require("path");
const {
  Document,
  Packer,
  Paragraph,
  TextRun,
  Table,
  TableRow,
  TableCell,
  Header,
  Footer,
  AlignmentType,
  HeadingLevel,
  WidthType,
  BorderStyle,
  ShadingType,
  LevelFormat,
  PageNumber,
  TableOfContents,
  TabStopType,
  TabStopPosition,
} = require("docx");

const outPath = path.join(__dirname, "DSSAT_Hemp_Beginner_Guide.docx");

const border = { style: BorderStyle.SINGLE, size: 1, color: "D0D0D0" };
const borders = { top: border, bottom: border, left: border, right: border };

function p(text, options = {}) {
  return new Paragraph({
    children: [new TextRun({ text, bold: options.bold || false })],
    spacing: { after: options.after ?? 120, before: options.before ?? 0 },
    heading: options.heading,
    pageBreakBefore: options.pageBreakBefore || false,
    tabStops: options.tabStops,
  });
}

function bullet(text) {
  return new Paragraph({
    numbering: { reference: "bullets", level: 0 },
    spacing: { after: 80 },
    children: [new TextRun(text)],
  });
}

function numberItem(text) {
  return new Paragraph({
    numbering: { reference: "numbers", level: 0 },
    spacing: { after: 90 },
    children: [new TextRun(text)],
  });
}

function cell(text, width, fill = "FFFFFF", bold = false) {
  return new TableCell({
    width: { size: width, type: WidthType.DXA },
    borders,
    shading: { fill, type: ShadingType.CLEAR },
    margins: { top: 80, bottom: 80, left: 120, right: 120 },
    children: [
      new Paragraph({
        spacing: { after: 0 },
        children: [new TextRun({ text, bold })],
      }),
    ],
  });
}

function makeTable(rows, widths) {
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: widths,
    rows,
  });
}

const sections = [];

sections.push(
  p("DSSAT Hemp Project Beginner Guide", {
    heading: HeadingLevel.TITLE,
    after: 220,
  }),
  p("A step-by-step walkthrough for understanding, running, checking, and calibrating your hemp DSSAT project.", {
    after: 160,
  }),
  p("Prepared for the project in C:\\Users\\chich\\Downloads\\DSSAT Files\\DSSAT Files and the DSSAT installation at C:\\DSSAT48.", {
    after: 240,
  }),
  new Paragraph({
    children: [new TextRun("Version date: 28 April 2026")],
    tabStops: [{ type: TabStopType.RIGHT, position: TabStopPosition.MAX }],
    spacing: { after: 320 },
  }),
  new TableOfContents("Table of Contents", {
    hyperlink: true,
    headingStyleRange: "1-3",
  }),
  p("1. What This Project Is", {
    heading: HeadingLevel.HEADING_1,
    pageBreakBefore: true,
  }),
  p("This project is a crop simulation workflow for hemp using DSSAT and the CROPGRO model family. In simple terms, DSSAT takes weather, soil, management, and cultivar parameters and simulates crop growth, development, water use, nutrient uptake, and yield-related outputs."),
  p("Your current project is not just a single DSSAT experiment file. It is a complete mini-ecosystem made of:"),
  bullet("experiment files in the Hemp folder"),
  bullet("genetic coefficient files in the Genotype folder"),
  bullet("weather station files in the Weather folder"),
  bullet("soil profile files in the Soil folder"),
  bullet("metadata files in the DSSAT root folder such as SIMULATION.CDE, DETAIL.CDE, and DSSATPRO.V48"),
  bullet("an R workflow that automates reruns and collects outputs into analysis tables"),
  p("A useful mindset is this: the experiment file is the recipe, the weather and soil files are the environment, the genotype files are the crop behavior rules, and DSSAT is the engine that combines them into a simulation."),
  p("2. The Minimum Things DSSAT Needs To Run Hemp", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("For hemp to run, DSSAT needs both the normal scientific inputs and the correct metadata that tells DSSAT hemp is a valid crop under CROPGRO. This was the critical issue we fixed on your machine."),
  makeTable(
    [
      new TableRow({
        children: [
          cell("Component", 2500, "D9EAF4", true),
          cell("Example on your machine", 3400, "D9EAF4", true),
          cell("Why it matters", 3460, "D9EAF4", true),
        ],
      }),
      new TableRow({
        children: [
          cell("Experiment file", 2500),
          cell("C:\\DSSAT48\\Hemp\\UFHO0399.HMX", 3400),
          cell("Defines treatments, planting dates, cultivar choices, soil ID, weather station, management operations, and simulation controls.", 3460),
        ],
      }),
      new TableRow({
        children: [
          cell("Cultivar file", 2500),
          cell("C:\\DSSAT48\\Genotype\\HMGRO048.CUL", 3400),
          cell("Stores cultivar-level parameters such as photoperiod response and partitioning behavior.", 3460),
        ],
      }),
      new TableRow({
        children: [
          cell("Ecotype file", 2500),
          cell("C:\\DSSAT48\\Genotype\\HMGRO048.ECO", 3400),
          cell("Stores ecotype-level parameters shared across related cultivars.", 3460),
        ],
      }),
      new TableRow({
        children: [
          cell("Species file", 2500),
          cell("C:\\DSSAT48\\Genotype\\HMGRO048.SPE", 3400),
          cell("Stores hemp species-level parameters for photosynthesis, partitioning, stress, and tissue composition.", 3460),
        ],
      }),
      new TableRow({
        children: [
          cell("Weather file", 2500),
          cell("Example: C:\\DSSAT48\\Weather\\UFHO0301.WTH", 3400),
          cell("Provides daily weather forcing such as solar radiation, maximum temperature, minimum temperature, and rainfall.", 3460),
        ],
      }),
      new TableRow({
        children: [
          cell("Soil profile", 2500),
          cell("Referenced by soil ID such as UFHO2101", 3400),
          cell("Provides soil hydraulic and chemical properties used for rooting, water balance, and nutrient processes.", 3460),
        ],
      }),
      new TableRow({
        children: [
          cell("Metadata files", 2500),
          cell("SIMULATION.CDE, DETAIL.CDE, DSSATPRO.V48", 3400),
          cell("Tell DSSAT that HM is a valid hemp crop and that CRGRO048 can simulate it.", 3460),
        ],
      }),
    ],
    [2500, 3400, 3460],
  ),
  p("3. What The Main Hemp Files Mean", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("You asked what the so-called hemp files are. Here is the practical interpretation you should keep in mind."),
  makeTable(
    [
      new TableRow({
        children: [
          cell("File type", 1900, "D9EAF4", true),
          cell("Meaning", 2400, "D9EAF4", true),
          cell("How you use it", 5060, "D9EAF4", true),
        ],
      }),
      new TableRow({
        children: [
          cell(".HMX", 1900),
          cell("Hemp experiment file", 2400),
          cell("This is the file you run. It links weather, soil, cultivar, and management together into one or more treatments.", 5060),
        ],
      }),
      new TableRow({
        children: [
          cell(".CUL", 1900),
          cell("Cultivar coefficients", 2400),
          cell("Edit this when calibrating cultivar-specific behavior such as flowering timing, biomass partitioning, and maturity behavior.", 5060),
        ],
      }),
      new TableRow({
        children: [
          cell(".ECO", 1900),
          cell("Ecotype coefficients", 2400),
          cell("Edit this when a group of cultivars share broader developmental behavior such as maturity group logic or adaptation traits.", 5060),
        ],
      }),
      new TableRow({
        children: [
          cell(".SPE", 1900),
          cell("Species coefficients", 2400),
          cell("Change carefully. This is species-level biology and usually should not be your first calibration target.", 5060),
        ],
      }),
      new TableRow({
        children: [
          cell(".WTH", 1900),
          cell("Daily weather data", 2400),
          cell("Check quality and consistency. Usually correct or replace bad weather data rather than ‘calibrate’ it to fit the model.", 5060),
        ],
      }),
      new TableRow({
        children: [
          cell(".SOL", 1900),
          cell("Soil profile file", 2400),
          cell("Review layer depths, texture, bulk density, water limits, organic carbon, pH, and nutrient-related entries before changing genetic parameters.", 5060),
        ],
      }),
      new TableRow({
        children: [
          cell("DSSBatch.V48", 1900),
          cell("Batch run list", 2400),
          cell("Lists which experiment file and which treatment numbers DSSAT should run in one call.", 5060),
        ],
      }),
    ],
    [1900, 2400, 5060],
  ),
  p("4. How This Specific Project Flows End To End", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("For your project, the easiest way to think about the end-to-end workflow is this:"),
  numberItem("Pick one experiment file, for example UFHO0399.HMX."),
  numberItem("Generate a batch file telling DSSAT which treatments to run."),
  numberItem("Run DSSAT from C:\\DSSAT48\\Hemp so the engine reads the local hemp experiment and writes output files into the same folder."),
  numberItem("Read outputs such as Summary.OUT, PlantGro.OUT, Weather.OUT, and Overview.OUT."),
  numberItem("Compare the outputs with observed data or with the summary tables created by your R workflow."),
  p("Your R script already follows exactly this idea. For example, it repeatedly does three things:"),
  bullet("sets the working directory to C:\\DSSAT48\\Hemp"),
  bullet("writes DSSBatch.V48 with selected treatment numbers"),
  bullet("calls run_dssat() and then reads outputs back into R"),
  p("That means your project has two layers: the DSSAT simulation layer and the R automation or post-processing layer."),
  p("5. What You Should Learn First As A New DSSAT User", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("If you are new to crop modelling, do not start by changing many parameters at once. The safest learning sequence is:"),
  numberItem("Learn how to run one experiment file successfully."),
  numberItem("Learn which input file supplies which piece of information."),
  numberItem("Learn how to inspect Summary.OUT and PlantGro.OUT."),
  numberItem("Check weather and soil realism before tuning genetics."),
  numberItem("Only after the run is clean and the inputs are believable should you calibrate cultivar parameters."),
  p("A beginner mistake is to use genetic coefficients to hide poor weather, poor soil, or incorrect management inputs. That usually produces a model that fits one case badly and fails everywhere else."),
  p("6. A Safe Beginner Workflow For This Hemp Project", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("Use this exact order when you work on the project."),
  numberItem("Start from a known-good baseline run. On this machine, the reproducibility check script in the project folder gives you that baseline."),
  numberItem("Limit yourself to one site and one treatment set first, for example UFHO0399 treatments 1 to 9."),
  numberItem("Confirm that the outputs are produced without errors."),
  numberItem("Read the experiment file and write down the cultivar, weather station, soil ID, planting date, and fertilizer assumptions."),
  numberItem("Compare simulated dates and yields against observed values before you change anything."),
  numberItem("Change only one category of inputs at a time: weather, then soil, then management, then cultivar or ecotype."),
  p("7. How To Read An HMX File", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("An HMX file is where the experiment is assembled. The most important sections for a beginner are:"),
  bullet("TREATMENTS: lists the scenarios you are running"),
  bullet("CULTIVARS: shows which cultivar code each treatment uses"),
  bullet("FIELDS: points to weather station and soil ID"),
  bullet("PLANTING DETAILS: controls planting date, density, row spacing, and depth"),
  bullet("FERTILIZERS and IRRIGATION: define management events"),
  bullet("SIMULATION CONTROLS: determine run options and outputs"),
  p("If a run looks wrong, this is often the best first file to inspect because it links nearly everything else together."),
  p("8. How To Think About Weather Data", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("Weather is not usually calibrated in the same way genetics are calibrated. Weather is closer to measured forcing data. Your goal is not to make weather fit the model; your goal is to make sure the weather file honestly represents the real environment."),
  p("What to check in a weather file:"),
  bullet("station code matches what the HMX file expects"),
  bullet("daily records cover the full simulation period"),
  bullet("solar radiation units are plausible"),
  bullet("TMAX is always greater than or equal to TMIN"),
  bullet("rainfall is not shifted by one day"),
  bullet("no large missing blocks or impossible repeated values"),
  p("What you can adjust carefully:"),
  bullet("fill missing values from a trusted nearby station or reanalysis source"),
  bullet("correct obvious formatting or unit mistakes"),
  bullet("replace clearly wrong station files with better curated ones"),
  p("What you should not do:"),
  bullet("raise or lower temperatures just to force flowering or yield to match"),
  bullet("inflate rainfall because the crop looked too dry in the model"),
  p("9. How To Think About Soil Data", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("Soil is partly measured data and partly inferred data. Soil files often need refinement because field profiles are incomplete. This is where careful adjustment is often acceptable."),
  p("The main question is not ‘How do I make yield match?’ but ‘Does this soil file describe the real field well enough for the water and nutrient balance to behave realistically?’"),
  p("What to inspect first in a soil profile:"),
  bullet("layer depths"),
  bullet("texture class and consistency with sand, silt, and clay"),
  bullet("bulk density"),
  bullet("lower limit, drained upper limit, and saturation"),
  bullet("soil organic carbon or organic matter"),
  bullet("soil pH"),
  bullet("initial soil water and initial nitrate or ammonium if used"),
  p("A practical soil calibration order is:"),
  numberItem("Fix obvious structural errors such as layer depth or texture mismatches."),
  numberItem("Improve hydraulic realism so the water balance behaves reasonably."),
  numberItem("Improve fertility-related entries only after water dynamics look believable."),
  numberItem("Re-run and check whether stress timing looks more realistic."),
  p("10. How To Think About Management Data", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("Management settings are often easier to correct than genetics and should be checked early. For hemp, management assumptions such as plant density, planting date, nitrogen rate, and irrigation can strongly affect biomass and harvest outcomes."),
  p("For your project, many treatment names already encode management scenarios such as planting density or nitrogen rate. That means management is part of the treatment design, not a background detail."),
  p("Before touching genetic coefficients, ask these questions:"),
  bullet("Is the planting date correct?"),
  bullet("Is the stand density realistic?"),
  bullet("Are fertilizer dates and amounts correct?"),
  bullet("Is irrigation being applied when the field actually was irrigated?"),
  bullet("Does the harvest rule reflect how the observed data were collected?"),
  p("11. How To Think About Genetic Calibration", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("Genetic calibration means tuning cultivar or ecotype parameters so simulated crop development and partitioning resemble the observed cultivar behavior under believable environmental and management inputs."),
  p("In your hemp project, the main genetic files are HMGRO048.CUL and HMGRO048.ECO. The species file HMGRO048.SPE is usually a later-stage target, not the first place to edit."),
  p("A simple beginner rule is:"),
  bullet("CUL = cultivar-specific tuning"),
  bullet("ECO = broader ecotype tuning"),
  bullet("SPE = species-level biology, change only with strong justification"),
  p("Typical calibration sequence for cultivar parameters:"),
  numberItem("Match development timing first, especially emergence, flowering, and maturity or harvest timing."),
  numberItem("Then match biomass accumulation and partitioning."),
  numberItem("Then check harvest weight and any quality-related targets."),
  p("If flowering and maturity timing are wrong, do not start by adjusting yield partitioning. Get phenology roughly right first."),
  p("12. A Recommended Calibration Order For Your Hemp Project", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("If I were starting fresh on this project, I would calibrate in this order:"),
  numberItem("Baseline run validation: make sure the run is clean and reproducible."),
  numberItem("Weather quality control: confirm station files and units."),
  numberItem("Soil quality control: improve hydraulic realism and initial condition realism."),
  numberItem("Management confirmation: planting date, density, nitrogen, irrigation, harvest assumptions."),
  numberItem("Phenology calibration in HMGRO048.CUL and HMGRO048.ECO."),
  numberItem("Biomass and harvest calibration in HMGRO048.CUL."),
  numberItem("Only if necessary, species-level refinements in HMGRO048.SPE."),
  p("13. What Outputs To Inspect After Every Run", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("Do not rerun blindly. After every meaningful change, inspect the same core outputs."),
  makeTable(
    [
      new TableRow({
        children: [
          cell("Output file", 2300, "D9EAF4", true),
          cell("What it tells you", 7060, "D9EAF4", true),
        ],
      }),
      new TableRow({
        children: [
          cell("Summary.OUT", 2300),
          cell("Season-level summary values such as flowering date, maturity date, biomass, harvest weight, water and nitrogen totals. This is the fastest file for spotting big problems.", 7060),
        ],
      }),
      new TableRow({
        children: [
          cell("Overview.OUT", 2300),
          cell("Readable narrative summary of the run. Good for quick interpretation and troubleshooting.", 7060),
        ],
      }),
      new TableRow({
        children: [
          cell("PlantGro.OUT", 2300),
          cell("Time-series growth output. Essential for checking whether the crop trajectory is realistic, not just the final yield.", 7060),
        ],
      }),
      new TableRow({
        children: [
          cell("Weather.OUT", 2300),
          cell("Simulation-period weather values as used during the run. Useful for quality control and downstream analysis.", 7060),
        ],
      }),
      new TableRow({
        children: [
          cell("SoilWat.OUT", 2300),
          cell("Helps you see whether the soil water dynamics make sense and whether stress timing is believable.", 7060),
        ],
      }),
      new TableRow({
        children: [
          cell("WARNING.OUT and ERROR.OUT", 2300),
          cell("Always inspect these if something odd happens. Warnings often explain why results look strange even when the run technically completed.", 7060),
        ],
      }),
    ],
    [2300, 7060],
  ),
  p("14. How To Decide Whether A Change Helped", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("A good change should improve the model for the right reason. That means:"),
  bullet("the parameter you changed belongs to the process that was wrong"),
  bullet("the improvement is visible in more than one output or more than one treatment"),
  bullet("the change does not break a process that was already behaving well"),
  p("For example, if flowering is late across many treatments, adjusting phenology parameters may make sense. If only one site is late because its weather file is wrong, a genetic change would be the wrong fix."),
  p("15. Common Beginner Mistakes", {
    heading: HeadingLevel.HEADING_1,
  }),
  bullet("Changing too many parameters between runs."),
  bullet("Treating weather like a calibration target instead of forcing data."),
  bullet("Using cultivar coefficients to hide soil or management problems."),
  bullet("Looking only at final yield and ignoring growth trajectories."),
  bullet("Editing the species file too early."),
  bullet("Failing to keep a record of what changed between runs."),
  p("16. A Practical Work Log You Should Keep", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("For each change, record at least:"),
  bullet("date"),
  bullet("files changed"),
  bullet("parameters changed"),
  bullet("reason for the change"),
  bullet("which site and treatments were rerun"),
  bullet("which outputs improved or worsened"),
  p("This is especially important in calibration because memory becomes unreliable after only a few iterations."),
  p("17. The Reproducible Run On This Machine", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("On your machine, the current reproducible check is in:"),
  bullet("C:\\Users\\chich\\Downloads\\DSSAT Files\\DSSAT Files\\reproduce_hemp_results.ps1"),
  p("The run writes outputs into:"),
  bullet("C:\\DSSAT48\\Hemp"),
  p("The official source and metadata copies used to fix the hemp support are in:"),
  bullet("C:\\Users\\chich\\Downloads\\DSSAT Files\\DSSAT Files\\dssat-csm-os"),
  bullet("C:\\Users\\chich\\Downloads\\DSSAT Files\\DSSAT Files\\dssat-csm-data"),
  p("The key lesson from this fix is important for future machines: hemp support depends not only on the experiment files but also on the newer metadata files that register HM in DSSAT."),
  p("18. A Beginner-Friendly End-to-End Checklist", {
    heading: HeadingLevel.HEADING_1,
  }),
  numberItem("Confirm the DSSAT install folder exists."),
  numberItem("Confirm Hemp, Genotype, Soil, and Weather folders are copied into the install."),
  numberItem("Confirm SIMULATION.CDE, DETAIL.CDE, and DSSATPRO.V48 are hemp-aware."),
  numberItem("Run one small batch first, such as UFHO0399 treatments 1 to 9."),
  numberItem("Read Summary.OUT and check that the run completed without ERROR.OUT problems."),
  numberItem("Review weather realism and soil realism before calibrating genetics."),
  numberItem("Check management assumptions from the HMX file."),
  numberItem("Calibrate phenology first, then biomass and harvest behavior."),
  numberItem("Document every change."),
  numberItem("Only scale up to many sites or treatments after the baseline looks scientifically believable."),
  p("19. Final Advice", {
    heading: HeadingLevel.HEADING_1,
  }),
  p("If you feel overwhelmed, that is normal. Crop modelling projects look like many files, but conceptually they are simpler than they first appear. The core question is always the same: do the environment, management, and genetics combine to produce a believable crop story?"),
  p("Work one layer at a time. First make the run clean. Then make the weather and soil believable. Then make the management accurate. Then calibrate cultivar behavior. That order will save you a lot of confusion."),
  p("20. Suggested Next Steps For You", {
    heading: HeadingLevel.HEADING_1,
  }),
  numberItem("Run the reproducibility script once and confirm the outputs appear in C:\\DSSAT48\\Hemp."),
  numberItem("Open UFHO0399.HMX and write down the weather station, soil ID, cultivar codes, and treatment meanings."),
  numberItem("Pick one site and one treatment group for your first calibration cycle."),
  numberItem("Compare observed flowering date, maturity or harvest date, biomass, and harvest output against Summary.OUT and PlantGro.OUT."),
  numberItem("Adjust only one category of inputs at a time and keep a short calibration log."),
  p("If you want, the next document I can make for you is a calibration workbook template where each page helps you record one calibration cycle for one site and one treatment set.")
);

const doc = new Document({
  creator: "OpenAI Codex",
  title: "DSSAT Hemp Project Beginner Guide",
  description: "Step-by-step beginner guide for understanding and calibrating a hemp DSSAT project.",
  styles: {
    default: {
      document: {
        run: { font: "Arial", size: 22 },
      },
    },
    paragraphStyles: [
      {
        id: "Heading1",
        name: "Heading 1",
        basedOn: "Normal",
        next: "Normal",
        quickFormat: true,
        run: { font: "Arial", size: 32, bold: true },
        paragraph: { spacing: { before: 240, after: 140 }, outlineLevel: 0 },
      },
      {
        id: "Heading2",
        name: "Heading 2",
        basedOn: "Normal",
        next: "Normal",
        quickFormat: true,
        run: { font: "Arial", size: 26, bold: true },
        paragraph: { spacing: { before: 180, after: 120 }, outlineLevel: 1 },
      },
      {
        id: "Title",
        name: "Title",
        basedOn: "Normal",
        next: "Normal",
        quickFormat: true,
        run: { font: "Arial", size: 36, bold: true },
        paragraph: { spacing: { after: 200 }, alignment: AlignmentType.CENTER },
      },
    ],
  },
  numbering: {
    config: [
      {
        reference: "bullets",
        levels: [
          {
            level: 0,
            format: LevelFormat.BULLET,
            text: "•",
            alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 720, hanging: 360 } } },
          },
        ],
      },
      {
        reference: "numbers",
        levels: [
          {
            level: 0,
            format: LevelFormat.DECIMAL,
            text: "%1.",
            alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 720, hanging: 360 } } },
          },
        ],
      },
    ],
  },
  sections: [
    {
      properties: {
        page: {
          size: { width: 12240, height: 15840 },
          margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 },
        },
      },
      headers: {
        default: new Header({
          children: [
            new Paragraph({
              border: {
                bottom: { style: BorderStyle.SINGLE, size: 6, color: "8FAFC1", space: 1 },
              },
              spacing: { after: 60 },
              children: [new TextRun("DSSAT Hemp Project Beginner Guide")],
            }),
          ],
        }),
      },
      footers: {
        default: new Footer({
          children: [
            new Paragraph({
              alignment: AlignmentType.CENTER,
              children: [
                new TextRun("Page "),
                new TextRun({ children: [PageNumber.CURRENT] }),
              ],
            }),
          ],
        }),
      },
      children: sections,
    },
  ],
});

Packer.toBuffer(doc).then((buffer) => {
  fs.writeFileSync(outPath, buffer);
  console.log(outPath);
});
