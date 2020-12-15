(*  €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
    €               Z B L A N K                €
    €˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙€
    €  (c) Copyright Nov 1994 by Dragan ZakiÜ  €
    €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€  *)

Program Zblank;

{$M 16386,20480,20480} {$S-}

uses Zutl,Zcmd,Zhotk,Ztsr,ZblAsm,Dos
     {$IFDEF protect} ,Zprot {$ENDIF}
     ;

const OnStr        : array[false..true] of pchar = ('off','on');
      CopyRightMsg : pchar = 'dLVKXU*$6*MyzÉ|sqr~*/*lÉ*N|kqkx*dkusm';
      CRMcrc       = 12998;
      TimeStr      : string[11] = '26 Nov 1994';
      ProgName     : string[6]='zblank';
      HelpStr      : pchar = #10'Type /? for help';

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

@Patched: pop   ds
end;

{$L zblankhlp.obj}
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
{  writeln(RegStr); }
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
    writeln('    HotKey1 .......... ',HotKeyString(A^.hotkey1));
    writeln('    HotKey2 .......... ',HotKeyString(A^.hotkey2));
    writeln(HelpStr);
  end;
end;

Procedure DisplayHelp; far;
begin
  DisplayToDelimiter(@HelpText,#27);
end;

Procedure TurnOn; far;
begin
  A^.ProgOn:=true;
  writeln('˛ Zblank now active');
end;

Procedure TurnOff; far;
begin
  A^.ProgOn:=false;
  writeln('˛ Zblanka now deactivated');
end;

Procedure SetLoLoad; far; begin InstFlag:=FLGlo end;
Procedure SetHiLoad; far; begin InstFlag:=FLGhi end;

Procedure InstallAsm;
begin
  if Installed then writeln('Already installed, cannot install') else
  begin
    writeln;
    TSRpara:=1+((ofs(AsmEnd)-1) div 16);
    AllocTsrMem;
    CopyTSR;
    LinkVectors(@Vectors);
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
  InstallAsm;
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
      writeln('Other programs above, program deactivated.');
      TurnOff;
    end;
  end;
end;

Procedure SetHotKey1; far;
begin
  A^.HotKey1:=HotKeyByte(ValueString);
  writeln('˛ Hotkey1: ',HotKeyString(A^.hotkey1));
end;

Procedure SetHotKey2; far;
begin
  A^.HotKey2:=HotKeyByte(ValueString);
  writeln('˛ Hotkey2: ',HotKeyString(A^.hotkey2));
end;

const MaxCmd = 10;
      C:array[1..MaxCmd] of Cmd = (
      (Name:'?';         Proc:DisplayHelp;   Par:ParamNone),
      (Name:'help';      Proc:DisplayHelp;   Par:ParamNone),
      (Name:'/lo';       Proc:SetLoLoad;     Par:ParamNone+PreExec),
      (Name:'/hi';       Proc:SetHiLoad;     Par:ParamNone+PreExec),
      (Name:'/hk1';      Proc:SetHotkey1;    Par:ParamString),
      (Name:'/hk2';      Proc:SetHotkey2;    Par:ParamString),
      (Name:'on';        Proc:TurnOn;        Par:ParamNone),
      (Name:'off';       Proc:TurnOff;       Par:ParamNone),
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
