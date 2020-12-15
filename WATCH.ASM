;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €                  W A T C H               €
;   €                assembly code             €
;   €˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙€
;   €  (c) Copyright Jun 1996 by Dragan ZakiÜ  €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

code segment public
public          AsmBegin
public          AsmActivate
public          AsmDeactivate
public          AsmEnd
public          Vectors

On              equ   1
Off             equ   0
true            equ   1
false           equ   0

AsmBegin:

;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €  Global vars, available from .pas        €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

Copyright       db    'dzakic  watch   '
Ver             dw    0014h
MPXno           db    0
ProgON          db    false

VidMem          dw    0B800h
Counter         dw    0
TimeOut         dw    5000
DTRLimit        dw    4000
Port            dw    0
PortAddr        dw    0

OldInt8Ofs      dw    0
OldInt8Seg      dw    0
OldInt2DOfs     dw    0
OldInt2DSeg     dw    0

hex             db   '0123456789ABCDEF'


;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €  Timer tick interrupt 8                    €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

AsmInt8         proc  far
                pushf
                call    far cs:d:[OldInt8Ofs]
                sti
                push    ax
                inc     cs:Counter
                mov     ax,cs:Counter
                cmp     ax,cs:DTRlimit
                jz      LimitExceeded
                cmp     ax,cs:Timeout
                jz      Reboot
Exit8:          test    ax,7
                jnz     quit8
                shr     ax,3
                push    es
                push    si
                push    dx
                push    cx
                push    bx
                mov     dx,ax
                mov     cl,4
                mov     ax,cs:Vidmem
                mov     es,ax
                mov     si,158
                mov     bx,offset hex
Petljica:       mov     ax,dx
                and     ax,0fh
                cs:     xlat
                mov     ah,79
                mov     es:[si],ax
                dec     si
                dec     si
                shr     dx,4
                dec     cl
                jnz     Petljica
                pop     bx
                pop     cx
                pop     dx
                pop     si
                pop     es
Quit8:          pop     ax
                iret

LimitExceeded:  call    DropDTR
                jmp     Exit8

DropDTR:        push    dx
                mov     dx,cs:PortAddr
                add     dx,4
                in      al,dx
                and     al,0FEh
                out     dx,al
                pop     dx
                ret

Reboot:         call    DropDTR
                mov     ax,40h
                mov     ds,ax
                mov     w:[72h],9abch
                cli
                xor     ax,ax
                mov     ds,ax
                mov     es,ax
                mov     ss,ax
                mov     sp,ax
cp:             in      al,64h          ; wait on at keyboard controller
                test    al,2
                jne     cp
                xor     al,al           ; try reset lines
                out     64h,al
                nop
                nop
                mov     al,0feh
                out     64h,al
                nop
                nop
                push    00002h
                push    0f000h
                push    0fff0h
                iret

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

Vectors:        db    08h
                dw    OldInt8ofs
                dw    AsmInt8
                db    2Dh
                dw    OldInt2Dofs
                dw    AsmInt2D
                db    0

ends
