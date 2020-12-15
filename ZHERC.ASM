;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €                 Z H E R C                €
;   €               assembly code              €
;   €˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙˙€
;   €  (c) Copyright Nov 1994 by Dragan ZakiÜ  €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

code segment public
public          AsmBegin
public          AsmActivate
public          AsmDeactivate
public          AsmRefresh
public          InitAddrTable
public          AsmEnd
public          CharTable
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

Copyright       db    'dzakic  zherc   '
Ver             dw    0346h
MPXno           db    0
ProgON          db    false
BoldON          db    true
LineCurs        db    off
MaxPrint        dw    500
Flash           db    4
HotKey          db    BITctl+BITalt

;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €  Local vars, unavailable from .pas       €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

Busy            db    false
Index           dw    0
Cpos            dw    0
Counter         dw    0
Begaj           db    0
ChrAtCurs       dw    0
VideoAddr       dw    0
Attribute       db    0
AddrTable       dw    25 dup 0

OldInt8Ofs      dw    0
OldInt8Seg      dw    0
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
                push  ds
                push  si
                push  di
                push  dx
                push  cx
                push  bx
                push  cs
                pop   ds
                mov   ProgOn,false
                mov   si,TextTable
                call  Switch
                mov   bh,0                    ;nulta video stranica
                mov   ah,03                   ;uzmi veliÅinu i poziciju u cx i dx
                int   10h                     ;pozivom VIDEO prekida
                mov   ah,02                   ;ostavljamo BIOS-u da u registre
                int   10h                     ;video kontrolera upiÑe vrednosti
                mov   ah,01                   ;za podeÑavanje veliÅine
                int   10h                     ;i pozicije kursora
                pop   bx
                pop   cx
                pop   dx
                pop   di
                pop   si
                pop   ds
                ret
endp

;   ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;   Activate proc
;   ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

AsmActivate     proc  far
                push  ds
                push  si
                push  di
                push  cs
                pop   ds
                cmp   ProgON,true
                jnz   ProgNotOn
                push  cs
                call  near AsmRefresh
ProgNotOn:      mov   si,GraphTable
                call  Switch
                mov   ProgON,true
                pop   di
                pop   si
                pop   ds
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
endp

;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €  Video service, avoid bios video reset  €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

AsmInt10        proc  far
                or    ah,ah                   ;da li je u pitanju funkcija 0
                jnz   Done10
                cmp   cs:ProgOn,true          ;da li je rutina ukljuüena?
                jnz   Done10
                push  ds
                push  es
                push  di
                push  cx
                mov   ax,0B000h
                mov   es,ax
                sub   di,di
                mov   cx,800h
                mov   ax,0720h
                rep   stosw
                push  cs
                call  near AsmRefresh          ;inicijalizuj grafiÅki ekran
                push  cs
                call  near AsmActivate
                mov   ax,40h
                mov   es,ax
                sub   ax,ax
                mov   es:[50h],ax
                pop   cx
                pop   di
                pop   es
                pop   ds
                iret
Done10:         jmp   dword cs:[OldInt10ofs]
endp

;   €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;   €  Real stuff, Timer interrupt            €
;   €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

AsmInt8         proc  far
                pushf
                call  dword cs:[OldInt8ofs]
                cmp   cs:ProgOn,true
                jnz   Done8
                cmp   cs:Busy,true
                jnz   Begin
                mov   cs:Begaj,true
Done8:          iret
Begin:          push  ax
                mov   al,00001011xB
                out   20h,al
                in    al,20h
                and   al,11111110xB
                pop   ax
                jnz   Done8
                mov   cs:Busy,true           ;osveÇavanje u toku
                mov   cs:Begaj,false         ;vreme nije isteklo
                sti
                push  ax
                push  bx
                push  cx
                push  dx
                push  di
                push  si
                push  ds
                push  es
                mov   ax,cs:MaxPrint
                mov   cs:Counter,ax
                cld
                mov   ax,40h
                mov   ds,ax
                mov   cx,[50h]                ;uzmi poziciju kursora
                mov   ax,[60h]                ;uzmi veliÅinu kursora
                cmp   ah,al                   ;da li je vidljiv?
                jna   CursVisible1
                mov   cx,0FFFFh               ;ako nije, postavi ilegalnu poziciju kursora
