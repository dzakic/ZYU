Unit ZkeyCfg;

{$S-}

interface

uses Dos,ZkeyAsm,ZUtl,Zcmd,BufKey,BufKbd
     {$IFDEF protect} ,Zprot {$ENDIF}
     ;

const MaxTablesInCfg=3;

type ColorNames = (Cheadline,Cbotomline,CLEDoff,CLEDon,Ctocfg,Cexitwin,
                   Chelpwin,CpressedKey,CnormKey,CspecKey,
                   Cmarked,Cunmarked);
     Colors = array [ColorNames,false..true] of byte;

const MaxBufSize = 8192;
      col : Colors = (
        (16*3,112),
        (16*1+15,112),
        (8,7),            { CLEDoff }
        (10,15),
        (16*4+14,112),
        (16*3+15,112),
        (1*16+7,112),
        (15,112),        { CpressedKey }
        (7,7),
        (4,7),
        (16*4+15,112),    { Cmarked }
        (7,7)
      );

      CfgCopyRightMsg : pchar = 'dUOc*#**Myxpsq|k~syx*Ons~y|**Myzƒ|sqr~*2m3*$*lƒ*N|kqkx*dkusm';
      CfgCRMcrc       = 44628;

type Buffer        = array[0..MaxBufsize] of byte;

var TotalTables   : byte;
    DefBuf        : ^Buffer;
    DefSize       : word;

Procedure Configure(headline:string);
Procedure SaveDef;
Procedure LoadDef;
Procedure PackBuf(ofset:word);

implementation

{$L zkeyhlp.obj}

Procedure HelpText; external;

type ch2=array[1..2] of char;
     b2=array[1..2] of byte;
     KeyData=record
       x    : byte;
       y    : byte;
       len  : byte;
       scr  : ch2;
       name : string[8];
       cfg  : Boolean;
     end;
     DefData=record
       def  : array[1..3] of b2;
       caps : array[1..3] of Boolean;
     end;

