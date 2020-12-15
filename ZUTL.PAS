Unit Zutl; {$S-}

interface

uses dos;

const Win_NoBckgr  = $20;
      Win_Wide     = $40;
      Win_Shadow   = $80;
      Win_Single   = $01;
      Win_Double   = $02;
      MonoMode     : Boolean = false;

var CursorStatus   : word;
    VideoSeg       : word;
    LastMode       : byte absolute $40:$49;
    MaxX           : word absolute $40:$4A;

{ Window Type:   $80 - Shadow
                 $40 - Two from side
                 $20 - Do not store backgr
                   0 - No border
                   1 - Single
                   2 - Double                }

Function StrPas(p:pchar):string;
Function GetToken(var s:string):string;
Function Upercase(s:string):string;
Function LowerCase(s:string):string;
Function Maxy:integer;
Procedure ZeroStr(var s:string);
Function NameOnly(s:pathstr):pathstr;
Function LTrim(s:string):string;
Function RTrim(s:string):string;
Procedure StoreCursor;
Procedure HideCursor;
Procedure ShowCursor;
Procedure ShowBigCursor;
Procedure ClearWindow(x,y,w,h,col:byte);
Procedure StoreWindow(x,y,w,h:integer; var p:pointer);
Procedure RestoreWindow(p:pointer);
Procedure PasteAttr(x,y,w,h:integer; attr:byte);
Procedure PasteText(x,y:integer; s:string);
Procedure Rpad(var s:string; len:integer);
Procedure Inituif;
Function FileExist(s:string):boolean;
Function SetExtension(s,ext:string):string;
Function Crc16(var s; l:word):word;
Function Crc32(var s; l:word):longint;
Function Crc(p:pchar):word;
Function Hex1(b:byte):char;
Function Hex2(b:byte):string;
Function Hex4(w:word):string;
Function Hex8(l:longint):string;
Procedure DisplayToDelimiter(p:pchar; delimiter:char);

type
  WinObj=object
    x,y          :byte;
    w,h          :byte;
    typ          :byte;
    col          :byte;
    oldwin       :pointer;
    Procedure Open(xp,yp,wp,hp,typp,colp:integer);
    Procedure Close;
    Procedure WWrite(xx,yy:integer; s:string);
    Procedure ScrollDown;
    Procedure ScrollUp;
    Procedure DrawShadow;
    Procedure DrawBox;
  end;

implementation

Procedure DisplayToDelimiter(p:pchar; delimiter:char);
begin while p^<>Delimiter do begin write(p^); inc(p) end end;

Procedure Rolbxdx; assembler;
asm
                mov     al,bh
                and     al,$80
                rol     al,1
                shl     dx,1
                rcl     bx,1
                or      dl,al
end;

Function Crc32(var s; l:word):longint; assembler;
var xorval_l:word;
    xorval_h:word;
asm
                mov     xorval_l,1100111010110010B
                mov     xorval_h,0010010101011100B
                push    ds
                lds     si,s
                mov     cx,l
                or      cx,cx          { cmp cx,0 }
                jz      @crc_end
                sub     bx,bx          { bx=0 }
                sub     dx,dx          { dx=0 }
  @crc_loop:    lodsb
                sub     al,23
                xor     dl,al
                push    cx
                mov     cx,6
  @mix:         call    Rolbxdx
                loop    @mix
                pop     cx
                xor     dx,xorval_l
                xor     bx,xorval_h
                ror     xorval_l,1
                ror     xorval_h,1
                loop    @crc_loop
  @crc_end:     pop     ds
                mov     ax,dx
                mov     dx,bx
end;

Function Crc16(var s; l:word):word; assembler;
var xorval:word;
asm
                mov     xorval,1100111010110010B
                push    ds
                lds     si,s
                sub     dx,dx          { dx=0 }
                mov     cx,l
                or      cx,cx          { cmp cx,0 }
                jz      @crc_end
  @crc_loop:    lodsb
                sub     al,23
                xor     dl,al
                rol     dx,1
                xchg    dh,dl
                xor     dx,xorval
                ror     xorval,1
                loop    @crc_loop
  @crc_end:     pop     ds
                mov     ax,dx
