Program CalcVersionString;
uses zutl;
var s:string;
    i:integer;
    f:text;
    p:pchar;
begin
  write('Unesi CPR: ');
  readln(s);
  s[length(s)+1]:=#0;
  p:=@s[1];
  for i:=1 to length(s) do if (s[i]<>'#') and (s[i]<>'$') then inc(s[i],10);
  assign(f,'cpr.txt');
  rewrite(f);
  writeln(s);
  writeln(f,'STR=',#39,s,#39);
  writeln('CRC=',crc(p));
  writeln(f,'CRC=',crc(p));
  close(f);
end.
