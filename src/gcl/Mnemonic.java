package gcl;

import java.util.HashMap;
import java.util.Map;

/** --------------------- Assembly Mnemonics and opcodes ----------------------------
 * THIS FILE SHOULD NEVER CHANGE. IT IS KEYED TO THE SAM3 Assembler.
 */
public interface Mnemonic {
	class SamOp {
		private SamOp(final int maccOpCode, final String samCode) {
			this(maccOpCode, -1, samCode);
		}

		private SamOp(int maccOpCode, int specifier, String samCode) {
			this.maccValue = maccOpCode;
			this.samCode = samCode;
			this.specifier = specifier;
			opCodes.put(samCode.trim(), this);
		}

		public String samCodeString() {
			return samCode;
		}
		
		public static SamOp get(String opCode){
			return opCodes.get(opCode);
		}
		
		public String toString(){
			return samCode.trim();
		}
		
		public int opCodeValue(){
			return maccValue;
		}
		
		public int specifier(){
			return specifier;
		}
		
		private static final Map<String, SamOp> opCodes = new HashMap<String, SamOp>();

		private final int maccValue; // the Macc op code.
		private final int specifier; // register number for jumps, mode for shifts and i/o
		private final String samCode;
	}
	

	public static final SamOp INEG = new SamOp(0, "     IN      ");
	public static final SamOp IA = new SamOp(1, "     IA      ");
	public static final SamOp IS = new SamOp(2, "     IS      ");
	public static final SamOp IM = new SamOp(3, "     IM      ");
	public static final SamOp ID = new SamOp(4, "     ID      ");
	public static final SamOp FNEG = new SamOp(5, "     FN      ");
	public static final SamOp FA = new SamOp(6, "     FA      ");
	public static final SamOp FS = new SamOp(7, "     FS      ");
	public static final SamOp FM = new SamOp(8, "     FM      ");
	public static final SamOp FD = new SamOp(9, "     FD      ");
	public static final SamOp BI = new SamOp(10, "     BI      ");
	public static final SamOp BO = new SamOp(11, "     BO      ");
	public static final SamOp BA = new SamOp(12, "     BA      ");
	public static final SamOp IC = new SamOp(13, "     IC      ");
	public static final SamOp FC = new SamOp(14, "     FC      ");
	public static final SamOp JSR = new SamOp(15, "     JSR     ");
	public static final SamOp BKT = new SamOp(16, "     BKT     ");
	public static final SamOp LD = new SamOp(17, "     LD      ");
	public static final SamOp STO = new SamOp(18, "     STO     ");
	public static final SamOp LDA = new SamOp(19, "     LDA     ");
	public static final SamOp FLT = new SamOp(20, "     FLT     ");
	public static final SamOp FIX = new SamOp(21, "     FIX     ");
	public static final SamOp JMP = new SamOp(22, 0, "     JMP     ");
	public static final SamOp JLT = new SamOp(22, 1, "     JLT     ");
	public static final SamOp JLE = new SamOp(22, 2, "     JLE     ");
	public static final SamOp JEQ = new SamOp(22, 3, "     JEQ     ");
	public static final SamOp JNE = new SamOp(22, 4, "     JNE     ");
	public static final SamOp JGE = new SamOp(22, 5, "     JGE     ");
	public static final SamOp JGT = new SamOp(22, 6, "     JGT     ");
	public static final SamOp NOP = new SamOp(22, 7, "     NOP     ");
	public static final SamOp SRZ = new SamOp(23, 0, "     SRZ     ");
	public static final SamOp SRO = new SamOp(23, 1, "     SRO     ");
	public static final SamOp SRE = new SamOp(23, 2, "     SRE     ");
	public static final SamOp SRC = new SamOp(23, 3, "     SRC     ");
	public static final SamOp SRCZ = new SamOp(23, 4, "     SRCZ    ");
	public static final SamOp SRCO = new SamOp(23, 5, "     SRCO    ");
	public static final SamOp SRCE = new SamOp(23, 6, "     SRCE    ");
	public static final SamOp SRCC = new SamOp(23, 7, "     SRCC    ");
	public static final SamOp SLZ = new SamOp(24, 0, "     SLZ     ");
	public static final SamOp SLO = new SamOp(24, 1, "     SLO     ");
	public static final SamOp SLE = new SamOp(24, 2, "     SLE     ");
	public static final SamOp SLC = new SamOp(24, 3, "     SLC     ");
	public static final SamOp SLCZ = new SamOp(24, 4, "     SLCZ    ");
	public static final SamOp SLCO = new SamOp(24, 5, "     SLCO    ");
	public static final SamOp SLCE = new SamOp(24, 6, "     SLCE    ");
	public static final SamOp SLCC = new SamOp(24, 7, "     SLCC    ");
	public static final SamOp RDI = new SamOp(25, 0, "     RDI     ");
	public static final SamOp RDF = new SamOp(25, 1, "     RDF     ");
	public static final SamOp RDBD = new SamOp(25, 2, "     RDBD    ");
	public static final SamOp RDBW = new SamOp(25, 3, "     RDBW    ");
	public static final SamOp RDOD = new SamOp(25, 4, "     RDOD    ");
	public static final SamOp RDOW = new SamOp(25, 5, "     RDOW    ");
	public static final SamOp RDHD = new SamOp(25, 6, "     RDHD    ");
	public static final SamOp RDHW = new SamOp(25, 7, "     RDHW    ");
	public static final SamOp RDCH = new SamOp(25, 8, "     RDCH    ");
	public static final SamOp RDST = new SamOp(25, 9, "     RDST    ");
	public static final SamOp RDNL = new SamOp(25, 11, "     RDNL    ");
	public static final SamOp WRI = new SamOp(26, 0, "     WRI     ");
	public static final SamOp WRF = new SamOp(26, 1, "     WRF     ");
	public static final SamOp WRBD = new SamOp(26, 2, "     WRBD    ");
	public static final SamOp WRBW = new SamOp(26, 3, "     WRBW    ");
	public static final SamOp WROD = new SamOp(26, 4, "     WROD    ");
	public static final SamOp WROW = new SamOp(26, 5, "     WROW    ");
	public static final SamOp WRHD = new SamOp(26, 6, "     WRHD    ");
	public static final SamOp WRHW = new SamOp(26, 7, "     WRHW    ");
	public static final SamOp WRCH = new SamOp(26, 8, "     WRCH    ");
	public static final SamOp WRST = new SamOp(26, 9, "     WRST    ");
	public static final SamOp WRNL = new SamOp(26, 11, "     WRNL    ");
	public static final SamOp TRNG = new SamOp(27, "     TRNG    ");
	public static final SamOp INC = new SamOp(28, "     INC   "); // increment a location or register by 1..16
	public static final SamOp DEC = new SamOp(29, "     DEC   "); // decrement a location or register by 1..16
	public static final SamOp HALT = new SamOp(31, 0, "     HALT    ");
	public static final SamOp PUSH = new SamOp(31, 1, "     PUSH    ");
	public static final SamOp POP = new SamOp(31, 2, "     POP     ");
	public static final SamOp SKIP_DIRECTIVE = new SamOp(-1, "     SKIP    ");
	public static final SamOp LABEL_DIRECTIVE = new SamOp(-1, " LABEL ");
	public static final SamOp REAL_DIRECTIVE = new SamOp(-1, "     REAL    ");
	public static final SamOp INT_DIRECTIVE = new SamOp(-1, "     INT     ");
	public static final SamOp STRING_DIRECTIVE = new SamOp(-1, "     STRING  ");
	public static final SamOp CLR_DIRECTIVE = new SamOp(23, "     CLR     ");// like a shift right of a register

}
