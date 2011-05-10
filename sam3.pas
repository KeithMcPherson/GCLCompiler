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
{*                                                         *}
{*         It may not run on 64 bit architecture           *}
{*                                                         *}
{*     http://www.freepascal.org/                          *}
{*                                                         *}
{***********************************************************}

{ }
{$R+}

program sam3(input, output,memf,InFile); uses getopts;
{version of the SAM assembler for the MACC2 byte-addressable machine}
{        Author: C.T. Wilkes (from original by A.B. Maccabe)        }
{                   Last modified: 84/11/26 CTW                     }
type
    word = set of 0..15;

    byte = set of 0..7;

    wordrange = -maxint .. maxint ;

    byterange = -128..127;

    opkind = (OIN, IA, IS, IM, IDENT, FN, FA, FS, FM, FD, BI, BO, BA, IC,
	FC, JSR, BKT, LD, STO, LDA, FLT, FIX, J, SR, SL, RD, WR, TRNG, DEC, INC, HALT, PUSH, POP,
	NOP, CLR, REALDIR, STRINGDIR, INTDIR, SKIPDIR, LABELDIR);

    errorkind = (noerr, unkopname, badregaddr, badgenaddr, badint,
                 badreal, badstr, badname, illregaddr, illimedaddr, badshftamt,
                 badstring, invalidname);
    warnkind = (longname, missingR, missingnum, missingrp, missingcomma,
                namedefined, badskip, esctooshort, strtooshort, textfollows);

    icrec = record
       case boolean of
          true:  ( wdf: word );
          false: ( sintf: wordrange )
          end;
          
    cardrec = record
       case boolean of
          true:  ( wdf: word );
          false: ( sintf: cardinal )
          end;

    bcrec = record
       case boolean of
          true: ( bytef: byte );
          false: ( hintf: byterange )
          end;

    stringtype = packed array [ 1 .. 25 ] of char ;



    name = array [1..7] of char;

    symptr = ^ symrec;
    symrec = record
       id: name;
       left, right: symptr;
       patch, loc: integer
       end;

var
    Inop, Iaop, Isop, Imop, Idop, Fnop, Faop, Fsop, Fmop, Fdop,
    Biop, Boop, Baop, Icop, Fcop, Jsrop, Bktop, Ldop, Stoop, Ldaop,
    Fltop, Fixop, Jop, Srop, Slop, Rdop, Wrop, Trngop, Incop, Decop,
    Haltop: word;

    InFile : text ;
    option: char;

    Saved: boolean;  {flag for one character lookahead}
    Ch: char;   {Current character from the input}

    Mem: array [0..maxint] of byte; {Memory Image being created}
    Lc: 0..maxint;  {Location Counter}
    memf: file of byterange;    {File for the memory image}

    Symbols: symptr;
    Line: integer;  {Number of the current input line}
    Listing: boolean;

    Error: errorkind;
    Errs: boolean;
    Warning: boolean;
    Morewarn: boolean;
    Warns: array [1..10] of warnkind;
    Windex: integer;

    Icr: icrec;{Integer/Word Conversion Record}
    Bcr: bcrec;{Halfint/Byte Conversion Record}
    Ccr: cardrec;
    i: integer;{loop index}

{   Arg, Memfname, Srcfname: stringtype;}



    procedure wordtobytes (w : word;  var hibyte, lobyte : byte);
    var i : integer;
    begin
    lobyte := [];
    hibyte := [];
    for i := 0 to 7 do
       begin
       if i in w then
          lobyte := lobyte + [i];
       if i+8 in w then
           hibyte := hibyte + [i]
       end {for}
    end; {procedure wordtobytes}


    procedure bytestoword (hibyte, lobyte : byte;  var w : word);
    var i : integer;
    begin
    w := [];
    for i := 0 to 7 do
       begin
       if i in lobyte then
          w := w + [i];
       if i in hibyte then
          w := w + [i+8]
       end {for}
    end; {procedure bytestoword}


    procedure insertmem (w : word);
    var lobyte, hibyte : byte;
    begin
    wordtobytes (w, hibyte, lobyte);
    Mem[Lc] := hibyte;
    Mem[Lc+1] := lobyte;
    Lc := Lc + 2
    end; {procedure insertmem}

    procedure checktab(cur: symptr);
    begin
    if cur <> nil then
       begin
       checktab(cur^.left);
       if cur^.loc < 0 then
          begin
          Warning := true;
          writeln('WARNING -- ', cur^.id, ' Undefined');
          end;
       checktab(cur^.right)
       end {if}
    end; {procedure checktab}


    procedure warn (w: warnkind);
    begin
    if not Morewarn then
       Windex := 1;
    Morewarn := true;
    Warns[Windex] := w;
    Windex := Windex + 1
    end; {procedure warn}


    procedure printwarn;
    var
        i: integer;
    begin
    write('WARNING -- ');
    case Warns[1] of
     textfollows: write('Text follows instruction');
     esctooshort: write('Need 3 digits to specify an unprintable character');
     strtooshort: write('Missing " in string');
     badskip: write('Skip value must be positive, Skip directive ignored');
     namedefined: write('Name already defined, earlier definition lost');
     longname: write('Name too long, only 7 characters used');
     missingR: write('Missing R in Register Address');
     missingnum: write('Missing Number in Register Address (0 assumed)');
     missingrp: write('Missing ")" in Indexed Address');
     missingcomma: write('Missing ","')
 end; {case}
 writeln(' on line ', Line: 1);

 for i := 2 to Windex - 1 do
     Warns[i - 1] := Warns[i];
 Windex := Windex - 1;
 if Windex <= 1 then
     Morewarn := false
    end; {procedure printwarn}


    procedure inregaddr (var w: word; reg: integer; hbit: integer);
    {Insert a register address into a word}
    begin
    if reg > 7 then begin
        w := w + [hbit];
        reg := reg - 8
    end; {if reg > 7}
    hbit := hbit - 1;
    if reg > 3 then begin
       w := w + [hbit];
       reg := reg - 4
       end; {if reg > 3}
    hbit := hbit - 1;
    if reg > 1 then begin
       w := w + [hbit];
       reg := reg - 2
       end; {if reg > 1}
    hbit := hbit - 1;
    if reg > 0 then
       w := w + [hbit]
    end; {procedure inregaddr}


    procedure getch;
    {Get a character from the input -- character may have been saved}
    begin
 if not Saved then
     if eof ( InFile ) then
        Ch := '%'
     else if not eoln ( InFile ) then
        begin
        repeat
          read(InFile, Ch);
          if Listing then
            write(Ch)
        until (Ch <> ' ') and (Ch <> chr(9)) or eoln ( InFile );
        if Ch = '%' then begin
           while not eoln ( InFile ) do
              begin
              read(InFile, Ch);
              if Listing then
              write(Ch)
              end; {while}
           Ch := '%'
           end
       end
          else
          Ch := '%'
   else
     Saved := false
     end; {procedure getch}


    procedure scanname(var id: name);
    var
       i: integer;
    begin
    for i := 1 to 7 do
       id[i] := ' ';
    i := 1;
    while (Ch in ['a'..'z', 'A'..'Z', '0'..'9','$']) and (i <= 7) do
       begin
       id[i] := Ch;
       i := i + 1;
       getch
       end; {while}
    if Ch in ['a'..'z', 'A'..'Z', '0'..'9','$'] then
       warn(longname);
    while Ch in ['a'..'z', 'A'..'Z', '0'..'9','$'] do
       getch;
    Saved := true
    end; {procedure scanname}


    function findname(id: name): symptr;
    var
       temp: symptr;
       found: boolean;
    begin
    temp := Symbols;
    found := false;
    while not found and (temp <> nil) do
       if temp^.id = id then
          found := true
       else if temp^.id > id then
          temp := temp^.left
       else
          temp := temp^.right;
    findname := temp
    end; {function findname}


    function inname(id: name): symptr;
    var
       cur, prev: symptr;
    begin
    cur := Symbols;
    prev := nil;
    while cur <> nil do
       begin
       prev := cur;
       if cur^.id > id then
          cur := cur^.left
       else
          cur := cur^.right
       end; {while}
    new(cur);
    cur^.left := nil;
    cur^.right := nil;
    cur^.id := id;
    if prev = nil then
       Symbols := cur
    else if prev^.id > id then
       prev^.left := cur
    else
       prev^.right := cur;
    inname := cur
    end; {function inname}


    procedure scanstr;
    type
       ccrec = record
         case boolean of
           true: ( wf: word  );
           false: ( c2, c1: char ) {Inverted Bytes!!!}
           end;
    var
       one:boolean;
       ccr: ccrec;
       ival: integer;
    begin
    one := true;
    getch;
    if Ch = '"' then
       begin
       if not eoln ( InFile ) then
          begin
          read(InFile, Ch);
          if Listing then
             write(Ch)
          end; {if}
       while (Ch <> '"') and not eoln ( InFile ) do
          begin
          if Ch = ':' then
             begin
             if not eoln ( InFile ) then
                begin
                read(InFile, Ch);
                if Listing then
                   write(Ch);
                if Ch in ['0'..'9'] then
                   begin
                   ival := ord(Ch) - ord('0');
                   if not eoln ( InFile ) then
                      begin
                      read(InFile, Ch);
                      if Listing then
                      write(Ch);
                      if Ch in ['0'..'9'] then
                         begin
                         ival := ival * 10 + ord(Ch) - ord('0');
                         if not eoln ( InFile ) then
                            begin
                            read(InFile, Ch);
                            if Listing then
                               write(Ch);
                            if Ch in ['0'..'9'] then
                               ival := ival * 10 + ord(Ch) - ord('0')
                            else
                               warn(esctooshort)
                            end
                         else
                            warn(esctooshort)
                         end
                      else
                         warn(esctooshort)
                      end
                   else
                      warn(esctooshort);
                   Ch := chr(ival)
                   end
                end
             else
                warn(esctooshort)
             end;
             if one then
                begin
                one := false;
                ccr.c1 := Ch
                end
             else
                begin
                one := true;
                ccr.c2 := Ch;
                insertmem (ccr.wf)
                end; {else}
             if not eoln ( InFile ) then
                begin
                read(InFile, Ch);
                if Listing then
                   write(Ch)
                end {if}
          end; {while}
       if one then
          ccr.c1 := chr(0)
       else
         ccr.c2 := chr(0);
       insertmem (ccr.wf);
       if Ch <> '"' then
          warn(strtooshort)
       end
    else
      Error := badstring
    end; {procedure scanstr}


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
    
    procedure scanreal(var w1, w2: word);
    type
        bytetype = set of 0..7;
        real = single;


        rcrec = record
           case boolean of
              true : ( rf : real ) ;
              false : ( bits : Cardinal )
              end;

    var
       rcr: rcrec;
       dval: real;
       isNegative: boolean;

    begin
    rcr.rf := 0.0;
    isNegative := false;
    getch;
    if Ch = '-' then begin
    	isNegative := true;
    	getch;
    end;
    while Ch in ['0'..'9'] do
       begin
       rcr.rf := rcr.rf * 10 + ord(Ch) - ord('0');
       getch
       end; {while}
    if Ch = '.' then
       begin
       getch;
       dval := 10.0;
       while Ch in ['0'..'9'] do
          begin
          rcr.rf := rcr.rf + (ord(Ch) - ord('0')) / dval;
          dval := dval * 10.0;
          getch
          end {while}
       end
    else
       Saved := true;
    if isNegative then
    	rcr.rf := -rcr.rf;
    cardinaltowords(rcr.bits, w1, w2);
{    bytestoword ( rcr.mf.byte1, rcr.mf.byte4, w1 );}
{    bytestoword ( rcr.mf.byte5, rcr.mf.byte6, w2 )}
    end; {procedure scanreal}


    procedure scanint(var w: word);
    {Get an integer from the input stream}
    var
       temp: integer;
       neg: boolean;
    begin
    neg := false;
    temp := 0;
    getch;
		if Ch in ['-', '+'] then
		   begin
		   if Ch = '-' then
		   neg := true;
		   getch
		   end; {if Ch in ['-', '+']}
		while Ch in ['0'..'9'] do
		   begin
		   temp := temp * 10 + ord(Ch) - ord('0');
		   getch
		   end; {while}
		Saved := true;    {Note the lookahead}
		if neg then
		   temp := -temp;
		if (temp > maxint) or (temp < -maxint) then
		   Error := badint
		else begin
		   Icr.sintf := temp;
		   w := Icr.wdf
		end
    end; { scanint }
    
    procedure shiftLeft(var w:word);
    {Shift the bits of a word to the left. Multiply by 2 effectively.}
    var i: integer;
    begin
    	for i := 14 downto 0 do begin
    		if i in w then begin
    			w := w - [i] + [i + 1];
    		end
    	end
    end;

    procedure scancardinal(var w: word);
    {Get an unsigned integer from the input stream}
    var
       temp: cardinal;
       hasOnes:boolean;
    begin
		getch;
		if Ch = '^' then begin {binary}
			w := [];
			hasOnes := false;
			getch;
			while Ch in ['0','1'] do begin
				if hasOnes then
					shiftLeft(w);
				if Ch = '1' then begin
					w := w + [0];
					hasOnes := true;
				end;
				getch
			end;
			Saved := true;    {Note the lookahead}
		end else begin {decimal}
    	temp := 0;
		while (Ch in ['0'..'9']) and (temp <= 65535) do begin
		   temp := temp * 10 + ord(Ch) - ord('0');
		   getch;
		   end; {while}
		   Saved := true;    {Note the lookahead}
		   Ccr.sintf := temp;
		   w := Ccr.wdf
       end
    end; { scancardinal }


    function getregaddr: integer;
    {Get a register address from the input stream}
    var
       temp: integer;

    begin
		getch;
		if Ch = 'R' then
		   getch
		else
		   warn(missingR);
		if Ch in ['0'..'9'] then
		   begin  {Check first digit}
		   temp := ord(Ch) - ord('0');
		   getch;
		   if Ch in ['0'..'9'] then 		{Check for two digits}
			  temp := temp * 10 + ord(Ch) - ord('0')
		   else
			  Saved := true;
		   if temp > 15 then
			  Error := badregaddr
		   end
		else  {if Ch is a digit}
		   warn(missingnum);
	
		getregaddr := temp
    end; {function getregaddr}


    procedure getgenaddr (op: opkind; var w1, w2: word; var flag: boolean);
    var
        reg: integer;
        id: name;
        idrec: symptr;

    begin
    flag := false;
    getch;
    if Ch = '*' then
       begin
       w1 := w1 + [6];
       getch
       end; {if Ch = '*'}

    if Ch in ['a'..'z', 'A'..'Q', 'S'..'Z','$'] then
       begin
       flag := true;
       scanname(id);
       idrec := findname(id);
       if idrec = nil then
          begin
          idrec := inname(id);
          idrec^.loc := -1;
          idrec^.patch := Lc + 2;
          Icr.sintf := -1
          end
       else if idrec^.loc = -1 then
          begin
          Icr.sintf := idrec^.patch;
          idrec^.patch := Lc + 2
          end
       else
          Icr.sintf := idrec^.loc;
       w2 := Icr.wdf;
       getch;
       if Ch = '(' then
          begin
          w1 := w1 + [5];
          reg := getregaddr;
          if Error = noerr then
             begin
             inregaddr(w1, reg, 3);
             getch;
             if Ch <> ')' then
                warn(missingrp)
             end {if Error in register address}
          end
        else     {Ch <> '('}
           w1 := w1 + [4]
       end (* Letter other than 'R' *)
    else if Ch in ['0'..'9'] then
       begin
       Saved := true;
       w1 := w1 + [4];
       flag := true;
       scanint(w2)
       end
    else if Ch in ['R', '#', '-', '+', '&'] then
       case Ch of
          'R' :  begin   {direct register}
                 flag := false;
                 Saved := true;
                 reg := getregaddr;
                 inregaddr(w1, reg, 3);
                 if (op in [JSR, BKT, LDA, J]) and not (6 in w1) then
                    Error := illregaddr
                 end;
          '#' : begin   {immediate}
                flag := true;
                if 6 in w1 then
                   Error := badgenaddr
                else if op in [FN, FA, FS, FM, FD, FC, FIX,
                               JSR, BKT, STO, J, RD, TRNG] then
                   Error := illimedaddr
                else if w1 = Wrop + [7] then
                   Error := illimedaddr
                else if w1 = Wrop + [10, 7] then
                   Error := illimedaddr
                else
                   begin
                   w1 := w1 + [4, 5];
                   scanint(w2)
                   end {else}
                end;
     '-', '+' : begin   {indexed}
                w1 := w1 + [5];
                flag := true;
                if Ch = '-' then
                   Saved := true;
                scanint(w2);
                getch;
                if Ch = '(' then
                   begin
                   reg := getregaddr;
                   if Error = noerr then
                      begin
                      inregaddr(w1, reg, 3);
                      getch;
                      if Ch <> ')' then
                         warn(missingrp)
                      end {if Error in register address}
                   end
                else   {Ch <> '('}
                   Error := badgenaddr
                end;
          '&' : begin
                flag := true;
                if 6 in w1 then
                   Error := badgenaddr
                else
                   begin
                   w1 := w1 + [4, 5, 6];
                   scanint(w2)
                   end
                end
     end {case of Ch}
 else
     Error := badgenaddr
    end; {procedure getgenaddr}


    procedure getBop(var op: opkind; var wd: word);
    {Get an operator or directive name that begins with 'B'}
    begin
    getch;
 if Ch in ['A', 'I', 'K', 'O'] then
     case Ch of
  'A':
      begin
   op := BA;
   wd := Baop
      end;
  'I':
      begin
   op := BI;
   wd := Biop
      end;
  'K':
      begin
   getch;
   if Ch = 'T' then begin
       op := BKT;
       wd := Bktop
   end else   {Ch <> 'T'}
       Error := unkopname
      end;
  'O':
      begin
   op := BO;
   wd := Boop
      end
     end {case of Ch}
 else      {character does not legally follow `B'}
     Error := unkopname
    end; {procedure getBop}
    
    procedure getDop(var op: opkind; var wd: word);
    {Get an operator or directive name that begins with 'D'}
    begin
    	getch;
    	if Ch = 'E' then begin
    		getch;
    		if Ch = 'C' then begin
    			op := DEC;
    			wd := Decop
    		end else
       			Error := unkopname
    	end else
    	Error := unkopname
    end;


    procedure getFop(var op: opkind; var wd: word);
    {Get an operator or directive name that begins with 'F'}
    begin
	getch;
	if Ch in ['A', 'C', 'D', 'I', 'L', 'M', 'N', 'S'] then 
	    case Ch of
		'A':
		    begin
			op := FA;
			wd := Faop
		    end;
		'C':
		    begin
			op := FC;
			wd := Fcop
		    end;
		'D':
		    begin
			op := FD;
			wd := Fdop
		    end;
		'I':
		    begin
			getch;
			if Ch = 'X' then begin
			    op := FIX;
			    wd := Fixop
			end else 		{Ch <> 'X'}
			    Error := unkopname
		    end;
		'L':
		    begin
			getch;
			if Ch = 'T' then begin
			    op := FLT;
			    wd := Fltop
			end else 		{Ch <> 'T'}
			    Error := unkopname
		    end;
		'M':
		    begin
			op := FM;
			wd := Fmop
		    end;
		'N':
		    begin
			op := FN;
			wd := Fnop
		    end;
		'S':
		    begin
			op := FS;
			wd := Fsop
		    end
	    end {case of Ch}
	else 					{character does not legally follow `F'}
	    Error := unkopname
    end; {procedure getFop}


    procedure getIop(var op: opkind; var wd: word);
    {Get an operator or directive name that begins with 'I'}
    begin
	getch;
	if Ch in ['A', 'C', 'D', 'M', 'N', 'S'] then 
	    case Ch of
		'A':
		    begin
			op := IA;
			wd := Iaop
		    end;
		'C':
		    begin
			op := IC;
			wd := Icop
		    end;
		'D':
		    begin
			op := IDENT;
			wd := Idop
		    end;
		'M':
		    begin
			op := IM;
			wd := Imop
		    end;
		'N':
		    begin
			getch;
			if Ch = 'T' then 
			    op := INTDIR
			else if Ch = 'C' then begin
				op := INC;
				wd := Incop
			end else
			begin
			    op := OIN;
			    wd := Inop;
			    Saved := true
			end
		    end;
		'S':
		    begin
			op := IS;
			wd := Isop
		    end
	    end {case of Ch}
	else 					{character does not legally follow `I'}
	    Error := unkopname
    end; {getIop}


    procedure getJop(var op: opkind; var wd: word);
    {Get an operator or directive name that begins with 'J'}
    begin
	getch;
	if Ch in ['E', 'G', 'L', 'M', 'N', 'S'] then begin
	    op := J; {most are simple jumps--except JSR!!}
	    case Ch of
		'E':
		    begin
			getch;
			if Ch = 'Q' then
			    wd := Jop + [7, 8]
			else 
			    Error := unkopname
		    end;
		'G':
		    begin
			getch;
			if Ch = 'E' then
			    wd := Jop + [7, 9]
			else if Ch = 'T' then
			    wd := Jop + [8, 9]
			else 
			    Error := unkopname
		    end;
		'L':
		    begin
			getch;
			if Ch = 'E' then 
			    wd := Jop + [8]
			else if Ch = 'T' then
			    wd := Jop + [7]
			else
			    Error := unkopname
		    end;
		'M':
		    begin
			getch;
			if Ch = 'P' then 
			    wd := Jop
			else
			    Error := unkopname
		    end;
		'N':
		    begin
			getch;
			if Ch = 'E' then
			    wd := Jop + [9]
			else 
			    Error := unkopname
		    end;
		'S':
		    begin
			getch;
			if Ch = 'R' then begin
			    op := JSR;
			    wd := Jsrop
			end else 		{Ch <> 'R'}
			    Error := unkopname
		    end
	    end {case of Ch}
	end else 				{Ch not in ['E','G',...]}
	    Error := unkopname
    end; {procedure getJop}


    procedure getLop(var op: opkind; var wd: word);
    {Get an operator or directive name that begins with 'L'}
    begin
	getch;
	if Ch in ['A', 'D'] then
	    case Ch of
		'A':
		    begin
			getch;
			if Ch = 'B' then begin
			    getch;
			    if Ch = 'E' then begin
				getch;
				if Ch = 'L' then
				    op := LABELDIR
				else
				    Error := unkopname
			    end else
				Error := unkopname
			end else
			    Error := unkopname
		    end;
		'D':
		    begin
			getch;
			if Ch = 'A' then begin
			    op := LDA;
			    wd := Ldaop
			end else begin
			    op := LD;
			    wd := Ldop;
			    Saved := true
			end
		    end
	    end {case Ch of}
	else
	    Error := unkopname
    end; {procedure getLop}

	procedure getPop(var op: opkind; var wd: word);
    {Get an operator or directive name that begins with 'P'}
	begin
		wd := HALTop;
		getch;
		if Ch = 'U' then begin
			getch;
			if Ch = 'S' then begin
				getch;
				if Ch = 'H' then begin
					op := PUSH;
					wd := wd + [4]
				end else
					Error := unkopname;
			end else
				Error := unkopname
		end else if Ch = 'O' then begin
			getch;
			if Ch = 'P' then begin
					op := POP;
					wd := wd + [5]
			end else 
				Error := unkopname
		end else 				
	    Error := unkopname

	end;

    procedure getRop(var op: opkind; var wd: word);
    {Get an operator or directive name that begins with 'R'}
    begin
	getch;
	if Ch = 'D' then begin
	    op := RD;
	    getch;
	    if Ch in ['B', 'C', 'F', 'H', 'I', 'N', 'O', 'S'] then
		case Ch of
		    'B':
			begin
			    getch;
			    if Ch = 'D' then
				wd := Rdop + [8]
			    else if Ch = 'W' then 
				wd := Rdop + [7, 8]
			    else
				Error := unkopname
			end;
		    'C':
			begin
			    getch;
			    if Ch = 'H' then
				wd := Rdop + [10]
			    else 
				Error := unkopname
			end;
		    'F':
			wd := Rdop + [7];
		    'H':
			begin
			    getch;
			    if Ch = 'D' then
				wd := Rdop + [8, 9]
			    else if Ch = 'W' then 
				wd := Rdop + [7, 8, 9]
			    else
				Error := unkopname
			end;
		    'I':
			wd := Rdop;
		    'N':
			begin
			    getch;
			    if Ch = 'L' then
			        wd := Rdop + [7, 8, 10]
			    else
				Error := unkopname
			end;
		    'O':
			begin
			    getch;
			    if Ch = 'D' then
				wd := Rdop + [9]
			    else if Ch = 'W' then
				wd := Rdop + [7, 9]
			    else
				Error := unkopname
			end;
		    'S':
			begin
			    getch;
			    if Ch = 'T' then
				wd := Rdop + [7, 10]
			    else
				Error := unkopname
			end
		end {case of Ch}
	    else 				{Ch not in ['B','C',...]}
		Error := unkopname
	end else if Ch = 'E' then begin
	    getch;
	    if Ch = 'A' then begin
		getch;
		if Ch = 'L' then 
		    op := REALDIR
		else
		    Error := unkopname
	    end else 				{Ch <> 'A'}
		Error := unkopname
	end else 				{Ch <> 'E'}
	    Error := unkopname
    end; {procedure getRop}


    procedure getSop(var op: opkind; var wd: word);
    {Get an operator or directive name that begins with 'S'}
    begin
	getch;
	if Ch in ['K', 'L', 'R', 'T'] then 
	    case Ch of
		'K':
		    begin
			getch;
			if Ch = 'I' then begin
			    getch;
			    if Ch = 'P' then
				op := SKIPDIR
			    else
				Error := unkopname
			end else 		{Ch <> 'I'}
			    Error := unkopname
		    end;
		'L':
		    begin
			getch;
			if Ch in ['C', 'E', 'O', 'Z'] then begin
			    op := SL;
			    case Ch of
				'C':
				    begin
					getch;
					if Ch in ['C', 'E', 'O', 'Z'] then 
					    case Ch of
						'C':
						    wd := Slop + [4, 5, 6];
						'E':
						    wd := Slop + [5, 6];
						'O':
						    wd := Slop + [4, 6];
						'Z':
						    wd := Slop + [6]
					    end {case of Ch}
					else begin
					    Saved := true;
					    wd := Slop + [4, 5]
					end {else}
				    end;
				'E':
				    wd := Slop + [5];
				'O':
				    wd := Slop + [4];
				'Z':
				    wd := Slop
			    end {case Ch of}
			end else 
			    Error := unkopname
		    end;
		'R':
		    begin
			getch;
			if Ch in ['C', 'E', 'O', 'Z'] then begin
			    op := SR;
			    case Ch of
				'C':
				    begin
					getch;
					if Ch in ['C', 'E', 'O', 'Z'] then
					    case Ch of
						'C':
						    wd := Srop + [4, 5, 6];
						'E':
						    wd := Srop + [5, 6];
						'O':
						    wd := Srop + [4, 6];
						'Z':
						    wd := Srop + [6]
					    end {case of Ch}
					else begin
					    Saved := true;
					    wd := Srop + [4, 5]
					end {else}
				    end;
				'E':
				    wd := Srop + [5];
				'O':
				    wd := Srop + [4];
				'Z':
				    wd := Srop
			    end {case Ch of}
			end else
			    Error := unkopname
		    end;
		'T':
		    begin
			getch;
			if Ch = 'O' then begin
			    op := STO;
			    wd := Stoop
			end else if Ch = 'R' then begin
			    getch;
			    if Ch = 'I' then begin
				getch;
				if Ch = 'N' then begin
				    getch;
				    if Ch = 'G' then 
					op := STRINGDIR
				    else
					Error := unkopname
				end else 	{Ch <> 'N'}
				    Error := unkopname
			    end else 		{Ch <> 'I'}
				Error := unkopname
			end else 		{Ch <> 'R'}
			    Error := unkopname
		    end
	    end {case Ch of}
	else 
	    Error := unkopname
    end; {procedure getSop}


    procedure getWop(var op: opkind; var wd: word);
    {Get an operator or directive name that begins with 'W'}
    begin
	getch;
	if Ch = 'R' then begin
	    op := WR;
	    getch;
	    if Ch in ['B', 'C', 'F', 'H', 'I', 'N', 'O', 'S'] then
		case Ch of
		    'B':
			begin
			    getch;
			    if Ch = 'D' then
				wd := Wrop + [8]
			    else if Ch = 'W' then
				wd := Wrop + [7, 8]
			    else 
				Error := unkopname
			end;
		    'C':
			begin
			    getch;
			    if Ch = 'H' then 
				wd := Wrop + [10]
			    else
				Error := unkopname
			end;
		    'F':
			wd := Wrop + [7];
		    'H':
			begin
			    getch;
			    if Ch = 'D' then
				wd := Wrop + [8, 9]
			    else if Ch = 'W' then
				wd := Wrop + [7, 8, 9]
			    else 
				Error := unkopname
			end;
		    'I':
			wd := Wrop;
		    'N':
			begin
			    getch;
			    if Ch = 'L' then
				wd := Wrop + [7, 8, 10]
			    else
				Error := unkopname
			end;
		    'O':
			begin
			    getch;
			    if Ch = 'D' then
				wd := Wrop + [9]
			    else if Ch = 'W' then
				wd := Wrop + [7, 9]
			    else
				Error := unkopname
			end;
		    'S':
			begin
			    getch;
			    if Ch = 'T' then 
				wd := Wrop + [7, 10]
			    else 
				Error := unkopname
			end
		end {case of Ch}
	    else 
		Error := unkopname
	end else 				{Ch <> 'R'}
	    Error := unkopname
    end; {procedure getWop}


    procedure proline;
    {process the current line of input}
    var
	wd, wd2: word;
	b1, b2: byte;
	op: opkind;
	reg: integer;
	twowds: boolean;
	i1, i2: integer;
	id: name;
	idrec: symptr;
    begin
	twowds := false;
	Error := noerr;
	if Ch in ['B', 'C', 'D', 'F', 'H', 'I', 'J', 'L',
		  'N', 'P', 'R', 'S', 'T', 'W'] then
	    case Ch of
		'B':
		    getBop(op, wd);
		'C':
		    begin
			getch;
			if Ch = 'L' then begin
			    getch;
			    if Ch = 'R' then begin
				op := CLR;
				wd := Srop
			    end else 		{Ch <> 'R'}
				Error := unkopname
			end else 		{Ch <> 'L'}
			    Error := unkopname
		    end;
		'D':
			getDop(op, wd);
		'F':
		    getFop(op, wd);
		'H':
		    begin
			getch;
			if Ch = 'A' then begin
			    getch;
			    if Ch = 'L' then begin
				getch;
				if Ch = 'T' then begin
				    op := HALT;
				    wd := Haltop
				end else 	{Ch <> 'T'}
				    Error := unkopname
			    end else 		{Ch <> 'L'}
				Error := unkopname
			end else 		{Ch <> 'A'}
			    Error := unkopname
		    end;
		'I':
		    getIop(op, wd);
		'J':
		    getJop(op, wd);
		'L':
		    getLop(op, wd);
		'N':
		    begin
			getch;
			if Ch = 'O' then begin
			    getch;
			    if Ch = 'P' then begin
				op := NOP;
				wd := Jop + [7, 8, 9]
			    end else 		{Ch <> 'P'}
				Error := unkopname
			end else 		{Ch <> 'O'}
			    Error := unkopname
		    end;
		'P':
			getPop(op, wd);
		'R':
		    getRop(op, wd);
		'S':
		    getSop(op, wd);
		'T':
		    begin
			getch;
			if Ch = 'R' then begin
			    getch;
			    if Ch = 'N' then begin
				getch;
				if Ch = 'G' then begin
				    op := TRNG;
				    wd := Trngop
				end else	{Ch <> 'G'}
				    Error := unkopname
			    end else		{Ch <> 'N'}
				Error := unkopname
			end else		{Ch <> 'R'}
			    Error := unkopname
		    end;
		'W':
		    getWop(op, wd)
	    end {case of Ch}
	else 					{Ch not a valid first letter}
	    Error := unkopname;
	if Error = noerr then begin
	    case op of
		CLR:
		    begin			{need to find a reg address}
			reg := getregaddr;
			if Error = noerr then begin
			    inregaddr(wd, reg, 10);
			    insertmem (wd)
			end {if Error = noerr}
		    end;			{SL, SR case}
		SL, SR:
		    begin			{need to find a reg address}
			reg := getregaddr;
			if Error = noerr then
			    inregaddr(wd, reg, 10);
			getch;
			if Ch <> ',' then begin
			    warn(missingcomma);
			    Saved := true
			end;
			scanint(Icr.wdf);
			if Error = noerr then begin
			    reg := Icr.sintf ;
			    if reg = 16 then
				reg := 0;
			    if (reg < 16) and (reg >= 0) then begin
				inregaddr(wd, reg, 3);
				insertmem (wd)
			    end else
				Error := badshftamt
			end {if Error = noerr}
		    end;			{SL, SR case}
		OIN, IA, IS, IM, IDENT, FN, FA,
		FS, FM, FD, BI, BO, BA, IC,
		FC, JSR, BKT, LD, STO, LDA, FLT,
		FIX, TRNG:
		    begin
			reg := getregaddr;
			if Error = noerr then begin
			    inregaddr(wd, reg, 10);
			    getch;
			    if Ch <> ',' then begin
				warn(missingcomma);
				Saved := true
			    end; {if Ch <> ','}

			    getgenaddr(op, wd, wd2, twowds);

			    if Error = noerr then
				if twowds then begin
				    insertmem (wd);
				    insertmem (wd2)
				end else
				    insertmem (wd)
			end {if Error = noerr}
		    end;			{two-address case}
		J:
		    begin
			getgenaddr(op, wd, wd2, twowds);
			if Error = noerr then
			    if twowds then begin
				insertmem (wd);
				insertmem (wd2)
			    end else
				insertmem (wd)
		    end;			{one general address case}
		INC, DEC:
			begin
			getgenaddr(op, wd, wd2, twowds);
{			Saved := true;}
{			write (' first ', ch);}
			if Ch <> ',' then begin
				getch;
				if Ch <> ',' then begin
					warn(missingcomma);
					Saved := true;
				end {if Ch <> ','}
			end else begin
				getch;
				end;
			scanint(Icr.wdf);
			if Error = noerr then begin
			    reg := Icr.sintf ;
			    if reg = 16 then
				reg := 0;
			    if (reg < 16) and (reg >= 0) then begin
				inregaddr(wd, reg, 10);
			    end else
				Error := badshftamt
			end;

			if Error = noerr then
			    if twowds then begin
					insertmem (wd);
					insertmem (wd2)
			    end else
					insertmem (wd)			
			end;
		PUSH, POP:
			begin
			reg := getregaddr;
				if Error = noerr then begin
					inregaddr(wd, reg, 10);
					getch;
					if Ch <> ',' then begin
						warn(missingcomma);
						Saved := true
					end; {if Ch <> ','}
					scancardinal(wd2);
					twowds := true;
					insertmem(wd);
					insertmem(wd2);
				end			
			end;
		RD, WR:
		    begin
			twowds := false;
			if not ((10 in wd) and (8 in wd)) then
			    getgenaddr(op, wd, wd2, twowds);
			if Error = noerr then
			    if twowds then begin
				insertmem (wd);
				insertmem (wd2)
			    end else
				insertmem (wd)
		    end;			{one general address case}
		NOP, HALT:
		    insertmem (wd);
		INTDIR:
		    begin
			scanint(wd);
			wordtobytes (wd, Mem[Lc], Mem[Lc+1]);
			Lc := Lc + 2
		    end;
		REALDIR:
		    begin
			scanreal(wd, wd2);
			wordtobytes (wd, Mem[Lc], Mem[Lc+1]);
			wordtobytes (wd2, Mem[Lc+2], Mem[Lc+3]);
			Lc := Lc + 4
		    end;
		SKIPDIR:
		    begin
			scanint(wd);
			Icr.wdf := wd;
			i1 := Icr.sintf ;
			if i1 < 0 then
			    warn(badskip)
			else
			    Lc := Lc + i1
		    end;
		STRINGDIR:
		    begin
			scanstr
		    end;
		LABELDIR:
		    begin
			getch;
			if Ch in ['a'..'z', 'A'..'Q', 'S'..'Z','$'] then begin
			    scanname(id);
			    idrec := findname(id);
			    if idrec = nil then
				idrec := inname(id)
			    else begin
				if idrec^.loc >= 0 then
				    warn(namedefined);
				i1 := idrec^.patch;
				Icr.sintf := Lc;
				wordtobytes (Icr.wdf, b1, b2);
				while i1 >= 0 do begin
				    bytestoword (Mem[i1], Mem[i1+1], Icr.wdf);
				    i2 := Icr.sintf ;
				    Mem[i1] := b1;
				    Mem[i1+1] := b2;
				    i1 := i2
				end {while}
			    end; {else}
			    idrec^.patch := -1;
			    idrec^.loc := Lc
			end else
  	    Error := invalidname
      end
     end {case of op}
 end {if Error = noerr}
    end; {procedure proline}

    procedure initopcodes;
    begin
 Inop := [];
 Iaop := [11];
 Isop := [12];
 Imop := [11, 12];
 Idop := [13];
 Fnop := [11, 13];
 Faop := [12, 13];
 Fsop := [11, 12, 13];
 Fmop := [14];
 Fdop := [11, 14];
 Biop := [12, 14];
 Boop := [11, 12, 14];
 Baop := [13, 14];
 Icop := [11, 13, 14];
 Fcop := [12, 13, 14];
 Jsrop := [11, 12, 13, 14];
 Bktop := [15];
 Ldop := [11, 15];
 Stoop := [12, 15];
 Ldaop := [11, 12, 15];
 Fltop := [13, 15];
 Fixop := [11, 13, 15];
 Jop := [12, 13, 15];
 Srop := [11, 12, 13, 15];
 Slop := [14, 15];
 Rdop := [11, 14, 15];
 Wrop := [12, 14, 15];
 Trngop := [11, 12, 14, 15];
 Incop :=[13, 14, 15];
 Decop := [11, 13, 14, 15];
 Haltop := [11, 12, 13, 14, 15]
    end; {procedure initopcodes}

begin {main}
    assign ( InFile, 'codefile' );
    reset ( InFile );
    symbols := nil ;
    initopcodes;
    Line := 1;
    Lc := 0;
    Errs := false;
    Warning := false;
    
    Saved := false;
    option := getOpt('lL');
    if not (option in ['?', endofoptions]) then
    	Listing := true
    else
    	Listing := false;

    if Listing and not eof ( InFile ) then
       begin
       writeln;
       write ( Lc:4, ': ' );
       end;
    while not eof ( InFile ) do
       begin
       getch;
       while not eof ( InFile ) and ((Ch = '%') or (Ch = ' ')) do
          begin
          readln ( InFile );
          if Listing and not eof ( InFile ) then
             begin (* Dana -- added 'and not eof' *)
             writeln;
             write ( Lc:4, ': ' );
             end;
          getch;
          Line := Line + 1
          end;
       if not eof ( InFile ) then
          begin
          Error := noerr;
          Morewarn := false;
          proline;
          getch;
          if (Ch <> '%') and (Ch <> ' ') then
             begin
             warn(textfollows);
             while not eoln ( InFile ) do
                begin
                read(InFile, Ch);
                if Listing then
                   write(Ch)
                end
          end {while};
          readln ( InFile );
          if Listing and (not eof ( InFile )) then
             begin (* Dana -- added 'and not eof' *)
             writeln;
             write ( Lc:4, ': ' );
             end;
          if Error <> noerr then
             begin
             Errs := true;
             write('ERROR -- ');
             case Error of
                invalidname: write('Invalid Name in Label Directive');
                unkopname: write('Unknown Operation or Directive Name');
                badstring: write('Improper String Directive -- Missing "');
                badgenaddr: write('Improperly Formed General Address');
                badregaddr: write('Register Address Out of Range');
                badint: write('Improperly Formed Integer Constant');
                badreal: write('Improperly Formed Real Constant');
                badstr: write('Improperly Formed String Constant');
                badname: write('Improperly Formed Name');
                illregaddr: write('Direct Register Address not Permitted');
                illimedaddr: write('Immediate Address not Permitted');
                badshftamt: write('Shift Amount not in Range')
                end; {case Error of}
             writeln(' detected on line ', Line: 1)
             end;
          while Morewarn do
             printwarn;
          Line := Line + 1
          end;
       end; {while}
		writeln;
		writeln;
    checktab(Symbols);

    assign ( memf, 'OBJ' );
    rewrite(memf); (* write an empty file if necessary *)
    if not Errs and not Warning then
       begin
       for i := 0 to Lc - 1 do
           begin
           Bcr.bytef := Mem[i];
           write(memf, Bcr.hintf)
           end; {for}
       end;

   close ( InFile );
   close ( memf )

end.
