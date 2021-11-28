unit profile_plot_all;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF WINDOWS}
    UXTheme,
  {$ENDIF}

  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, IniFiles, SQLDB, Variants, Types, TAGraph, TATools, TASeries, DB,
  TATypes, TACustomSeries, TAChartUtils, TAEnumerators, BufDataset;

type

  { Tfrmprofile_plot_all }

  Tfrmprofile_plot_all = class(TForm)
    Chart1: TChart;
    ChartToolset1: TChartToolset;
    DPH: TDataPointHintTool;
    DPC: TDataPointClickTool;
    ToolBar1: TToolBar;
    btnNext: TToolButton;
    btnPrior: TToolButton;
    ZD: TZoomDragTool;
    ZMW: TZoomMouseWheelTool;

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure btnPriorClick(Sender: TObject);
    procedure DPCPointClick(ATool: TChartTool; APoint: TPoint);
    procedure DPHAfterMouseMove(ATool: TChartTool; APoint: TPoint);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormDestroy(Sender: TObject);

  private
    function AddLineSeries (AChart: TChart; sName:string):TLineSeries;
    function AddPointSeries(AChart: TChart; sName:string):TLineSeries;
    procedure HighlightSeries(ASeries: TBasicChartSeries);
    procedure SelectProfile(sname:string);
    procedure InitialPlot;

  public
    procedure AddToPlot(ID:integer; ToUpdate:boolean);
    procedure ChangeID(ID:integer);
  end;

var
  frmprofile_plot_all: Tfrmprofile_plot_all;
  mik:integer;


implementation

{$R *.lfm}

{ Tfrmprofile_plot_all }

uses main, parameters_list;


function Tfrmprofile_plot_all.AddLineSeries(AChart: TChart; sName:string): TLineSeries;
begin
 Result := TLineSeries.Create(AChart.Owner);
  with TLineSeries(Result) do begin
    Title := sName;
    ShowPoints := false;
    ShowLines := true;
    LinePen.Style := psSolid;
    SeriesColor := clGray;
    Name := sName;
    ToolTargets := [nptPoint, nptYList, nptCustom];
  end;
 AChart.AddSeries(Result);
end;


function Tfrmprofile_plot_all.AddPointSeries(AChart: TChart;sName:string): TLineSeries;
begin
 Result := TLineSeries.Create(AChart.Owner);
  with TLineSeries(Result) do begin
    Title := sname;
    ShowPoints := true;
    Pointer.Brush.Color := clGray;
    Pointer.Pen.Color := clBlack;
    Pointer.Style := psCircle;
    ShowLines := false;
    Name := sName;
  end;
 AChart.AddSeries(Result);
end;


procedure Tfrmprofile_plot_all.FormCreate(Sender: TObject);
Var
  Ini:TInifile;
  k, top_pos:integer;
begin
 Ini := TIniFile.Create(IniFileName);
  try
    Top   :=Ini.ReadInteger( 'osprofile_plot_all', 'Top',  100);
    Left  :=Ini.ReadInteger( 'osprofile_plot_all', 'Left', 100);
    Width :=Ini.ReadInteger( 'osprofile_plot_all', 'Width',  600);
    Height:=Ini.ReadInteger( 'osprofile_plot_all', 'Height', 600);
  finally
   Ini.Free;
  end;
end;


procedure Tfrmprofile_plot_all.FormShow(Sender: TObject);
begin
 InitialPlot;
end;


procedure Tfrmprofile_plot_all.InitialPlot;
Var
ID, CurrentID:integer;
begin

 mik:=-1;
 Chart1.Series.Clear;
  try
   CurrentID:=frmmain.CDS.FieldByName('absnum').AsInteger;

   frmmain.CDS.DisableControls;
   frmmain.CDS.First;

     While not frmmain.CDS.Eof do begin
      ID:=frmmain.CDS.FieldByName('absnum').AsInteger;
        AddToPlot(ID, false);
      frmmain.CDS.Next;
     end;

   finally
     frmmain.CDS.Locate('absnum',CurrentID,[]);
     frmmain.CDS.EnableControls;
   end;

 ChangeID(CurrentID);

 Caption:=CurrentParTable+', '+inttostr(Chart1.SeriesCount)+' profiles';

