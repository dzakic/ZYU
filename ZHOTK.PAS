unit Zhotk;

interface

Function HotKeyByte(s:string):byte;
Function HotKeyString(b:byte):string;

implementation

Function HotKeyByte(s:string):byte;
var h:byte;
    i:integer;
begin
  if s='' then h:=$FF else
  begin
    h:=0;
    for i:=1 to length(s) do
      case upcase(s[i]) of
        'R': h:=h or 1;
        'L': h:=h or 2;
        'C': h:=h or 4;
        'A': h:=h or 8;
        else begin
               writeln(#39,s[i],#39'? Unknown hotkey char.');
               Halt(1);
             end;
      end;
  end;
  HotKeyByte:=h;
end;

Function HotKeyString(b:byte):string;
const HS:array[1..4] of string[6] = ('RShift','LShift','Ctrl','Alt');
var i:integer;
    s:string;
begin
  s:='';
  if b<>$FF then
  begin
    for i:=1 to 4 do
    begin
      if Boolean(b and 1) then s:=s+HS[i]+'+';
      b:=b shr 1;
    end;
    dec(s[0]);
  end else s:='None';
  HotKeyString:=s;
end;

end.
