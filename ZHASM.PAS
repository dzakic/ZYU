unit ZhAsm; {$S-}

interface

const Copyrightlen = 16;
type AsmVarsType=record
       Copyright  : array [1..Copyrightlen] of char;
       Ver        : word;
       MPXno      : byte;
       ProgOn     : Boolean;
       BoldOn     : Boolean;
       LineCursor : Boolean;
       MaxPrint   : Word;
       Flash      : Byte;
       HotKey     : byte;
     end;

Procedure AsmBegin;
Procedure AsmActivate;
Procedure AsmDeactivate;
Procedure AsmRefresh;
Procedure InitAddrTable;
Procedure AsmEnd;
Procedure Vectors;

implementation

{$L zherc.obj}
Procedure AsmBegin;      external;
Procedure AsmActivate;   external;
Procedure AsmDeactivate; external;
Procedure AsmRefresh;    external;
Procedure InitAddrTable; external;
Procedure AsmEnd;        external;
Procedure Vectors;       external;

end.
