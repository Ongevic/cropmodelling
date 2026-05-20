package org.ciat.dssat_sum.control;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.PrintWriter;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Scanner;

public class SummaryRunManager {

	private String separator = "\t";
	private String model = "CSYCA046 - Cassava";
	private Map<String, String> outputVarsValues = new LinkedHashMap<>();;
	private List<String> growthVariables;
	private List<String> cropNSoilVariables;
	private String OBSERVED_TAG = "Observed ";

	public enum fileSection {
		INIT, CROP_N_SOIL, GROWTH, END
	};

	public void work() {
		DecimalFormat nf = new DecimalFormat("000000");
		cropNSoilVariables = new ArrayList<String>();
		growthVariables = new ArrayList<String>();

		model = obtainModel();

		populateVariables();



		PrintWriter pwriter;
		BufferedWriter bwriter;
		try {
			long yourmilliseconds = System.currentTimeMillis();
			SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmm");    
			Date resultdate = new Date(yourmilliseconds);
			
			File master = new File("summary_"+ sdf.format(resultdate) + ".csv");
			pwriter = new PrintWriter(master);
			bwriter = new BufferedWriter(pwriter);
			String head = "Corrida No" + separator + "TR" + separator;

			for (String var : cropNSoilVariables) {
				outputVarsValues.put(var, "");
				var = var.replaceAll(",", "");
				var = var.replaceAll(separator, "");
				head += var + separator;
			}

			for (String var : growthVariables) {
				outputVarsValues.put(var, "");
				outputVarsValues.put(OBSERVED_TAG + var, "");
				var = var.replaceAll(",", "");
				var = var.replaceAll(separator, "");
				head += var + separator;
				head += OBSERVED_TAG + var + separator;
			}

			bwriter.write(head);
			bwriter.newLine();
			boolean flagFile = true;
			boolean flagFolder = true;
			for (int folder = 0; flagFolder & flagFile; folder++) {
				File bigFolder = new File(folder + "\\");
				if (bigFolder.exists()) {
					flagFile=false;
					for (File subFolder:bigFolder.listFiles()) {

						flagFile = true;
						File cultivarOutput = new File(subFolder.getAbsolutePath()+"\\OVERVIEW.OUT");
								for (String cadena : getCultivarVariables(cultivarOutput)) {
									bwriter.write(cadena);
									bwriter.newLine();
								}
							}
							bwriter.flush();

				} else {
					flagFolder = false;
				}
			}
			pwriter.close();
			bwriter.close();
		} catch (IOException e1) {
			e1.printStackTrace();
		}

	}

	private void populateVariables() {
		switch (model) {
		case "CRGRO046 - Dry bean ": {
			cropNSoilVariables.add("Emergence");
			cropNSoilVariables.add("End Juven");
			cropNSoilVariables.add("Flower Ind");
			cropNSoilVariables.add("First Flwr");
			cropNSoilVariables.add("First Pod");
			cropNSoilVariables.add("First Seed");
			cropNSoilVariables.add("End Pod");
			cropNSoilVariables.add("Phys. Mat");
			cropNSoilVariables.add("End Leaf");
			cropNSoilVariables.add("Harv. Mat");
			cropNSoilVariables.add("Harvest");
			growthVariables.add("Anthesis day (dap)");
			growthVariables.add("Physiological maturity day (dap) ");
			growthVariables.add("Yield at harvest maturity (kg [dm]/ha)");
			growthVariables.add("Number at maturity (no/m2)");
			growthVariables.add("Unit wt at maturity (g [dm]/unit)");
			growthVariables.add("Number at maturity (no/unit)");
			growthVariables.add("Tops weight at maturity (kg [dm]/ha)");
			growthVariables.add("By-product produced (stalk) at maturity (kg[dm]/ha");
			growthVariables.add("Leaf area index, maximum");
			growthVariables.add("Harvest index at maturity");
			growthVariables.add("Leaf number per stem at maturity");

		}

			break;
		case "MZCER046 - Maize    ": {
			cropNSoilVariables.add("End Juveni");
			cropNSoilVariables.add("Floral Ini");
			cropNSoilVariables.add("Silkin");
			cropNSoilVariables.add("End Gr Fil");
			cropNSoilVariables.add("Maturity");
			cropNSoilVariables.add("Harvest");
			growthVariables.add("Anthesis day (dap)");
			growthVariables.add("Physiological maturity day (dap) ");
			growthVariables.add("Yield at harvest maturity (kg [dm]/ha)");
			growthVariables.add("Number at maturity (no/m2)");
			growthVariables.add("Unit wt at maturity (g [dm]/unit)");
			growthVariables.add("Number at maturity (no/unit)");
			growthVariables.add("Tops weight at maturity (kg [dm]/ha)");
			growthVariables.add("By-product produced (stalk) at maturity (kg[dm]/ha");
			growthVariables.add("Leaf area index, maximum");
			growthVariables.add("Harvest index at maturity");
			growthVariables.add("Leaf number per stem at maturity");

		}
			break;

		case "CSYCA046 - Cassava  ": {
			growthVariables.add("Germination  (dap)");
			growthVariables.add("Emergence    (dap)");
			growthVariables.add("1stBranch    (dap)");
			growthVariables.add("2ndBranch    (dap)");
			growthVariables.add("3rdBranch    (dap)");
			growthVariables.add("4thBranch    (dap)");
			growthVariables.add("AboveGround (kg dm/ha)");
			growthVariables.add("Product (kg dm/ha)");
			growthVariables.add("AboveGroundVegetative (kg dm/ha)");
			growthVariables.add("HarvestIndex (ratio)");
			growthVariables.add("Maximum leaf area index");
			growthVariables.add("Final leaf number (one axis)");
			growthVariables.add("Product unit wt (g dm)");
			growthVariables.add("Product number (/m2)");
			growthVariables.add("Product number (/shoot)");

		}
			break;
		default: {
			System.out.println("Crop not found: " + model);
			cropNSoilVariables.add("End Juven");
			cropNSoilVariables.add("Floral I");
			cropNSoilVariables.add("Harvest");
			growthVariables.add("Anthesis day (dap)");
			growthVariables.add("Physiological maturity day (dap) ");
			growthVariables.add("Yield at harvest maturity (kg [dm]/ha)");
			growthVariables.add("Number at maturity (no/m2)");
			growthVariables.add("Unit wt at maturity (g [dm]/unit)");
			growthVariables.add("Number at maturity (no/unit)");
			growthVariables.add("Tops weight at maturity (kg [dm]/ha)");
			growthVariables.add("By-product produced (stalk) at maturity (kg[dm]/ha");
			growthVariables.add("Leaf area index, maximum");
			growthVariables.add("Harvest index at maturity");
			growthVariables.add("Leaf number per stem at maturity");
		}
		}

	}

