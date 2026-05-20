package org.ciat.gavilan.control;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Scanner;

import org.ciat.gavilan.model.Measurements;
import org.ciat.gavilan.model.SummaryRun;
import org.ciat.gavilan.model.Treatment;
import org.ciat.gavilan.model.Utils;
import org.ciat.gavilan.model.Variable;
import org.ciat.gavilan.view.ProgressBar;

public class OverviewWorker {

	private Map<String, String> outputValues;
	private Map<Variable, String> growthLables;
	private Map<Variable, Integer> indexFileA;
	private List<String> cropNSoilLables;
	private SummaryRun run;
	private Map<Integer, Treatment> treatments;
	private static final String NO_DATE = "NO_DATE";

	public enum fileSection {
		INIT(), CROP_N_SOIL, GROWTH, END
	};

	public OverviewWorker(SummaryRun summaryRun) {
		this.run = summaryRun;
		this.cropNSoilLables = new ArrayList<String>();
		this.growthLables = new LinkedHashMap<Variable, String>();
		this.outputValues = new LinkedHashMap<String, String>();
		this.indexFileA = new LinkedHashMap<Variable, Integer>();

	}

	public void work() {

		ProgressBar bar = new ProgressBar();
		int subFolderIndex = 0;

		populateVariables();
		treatments = readMeasurements();

		File CSV = run.getOverviewCSVOutput();
		// File JSON = run.getOverviewJSONOutput();

		try (BufferedWriter CSVwriter = new BufferedWriter(
				new PrintWriter(CSV)); /* BufferedWriter JSONwriter = new BufferedWriter(new PrintWriter(JSON)) */) {

			/* Building the header */
			String head = SummaryRun.CANDIDATE_LABEL + SummaryRun.COLUMN_SEPARATOR + "RUN" + SummaryRun.COLUMN_SEPARATOR + SummaryRun.TREATMENT_LABEL + SummaryRun.COLUMN_SEPARATOR;

			for (String var : cropNSoilLables) {
				outputValues.put(var, "");
				var = var.replaceAll(",", "");
				var = var.replaceAll(SummaryRun.COLUMN_SEPARATOR, "");
				head += var + SummaryRun.COLUMN_SEPARATOR;
			}

			for (Variable var : indexFileA.keySet()) {
				outputValues.put(SummaryRun.MEASURED_PREFIX + var.getName(), "");
				outputValues.put(SummaryRun.SIMULATED_PREFIX + var.getName(), "");
				head += SummaryRun.MEASURED_PREFIX + var.getName() + SummaryRun.COLUMN_SEPARATOR;
				head += SummaryRun.SIMULATED_PREFIX + var.getName() + SummaryRun.COLUMN_SEPARATOR;
			}

			CSVwriter.write(head);
			CSVwriter.newLine();
			/* END building the header **/

			/* Search on each OVERVIEW.OUT file from 0/ folder and further */
			boolean flagFolder = true;
			for (int folder = 0; flagFolder; folder++) {
				File bigFolder = new File(folder + SummaryRun.PATH_SEPARATOR);
				if (bigFolder.exists()) {
					bar = new ProgressBar();
					System.out.println("Getting overwiew on folder " + bigFolder.getName());
					int subFoderTotal = bigFolder.listFiles().length;

					for (File subFolder : bigFolder.listFiles()) { // for each subfolder
						// look at the overview.out file
						File output = new File(subFolder.getAbsolutePath() + SummaryRun.PATH_SEPARATOR + "OVERVIEW.OUT");
						if (output.exists()) {
							// for each candidate get all the simulated and observed values
							for (String cadena : getCandidateVariables(output)) {
								CSVwriter.write(cadena); // print the values
								CSVwriter.newLine();
							}

						} else {
							App.log.warning(subFolder.getName() + SummaryRun.PATH_SEPARATOR + output.getName() + " not found");
						}
						subFolderIndex++;
						if (subFolderIndex % 100 == 0) {
							bar.update(subFolderIndex, subFoderTotal);
						}
					}
					bar.update(subFoderTotal - 1, subFoderTotal);
					// bwriter.flush();

				} else {
					flagFolder = false; // Flag that there are no more folders search in
					App.log.fine("Finished gathering overwiew results");
				}
			}

			App.log.fine("overview.csv created");

		} catch (IOException e1) {
			e1.printStackTrace();
		}

	}

