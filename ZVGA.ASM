;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €                  Z V G A                 €
;   €               assembly code              €
;   €˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙€
;   €  (c) Copyright Nov 1994 by Dragan ZakiÜ  €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

code segment public
public          AsmBegin
public          AsmActivate
public          AsmDeactivate
public          AsmEnd
public          Vectors

F9scan          equ   43h
F10scan         equ   44h
KBDstat         equ   17h
BitRsh          equ   1
BitLsh          equ   2
BitCtl          equ   4
BitAlt          equ   8
On              equ   1
Off             equ   0
true            equ   1
false           equ   0

AsmBegin:

;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €  Global vars, available from .pas        €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

Copyright       db    'dzakic  zvga    '
Ver             dw    0014h
MPXno           db    0
ProgON          db    false
HotKey          db    BITctl+BITalt

InInt10         db    0
OldInt9Ofs      dw    0
OldInt9Seg      dw    0
OldInt10Ofs     dw    0
OldInt10Seg     dw    0
OldInt2DOfs     dw    0
OldInt2DSeg     dw    0

;   ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;   Deactivate proc
;   ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

AsmDeactivate   proc  far
                push  ax
                push  bx

                mov   bl,0
                mov   ax,1104h
                int   10h
                mov   cs:ProgOn,false

                pop   bx
                pop   ax
                ret
endp

;   ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;   Activate proc
;   ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

AsmActivate     proc  far
                push  ax
                push  bx
                push  bp
                push  es

                mov   ax,cs
                mov   es,ax
                mov   bp,offset CharTable
                mov   cx,256
                sub   dx,dx
                mov   bx,1000h
                mov   ax,1100h
                int   10h
                mov   cs:ProgOn,true

                pop   es
                pop   bp
                pop   bx
                pop   ax
                ret
endp

;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €  Keyboard service, allow hotkey act/deact  €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

AsmInt9         proc  far
                push  ax
                push  ds
                mov   ax,40h
                mov   ds,ax
                in    al,60h
                mov   ah,[KBDstat]
                and   ah,cs:HotKey
                cmp   ah,cs:HotKey
                jnz   NoHotKey
                cmp   al,F9scan
                jz    HotKDeact
                cmp   al,F10scan
                jz    HotKAct
NoHotKey:       pop   ds
                pop   ax
                jmp   dword cs:[OldInt9Ofs]
HotKAct:        push  cs
                call  near AsmActivate
                jmp   EndInt
HotKDeact:      push  cs
                call  near AsmDeactivate
EndInt:         call  SignalEndInt
                pop   ds
                pop   ax
                iret
endp

SignalEndInt    proc  near
                in    al,61h                  ;uzmi vrednost sa porta 61h
                mov   ah,al                   ;saÅuvaj je
                or    al,80h                  ;setuj bit 7
                out   61h,al                  ;signaliziraj da je znak prihvaÜen
                mov   al,ah                   ;vrati staro stanje
                out   61h,al                  ;na port 61h
                mov   al,20h
                out   20h,al
                sti
                ret
endp

;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €  Video service, avoid bios video reset  €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

AsmInt10        proc  far
                cmp   cs:ProgOn,true
                jnz   Done10
                or    ah,ah
                jnz   NoFn0
                cmp   al,3
                ja    Done10
                jmp   PasteFont
NoFn0:          cmp   ax,1114h
                jnz   Done10
PasteFont:      pushf
                call  dword cs:[OldInt10Ofs]
                sti
                push  cs
                call  near AsmActivate
                iret
Done10:         jmp   dword cs:[OldInt10ofs]
endp

;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €  Multiplex Interrupt Specification, bare  €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

AsmInt2D        proc  far
                cmp   ah,cs:MPXno
                jz    My2D
Orig2D:         jmp   dword cs:[OldInt2DOfs]
My2D:           sti
                or    al,al
                jnz   TryFn2
                mov   dx,cs
                mov   di,offset CopyRight
                mov   cx,cs:Ver
                dec   al
                iret
TryFn2:         cmp   al,2
                jnz   TryFn4
                inc   ax
                mov   bx,cs
                iret
TryFn4:         sub   al,al
                iret
endp

AsmEnd:

CharTable:

;  €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;  €  Table of hooked vectors, readable from .pas  €
;  €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

Vectors:        db    09h
                dw    OldInt9ofs
                dw    AsmInt9
                db    10h
                dw    OldInt10ofs
                dw    AsmInt10
                db    2Dh
                dw    OldInt2Dofs
                dw    AsmInt2D
                db    0

ends
