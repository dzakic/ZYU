unit ZCMD;

interface

uses Zutl;

const ParamNone       = 0;
      ParamBoolean    = 1;
      ParamInteger    = 2;
      ParamStringNext = 3;
      ParamString     = 4;
      PreExec         = $80;

type  Cmd = record
              Name : pchar;
              Proc : Procedure;
              Par  : byte;
            end;
      CmdPtr = ^Cmd;

{ Name:  "option[:p]" gde je p "b" za boolean
                                "n" za numerik (integer)
  Ime ne sme sadr‚ati znak ":" }

var ValueBoolean : Boolean;
    ValueInteger : integer;
    ValueString  : String[80];

Procedure DoCmds(C:CmdPtr; MaxCmd:integer; t:Boolean);

implementation

Procedure DoCmds;
var ParamNo    : integer;
    s          : string;
    i,j        : integer;
    p          : pchar;
    count      : integer;
    index      : integer;
    maxmatch   : integer;
    CC,MC      : CmdPtr;
begin
  for ParamNo:=1 to ParamCount do
  begin
    s:=LowerCase(ParamStr(ParamNo));
    count:=0; maxmatch:=0;
    CC:=C;
    for i:=1 to MaxCmd do
    begin
      p:=CC^.Name;
      j:=1;
      if p^<>'/' then if (s[1]='/') or (s[1]='-') then j:=2;
      while (s[j]=p^) and (j<=length(s)) do begin inc(j); inc(p) end;
      if j>maxmatch then
      begin
        count:=1;
        index:=j;
        maxmatch:=j;
        MC:=CC;
        if p^=#0 then break;
      end else if j=maxmatch then inc(count);
      inc(CC);
    end;
    if count<>1 then
    begin
      writeln('Unknown command: ',s);
      Halt(1);
    end else
    begin
      j:=MaxMatch;
      if s[j]=':' then inc(j);
      Delete(s,1,j-1);
      case (MC^.Par and 7) of
      ParamNone:
        if s<>'' then
        begin
          writeln('Error: '#39,ParamStr(ParamNo),#39'? Unknown command');
          Halt(1);
        end;
      ParamBoolean:
        begin
          if s='+' then ValueBoolean:=true else
          if s='-' then ValueBoolean:=false else
          begin
            writeln('Error: '#39,s,#39'? +/- expected.');
            Halt(1);
          end;
        end;
      ParamInteger:
        begin
          Val(s,ValueInteger,j);
          if j<>0 then
          begin
            writeln('Error: '#39,s,#39'? Bad numeric.');
            Halt(1);
          end;
        end;
      ParamStringNext:
        begin
          ValueString:=ParamStr(ParamNo+1);
          if ParamNo<ParamCount then inc(ParamNo);
        end;
      ParamString:
        begin
          ValueString:=s;
        end;
      else;
      end; {case}
      if t xor (MC^.Par and PreExec <> 0) then MC^.Proc;
    end;
  end;
end;

end.
