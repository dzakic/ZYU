Unit Zprot;

interface

uses Zutl,Dos;

const Patched         : Boolean = true;
      MarkerLen       = 8;
      Marker          : array[1..markerlen] of char = 'StayAway';
      ProgCRC         : word = 0;
      FileLen         : word = 0;

      OldExitProc     : pointer = Nil;
      OldInt1         : pointer = Nil;
      OldInt3         : pointer = Nil;
      RegStr          = '* SHAREWARE version NOT REGISTERED for commercial use *';
{     RegStr          = 'Registered to Dragan Obrenovi† on SezamNet'; }

Procedure DemoProc(var ProgName:string);

implementation

Procedure DemoProc(var ProgName:string);
const y1=1995; m1=12;
      y2=1996; m2=1;
var   y,m,d,dow:word;
begin
  GetDate(y,m,d,dow);
  if (y>=y1) and (m>=m1) then writeln('Evaluation period has expired! Please stop using ',ProgName,'.');
  if (y>=y2) and (m>=m2) then
  begin
    writeln('Evaluation period expired! Please contact author for registration.');
    Halt(1);
  end;
end;

Procedure CheckIntegrity; interrupt;
var CharRead:word;
    Buf:pointer;
    f:file;
begin
  GetMem(Buf,FileLen);
  assign(f,ParamStr(0));
  {$i-} reset(f,1); {$i+}
  if ioresult<>0 then Halt(1);
  BlockRead(f,Buf^,FileLen,CharRead);
  if (FileLen<>0) and (ProgCRC<>0) then
  if crc16(Buf^,FileLen)=ProgCRC then Patched:=false;
  close(f);
  FreeMem(Buf,FileLen);
end;

Procedure MyExitProc; far;
begin
  ExitProc:=OldExitProc;
  SetIntVec(1,OldInt1);
  SetIntVec(3,OldInt3);
end;

begin
  {$IFDEF protect}
  GetIntVec(1,OldInt1);
  GetIntVec(3,OldInt3);
  GetIntVec($21,OldExitProc);
  SetIntVec(3,OldExitProc);
  SetIntVec(1,@CheckIntegrity);
  OldExitProc:=ExitProc;
  ExitProc:=@MyExitProc;
  asm int 1 end;
  {$ENDIF}
end.
