;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €                Z B L A N K               €
;   €               assembly code              €
;   €˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙€
;   €  (c) Copyright Nov 1994 by Dragan ZakiÜ  €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

code segment public
public          AsmBegin
public          AsmEnd
public          Vectors

;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €  Constants                               €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

Caps            equ   80h
KBDstat         equ   17h
KBDestat        equ   18h
BitRsh          equ   1
BitLsh          equ   2
BitCtl          equ   4
BitAlt          equ   8
BitCapsOn       equ   64
EBitLCtl        equ   1
EBitLAlt        equ   2

AsmBegin:

;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €  Global vars, available from .pas        €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

Copyright       db    'dzakic  zblank  '
Ver             dw    0000h
MPXno           db    0
ProgON          db    1
HotKey1         db    BITctl+BITalt
HotKey2         db    BITctl+BITlsh
TimeLimit       dw    546
Scan            db    48
Count           dw    546
Blackened       db    0

OldInt8Ofs      dw    0
OldInt8Seg      dw    0
OldInt9Ofs      dw    0
OldInt9Seg      dw    0
OldInt2DOfs     dw    0
OldInt2DSeg     dw    0

;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €  Global proc, available from .pas        €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€
;
;   DS=40h
;   CS=Asm Vars

AsmInt8         proc  far
                pushf
                call  dword cs:[OldInt8ofs]
                cmp   cs:ProgON,1
                jnz   Over1
                cmp   cs:Blackened,1
                jz    Over1
                dec   cs:Count
                cmp   cs:Count,0
                jnz   Over1
                call  Blacken
Over1:          iret
endp

AsmInt9         proc  far

                push  ax
                push  ds
                mov   ax,40h
                mov   ds,ax

                in    al,60h
                test  al,80h
                jnz   Over

                mov   ah,[KBDstat]
                and   ah,cs:HotKey2
                cmp   ah,cs:HotKey2
                jnz   NoHotKey1
                cmp   al,cs:Scan
                jnz   NoHotKey1
                xor   cs:ProgON,1
                jmp   EndInt
NoHotKey1:
                cmp   cs:ProgOn,1
                jnz   Over
                mov   ah,[KBDstat]
                and   ah,cs:HotKey1
                cmp   ah,cs:HotKey1
                jnz   NoHotKey
                cmp   al,cs:Scan
                jnz   NoHotKey
                cmp   cs:Blackened,1
                jz    EndInt
                call  Blacken
                jmp   EndInt

NoHotKey:       mov   ax,cs:TimeLimit
                mov   cs:Count,ax
                cmp   cs:Blackened,0
                jz    Over
                push  dx
                mov   dx,[0063h]
                add   dx,4
                mov   al,[0065h]
                or    al,8
                out   dx,al
                mov   [0065h],al
                mov   cs:Blackened,0
                pop   dx

Over:           pop   ds
                pop   ax
                jmp   dword cs:[OldInt9Ofs]

EndInt:         in    al,61h                  ;uzmi vrednost sa porta 61h
                mov   ah,al                   ;saÅuvaj je
                or    al,80h                  ;setuj bit 7
                out   61h,al                  ;signaliziraj da je znak prihvaÜen
                mov   al,ah                   ;vrati staro stanje
                out   61h,al                  ;na port 61h
                mov   al,20h
                out   20h,al
                pop   ds
                pop   ax
                iret

Blacken         proc  near
                push  ax
                push  dx
                push  ds
                mov   ax,40h
                mov   ds,ax
                mov   dx,[0063h]
                add   dx,4
                mov   al,[0065h]
                and   al,0f7h
                out   dx,al
                mov   cs:Blackened,1
                pop   ds
                pop   dx
                pop   ax
                ret
endp

;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €  Multiplex Interrupt Specification, bare  €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

AsmInt2D        proc  far
                cmp   ah,cs:MPXno
                jz    My2D
Orig2D:         jmp   far dword:cs:[OldInt2DOfs]
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

;  €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;  €  Table of hooked vectors, readable from .pas  €
;  €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

Vectors:        db    08h
                dw    OldInt8Ofs
                dw    AsmInt8
                db    09h
                dw    OldInt9ofs
                dw    AsmInt9
                db    2Dh
                dw    OldInt2Dofs
                dw    AsmInt2D
                db    0

ends

