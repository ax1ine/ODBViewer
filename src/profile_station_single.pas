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
    clbSeries: TChartListbox;
    ChartToolset1: TChartToolset;
    DPCT: TDataPointClickTool;
    DPHT: TDataPointHintTool;
    MenuItem1: TMenuItem;
    btnBestProfile: TMenuItem;
    Splitter2: TSplitter;
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
    StatusBar1: TStatusBar;
    StatusBar2: TStatusBar;
    ToolBar1: TToolBar;
    ToolButton4: TToolButton;

    procedure FormShow(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnBestProfileClick(Sender: TObject);
    procedure btnCommitClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure cbParametersChange(Sender: TObject);
    procedure DPCTPointClick(ATool: TChartTool;
      APoint: TPoint);
    procedure DBGridSingleProfilePrepareCanvas(sender: TObject; DataCol: Integer;
      Column: TColumn; AState: TGridDrawState);
    procedure DBGridSingleProfileSelectEditor(Sender: TObject; Column: TColumn;
      var Editor: TWinControl);
    procedure DPHTAfterMouseMove(ATool: TChartTool; APoint: TPoint);
    procedure SetFlagAboveClick(Sender: TObject);
    procedure SetFlagBelowClick(Sender: TObject);
    procedure TabControl1Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);

  private
    function AddLineSeries (AChart: TChart; ATitle: String; AColor:TColor; sName:string):TLineSeries;
    procedure HighlightSeries(ASeries: TBasicChartSeries);
    procedure GetProfile(ID, prof_num, instr_id: integer);
  public
    procedure ChangeID(ID:integer);
  end;

var
  frmprofile_station_single: Tfrmprofile_station_single;
  current_index, mik: integer;

implementation

{$R *.lfm}

{ Tfrmprofile_station_single }

uses osmain, dm;


function Tfrmprofile_station_single.AddLineSeries(AChart: TChart;
  ATitle: String; AColor:TColor; sName:string): TLineSeries;
begin
 Result := TLineSeries.Create(AChart.Owner);
  with TLineSeries(Result) do begin
    Title := ATitle;
    ShowPoints := false;
    ShowLines := true;
    LinePen.Style := psSolid;
    LinePen.Width:=2;
    SeriesColor := AColor;
    Pointer.Style:=psCircle;
    Pointer.Brush.Color := AColor;
    Pointer.Pen.Color := AColor;
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
  IniSection:=name;
  try
    Width :=Ini.ReadInteger(IniSection, 'Width',  600);
    Height:=Ini.ReadInteger(IniSection, 'Height', 600);
  finally
     Ini.Free;
  end;
cbParameters.Items:=frmosmain.ListBox1.Items;
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

  if ODBDM.ib1q1.IsEmpty=false then
   try
   Qt.DisableControls;
    Val_Sum:=0; Lev_sum:=0;
    Val_min:=10000; Val_max:=-9999;
    Lev_min:=10000; Lev_max:=-9999;
    while not Qt.eof do begin
      Lev:=Qt.FieldByName('level_').AsFloat;
      Val:=Qt.FieldByName('Value_').AsFloat;
      Flag_:=Qt.FieldByName('Flag_').AsFloat;

      Val_sum:=Val_sum+Val;
      Lev_sum:=Lev_sum+Lev;

      if lev>lev_max then lev_max:=lev;
      if lev<lev_min then lev_min:=lev;
      if val>val_max then val_max:=val;
      if val<val_min then val_min:=val;

      Qt.Next;
    end;
    Count:=cds.RecordCount;
    Avg_Val:=Val_sum/Qt.RecordCount;
    Avg_Lev:=Lev_sum/Qt.RecordCount;

   cds.First; sum:=0;
    while not cds.Eof do begin
     Val:=cds.FieldValues['Value_'];
     Dif2:=sqr(Val-Avg_Val);
    sum:=sum+Dif2;
   cds.Next;
   end;
   cds.First;

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

   with Series1 do begin
     XValues.Order:=loNone;
     YValues.Order:=loDescending;
     DataSource:=cds;
     XValues.ValueSource:='Value_';
     YValues.ValueSource:='Level_';
     CheckDataSource;
   end;