	private void populateVariables() {
		Variable var = new Variable("");
		switch (run.getModel()) {
		case BEAN: {
			cropNSoilLables.add("Emergence");
			cropNSoilLables.add("End Juven");
			cropNSoilLables.add("Flower Ind");
			cropNSoilLables.add("First Flwr");
			cropNSoilLables.add("First Pod");
			cropNSoilLables.add("First Seed");
			cropNSoilLables.add("End Pod");
			cropNSoilLables.add("Phys. Mat");
			cropNSoilLables.add("End Leaf");
			cropNSoilLables.add("Harv. Mat");
			cropNSoilLables.add("Harvest");
			var = new Variable("ADAP");
			growthLables.put(var, "Anthesis day (dap)");
			var = new Variable("MDAP");
			growthLables.put(var, "Physiological maturity day (dap) ");
			var = new Variable("HWAM");
			growthLables.put(var, "Yield at harvest maturity (kg [dm]/ha)");
			var = new Variable("H#AM");
			growthLables.put(var, "Number at maturity (no/m2)");
			var = new Variable("HWUM");
			growthLables.put(var, "Unit wt at maturity (g [dm]/unit)");
			var = new Variable("H#UM");
			growthLables.put(var, "Number at maturity (no/unit)");
			var = new Variable("CWAM");
			growthLables.put(var, "Tops weight at maturity (kg [dm]/ha)");
			var = new Variable("BWAH");
			growthLables.put(var, "By-product produced (stalk) at maturity (kg[dm]/ha");
			var = new Variable("LAIX");
			growthLables.put(var, "Leaf area index, maximum");
			var = new Variable("HIAM");
			growthLables.put(var, "Harvest index at maturity");
			var = new Variable("L#SM");
			growthLables.put(var, "Leaf number per stem at maturity");
			var = new Variable("PWAM");
			growthLables.put(var, "Pod/Ear/Panicle weight at maturity");
			var = new Variable("PD1P");
			growthLables.put(var, "First pod day");
			var = new Variable("PDFP");
			growthLables.put(var, "First seed day");
			var = new Variable("CWAM");
			growthLables.put(var, "Tops N at maturity");
			var = new Variable("LAIX");
			growthLables.put(var, "Leaf area index, maximum ");

		}

			break;
		case MAIZE: {
			cropNSoilLables.add("End Juveni");
			cropNSoilLables.add("Floral Ini");
			cropNSoilLables.add("Silkin");
			cropNSoilLables.add("Beg Gr Fil");
			cropNSoilLables.add("End Gr Fil");
			cropNSoilLables.add("Maturity");
			cropNSoilLables.add("Harvest");
			var = new Variable("ADAP");
			growthLables.put(var, "Anthesis day (dap)");
			var = new Variable("MDAP");
			growthLables.put(var, "Physiological maturity day (dap) ");
			var = new Variable("HWAM");
			growthLables.put(var, "Yield at harvest maturity (kg [dm]/ha)");
			var = new Variable("H#AM");
			growthLables.put(var, "Number at maturity (no/m2)");
			var = new Variable("HWUM");
			growthLables.put(var, "Unit wt at maturity (g [dm]/unit)");
			var = new Variable("H#UM");
			growthLables.put(var, "Number at maturity (no/unit)");
			var = new Variable("CWAM");
			growthLables.put(var, "Tops weight at maturity (kg [dm]/ha)");
			var = new Variable("BWAH");
			growthLables.put(var, "By-product produced (stalk) at maturity (kg[dm]/ha");
			var = new Variable("LAIX");
			growthLables.put(var, "Leaf area index, maximum");
			var = new Variable("HIAM");
			growthLables.put(var, "Harvest index at maturity");

		}
			break;
		case CASSAVA: {
			cropNSoilLables.add("Harvest");


		}
			break;
		default: {
			App.log.warning("Crop not configurated for overview: " + run.getModel() + ", using default variables");
			cropNSoilLables.add("End Juven");
			cropNSoilLables.add("Floral I");
			cropNSoilLables.add("Harvest");
			var = new Variable("ADAP");
			growthLables.put(var, "Anthesis day (dap)");
			var = new Variable("MDAP");
			growthLables.put(var, "Physiological maturity day (dap) ");
			var = new Variable("HWAM");
			growthLables.put(var, "Yield at harvest maturity (kg [dm]/ha)");
			var = new Variable("H#AM");
			growthLables.put(var, "Number at maturity (no/m2)");
			var = new Variable("HWUM");
			growthLables.put(var, "Unit wt at maturity (g [dm]/unit)");
			var = new Variable("H#UM");
			growthLables.put(var, "Number at maturity (no/unit)");
			var = new Variable("CWAM");
			growthLables.put(var, "Tops weight at maturity (kg [dm]/ha)");
			var = new Variable("BWAH");
			growthLables.put(var, "By-product produced (stalk) at maturity (kg[dm]/ha");
			var = new Variable("LAIX");
			growthLables.put(var, "Leaf area index, maximum");
			var = new Variable("HIAM");
			growthLables.put(var, "Harvest index at maturity");
		}
		}

	}

