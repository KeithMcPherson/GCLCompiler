{***********************************************************}
{*                                                         *}
{* ICS 4410                                                *}
{* Fall '87                                                *}
{*                                                         *}
{* Lynn R. Akers, Jr.                                      *}
{*                                                         *}
{* This program has been modified to run on an Mac-intel   *}
{* compatable using Free Pascal.    Joseph Bergin 2009     *}
{*                                                         *}
{* It has only been tested for MICRO, so some bugs may     *}
{* still exist.                                            *}
{*         It may not run on 64 bit architecture           *}
{*                                                         *}
{*     http://www.freepascal.org/                          *}
{*                                                         *}
{*    not implemented                                      *}
{*            WROD
			  WROW 
			  RDOD
			  RDOW
			  double word shifts beyone 16 bits 
			  
    This version fixes bugs for the float operations  
    It assumes little-endian target architecture, though 
    Macc itself is big-endian.  
    
    Cardinal type is a 32 bit integer type, probably unsigned.
    Single is a 32 bit float type. We depend on this.  *}
{***********************************************************}


{ }
{$R+}

program macc3(input, output);
uses  getopts;
{version of the MACC1 interpreter for the MACC2 byte-addressable mach }
{ Author: C.T. Wilkes (from the original MACC1 source by A.B. Maccabe)}
{                     Last modified: 84/11/23 CTW                     }
const
    MEMSIZ = Maxint;	{15 bit addresses}
    REGSIZ = 16;
    INTSIZ = maxint;

    {addressing modes}
    dreg = 0;   {direct register}
    dmem = 1;   {direct memory}
    indxd = 2;   {indexed}
    immed = 3;   {immediate}
    ireg = 4;   {indirect register}
    imem = 5;   {indirect memory}
    iindxd = 6;   {indirect indexed}
    pcrel = 7;   {Pc relative}

    {opcodes}
    INDENT = 0;
    IA = 1;
    IS = 2;
    IM = 3;
    ID = 4;
    FN = 5;
    FA = 6;
    FS = 7;
    FM = 8;
    FD = 9;
    BI = 10;
    BO = 11;
    BA = 12;
    IC = 13;
    FC = 14;
    JSR = 15;
    BKT = 16;
    LD = 17;
    STO = 18;
    LDA = 19;
    FLT = 20;
    FIX = 21;
    J = 22;
    SR = 23;
    SL = 24;
    RD = 25;
    WR = 26;
    TRNG = 27;
    INC = 28;
    DEC = 29;
    HALT = 31;

type
	real = single; {4 byte reals}
	regaddr = 0..15;
    memaddr = 0..maxint;

    word = set of 0..15;// stored in longints 32 bits

    byte = set of 0..7; // stored in longints 32 bits

    wordrange = -maxint..maxint;

    byterange = -128..127;

    icrec = record
        case boolean of
           true: ( wf: word );
           false: ( sintf: wordrange )
           end;

    bcrec = record
       case boolean of
          true: ( bytef: byte );
          false: (  hintf: byterange )
          end;

    rcrec = record
       case char of
          'a': ( rf: real );
          'c': (bits : Cardinal ) {used to unpack the real}
          end;
          
    ccrec = record
     case boolean of
       true: ( c2, c1: char );
       false: ( wf: word)
       end;
var
	option: char;
    Mem: array [memaddr] of byte; {Memory}
    Regs: array [regaddr] of word; {Registers}
    Pc: memaddr;  {Program Counter}
    Ir: word;   {Instruction Register}
    StopProgram: boolean;  {Machine halt flag}
    Lt, Eq, Gt: boolean;
    oldPc: memaddr;
    Icr: icrec;
    Rcr: rcrec;
    Ccr: ccrec;
    Bcr: bcrec;
{    Arg, Memfname, Dumpfname: packed array [1..20] of char;}
    Dumpf: file of byterange;
    MemImage: boolean;  {true iff there is a nonempty memory image}
    Trace, Dump: boolean;
    i: integer;
    RegIndex : integer ; { used to zero registers }

{intel is little-endian = low byte first. ppc is big-endian}
    {hibyte, lobyte vs lobyte, hibyte }
    { hi, b2, b3, lo vs lo, b3, b2, hi}
	{hiword, loword vs loword, hiword }
{Macc2 is big-endian -- see LD}
    procedure wordtobytes (w : word;  var hibyte, lobyte : byte);
    var i : integer;
    begin
 		lobyte := [];
 		hibyte := [];
 		for i := 0 to 7 do begin
     		if i in w then
         		lobyte := lobyte + [i];
     		if i+8 in w then
         		hibyte := hibyte + [i]
 		end {for}
    end; {procedure wordtobytes}
    
    procedure cardinaltobytes(w: cardinal; var hi, b2, b3, lo: byte);
    var i: integer;
    begin
    	lo := [];
    	b2 := [];
    	b3 := [];
    	hi := [];
    	for i := 0 to 7 do begin
    		if w mod 2 = 1 then
    			lo := lo + [i];
    		w := w div 2;
    	end;
    	for i := 0 to 7 do begin
    		if w mod 2 = 1 then
    			b3 := b3 + [i];
    		w := w div 2;
    	end;
    	for i := 0 to 7 do begin
    		if w mod 2 = 1 then
    			b2 := b2 + [i];
    		w := w div 2;
    	end;
    	for i := 0 to 7 do begin
    		if w mod 2 = 1 then
    			hi := hi + [i];
    		w := w div 2;
    	end
    end;
    
    procedure cardinaltowords(w: cardinal; var hiword, loword: word);
    var i: integer;
    begin
    	hiword := [];
    	loword := [];
    	for i := 0 to 15 do begin
    		if w mod 2 = 1 then
    			loword := loword + [i];
    		w := w div 2;
    	end;
    	for i := 0 to 15 do begin
    		if w mod 2 = 1 then
    			hiword := hiword + [i];
    		w := w div 2;
    	end
    end;
    
    procedure bytestocardinal(hi, b2, b3, lo: byte; var w:cardinal);
    var i: integer;
    begin
    	w := 0;
    	for i := 7 downto 0 do begin
    		w := 2 * w;
    		if i in hi then
    			w := w + 1;
    	end;
    	for i := 7 downto 0 do begin
    		w := 2 * w;
    		if i in b2 then
    			w := w + 1;
    	end;
    	for i := 7 downto 0 do begin
    		w := 2 * w;
    		if i in b3 then
    			w := w + 1;
    	end;
    	for i := 7 downto 0 do begin
    		w := 2 * w;
    		if i in lo then
    			w := w + 1;
    	end
    	
    end;
    
    procedure wordstocardinal(hiword, loword: word; var w:cardinal);
    var i: integer;
    begin
    	w := 0;
    	for i := 15 downto 0 do begin
    		w := 2 * w;
    		if i in hiword then
    			w := w + 1;
    	end;
    	for i := 15 downto 0 do begin
    		w := 2 * w;
    		if i in loword then
    			w := w + 1;
    	end
    end;
    

    procedure bytestoword (hibyte, lobyte : byte;  var w : word);
    var i : integer;
    begin
		 w := [];
		 for i := 0 to 7 do begin
			 if i in lobyte then
		  		w := w + [i];
			 if i in hibyte then
		  		w := w + [i+8]
		 end {for}
    end; {procedure bytestoword}

    procedure writeinst (loc, opcode, field1, field2, field3, addr2 : integer);
    (*----------------------------------------------*
    * writeinst -                                   *
    *     writes out an instruction to the listing  *
    *-----------------------------------------------*)

       procedure showreg (reg : integer);
          (* write a register symbol to the listing *)
       begin
          write ('r', reg:1)
       end; (* showreg *)

       procedure showaddr (location, mode, r2, a2 : integer);
          (* write a symbolic general address to the listing *)

          procedure showindxd (r, a : integer);
             (* write a symbolic indexed address to the listing *)
          begin
             write (a:1, '(');
             showreg (r);
             write (')')
          end; (* showindxd *)

       begin (* showaddr *)
          case mode of
             dreg :
                showreg (r2);
             dmem :
                write (a2:1);
             indxd :
                showindxd (r2, a2);
             immed :
                write ('#', a2:1);
             ireg :
                begin
                   write ('*');
                   showreg (r2)
                end;
             imem :
                write ('*', a2:1);
             iindxd :
                begin
                   write ('*');
                   showindxd (r2, a2)
                end;
             pcrel :
                write ('&', a2:1);
             else
                write ('invalid addressing mode = ', mode:1);
          end (* case *)
       end; (* showaddr *)

    begin (* writeinst *)
       write (' ':5, loc:5, ' ':5);
       case opcode of
          INDENT   : write ('in    ');
          IA   : write ('ia    ');
          IS   : write ('is    ');
          IM   : write ('im    ');
          ID   : write ('id    ');

          FN   : write ('fn    ');
          FA   : write ('fa    ');
          FS   : write ('fs    ');
          FM   : write ('fm    ');
          FD   : write ('fd    ');

          BI   : write ('bi    ');
          BO   : write ('bo    ');
          BA   : write ('ba    ');

          IC   : write ('ic    ');
          FC   : write ('fc    ');

          JSR  : write ('jsr   ');

          BKT  : write ('bkt   ');
          LD   : write ('ld    ');
          STO  : write ('sto   ');
          LDA  : write ('lda   ');

          FLT  : write ('flt   ');
          FIX  : write ('fix   ');

          J    : case field1 of
                   0 : write ('jmp   ');
                   1 : write ('jlt   ');
                   2 : write ('jle   ');
                   3 : write ('jeq   ');
                   4 : write ('jne   ');
                   5 : write ('jge   ');
                   6 : write ('jgt   ');
                   7 : write ('nop   ');
                else
                      write ('invalid jump instruction, type = ',
        field1:1, ': ');
                 end; (* case *)

          SR   : case field2 of
                   0 : write ('srz   ');
                   1 : write ('sro   ');
                   2 : write ('sre   ');
                   3 : write ('src   ');
                   4 : write ('srcz  ');
                   5 : write ('srco  ');
                   6 : write ('srce  ');
                   7 : write ('srcc  ');
                   else
                      write ('invalid sr instruction, mode = ', field2:1, ': ');
                 end; (* case *)

          SL   : case field2 of
                   0 : write ('slz   ');
                   1 : write ('slo   ');
                   2 : write ('sle   ');
                   3 : write ('slc   ');
                   4 : write ('slcz  ');
                   5 : write ('slco  ');
                   6 : write ('slce  ');
                   7 : write ('slcc  ');
                   else
                      write ('invalid sl instruction, mode = ', field2:1, ': ');
                 end; (* case *)

          RD   : case field1 of
                   0 : write ('rdi   ');
                   1 : write ('rdf   ');
                   2 : write ('rdbd  ');
                   3 : write ('rdbw  ');
                   4 : write ('rdod  ');
                   5 : write ('rdow  ');
                   6 : write ('rdhd  ');
                   7 : write ('rdhw  ');
                   8 : write ('rdch  ');
                   9 : write ('rdst  ');
                  10 : write ('rdin  ');
                  11 : write ('rdln  ');
                   else
                      write ('invalid rd instruction, fmt = ', field1:1, ': ');
                 end; (* case *)

          WR   : case field1 of
                   0 : write ('wri   ');
                   1 : write ('wrf   ');
                   2 : write ('wrbd  ');
                   3 : write ('wrbw  ');
                   4 : write ('wrod  ');
                   5 : write ('wrow  ');
                   6 : write ('wrhd  ');
                   7 : write ('wrhw  ');
                   8 : write ('wrch  ');
                   9 : write ('wrst  ');
                  11 : write ('wrnl  ');
                   else
                      write ('invalid wr instruction, fmt = ', field1:1, ': ');
                 end; (* case *)
                 
             

          TRNG : write ('trng  ');
          HALT :  case field2 of
          			0: write ('halt  ');
          			1: write ('push  ');
          			2: write ('pop   ');
                   else
                      write ('invalid control instruction, fmt = ', field2,
                      ': ');
                 end; (* case *)
          			
          INC  : write ('inc   ');
          DEC  : write ('dec   ');

          else
             write ('invalid instruction, opcode = ', opcode:1, ': ');
       end; (* case *)

       if opcode in [INDENT .. FLT, TRNG] then         (* 2 address *)
          begin
             showreg (field1);
             write (', ');
             showaddr (loc, field2, field3, addr2)
          end (* if *)
       else if ((opcode = J) and (field1 <> 7))   (* jump but not nop *)
            or ((opcode = WR) and (field1 <> 11)) (* write but not wrnl *)
            or (opcode = RD) 
            or (opcode = INC)
            or (opcode = DEC) then begin
          showaddr (loc, field2, field3, addr2);
          if opcode in [INC, DEC] then begin
             write (', ');
			 write (field3);          	
          end
       end else if opcode in [SR, SL] then       (* 1 register address *)
          begin
             showreg (field1);
             write (', ');
             write (field3)  (* amnt *)
          end else if opcode = HALT then begin
          	if field2 in [1,2] then begin
             	showreg (field1);
             	write (', ');
             	writeln(addr2)
          		end
          end(* else if *);

       writeln
    end; (* writeinst *)


    procedure writeboolean (b: boolean);
    begin
    if b then
       write ('TRUE')
    else
       write ('FALSE')
    end; (* writeboolean *)

    procedure displayregs;
    var i : integer;
    begin
    writeln ('########################################');
    write ('  Pc = ', Pc:1, '  Lt = ');
    writeboolean (Lt);
    write ('  Eq = ');
    writeboolean (Eq);
    write ('  Gt = ');
    writeboolean (Gt);
    writeln;
    for i := 0 to REGSIZ - 1 do begin
        Icr.wf := Regs[i];
        write ('  Reg[', i:2, '] = ', Icr.sintf : 5);
        if (i + 1) mod 4 = 0 then
           writeln
        end; {for}
    writeln ('########################################')
    end; (* displayregs *)


    procedure fetchword (var w : word);
    begin
    bytestoword (Mem[Pc], Mem[Pc+1], w);
    Pc := (Pc + 2) mod MEMSIZ
    end; {procedure fetchword}


    function eac(mode: integer; reg: regaddr;  var w2: integer): integer;
    {perform effective address calculation -- update Pc as needed for 2
    word instructions.}
    var
       taddr: integer;    {temporary address}
    begin
 w2 := 0;
 case mode of
     dreg: taddr := -1;			{indicates direct reg}
     dmem: begin
           fetchword (Icr.wf);
           {Icr.wf := Icr.wf - [15];}
           taddr := Icr.sintf ;
           w2 := taddr
           end;
    indxd:   begin
             fetchword (Icr.wf);
             w2 := Icr.sintf ;
             Icr.wf := Regs[reg];
             taddr := (w2 + Icr.sintf) mod MEMSIZ
             end;
    immed:   begin
             taddr := Pc;
             bytestoword (Mem[taddr], Mem[taddr+1], Icr.wf);
             w2 := Icr.sintf ;
             Pc := (Pc + 2) mod MEMSIZ
             end;
     ireg: begin
           Icr.wf := Regs[reg] {- [15]};
           taddr := Icr.sintf
           end;
     imem: begin
           fetchword (Icr.wf);
           {Icr.wf := Icr.wf - [15];}
           w2 := Icr.sintf ;
           bytestoword (Mem[w2], Mem[w2+1], Icr.wf);
           {Icr.wf := Icr.wf - [15];}
           taddr := Icr.sintf
           end;
   iindxd: begin
           fetchword (Icr.wf);
           w2 := Icr.sintf ;
           Icr.wf := Regs[reg];
           taddr := (w2 + Icr.sintf ) mod MEMSIZ;
           bytestoword (Mem[taddr], Mem[taddr+1], Icr.wf);
           {Icr.wf := Icr.wf - [15];}
           taddr := Icr.sintf
           end;
    pcrel: begin
           fetchword (Icr.wf);
           w2 := Icr.sintf ;
           taddr := (w2 + Pc) mod MEMSIZ
           end
    end; {case of mode}
 eac := taddr
 end; {function eac}

	procedure incdec(opcode, amount, amode, r2: integer; var w2: integer);
	var 
	addr: integer;
	iop1, ans: integer;
	begin
		if amount = 0 then
			amount := 16;
		addr := eac(amode, r2, w2);
		if addr >= 0 then
			bytestoword (Mem[addr], Mem[addr+1], Icr.wf)
	    else begin
			Icr.wf := Regs[r2];
		end;
		iop1 := Icr.sintf;
		if opcode = INC then begin
			ans := iop1 + amount;
		end 
		else if opcode = DEC then begin
			ans := iop1 - amount;
		end;
	    Icr.sintf := ans;
		{put it back}
		if addr >= 0 then begin
			wordtobytes(Icr.wf, Mem[addr], mem[addr+1]);
		end else begin
	    	Regs[r2] := Icr.wf;
		end
	end;

    procedure twoaddr(opcode, r1, amode, r2: integer;  var w2: integer);
    {perform two address operation}
    var
	addr: integer;
	wd: word;
	iop1, iop2, ans: integer;
	rop1, rop2: real;
	i: integer;
    begin
	addr := eac(amode, r2, w2);
	if opcode in [INDENT, IA, IS, IM, ID, IC] then begin
	    if addr >= 0 then
		bytestoword (Mem[addr], Mem[addr+1], Icr.wf)
	    else
			Icr.wf := Regs[r2];
	    iop2 := Icr.sintf ;
	    Icr.wf := Regs[r1];
	    iop1 := Icr.sintf ;
	    case opcode of
		INDENT:
		    ans := -iop2;
		IA:
		    ans := iop1 + iop2;
		IS:
		    ans := iop1 - iop2;
		IM:
		    ans := iop1 * iop2;
		ID:
			if iop2 = 0 then begin
				writeln('Integer ZeroDivide check. Exiting.');
				exit;
			end else begin
		    	ans := iop1 div iop2;
		    end;
		IC:
		    begin
			ans := iop1;    {to restore state of Regs[r1]}
			Lt := false;
			Eq := false;
			Gt := false;
			if iop1 < iop2 then
			    Lt := true
			else if iop1 = iop2 then
			    Eq := true
			else
			    Gt := true
		    end
	    end; {case of opcode}
	    Icr.sintf := ans;
	    Regs[r1] := Icr.wf
        end else if opcode in [FN, FA, FS, FM, FD, FC] then begin
			wordstocardinal(Regs[r1], Regs[(r1 + 1) mod REGSIZ], Rcr.bits);
	    rop1 := Rcr.rf;
	    if addr >= 0 then begin
			bytestocardinal(Mem[addr],  Mem[addr+1], Mem[addr+2], Mem[addr + 3] , Rcr.bits);
	    end else begin
           wordstocardinal(Regs[r2],Regs[(r2 + 1) mod REGSIZ], Rcr.bits);
	    end;
	    rop2 := Rcr.rf;
	    case opcode of
		FN:
		    rop1 := -rop2;
		FA:
		    rop1 := rop1 + rop2;
		FS:
		    rop1 := rop1 - rop2;
		FM:
		    rop1 := rop1 * rop2;
		FD:
			if (rop2 > 1.0e-6) and (rop2 < 1.0e-6) then begin
				writeln('Floating ZeroDivide check. Exiting.');
				exit;
			end else begin
		    	rop1 := rop1 / rop2;
		    end;
		FC:
		    begin
			Lt := false;
			Eq := false;
			Gt := false;
			if rop1 < rop2 then
			    Lt := true
			else if rop1 = rop2 then
			    Eq := true
			else
			    Gt := true
		    end
	    end; {case of opcode}
	    Rcr.rf := rop1;
     	cardinaltowords(Rcr.bits, Regs[r1], Regs[(r1 + 1) mod REGSIZ]);
	end else if opcode in [BI, BO, BA] then begin
	    if addr >= 0 then
		bytestoword (Mem[addr], Mem[addr+1], wd)
	    else
		wd := Regs[r2];
	    case opcode of
		BI:
		    begin
			Regs[r1] := [];
			for i := 0 to 15 do
			    if not (i in wd) then
				Regs[r1] := Regs[r1] + [i]
		    end;
		BO:
		    Regs[r1] := Regs[r1] + wd;
		BA:
		    Regs[r1] := Regs[r1] * wd
	    end {case of opcode}
	end else if opcode = JSR then begin
	    Icr.sintf := Pc;
	    Regs[r1] := Icr.wf;
	    if addr >= 0 then
		Pc := addr
	    else begin
		writeln('JSR to a Register ', Pc - 2: 1);
		StopProgram := true
	    end
	end else if opcode = BKT then
	    if addr < 0 then begin
		writeln('Address of BKT is a Register ', Pc - 2: 1);
		StopProgram := true
	    end else begin
		Icr.wf := Regs[r1];
		iop2 := Icr.sintf ;
		Icr.wf := Regs[(r1 + 1) mod REGSIZ];
		for i := 0 to Icr.sintf  - 1 do
		    Mem[(addr + i) mod MEMSIZ] := Mem[(iop2 + i) mod MEMSIZ]
	    end {if}
	else if opcode = LD then
	    if addr >= 0 then
		bytestoword (Mem[addr], Mem[addr+1], Regs[r1])
	    else 
		Regs[r1] := Regs[r2]
	else if opcode = STO then 
	    if addr >= 0 then begin
		wordtobytes (Regs[r1], Mem[addr], Mem[addr+1]);
		if Trace then begin
		    bytestoword (Mem[addr], Mem[addr+1], Icr.wf);
		    writeln ('***** value ', Icr.sintf :1,
			     ' stored at location ', addr:1)
		end
	    end else
		Regs[r2] := Regs[r1]
	else if opcode = LDA then 
	    if addr >= 0 then begin
		Icr.sintf := addr;
		Regs[r1] := Icr.wf
	    end else begin
		writeln('Address of LDA is a Register ', Pc - 2: 1);
		StopProgram := true
	    end
	else if opcode = FLT then begin
	    if addr >= 0 then
		bytestoword (Mem[addr], Mem[addr+1], Icr.wf)
	    else
		Icr.wf := Regs[r2];
	    Rcr.rf := Icr.sintf ;
     cardinaltowords(Rcr.bits, Regs[r1], Regs[(r1 + 1) mod REGSIZ] );	end else if opcode = FIX then begin
	    if addr >= 0 then begin
			bytestocardinal(Mem[addr],  Mem[addr+1], Mem[addr+2], Mem[addr+3] , Rcr.bits);
	    end else begin
           wordstocardinal(Regs[r2],Regs[(r2 + 1) mod REGSIZ], Rcr.bits);
	    end; {if}
	    Icr.sintf := round(Rcr.rf);
	    Regs[r1] := Icr.wf
	end else if opcode = TRNG then
	    if addr >= 0 then begin
		bytestoword (Mem[addr], Mem[addr+1], Icr.wf);
		iop1 := Icr.sintf ;		{lower bound}
		bytestoword (Mem[addr+2], Mem[addr+3], Icr.wf);
		iop2 := Icr.sintf ;		{upper bound}
		Icr.wf := Regs[r1];
		ans := Icr.sintf ;		{test expression}
{ ***** On next line, Icr.sintf should be ans?! ***** }
		if (ans < iop1) or (ans > iop2) then begin
		   writeln('Index expression out of bounds at ', Pc-2:1,
			   ' (expr = ', ans:1, ' lower = ', iop1:1,
			   ' upper = ', iop2:1, ')');
		   StopProgram := true
		end
	    end else begin
		writeln('Address of TRNG is a register at ', Pc-2:1);
		StopProgram := true
	    end
    end; {procedure twoaddr}


    procedure jop(jmode, amode, reg: integer;  var w2: integer);
    {perform jump operation}
    var
	addr: integer;
    begin
	addr := eac(amode, reg, w2);
	if addr < 0 then begin
	    writeln('Jump to a Register ', Pc - 2: 1);
	    StopProgram := true
	end else if jmode in [0, 1, 2, 3, 4, 5, 6, 7] then 
	    case jmode of
		0:
		    Pc := addr;
		1:
		    if Lt then
			Pc := addr;
		2:
		    if Lt or Eq then
			Pc := addr;
		3:
		    if Eq then
			Pc := addr;
		4:
		    if not Eq then 
			Pc := addr;
		5:
		    if Gt or Eq then 
			Pc := addr;
		6:
		    if Gt then
			Pc := addr;
		7:
		    {null};
	    end {case of jmode}
	else begin
	    writeln('Invalid Jump Mode ', Pc - 2: 1);
	    StopProgram := true
	end {if}
    end; {procedure jop}

    procedure srop(reg, smode, amnt: integer);
    {perform right shift}
    var
	w1, w2, w3: word;
	i, j: integer;
	flag: boolean;
    begin
	case smode of
	    0:
		begin
		    w1 := Regs[reg];
		    if amnt = 0 then
			w1 := []
		    else
			for i := 1 to amnt do begin
			    for j := 0 to 15 - i do begin
				w1 := w1 - [j];
				if j + 1 in w1 then
				    w1 := w1 + [j]
			    end; {for j}
			    w1 := w1 - [16 - i]
			end; {for i}
		    Regs[reg] := w1
		end;
	    1:
		begin
		    w1 := Regs[reg];
		    if amnt = 0 then
			w1 := [0..15]
		    else
			for i := 1 to amnt do begin
			    for j := 0 to 15 - i do begin
				w1 := w1 - [j];
				if j + 1 in w1 then
				    w1 := w1 + [j]
			    end; {for j}
			    w1 := w1 + [16 - i]
			end; {for i}
		    Regs[reg] := w1
		end;
	    2:
		begin
		    w1 := Regs[reg];
		    if amnt = 0 then 
			if 15 in w1 then
			    w1 := [0..15]
			else 
			    w1 := []
		    else
			for i := 1 to amnt do
			    for j := 0 to 14 do begin
				w1 := w1 - [j];
				if j + 1 in w1 then
				    w1 := w1 + [j]
			    end; {for j}
		    Regs[reg] := w1
		end;
	    3:
		begin				{SRC}
		    w1 := Regs[reg];
		    if amnt <> 0 then 
			for i := 1 to amnt do begin
			    flag := 0 in w1;
			    for j := 0 to 14 do begin
				w1 := w1 - [j];
				if j + 1 in w1 then
				    w1 := w1 + [j]
			    end; {for j}
			    if flag then
				w1 := w1 + [15]
			    else 
				w1 := w1 - [15]
			end; {for i}
		    Regs[reg] := w1
		end;
	    4:
		begin				{SRCZ}
		    w1 := Regs[reg];
		    w2 := Regs[(reg + 1) mod REGSIZ];
		    if amnt = 0 then begin
			w2 := w1;
			w1 := []
		    end else begin
			for i := 1 to amnt do begin
			    for j := 0 to 14 do begin
				w2 := w2 - [j];
				if j + 1 in w2 then
				    w2 := w2 + [j]
			    end; {for j}
			    if 0 in w1 then 
				w2 := w2 + [15]
			    else
				w2 := w2 - [15];
			    for j := 0 to 15 - i do begin
				w1 := w1 - [j];
				if j + 1 in w1 then
				    w1 := w1 + [j]
			    end; {for j}
			    w1 := w1 - [16 - i]
			end
		    end {for i}; {else}
		    Regs[reg] := w1;
		    Regs[(reg + 1) mod REGSIZ] := w2
		end;
	    5:
		begin				{SRCO}
		    w1 := Regs[reg];
		    w2 := Regs[(reg + 1) mod REGSIZ];
		    if amnt = 0 then begin
			w2 := w1;
			w1 := [0..15]
		    end else begin
			for i := 1 to amnt do begin
			    for j := 0 to 14 do begin
				w2 := w2 - [j];
				if j + 1 in w2 then 
				    w2 := w2 + [j]
			    end; {for j}
			    if 0 in w1 then
				w2 := w2 + [15]
			    else 
				w2 := w2 - [15];
			    for j := 0 to 15 - i do begin
				w1 := w1 - [j];
				if j + 1 in w1 then
				    w1 := w1 + [j]
			    end; {for j}
			    w1 := w1 + [16 - i]
			end
		    end {for i}; {else}
		    Regs[reg] := w1;
		    Regs[(reg + 1) mod REGSIZ] := w2
		end;
	    6:
		begin
		    w1 := Regs[reg];
		    w2 := Regs[(reg + 1) mod REGSIZ];
		    if amnt = 0 then begin
			w2 := w1;
			if 15 in w2 then 
			    w1 := [0..15]
			else
			    w1 := []
		    end else begin
			for i := 1 to amnt do begin
			    for j := 0 to 14 do begin
				w2 := w2 - [j];
				if j + 1 in w2 then
				    w2 := w2 + [j]
			    end; {for j}
			    if 0 in w1 then 
				w2 := w2 + [15]
			    else 
				w2 := w2 - [15];
			    for j := 0 to 15 - i do begin
				w1 := w1 - [j];
				if j + 1 in w1 then
				    w1 := w1 + [j]
			    end
			end {for j}
		    end {for i}; {else}
		    Regs[reg] := w1;
		    Regs[(reg + 1) mod REGSIZ] := w2
		end;
	    7:
		begin
		    w1 := Regs[reg];
		    w2 := Regs[(reg + 1) mod REGSIZ];
		    if amnt = 0 then begin
			w3 := w2;
			w2 := w1;
			w1 := w3
		    end else begin
			for i := 1 to amnt do begin
			    flag := 0 in w2;
			    for j := 0 to 14 do begin
				w2 := w2 - [j];
				if j + 1 in w2 then 
				    w2 := w2 + [j]
			    end; {for j}
			    if 0 in w1 then
				w2 := w2 + [15]
			    else
				w2 := w2 - [15];
			    for j := 0 to 14 do begin
				w1 := w1 - [j];
				if j + 1 in w1 then
				    w1 := w1 + [j]
			    end; {for j}
			    if flag then 
				w1 := w1 + [15]
			    else
				w1 := w1 - [15]
			end
		    end {for i}; {else}
		    Regs[reg] := w1;
		    Regs[(reg + 1) mod REGSIZ] := w2
		end
	end {case of smode}
    end; {procedure srop}


    procedure slop(reg, smode, amnt: integer);
    {perform left shift}
    var
	w1, w2, w3: word;
	i, j: integer;
	flag: boolean;
    begin
	case smode of
	    0:
		begin
		    w1 := Regs[reg];
		    if amnt = 0 then
			w1 := []
		    else 
			for i := 1 to amnt do begin
			    for j := 14 downto i - 1 do begin
				w1 := w1 - [j + 1];
				if j in w1 then 
				    w1 := w1 + [j + 1]
			    end; {for j}
			    w1 := w1 - [i - 1]
			end; {for i}
		    Regs[reg] := w1
		end;
	    1:
		begin
		    w1 := Regs[reg];
		    if amnt = 0 then
			w1 := [0..15]
		    else 
			for i := 1 to amnt do begin
			    for j := 14 downto i - 1 do begin
				w1 := w1 - [j + 1];
				if j in w1 then 
				    w1 := w1 + [j + 1]
			    end; {for j}
			    w1 := w1 + [i - 1]
			end; {for i}
		    Regs[reg] := w1
		end;
	    2:
		begin
		    w1 := Regs[reg];
		    if amnt = 0 then
			if 0 in w1 then 
			    w1 := [0..15]
			else
			    w1 := []
		    else 
			for i := 1 to amnt do
			    for j := 14 downto i - 1 do begin
				w1 := w1 - [j + 1];
				if j in w1 then 
				    w1 := w1 + [j + 1]
			    end; {for j}
		    Regs[reg] := w1
		end;
	    3:
		begin
		    w1 := Regs[reg];
		    if amnt <> 0 then
			for i := 1 to amnt do begin
			    flag := 15 in w1;
			    for j := 14 downto 0 do begin
				w1 := w1 - [j + 1];
				if j in w1 then 
				    w1 := w1 + [j + 1]
			    end; {for j}
			    if flag then
				w1 := w1 + [0]
			    else
				w1 := w1 - [0]
			end; {for i}
		    Regs[reg] := w1
		end;
	    4:
		begin
		    w1 := Regs[reg];
		    w2 := Regs[(reg + 1) mod REGSIZ];
		    if amnt = 0 then begin
			w1 := w2;
			w2 := []
		    end else begin
			for i := 1 to amnt do begin
			    for j := 14 downto 0 do begin
				w1 := w1 - [j + 1];
				if j in w1 then 
				    w1 := w1 + [j + 1]
			    end; {for j}
			    if 15 in w2 then
				w1 := w1 + [0]
			    else
				w1 := w1 - [0];
			    for j := 14 downto i - 1 do begin
				w2 := w2 - [j + 1];
				if j in w2 then
				    w2 := w2 + [j + 1]
			    end; {for j}
			    w2 := w2 - [i - 1]
			end
		    end {for i}; {else}
		    Regs[reg] := w1;
		    Regs[(reg + 1) mod REGSIZ] := w2
		end;
	    5:
		begin
		    w1 := Regs[reg];
		    w2 := Regs[(reg + 1) mod REGSIZ];
		    if amnt = 0 then begin
			w1 := w2;
			w2 := [0..15]
		    end else begin
			for i := 1 to amnt do begin
			    for j := 14 downto 0 do begin
				w1 := w1 - [j + 1];
				if j in w1 then
				    w1 := w1 + [j + 1]
			    end; {for j}
			    if 15 in w2 then
				w1 := w1 + [0]
			    else 
				w1 := w1 - [0];
			    for j := 14 downto i - 1 do begin
				w2 := w2 - [j + 1];
				if j in w2 then
				    w2 := w2 + [j + 1]
			    end; {for j}
			    w2 := w2 + [i - 1]
			end
		    end {for i}; {else}
		    Regs[reg] := w1;
		    Regs[(reg + 1) mod REGSIZ] := w2
		end;
	    6:
		begin
		    w1 := Regs[reg];
		    w2 := Regs[(reg + 1) mod REGSIZ];
		    if amnt = 0 then begin
			w1 := w2;
			if 0 in w2 then
			    w2 := [0..15]
			else
			    w2 := []
		    end else begin
			for i := 1 to amnt do begin
			    for j := 14 downto 0 do begin
				w1 := w1 - [j + 1];
				if j in w1 then
				    w1 := w1 + [j + 1]
			    end; {for j}
			    if 15 in w2 then
				w1 := w1 + [0]
			    else
				w1 := w1 - [0];
			    for j := 14 downto i - 1 do begin
				w2 := w2 - [j + 1];
				if j in w2 then
				    w2 := w2 + [j + 1]
			    end
			end {for j}
		    end {for i}; {else}
		    Regs[reg] := w1;
		    Regs[(reg + 1) mod REGSIZ] := w2
		end;
	    7:
		begin
		    w1 := Regs[reg];
		    w2 := Regs[(reg + 1) mod REGSIZ];
		    if amnt = 0 then begin
			w3 := w1;
			w1 := w2;
			w2 := w3
		    end else begin
			for i := 1 to amnt do begin
			    flag := 15 in w1;
			    for j := 14 downto 0 do begin
				w1 := w1 - [j + 1];
				if j in w1 then
				    w1 := w1 + [j + 1]
			    end; {for j}
			    if 15 in w2 then 
				w1 := w1 + [0]
			    else 
				w1 := w1 - [0];
			    for j := 14 downto 0 do begin
				w2 := w2 - [j + 1];
				if j in w2 then 
				    w2 := w2 + [j + 1]
			    end; {for j}
			    if flag then 
				w2 := w2 + [0]
			    else
				w2 := w2 - [0]
			end
		    end {for i}; {else}
		    Regs[reg] := w1;
		    Regs[(reg + 1) mod REGSIZ] := w2
		end
	end {case of smode}
    end; {procedure slop}


    procedure rdop(rmode, amode, reg: integer;  var w2: integer);
    {perform a read operation}
    var
	wd: word;
	flag: boolean;
	addr: integer;
	i: integer;
	ival: integer;
	ch: char;
    begin
	if rmode in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] then begin
	    addr := eac(amode, reg, w2);
	    case rmode of
		0:
		    begin			{RDI--read integer}
			read(i);
			if (i > maxint) or (i < -maxint) then begin
			    writeln('Invalid Input: RDI ', Pc - 2: 1);
			    StopProgram := true
			end else begin
			    Icr.sintf := i;
			    if addr >= 0 then
				wordtobytes (Icr.wf, Mem[addr], Mem[addr+1])
			    else
				Regs[reg] := Icr.wf
			end {else}
		    end;
		1:
		    begin			{RDF--read floating point}
			read(Rcr.rf);
			if addr >= 0 then begin
	 			cardinaltobytes(Rcr.bits, Mem[addr],  Mem[addr+1],  Mem[addr+2],  Mem[addr+3]);
			end else begin
     			cardinaltowords(Rcr.bits, Regs[reg], Regs[(reg + 1) mod REGSIZ] );
			end {else}
		    end;
		2:
		    begin			{RDBD--read binary digit}
			read(ch);
			if ch = '0' then
			    if addr >= 0 then
				Mem[addr] := Mem[addr] - [7]
			    else
				Regs[addr] := Regs[addr] - [15]
			else if ch = '1' then
			    if addr >= 0 then
				Mem[addr] := Mem[addr] + [7]
			    else
				Regs[addr] := Regs[addr] + [15]
			else begin
			    writeln('Invalid Input: RDBD ', Pc - 2: 1);
			    StopProgram := true
			end
		    end;
		3:
		    begin			{RDBW--read binary word}
			i := 15;
			flag := true;
			wd := [];
			while (i >= 0) and flag do begin
			    read(ch);
			    if ch = '1' then
				wd := wd + [i]
			    else if ch = '0' then
				wd := wd - [i]
			    else begin
				writeln('Invalid Input: RDBW ', Pc - 2: 1);
				flag := false;
				StopProgram := true
			    end; {else}
			    i := i - 1
			end; {while}
			if flag then 
			    if addr >= 0 then
				wordtobytes (wd, Mem[addr], Mem[addr+1])
			    else
				Regs[reg] := wd
		    end;
		4,                              {RDOD--read octal digit}
		5:                              {RDOW--read octal word}
		    begin
		        writeln ('Operations RDOD and RDOW not presently',
		                 'implemented, at ', Pc-2:1);
			StopProgram := true
		    end;
		6:
		    begin			{RDHD--read hex digit}
			read(ch);
			if ch in ['A'..'F', 'a'..'f', '0'..'9'] then begin
			    case ch of
				'A', 'a':
				    wd := [15, 13];
				'B', 'b':
				    wd := [15, 13, 12];
				'C', 'c':
				    wd := [15, 14];
				'D', 'd':
				    wd := [15, 14, 12];
				'E', 'e':
				    wd := [15, 14, 13];
				'F', 'f':
				    wd := [15, 14, 13, 12];
				'0':
				    wd := [];
				'1':
				    wd := [12];
				'2':
				    wd := [13];
				'3':
				    wd := [13, 12];
				'4':
				    wd := [14];
				'5':
				    wd := [14, 12];
				'6':
				    wd := [14, 13];
				'7':
				    wd := [14, 13, 12];
				'8':
				    wd := [15];
				'9':
				    wd := [15, 12]
			    end; {case of ch}
			    if addr >= 0 then begin
				{Mem[addr] := Mem[addr] - [15, 14, 13, 12];}
				{Mem[addr] := Mem[addr] + wd}
			    end else begin
				Regs[reg] := Regs[reg] - [15, 14, 13, 12];
				Regs[reg] := Regs[reg] + wd
			    end {else}
			end else begin
			    writeln('Invalid Input: RDHD ', Pc - 2: 1);
			    StopProgram := true
			end {else}
		    end;
		7:
		    begin			{RDHW--read hex word}
			i := 15;
			flag := true;
			wd := [];
			while (i >= 1) and flag do begin
			    read(ch);
			    if ch in ['A'..'F'] then
				ival := ord(ch) - ord('A') + 10
			    else if ch in ['a'..'f'] then
				ival := ord(ch) - ord('a') + 10
			    else if ch in ['0'..'9'] then 
				ival := ord(ch) - ord('0')
			    else begin
				writeln('Invalid Input: RDHW ', Pc - 2: 1);
				flag := false;
				StopProgram := true
			    end {else};
			    if flag then begin
				if ival > 7 then begin
				    wd := wd + [i];
				    ival := ival - 7
				end;
				i := i - 1;
				if ival > 3 then begin
				    wd := wd + [i];
				    ival := ival - 3
				end;
				i := i - 1;
				if ival > 1 then begin
				    wd := wd + [i];
				    ival := ival - 1
				end;
				i := i - 1;
				if ival > 0 then 
				    wd := wd + [i];
				i := i - 1
			    end {if}
			end; {while}
			if addr >= 0 then 
			    wordtobytes (wd, Mem[addr], Mem[addr+1])
			else
			    Regs[reg] := wd
		    end;
		8:
		    begin			{RDCH--read ASCII character}
			if addr >= 0 then 
			    bytestoword (Mem[addr], Mem[addr+1], Ccr.wf)
			else 
			    Ccr.wf := Regs[reg];
			read(Ccr.c1);
			if addr >= 0 then
			    wordtobytes (Ccr.wf, Mem[addr], Mem[addr+1])
			else
			    Regs[reg] := Ccr.wf
		    end;
		9:
		    begin			{RDST--read ASCII String}
			if addr < 0 then begin
			    writeln('Invalid Address: RDST ', Pc - 2: 1);
			    StopProgram := true
			end else begin
			    flag := true;
			    while not eoln do
				if flag then begin
				    flag := false;
				    read(Ccr.c1)
				end else begin
				    flag := true;
				    read(Ccr.c2);
				    wordtobytes
					(Ccr.wf, Mem[addr], Mem[addr+1]);
				    addr := (addr + 2) mod MEMSIZ
				end; {else}
			    if flag then
				Ccr.c1 := chr(0)
			    else
				Ccr.c2 := chr(0);
			    wordtobytes (Ccr.wf, Mem[addr], Mem[addr+1])
			end; {else}
			readln
		    end;
	       10:                           {RDIN--read instruction}
		    begin
			writeln('Operation RDIN not presently implemented',
				', at ', Pc-2:1);
			StopProgram := true
		    end;
	       11:                           {RDNL--read newline}
		    readln
	    end {case of rmode}
	end else begin
	    writeln('Invalid Read Mode Detected at ', Pc - 2: 1);
	    StopProgram := true
	end
    end; { rdop }


    procedure wrop(wmode, amode, reg: integer;  var w2: integer);
    {perform a write operation}
    var
	addr: integer;
	ival, bval, i: integer;
	wd: word;
	ch: char;
    begin
	if wmode in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11] then begin
	    addr := eac(amode, reg, w2);
	    case wmode of
		0:
		    begin			{WRI}
			if addr >= 0 then
			    bytestoword (Mem[addr], Mem[addr+1], Icr.wf)
			else
			    Icr.wf := Regs[reg];
			write(Icr.sintf : 1)
		    end;
		1:
		    begin			{WRF}
			if addr >= 0 then begin
 				bytestocardinal(Mem[addr],  Mem[addr+1], Mem[addr+2], Mem[addr+3] , Rcr.bits);
			end else begin
           		wordstocardinal(Regs[reg],Regs[(reg + 1) mod REGSIZ], Rcr.bits);
			end; {if}
			write(Rcr.rf)
		    end;
		2:
		    begin			{WRBD}
			if addr >= 0 then
			    bytestoword (Mem[addr], Mem[addr+1], wd)
			else
			    wd := Regs[reg];
			if 15 in wd then
			    write('1')
			else
			    write('0')
		    end;
		3:
		    begin			{WRBW}
			if addr >= 0 then 
			    bytestoword (Mem[addr], Mem[addr+1], wd)
			else 
			    wd := Regs[reg];
			for i := 0 to 15 do 
			    if i in wd then
				write('1')
			    else 
				write('0')
		    end;
		4,                              {WROD--write octal digit}
		5:                              {WROW--write octal word}
		    begin
			writeln('Operations WROD and WROW not presently',
				'implemented, at ', Pc-2:1);
			StopProgram := true
		    end;
		6:
		    begin			{WRHD}
			if addr >= 0 then 
			    bytestoword (Mem[addr], Mem[addr+1], wd)
			else 
			    wd := Regs[reg];
			bval := 8;
			ival := 0;
			for i := 15 downto 12 do begin
			    if i in wd then
				ival := ival + bval;
			    bval := bval div 2
			end; {for}
			write(ival: 1 {hex})
		    end;
		7:
		    begin			{WRHW}
			if addr >= 0 then
			    bytestoword (Mem[addr], Mem[addr+1], wd)
			else
			    wd := Regs[reg];
			bval := maxint;
			ival := 0;
			for i := 15 downto 0 do begin
			    if i in wd then
				ival := ival + bval;
			    bval := bval div 2
			end; {for}
			if ival < 4096 then
			    write('0');
			if ival < 256 then
			    write('0');
			if ival < 16 then
			    write('0');
			write(ival: 1 {hex})
		    end;
		8:				{WRCH--write character}
		    begin
			if addr >= 0 then
			    bytestoword (Mem[addr], Mem[addr+1], Ccr.wf)
			else
			    Ccr.wf := Regs[reg];
			write(Ccr.c1)
		    end;
		9:				{WRST--write string}
		    begin
			ch := ' ';
			while ord(ch) <> 0 do begin
			    if addr >= 0 then begin
				bytestoword (Mem[addr], Mem[addr+1], Ccr.wf);
				addr := (addr + 2) mod MEMSIZ
			    end else begin
				Ccr.wf := Regs[reg];
				reg := (reg + 1) mod REGSIZ
			    end; {if}
			    if ord(Ccr.c1) <> 0 then begin
				write(Ccr.c1);
				if ord(Ccr.c2) <> 0 then
				    write(Ccr.c2)
				else 
				    ch := chr(0)
			    end else
				ch := chr(0)
			end {while}
		    end;
	       11:				{WRNL--write newline}
		    writeln
	    end {case of wmode}
	end else begin
	    writeln('Invalid Write Mode Dectected at ', Pc - 1: 1);
	    StopProgram := true
	end
    end; { wrop }
    
    function reverse(x: integer):integer;
    var i, result:integer;
    wasnegative: boolean;
    begin
    	result := 0;
    	i := 0;
    	if x MOD 2 <> 0 then begin {hi bit will be on at end}
    		wasNegative := true;
    		i := 1;
    		x := x div 2;
    	end;
    	while (i < 16) and (x > 0) do begin
    		result := result * 2;
    		if x MOD 2 <> 0 then begin
    			result := result + 1
    		end;
    		x := x DIV 2;
    		i := i + 1;
    	end;
    	while i < 16 do begin
    		i := i + 1;
    		result := result * 2;
    	end;
    	if wasnegative then begin
    		Icr.sintf := result;
    		Icr.wf := Icr.wf + [15];
    		result := Icr.sintf
    	end;
    	reverse := result;
    end;

	procedure systemop(r1, amode, r2: integer;  var w2: integer);
	var i: integer;
	    temp, addr: integer;
	    wasNegative: boolean;
	    original: integer;
	begin
		original := w2;
		if amode = 0 then begin{halt}
			StopProgram := true;
			
		end else begin
			addr := eac(IMMED, 0, addr);
			bytestoword (Mem[addr], Mem[addr+1], Icr.wf);
			w2 := Icr.sintf;
		original := w2;
			if amode = 1 then begin {push}
				wasnegative := w2 < 0;
				if wasNegative then begin
					Icr.wf := Icr.wf - [15];
					w2 := Icr.sintf
				end;
				i := 0;
				while w2 > 0 do begin
					if w2 MOD 2 <> 0 then begin
						{subtract 2 from r2 and move i to *r2}
						{effect of twoaddr(IS, r2, IMMED, 0, 2);}
						Icr.wf := Regs[r1];
						Icr.sintf := Icr.sintf - 2;
						regs[r1] := Icr.wf;
						twoaddr(STO, i, IREG, r1, temp);
					end;
					w2 := w2 DIV 2;
					i := i + 1;
					
				end;
				if wasnegative then begin {missed reg 15}
						Icr.wf := Regs[r1];
						Icr.sintf := Icr.sintf - 2;
						regs[r1] := Icr.wf;
						twoaddr(STO, 15, IREG, r1, temp);
				end
			end else if amode = 2 then begin {pop}
				i := 0;
				w2 := reverse(w2); 
				wasnegative := w2 < 0;
				if wasNegative then begin
					Icr.wf := Icr.wf - [15];
					w2 := Icr.sintf
				end;
				while w2 > 0 do begin
					if w2 MOD 2 <> 0 then begin
						{subtract 2 from r2 and move i to *r2}
						{effect of twoaddr(IS, r2, IMMED, 0, 2);}
						twoaddr(LD, 15 - i, IREG, r1, temp);
						Icr.wf := Regs[r1];
						Icr.sintf := Icr.sintf + 2;
						regs[r1] := Icr.wf;
					end;
					w2 := w2 DIV 2;
					i := i + 1;
					
				end;
				if wasnegative then begin {missed reg 0}
						twoaddr(LD, 0, IREG, r1, temp);
						Icr.wf := Regs[r1];
						Icr.sintf := Icr.sintf + 2;
						regs[r1] := Icr.wf;
				end
			end else begin
				writeln('Invalid System Mode Dectected at ', Pc - 1: 1);
				StopProgram := true
			end;
		end;
		w2 := original;
	end; { systemop }

    procedure execute;
    var
	opcode: integer;
	f1: integer;
	f2: integer;
	f3: integer;
	w2: integer;
    begin
	opcode := 0;
	if 15 in Ir then
	    opcode := 16;
	if 14 in Ir then
	    opcode := opcode + 8;
	if 13 in Ir then
	    opcode := opcode + 4;
	if 12 in Ir then 
	    opcode := opcode + 2;
	if 11 in Ir then
	    opcode := opcode + 1;
	f1 := 0;
	if 10 in Ir then 
	    f1 := 8;
	if 9 in Ir then
	    f1 := f1 + 4;
	if 8 in Ir then 
	    f1 := f1 + 2;
	if 7 in Ir then
	    f1 := f1 + 1;
	f2 := 0;
	if 6 in Ir then
	    f2 := 4;
	if 5 in Ir then 
	    f2 := f2 + 2;
	if 4 in Ir then
	    f2 := f2 + 1;
	f3 := 0;
	if 3 in Ir then
	    f3 := 8;
	if 2 in Ir then 
	    f3 := f3 + 4;
	if 1 in Ir then
	    f3 := f3 + 2;
	if 0 in Ir then 
	    f3 := f3 + 1;
	w2 := 0;
	case opcode of
	    INDENT, IA, IS, IM, ID, FN, FA,
	    FS, FM, FD, BI, BO, BA, IC,
	    FC, JSR, BKT, LD, STO, LDA, FIX,
	    FLT, TRNG:
		twoaddr(opcode, f1, f2, f3, w2);
	    J:
		jop(f1, f2, f3, w2);
	    SR:
		srop(f1, f2, f3);
	    SL:
		slop(f1, f2, f3);
	    RD:
		rdop(f1, f2, f3, w2);
	    WR:
		wrop(f1, f2, f3, w2);
	    HALT:
	    if (f2 <>1) and (f2 <> 2) then
	    	StopProgram := true
	    else
	    systemop(f1, f2, f3, w2);
	    INC, DEC:
	    begin
	    incdec(opcode, f1, f2, f3, w2);
	    end;
	    30:
		begin
		    writeln('Bad opcode', Pc - 2: 1);
		    StopProgram := true
		end
	end {case};
	if Trace then begin
	   writeln ('----------------------------------------');
	   writeinst (oldPc, opcode, f1, f2, f3, w2);
	   writeln ('----------------------------------------');
	   displayregs
	end {for}
    end; {procedure execute}

    procedure rdmem;
    var
       memf: file of byterange;

 i: integer;
    begin
    assign ( memf, 'OBJ' );
    reset(memf);
    if eof(memf) then MemImage := false;
    i := 0;
    while not eof(memf) do begin
        read(memf, Bcr.hintf);
        Mem[i] := Bcr.bytef;
        i := i + 1
    end {while}
 end; {procedure rdmem}

