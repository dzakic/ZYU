(*  €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
    €                 Z V G A                  €
    €˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙€
    €  (c) Copyright Nov 1994 by Dragan ZakiÜ  €
    €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€  *)

Program Zvga;

{$M 16386,20480,20480} {$S-,V-}

uses Zutl,Zcmd,Zhotk,Ztsr,ZvgaAsm,Dos,Zprot;

const OnStr        : array[false..true] of pchar = ('off','on');
      CopyRightMsg : pchar = 'd`QK*#6*MyzÉ|sqr~*$*lÉ*N|kqkx*dkusm';
      CRMcrc       = 26554;
      TimeStr      : string[11] = '26 Nov 1994';
      ProgName     : string[4]='zvga';
      HelpStr      : pchar = #10'Type /? for help';

      FntBufSize    = 16*256;

type  Buffer        = array[0..FntBufSize-1] of byte;

var A             : ^AsmVarsType absolute TSRofs;
    BaseDir       : DirStr;
    FntBuf        : ^Buffer;

Procedure CopyTSR; assembler;
const ofs=10;
asm       push  ds
{$IFDEF protect}
          mov   bx,offset Patched-ofs
          mov   al,true
          cmp   [bx+ofs],al
          jz    @Patched
{$ENDIF}
          mov   ax,TSRseg
          mov   es,ax
          mov   ax,seg AsmBegin
          mov   ds,ax
          mov   di,offset AsmBegin
          mov   si,offset AsmBegin
          mov   cx,offset AsmEnd
          rep   movsb

          mov   cx,FntBufSize
          mov   ax,seg FntBuf
          mov   ds,ax
          lds   si,FntBuf
          rep   movsb
@Patched: pop   ds
end;

{$L zvgahlp.obj}
Procedure HelpText; external;

Function VerS:string;
var s1,s2:string;
    B:^AsmVarsType;
begin
  B:=@AsmBegin;
  Str(Hi(B^.Ver),s1);
  Str(Lo(B^.Ver):2,s2);
  if s2[1]=' ' then s2[1]:='0';
  VerS:=s1+'.'+s2;
end;

Function VerStr(p:pchar):string;
var s:string;
begin
  s:='';
  while p^<>#0 do
  begin
    if p^='#' then s:=s+VerS else
    if p^='$' then s:=s+TimeStr else
    begin
      inc(s[0]);
      s[length(s)]:=p^;
      dec(s[length(s)],10);
    end;
    inc(p);
  end;
  VerStr:=s;
  {$IFDEF protect}
  if crc(CopyRightMsg)<>CRMcrc then Patched:=true;
  {$ENDIF}
end;

Procedure InitAppl;
var n:namestr;
    e:extstr;
begin
  Fsplit(Fexpand(ParamStr(0)),basedir,n,e);
  writeln(VerStr(CopyRightMsg));
  writeln(RegStr);
  if LowerCase(n)<>ProgName then writeln('EXE should be named "',ProgName,'"!');
  {$IFDEF demo}
  DemoProc(ProgName);
  {$ENDIF}
end;

Procedure DisplayStatus;
begin
  with A^ do
  begin
    writeln;
    writeln('    Status ........... ',OnStr[A^.ProgOn]);
    writeln('    HotKey ........... ',HotKeyString(A^.hotkey));
    writeln(HelpStr);
  end;
end;

