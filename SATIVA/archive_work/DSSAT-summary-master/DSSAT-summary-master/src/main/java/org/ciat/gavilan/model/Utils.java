package org.ciat.gavilan.model;

public class Utils {
	
	public static boolean isNumeric(String s) {
		// TODO check if format has exponential 'E'
		return s.matches("[-+]?\\d*\\.?\\d+");
	}

}