CursVisible1:   mov   al,[6Ch]                ;uzmi brojaÅ koji uveÜava tajmer 18 puta u sec.
                and   al,cs:Flash             ;maskiraj jedan od bitova
                jz    CursFlashes
                mov   cx,0FFFFh
CursFlashes:    mov   ax,0B000h
                mov   ds,ax
                mov   ax,0B700h
                mov   es,ax
                mov   al,ch                   ;al=red u kome je kursor
;               cbw
                mov   ah,0
                add   ax,ax                   ;x2
                add   ax,ax                   ;x4
                add   ax,ax                   ;x8
                add   ax,ax                   ;x16
                mov   bx,ax
                add   ax,ax                   ;x32
                add   ax,ax                   ;x64
                add   ax,bx                   ;+16=80
                mov   bl,cl                   
                mov   bh,0                    ;bx=kolona u kojoj je kursor
                add   ax,bx                   ;ax=ax+bx
                add   ax,ax                   ;ax mnoÇimo sa dva
                cmp   ax,80*25*2              ;da li je kursor vidljiv
                jb    CursVisible2
                mov   ax,80*25*2
CursVisible2:   mov   di,ax                   ;karakter ispod kursora
                mov   cs:Cpos,di              ;saÅuvaj poziciju kursora
                mov   ax,ds:[di]              ;uzmi karakter na mestu kursora
                mov   cs:ChrAtCurs,ax         ;saÅuvaj za kasnije
                inc   ax                      ;nek se na cpos karakter obavezno
                mov   es:[di],ax              ;razlikuje
                mov   si,cs:Index             ;dokle smo stigli?
                cmp   si,80*25*2              ;da li je proÑli put sve zavrÑeno?
                jb    Continue1
                sub   si,si                   ;ako jesmo, kreÜemo od poÅetka
Continue1:      mov   di,si                   ;di=si
Repeat:         mov   cx,80*25*2              ;cx uzima maksimalnu vrednost
                sub   cx,si                   ;oduzimamo poziciju
                shr   cx,1                    ;mnoÇimo sa dva zbog atributa
Search:         repe  cmpsw                   ;poreîenje video memorije sa baferom
                jz    SearchEnd               ;ako su jednaki, kraj
                call  Update                  ;ako nisu, aÇurirati stanje na ekranu
                or    cx,cx                   ;da li je zavrÑeno sa poreîenjem
                jz    SearchEnd               ;ako jeste, kraj
                dec   cs:Counter              ;umanji brojaÅ
                jz    SearchEnd               ;ako je prikazano maxprint karaktera, kraj
                cmp   cs:Begaj,true           ;da li je isteklo vreme?
                jnz   Search                  ;ako nije, poredi dalje
                cmp   cs:MaxPrint,0
                jnz   Search
SearchEnd:      mov   cs:Index,si             ;upamti dokle smo stigli
                pop   es
                pop   ds
                pop   si
                pop   di
                pop   dx
                pop   cx
                pop   bx
                pop   ax
                mov   cs:Busy,false           ;signaliziraj kraj
                iret                          ;povratak iz interapta
endp

;   ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;   Update Proc
;   ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

Update          proc  near
                dec   si                      ;smanji si
                dec   si                      ;za dva
                mov   ax,[si]                 ;uzmi karakter koji ne odgovara onom u baferu
                cmp   si,cs:Cpos              ;da li smo stali na mestu kursora?
                jnz   CommonChr               ;ako nismo, aÇuriraj
                cmp   cs:[LineCurs],on
                jnz   BlockCurs
                mov   ah,1
                jmp   DrawCursor
BlockCurs:      and   ah,01110111xB           ;maskiraj inverzni atribut
                cmp   ah,01110000xB           ;da li je kursor na inverznoj pozadini
                mov   ah,112                  ;ako nije, invertuj karakter
                jnz   DrawCursor
                mov   ah,7                    ;ako jeste, atribut je sedam