Procedure SearchFontName;
begin
  if ValueString='' then
  begin
    writeln('Font file missing.');
    Halt(1);
  end;
  ValueString:=LowerCase(SetExtension(ValueString,'f16'));
  if not fileexist(ValueString) then
  begin
    ValueString:=LowerCase(BaseDir+NameOnly(ValueString));
    if not fileexist(ValueString) then
    begin
      writeln(#39+ValueString+#39'? Font file not found.');
      Halt(1);
    end;
  end;
end;

Procedure LoadFont;
var f:file;
    cr:word;
begin
  {$IFDEF protected}
  if Patched then Dec(FntBuf,Random(1000));
  {$ENDIF}
  assign(f,ValueString);
  reset(f,1);
  {$i-}
  BlockRead(f,FntBuf^,FntBufSize,cr);
  {$i+}
  close(f);
  if cr<>FntBufSize then
  begin
    writeln('Error loading font file.');
    Halt(1);
  end;
end;

Procedure Activate; assembler;
asm
      push  bp
      les   bp,FntBuf
      mov   cx,256
      sub   dx,dx
      mov   bx,1000h
      mov   ax,1100h
      int   10h
      pop   bp
end;

Procedure DisplayHelp; far;
begin
  DisplayToDelimiter(@HelpText,#27);
end;

Procedure TurnOn; far;
begin
  A^.ProgOn:=true;
  AsmActivate;
  writeln('˛ Zvga now active');
end;

Procedure TurnOff; far;
begin
  A^.ProgOn:=false;
  AsmDeactivate;
  writeln('˛ Zvga now deactivated');
end;

Procedure SetLoLoad; far; begin InstFlag:=FLGlo end;
Procedure SetHiLoad; far; begin InstFlag:=FLGhi end;

Procedure InstallAsm;
begin
  if Installed then writeln('Already installed, cannot install') else
  begin
    writeln;
    TSRpara:=1+((ofs(AsmEnd)+FntBufSize-1) div 16);
    AllocTsrMem;
    CopyTSR;
    LinkVectors(@Vectors);
    Activate;
    A^.MPXno:=MPXno;
    A^.ProgON:=true;
    writeln('Installed at ',hex4(TSRSeg),', MPXno: ',MPXno);
  end;
end;

Procedure Install; far;
begin
  if Installed then
  begin
    writeln('Already installed, uninstall first.');
    Halt(1);
  end;
  SearchFontName;
  GetMem(FntBuf,FntBufSize);
  LoadFont;
  InstallAsm;
  FreeMem(FntBuf,FntBufSize);
end;

Procedure Uninstall; far;
begin
  if not Installed then writeln('Not installed, cannot uninstall.') else
  begin
    if UnLinkVectors(@Vectors) then
    begin
      if FreeTSRMem
        then writeln('Uninstalled! Removed from memory.')
        else writeln('Uninstalled. Cannot remove from memory.');
    end else
    begin
      AsmDeactivate;
      writeln('Other programs above, program deactivated.');
    end;
  end;
end;

Procedure ChangeFont; far;
var f:file;
    cr:word;
begin
  if not Installed then
  begin
    writeln('Not installed, cannot change font.');
    Halt(1);
  end;
  if ValueString='' then
  begin
    writeln('Font file missing');
    Halt(1);
  end;
  SearchFontName;
  GetMem(FntBuf,FntBufSize);
  LoadFont;
  Move(FntBuf^,Ptr(TSRseg,Ofs(AsmEnd))^,FntBufSize);
  Activate;
  FreeMem(FntBuf,FntBufSize);
end;

Procedure SetHotKey; far;
begin
  A^.HotKey:=HotKeyByte(ValueString);
  writeln('˛ Hotkey: ',HotKeyString(A^.hotkey));
end;

const MaxCmd = 10;
      C:array[1..MaxCmd] of Cmd = (
      (Name:'?';         Proc:DisplayHelp;   Par:ParamNone),
      (Name:'help';      Proc:DisplayHelp;   Par:ParamNone),
      (Name:'/lo';       Proc:SetLoLoad;     Par:ParamNone+PreExec),
      (Name:'/hi';       Proc:SetHiLoad;     Par:ParamNone+PreExec),
      (Name:'/hotkey';   Proc:SetHotkey;     Par:ParamString),
      (Name:'on';        Proc:TurnOn;        Par:ParamNone),
      (Name:'off';       Proc:TurnOff;       Par:ParamNone),
      (Name:'install';   Proc:Install;       Par:ParamStringNext),
      (Name:'font';      Proc:ChangeFont;    Par:ParamStringNext),
      (Name:'uninstall'; Proc:Uninstall;     Par:ParamNone)
      );

begin
  InitAppl;
  CheckInstalled(@AsmBegin);
  if Installed and (TSRVer<>A^.Ver) then
  begin
    writeln('Different version found resident.');
    Halt(1);
  end;
  if ParamCount=0 then
  begin
    if Installed then DisplayStatus else DisplayHelp
  end else
  begin
    DoCmds(@C,MaxCmd,false);
    DoCmds(@C,MaxCmd,true);
  end;
end.
