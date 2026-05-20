package org.ciat.gavilan.model;

public enum CropCode {
	BEAN, MAIZE, CASSAVA;

	public static CropCode getModelCode(String name) {
		switch (name) {
		case "BN":
			return CropCode.BEAN;
		case "MZ":
			return CropCode.MAIZE;
		case "CS":
			return CropCode.CASSAVA;
		}
		
		return null;
	}

}