Application.ProcessMessages;
end;

procedure Tfrmprofile_plot_all.ChangeID(ID:integer);
begin
 SelectProfile('s'+inttostr(ID));
end;


procedure Tfrmprofile_plot_all.AddToPlot(ID:integer; ToUpdate:boolean);
Var
k:integer;
lev, val1:real;
sName:TComponentName;

TRt:TSQLTransaction;
Qt:TSQLQuery;
begin

TRt:=TSQLTransaction.Create(self);
TRt.DataBase:=frmmain.DB1;

Qt:=TSQLQuery.Create(self);
Qt.Database:=frmmain.DB1;
Qt.Transaction:=TRt;
try

    with Qt do begin
     Close;
      SQL.Clear;
      SQL.Add(' SELECT * ');
      SQL.Add(' FROM '+ CurrentParTable );
      SQL.Add(' WHERE ABSNUM=:ID ');
      SQL.Add(' AND LEVEL_<=150 ');
      SQL.Add(' ORDER BY LEVEL_');
      ParamByName('ID').AsInteger:=ID;
     Open;
     Last;
     First;
    end;

   sName:='s'+inttostr(ID);

   if ToUpdate = true then begin
    for k:=0 to Chart1.SeriesCount-1 do
     if Chart1.Series[k].Name=sName then begin
       TLineSeries(Chart1.Series[k]).Clear;
       mik:=k;
       break;
     end;
   end;

  if (ToUpdate = true) and (Qt.IsEmpty=true) then
      TLineSeries(Chart1.Series[mik]).Free;


  if not Qt.IsEmpty then begin
   if ToUpdate = false then begin
    inc(mik);
    if Qt.RecordCount=1 then AddPointSeries(Chart1, sName);
    if Qt.RecordCount>1 then AddLineSeries(Chart1, sName);
   end;

   Qt.First;
    while not Qt.Eof do begin
     lev := Qt.FieldByName('LEVEL_').AsVariant;
     val1:= Qt.FieldByName('VALUE_').AsFloat;

     if val1<>-9999 then begin
      TLineSeries(Chart1.Series[mik]).AddXY(val1, lev);
     end;
      Qt.Next;
    end;
    Qt.Close;
   end;

finally
 Qt.Close;

 Trt.Commit;
 Trt.Free;
end;
end;



procedure Tfrmprofile_plot_all.SelectProfile(sName:string);
var
k, cs, i, c:integer;
ChartName, ss_name, src_name: string;
clr:TColor;
begin

//showmessage(sname);
  cs:=-1;
  for k:=0 to Chart1.SeriesCount-1 do begin
   ChartName:=TLineSeries(Chart1.Series[k]).Name;
 //  showmessage('chatrname: '+ChartName);

   with TLineSeries(Chart1.Series[k]) do begin
    SeriesColor:=clGray;
    Pointer.Brush.Color:=clGray;
    LinePen.Width:=1;
    Pointer.HorizSize:=2;
    Pointer.VertSize:=2;
    ZPosition:=0;
   end;

   if sName=ChartName then begin
    cs:=k; //current series
    break;
   end;
  end;

//  showmessage(inttostr(cs));

  if cs>0 then begin
   with TLineSeries(Chart1.Series[cs]) do begin
    SeriesColor:=clRed;
    Pointer.Brush.Color:=clRed;
    LinePen.Width:=2;
    Pointer.HorizSize:=3;
    Pointer.VertSize:=3;
    ZPosition:=mik;
   end;
  end;
end;


procedure Tfrmprofile_plot_all.DPCPointClick(
  ATool: TChartTool; APoint: TPoint);
