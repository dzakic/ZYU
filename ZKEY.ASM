;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €                  Z K E Y                 €
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
KBDhead         equ   1Ah
KBDtail         equ   1Ch
KBDbegin        equ   80h
KBDend          equ   82h
KBDstat         equ   17h
KBDestat        equ   18h
BitRsh          equ   1
BitLsh          equ   2
BitCtl          equ   4
BitAlt          equ   8
BitNuml         equ   32
BitCapsOn       equ   64
EBitLCtl        equ   1
EBitLAlt        equ   2
F1scan          equ   3Bh
F10scan         equ   44h
MinNumKey       equ   71
MaxNumKey       equ   83

AsmBegin:

;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €  Global vars, available from .pas        €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

Copyright       db    'dzakic  zkey    '
Ver             dw    0216h
MPXno           db    0
ProgON          db    1
Table           db    0
Tables          db    2
Side            db    0
HotKey          db    BITctl+BITalt

PrevScan        db    0
OldInt9Ofs      dw    0
OldInt9Seg      dw    0
OldInt2DOfs     dw    0
OldInt2DSeg     dw    0

;       40:17   byte    Keyboard flag byte 0 (see KB FLAGS)
;
;       	≥7≥6≥5≥4≥3≥2≥1≥0≥ keyboard flag byte 0
;       	 ≥ ≥ ≥ ≥ ≥ ≥ ≥ ¿ƒƒƒ right shift key depressed
;       	 ≥ ≥ ≥ ≥ ≥ ≥ ¿ƒƒƒƒ left shift key depressed
;       	 ≥ ≥ ≥ ≥ ≥ ¿ƒƒƒƒƒ CTRL key depressed
;       	 ≥ ≥ ≥ ≥ ¿ƒƒƒƒƒƒ ALT key depressed
;       	 ≥ ≥ ≥ ¿ƒƒƒƒƒƒƒ scroll-lock is active
;       	 ≥ ≥ ¿ƒƒƒƒƒƒƒƒ num-lock is active
;       	 ≥ ¿ƒƒƒƒƒƒƒƒƒ caps-lock is active
;       	 ¿ƒƒƒƒƒƒƒƒƒƒ insert is active
;
;       40:18	byte	Keyboard flag byte 1 (see KB FLAGS)
;
;       	≥7≥6≥5≥4≥3≥2≥1≥0≥ keyboard flag byte
;       	 ≥ ≥ ≥ ≥ ≥ ≥ ≥ ¿ƒƒƒ left CTRL key depressed
;       	 ≥ ≥ ≥ ≥ ≥ ≥ ¿ƒƒƒƒ left ALT key depressed
;       	 ≥ ≥ ≥ ≥ ≥ ¿ƒƒƒƒƒ system key depressed and held
;       	 ≥ ≥ ≥ ≥ ¿ƒƒƒƒƒƒ suspend key has been toggled
;       	 ≥ ≥ ≥ ¿ƒƒƒƒƒƒƒ scroll lock key is depressed
;       	 ≥ ≥ ¿ƒƒƒƒƒƒƒƒ num-lock key is depressed
;       	 ≥ ¿ƒƒƒƒƒƒƒƒƒ caps-lock key is depressed
;       	 ¿ƒƒƒƒƒƒƒƒƒƒ insert key is depressed

;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €  Global proc, available from .pas        €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€
;
;   DS=40h
;   CS=Asm Vars

AsmInt9         proc  far
                cmp   cs:ProgOn,1
                jz    MyInt
                jmp   dword cs:[OldInt9Ofs]
MyInt:          push  ax
                push  bx
                push  ds

                in    al,60h
                mov   bx,40h
                mov   ds,bx

                mov   ah,[KBDstat]
                and   ah,cs:HotKey
                cmp   ah,cs:HotKey
;               test  ah,cs:HotKey     - ne moße
                jnz   NoHotKey
                cmp   al,F1scan
                jb    NoHotKey
                cmp   al,F10scan
                ja    NoHotKey
                mov   ah,al
                sub   ah,F1scan
                cmp   ah,cs:Tables
                jae   NoHotKey
                mov   cs:Table,ah
;               int   1Bh
; EndInt:
                in    al,61h                  ;uzmi vrednost sa porta 61h
                mov   ah,al                   ;sacuvaj je
                or    al,80h                  ;setuj bit 7
                out   61h,al                  ;signaliziraj da je znak prihvaÜen
                mov   al,ah                   ;vrati staro stanje
                out   61h,al                  ;na port 61h

                mov   al,20h
                out   20h,al
                jmp   Skip

