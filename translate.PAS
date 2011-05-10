program transl;

  { by Joseph Bergin, Sept. 1989.
    A docoder for the SAM2 output files.}

type byterange = -128..127;
     byte = set of 0..7;
     bcrec = record
               case boolean of
                 true:( bytef: byterange);
                 false:( hintf: byte);
                 end;

var n,  {byte number}
    y,  {for the raw high byte}
    xx, {x as an integer with adjustments}
    zz, {z as an integer}
    xi, {x as an integer}
    i,  {the FOR loop counter}
    f:  {the high bit of the low byte. Bit 7}
      integer;

    x,z: byterange;  {input data}
    infile: file of byterange ;
    outfile: text;
    movex,movez : bcrec;  {input data as bits}

begin
     {open(infile,'OBJ');}
     {open(outfile,'MEM');}
     reset(infile, 'OBJ');
     rewrite(outfile, 'MEM');
     n := 0;
     writeln(outfile,' num   binary',' opcode:15-11':20,'  reg:10-7',
                         '   6-4  3-0  ', ' raw Hi':10,'  raw Lo');
     while not eof(infile) do begin
           read(infile,x,z);
           movex.bytef := x;
           movez.bytef := z;
           y := x;
           if y < 0 then y := 256+y;
           xx := x+128; if xx = 128 then xx := 0;
           zz := z;
           if z < 0 then zz := zz + 256;
           xi := x;
           if (z<0) then f := 1 else f := 0;
           write(outfile,n:5,' ' {,x:6,z:6, xx:10,zz:6} );
           for i := 7 downto 0 do
               if i in movex.hintf then write(outfile,1:1)
                                   else write(outfile,0:1);
           for i := 7 downto 0 do
               if i in movez.hintf then write(outfile,1:1)
                                   else write(outfile,0:1);
           write(outfile, ' ');
           if x>=0 then
             write(outfile,  xi div 8:6, xi mod 8*2+f:10)
           else
             write(outfile,  16+xx div 8:6,xx mod 8*2+f:10);
           writeln(outfile, zz div 16:10, zz mod 16:5,y:10,zz:6);

           n := n+2;
           end;
     close(outfile);
end.