package org.ciat.gavilan.control;

import java.text.SimpleDateFormat;
import java.util.Date;

import org.ciat.gavilan.control.OverviewWorker;
import org.ciat.gavilan.model.SummaryRun;

public class RunConfig {
	private SummaryRun run;
	

	public RunConfig(){

		/* Tag the run with the timestamp*/
		long yourmilliseconds = System.currentTimeMillis();
		SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmm");
		Date resultdate = new Date(yourmilliseconds);
		String runName = sdf.format(resultdate);
		
		String cropName =  App.prop.getProperty("crop.name");
		String cropShortName = App.prop.getProperty("crop.shortname");
		
		run = new SummaryRun(cropName, cropShortName, runName);
	
	}
	

	public OverviewWorker getOverviewWorker() {
		return new OverviewWorker(run);
	}

	public SeriesWorker getSeriesWorker() {
		return new SeriesWorker(run);
	}
	
	




}
