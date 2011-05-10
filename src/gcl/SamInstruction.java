package gcl;

import gcl.Codegen.Mode;
import gcl.Mnemonic.SamOp;

public abstract class SamInstruction {

	abstract String samCode();
	
	
	public static class Directive extends SamInstruction{
		private SamOp opcode;
		private String directive;
		public Directive(SamOp opcode, String directive){
			this.opcode = opcode;
			this.directive = directive;
		}
		public String samCode(){
			if (opcode == null)
				return directive;
			else
				return opcode.samCodeString() + directive;
		}
	}
	
	public static class ZeroAddress extends SamInstruction{
		private SamOp opcode;
		
		public ZeroAddress(final SamOp opcode){
			this.opcode = opcode;
		}
		
		public String samCode(){
			return opcode.samCodeString();
		}
	}
	
	public static class OneAddress extends SamInstruction{
		private SamOp opcode;
		private Mode mode;
		private int base;
		private int displacement;
		
		public OneAddress(final SamOp opcode, final Mode mode, final int base, final int displacement){
			this.opcode = opcode;
			this.mode = mode;
			this.base = base;
			this.displacement = displacement;
		}
		
		public String samCode(){
			return (opcode.samCodeString() + mode.address(base, displacement));
		}
	}
	
	public static class TwoAddress extends SamInstruction{
		private SamOp opcode;
		private int reg;
		private Mode mode;
		private int base;
		private int displacement;
		private String dmemLocation;
		
		public TwoAddress(final SamOp opcode, final int reg, final Mode mode, final int base,
				int displacement){
			this.opcode = opcode;
			this.reg = reg;
			this.mode = mode;
			this.base = base;
			this.displacement = displacement;
		}
		
		public TwoAddress(final SamOp opcode, final int reg, final String dmemLocation){
			this.opcode = opcode;
			this.reg = reg;
			this.dmemLocation = dmemLocation;
		}
		
		public String samCode(){
				if (dmemLocation == null) {
				    if(opcode == Mnemonic.INC || opcode == Mnemonic.DEC){
				         int temp = reg;
				         if( reg == 0){
				                 temp = 16;
				         }
				         return (opcode.samCodeString()+ mode.address(base, displacement) + ", " + temp );
				    }
			    return (opcode.samCodeString() + 'R' + reg + ", "
			                    + mode.address(base, displacement));
				}
				return (opcode.samCodeString() + 'R' + reg + ", " + dmemLocation);
				
		}
	}
}
