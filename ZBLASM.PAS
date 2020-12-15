unit ZblAsm;

interface

const Copyrightlen = 16;
type AsmVarsType=record
       Copyright  : array [1..Copyrightlen] of char;
       Ver        : word;
       MPXno      : byte;
       ProgOn     : Boolean;
       HotKey1    : byte;
       HotKey2    : byte;
       TimeLimit  : word;
       Scan       : byte;
     end;

Procedure AsmBegin;
Procedure AsmEnd;
Procedure Vectors;

implementation

{$L zblank.obj}
Procedure AsmBegin; external;
Procedure AsmEnd; external;
Procedure Vectors; external;

end.
