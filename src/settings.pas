unit settings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, IniFiles;

type

  { Tfrmsettings }

  Tfrmsettings = class(TForm)
    Button2: TButton;
    eOceanFDB: TEdit;
    Label2: TLabel;

    procedure FormShow(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);

  private

  public

  end;

var
  frmsettings: Tfrmsettings;

implementation

{$R *.lfm}

{ Tfrmsettings }

uses main;


procedure Tfrmsettings.FormShow(Sender: TObject);
Var
  Ini:TIniFile;
begin
 Ini := TIniFile.Create(IniFileName);
  try
    eOceanFDB.Text :=Ini.ReadString( 'osmain', 'oceanfdb', '');
  finally
    Ini.Free;
  end;
end;

procedure Tfrmsettings.Button2Click(Sender: TObject);
begin
  frmmain.OD.Filter:='Firebird database|*.fdb;*.FDB';
  if frmmain.OD.Execute then
    eOceanFDB.Text:=frmmain.OD.FileName;
end;

procedure Tfrmsettings.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
Var
  Ini:TIniFile;
begin
 Ini := TIniFile.Create(IniFileName);
  try
    Ini.WriteString( 'osmain', 'oceanfdb', eOceanFDB.Text);
  finally
    Ini.Free;
  end;
end;



end.