DBGridEh1.DataSource:=DS;

btnDeleteProfile.Enabled:=true;
btnCommit.Enabled:=true;
cds.EnableControls;
series2.Clear;

ComboBoxEx1.Text:=copy(CurrentParTable,3,length(CurrentParTable));

DBChart1.RefreshData;
Application.ProcessMessages;

end;



procedure Tfrmprofile_station_single.GetProfile(ID, PROF_NUM, instr_id: integer);
Var
  Ini: TIniFile;
  count, items_id, k, LNum:integer;
  Avg, Sum, Dif2, ValX, SD, ValX_Sum:real;
  lev, val, avg_lev, avg_val:real;
  val_sum, lev_sum, lev_min, lev_max, val_min, val_max:real;
  units, tbl, depth_units_str:string;
  Depth_units: integer;

  TRt:TSQLTransaction;
  Qtt:TSQLQuery;
begin
  Ini := TIniFile.Create(IniFileName);
  try
    Depth_units:=Ini.ReadInteger ( 'main', 'Depth_units', 0);
  finally
    ini.Free;
  end;

  Items_id:=cbParameters.ItemIndex;

  try
  Qt.DisableControls;

        with Qt do begin
         Close;
           Sql.Clear;
           SQL.Add(' SELECT * FROM ');
           SQL.Add( CurrentParTable);
           SQL.Add(' WHERE ');
           SQL.Add( CurrentParTable+'.ID=:ID AND ');
           SQL.Add( CurrentParTable+'.INSTRUMENT_ID=:INSTR_ID AND ');
           SQL.Add( CurrentParTable+'.PROFILE_NUMBER=:PROF_NUM');
           SQL.Add(' ORDER BY LEV_DBAR, LEV_M');
           ParamByName('ID').AsInteger:=ID;
           ParamByName('INSTR_ID').AsInteger:=INSTR_ID;
           ParamByName('PROF_NUM').AsInteger:=PROF_NUM;
          // showmessage(qt.SQL.Text);
         Open;
        end;

  if Qt.IsEmpty=false then begin
    Val_Sum:=0; Lev_sum:=0;
    Val_min:=10000; Val_max:=-9999;
    Lev_min:=10000; Lev_max:=-9999;

    Qt.First;
    while not Qt.eof do begin

      if Depth_units=0 then begin
       Lev:=Qt.FieldByName('LEV_M').AsFloat;
       depth_units_str:='Meter';
      end;
      if Depth_units=1 then begin
       Lev:=Qt.FieldByName('LEV_DBAR').AsFloat;
       depth_units_str:='dBar';
      end;

      Val:=Qt.FieldByName('VAL').AsFloat;
      //Flag_:=Qt.FieldByName('PQF2').AsFloat;

      Val_sum:=Val_sum+Val;
      Lev_sum:=Lev_sum+Lev;

      if lev>lev_max then lev_max:=lev;
      if lev<lev_min then lev_min:=lev;
      if val>val_max then val_max:=val;
      if val<val_min then val_min:=val;

     // Series1.AddXY(val,lev);

      Qt.Next;
    end;
    Count:=Qt.RecordCount;
    Avg_Val:=Val_sum/Qt.RecordCount;
    Avg_Lev:=Lev_sum/Qt.RecordCount;

   Qt.First; sum:=0;
    while not Qt.Eof do begin
     Val:=Qt.FieldByName('VAL').AsFloat;
     Dif2:=sqr(Val-Avg_Val);
    sum:=sum+Dif2;
    Qt.Next;
   end;
   Qt.First;

   //  showmessage('here3');

   try
     TRt:=TSQLTransaction.Create(self);
     TRt.DataBase:=frmdm.IBDB;

     Qtt:=TSQLQuery.Create(self);
     Qtt.Database:=frmdm.IBDB;
     Qtt.Transaction:=TRt;

       with Qtt do begin
         Close;
           Sql.Clear;
           SQL.Add(' SELECT UNITS.NAME_SHORT FROM ');
           SQL.Add(CurrentParTable+ ', UNITS ');
           SQL.Add(' WHERE ');
           SQL.Add( CurrentParTable+'.UNITS_ID=UNITS.ID AND ');
           SQL.Add( CurrentParTable+'.INSTRUMENT_ID=:INSTR_ID AND ');
           SQL.Add( CurrentParTable+'.PROFILE_NUMBER=:PROF_NUM AND ');
           SQL.Add( CurrentParTable+'.ID=:ID ');
           ParamByName('ID').AsInteger:=ID;
           ParamByName('INSTR_ID').AsInteger:=INSTR_ID;
           ParamByName('PROF_NUM').AsInteger:=PROF_NUM;
         Open;
           Units:=Qtt.Fields[0].AsString;
         Close;
        end;
   finally
     Trt.Commit;
     Qtt.Free;
     Trt.Free;
   end;
    // showmessage('here4');

   SD:=sqrt(sum/count);

   StatusBar1.Panels[1].Text:='Count= '+Inttostr(Count);
   StatusBar1.Panels[2].Text:='Min= '  +floattostr(Lev_Min);
   StatusBar1.Panels[3].Text:='Max= '  +floattostr(Lev_Max);
   StatusBar1.Panels[4].Text:='Avg= '  +floattostrF(Avg_Lev, fffixed,8,3);
   StatusBar1.Panels[5].Text:='Units= '+depth_units_str;

   StatusBar2.Panels[1].Text:='SD= '   +floattostrF(SD, fffixed,8,4);
   StatusBar2.Panels[2].Text:='Min= '  +floattostr(Val_Min);
   StatusBar2.Panels[3].Text:='Max= '  +floattostr(Val_Max);
   StatusBar2.Panels[4].Text:='Avg= '  +floattostrF(Avg_Val, fffixed,8,4);
   StatusBar2.Panels[5].Text:='Units= '+Units;

  end;
  finally
    Qt.EnableControls;
  end;


