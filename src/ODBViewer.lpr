program ODBViewer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, main, icons, test, load_kirillov, load_iarc, tachartlazaruspkg, export_DIVA;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(Tfrmmain, frmmain);
  Application.CreateForm(Tfrmicons, frmicons);
  Application.CreateForm(Tfrmtest, frmtest);
  Application.Run;
end.

