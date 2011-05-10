package gcl;

import java.util.HashMap;
import java.util.Iterator;

/**
 *  --------------------- SymbolTable ---------------------------------
 *  Represents a null terminated list of scopes. Each scope knows the names defined in that scope and
 *  the characteristics (semantic entries) of those names. 
 * @author jbergin
 *
 */
public class SymbolTable implements Iterable<SymbolTable.Entry>{
	
	private static final int hashsize = 8;
	private final HashMap<Identifier, Entry> storage = new HashMap<Identifier, Entry>(hashsize);
	private SymbolTable next = null;
	private static SymbolTable globalScope = null;
	//Note that the only purpose of globalScope is to permit the $s+ pragma to work
	//It has no real function in the compiler otherwise.
	private static boolean publicScope = true; // Are new defs public or private? Documentation only.
	
	
	public static final Entry NULL_ENTRY; // returned when a lookup fails

	private SymbolTable(final SymbolTable oldScope) {
		next = oldScope;
	}

	/** return a new symbol table not chained to any other. */
	public static SymbolTable unchained() {
		SymbolTable result = new SymbolTable(null);
		return result;
	}

	/** Retrieve the current maximal (deepest) scope */
	public static SymbolTable currentScope() {
		return globalScope;
	}

	/** Create a new scope chained to the current scope
	 *  @param isPublic tells if this is a public or privat scope. For documentation only.
	 *  @return a new scope chained to the original current. The new one is now current.
	 */
	public SymbolTable openScope(final boolean isPublic) {
		publicScope = isPublic;
		SymbolTable result = new SymbolTable(this);
		globalScope = result;
		return result;
	}

	/** Abandon the current scope for the previous one. Used to make the @s+ pragma
	 *  behave properly.     */
	public void closeScope() {
		globalScope = next;
	}

	/** Restore a previously saved procedure scope. Note that this has no effect
	 * on the computation other than to enable @s+ to work correctly.
	 *  @param scope the scope to be restored. It must have been previously saved.
	 */
	public void restoreProcedureScope(final SymbolTable scope) {
		globalScope = scope;
	}

	/** Factory for new symbol table entries.  Creates a new entry and 
	 * puts it into the symbol table
	 *  @param entryKind the kind of entry, variable, type,...
	    @param name the identifier to assign to this entry
	    @param item the semantic item to return when this entry is used
	    @return an entry according to the entryKind
	 */
	public Entry newEntry(final String entryKind, final Identifier name, final SemanticItem item, final SemanticItem module) {
		Entry result = new Entry(entryKind, name, item, module);
		enterIdentifier(name, result); // save it in this hashtable
		return result;
	}

	/** Lookup an identifier in this SymbolTable and the ones chained to it
		@param name some identifier to be looked up
	    @return the associated symbol table entry or null
	 */
	public Entry lookupIdentifier(final Identifier name) { // Checks initializations also
		Entry result = NULL_ENTRY;
		HashMap<Identifier, Entry> here = storage;
		SymbolTable current = this;
		boolean done = false;
		while (!done) {
			if (here.containsKey(name)) {
				result = here.get(name);
				return result;
			} else {
				CompilerOptions.message("Not yet found: " + name); // info only, not necessarily an error
			}
			if (current.next == null){
				done = true;
			}
			else {
				current = current.next;
				here = current.storage;
			}
		}
		return result;
	}
	
	/** Lookup an identifier in this SymbolTable
	@param name some identifier to be looked up
    @return the associated symbol table entry or null
 */
public Entry lookupIdentifierCurrentScope(final Identifier name) { // Checks initializations also
	Entry result = NULL_ENTRY;
	HashMap<Identifier, Entry> here = storage;
		if (here.containsKey(name)) {
			result = here.get(name);
			return result;
		} else {
			CompilerOptions.message("Not yet found: " + name); // info only, not necessarily an error
		}
	
	return result;
}

	/** Insert an identifier and its associated data into the SymbolTable
		@param name the identifier to insert (entryKind)
	    @param value the associated data
	 */
	private void enterIdentifier(final Identifier name, final Entry value) {
		if (name != null)
			storage.put(name, value);
	}

	/** Show the entire symbol table */
	public void dump() {
		boolean old = CompilerOptions.listCode;
		CompilerOptions.listCode = true;
		CompilerOptions.listCode("");
		CompilerOptions.listCode("------ Symbol Table with " + size() + " entries. ------ ");
		CompilerOptions.listCode("");
		SymbolTable current = this;
		boolean done = false;
		while (!done) {
			for(Entry entry: current) {
				CompilerOptions.listCode(entry.toString());
			}
			if (current.next == null){
				done = true;
			}
			else {
				CompilerOptions.listCode("Scope change");
				current = current.next;
			}
		}
		CompilerOptions.listCode("");
		CompilerOptions.listCode("------ Symbol Table End ------");
		CompilerOptions.listCode("");
		CompilerOptions.listCode = old;
	}

	public Iterator<Entry> iterator() {
		return storage.values().iterator();
	}

	public static void dumpAll() {
		globalScope.dump();
	}

	/** Set the symbol table at the beginning of a run
	 */
	public static void initializeSymbolTable() {
		globalScope = new SymbolTable(null);
		publicScope = true;
	}

	public int size() {
		int result = 0;
		SymbolTable another = this;
		while (another != null) {
			result += another.storage.size();
			another = another.next;
		}
		return result;
	}

	static {
		boolean messages = CompilerOptions.showMessages;
		CompilerOptions.showMessages = false;
		NULL_ENTRY = new Entry("ILLEGAL", 
				new Identifier("ILLEGAL"), 
				new SemanticError("Failed SymbolTable lookup."), new SemanticError("No Module to be a part of"));
		CompilerOptions.showMessages = messages;
		initializeSymbolTable();
	}

	// -------------- Symbol Table Entries ----- inner -------

	static class Entry {
		public Entry(final String entryKind, final Identifier itsName, final SemanticItem item, final SemanticItem module) {
			identifierValue = itsName;
			isPublic = publicScope;
			this.entryKind = entryKind;
			this.MODULE = module;
			if (item != null) {
				semanticRecord = item;
			}
		}

		public String toString() {
			return (isPublic() ? "public " : "private ") + entryKind
					+ " entry: ID = " + identifierValue + " semantic: "
					+ semanticRecord.toString();
		}
		
		public SemanticItem getModule() {
			return MODULE;
		}
		
		public SemanticItem semanticRecord() {
			return semanticRecord;
		}

		private boolean isPublic() {
			return isPublic;
		}

		public Identifier identifier() {
			return identifierValue;
		}

		private final Identifier identifierValue;
		private final String entryKind; // Documentation only
		private final boolean isPublic; // Documentation only
		private SemanticItem semanticRecord = DEFAULT_ITEM;
		private static final SemanticItem DEFAULT_ITEM;
		private static SemanticItem MODULE;
		static {
			boolean messages = CompilerOptions.showMessages;
			CompilerOptions.showMessages = false;
			DEFAULT_ITEM = new SemanticError("Error entry in symbol table.");
			CompilerOptions.showMessages = messages;
		}
	}
}