//  showmessage('here6');

btnCommit.Enabled:=true;
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

procedure Tfrmprofile_station_single.DPHTAfterMouseMove(ATool: TChartTool;
  APoint: TPoint);
begin
    HighlightSeries(TDatapointHintTool(ATool).Series);
end;

procedure Tfrmprofile_station_single.DPCTPointClick(
  ATool: TChartTool; APoint: TPoint);
Var
 k,pp: integer;
 tool: TDataPointClicktool;
 series: TLineSeries;
 pointer: TSeriesPointer;
 instr_name, id, prof_num: string;
 instr_id: integer;

 TRt:TSQLTransaction;
 Qt1:TSQLQuery;
begin
  tool := ATool as TDataPointClickTool;
  if tool.Series is TLineSeries then begin
    series := TLineSeries(tool.Series);

    INSTR_ID:=StrToInt(Copy(series.Name, 2, Pos('_', Series.Name)-2));

  //  showmessage(inttostr(instr_ID));

    try
     TRt:=TSQLTransaction.Create(self);
     TRt.DataBase:=frmdm.IBDB;

     Qt1:=TSQLQuery.Create(self);
     Qt1.Database:=frmdm.IBDB;
     Qt1.Transaction:=TRt;

      with Qt1 do begin
       Close;
        SQL.Clear;
        SQL.Add(' SELECT NAME FROM INSTRUMENT ');
        SQL.Add(' WHERE ID=:ID ');
        ParamByName('ID').AsInteger:=INSTR_ID;
       Open;
         instr_name:=Qt1.Fields[0].AsString;
       Close;
      end;
    finally
      Trt.Commit;
      Qt1.Free;
      TrT.Free;
    end;


    Prof_num:=Copy(series.name, Pos('_', Series.Name)+1, length(series.name));

    if Pos('__B', series.name)<>0 then
      Prof_num:=StringReplace(Prof_num, '__B', ' [BEST]', []);

  //  showmessage(prof_num);

    TabControl1.TabIndex:=TabControl1.IndexOfTabWithCaption(INSTR_NAME+', Profile '+Prof_num);
    TabControl1.OnChange(self);

    if (tool.PointIndex<>-1) then begin
      if depth_units=0 then
        Qt.Locate('LEV_M', series.YValue[tool.PointIndex], []) else
        Qt.Locate('LEV_DBAR', series.YValue[tool.PointIndex], []);

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
  ID, Instr_id, Prof_num:integer;
  TabName, Instr_name:string;