NoHotKey:       mov   bx,word ptr [KBDtail]
                pushf
                call  dword cs:[OldInt9Ofs]

                cmp   cs:PrevScan,0E0h
                mov   cs:PrevScan,al
                jz    Skip
                test  al,80h                       ; Break code?
                jnz   Skip                         ; Do Nothing
; Thanx to      cmp   bx,word ptr [KBDtail]        ; KBDtail changed
;  beast        jz    Skip                         ; No, Do Nothing
                mov   ah,cs:Table                  ; Active table
                cmp   ah,-1                        ; Driver active?
                jz    Skip                         ; No, skip

                push  cx
                push  dx
                push  si

                mov   dl,ah
                sub   dh,dh
                add   dx,dx                        ; x2
                mov   cx,dx
                add   dx,dx                        ; x4
                add   dx,cx                        ; x6
                add   dx,AsmEnd                    ; Addr of Tables
                mov   si,dx

                test  byte ptr [KBDstat],BitCtl    ; Stisnut Ctrl
                jz    TryAlt                       ; Nije, probaj Alt
                mov   ah,byte ptr [KBDestat]       ; Uzmi extended status
                xor   ah,cs:Side                   ; Side FF for left
                test  ah,EBitLCtl                  ; Stisnut Levi Ctrl
                jnz   TransOver                    ; Jeste, probaj Alt

                mov   si,cs:[si+2]                 ; RCtlTable
                call  Translate
                jmp   TransOver

TryAlt:         test  byte ptr [KBDstat],BitAlt    ; Stisnut Alt?
                jz    Normal                       ; Nije, nije niÁta
                mov   ah,byte ptr [KBDestat]       ; Uzmi extended status
                xor   ah,cs:Side                   ; Side FF for left
                test  ah,EBitLAlt                  ; Stisnut Levi Alt?
                jnz   TransOver                    ; Jeste, normal

                mov   si,cs:[si+4]                 ; RAltTable
                call  Translate
                jmp   TransOver

Normal:         mov   si,cs:[si]                   ; NormTable
                call  Translate

TransOver:      pop   si
                pop   dx
                pop   cx

Skip:           pop   ds
                pop   bx
                pop   ax
                iret
endp

Translate       proc  near
                mov   dh,cs:[si]
                or    dh,dh
                jz    Return
                mov   dl,dh
                and   dl,7Fh
                cmp   dl,al
                jz    Found
                add   si,3
                jmp   Translate

Found:          cmp   al,MinNumKey
                jb    NoNum
                cmp   al,MaxNumKey
                ja    NoNum
                test  byte ptr [KBDstat],BitNuml
                jz    Return
NoNum:          mov   cx,cs:[si+1]
                test  byte ptr [KBDstat],BitRsh+BitLsh
                jz    ShiftOff
                xchg  ch,cl
ShiftOff:       test  dh,80h
                jz    CapsOff
                test  byte ptr [KBDstat],BitCapsOn
                jz    CapsOff
                xchg  ch,cl
CapsOff:        cmp   cl,-1
                jz    Return
                mov   dx,bx
                cmp   dx,[KBDtail]         ;  Thanx to beast
                jnz   Fillin               ;
                inc   dx                   ;
                inc   dx                   ;
                cmp   dx,[KBDhead]         ;
                jz    Return               ;
                cmp   dx,[KBDend]          ;
                jne   NoBound              ;
                mov   dx,[KBDbegin]        ;
NoBound:        mov   [KBDtail],dx         ;
Fillin:         mov   [bx],cl
                cmp   cl,0F0
                jz    Poke
                cmp   cl,0E0
                jnz   Return
Poke:           mov   b:[bx+1],0
Return:         ret
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

Vectors:        db    09h
                dw    OldInt9ofs
                dw    AsmInt9
                db    2Dh
                dw    OldInt2Dofs
                dw    AsmInt2D
                db    0

ends

; Format tabele:
;    Prvo ide tabela sa pointerima na tabele.
;
;              dw     NormTable1
;              dw     CtrlTable1
;              dw     AltTable1
;
;              dw     NormTable2
;              dw     CtrlTable2
;              dw     AltTable2
;
;    i tako, koliko god ih ima (max 10). Ovi pointeri ukazuju na:
;
; NormTable1:  db     ScanCode, NormChar, ShiftChar
;              db     1Ah,      'Ñ',      'é'
;              db     1Bh,      'î',      'ô'
;              db     0
; CtrlTable1:  db     0
; AltTable1:   db     1Ah,      '[',      '{'
;              :
;              :
;              db     0
; * Na scan code treba dodati 80h, ukoliko taster treba da reaguje
;   na CAPS lock.