end;

Function Crc(p:pchar):word; assembler;
var xorval:word;
asm
                push    ds
                lds     bx,p
                mov     xorval,111011100010101B
                mov     dx,0
  @Loop:        mov     al,[bx]
                cmp     al,0
                jz      @over
                inc     bx
                xor     dl,al
                mov     cl,6
                rol     dx,cl
                xor     dx,xorval
                ror     xorval,1
                jmp     @Loop
  @over:        mov     ax,dx
                pop     ds
end;

Function Maxy:integer; assembler;       { returns max lines on screen }
asm         mov  ah,$12                 { Get EGA info }
            mov  bl,$10
            int  $10
            cmp  bl,$10
            je   @@not_ega
            xor  ax,ax
            mov  es,ax
            mov  al,byte ptr es:[$484]  { EGA rows - 1 }
            inc  ax
            jmp  @@end
        @@not_ega:
            mov  ax,25
        @@end:
end;

Procedure ZeroStr(var s:string);
var i:integer;
begin for i:=1 to length(s) do if s[i]=' ' then s[i]:='0' end;

Function FileExist(s:string):boolean;
var DirInfo:SearchRec;
begin
  findfirst(s,archive,dirinfo);
  fileexist:=(doserror=0) and (DirInfo.Attr<>$40) and
             (pos('*',s)=0) and (pos('?',s)=0);
end;

Function NameOnly(s:pathstr):pathstr;
var d:dirstr;
    n:namestr;
    e:extstr;
begin
  fsplit(s,d,n,e);
  NameOnly:=n+e;
end;

Function LTrim(s:string):string;
begin
  while((s[1]=' ') and (length(s)>0)) do Delete(s,1,1);
  LTrim:=s;
end;

Function RTrim(s:string):string;
begin
  while((s[length(s)]=' ') and (length(s)>0)) do dec(s[0]);
  RTrim:=s;
end;

Procedure StoreCursor; assembler;
asm            mov   ah,3
               int   10h
               mov   cursorstatus,cx
end;

Procedure HideCursor; assembler;
asm            mov   ah,1
               mov   cx,$2000
               int   10h
end;

Procedure ShowCursor; assembler;
asm            mov   ah,1
               mov   cx,cursorstatus
               int   10h
end;

Procedure ShowBigCursor; assembler;
asm            mov   ah,1
               mov   cx,$000E
               int   10h
end;

Procedure ClearWindow(x,y,w,h,col:byte); assembler;
asm
               mov   cl,x
               mov   ch,y
               mov   dl,w
               mov   dh,h
               add   dx,cx
               mov   bh,col
               mov   al,0
               mov   ah,7
               dec   cl
               dec   ch
               dec   dl
               dec   dh
               int   $10
end;

Procedure WinObj.ScrollDown; assembler;
asm
               les   si,Self
               mov   cl,WinObj(es:[si]).x
               mov   ch,WinObj(es:[si]).y
               mov   dl,WinObj(es:[si]).w
               mov   dh,WinObj(es:[si]).h
               add   dx,cx
               mov   bh,WinObj(es:[si]).col
               mov   al,1
               mov   ah,7
               sub   dx,$0202
               int   $10
end;

Procedure WinObj.ScrollUp; assembler;
asm
               les   si,Self
               mov   cl,WinObj(es:[si]).x
               mov   ch,WinObj(es:[si]).y
               mov   dl,WinObj(es:[si]).w
               mov   dh,WinObj(es:[si]).h
               add   dx,cx
               mov   bh,WinObj(es:[si]).col
               mov   al,1
               mov   ah,6
               sub   dx,$0202
               int   $10
end;

