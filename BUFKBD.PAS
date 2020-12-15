unit BufKbd;

{$S-}

interface

uses dos;

Procedure KBDGet;
Function KBDempty:Boolean;
Procedure ReadKey;
Procedure EmptyKBD;

const BITshifts = $0003;
      BITRsh    = $0001;
      BITLsh    = $0002;
      BITctrl   = $0004;
      BITalt    = $0008;
      BITLctrl  = $0100;
      BITLalt   = $0200;
      BITscrl   = $0010;
      BITnum    = $0020;
      BITcaps   = $0040;

var KBDshifts : word absolute $40:$17;
    scan      : word;
    ch        : char;

implementation

var KBDhead  : word absolute $40:$1A;
    KBDtail  : word absolute $40:$1C;
    KBDstart : word absolute $40:$80;
    KBDend   : word absolute $40:$82;

Procedure ReadKey;
var r:registers;
begin
  r.ah:=$10;
  Intr($16,r);
  ch:=char(r.al);
  if (ch=#$E0) and (r.ah<>0) then ch:=#0;
  scan:=r.ax;
end;

Procedure KBDGet;
var sh:word;
begin
  sh:=KBDshifts;
  repeat until (KBDhead<>KBDtail) or (KBDshifts<>sh);
  if KBDshifts<>sh then scan:=$FFFF else ReadKey;
end;

Function KBDempty:Boolean;
begin
  KBDempty:=KBDhead=KBDtail;
end;

Procedure EmptyKBD;
begin
  asm cli end;
  KBDtail:=KBDhead;
  asm sti end;
end;

end.
