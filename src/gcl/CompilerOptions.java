package gcl;

import java.io.PrintWriter;

/**
 * Define variables to turn the pragmas on and off. Change this only to add new
 * compiler options (pragmas).
 */
class CompilerOptions {
	public static boolean listCode = false;
	public static boolean optimize = false;
	public static boolean showSymbolTable = false;
	public static boolean showMessages = false;

	private static PrintWriter out; // Set by main to the Scanner's listing file.
	private static Codegen codegen; // set by main

	public static void listCode(final String samStatement) {
		if (listCode) {
			out.println(samStatement);
		}
	}

	public static void message(final String message) {
		if (showMessages) {
			codegen.genCodeComment(message);
		}
	}

	public static void genHalt() {
		codegen.gen0Address(Mnemonic.HALT);
	}

	public static void printAllocatedRegisters() {
		codegen.printAllocatedRegisters();
	}

	public static void init(final PrintWriter outFile, final Codegen cg) {
		out = outFile;
		codegen = cg;
	}
	
	private CompilerOptions(){ // not instantiable
		//nothing
	}

}