const KeyboardLook : array [1..14] of string[80] = (
'ÚÄÄÄ¿   ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿ ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿ ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿   NumL Caps Scrl',
'³Esc³   ³F1 ³F2 ³F3 ³F4 ³ ³F5 ³F6 ³F7 ³F8 ³ ³F9 ³F10³F11³F12³    ÜÜ   ÜÜ   ÜÜ',
'ÀÄÄÄÙ   ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ    ßß   ßß   ßß',
'ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿  ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿',
'³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³Bsp³  ³Num³ / ³   ³   ³',
'ÃÄÄÄÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÄ´  ÃÄÄÄÅÄÄÄÅÄÄÄÅÄÄÄ´',
'³ Tab  ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³    ³  ³   ³   ³   ³   ³',
'ÃÄÄÄÄÄÄÁÂÄÄÁÂÄÄÁÂÄÄÁÂÄÄÁÂÄÄÁÂÄÄÁÂÄÄÁÂÄÄÁÂÄÄÁÂÄÄÁÂÄÄÁÂÄÄÙ    ³  ÃÄÄÄÅÄÄÄÅÄÄÄ´   ³',
'³ Caps  ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³ Enter ³  ³   ³   ³   ³   ³',
'ÃÄÄÄÄÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÂÁÄÄÄÄÄÄÄ´  ÃÄÄÄÅÄÄÄÅÄÄÄÅÄÄÄ´',
'³ Shft ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³   ³  Shift ³  ³   ³   ³   ³ E ³',
'ÃÄÄÄÄÄÄÁÂÄÄÁÂÄÄÁÄÄÂÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÂÄÄÁÄÄÂÁÄÂÄÄÄÄÄÄ´  ÃÄÄÄÁÄÄÄÅÄÄÄ´ n ³',
'³ Ctrl  ³   ³ Alt ³          Space          ³ Alt ³  ³ Ctrl ³  ³       ³   ³ t ³',
'ÀÄÄÄÄÄÄÄÙ   ÀÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÙ  ÀÄÄÄÄÄÄÙ  ÀÄÄÄÄÄÄÄÁÄÄÄÁÄÄÄÙ');

  MaxKeys = $59;
  K : array[$01..MaxKeys] of KeyData = (
    ( x:2;  y:2;  len:3; scr:'  '; name:'KeyEsc';    cfg:false ),  { Esc }
    ( x:6;  y:5;  len:3; scr:'1!'; name:'Key1';      cfg:true  ),  {  1  }
    ( x:10; y:5;  len:3; scr:'2@'; name:'Key2';      cfg:true  ),  {  2  }
    ( x:14; y:5;  len:3; scr:'3#'; name:'Key3';      cfg:true  ),  {  3  }
    ( x:18; y:5;  len:3; scr:'4$'; name:'Key4';      cfg:true  ),  {  4  }
    ( x:22; y:5;  len:3; scr:'5%'; name:'Key5';      cfg:true  ),  {  5  }
    ( x:26; y:5;  len:3; scr:'6^'; name:'Key6';      cfg:true  ),  {  6  }
    ( x:30; y:5;  len:3; scr:'7&'; name:'Key7';      cfg:true  ),  {  7  }
    ( x:34; y:5;  len:3; scr:'8*'; name:'Key8';      cfg:true  ),  {  8  }
    ( x:38; y:5;  len:3; scr:'9('; name:'Key9';      cfg:true  ),  {  9  }
    ( x:42; y:5;  len:3; scr:'0)'; name:'Key0';      cfg:true  ),  {  0  }
    ( x:46; y:5;  len:3; scr:'-_'; name:'Key-';      cfg:true  ),  {  -  }
    ( x:50; y:5;  len:3; scr:'=+'; name:'Key=';      cfg:true  ),  {  =  }
    ( x:58; y:5;  len:3; scr:'  '; name:'KeyBcksp';  cfg:false ),  { Bsp }
    ( x:2;  y:7;  len:5; scr:'  '; name:'KeyTab';    cfg:false ),  { Tab }
    ( x:9;  y:7;  len:3; scr:'qQ'; name:'KeyQ';      cfg:true  ),  {  q  }
    ( x:13; y:7;  len:3; scr:'wW'; name:'KeyW';      cfg:true  ),  {  w  }
    ( x:17; y:7;  len:3; scr:'eE'; name:'KeyE';      cfg:true  ),  {  e  }
    ( x:21; y:7;  len:3; scr:'rR'; name:'KeyR';      cfg:true  ),  {  r  }
    ( x:25; y:7;  len:3; scr:'tT'; name:'KeyT';      cfg:true  ),  {  t  }
    ( x:29; y:7;  len:3; scr:'yY'; name:'KeyY';      cfg:true  ),  {  y  }
    ( x:33; y:7;  len:3; scr:'uU'; name:'KeyU';      cfg:true  ),  {  u  }
    ( x:37; y:7;  len:3; scr:'iI'; name:'KeyI';      cfg:true  ),  {  i  }
    ( x:41; y:7;  len:3; scr:'oO'; name:'KeyO';      cfg:true  ),  {  o  }
    ( x:45; y:7;  len:3; scr:'pP'; name:'KeyP';      cfg:true  ),  {  p  }
    ( x:49; y:7;  len:3; scr:'[{'; name:'Key[';      cfg:true  ),  {  [  }
    ( x:53; y:7;  len:3; scr:']}'; name:'Key]';      cfg:true  ),  {  ]  }
    ( x:54; y:9;  len:7; scr:'  '; name:'KeyEnter';  cfg:false ),  { Ent }
    ( x:2;  y:13; len:6; scr:'  '; name:'KeyCtrl';   cfg:false ),  { Ctl }
    ( x:10; y:9;  len:3; scr:'aA'; name:'KeyA';      cfg:true  ),  {  a  }
    ( x:14; y:9;  len:3; scr:'sS'; name:'KeyS';      cfg:true  ),  {  s  }
    ( x:18; y:9;  len:3; scr:'dD'; name:'KeyD';      cfg:true  ),  {  d  }
    ( x:22; y:9;  len:3; scr:'fF'; name:'KeyF';      cfg:true  ),  {  f  }
    ( x:26; y:9;  len:3; scr:'gG'; name:'KeyG';      cfg:true  ),  {  g  }
    ( x:30; y:9;  len:3; scr:'hH'; name:'KeyH';      cfg:true  ),  {  h  }
    ( x:34; y:9;  len:3; scr:'jJ'; name:'KeyJ';      cfg:true  ),  {  j  }
    ( x:38; y:9;  len:3; scr:'kK'; name:'KeyK';      cfg:true  ),  {  k  }
    ( x:42; y:9;  len:3; scr:'lL'; name:'KeyL';      cfg:true  ),  {  l  }
    ( x:46; y:9;  len:3; scr:';:'; name:'Key;';      cfg:true  ),  {  ;  }
    ( x:50; y:9;  len:3; scr:'''"';name:'Key''';     cfg:true  ),  {  '  }
    ( x:2;  y:5;  len:3; scr:'`~'; name:'Key`';      cfg:true  ),  {  `  }
    ( x:2;  y:11; len:6; scr:'  '; name:'KeyLShift'; cfg:false ),  { LSh }
    ( x:54; y:5;  len:3; scr:'\|'; name:'Key\';      cfg:true  ),  {  \  }
    ( x:13; y:11; len:3; scr:'zZ'; name:'KeyZ';      cfg:true  ),  {  z  }
    ( x:17; y:11; len:3; scr:'xX'; name:'KeyX';      cfg:true  ),  {  x  }
    ( x:21; y:11; len:3; scr:'cC'; name:'KeyC';      cfg:true  ),  {  c  }
    ( x:25; y:11; len:3; scr:'vV'; name:'KeyV';      cfg:true  ),  {  v  }
    ( x:29; y:11; len:3; scr:'bB'; name:'KeyB';      cfg:true  ),  {  b  }
    ( x:33; y:11; len:3; scr:'nN'; name:'KeyN';      cfg:true  ),  {  n  }
    ( x:37; y:11; len:3; scr:'mM'; name:'KeyM';      cfg:true  ),  {  m  }
    ( x:41; y:11; len:3; scr:',<'; name:'Key,';      cfg:true  ),  {  ,  }
    ( x:45; y:11; len:3; scr:'.>'; name:'Key.';      cfg:true  ),  {  .  }
    ( x:49; y:11; len:3; scr:'/?'; name:'Key/';      cfg:true  ),  {  /  }
    ( x:54; y:11; len:7; scr:'  '; name:'KeyRShift'; cfg:false ),  { RSh }
    ( x:73; y:5;  len:3; scr:'* '; name:'Gray*';     cfg:true  ),  { Gray * }
    ( x:14; y:13; len:5; scr:'  '; name:'KeyAlt';    cfg:false ),  { Alt    }
    ( x:29; y:13; len:7; scr:'  '; name:'KeySpace';  cfg:false ),  { Space  }
    ( x:2;  y:9;  len:6; scr:'  '; name:'KeyCaps';   cfg:false ),  { Caps   }
    ( x:10; y:2;  len:3; scr:'  '; name:'KeyF1';     cfg:false ),  { F1 }
    ( x:14; y:2;  len:3; scr:'  '; name:'KeyF2';     cfg:false ),  { F2 }
    ( x:18; y:2;  len:3; scr:'  '; name:'KeyF3';     cfg:false ),  { F3 }
    ( x:22; y:2;  len:3; scr:'  '; name:'KeyF4';     cfg:false ),  { F4 }
    ( x:28; y:2;  len:3; scr:'  '; name:'KeyF5';     cfg:false ),  { F5 }
    ( x:32; y:2;  len:3; scr:'  '; name:'KeyF6';     cfg:false ),  { F6 }
    ( x:36; y:2;  len:3; scr:'  '; name:'KeyF7';     cfg:false ),  { F7 }
    ( x:40; y:2;  len:3; scr:'  '; name:'KeyF8';     cfg:false ),  { F8 }
    ( x:46; y:2;  len:3; scr:'  '; name:'KeyF9';     cfg:false ),  { F9 }
    ( x:50; y:2;  len:3; scr:'  '; name:'KeyF10';    cfg:false ),  { F10 }
    ( x:65; y:5;  len:3; scr:'  '; name:'KeyNumL';   cfg:false ),  { Num }
    ( x:0;  y:0;  len:0; scr:'  '; name:'KeyScrL';   cfg:false ),  { ScL }
    ( x:65; y:7;  len:3; scr:'7 '; name:'Gray7';     cfg:true  ),  { Gray 7 }
    ( x:69; y:7;  len:3; scr:'8 '; name:'Gray8';     cfg:true  ),  { Gray 8 }
    ( x:73; y:7;  len:3; scr:'9 '; name:'Gray9';     cfg:true  ),  { Gray 9 }
    ( x:77; y:5;  len:3; scr:'--'; name:'Gray-';     cfg:true  ),  { Gray - }
    ( x:65; y:9;  len:3; scr:'4 '; name:'Gray4';     cfg:true  ),  { Gray 4 }
    ( x:69; y:9;  len:3; scr:'5 '; name:'Gray5';     cfg:true  ),  { Gray 5 }
    ( x:73; y:9;  len:3; scr:'6 '; name:'Gray6';     cfg:true  ),  { Gray 6 }
    ( x:77; y:8;  len:3; scr:'++'; name:'Gray+';     cfg:true  ),  { Gray + }
    ( x:65; y:11; len:3; scr:'1 '; name:'Gray1';     cfg:true  ),  { Gray 1 }
    ( x:69; y:11; len:3; scr:'2 '; name:'Gray2';     cfg:true  ),  { Gray 2 }
    ( x:73; y:11; len:3; scr:'3 '; name:'Gray3';     cfg:true  ),  { Gray 3 }
    ( x:66; y:13; len:5; scr:'0 '; name:'Gray0';     cfg:true  ),  { Gray 0 }
    ( x:73; y:13; len:3; scr:'. '; name:'Gray.';     cfg:true  ),  { Gray . }
    ( x:55; y:13; len:6; scr:'  '; name:'';          cfg:false ),  { MyCtl ** }
    ( x:46; y:13; len:5; scr:'  '; name:'';          cfg:false ),  { MyAlt ** }
    ( x:9;  y:11; len:3; scr:'\|'; name:'Key102';    cfg:true  ),  { Addnlkey }
    ( x:54; y:2;  len:3; scr:'  '; name:'KeyF11';    cfg:false ),  { F11 }
    ( x:58; y:2;  len:3; scr:'  '; name:'KeyF12';    cfg:false ),  { F12 }
    ( x:69; y:5;  len:3; scr:'  '; name:'';          cfg:false )   { My Gray / }
);

const Vert1 = 3;
      Vert2 = 19;

var D : array[1..10,1..MaxKeys] of DefData;
    Current:integer;

Procedure BotomLine(s:string);
begin
  if length(s)>68 then s[0]:=#68;
  while length(s)<68 do
  begin
    inc(s[0]);
    s[length(s)]:=' ';
  end;
  PasteText(2,Maxy,s);
end;

Procedure DisplayKeyboard;
var i:integer;
begin
  for i:=1 to 14 do PasteText(1,Vert1+i,KeyboardLook[i]);
  PasteAttr(1,Vert1+1,80,14,12);
end;

Procedure DisplayCurrent;
var x:integer;
begin
  ClearWindow(1,Vert1,70,0,15);
  x:=9+current*4;
  if Current<5 then dec(x,2);
  if Current>8 then inc(x,2);
  PasteText(x,Vert1,'');
end;

Procedure writeLED(x:integer; w:word);
var a1,a2:byte;
begin
  if w<>0 then PasteAttr(x,Vert1+2,2,2,col[CLEDon,monomode])
          else PasteAttr(x,Vert1+2,2,2,col[CLEDoff,monomode]);
end;

Function KeyDefExists(table:integer; c:byte):Boolean;
var b:boolean;
    i,j:integer;
begin
  b:=false;
  for i:=1 to 3 do
    for j:=1 to 2 do
      if D[table,c].def[i][j]<>$FF then
      begin
        b:=true;
        break;
      end;
  KeyDefExists:=b;
end;

const tocfg     : byte=0;
var   Extended  : Boolean;
      b,c       : byte;
      make      : Boolean;
      incfg     : Boolean;
      shifts    : word;

Procedure DisplayKeys(Shifts:word);
var key,i,j:integer;
    b:byte;
    Attr:byte;
begin
  if Shifts and BITshifts = 0 then j:=1 else j:=2;
  if Shifts and BITctrl <> 0 then i:=2 else
  if Shifts and BITalt <> 0 then i:=3 else i:=1;
  for key:=1 to MaxKeys do with D[Current,key] do with K[key] do
  begin
    Attr:=col[Cspeckey,monomode];
    if cfg then
    begin
      Attr:=col[Cnormkey,monomode];
      b:=def[i][j];
      if (b=$FF) and (i=1) then b:=byte(scr[j]);
      if key=tocfg then attr:=col[Ctocfg,monomode] else
      if (i=1) and (j=1) then Attr:=attr+8*byte(KeyDefExists(Current,key))
                         else Attr:=attr+8*byte(def[i][j]<>$FF);
      PasteText(x+1,Vert1+y,chr(b));
    end;
    if len>0 then PasteAttr(x,Vert1+y,len,1,Attr);
  end;
  writeLED(66,KBDshifts and BITnum);
  writeLED(71,KBDshifts and BITcaps);
  WriteLED(76,KBDshifts and BITscrl);
end;

Procedure ShowHelp(i:integer);
var p,pp:pchar;
    xm,x,y:integer;
    W:WinObj;
    oldta:byte;
begin
  Buf.Stop;
  p:=@HelpText;
  while i>0 do
  begin
    while p^<>#27 do inc(p);
    dec(i);
    inc(p);
  end;
  xm:=0; x:=0; y:=0; pp:=p;
  while p^<>#27 do
  begin
    if p^<>#13 then inc(x) else
    begin
      inc(y);
      if x>xm then xm:=x;
      x:=0;
    end;
    inc(p);
  end;
  p:=pp;
  if xm>Maxx then xm:=maxx-1;
  if y>Maxy then y:=maxy-1;
  W.Open(-1,-1,xm+2,y,$80+2,col[Chelpwin,monomode]);
  W.WWrite(-1,0,' Help ');
  W.WWrite(-1,W.h,' Press any key ');
  x:=0; y:=0;
  while p^<>#27 do
  begin
    if p^=#10 then begin inc(y); x:=0 end;
    if (p^<>#10) and (p^<>#13) then PasteText(W.x+x+1,W.y+y,p^);
    inc(p);
    inc(x);
  end;
  KBDget;
  W.Close;
  Buf.Start;
  scan:=$FFFF;
  DisplayKeys(shifts);
end;

Function ByteStr(b:byte):string;
var c:char;
    s:string;
    hs:string;
    ds:string;
begin
  FillChar(s[1],11,' ');
  s[0]:=#11;
  if b=$FF then
  begin
    hs:='úúú';
    ds:='úúú';
  end else
  begin
    hs:=Hex2(b)+'h';
    Str(b:3,ds);
    ZeroStr(ds);
  end;
  Move(hs[1],s[1],3);
  Move(ds[1],s[5],3);
  { if b>=32 then } s[9]:=chr(b) { else s[9]:=' ' } ;
  ByteStr:=s;
end;

Procedure Keyclick; interrupt;
begin
  b:=port[$60];
  asm pushf
      call Buf.KbdIntVec
  end;

  if KBDshifts<>shifts then
  begin
    Shifts:=KBDshifts;
    DisplayKeys(Shifts);
  end;

  if (b=$E0) or (b=$E1) then Extended:=true else
  begin
    make:=(b and $80) = 0;
    c:=b and $7F;
    if Extended then
    begin
      if c=$1D then begin c:=$54; Extended:=false end else
      if c=$38 then begin c:=$55; Extended:=false end else
      if c=$35 then begin c:=$59; Extended:=false end;
    end;
    if crc(CfgCopyRightMsg)<>CfgCRMcrc then inc(c,Random(4));
    if c <= MaxKeys then with K[c] do with D[current,c] do
    if not Extended and (len>0) then
    begin
      if make then
      begin
        PasteAttr(x,Vert1+y,len,1,col[CpressedKey,monomode]);
        if cfg and not incfg then
        begin
          incfg:=true;
          tocfg:=c;
        end;
        if (Shifts and BITctrl<>0) and (c>=$3B) and (c<$3B+MaxTablesInCfg) then { F1 do F10 }
        begin
          Current:=c-$3B+1;
          DisplayCurrent;
          DisplayKeys(Shifts);
        end;
      end else if c<>tocfg then
      begin
        if cfg then b:=col[CnormKey,monomode] else b:=col[CspecKey,monomode];
        PasteAttr(x,Vert1+y,len,1,b+8*byte(KeyDefExists(Current,c)));
      end;
    end;
    Extended:=false;
  end;
end;

Procedure SelectByte(var b:byte);
var W:WinObj;
    i,j:integer;

  Procedure MarkCh(i,j:integer; col:byte);
  begin
    PasteAttr(W.x+j*2+1,W.y+i+1,3,1,col);
  end;

begin
  Buf.Stop;
  W.Open(-1,-1,34,18,2+$80,112);
  for i:=0 to 15 do
    for j:=0 to 15 do
      PasteText(W.x+j*2+2,W.y+i+1,chr(i*16+j));
  i:=b div 16; j:=b mod 16;
  repeat
    PasteText(W.x+13,W.y+17,ByteStr(i*16+j));
    MarkCh(i,j,7);
    ReadKey;
    MarkCh(i,j,112);
    case ch of
      #1..#12,#14..#26,#28..#255:
          begin
            i:=byte(ch) div 16;
            j:=byte(ch) mod 16;
          end;
      else case scan and $FF00 of
             $4B00: begin dec(j); j:=j and $0F end;
             $4D00: begin inc(j); j:=j and $0F end;
             $4800: begin dec(i); i:=i and $0F end;
             $5000: begin inc(i); i:=i and $0F end;
           end;
    end;
  until (ch=#13) or (ch=#32) or (ch=#27);
  W.Close;
  if ch<>#27 then b:=i*16+j;
  ch:=#0;
  scan:=0;
{ DisplayKeyboard; }
  DisplayKeys(0);
  Buf.Start;
end;

Procedure Mark(x,y:integer; col:byte);
begin
  x:=21+(x-1)*25-14*byte(x=3);
  PasteAttr(x,Vert2+y,11,1,col);
end;

Procedure SetupKey;
const modestr:array[1..3,1..3] of string[18] = (
    ('Normal','Shift','Normal CAPS state'),
    ('Control','Control+Shift','Control CAPS state'),
    ('Alt','Alt+Shift','Alt CAPS state') );
var xx,yy:integer;
    mx,my:integer;
    i:integer;
    s:string;
begin

  DisplayKeys(Shifts);
  EmptyKBD;


  PasteText(15,Vert2+1,'Nrml:');
  PasteText(15,Vert2+2,'Ctrl:');
  PasteText(15,Vert2+3,' Alt:');

  PasteText(34,Vert2+1,'     Shift:');
  PasteText(34,Vert2+2,'Ctrl+Shift:');
  PasteText(34,Vert2+3,' Alt+Shift:');

  PasteText(1,Vert2+1,'Scan:');

  for i:=1 to 3 do PasteText(58,Vert2+i,'Caps: ( )');

  if Shifts and BITshifts = 0 then xx:=1 else xx:=2;
  if Shifts and BITctrl <> 0 then yy:=2 else
  if Shifts and BITalt <> 0 then yy:=3 else yy:=1;
  mx:=1+((xx+1) mod 3); my:=1+((yy+1) mod 3);

  repeat
    with K[tocfg] do with D[Current,tocfg] do
    begin

      BotomLine('Editing ú '+name+' ú '+modestr[yy,xx]);

      PasteText(7,Vert2+1,Hex2(tocfg));

      for i:=1 to 3 do
      begin
        PasteText(22,Vert2+i,ByteStr(def[i][1]));
        PasteText(47,Vert2+i,ByteStr(def[i][2]));
        if not caps[i] then PasteText(65,Vert2+i,'û')
                       else PasteText(65,Vert2+i,' ');
      end;
   {  PasteAttr(x,Vert1+y,len,1,7+8*byte(KeyDefExists(Current,tocfg))); }
      if (mx<>xx) or (my<>yy) then
      begin
        Mark(mx,my,col[Cunmarked,monomode]);
        Mark(xx,yy,col[Cmarked,monomode]);
        mx:=xx; my:=yy;
      end;
      ReadKey;
      case ch of
        #32,#13: if xx=3 then caps[yy]:=not caps[yy] else SelectByte(def[yy][xx]);
        #1..#26,#28..#255: if xx<=2 then def[yy][xx]:=byte(ch);
      end;
      case scan and $FF00 of
        $3B00: ShowHelp(2);
        $4B00: if xx>1 then dec(xx);
        $4D00: if xx<3 then inc(xx);
        $4800: if yy>1 then dec(yy);
        $5000: if yy<3 then inc(yy);
        $4900: if xx<=2 then inc(def[yy][xx]);
        $5100: if xx<=2 then dec(def[yy][xx]);
        $5300: if xx<=2 then def[yy][xx]:=$FF;
        $7700: FillChar(def,sizeof(def),$FF);
      end;
    end; { with }
  until scan=$011B;
  ClearWindow(1,Vert2+1,78,3,7);
  DisplayKeys(Shifts);
  tocfg:=0;
  incfg:=false;
  DisplayKeys(Shifts);
  scan:=$FFFF;
end;

Function TableEmpty(tab:integer):boolean;
var b:Boolean;
    i,j,k:integer;
begin
  b:=true;
  for i:=1 to MaxKeys do
    for j:=1 to 3 do
      for k:=1 to 2 do
        if D[tab,i].def[j][k]<>$FF then
        begin
          b:=false;
          break;
        end;
  TableEmpty:=b;
end;

Procedure PackBuf(ofset:word);
var table,key,i,j:integer;
    ad:array[1..10,1..3] of word;
    TabOfs:word;
    NulAddr,bx:word;
begin
  FillChar(ad,sizeof(ad),0);
  TotalTables:=10;
  while TableEmpty(TotalTables) do dec(TotalTables);
  TabOfs:=TotalTables*6; { Preskoi po 3 worda za svaku pred-tabelu }
  bx:=TabOfs;
  NulAddr:=$FFFF;
  for table:=1 to TotalTables do
  begin
    for i:=1 to 3 do
    begin
      ad[table,i]:=bx;
      for key:=1 to MaxKeys do with D[table,key] do
        if K[key].cfg and ((def[i][1]<>$FF) or (def[i][2]<>$FF)) then
        begin
          DefBuf^[bx]:=key;
          if not caps[i] then inc(DefBuf^[bx],$80);
          DefBuf^[bx+1]:=def[i][1];
          DefBuf^[bx+2]:=def[i][2];
          inc(bx,3);
        end;
      if ad[table,i]=bx then
      begin
        if NulAddr=$FFFF then
        begin
          NulAddr:=bx;
          DefBuf^[bx]:=0;
          inc(bx);
        end else ad[table,i]:=NulAddr;
      end else
      begin
        DefBuf^[bx]:=0;
        inc(bx);
      end;
    end;
  end;
  if bx=0 then
  begin
    DefBuf^[bx]:=0;
    inc(bx);
  end;
  {$IFDEF protect} if not Patched then {$ENDIF}
  for table:=1 to TotalTables do
    for i:=1 to 3 do inc(ad[table,i],ofset);
  if TotalTables>0 then Move(ad[1],DefBuf^[0],TotalTables*sizeof(ad[1]));
  DefSize:=bx;
end;

type ErrorNum=(ERRbadnum,ERRbadtablenum,ERRoutofrange,ERRbadkey,
               ERRbadkeylen,ERRunknowntoken);

const ErrorStr:array[ErrorNum] of pchar=(
        'Bad numeric.',
        'Bad table numer.',
        'Numeric out of range.',
        'Invalid key name.',
        'Key definition size mismatch.',
        'Unknown token.'
      );

Procedure LoadDef;
var t:text;
    lin:integer;
    s,s1:string;

  Procedure Error(e:ErrorNum);
  begin
    str(lin:4,s1);
    ZeroStr(s1);
    writeln(#13'Error at line ',s1,': '#39,s,#39'? ',ErrorStr[e]);
    Halt(1);
  end;

  Procedure DoLoad;
  var table,key,i,j:integer;
      total:integer;
      line:string;
      c:char;
      erc,value:integer;
      keyfound:boolean;
  begin
    lin:=0;
    total:=0;
    while not eof(t) do
    begin
      readln(t,line);
      inc(lin);
      s:=UperCase(GetToken(line));
      if s<>'' then
      if s<>';' then
      if s='TABLES' then
      begin
        s:=GetToken(line);
        val(s,total,i);
        if i<>0 then Error(ERRbadnum);
        if (total<0) or (total>MaxTablesInCfg) then Error(ERRoutofrange);
      end else
      if s='#TABLE' then
      begin
        s:=GetToken(line);
        val(s,table,i);
        if i<>0 then Error(ERRbadnum);
        if table>total then Error(ERRbadtablenum);
      end else
      begin
        keyfound:=false;
        for key:=1 to MaxKeys do
        begin
          if UperCase(K[key].name)=UperCase(s) then
          begin
            keyfound:=true;
            break;
          end;
        end;
        if not keyfound then Error(ERRbadkey);

        with D[table,key] do
        for i:=1 to 3 do
          for j:=1 to 2 do
          begin
            s:=GetToken(line);
            if length(s)<>3 then Error(ERRbadkeylen);
            if (s[1]=#39) and (s[3]=#39) then def[i][j]:=byte(s[2]) else
            if UperCase(s)='NUL' then def[i][j]:=$FF else
            begin
              val(s,value,erc);
              if erc<>0 then Error(ERRbadnum);
              if (value>=0) and (value<=255) then def[i][j]:=value
                                             else Error(ERRoutofrange);
            end;
          end;
        while length(s)>0 do
        begin
          s:=UperCase(GetToken(line));
          if s<>'' then
          begin
            if s='CAPS'  then D[table,key].caps[1]:=false else
            if s='CAPSC' then D[table,key].caps[2]:=false else
            if s='CAPSA' then D[table,key].caps[3]:=false else
            Error(ERRunknowntoken);
          end;
        end;
      end;
    end;
    close(t);
  end;

begin
  write('Loading ',ValueString,'...');
  FillChar(D,sizeof(D),$FF);
  assign(t,ValueString);
  {$i-} reset(t); {$i+}
  if ioresult=0 then DoLoad;
  write(#13'Loaded ',ValueString,'    '#13);
end;

Procedure SaveDef;
var t:text;
    table,key,i,j:integer;
    s:string;
    c:char;
begin
  BotomLine('Saving '+ValueString);
  TotalTables:=10;
  while TableEmpty(TotalTables) do dec(TotalTables);
  assign(t,ValueString);
  rewrite(t);
  Str(TotalTables:2,s);
  ZeroStr(s);
  writeln(t,'Tables ',s);
  writeln(t);
  for table:=1 to TotalTables do if not TableEmpty(table) then
  begin
    Str(table:2,s);
    ZeroStr(s);
    writeln(t,'#Table ',s,'       KeyID     Nrm Shf Ctr CSh Alt ASh');
    for key:=1 to MaxKeys do
      if K[key].cfg and KeyDefExists(table,key) then
      begin
        s:=K[key].name;
        RPad(s,10);
        write(t,'                ',s);
        for i:=1 to 3 do
          for j:=1 to 2 do
          begin
            c:=chr(D[table,key].def[i,j]);
            case c of
              #255: s:='Nul';
              #0..#32: begin
                          str(byte(c):3,s);
                          ZeroStr(s);
                        end;
              #33..#254: s:=#39+c+#39;
            end;
            write(t,s,' ');
          end;
        if not D[table,key].Caps[1] then write(t,'Caps  ');
        if not D[table,key].Caps[2] then write(t,'CapsC ');
        if not D[table,key].Caps[3] then write(t,'CapsA ');
        writeln(t);
      end;
    writeln(t);
  end;
  close(t);
end;

Procedure AskExit;
var W:WinObj;
begin
  BotomLine('Esc to go back, Enter to leave without saving');
  W.Open(-1,Vert2+1,29,2,$80+1,col[Cexitwin,monomode]);
  PasteText(W.x+2,W.y+1,'Exit without saving? (y/n)');
  ReadKey;
  if (upcase(ch)<>'Y') and (ch<>#13) then scan:=$FFFF else scan:=$011B;
  W.Close;
  incfg:=false;
  tocfg:=0;
end;

Procedure Configure(headline:string);
var W:WinObj;
    x,y:integer;
    ch:char;
begin
  LoadDef;
  Inituif;
  W.Open(1,1,Maxx,Maxy,$80,7);
  PasteAttr(1,1,Maxx,1,col[Cheadline,monomode]);
  PasteText(2,1,HeadLine);
  PasteAttr(1,Maxy,Maxx,1,col[Cbotomline,monomode]);
  PasteText(71,Maxy,'F1 - Help');
  Current:=1;
  DisplayKeyboard;
  DisplayKeys(0);
  DisplayCurrent;
  Buf.Init(@KeyClick);
  Buf.Start;
  Extended:=false;
  repeat
    BotomLine('Editing '+ValueString);
    if KBDempty then scan:=$FFF else KBDGet;
    if incfg then SetupKey;
    case scan of
      $77E0: FillChar(D[Current],sizeof(D[Current]),$FF);
      $3B00: ShowHelp(1);
      $011B: AskExit;
      $4400: SaveDef;
    end;
  until (scan=$011B) or (scan=$4400);
  Buf.Stop;
  W.Close;
  ShowCursor;
  writeln('Edit');
end;

end.
