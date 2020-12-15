unit bufkey;

{$S-}

interface

const BufSize = 32;

type
     BufObj = object
       Buffer    : array[0..BufSize-1] of byte;
       Head      : integer;
       Tail      : integer;
       KbdIntVec : pointer;
       MyIntVec  : pointer;
       Procedure Init(p:pointer);
       Procedure Start;
       Procedure Stop;
       Procedure Put(b:byte);
       Function Get:byte;
       Function Empty:Boolean;
     end;

var Buf:BufObj;

implementation

uses Dos;

Procedure BufObj.Put(b:byte);
begin
  Buffer[Head]:=b;
  inc(Head,2);
  Head:=Head and (BufSize-1);
end;

Function BufObj.Empty:Boolean;
begin
  if Tail=Head then Empty:=true else Empty:=False;
end;

Function BufObj.Get:byte;
begin
  if Tail=Head then Get:=$FF else
  begin
    Get:=Buffer[Tail];
    Inc(Tail,2);
    Tail:=Tail and (BufSize-1);
  end;
end;

Procedure BufObj.Start;
begin
  GetIntVec($9,KbdIntVec);
  SetIntVec($9,MyIntVec);
end;

Procedure BufObj.Init(p:pointer);
begin
  Head:=0;
  Tail:=0;
  MyIntVec:=p;
end;

Procedure BufObj.Stop;
begin
  SetIntVec($9,KbdIntVec);
end;

end.