{procedure GetCommand;}
{var}
{  I,J: Integer;}
{  S: string;}
{begin}
{  for I := 1 to ParamCount do}
{  begin}
{    S := ParamStr(I);}
{    if S[1] = '-' then}
{      for J := 2 to Length(S) do}
{        case UpCase(S[J]) of}
{          'D' : Dump:= True;}
{          'T': Trace:= True;}
{        else begin}
{          WriteLn('Invalid option: ', S[J]);}
         {Halt(1);}
{          end}
{        end}
{    else}
        { Path := S; }
{  end;}
{end;}


begin {main program}
    MemImage := true;
    Dump := false;
    option := getOpt('tT');
    if not (option in ['?', endofoptions]) then
    	Trace := true
    else
    	Trace := false;

{    getCommand;}
    rdmem;
    Lt := false;
    Eq := false;
    Gt := false;
    Pc := 0;
    StopProgram := false;
    if MemImage then
       begin
       for RegIndex := 0 to 15 do
          Regs [ RegIndex ] := [] ;
       repeat
       oldPc := Pc;
       fetchword (Ir);         {fetch the next instruction}
       execute ;
       if Trace then
          begin
          writeln ( output );
          writeln ( output, 'Press <ENTER> to contine.' );
          readln ( input );
          writeln ( output )
          end
       until StopProgram    {execute the current inst}
       end;
    if Dump then
       begin
       assign ( Dumpf, 'DUMPFILE' );
       rewrite(Dumpf );
       for i := 1 to MEMSIZ - 1 do begin
           Bcr.bytef := Mem[i];
           write(Dumpf, Bcr.hintf)
           end {for}
       end {if}
end.
