unit WatchAsm;

interface

const Copyrightlen = 16;
type AsmVarsType=record
       Copyright  : array [1..Copyrightlen] of char;
       Ver        : word;
       MPXno      : byte;
       ProgOn     : Boolean;
       VidMem     : word;
       Counter    : word;
       TimeOut    : word;
       DTRLimit   : word;
       Port       : word;
       PortAddr   : word;
     end;

Procedure AsmBegin;
Procedure AsmEnd;
Procedure Vectors;

implementation

{$L watch.obj}
Procedure AsmBegin; external;
Procedure AsmEnd; external;
Procedure Vectors; external;

end.
