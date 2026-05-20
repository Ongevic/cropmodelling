package org.ciat.gavilan.control;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.text.DecimalFormat;
import java.util.Calendar;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Scanner;

import org.ciat.gavilan.model.CropCode;
import org.ciat.gavilan.model.GoodnessEvaluator;
import org.ciat.gavilan.model.Measurements;
import org.ciat.gavilan.model.SummaryRun;
import org.ciat.gavilan.model.Treatment;
import org.ciat.gavilan.model.Utils;
import org.ciat.gavilan.model.Variable;
import org.ciat.gavilan.view.ProgressBar;

public class SeriesWorker {

	private Map<Variable, Integer> indexFileT;
	private Map<Variable, Integer> indexPlantGro;
	private Map<Integer, Treatment> samplings;
	private String[] inputCoeficientsNames;
	private Map<Integer, String> inputCoefficients; // pair of run a coefficients

	private SummaryRun run;

	public SeriesWorker(SummaryRun summaryRun) {
		this.run = summaryRun;
	}

	public void work() {

		indexFileT = new LinkedHashMap<>();
		indexPlantGro = getIndexPlantGro(run.getModel());
		samplings = getSampleMeasurements();
		Map<Integer, Treatment> simulations = new LinkedHashMap<Integer, Treatment>();
		inputCoefficients = new LinkedHashMap<Integer, String>();
		ProgressBar bar = new ProgressBar();
		int subFolderIndex = 0;
		DecimalFormat df = new DecimalFormat("00");
		String id_ = "";
		double measured, simulated;

		File CSV = run.getSummaryCSVOutput();
		File JSON = run.getSummaryJSONOutput();
		File Eval = run.getSummaryEvalOutput();

		String option = "";
		
		// check if user wants output in CSV
		boolean isCSV = true;
		try {
			option = "output.summary.csv";
			isCSV = App.prop.getProperty(option).contains("Y");
		} catch (Exception e1) {
			App.log.warning("A problem occurred reading option" + option + " configuration in " + App.config.getName() + ", taking default value: " + isCSV);
		}
		if (isCSV) {
			try {
				CSV.createNewFile();
			} catch (IOException e) {
				App.log.severe("File can't be created: " + CSV.getAbsolutePath());
			}
		}
		
		// check if user wants output in JSON
		boolean isJSON = true;
		try {
			option = "output.summary.json";
			isJSON = App.prop.getProperty(option).contains("Y");
		} catch (Exception e1) {
			App.log.warning("A problem occurred reading option" + option + " configuration in " + App.config.getName() + ", taking default value: " + isJSON);
		}
		if (isJSON) {
			try {
				JSON.createNewFile();
			} catch (IOException e) {
				App.log.severe("File can't be created: " + JSON.getAbsolutePath());
			}
		}

		// check if user wants evaluation
		boolean isEval = true;
		try {
			option = "output.eval.json";
			isEval = App.prop.getProperty(option).contains("Y");
		} catch (Exception e1) {
			App.log.warning("A problem occurred reading option" + option + " configuration in " + App.config.getName() + ", taking default value: " + isEval);
		}
		if (isEval) {
			File cul = new File(App.prop.getProperty("crop.name") + ".CUL");
			try {
				Eval.createNewFile();
			} catch (IOException e) {
				App.log.severe("File can't be created: " + Eval.getAbsolutePath());
			}
			if (App.prop.getProperty("output.eval.json").contains("Y")) {
				if (cul.exists()) {
					populateInputCoeficients(cul);
				} else {
					App.log.warning("Cultivar file not found " + cul.getAbsolutePath());
				}
			}
		}

		try (BufferedWriter CSVWriter = new BufferedWriter(new PrintWriter(CSV)); BufferedWriter JSONWriter = new BufferedWriter(new PrintWriter(JSON)); BufferedWriter EvalWriter = new BufferedWriter(new PrintWriter(Eval));) {

			/* Building the header */
			String head = SummaryRun.CANDIDATE_LABEL + SummaryRun.COLUMN_SEPARATOR + SummaryRun.DATE_LABEL + SummaryRun.COLUMN_SEPARATOR + SummaryRun.TREATMENT_LABEL + SummaryRun.COLUMN_SEPARATOR;

			for (Variable var : indexFileT.keySet()) {
				head += SummaryRun.MEASURED_PREFIX + var.getName() + SummaryRun.COLUMN_SEPARATOR;
				head += SummaryRun.SIMULATED_PREFIX + var.getName() + SummaryRun.COLUMN_SEPARATOR;
			}

			if (isCSV) {
				CSVWriter.write(head);
				CSVWriter.newLine();
			}
			/* END building the header **/

			/* Search on each run the PlanGro.OUT file from 0/ folder and further */
			boolean flagFolder = true;
			for (int folder = 0; flagFolder; folder++) {
				File bigFolder = new File(folder + SummaryRun.PATH_SEPARATOR);
				subFolderIndex = 0;
				if (bigFolder.exists()) {
					bar = new ProgressBar();
					System.out.println("Getting summary on folder " + bigFolder.getName());

					int subFoderTotal = bigFolder.listFiles().length;

					// for each subfolder
					for (File subFolder : bigFolder.listFiles()) {
						// look at the overview.out file
						File output = new File(subFolder.getAbsolutePath() + SummaryRun.PATH_SEPARATOR + "PlantGro.OUT");
						if (output.exists()) {
							simulations = getSimulatedMeasurements(output); // get simulated values for that run

							// for each treatment
							for (Integer tIndex : samplings.keySet()) {
								int sampleNumber = 0;

								/** Declaring matrix of values according to the number of the sample and the variable */
								// number of samplings measured
								int samplingNumber = samplings.get(tIndex).getMeasurements().size();
								// number of variables
								int variableNumber = samplings.get(tIndex).getMeasurements().get(samplings.get(tIndex).getMeasurements().keySet().iterator().next()).getValues().size();
								Double[][] matrixObservations = new Double[samplingNumber][variableNumber];
								Double[][] matrixSimulations = new Double[samplingNumber][variableNumber];
								String[] varNames = new String[samplingNumber];
								/** end of declaration */

								// for each sampling
								for (String date : samplings.get(tIndex).getMeasurements().keySet()) {
									sampleNumber++;
									int variableIndex = -1;

									// check if the treatment was simulated
									if (simulations.get(tIndex.intValue()) != null) {
										// check if that date was simulated
										if (simulations.get(tIndex.intValue()).getMeasurements().get(date) != null) {

											/* printing base data in CSV */
											if (isCSV) {
												CSVWriter.write(subFolder.getName() + SummaryRun.COLUMN_SEPARATOR);
												CSVWriter.write(date + SummaryRun.COLUMN_SEPARATOR);
												CSVWriter.write(tIndex.intValue() + SummaryRun.COLUMN_SEPARATOR);
											}

											/* printing base data in JSON */
											id_ = df.format(tIndex.intValue()) + df.format(sampleNumber) + subFolder.getName();
											if (isJSON) {
												/* printing elastic-search meta-fields */
												JSONWriter.write("{\"index\":{\"_index\":\"summary-" + run.getModel().toString().toLowerCase() + "-" + run.getRunName() + "\",\"_type\":\"sampling\",\"_id\":" + Long.parseLong(id_) + "}}");
												JSONWriter.newLine();
												/* printing run data */
												JSONWriter.write("{");
												JSONWriter.write("\"" + SummaryRun.KIBANA_INDEX + SummaryRun.CANDIDATE_LABEL + "\":" + Integer.parseInt(subFolder.getName()) + ",");
												JSONWriter.write("\"" + SummaryRun.KIBANA_INDEX + SummaryRun.DATE_LABEL + "\":\"" + date + "\",");
												JSONWriter.write("\"" + SummaryRun.KIBANA_INDEX + SummaryRun.TREATMENT_LABEL + "\":" + tIndex.intValue() + ",");
											}

											// for each variable sampled on the specific date
											for (Variable var : samplings.get(tIndex).getMeasurements().get(date).getValues().keySet()) {
												// get the measured value and the simulated value
												measured = samplings.get(tIndex.intValue()).getMeasurements().get(date).getValues().get(var).doubleValue();
												simulated = simulations.get(tIndex.intValue()).getMeasurements().get(date).getValues().get(var).doubleValue();

												/**
												 * populating the values according to the number of the sample and the
												 * variable
												 */
												variableIndex++;
												matrixObservations[sampleNumber - 1][variableIndex] = measured;
												matrixSimulations[sampleNumber - 1][variableIndex] = simulated;
												varNames[variableIndex] = var.getName();
												/** end of population */

												/* printing plantGro and file T values in CSV */
												if (isCSV) {
													CSVWriter.write(measured + SummaryRun.COLUMN_SEPARATOR);
													CSVWriter.write(simulated + SummaryRun.COLUMN_SEPARATOR);
												}

												/* printing plantGro and file T values in JSON */
												if (isJSON) {
													JSONWriter.write("\"" + SummaryRun.KIBANA_INDEX + SummaryRun.MEASURED_PREFIX + var.getName() + "\":" + measured + ",");
													JSONWriter.write("\"" + SummaryRun.KIBANA_INDEX + SummaryRun.SIMULATED_PREFIX + var.getName() + "\":" + simulated + ",");
												}
											}
											if (isJSON) {
												/* closing JSON line */
												JSONWriter.write("\"" + SummaryRun.KIBANA_INDEX + "id" + "\":\"" + id_ + "\"");
												JSONWriter.write("}");
												JSONWriter.newLine();
											}
											if (isCSV) {
												CSVWriter.newLine();
											}
										}
									}

								}

								// if the cultivar file is present and treatment was simulated
								if (isEval && (simulations.get(tIndex.intValue()) != null)) {
									id_ = df.format(tIndex.intValue()) + subFolder.getName();

									EvalWriter.write("{\"index\":{\"_index\":\"evaluation-" + run.getModel().toString().toLowerCase() + "-" + run.getRunName() + "\",\"_type\":\"evaluation" + "\",\"_id\":" + Long.parseLong(id_) + "}}");
									EvalWriter.newLine();
									/* printing coefficients evaluation data */
									EvalWriter.write("{");
									EvalWriter.write("\"" + SummaryRun.KIBANA_INDEX + SummaryRun.CANDIDATE_LABEL + "\":" + Integer.parseInt(subFolder.getName()) + ",");
									EvalWriter.write("\"" + SummaryRun.KIBANA_INDEX + SummaryRun.TREATMENT_LABEL + "\":" + tIndex.intValue() + ",");

									String coefficientsLine = inputCoefficients.get(Integer.parseInt(subFolder.getName()));
									if (coefficientsLine != null) {
										String[] coefficientsValues = coefficientsLine.split(" ");
										for (int i = 0; i < coefficientsValues.length; i++) {
											/* printing coefficients values in JSON */
											EvalWriter.write("\"" + SummaryRun.KIBANA_INDEX + SummaryRun.COEFFICIENT_PREFIX + inputCoeficientsNames[i] + "\":" + coefficientsValues[i] + ",");
										}
									} else {
										App.log.warning("Coeffiencients not found for run: " + subFolder.getName());
									}

									// for each variable
									for (int variableIndex = 0; variableIndex < variableNumber; variableIndex++) {
										// observed values from file T
										Map<Integer, Double> observed = new LinkedHashMap<>();
										// calculated values from PlantGro
										Map<Integer, Double> calculated = new LinkedHashMap<>();

										for (int samplingIndex = 0; samplingIndex < samplingNumber; samplingIndex++) {
											// check if data is comparable
											if (matrixObservations[samplingIndex][variableIndex] != null && matrixObservations[samplingIndex][variableIndex] != -99 && matrixObservations[samplingIndex][variableIndex] != 0 && matrixSimulations[samplingIndex][variableIndex] != null && matrixSimulations[samplingIndex][variableIndex] != -99 && matrixSimulations[samplingIndex][variableIndex] != 0) {
												// populate observed and calculated
												observed.put(samplingIndex, matrixObservations[samplingIndex][variableIndex]);
												calculated.put(samplingIndex, matrixSimulations[samplingIndex][variableIndex]);
											}
										}
										// calculate RMSE and NSE
										String tracklabel = "run:" + subFolder.getName() + " treatment:" + tIndex + " variable:" + varNames[variableIndex];
										double rmse = GoodnessEvaluator.RMSE(tracklabel, observed, calculated);
										double nse = GoodnessEvaluator.NSE(tracklabel, observed, calculated);
										// write RMSE and NSE on JSON output
										EvalWriter.write("\"" + SummaryRun.KIBANA_INDEX + varNames[variableIndex] + ".rmse\":" + rmse + ",");
										EvalWriter.write("\"" + SummaryRun.KIBANA_INDEX + varNames[variableIndex] + ".nse\":" + nse + ",");

									}
									/* closing JSON line */
									EvalWriter.write("\"" + SummaryRun.KIBANA_INDEX + "id" + "\":\"" + id_ + "\"");
									EvalWriter.write("}");
									EvalWriter.newLine();
								}
							}

						} else {
							App.log.warning(subFolder + SummaryRun.PATH_SEPARATOR + output.getName() + " not found");
						}

						subFolderIndex++;
						if (subFolderIndex % 100 == 0) {
							bar.update(subFolderIndex, subFoderTotal);
						}

					}
					bar.update(subFoderTotal - 1, subFoderTotal);

				} else {
					flagFolder = false; // Flag that there are no more folders search in
					App.log.fine("Finished gathering simulated results");
				}
			}
			if (isCSV) {
				App.log.fine("summary.csv created");
			}
			if (isJSON) {
				App.log.fine("summary.json created");
			}
			if (isEval) {
				App.log.fine("eval.json created");
			}

		} catch (FileNotFoundException e) {
			App.log.severe("File not found " + CSV.getAbsolutePath());
		} catch (IOException e) {
			App.log.severe("Error writing in " + CSV.getAbsolutePath());
		}

	}