Var
 ID, CrID:integer;
 tool: TDataPointClicktool;
 series: TLineSeries;
 k, ss:integer;
 clr:TColor;
 sName, ss_name, src_name:string;
begin
  tool := ATool as TDataPointClickTool;
  if tool.Series is TLineSeries then begin
    series := TLineSeries(tool.Series);
   if series.Active=true then begin
    for ss:=0 to Chart1.Series.Count-1 do begin
       sName:=Chart1.Series[ss].Name;

      if Chart1.Series[ss].Name=series.name then begin
        TLineSeries(Chart1.Series[ss]).SeriesColor:=clRed;
        TLineSeries(Chart1.Series[ss]).Pointer.Brush.Color:=clRed;
        TLineSeries(Chart1.Series[ss]).LinePen.Width:=2;
        TLineSeries(Chart1.Series[ss]).Pointer.HorizSize:=3;
        TLineSeries(Chart1.Series[ss]).Pointer.VertSize:=3;
        TLineSeries(Chart1.Series[ss]).ZPosition:=mik;
      end else begin
        TLineSeries(Chart1.Series[ss]).SeriesColor:=clGray;
        TLineSeries(Chart1.Series[ss]).Pointer.Brush.Color:=clGray;
        TLineSeries(Chart1.Series[ss]).LinePen.Width:=1;
        TLineSeries(Chart1.Series[ss]).Pointer.HorizSize:=2;
        TLineSeries(Chart1.Series[ss]).Pointer.VertSize:=2;
        TLineSeries(Chart1.Series[ss]).ZPosition:=0;
      end;
    end;

      ID:=strtoint(copy(series.Name,2,length(series.Name)));
      frmmain.CDS.Locate('ABSNUM', ID, []);
    end;
  end;
end;

procedure Tfrmprofile_plot_all.btnPriorClick(Sender: TObject);
begin
 btnNext.Enabled:=true;
 frmmain.CDS.Prior;
 if frmmain.CDS.RecNo=1 then btnPrior.Enabled:=false;
 frmmain.CDSNavigation;
end;


procedure Tfrmprofile_plot_all.btnNextClick(Sender: TObject);
begin
 btnPrior.Enabled:=true;
 frmmain.CDS.Next;
 if frmmain.CDS.Eof then btnNext.Enabled:=false;
 frmmain.CDSNavigation;
end;

procedure Tfrmprofile_plot_all.HighlightSeries(ASeries: TBasicChartSeries);
var
  series: TCustomChartSeries;
begin
  for series in CustomSeries(Chart1) do
    if (series is TLineSeries) and (series.Active=true) then begin
      if (series = ASeries) and (TLineSeries(series).SeriesColor<>clRed) then begin
        TLineSeries(series).LinePen.Width:=2;
      end;
      if (series <> ASeries) and (TLineSeries(series).SeriesColor<>clRed) then begin
        TLineSeries(series).LinePen.Width:=1;
      end;
    end;
end;

procedure Tfrmprofile_plot_all.DPHAfterMouseMove(ATool: TChartTool;
  APoint: TPoint);
begin
  HighlightSeries(TDatapointHintTool(ATool).Series);
end;


procedure Tfrmprofile_plot_all.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
Var
  Ini:TIniFile;
begin
 Ini := TIniFile.Create(IniFileName);
   try
     Ini.WriteInteger( 'osprofile_plot_all', 'Top',    Top);
     Ini.WriteInteger( 'osprofile_plot_all', 'Left',   Left);
     Ini.WriteInteger( 'osprofile_plot_all', 'Width',  Width);
     Ini.WriteInteger( 'osprofile_plot_all', 'Height', Height);
   finally
    Ini.Free;
   end;

  frmprofile_plot_all_open:=false;
end;


procedure Tfrmprofile_plot_all.FormDestroy(Sender: TObject);
begin
 Chart1.Series.Clear;
end;

end.

