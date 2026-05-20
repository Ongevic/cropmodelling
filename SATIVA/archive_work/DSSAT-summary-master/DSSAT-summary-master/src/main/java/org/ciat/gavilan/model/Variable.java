package org.ciat.gavilan.model;

import java.util.Objects;

public class Variable {

	private String name;

	public Variable(String name) {
		super();
		this.name = name;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	@Override
	public String toString() {
		return name;
	}
	
	@Override
	public boolean equals(Object obj) {
		if (obj == null)
			return false;
		if (obj == this)
			return true;
		if (!(obj instanceof Variable))
			return false;
		Variable castedObj = (Variable) obj;
		if (castedObj.name.trim().equals(this.name.trim())) {
			return true;
		} else {
			return false;
		}
	}

	@Override
	public int hashCode() {
		return Objects.hash(name.hashCode());
	}
	
}