DrawCursor:     cmp   ax,cs:ChrAtCurs         ;da li je na mestu kursora ispisan karakter koji treba
                jnz   CommonChr               ;ako nije, ispiÑi ga
                mov   es:[di-2],ax            ;ako jeste, zapiÑi to u bafer
                mov   si,di                   ;uveÜaj si za dva
                ret                           ;povratak
CommonChr:      push  es
                push  ds
                push  si
                push  di
                push  dx
                push  cx
                push  ax
                mov   ax,0B700h               ;ds=segment bafera
                mov   ds,ax
                mov   ax,0B800h               ;es=segment grafiÅke video memorije
                mov   es,ax
                pop   ax
                mov   [si],ax                 ;update video buffer
                mov   ax,si                   ;offset karaktera iz text video memorije
                shr   ax,1
                mov   bl,80                   ;delimo sa 160
                div   bl                      ;da dobijemo red
                mov   bl,al                   ;stavimo u bl
                mov   bh,0
                add   bx,bx                   ;bx mnoÇimo sa dva
                mov   di,cs:AddrTable[bx]     ;uzimamo adresu u video memoriji iz tabele
                mov   bl,ah
                mov   cl,ah
                and   cl,7
                shr   bl,1
                shr   bl,1
                shr   bl,1
                add   bl,ah
                mov   bh,0
                add   di,bx
                mov   ax,[si]
                push  cs
                pop   ds
                call  write
                pop   cx
                pop   dx
                pop   di
                pop   si
                pop   ds
                pop   es
                mov   si,di
                ret
endp

;   ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;   Update Proc
;   ulaz: al=char, cl=broj shiftovanja,
;         di=video adresa
;   ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

Write           proc  near
                mov   cs:Attribute,ah
                test  ah,01110111xB
                jnz   ChrVisible
                mov   al,' '
ChrVisible:     mov   ah,0
                push  ax
                and   al,11100000xB
                mov   bl,1
                cmp   al,11000000xB
                jnz   L1
                mov   bl,0
L1:             pop   ax
                add   ax,ax           ;x2
                mov   dx,ax           ;pamti 2
                add   ax,ax           ;x4
                add   ax,ax           ;x8
                add   ax,ax           ;x16
                sub   ax,dx           ;x14
                add   ax,offset CharTable
                mov   si,ax
                mov   ch,14
                mov   VideoAddr,di
                mov   dx,0111111100000000xB
                ror   dx,cl
                or    bl,bl
                jz    SpecialGraph

P1:             and   es:[di],dx
                lodsb
                mov   ah,0
                ror   ax,cl
                or    es:[di],ax
                add   di,2000h
                test  di,8000h
                jz    AddrOk1
                add   di,90d-8000h
AddrOk1:        dec   ch
                jnz   P1
                jmp   Continue2

SpecialGraph:
P2:             and   es:[di],dx
                lodsb
                mov   ah,0
                mov   bh,al
                ror   ax,1
                mov   al,bh
                ror   ax,cl
                or    es:[di],ax
                add   di,2000h
                test  di,8000h
                jz    AddrOk2
                add   di,90d-8000h
AddrOk2:        dec   ch
                jnz   P2

Continue2:      mov   ah,cs:attribute
                and   ah,01110111xB
                cmp   ah,01110000xB
                jnz   Underline
                mov   ch,14
                mov   di,VideoAddr
                mov   ax,1000000011111111xB
                ror   ax,cl
I1:             xor   es:[di],ax
                add   di,2000h
                test  di,8000h
                jz    AddrOk3
                add   di,90d-8000h
AddrOk3:        dec   ch
                jnz   I1
                ret

Underline:      mov   ah,cs:Attribute
                and   ah,00000111xB
                cmp   ah,00000001xB
                jnz   bright
                sub   di,2000h
                test  di,8000h
                jz    AddrOk4
                sub   di,90-8000h
AddrOk4:        mov   ax,1000000011111111xB
                ror   ax,cl
                xor   es:[di],ax
Bright:         mov   ah,cs:attribute
                and   ah,0001000xB
                cmp   ah,0001000xB
                jnz   ret
                cmp   cs:BoldOn,true
                jnz    ret
                mov   di,VideoAddr
                mov   ch,14
                mov   bx,0000000011111111xB
                ror   bx,cl