begin
  ID:=frmdm.Q.FieldByName('ID').AsInteger;

  TabName:=TabControl1.Tabs[TabControl1.TabIndex];
  if Pos('[', TabName) <> 0 then TabName:=copy(TabName, 1, Pos('[', TabName)-2);

  Instr_name:=Copy(tabName, 1, Pos(',', TabName)-1);
  Prof_num :=StrToInt(trim(Copy(TabName, Pos('Profile', TabName)+7, length(TabName))));

  try
   Qt.DisableControls;

     try
      with frmdm.q1 do begin
        Close;
          Sql.Clear;
          SQL.Add(' SELECT ID FROM INSTRUMENT WHERE NAME=:INSTR ');
          ParamByName('INSTR').Value:=INSTR_NAME;
        Open;
         Instr_id:=frmdm.q1.Fields[0].AsInteger;
        Close;
      end;

       with frmdm.q1 do begin
         Close;
           Sql.Clear;
           SQL.Add(' DELETE FROM ');
           SQL.Add(CurrentParTable);
           SQL.Add(' WHERE ');
           SQL.Add(' ID=:ID AND PROFILE_NUMBER=:P_NUM AND ');
           SQL.Add(' INSTRUMENT_ID=:ID_I ');
           ParamByName('ID').AsInteger:=ID;
           ParamByName('ID_I').AsInteger:=Instr_ID;
           ParamByName('P_NUM').AsInteger:=Prof_num;
         ExecSQL;
         Close;
        end;
     frmdm.TR.CommitRetaining;

     Qt.First;
     while not Qt.Eof do begin
      with frmdm.q1 do begin
       Close;
        Sql.Clear;
        SQL.Add('insert into');
        SQL.Add(CurrentParTable);
        SQL.Add(' (ID, lev_m, lev_dbar, val, pqf1, pqf2, sqf, ');
        SQL.Add(' bottle_number, units_id, instrument_id, PROFILE_NUMBER) ');
        SQL.Add(' VALUES ' );
        SQL.Add(' (:ID, :lev_m, :lev_dbar, :val, :pqf1, :pqf2, :sqf, ');
        SQL.Add(' :bottle_number, :units_id, :instrument_id, :PROFILE_NUMBER) ');
        ParamByName('ID').Value:=Qt.FieldByName('ID').Value;
        ParamByName('LEV_M').Value:=Qt.FieldByName('LEV_M').Value;
        ParamByName('LEV_DBAR').Value:=Qt.FieldByName('LEV_DBAR').Value;
        ParamByName('VAL').Value:=Qt.FieldByName('VAL').Value;
        ParamByName('PQF1').Value:=Qt.FieldByName('PQF1').Value;
        ParamByName('PQF2').Value:=Qt.FieldByName('PQF2').Value;
        ParamByName('SQF').Value:=Qt.FieldByName('SQF').Value;
        ParamByName('BOTTLE_NUMBER').Value:=Qt.FieldByName('BOTTLE_NUMBER').Value;
        ParamByName('UNITS_ID').Value:=Qt.FieldByName('UNITS_ID').Value;
        ParamByName('INSTRUMENT_ID').Value:=Instr_id;
        ParamByName('PROFILE_NUMBER').Value:=Prof_num;
       ExecSQL;
      end;
     Qt.Next;
   end;

   frmdm.TR.CommitRetaining;
   except
    On E :Exception do begin
     ShowMessage(E.Message);
     frmdm.TR.RollbackRetaining;
    end;
   end;

   finally
     Qt.EnableControls;
   end;
 ChangeID(ID);

// if frmprofile_plot_all_open=true then frmprofile_plot_all.AddToPlot(ID, true);
end;


