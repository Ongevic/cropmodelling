package org.ciat.gavilan.model;

import java.util.logging.Formatter;
import java.util.logging.LogRecord;

public class LogFormatter extends Formatter {

	// this method is called for every log records
	@Override
	public String format(LogRecord rec) {
		StringBuffer buf = new StringBuffer(1000);
		buf.append(rec.getLevel() + "\t" + rec.getMessage() + System.lineSeparator());

		return buf.toString();
	}
}