Procedure StoreWindow(x,y,w,h:integer; var p:pointer);
var rowsize:word;
begin
  GetMem(p,w*2*h+8);
  rowsize:=MaxX*2;
  asm
               dec   x
               dec   y
               push  ds
               lds   si,p
               mov   di,[si]
               mov   ax,[si+2]
               mov   es,ax
               mov   ax,x
               stosw
               mov   ax,y
               stosw
               mov   ax,w
               stosw
               mov   ax,h
               stosw
               mov   ax,y
               mov   cx,rowsize
               mul   cx
               mov   si,x
               add   si,si
               add   si,ax
               mov   ax,SEG @data
               mov   ds,ax
               mov   ax,videoseg
               mov   ds,ax
               mov   dx,h
  @l1:         mov   bx,si
               mov   cx,w
               rep   movsw
               mov   si,bx
               add   si,rowsize
               dec   dx
               jnz   @l1
               pop   ds
  end;
end;

Procedure RestoreWindow(p:pointer);
var rowsize:word;
    x,y,h,w:integer;
begin
  rowsize:=MaxX*2;
  asm
               push  ds
               mov   ax,videoseg
               mov   es,ax
               lds   si,p
               lodsw
               mov   x,ax
               lodsw
               mov   y,ax
               lodsw
               mov   w,ax
               lodsw
               mov   h,ax

               mov   ax,y
               mov   cx,rowsize
               mul   cl
               mov   di,x
               add   di,di
               add   di,ax
               mov   dx,h
  @l1:         mov   bx,di
               mov   cx,w
               rep   movsw
               mov   di,bx
               add   di,rowsize
               dec   dx
               jnz   @l1
               pop   ds
  end;
  FreeMem(p,w*2*h+8);
end;

Procedure PasteAttr(x,y,w,h:integer; attr:byte);
const ShadowCol=8;
var rowsize:word;
begin
  rowsize:=MaxX*2;
  asm
               dec   x
               dec   y
               mov   ax,videoseg
               mov   es,ax
               mov   ax,y
               mov   cx,rowsize
               mul   cx
               mov   di,x
               add   di,di
               add   di,ax
               mov   dx,h
               mov   al,attr
  @l1:         mov   bx,di
               mov   cx,w
  @l2:         inc   di

               mov   al,attr
               cmp   al,$FF
               jnz   @obicn
               mov   al,es:[di]
               and   al,$0F
               jz    @obicn
               mov   al,ShadowCol

  @obicn:      stosb
               loop  @l2
               mov   di,bx
               add   di,rowsize
               dec   dx
               jnz   @l1
  end;
end;

Procedure PasteText(x,y:integer; s:string);
var rowsize:word;
begin
  rowsize:=MaxX*2;
  asm
               push  ds
               dec   x
               dec   y
               mov   ax,videoseg
               mov   es,ax
               mov   ax,y
               mov   cx,rowsize
               mul   cx
               mov   di,x
               add   di,di
               add   di,ax
               mov   ax,ss
               mov   ds,ax

               lea   si,[s]
               mov   cl,[si]
               sub   ch,ch
               inc   si

  @l1:         movsb
               inc   di
               loop  @l1
               pop   ds
  end;
end;

Procedure WinObj.DrawShadow;
var MayRight:Boolean;
begin
{  if not MonoMode then }
  if typ and $80 <> 0 then
  begin
    MayRight:=x+w+1<MaxX;
    if MayRight then PasteAttr(x+w+1,y+1,2,h,$FF);
    if y+h<MaxY-1 then PasteAttr(x+2,y+h+1,w-1+2*byte(MayRight),1,$FF);
  end;
end;

Procedure WinObj.DrawBox;
const windef:array[0..2] of array[1..7] of char=('       ','ÚÄ¿ÀÄÙ³','ÉÍ»ÈÍ¼º');
var i:integer;
    s:string;
    ltyp:integer;
