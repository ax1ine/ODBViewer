unit profile_station_single;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, DBGrids, IniFiles, SQLDB, DB, Grids, Menus, Types,
  TAGraph, TATools, TASeries, TATypes, TAChartAxisUtils,
  TACustomSeries,  // for TChartSeries
  TAChartUtils,
  TAEnumerators, TAChartListbox;

type

  { Tfrmprofile_station_single }

  Tfrmprofile_station_single = class(TForm)
    btnAdd: TToolButton;
    btnCommit: TToolButton;
    btnDelete: TToolButton;
    Chart1: TChart;
    cbParameters: TComboBox;
    ChartToolset1: TChartToolset;
    DPCT: TDataPointClickTool;
    MenuItem1: TMenuItem;
    btnBestProfile: TMenuItem;
    Splitter2: TSplitter;
    StatusBar1: TStatusBar;
    StatusBar2: TStatusBar;
    btnDeleteProf: TToolButton;
    ToolButton2: TToolButton;
    ZDT: TZoomDragTool;
    ZMWT: TZoomMouseWheelTool;
    DS: TDataSource;
    PM: TPopupMenu;
    DBGridSingleProfile: TDBGrid;
    Panel1: TPanel;
    Panel2: TPanel;
    SetFlagAbove: TMenuItem;
    SetFlagBelow: TMenuItem;
    Splitter1: TSplitter;
    Qt: TSQLQuery;
    ToolBar1: TToolBar;
    ToolButton4: TToolButton;

    procedure btnCommitClick(Sender: TObject);
    procedure btnDeleteProfClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure cbParametersChange(Sender: TObject);
    procedure DPCTPointClick(ATool: TChartTool;
      APoint: TPoint);
    procedure DBGridSingleProfilePrepareCanvas(sender: TObject; DataCol: Integer;
      Column: TColumn; AState: TGridDrawState);
    procedure DBGridSingleProfileSelectEditor(Sender: TObject; Column: TColumn;
      var Editor: TWinControl);
    procedure SetFlagAboveClick(Sender: TObject);
    procedure SetFlagBelowClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);

  private
    function AddLineSeries (AChart: TChart; ATitle: String; sName:string):TLineSeries;
  //  procedure HighlightSeries(ASeries: TBasicChartSeries);
  public
    procedure ChangeID(ID:integer);
  end;

var
  frmprofile_station_single: Tfrmprofile_station_single;
  current_index, mik: integer;
  sName:string;

implementation

{$R *.lfm}

{ Tfrmprofile_station_single }

uses main;


function Tfrmprofile_station_single.AddLineSeries(AChart: TChart;
  ATitle: String; sName:string): TLineSeries;
begin
 Result := TLineSeries.Create(AChart.Owner);
  with TLineSeries(Result) do begin
    Title := ATitle;
    ShowPoints := false;
    ShowLines := true;
    LinePen.Style := psSolid;
    LinePen.Width:=2;
    SeriesColor := clRed;
    Pointer.Style:=psCircle;
    Pointer.Brush.Color := clRed;
    Pointer.Pen.Color := clRed;
    Pointer.HorizSize:=3;
    Pointer.VertSize:=3;
    Pointer.Visible:=true;
    Name := sName;
    ToolTargets := [nptPoint, nptYList, nptCustom];
  end;
 AChart.AddSeries(Result);
end;


procedure Tfrmprofile_station_single.FormShow(Sender: TObject);
Var
Ini:TIniFile;
begin
  Ini := TIniFile.Create(IniFileName);
  //IniSection:=name;
  try
    Width :=Ini.ReadInteger('main', 'Width',  600);
    Height:=Ini.ReadInteger('main', 'Height', 600);
  finally
     Ini.Free;
  end;
cbParameters.Items:=frmmain.ListBox2.Items;
current_index:=-1;

if CurrentParTable<>'' then
  cbParameters.ItemIndex:=cbParameters.Items.IndexOf(CurrentParTable) else
  cbParameters.ItemIndex:=0;

cbParameters.OnChange(self);
end;


procedure Tfrmprofile_station_single.cbParametersChange(Sender: TObject);
Var
  ID:integer;
begin
 ID:=frmmain.CDS.FieldByName('absnum').AsInteger;
  CurrentParTable:=cbParameters.Text;
 ChangeID(ID);
end;

