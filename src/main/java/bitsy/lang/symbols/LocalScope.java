package bitsy.lang.symbols;

public class LocalScope extends Scope {
	public LocalScope(Scope parent) {
		super(parent);
	}

	public String getScopeName() {
		return "local";
	}
}