	private void populateInputCoeficients(File cul) {

		if (cul.exists()) {
			try (BufferedReader inHead = new BufferedReader(new InputStreamReader(new FileInputStream(cul)))) {
				String line = "";
				int indexVars = 0;
				while ((line = inHead.readLine()) != null) {
					// if header populate variables names
					if (line.contains("ECO#")) {

						indexVars = line.replaceAll("ECO#", "ECO;").indexOf(";") + 1;

						line = line.split("#")[2];
						/* Leave the line with only one space of separation */
						while (line.contains("  ")) {
							line = line.replaceAll("  ", " ");
						}
						line = line.trim();

						inputCoeficientsNames = line.split(" "); // divide in spaces
					} else {
						String first = line.split(" ")[0];

						if (Utils.isNumeric(first)) {
							line = line.substring(indexVars);
							line = line.replaceAll("#", "");
							/* Leave the line with only one space of separation */
							while (line.contains("  ")) {
								line = line.replaceAll("  ", " ");
							}
							line = line.trim();
							inputCoefficients.put(Integer.parseInt(first), line);

						}
					}

				}
			} catch (IOException e) {
				App.log.severe("File not found " + App.prop.getProperty("crop.name") + ".CUL");
			}
		}
	}

	private Map<Integer, Treatment> getSimulatedMeasurements(File plantGro) {
		Map<Integer, Treatment> treatments = new LinkedHashMap<>();

		String line = "";
		String[] numbers;
		Treatment treatment = new Treatment(-1);
		// simulations in this case
		Measurements meas = new Measurements();
		int doy = 0;
		int year = 0;
		Calendar calendar = Calendar.getInstance();

		if (plantGro.exists()) {
			try (Scanner reader = new Scanner(plantGro)) {
				while (reader.hasNextLine()) {
					line = reader.nextLine();
					line = line.trim();

					/* Leave the line with only one space of separation */
					while (line.contains("  ")) {
						line = line.replaceAll("  ", " ");
					}

					numbers = line.split(" "); // divide in spaces

					if (line.contains("TREATMENT")) { // detecting the treatment
						if (treatment != new Treatment(Integer.parseInt(numbers[1]))) {
							treatment = new Treatment(Integer.parseInt(numbers[1]));
						}
					}

					// In values section
					if (numbers.length > 0 && Utils.isNumeric(numbers[0])) {

						year = Integer.parseInt(numbers[0]); // obtain the year
						doy = Integer.parseInt(numbers[1]); // obtain the DOY

						calendar.set(Calendar.DAY_OF_YEAR, doy);
						calendar.set(Calendar.YEAR, year);
						calendar.set(Calendar.HOUR, 0);
						calendar.set(Calendar.MINUTE, 0);
						calendar.set(Calendar.SECOND, 0);

						meas = new Measurements();
						for (Variable var : indexPlantGro.keySet()) {
							meas.getValues().put(var, Double.parseDouble(numbers[indexPlantGro.get(var)]));
						}
						treatment.getMeasurements().put(SummaryRun.DATE_FORMAT.format(calendar.getTime()), meas);
						treatments.put(treatment.getNumber(), treatment);
					}

				}

				// reader.close();

			} catch (FileNotFoundException e) {
				App.log.severe("File not found as " + plantGro.getAbsolutePath());
			}
		} else {
			App.log.warning("File not found " + plantGro.getAbsolutePath());
		}

		return treatments;

	}