procedure Tfrmprofile_station_single.btnAddClick(Sender: TObject);
begin
  Qt.Append;
end;

procedure Tfrmprofile_station_single.btnDeleteClick(Sender: TObject);
begin
  Qt.Delete;
end;


procedure Tfrmprofile_station_single.ChangeID(ID:integer);
var
count, items_id, k, LNum:integer;
Avg, Sum, Dif2, ValX, SD, ValX_Sum:real;
lev, val, flag_, avg_lev, avg_val:real;
val_sum, lev_sum, lev_min, lev_max, val_min, val_max:real;
units:string;
begin

 Chart1.ClearSeries;;

   with Qt do begin
    Close;
    Sql.Clear;
    SQL.Add(' select * from ');
    SQL.Add(CurrentParTable);
    SQL.Add(' where absnum=:absnum ');
    SQL.Add(' order by level_ ');
    ParamByName('absnum').AsInteger:=ID;
    Open;
    Last;
    First;
   end;

 //  sName:='s'+inttostr(id);
   AddLineSeries (Chart1, sName, sName);
 //  showmessage('add series');


  try
   Qt.DisableControls;
    Val_Sum:=0; Lev_sum:=0;
    Val_min:=10000; Val_max:=-9999;
    Lev_min:=10000; Lev_max:=-9999;
    while not Qt.eof do begin
      Lev:=Qt.FieldByName('level_').AsFloat;
      Val:=Qt.FieldByName('Value_').AsFloat;
      Flag_:=Qt.FieldByName('Flag_').AsFloat;

       TLineSeries(Chart1.Series[0]).AddXY(val,lev);



      Val_sum:=Val_sum+Val;
      Lev_sum:=Lev_sum+Lev;

      if lev>lev_max then lev_max:=lev;
      if lev<lev_min then lev_min:=lev;
      if val>val_max then val_max:=val;
      if val<val_min then val_min:=val;

      Qt.Next;
    end;
    Count:=Qt.RecordCount;
    Avg_Val:=Val_sum/Qt.RecordCount;
    Avg_Lev:=Lev_sum/Qt.RecordCount;

   Qt.First; sum:=0;
    while not Qt.Eof do begin
     Val:=Qt.FieldValues['Value_'];
     Dif2:=sqr(Val-Avg_Val);
    sum:=sum+Dif2;
   Qt.Next;
   end;
   Qt.First;

   SD:=sqrt(sum/count);

   StatusBar1.Panels[1].Text:='Count= '+Inttostr(Count);
   StatusBar1.Panels[2].Text:='Min= '  +floattostr(Lev_Min);
   StatusBar1.Panels[3].Text:='Max= '  +floattostr(Lev_Max);
   StatusBar1.Panels[4].Text:='Avg= '  +floattostrF(Avg_Lev, fffixed,8,3);

   StatusBar2.Panels[1].Text:='SD= '   +floattostrF(SD, fffixed,8,4);
   StatusBar2.Panels[2].Text:='Min= '  +floattostr(Val_Min);
   StatusBar2.Panels[3].Text:='Max= '  +floattostr(Val_Max);
   StatusBar2.Panels[4].Text:='Avg= '  +floattostrF(Avg_Val, fffixed,8,4);
  finally
    Qt.EnableControls;
  end;


Application.ProcessMessages;
end;



procedure Tfrmprofile_station_single.DBGridSingleProfilePrepareCanvas(sender: TObject;
  DataCol: Integer; Column: TColumn; AState: TGridDrawState);
begin
  if gdRowHighlight in AState then begin
    TDBGrid(sender).Canvas.Brush.Color := clNavy;
    TDBGrid(sender).Canvas.Font.Color:= clYellow;
    TDBGrid(sender).Canvas.Font.Style:=[fsBold];
  end;
end;

procedure Tfrmprofile_station_single.DBGridSingleProfileSelectEditor(
  Sender: TObject; Column: TColumn; var Editor: TWinControl);
begin
  if (Column.Index = 3) or
     (Column.Index = 4) or
     (Column.Index = 5) or
     (Column.Index = 7) or
     (Column.Index = 8) then begin
       if (Editor is TCustomComboBox) then
        with Editor as TCustomComboBox do
          Style := csDropDownList;
  end;
end;


procedure Tfrmprofile_station_single.DPCTPointClick(
  ATool: TChartTool; APoint: TPoint);
