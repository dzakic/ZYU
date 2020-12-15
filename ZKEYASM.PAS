unit ZkeyAsm; {$S-}

interface

const Copyrightlen = 16;
type AsmVarsType=record
       Copyright  : array [1..Copyrightlen] of char;
       Ver        : word;
       MPXno      : byte;
       ProgOn     : Boolean;
       Table      : byte;
       Tables     : byte;
       Side       : byte;
       HotKey     : byte;
     end;

Procedure AsmBegin;
Procedure AsmEnd;
Procedure Vectors;

implementation

{$L zkey.obj}
Procedure AsmBegin; external;
Procedure AsmEnd;   external;
Procedure Vectors;  external;

end.

