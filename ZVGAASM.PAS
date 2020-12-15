unit ZvgaAsm;

interface

const Copyrightlen = 16;
type AsmVarsType=record
       Copyright  : array [1..Copyrightlen] of char;
       Ver        : word;
       MPXno      : byte;
       ProgOn     : Boolean;
       HotKey     : byte;
     end;

Procedure AsmBegin;
Procedure AsmActivate;
Procedure AsmDeactivate;
Procedure AsmEnd;
Procedure Vectors;

implementation

{$L zvga.obj}
Procedure AsmBegin; external;
Procedure AsmActivate; external;
Procedure AsmDeactivate; external;
Procedure AsmEnd; external;
Procedure Vectors; external;

end.