Var
 k,pp, ID: integer;
 tool: TDataPointClicktool;
 series: TLineSeries;
 pointer: TSeriesPointer;
 instr_name, prof_num: string;
 instr_id: integer;
begin
  tool := ATool as TDataPointClickTool;
  if tool.Series is TLineSeries then begin
    series := TLineSeries(tool.Series);

    if (tool.PointIndex<>-1) then begin
        Qt.Locate('LEVEL_', series.YValue[tool.PointIndex], []);
     current_index:=tool.PointIndex;
    end;
  end;
end;


procedure Tfrmprofile_station_single.SetFlagBelowClick(Sender: TObject);
Var
  par:string;
  fl, cur_pos: integer;
begin
 Qt.DisableControls;
 cur_pos:=Qt.RecNo;
 try
  fl:=Qt.FieldByName('PQF2').AsInteger;
   while not Qt.Eof do begin
    Qt.Edit;
     Qt.FieldByName('PQF2').AsInteger:=fl;
     Qt.Post;
    Qt.Next;
   end;
 finally
   Qt.RecNo:=Cur_pos;
   Qt.EnableControls;
 end;
end;


procedure Tfrmprofile_station_single.SetFlagAboveClick(Sender: TObject);
Var
  par:string;
  fl, cur_pos: integer;
begin

 Qt.DisableControls;
 cur_pos:=Qt.RecNo;
 try
  fl:=Qt.FieldByName('PQF2').AsInteger;
    repeat
     Qt.Edit;
      Qt.FieldByName('PQF2').AsInteger:=fl;
      Qt.Post;
     Qt.Prior;
    until Qt.RecNo=1;
    Qt.First;
    Qt.Edit;
    Qt.FieldByName('PQF2').AsFloat:=fl;
    Qt.Post;
 finally
   Qt.RecNo:=Cur_pos;
   Qt.EnableControls;
 end;
end;


procedure Tfrmprofile_station_single.btnCommitClick(Sender: TObject);
Var
levnum, ID:integer;
begin
  ID:=frmmain.CDS.FieldByName('absnum').AsInteger;
  Qt.DisableControls;

  with frmmain.q1 do begin
   Close;
    SQL.Text:='Delete from '+CurrentParTable+' where absnum=:absnum';
    ParamByName('absnum').AsInteger:=ID;
   ExecSQL;
  end;

    try
     Qt.First;
     while not Qt.Eof do begin
         with frmmain.Q1 do begin
             Close;
              Sql.Clear;
              SQL.Add('insert into');
              SQL.Add(CurrentParTable);
              SQL.Add(' (absnum, level_, value_, flag_) ');
              SQL.Add(' VALUES ' );
              SQL.Add(' (:absnum, :level_, :value_, :flag_) ');
              ParamByName('absnum').AsInteger:=ID;
              ParamByName('Level_').AsFloat:=Qt.FieldByName('level_').AsFloat;
              ParamByName('Value_').AsFloat:=Qt.FieldByName('Value_').AsFloat;
              ParamByName('flag_').AsFloat:=Qt.FieldByName('Flag_').AsFloat;
           ExecSQL;
        end;
      Qt.Next;
    end;
 frmmain.TR.CommitRetaining;
 except
 frmmain.TR.RollbackRetaining;
 end;
 ChangeID(ID);

 Qt.EnableControls;
end;

procedure Tfrmprofile_station_single.btnDeleteProfClick(Sender: TObject);
Var
  ID:integer;
begin
 ID:=frmmain.CDS.FieldByName('absnum').AsInteger;
 Qt.DisableControls;

 with frmmain.q1 do begin
  Close;
   SQL.Text:='Delete from '+CurrentParTable+' where absnum=:absnum';
   ParamByName('absnum').AsInteger:=ID;
  ExecSQL;
 end;
 frmmain.TR.CommitRetaining;
 changeid(ID);
end;


procedure Tfrmprofile_station_single.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
Var
  Ini: TIniFile;
  IniSection:string;
begin
 Ini := TIniFile.Create(IniFileName);
 IniSection:=name;
  try
    Ini.WriteInteger ('main', 'Width',  Width);
    Ini.WriteInteger ('main', 'Height', Height);
  finally
   Ini.Free;
  end;

  frmprofile_station_single_open:=false;
end;



end.