begin
  if typ and $40 <> 0 then
  begin
    inc(x);
    dec(w,2);
  end;
  ltyp:=typ and $03;
  s[0]:=chr(w-1);
  FillChar(s[1],w-1,windef[ltyp,2]);
  PasteText(x,y,windef[ltyp,1]);
  PasteText(x+1,y,s);
  PasteText(x+w,y,windef[ltyp,3]);
  for i:=y+1 to y+h-1 do
  begin
    PasteText(x,i,windef[ltyp,7]);
    PasteText(x+w,i,windef[ltyp,7]);
  end;
  FillChar(s[1],w-1,windef[ltyp,2]);
  PasteText(x,y+h,windef[ltyp,4]);
  PasteText(x+1,y+h,s);
  PasteText(x+w,y+h,windef[ltyp,6]);
end;

Procedure WinObj.Open(xp,yp,wp,hp,typp,colp:integer);
begin
  if xp=-1 then x:=(MaxX-wp) div 2 else x:=xp;
  if yp=-1 then y:=((MaxY-hp) div 2)+1 else y:=yp;
  w:=wp;
  h:=hp;
  typ:=typp;
  col:=colp;
  if typp and win_nobckgr=0 then StoreWindow(x,y,w+3,h+2,oldwin);
  ClearWindow(x,y,w,h,col);
  DrawBox;
  DrawShadow;
end;

Procedure WinObj.Close;
begin
  RestoreWindow(oldwin);
end;

Procedure WinObj.WWrite(xx,yy:integer; s:string);
begin
  if xx=-1 then xx:=(w+1-length(s)) div 2;
  if yy=-1 then yy:=y div 2;
  PasteText(x+xx,y+yy,s);
end;

Procedure Rpad(var s:string; len:integer);
begin
  while length(s)<len do
  begin
    inc(s[0]);
    s[length(s)]:=' ';
  end;
end;

Function StrPas(p:pchar):string;
var s:string;
begin
  s:='';
  while p^<>#0 do
  begin
    inc(s[0]);
    s[length(s)]:=p^;
    inc(p);
  end;
  StrPas:=s;
end;

Function GetToken(var s:string):string;
var i:integer;
begin
  while (length(s)>0) and (s[1]=' ') do Delete(s,1,1);
  i:=Pos(' ',s);
  if i=0 then i:=length(s)+1;
  GetToken:=copy(s,1,i-1);
  Delete(s,1,i);
end;

Function Upercase(s:string):string;
var i:integer;
begin
  for i:=1 to length(s) do s[i]:=UpCase(s[i]);
  Upercase:=s;
end;

Function LowerCase(s:string):string;
var i:integer;
begin
  for i:=1 to length(s) do if (s[i]>='A') and (s[i]<='Z') then inc(s[i],32);
  LowerCase:=s;
end;

Function SetExtension(s,ext:string):string;
var d:dirstr;
    n:namestr;
    e:extstr;
begin
  Fsplit(Fexpand(s),d,n,e);
  if e='' then e:='.'+ext;
  SetExtension:=d+n+e;
end;

Function Hex1(b:byte):char;
var c:char;
begin
  c:=chr(b+ord('0'));
  if c>'9' then inc(c,ord('A')-ord('9')-1);
  Hex1:=c;
end;

Function Hex2(b:byte):string;
begin
  Hex2:=Hex1((b shr 4) and $0F)+Hex1(b and $0F);
end;

Function Hex4(w:word):string;
begin
  Hex4:=Hex2((w shr 8) and $FF)+Hex2(w and $FF);
end;

Function Hex8(l:longint):string;
begin
  Hex8:=Hex4((l shr 16) and $FFFF)+Hex4(l and $FFFF);
end;

Procedure Inituif;
begin
  StoreCursor;
  HideCursor;
  VideoSeg:=SegB800;
  if LastMode=7 then
  begin
    VideoSeg:=SegB000;
    monomode:=true;
  end;
end;

end.