	/*
	 * obtain all the simulated and observed values of the variables populated in both cropNSoilVariables and
	 * growthVariables
	 */
	private List<String> getCandidateVariables(File cultivarOutput) {

		List<String> runsOutput = new ArrayList<String>();
		String cadena = "";
		String line = "";
		fileSection flag = fileSection.INIT;
		int treatment = 0;
		int run = 0;

		try (Scanner reader = new Scanner(cultivarOutput)) {

			while (reader.hasNextLine()) { // reading the whole file
				line = reader.nextLine();

				switch (flag) {
				case INIT: {
					if (line.contains("*RUN")) { // to detect each single run
						run = Integer.parseInt(line.substring(6, 10).replaceAll(" ", ""));
						// to print candidate ID and the run
						cadena = (new File(cultivarOutput.getParent())).getName() + SummaryRun.COLUMN_SEPARATOR + run + SummaryRun.COLUMN_SEPARATOR;
						for (String key : outputValues.keySet()) {
							outputValues.put(key, ""); // clear the previous values to recycle the Map
						}
					}
					if (line.contains("TREATMENT")) { // to detect each single treatment of a run
						treatment = Integer.parseInt(line.substring(11, 15).replaceAll(" ", ""));
						// to print experiment treatment
						cadena += treatment + SummaryRun.COLUMN_SEPARATOR;
					}
					if (line.contains("*SIMULATED CROP AND SOIL STATUS AT MAIN DEVELOPMENT STAGES")) { // detect section
						flag = fileSection.CROP_N_SOIL;
					}
				}
					break;
				case CROP_N_SOIL: {

					for (String var : cropNSoilLables) {
						if (line.contains(var)) { // if contains the string that corresponds to the variable
							outputValues.put(var, line.substring(7, 12)); // get value from file
						}
					}
					if (line.contains("*MAIN GROWTH AND DEVELOPMENT VARIABLES")) { // detect section
						flag = fileSection.GROWTH;
					}
				}
					break;
				case GROWTH: {

					for (Variable var : indexFileA.keySet()) {
						// if contains the string that corresponds to the variable
						if (!line.isEmpty() && line.contains(growthLables.get(var))) {
							if (treatments.get(treatment) != null) {
								outputValues.put(SummaryRun.MEASURED_PREFIX + var.getName(), treatments.get(treatment).getMeasurements().get(NO_DATE).getValues().get(var).doubleValue() + "");
								// get simulated value
								outputValues.put(SummaryRun.SIMULATED_PREFIX + var.getName(), line.substring(57, 64));
							}
						}

					}
					// to detect the end of the treatment run
					if (line.contains("----------------------------------------------------------------------------------------------------------------------------------------------------------------")) {
						flag = fileSection.END;
						for (String key : outputValues.keySet()) {
							cadena += outputValues.get(key) + SummaryRun.COLUMN_SEPARATOR;
						}
						runsOutput.add(cadena);
					}
				}
				case END: {
					if (line.contains("*DSSAT Cropping System Model")) { // detect the start of a new treatment run
						flag = fileSection.INIT;
					}

				}
					break;
				default:
					break;
				}
			}

			// reader.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}

		return runsOutput;
	}

	private Map<Integer, Treatment> readMeasurements() {

		Map<Integer, Treatment> treatments = new LinkedHashMap<>();
		File fileA = new File(App.prop.getProperty("fileA.location"));
		Scanner reader;
		String line = "";
		String[] numbers; // the numbers of that row of the table
		Treatment treatment = new Treatment(-1);
		Treatment newTreatment = new Treatment(-1);
		Measurements meas = new Measurements();

		try {
			if (fileA.exists()) {
				reader = new Scanner(fileA);
				while (reader.hasNextLine()) {
					line = reader.nextLine();
					line = line.trim();

					/* Leave the line with only one space of separation */
					while (line.contains("  ")) {
						line = line.replaceAll("  ", " ");
					}

					numbers = line.split(" ");
					// if the line start with a number
					if (numbers.length > 0 && Utils.isNumeric(numbers[0])) {
						newTreatment = new Treatment(Integer.parseInt(numbers[0]));
						if (!treatment.equals(newTreatment)) {
							treatment = newTreatment;
						} else {
							App.log.warning("It is suppose to have only one sample per treatment " + numbers[0]);
						}

						meas = new Measurements();
						// fill the values on that row for all the variables
						for (Variable var : indexFileA.keySet()) {
							// add the measurement of each variable
							meas.getValues().put(var, Double.parseDouble(numbers[indexFileA.get(var)]));
						}
						// add the measurement with all the values for that in the treatment
						treatment.getMeasurements().put(NO_DATE, meas);
						treatments.put(treatment.getNumber(), treatment);
					} else {
						if (numbers[0].equals("@TRNO")) {
							for (int i = 1; i < numbers.length; i++) {

								Variable var = new Variable(numbers[i]);
								if (growthLables.containsKey(var)) {
									indexFileA.put(var, Integer.valueOf(i));
								} else {
									App.log.warning("The variable '" + var + "' is not an output in the OVERVIEW.OUT, please check this name in your file A");
								}

							}
						}
					}
				}

				reader.close();
			} else {
				App.log.severe("File A not found as " + fileA.getAbsolutePath());
			}

		} catch (FileNotFoundException e) {
			App.log.severe("File A not found as " + fileA.getAbsolutePath());
		}

		return treatments;
	}

	@Deprecated
	public static String obtainModel() {
		String model = "MZCER046 - Maize";
		File firstCultivarOutput = new File(((new File("0")).listFiles()[0].getAbsolutePath() + "\\OVERVIEW.OUT"));
		Scanner reader;
		try {
			if (firstCultivarOutput.exists()) {
				reader = new Scanner(firstCultivarOutput);
				String line = "";
				fileSection flag = fileSection.INIT;
				while (flag == fileSection.INIT && reader.hasNextLine()) {
					line = reader.nextLine();
					if (line.contains("MODEL          :")) {
						model = line.substring(18, 38);
						flag = fileSection.END;
					}

				}
				reader.close();
			}
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
		App.log.info("Detected model: " + model);
		return model;
	}

}
