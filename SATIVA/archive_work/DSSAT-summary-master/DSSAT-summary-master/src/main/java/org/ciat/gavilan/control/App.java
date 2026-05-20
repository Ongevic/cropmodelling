package org.ciat.gavilan.control;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Properties;
import java.util.logging.ConsoleHandler;
import java.util.logging.FileHandler;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.ciat.gavilan.control.OverviewWorker;
import org.ciat.gavilan.control.RunConfig;
import org.ciat.gavilan.model.LogFormatter;

public class App {

	public static Logger log;
	public static Properties prop;
	public static final String outputsFolder = "outputs//";
	public static File config = new File("summary.properties");

	public static void main(String[] args) {
		App app = new App();
		log = app.obtainLogger();
		prop = app.obtainProperties();
		app.run();
	}

	private void run() {

		File outputs = new File(App.outputsFolder);
		outputs.mkdir();

		OverviewWorker owrk;
		SeriesWorker swrk;
		RunConfig rc = new RunConfig();

		log.fine("work started");

		boolean overview = true;
		try {
			overview = App.prop.getProperty("output.overview.csv").contains("Y");
		} catch (Exception e) {
			App.log.warning("A problem occurred in outputs configuration in " + config.getName());
		}
		if (overview) {
			owrk = rc.getOverviewWorker();
			owrk.work();
		}

		boolean summary = true;
		try {
			summary = App.prop.getProperty("output.summary.csv").contains("Y") || App.prop.getProperty("output.summary.json").contains("Y") || App.prop.getProperty("output.eval.json").contains("Y");
		} catch (Exception e) {
			App.log.warning("A problem occurred in outputs configuration in " + config.getName());
		}
		if (summary) {
			swrk = rc.getSeriesWorker();
			swrk.work();
		}

		log.fine("work finished");

	}

	private Logger obtainLogger() {
		/* Tag the log with the timestamp */
		long yourmilliseconds = System.currentTimeMillis();
		SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmm");
		Date resultdate = new Date(yourmilliseconds);
		String runName = sdf.format(resultdate);

		FileHandler fileHandler;
		ConsoleHandler consoleHandler;
		LogFormatter formatterTxt;
		Logger logger = Logger.getLogger(Logger.GLOBAL_LOGGER_NAME);
		Handler[] handlers = logger.getHandlers();
		for (Handler handler : handlers) {
			logger.removeHandler(handler);
		}
		try {
			fileHandler = new FileHandler(App.outputsFolder + runName + "_summary.log");
			consoleHandler = new ConsoleHandler();
			fileHandler.setLevel(Level.FINE);
			consoleHandler.setLevel(Level.FINE);
			formatterTxt = new LogFormatter();
			fileHandler.setFormatter(formatterTxt);
			consoleHandler.setFormatter(formatterTxt);
			logger.addHandler(fileHandler);
			logger.addHandler(consoleHandler);
			logger.setUseParentHandlers(false);
			logger.setLevel(Level.ALL);

		} catch (SecurityException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}

		return logger;
	}

	private Properties obtainProperties() {
		Properties prop = new Properties();
		if (config.exists()) {
			try (FileInputStream in = new FileInputStream(config.getName())) {
				prop.load(in);

			} catch (IOException e) {
				App.log.severe(config + "not found");
			} catch (Exception e) {
				App.log.severe("Error reading configuration in file, please check the format");
			}

			return prop;

		} else {
			App.log.severe("Configuration not found in: " + config.getAbsolutePath());
		}

		return prop;
	}
}