procedure Tfrmprofile_station_single.btnBestProfileClick(Sender: TObject);
Var
  TabName, Instr_name:string;
  ID, Prof_num, prof_cur, instr_id: integer;
  TRt:TSQLTransaction;
  Qt1:TSQLQuery;
begin
  TabName:=TabControl1.Tabs.Strings[TabControl1.TabIndex];
  if Pos('[', TabName) <> 0 then
   if MessageDlg('This profile is already the BEST!', mtWarning, [mbOk], 0)=mrOk then exit;

  Instr_name:=trim(Copy(TabName, 1, Pos(',', TabName)-1));
  Prof_num :=StrToInt(trim(Copy(TabName, Pos('Profile', TabName)+7, length(TabName))));
  ID:=frmdm.Q.FieldByName('ID').AsInteger;

      with frmdm.q1 do begin
        Close;
          Sql.Clear;
          SQL.Add(' SELECT ID FROM INSTRUMENT WHERE NAME=:INSTR ');
          ParamByName('INSTR').Value:=INSTR_NAME;
        Open;
         Instr_id := frmdm.q1.Fields[0].AsInteger;
        Close;
      end;

      with frmdm.q1 do begin
        Close;
          SQL.Clear;
          SQL.Add(' UPDATE '+CurrentParTable);
          SQL.Add(' SET PROFILE_BEST=FALSE ');
          SQL.Add(' WHERE '+CurrentParTable+'.ID=:ID ');
          ParambyName('ID').AsInteger:=ID;
        ExecSQL;
      end;
      frmdm.TR.CommitRetaining;

      with frmdm.q1 do begin
        Close;
          SQL.Clear;
          SQL.Add(' UPDATE '+CurrentParTable);
          SQL.Add(' SET PROFILE_BEST=TRUE WHERE ');
          SQL.Add( CurrentParTable+'.ID=:ID AND ');
          SQL.Add( CurrentParTable+'.INSTRUMENT_ID=:I_ID AND ');
          SQL.Add( CurrentParTable+'.PROFILE_NUMBER=:PROF_NUM ');
          ParamByName('ID').AsInteger:=ID;
          ParamByName('I_ID').Value:=INSTR_ID;
          ParamByName('PROF_NUM').Value:=PROF_NUM;
        ExecSQL;
      end;
      frmdm.TR.CommitRetaining;

  ChangeID(ID);
end;



procedure Tfrmprofile_station_single.HighlightSeries(ASeries: TBasicChartSeries);
var
  series: TCustomChartSeries;
begin
  for series in CustomSeries(Chart1) do
    if series is TLineSeries then
    begin
      if (series = ASeries) then begin
        TLineSeries(series).LinePen.Width:=3;
        TLineSeries(series).Pointer.HorizSize:=4;
        TLineSeries(series).Pointer.VertSize:=4;
        TLineSeries(series).ZPosition:=mik;
      end;
      if (series <> ASeries) then begin
        TLineSeries(series).LinePen.Width:=2;
        TLineSeries(series).Pointer.HorizSize:=3;
        TLineSeries(series).Pointer.VertSize:=3;
        TLineSeries(series).ZPosition:=0;
      end;
    end;
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
    Ini.WriteInteger (IniSection, 'Width',  Width);
    Ini.WriteInteger (IniSection, 'Height', Height);

    With DBGridSingleProfile do begin
     Ini.WriteInteger( IniSection, 'DBGridCol00',  Columns[0].Width);
     Ini.WriteInteger( IniSection, 'DBGridCol01',  Columns[1].Width);
     Ini.WriteInteger( IniSection, 'DBGridCol02',  Columns[2].Width);
     Ini.WriteInteger( IniSection, 'DBGridCol03',  Columns[3].Width);
     Ini.WriteInteger( IniSection, 'DBGridCol04',  Columns[4].Width);
     Ini.WriteInteger( IniSection, 'DBGridCol05',  Columns[5].Width);
     Ini.WriteInteger( IniSection, 'DBGridCol06',  Columns[6].Width);
     Ini.WriteInteger( IniSection, 'DBGridCol07',  Columns[7].Width);
    end;

  finally
   Ini.Free;
  end;

  frmprofile_station_single_open:=false;
end;



end.