	private Map<Integer, Treatment> getSampleMeasurements() {
		Map<Integer, Treatment> treatments = new LinkedHashMap<>();
		File fileT = new File(App.prop.getProperty("fileT.location"));
		Scanner reader;
		String line = "";
		String[] numbers;
		Treatment treatment = new Treatment(-1);
		Treatment newTreatment = new Treatment(-1);
		Measurements meas = new Measurements();
		int doy = 0;
		int year = 0;
		Calendar calendar = Calendar.getInstance();

		try {
			if (fileT.exists()) {
				reader = new Scanner(fileT);
				while (reader.hasNextLine()) {
					line = reader.nextLine();
					line = line.trim();

					/* Leave the line with only one space of separation */
					while (line.contains("  ")) {
						line = line.replaceAll("  ", " ");
					}

					numbers = line.split(" ");
					if (numbers.length > 0 && Utils.isNumeric(numbers[0])) {
						newTreatment = new Treatment(Integer.parseInt(numbers[0]));
						if (!treatment.equals(newTreatment)) {
							treatment = newTreatment;
						}
						// obtain two digits of the year
						year = Integer.parseInt(numbers[1].charAt(0) + "" + numbers[1].charAt(1));

						if (year > 50) {
							year += 1900; // 50 and higher will be 1950
						} else {
							year += 2000; // 49 and lower will be 2049
						}
						// obtain three digits of the DOY
						doy = Integer.parseInt(numbers[1].charAt(2) + "" + numbers[1].charAt(3) + "" + numbers[1].charAt(4));

						calendar.set(Calendar.DAY_OF_YEAR, doy);
						calendar.set(Calendar.YEAR, year);
						calendar.set(Calendar.HOUR, 0);
						calendar.set(Calendar.MINUTE, 0);
						calendar.set(Calendar.SECOND, 0);

						meas = new Measurements();
						// fill the values on that row for all the variables
						for (Variable var : indexFileT.keySet()) {
							// add the measurement of each variable
							meas.getValues().put(var, Double.parseDouble(numbers[indexFileT.get(var)]));
						}
						// add the sampling with all the values for that day in the treatment
						treatment.getMeasurements().put(SummaryRun.DATE_FORMAT.format(calendar.getTime()), meas);
						treatments.put(treatment.getNumber(), treatment);

					} else {
						if (numbers[0].equals("@TRNO")) {
							for (int i = 2; i < numbers.length; i++) {
								Variable var = new Variable(numbers[i]);
								if (indexPlantGro.containsKey(var)) {
									indexFileT.put(var, Integer.valueOf(i));
								} else {
									App.log.warning("The variable '" + var + "' is not an output in the PlantGro.OUT, please check this name in your file T");
								}
							}
						}
					}

				}

				reader.close();
			} else {
				App.log.severe("File T not found as " + fileT.getAbsolutePath());
			}

		} catch (FileNotFoundException e) {
			App.log.severe("File T not found as " + fileT.getAbsolutePath());
		}
		return treatments;
	}

