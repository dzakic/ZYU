unit ZTSR;

interface

uses Zutl;

const FLGLo         = 1;      { Force lo mem install          }
      FLGHi         = 2;      { Refuse lo mem install         }
      FLGfirst      = 4;      { Force first fit for umb       }

      ErrNoHimem    = 250;
      ErrXMSbad     = 251;

      DOS           = {$IFDEF protect} 3 {$ELSE} $21 {$ENDIF};

      InstFlag      : byte = 0;

var   TSRPara       : word;
      Installed     : Boolean;
      MPXno         : byte;
      MPXavail      : Boolean;
      TSRver        : word;
      AllocStrat    : word;
      LinkState     : byte;
      Err           : word;
      Dos5Umbs      : Boolean;
      XMSpresent    : Boolean;
      XMSdriver     : pointer;

      TSRofs        : word;
      TSRseg        : word;

Procedure CheckInstalled(CopyRight:pointer);
Procedure AllocTSRMem;
Function  FreeTSRMem:Boolean;
Procedure LinkVectors(Vectors:pointer);
Function  UnLinkVectors(Vectors:pointer):Boolean;
Procedure ReturnMemState;
Procedure InitMemVars;

implementation

Procedure SetBlockName; assembler;
asm       mov   ax,TSRseg
          dec   ax
          mov   es,ax
          inc   ax
          mov   es:[1],ax           { Set MCB ownership       }
          mov   bx,PrefixSeg
          dec   bx
          push  ds
          mov   ds,bx
          mov   si,8
          mov   di,si
          mov   cx,4
          rep   movsw               { Copy TSRName to MCB     }
          pop   ds
end;