	private String obtainModel() {
		String model = "CSYCA046 - Cassava";
		File firstCultivarOutput =new File (((new File("0")).listFiles()[0].getAbsolutePath()+"\\OVERVIEW.OUT"));
		Scanner reader;
		try {
			if(firstCultivarOutput.exists()){
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
		System.out.println(model);
		return model;
	}

	private List<String> getCultivarVariables(File cultivarOutput) {

		Scanner reader;
		List<String> runsOutput = new ArrayList<String>();
		String cadena = "";
		String line = "";
		fileSection flag = fileSection.INIT;
		int treatment = 0;
		try {
			reader = new Scanner(cultivarOutput);
			while (reader.hasNextLine()) { // reading the whole file
				line = reader.nextLine();

				switch (flag) {
				case INIT: {
					if (line.contains("*RUN")) { // to detect each single run of a treatment
						treatment = Integer.parseInt(line.substring(7, 10).replaceAll(" ", ""));
						cadena = cultivarOutput.getParent() + separator + treatment + separator; // to print experiment run ID and the treatment
						for (String key : outputVarsValues.keySet()) {
							outputVarsValues.put(key, ""); // clear the previous values to recycle the Map
						}
					}
					if (line.contains("*SIMULATED CROP AND SOIL STATUS AT MAIN DEVELOPMENT STAGES")) { // detect section
						flag = fileSection.CROP_N_SOIL;
					}
				}
					break;
				case CROP_N_SOIL: {

					for (String var : cropNSoilVariables) {
						if (line.contains(var)) {
							outputVarsValues.put(var, line.substring(7, 12)); // get value
						}
					}
					if (line.contains("*MAIN GROWTH AND DEVELOPMENT VARIABLES")) { // detect section
						flag = fileSection.GROWTH;
					}
				}
					break;
				case GROWTH: {

					for (String var : growthVariables) {
						if (line.contains(var)) {
							//Changes values from Cassava Overwiev files
							outputVarsValues.put(var, line.substring(41, 48)); // get
																				// simulated
																				// value
							outputVarsValues.put(OBSERVED_TAG + var, line.substring(53, 58)); // get
																								// observed
																								// value

						}
					}
					// to detect the end of the treatment run
					if (line.contains(
							"--------------------------------------------------------------------------------------------------------------")) {
						flag = fileSection.END;
						for (String key : outputVarsValues.keySet()) {
							cadena += outputVarsValues.get(key) + separator;
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
			reader.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}

		return runsOutput;
	}

	/**
	 * Get the Overview files ordering by las number file name
	 * 
	 * @return
	 */
	public List<File> getCassavaOverviewFiles() {
		// Change the Path
		String path = "//ufrc//hoogenboom//lpmorenoc//cassava_dssat//Outputs//";

		String files;
		File folder = new File(path);
		File[] listOfFiles = folder.listFiles();
		List<Integer> overviewNumbers = new ArrayList<>();

		for (int i = 0; i < (listOfFiles.length); i++) {

			if (listOfFiles[i].isFile()) {
				files = listOfFiles[i].getName();
				if (files.toLowerCase().contains("overview")) {

					if (files.endsWith(".out") || files.endsWith(".OUT")) {
						String noExt = files.toLowerCase().replaceAll(".out", "");
						overviewNumbers.add(Integer.parseInt(noExt.substring(8)));

					}

				}
			}

		}

		overviewNumbers.sort((i1, i2) -> i1.compareTo(i2));
		List<File> filesList = new ArrayList<>();
		for (Integer integer : overviewNumbers) {

			File folderOrder = new File(path + "overview" + integer + ".out");
			filesList.add(folderOrder);

		}
		return filesList;
	}

}
