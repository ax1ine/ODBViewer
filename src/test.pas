unit test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { Tfrmtest }

  Tfrmtest = class(TForm)
    btnUpdateVessel: TButton;
    Memo1: TMemo;
    procedure btnUpdateVesselClick(Sender: TObject);
  private

  public

  end;

var
  frmtest: Tfrmtest;

implementation

{$R *.lfm}

{ Tfrmtest }

uses main;

procedure Tfrmtest.btnUpdateVesselClick(Sender: TObject);
Var
  id:integer;
  vessel_old, vessel, src:string;
begin
  with frmmain.Q1 do begin
    Close;
     SQL.Clear;
     SQL.Add('Select absnum, stvesselname from station order by absnum');
    Open;
  end;

  While not frmmain.Q1.eof do begin
    id:=frmmain.Q1.FieldByName('absnum').AsInteger;
    vessel_old:=frmmain.Q1.FieldByName('stvesselname').AsString;

    vessel_old:=trim(stringreplace(vessel_old, '"', '',[rfReplaceAll]));

    if copy(vessel_old,1,3)='ITP' then vessel_old:=copy(vessel_old,1,pos('__',vessel_old)-1);

    try
       with frmmain.Q2 do begin
        Close;
         SQL.Clear;
         SQL.Add('update station set stvesselname=:vessel ');
         SQL.Add('where absnum=:id ');
         Parambyname('id').AsInteger:=id;
         Parambyname('vessel').AsString:=vessel_old;
        ExecSQL;
      end;
        frmmain.TR.CommitRetaining;
      except
        frmmain.TR.RollbackRetaining;
        memo1.lines.add(vessel_old);
      end;

    {
    if pos('_', vessel_old)>0 then begin
      src:=copy(vessel_old, 1, pos('_', vessel_old)-1);
      vessel:=copy(vessel_old, Pos('_', vessel_old)+1, length(vessel_old));  }

  {  if pos('   ', vessel_old)>0 then begin
      src:=copy(vessel_old, 1, pos('   ', vessel_old)-1);
      vessel:=copy(vessel_old, Pos('   ', vessel_old)+1, length(vessel_old));

      try
       with frmmain.Q2 do begin
        Close;
         SQL.Clear;
         SQL.Add('update station set stsource=:src, stvesselname=:vessel ');
         SQL.Add('where absnum=:id ');
         Parambyname('id').AsInteger:=id;
         Parambyname('src').AsString:=src;
         Parambyname('vessel').AsString:=vessel;
        ExecSQL;
      end;
        frmmain.TR.CommitRetaining;
      except
        frmmain.TR.RollbackRetaining;
        memo1.lines.add(vessel_old);
      end;

    //  memo1.lines.Add(src+'   '+vessel);
    end;  }


   frmmain.Q1.Next;
  end;
  frmmain.TR.Commit;
end;

end.

