Program Zpatch;

uses zutl;

type  Buffer        = array[0..1] of byte;

const markerlen = 8;
      marker : array[1..markerlen] of char = 'StayAway';

Procedure PatchExe;
var f:file;
    buf:^Buffer;
    BufSize:word;
    ii,i,j:word;
    CharRead:word;
    ex:Boolean;
    v:word;
    s:string;
begin
  if ParamStr(1)='' then
  begin
    writeln('Usage: ZPATCH <exe file>');
    Halt(1);
  end;
  s:=lowercase(setextension(ParamStr(1),'exe'));
  if s='' then
  begin
    writeln('Usage: ZPATCH <exe file>');
    Halt(1);
  end;
  assign(f,s);
  {$i-}
  reset(f,1);
  {$i+}
  if ioresult<>0 then
  begin
    writeln('Cannot open ',s);
    Halt(1);
  end;
  BufSize:=filesize(f);
  GetMem(buf,BufSize);
  BlockRead(f,Buf^,BufSize,CharRead);
  ex:=false;
  ii:=0;
  repeat
    i:=ii;
    j:=1;
    while byte(Marker[j])=Buf^[i] do begin inc(i); inc(j) end;
    if j>MarkerLen then
    begin
      v:=crc16(buf^,ii);
      Seek(f,ii+markerlen);
      BlockWrite(f,v,sizeof(v));
      BlockWrite(f,ii,sizeof(ii));
      ex:=true;
    end;
    inc(ii);
  until ex or (ii>CharRead);
  Close(f);
  FreeMem(buf,BufSize);
  if not ex then
  begin
    writeln('Marker not found!');
    Halt(1);
  end else writeln('Done.');
end;

begin
  PatchExe;
end.
