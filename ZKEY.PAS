(*  €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
    €                 Z K E Y                  €
    €˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙€
    €  (c) Copyright Nov 1994 by Dragan ZakiÜ  €
    €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€  *)

Program Zkey;

{$M 16386,40960,40960} {$S-,V-}

uses Zutl,Zcmd,Zhotk,Ztsr,ZkeyCfg,ZkeyAsm,Dos,Zprot;

const OnStr        : array[false..true] of pchar = ('off','on');
      CopyRightMsg : pchar = 'dUOc*#6*MyzÉ|sqr~*2m3*$*lÉ*N|kqkx*dkusm';
      CRMcrc       = 57199;
      TimeStr      : string[11] = '10 Jan 1997';
      ProgName     : string[4]='zkey';
      HelpStr      : pchar = #10'Type /? for help';

      FntBufSize    = 16*256;

var A             : ^AsmVarsType absolute TSRofs;
    BaseDir       : DirStr;

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

          mov   ax,seg DefSize          { for zkey table }
          mov   ds,ax
          mov   cx,DefSize
          mov   ax,seg DefBuf
          mov   ds,ax
          lds   si,DefBuf
          rep   movsb
@Patched: pop   ds
end;

{$L zkeyhlp.obj}
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
    writeln('    Tables ........... ',Tables);
    writeln('    Active layout .... ',(Table+1) and $FF);
    write  ('    Side ............. ');
    if Side=0 then writeln('Right') else writeln('Left');
    writeln('    HotKey ........... ',HotKeyString(A^.hotkey));
    writeln(HelpStr);
  end;
end;

Procedure SearchDefName;
begin
  if ValueString='' then
  begin
    writeln('Kbd file missing.');
    Halt(1);
  end;
  ValueString:=LowerCase(SetExtension(ValueString,'kbd'));
  if not fileexist(ValueString) then
    ValueString:=LowerCase(BaseDir+NameOnly(ValueString));
end;

Procedure DisplayHelp; far;
begin
  DisplayToDelimiter(@HelpText,#27);
end;

Procedure SetLoLoad; far; begin InstFlag:=FLGlo end;
Procedure SetHiLoad; far; begin InstFlag:=FLGhi end;

Procedure InstallAsm;
begin
  if Installed then writeln('Already installed, cannot install') else
  begin
    writeln;
    TSRpara:=1+((ofs(AsmEnd)+DefSize-1) div 16);
    AllocTsrMem;
    CopyTSR;
    LinkVectors(@Vectors);
    A^.MPXno:=MPXno;
    A^.Tables:=TotalTables;
    if A^.Table>=A^.Tables then A^.Table:=A^.Tables-1;
    A^.ProgON:=true;
    writeln('Installed at ',hex4(TSRSeg),', MPXno: ',MPXno);
  end;
end;

Procedure Edit; far;
begin
  SearchDefName;
  Configure(VerStr(CfgCopyrightMsg));
end;

Procedure Install; far;
begin
  if Installed then
  begin
    writeln('Already installed, uninstall first.');
    Halt(1);
  end;
  SearchDefName;
  if not fileexist(ValueString) then
  begin
    writeln(#39+ValueString+#39'? Kbd file not found.');
    Halt(1);
  end;
  LoadDef;
  GetMem(DefBuf,MaxBufSize);
  FillChar(DefBuf^,MaxBufSize,0);
  PackBuf(ofs(AsmEnd));
  InstallAsm;
  FreeMem(DefBuf,MaxBufSize);
end;

Procedure Uninstall; far;
begin
  InitMemVars;
  if not Installed then writeln('Not installed, cannot uninstall.') else
  begin
    if UnLinkVectors(@Vectors) then
    begin
      if FreeTSRMem
        then writeln('Uninstalled! Removed from memory.')
        else writeln('Uninstalled. Cannot remove from memory.');
    end else
    begin
      A^.ProgOn:=false;
      A^.Tables:=0;
      writeln('Other programs above, program deactivated.');
    end;
  end;
  ReturnMemState;
end;

Procedure SetTable; far;
begin
  if A^.Tables=0 then writeln('No tables available') else
  begin
    if (ValueInteger<1) or (ValueInteger>A^.Tables) then
    begin
      writeln(#39,ValueInteger,#39'? Bad table number. Valid numbers: 1..',A^.Tables);
      Halt(1);
    end;
    A^.Table:=ValueInteger-1;
    writeln('˛ Using layout ',ValueInteger);
  end;
end;

Procedure TurnOn; far;
begin
  A^.ProgOn:=true;
  writeln('˛ Zkey now active');
end;

Procedure TurnOff; far;
begin
  A^.ProgOn:=false;
  writeln('˛ Zkey now deactivated');
end;

Procedure SetLeft; far;
begin
  A^.Side:=$FF;
  writeln('˛ Left-handed keyboard');
end;

Procedure SetRight; far;
begin
  A^.Side:=$00;
  writeln('˛ Right-handed keyboard');
end;

Procedure SetHotKey; far;
begin
  A^.HotKey:=HotKeyByte(ValueString);
  writeln('˛ Hotkey: ',HotKeyString(A^.hotkey));
end;

const MaxCmd = 13;
      C:array[1..MaxCmd] of Cmd = (
      (Name:'?';         Proc:DisplayHelp;   Par:ParamNone),
      (Name:'help';      Proc:DisplayHelp;   Par:ParamNone),
      (Name:'/lo';       Proc:SetLoLoad;     Par:ParamNone+PreExec),
      (Name:'/hi';       Proc:SetHiLoad;     Par:ParamNone+PreExec),
      (Name:'/hotkey';   Proc:SetHotkey;     Par:ParamString),
      (Name:'on';        Proc:TurnOn;        Par:ParamNone),
      (Name:'off';       Proc:TurnOff;       Par:ParamNone),
      (Name:'left';      Proc:SetLeft;       Par:ParamNone),
      (Name:'right';     Proc:SetRight;      Par:ParamNone),
      (Name:'table';     Proc:SetTable;      Par:ParamInteger),
      (Name:'edit';      Proc:Edit;          Par:ParamStringNext),
      (Name:'install';   Proc:Install;       Par:ParamStringNext),
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
