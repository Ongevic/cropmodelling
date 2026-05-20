package org.ciat.gavilan.model;

import java.util.Map;

import org.ciat.gavilan.control.App;

public class GoodnessEvaluator {

	public static Integer NO_VALUE = Integer.MIN_VALUE;

	public static double RMSE(String id, Map<Integer, Double> observed, Map<Integer, Double> calculated) {
		double rmse = 0.0;
		double n = 0;

		for (Integer i : observed.keySet()) {
			if (isComparable(observed.get(i)) && isComparable(calculated.get(i))) {
				rmse += Math.pow((observed.get(i) - calculated.get(i)), 2); // Sum (O-P)^2
				n++;
			}
		}

		// if there is nothing to compare return NO_VALUE
		if (n != 0) {
			rmse /= n; // Sum (O-P)^2 / N
			rmse = Math.sqrt(rmse); // SQRT (Sum (O-P)^2 / N)
		} else {
			App.log.warning("id: "+id+", RMSE can't be calculated, nothing to compare");
			return NO_VALUE;
		}

		// if it's not numeric return NO_VALUE
		if (!Utils.isNumeric(rmse + "")) {
			App.log.warning("id:" + id + ", RMSE can't be calculated: " + rmse + "; observed:" + observed + "; calculated:" + calculated);
			return NO_VALUE;
		}

		return rmse;
	}

	public static double NSE(String id, Map<Integer, Double> observed, Map<Integer, Double> calculated) {
		double nse = 1; // NSE
		double rmse = 0.0;
		double sd = 0.0; // standard deviations
		double o_avg = 0.0; // average of observed
		double n = 0;

		/* calculate the average of observed */
		for (Integer i : observed.keySet()) {
			if (isComparable(observed.get(i))) {
				o_avg += observed.get(i);
				n++;
			}
		}
		o_avg /= n; // (Sum O)/N
		/* end calculate the average of observed */

		// RMSE and SD
		for (Integer i : observed.keySet()) {
			if (isComparable(observed.get(i))) {
				rmse += Math.pow((observed.get(i) - calculated.get(i)), 2); // Sum (O-P)^2
				sd += Math.pow((observed.get(i) - o_avg), 2); // Sum (O-O_avg)^2
			}
		}

		// calculate NSE
		if (sd != 0) {
			nse = 1 - (rmse / sd);
		}

		// log calculation error
		if (nse < 0 && nse != NO_VALUE) {
			App.log.warning("id: " + id+", NSE value is under 0, RMSE: "+rmse+" NSE: " + nse + "; observed:" + observed + "; calculated:" + calculated);
		}


		return nse;
	}

	private static boolean isComparable(Double value) {
		return value != null && value != -99 && value != 0;
	}

}
