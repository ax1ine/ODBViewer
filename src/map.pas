unit map;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  main, DB, map_kml, procedures, map_globctrl, map_datastreams, map_settings;

type

  { Tfrmmap }

  Tfrmmap = class(TForm)
    MainGlobe : TGlobeControl;
    pmap: TPanel;
    ToolBar1: TToolBar;
    btnZoomIn: TToolButton;
    btnZoomOut: TToolButton;
    btnKMLExport: TToolButton;
    btnShowSelected: TToolButton;
    btnShowAllStations: TToolButton;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    btnSettings: TToolButton;
    btnSaveMapAs: TToolButton;

    procedure btnKMLExportClick(Sender: TObject);
    procedure btnSaveMapAsClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnShowAllStationsClick(Sender: TObject);
    procedure btnShowSelectedClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure btnZoomInClick(Sender: TObject);
    procedure btnZoomOutClick(Sender: TObject);
    procedure ChangeID;

  private

  public

  end;

var
  frmmap: Tfrmmap;


implementation

{$R *.lfm}

{ Tfrmmap }



procedure Tfrmmap.FormCreate(Sender: TObject);
begin
  // Loading the globe
  MainGlobe := TGlobeControl.Create(Self);
  MainGlobe.Align := alClient;
  MainGlobe.Parent := pmap;

  MainGlobe.Marker.Lat := frmmain.CDS.FieldByName('stlat').AsFloat;
  MainGlobe.Marker.Lon := frmmain.CDS.FieldByName('stlon').AsFloat;

  MainGlobe.CheckSettings;
end;

procedure Tfrmmap.ChangeID;
begin
  MainGlobe.ChangeID;
End;

procedure Tfrmmap.btnShowAllStationsClick(Sender: TObject);
begin
  MainGlobe.ShowAllStations;
end;

procedure Tfrmmap.btnKMLExportClick(Sender: TObject);
begin
  btnKMLExport.Enabled:=false;
  try
    ExportKML_;
  finally
    btnKMLExport.Enabled:=true;
  end;
end;

procedure Tfrmmap.btnSaveMapAsClick(Sender: TObject);
Var
  bmp : TBitmap;
  png : TPortableNetworkGraphic;
  Src: TRect;
  Dest: TRect;
begin
frmmain.SD.DefaultExt:='.bmp';
frmmain.SD.Filter:='Bitmap|*.bmp';

 if frmmain.SD.Execute then begin
   try
     bmp := TBitmap.Create;
     bmp.Width :=pmap.Width;
     bmp.Height:=pmap.Height;

     Dest:= Rect(0, 0, pmap.Width, pmap.Height);
     Src := Rect(0, 0, pmap.Width, pmap.Height);

     bmp.Canvas.CopyRect(Dest, pmap.Canvas, Src);
     bmp.SaveToFile(frmmain.SD.FileName);
  finally
    bmp.Free;
  end;
 end;

{  png := TPortableNetworkGraphic.Create;
  try
    png.Assign(FBufferBitmap);
    png.SaveToFile(fname);
  finally
    png.Free;
  end; }
end;

procedure Tfrmmap.btnShowSelectedClick(Sender: TObject);
begin
  MainGlobe.ShowSelectedStation;
end;

procedure Tfrmmap.btnZoomInClick(Sender: TObject);
begin
  MainGlobe.ZoomIn;
end;

procedure Tfrmmap.btnZoomOutClick(Sender: TObject);
begin
  MainGlobe.ZoomOut;
end;

procedure Tfrmmap.btnSettingsClick(Sender: TObject);
begin
frmmap_settings := Tfrmmap_settings.Create(Self);
 try
  if not frmmap_settings.ShowModal = mrOk then exit;
 finally
   frmmap_settings.Free;
   frmmap_settings := nil;
   MainGlobe.CheckSettings;
   ChangeID;
 end;
end;

procedure Tfrmmap.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
 frmmap_open:=false;
end;


end.