B1:             mov   ax,es:[di]
                and   ax,bx
                ror   ax,1
                or    es:[di],ax
                add   di,2000h
                test  di,8000h
                jz    AddrOk5
                add   di,90d-8000h
AddrOk5:        dec   ch
                jnz   B1
                ret
endp

AsmRefresh      proc  far
                push  es
                push  di
                push  cx
                push  ax

                mov   ax,0B700h
                mov   es,ax
                sub   di,di
                mov   cx,800h
                mov   ax,0720h
                rep   stosw

                mov   cx,4000h
                sub   ax,ax
                rep   stosw

                mov   cs:Index,0

                pop   ax
                pop   cx
                pop   di
                pop   es
                retf
endp

;   ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;   Herc Graph routines
;   ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

TextTable:      db 02h,00h
                db 61h,50h,52h,0Fh,19h,06h,19h,19h
                db 02h,0Dh,0Bh,0Ch,00h,00h,00h,00h
                db 28h

GraphTable:     db 03h,82h,
                db 35h,2Dh,2Eh,07h,5Bh,02h,58h,58h
                db 02h,03h,00h,00h,00h,00h,00h,00h
                db 8Ah

Switch          proc  near
                push  cx
                push  dx
                lodsb                  ;uzmi vrednost iz tabele
                mov   dx,3BFh          ;port za konfigurisanje video karte
                out   dx,al            ;upis vrednosti na port
                lodsb                  ;uzmi vrednost iz tabele
                mov   dx,3B8h          ;port za izbor reÇima rada video karte
                out   dx,al            ;upis vrednosti na port
                mov   dx,3B4h          ;port za adresiranje registra
                mov   cx,10h           ;postavlja se 16 registara
                mov   ah,0             ;poÅinjemo od prvog registra
SwLoop:         mov   al,ah            ;adresa ide u al
                out   dx,al            ;pozivanje izabranog registra
                inc   dx               ;na port 3B5 upisujemo sadrÇaj registra
                lodsb                  ;uzmi vrednost
                out   dx,al            ;poÑalji na port 3B5
                dec   dx               ;vrati dx na 3B4
                inc   ah               ;pozivna adresa sledeÜeg registra
                loop  SwLoop           ;ponovi za sve registre video kontrolera
                lodsb                  ;sledeÜa vrednost iz tabele
                mov   dx,3B8h          ;predstavlja nov konfiguracioni bajt
                out   dx,al            ;poÑalji je na port

                push  ds
                push  ax
                mov   ax,40h
                mov   ds,ax
                pop   ax
                mov   [0065],al
                pop   ds

                pop   dx
                pop   cx
                ret
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

Address         proc  near
                mov   ax,14
                mul   bl           ;na izlazlu adresu video memorije u di
                mov   di,ax        ;detaljnije objaÑnjenje u "RaÅunarima" 55
                and   di,0003h
                ror   di,1
                ror   di,1
                ror   di,1
                shr   ax,1
                shr   ax,1
                mov   dx,ax
                shl   ax,1
                shl   ax,1
                add   ax,dx
                shl   ax,1
                mov   dx,ax
                shl   ax,1
                shl   ax,1
                shl   ax,1
                add   ax,dx
                add   di,ax
                ret
endp

InitAddrTable   proc  far
                push  ds
                push  cs
                pop   ds
                mov   si,offset AddrTable     ;ofset tabele
                mov   bl,0                    ;oÅisti bl
                mov   cx,25                   ;25 redova je na ekranu
Table:          call  Address                 ;izraÅunaj adresu reda bl
                mov   [si],di                 ;upiÑi je u tabelu
                inc   bl                      ;sledeÜi red
                inc   si                      ;sledeÜe mesto
                inc   si                      ;u tabeli
                loop  Table                   ;ponovi cx puta
                pop   ds
                ret                           ;povratak iz potprograma
endp

;  €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
;  €  Table of hooked vectors, readable from .pas  €
;  €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

Vectors:        db    08h
                dw    OldInt8ofs
                dw    AsmInt8
                db    09h
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