	private Map<Variable, Integer> getIndexPlantGro(CropCode modelCode) {
		Map<Variable, Integer> vars = new LinkedHashMap<Variable, Integer>();

		switch (run.getModel()) {
		case BEAN: {
			// TODO check index
			vars.put(new Variable("LAID"), 6);
			vars.put(new Variable("CWAD"), 12);
			vars.put(new Variable("LWAD"), 7);
			vars.put(new Variable("GWAD"), 9);
			vars.put(new Variable("HIAD"), 15);
			vars.put(new Variable("L#SD"), 4);

		}

		break;
		case MAIZE: {
			vars.put(new Variable("LAID"), 6);
			vars.put(new Variable("CWAD"), 12);
			vars.put(new Variable("LWAD"), 7);
			vars.put(new Variable("GWAD"), 9);
			vars.put(new Variable("HIAD"), 15);
			vars.put(new Variable("L#SD"), 4);
			vars.put(new Variable("G#AD"), 13);
		}
		break;
		case CASSAVA: {
			vars.put(new Variable("LAID"), 11);
			vars.put(new Variable("CWAD"), 17);
			vars.put(new Variable("LWAD"), 18);
			vars.put(new Variable("HIAD"), 21);
			vars.put(new Variable("L#SD"), 7);
			vars.put(new Variable("TWAD"), 14);
			vars.put(new Variable("STWAD"), 13);
			vars.put(new Variable("HWAD"), 20);
			vars.put(new Variable("GSTD"), 6);
		}
		break;
		default: {
			App.log.warning("Crop not configurated for plantgro: " + run.getModel());
		}

		}

		return vars;
	}

}