Procedure CheckInstalled;
var MPX:byte;
begin
  asm       push  ds
            mov   ax,seg @data
            mov   ds,ax
            mov   MPX,0             { ah=mpx #00h, al=func 00h (instlchk)     }
            mov   bx,$0001          { bh=00h, bl=01h: all mpx numbers in use  }
  @Loop:    mov   ah,MPX
            mov   al,0
            int   $2D               { check if int 2d/ah=xx is in use         }
            cmp   al,$FF            { multiplex number in use?                }
            je    @InUse
            or    bl,bl             { if bl=00h, free mpx exists         }
            je    @Next
            mov   bl,0
            mov   bh,MPX
            jmp   @Next
  @InUse:   mov   es,dx
            push  cx                { remember version number             }
            push  ds
            lds   si,CopyRight
            mov   cx,16/2           { length of signature string          }
            cld
            rep   cmpsw             { did we get our signature?           }
            pop   ds
            pop   cx                { retrieve version                    }
            jnz   @Next
            mov   Installed,true
            mov   TSRVer,cx
            mov   TSRseg,dx
            jmp   @Done
  @Next:    inc   MPX
            jnz   @Loop
            les   ax,CopyRight
            mov   TSRseg,es
            mov   Installed,false   { not yet installed                   }
            mov   ax,bx             { ah <- MPXno, al <- 'avail' flag     }
  @Done:    mov   MPXno,ah
            xor   al,1
            mov   MPXavail,al
            pop   ds
  end;
  if not Installed then exit;
  writeln('Found at ',hex4(TSRSeg),', Ver: ',Hex4(TSRVer),', MPXno: ',MPXno);
end;

Procedure InitMemVars; assembler;
asm       mov   ax,$5800                { Get current allocation strategy   }
          int   DOS
          mov   AllocStrat,ax           { And remember it for later restore }
          mov   ax,$5802                { Get current state of umb linkage  }
          int   DOS
          mov   LinkState,al            { And remember it for later restore }
          mov   ax,$3000                { Get dos version                   }
          int   DOS
          cmp   al,5                    { Dos 5.0 or higher?                }
          jb    @NoUMB
          cmp   al,10                   { Make sure not os/2 penalty box    }
          jae   @NoUMB
          mov   ax,$2B01                { Check desqview presence           }
          mov   cx,$4445                { 'DE'                              }
          mov   dx,$5351                { 'SQ'                              }
          int   DOS
          cmp   al,$FF                  { If yes, no umb's to be allocated  }
          jne   @NoUMB
          mov   ax,$5803
          mov   bx,1                    { Try to link in umbs               }
          int   DOS
          mov   ax,$5802                { Get new link state                }
          int   DOS
          cmp   al,1                    { Dos5Umbs exist ?                  }
          jz    @over                   { We have UMB                       }
@NoUMB:   mov   ax,$352F                { Try XMS                           }
          int   DOS
          mov   ax,es
          or    ax,bx                   { Don't try XMS if int 2F is null   }
          jz    @NoXMS                  { (could be case under dos 2.x)     }
          mov   ax,$4300                { See if XMS is installed           }
          int   $2F
          cmp   al,$80                  { Did xms respond?                  }
          jnz   @NoXMS
          mov   ax,$4310                { If xms present, get entry point   }
          int   $2F
          mov   word ptr [XMSdriver],bx
          mov   word ptr [XMSdriver+2],es
          mov   al,false
          jmp   @over
@NoXMS:   mov   XMSpresent,false
@over:    mov   Dos5Umbs,al
end;

Procedure ReturnMemState; assembler;
asm       mov   ax,$5801             { Restore allocation strategy }
          mov   bx,AllocStrat
          int   DOS
          mov   ax,$5803             { Restore UMP link status     }
          mov   bh,0
          mov   bl,LinkState
          int   DOS
end;

Function  FreeTSRMem:Boolean; assembler;
asm       mov   ax,TSRSeg
          cmp   ax,$B000
          jb    @Conv
          cmp   Dos5Umbs,true
          jnz   @TryXMS
@Conv:    mov   es,ax
          mov   ah,$49
          int   DOS
          jc    @Fail
          mov   al,1
          jmp   @Done
@TryXMS:  cmp   XMSpresent,true
          jnz   @Fail
          mov   dx,ax
          mov   ah,$11
          call  dword [XMSdriver]
          jmp   @Done
@Fail:    mov   Err,ax
          mov   al,0
@Done:
end;

Function AllocBestUMB(Size:word):word; assembler;
var Segment : word;
    RetSize : word;
asm       mov   dx,$FFFF
          mov   ah,$10
          call  dword [XMSdriver]
          mov   Segment,bx
          mov   RetSize,dx
          mov   bx,ErrXMSbad
          or    ax,ax
          jnz   @Err
          cmp   dx,Size
          mov   bx,8
          jb    @Err
          mov   ah,$10
          call  dword [XMSdriver]
          mov   Segment,bx
          mov   RetSize,dx
          mov   bx,8
          or    ax,ax
          jz    @Err
          mov   ax,Size
          push  ax
          call  AllocBestUMB
          mov   TSRseg,ax
          mov   dx,Segment
          mov   ah,$11
          call  dword [XMSdriver]
          mov   ax,TSRseg
          or    ax,ax
          jnz   @Done
          mov   dx,Size
          mov   ah,$10
          call  dword [XMSdriver]
          mov   ax,bx
          mov   cx,0
          mov   Err,cx
          jmp   @Done
@Err:     mov   Err,bx
          sub   ax,ax
@Done:
end;

Procedure AllocTSRMem;
begin
  asm       call  InitMemVars
            mov   TSRseg,0
            mov   Err,0
            test  InstFlag,FLGLo
            jnz   @Conv
            cmp   Dos5Umbs,true
            jnz   @TryXMS

            mov   bx,$41                  { UMB best fit }
            mov   ax,$5801
            int   DOS
            mov   ah,$48
            mov   bx,TSRpara
            int   DOS
            jc    @NoHimem
            jmp   @SuccAx

  @TryXMS:  cmp   XMSpresent,true
            jnz   @NoHimem
            mov   dx,TSRpara
            push  dx
            call  AllocBestUMB
            cmp   Err,8
            jz    @NoHimem
            jmp   @SuccAx

  @NoHimem: mov   Err,ErrNoHimem
            test  InstFlag,FLGHi
            jnz   @Done
  @Conv:    mov   ax,$5803
            mov   bx,$0000
            int   DOS

            mov   bx,$01                  { Try Lo best fit             }
            mov   ax,$5801
            int   DOS
            mov   ah,$48
            mov   bx,TSRpara
            int   DOS
            jc    @Done                   { Failed to alloc best, done }
            cmp   ax,PrefixSeg
            jb    @SuccAx
            mov   es,ax
            mov   ah,$49
            int   DOS

            mov   bx,$00                  { Try Lo first fit           }
            mov   ax,$5801
            int   DOS
            mov   ah,$48
            mov   bx,TSRpara
            int   DOS
            jc    @Done
            cmp   ax,PrefixSeg
            jb    @SuccAx
            mov   es,ax
            mov   ah,$49
            int   DOS

            mov   bx,$02                  { Try Lo last fit            }
            mov   ax,$5801
            int   DOS
            mov   ah,$48
            mov   bx,TSRpara
            int   DOS
            jc    @Done
  @SuccAx:  mov   TSRseg,ax
            mov   TSRofs,0
            call  SetBlockName
  @Done:    call  ReturnMemState
  end;
  if TSRSeg=0 then
  begin
    write('Cannot install. ');
    case Err of
      ErrNoHimem : writeln('No high memory available.');
      ErrXMSbad  : writeln('XMS broken.');
      7          : writeln('Memory Control Blocks destroyed.');
      8          : writeln('Insufficient memory.');
      else writeln;
    end;
    Halt(1);
  end;
end;

Procedure LinkVectors; assembler;
var TSRloc:word;
    IntNo:byte;
asm       push  ds
          mov   ax,TSRseg
          mov   TSRloc,ax
          lds   si,Vectors
  @loop:  lodsb
          or    al,al
          je    @Done
          mov   IntNo,al
          mov   ah,$35
          int   DOS
          mov   dx,es
          mov   cx,bx
          lodsw
          mov   bx,ax
          mov   es,TSRloc
          mov   es:[bx],cx
          mov   es:[bx+2],dx
          lodsw
          mov   dx,ax
          push  ds
          mov   ds,TSRloc
          mov   al,IntNo
          mov   ah,$25
          int   DOS
          pop   ds
          jmp   @loop
  @Done:  pop   ds
end;

Function UnLinkVectors; assembler;
var OldSeg,OldOfs,TSRloc:word;
    IntNo:byte;
asm       push  ds
          mov   ax,TSRseg
          mov   TSRloc,ax
          lds   si,Vectors
  @loop1: lodsb
          or    al,al
          je    @Done1
          mov   ah,$35
          int   DOS
          mov   ax,es
          cmp   ax,TSRloc
          jnz   @False
          lodsw
          lodsw
          cmp   bx,ax
          jnz   @False
          jmp   @loop1
  @Done1: lds   si,Vectors
  @loop2: lodsb
          or    al,al
          je    @True
          mov   IntNo,al
          mov   ax,TSRloc
          mov   es,ax
          lodsw
          push  ds
          mov   bx,ax
          mov   dx,es:[bx]
          mov   ax,es:[bx+2]
          mov   ds,ax
          mov   ah,$25
          mov   al,IntNo
          int   DOS
          pop   ds
          lodsw
          jmp   @loop2
  @True:  mov   ax,1
          jmp   @Done
  @False: sub   ax,ax
  @Done:  pop   ds
end;

begin
  asm     mov   ax,PrefixSeg
          mov   es,ax
          mov   bx,es:[$2C]
          mov   es,bx
          mov   ah,$49
          int   $21
  end;
end.
