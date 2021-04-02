unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  Menus, ExtCtrls, Buttons, Spin, ComboEx, DBGrids, DateTimePicker, DateUtils,
  IBConnection, sqldb, DB, Grids, IniFiles, dynlibs, LCLIntf, math, LCLType;

type
   MapDS=record
     ID:int64;
     Latitude:real;
     Longitude:real;
     x:int64;
     y:int64;
end;

type

  { Tfrmmain }

  Tfrmmain = class(TForm)
    iOpenDB: TMenuItem;
    iExport: TMenuItem;
    iASCII: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    btnSelect: TButton;
    cbCountry: TCheckComboBox;
    cbSource: TCheckComboBox;
    cbVessel: TCheckComboBox;
    chkPeriod: TCheckBox;
    chkNOTCountry: TCheckBox;
    chkNOTSource: TCheckBox;
    chkNOTVessel: TCheckBox;
    DS: TDataSource;
    ib2q2: TSQLQuery;
    DB1: TIBConnection;
    DB2: TIBConnection;
    DBGridStation: TDBGrid;
    DBGridStationInfo: TDBGrid;
    dtpDateMax: TDateTimePicker;
    dtpDateMin: TDateTimePicker;
    gbAuxiliaryParameters: TGroupBox;
    gbDateandTime: TGroupBox;
    gbRegion: TGroupBox;
    iFile: TMenuItem;
    ListBox1: TListBox;
    ListBox2: TListBox;
    iImport: TMenuItem;
    iICES: TMenuItem;
    MenuItem1: TMenuItem;
    imap: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    iRemoveDuplicates: TMenuItem;
    iGEBCO: TMenuItem;
    iLastLevel: TMenuItem;
    ihelp: TMenuItem;
    itest: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    iIARC: TMenuItem;
    iLoad_IAOOC: TMenuItem;
    MenuItem8: TMenuItem;
    MM: TMainMenu;
    OD: TOpenDialog;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    pDataCruise: TPanel;
    q1: TSQLQuery;
    q2: TSQLQuery;
    q3: TSQLQuery;
    q4: TSQLQuery;
    ib2q1: TSQLQuery;
    CDS: TSQLQuery;
    SD: TSaveDialog;
    Splitter3: TSplitter;
    StatusBar1: TStatusBar;
    StatusBar2: TStatusBar;
    seLatMax: TFloatSpinEdit;
    seLatMin: TFloatSpinEdit;
    seLonMax: TFloatSpinEdit;
    seLonMin: TFloatSpinEdit;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TR: TSQLTransaction;
    TR2: TSQLTransaction;

    procedure btnSelectClick(Sender: TObject);
    procedure cbCountryDropDown(Sender: TObject);
    procedure cbSourceDropDown(Sender: TObject);
    procedure cbVesselDropDown(Sender: TObject);
    procedure DBGridStationCellClick(Column: TColumn);
    procedure DBGridStationKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure DBGridStationPrepareCanvas(sender: TObject; DataCol: Integer;
      Column: TColumn; AState: TGridDrawState);
    procedure DBGridStationTitleClick(Column: TColumn);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure iASCIIClick(Sender: TObject);
    procedure iGEBCOClick(Sender: TObject);
    procedure iIARCClick(Sender: TObject);
    procedure iICESClick(Sender: TObject);
    procedure iLastLevelClick(Sender: TObject);
    procedure iLoad_IAOOCClick(Sender: TObject);
    procedure imapClick(Sender: TObject);
    procedure iOpenDBClick(Sender: TObject);
    procedure iRemoveDuplicatesClick(Sender: TObject);
    procedure itestClick(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItem8Click(Sender: TObject);

  private
    procedure DatabaseInfo;
    procedure SelectionInfo;
    procedure SaveSettings;
  public
    procedure CDSNavigation;
  end;

var
  frmmain: Tfrmmain;

  GlobalPath, IniFileName, IBName, CurrentParTable:string;
  NavigationOrder:boolean;

  IBLatMin,IBLatMax,IBLonMin,IBLonMax :Real;
  IBCount:Integer;
  IBDateMin, IBDateMax :TDateTime;

  SLatMin,SLatMax,SLonMin,SLonMax:Real;
  SCount: Integer;
  SDateMin, SDateMax :TDateTime;

  libgswteos, netcdf:TLibHandle;
  libgswteos_exists, netcdf_exists:boolean;

  MapDataset: array of MapDS;
  frmmap_open, frmprofile_station_all_open, frmprofile_plot_all_open,
  frmparameters_list_open:boolean;


const
   NC_NOWRITE   = 0;    // file for reading
   NC_WRITE     = 1;    // file for writing
   NC_GLOBAL    = -1;   // global attributes ID
   NC_MAX_NAME  = 1024; // value from netcdf.h
   NC_UNLIMITED = 0;
   WS_EX_STATICEDGE = $20000;
   buf_len      = 3000;

implementation

{$R *.lfm}

{ Tfrmmain }

uses settings, sortbufds, load_ices, export_ASCII, map, procedures,
     load_odb, load_kirillov, load_iaoos, test, bathymetry, load_iarc,
     profile_station_all, parameters_list, profile_plot_all;


procedure Tfrmmain.FormShow(Sender: TObject);
Var
  Ini:TIniFile;
begin
 (* Defining Global Path - application root lolder *)
  GlobalPath:=ExtractFilePath(Application.ExeName);

  (* Define settings file, unique for every user*)
  IniFileName:=GetUserDir+'.climateshell';
  if not FileExists(IniFileName) then begin
    Ini:=TIniFile.Create(IniFileName);
    Ini.WriteInteger('main', 'Language', 0);
    Ini.Free;
  end;

  (* Loading TEOS-2010 dynamic library *)
  {$IFDEF WINDOWS}
    libgswteos:=LoadLibrary(PChar(GlobalPath+'libgswteos-10.dll'));
    netcdf    :=LoadLibrary(PChar(GlobalPath+'netcdf.dll'));
  {$ENDIF}
  {$IFDEF LINUX}
    libgswteos:=LoadLibrary(PChar(GlobalPath+'libgswteos-10.so'));
    netcdf    :=LoadLibrary(PChar(GlobalPath+'libnetcdf.so'));
  {$ENDIF}
  {$IFDEF DARWIN}
    libgswteos:=LoadLibrary(PChar(GlobalPath+'libgswteos-10.dylib'));
    netcdf    :=LoadLibrary(PChar(GlobalPath+'libnetcdf.dylib'));
  {$ENDIF}


  //GibbsSeaWater loaded?
  if libgswteos=0 then libgswteos_exists:=false else libgswteos_exists:=true;
    if not libgswteos_exists then showmessage('TEOS-10 is not installed');

  //netCDF loaded?
  if netcdf=0 then netcdf_exists:=false else netcdf_exists:=true;
  if not netcdf_exists then showmessage('netCDF is not installed');


  (* Define global delimiter *)
  DefaultFormatSettings.DecimalSeparator := '.';

  (* Loading settings from INI file *)
  Ini := TIniFile.Create(IniFileName);
  try
    (* main form sizes *)
    Top   :=Ini.ReadInteger( 'ODBViewer', 'top',    50);
    Left  :=Ini.ReadInteger( 'ODBViewer', 'left',   50);
    Width :=Ini.ReadInteger( 'ODBViewer', 'width',  1300);
    Height:=Ini.ReadInteger( 'ODBViewer', 'weight', 700);

    seLatMin.Value   :=Ini.ReadFloat  ( 'ODBViewer', 'station_latmin',     0);
    seLatMax.Value   :=Ini.ReadFloat  ( 'ODBViewer', 'station_latmax',     0);
    seLonMin.Value   :=Ini.ReadFloat  ( 'ODBViewer', 'station_lonmin',     0);
    seLonMax.Value   :=Ini.ReadFloat  ( 'ODBViewer', 'station_lonmax',     0);

    chkPeriod.Checked:=Ini.ReadBool   ( 'ODBViewer', 'station_period', false);
    cbVessel.Text    :=Ini.ReadString ( 'ODBViewer', 'station_platform',  '');
    cbCountry.Text   :=Ini.ReadString ( 'ODBViewer', 'station_country',   '');
    cbSource.Text    :=Ini.ReadString ( 'ODBViewer', 'station_source',    '');
    dtpDateMin.DateTime:=Ini.ReadDateTime('ODBViewer', 'station_datemin', now);
    dtpDateMax.DateTime:=Ini.ReadDateTime('ODBViewer', 'station_datemax', now);

    DBGridStation.Height    := Ini.ReadInteger( 'ODBViewer', 'dbGridCruise_Height',   200);

    With DBGridStation do begin
     Columns[0].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridCruise_Col00',  70);
     Columns[1].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridCruise_Col01',  70);
     Columns[2].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridCruise_Col02',  70);
     Columns[3].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridCruise_Col03',  70);
     Columns[4].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridCruise_Col04',  70);
     Columns[5].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridCruise_Col05',  70);
     Columns[6].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridCruise_Col06',  70);
     Columns[7].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridCruise_Col07', 150);
     Columns[8].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridCruise_Col08', 150);
     Columns[9].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridCruise_Col09', 150);
     Columns[10].Width :=Ini.ReadInteger( 'ODBViewer', 'DBGridCruise_Col10',  70);
     Columns[11].Width :=Ini.ReadInteger( 'ODBViewer', 'DBGridCruise_Col11',  70);
     Columns[12].Width :=Ini.ReadInteger( 'ODBViewer', 'DBGridCruise_Col12',  70);
    End;

    with DBGridStationInfo do begin
     Columns[0].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridStation1_Col00',    70);  //CheckBox
     Columns[1].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridStation1_Col01',    70);  //STATION ID
     Columns[2].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridStation1_Col02',    70);  //CRUISE ID
     Columns[3].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridStation1_Col03',    70);  //FLAG
     Columns[4].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridStation1_Col04',    70);  //LATITUDE
     Columns[5].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridStation1_Col05',    70);  //LONGITUDE
     Columns[6].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridStation1_Col06',    70);  //DATE
     Columns[7].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridStation1_Col07',    70);  //SOURCE
     Columns[8].Width  :=Ini.ReadInteger( 'ODBViewer', 'DBGridStation1_Col08',    70);  //PLATFORM
    end;
  finally
    Ini.Free;
  end;

  NavigationOrder:=true;
  frmmap_open:=false;
  frmprofile_plot_all_open:=false;
end;


procedure Tfrmmain.iOpenDBClick(Sender: TObject);
Var
  Ini:TIniFile;
  DB2Name: string;
begin
 OD.Filter:='Firebird database|*.fdb;*.FDB';

 if OD.Execute then begin
  Ini := TIniFile.Create(IniFileName);
  try
    DB2Name :=Ini.ReadString( 'ODBViewer', 'oceanfdb', '');
  finally
    Ini.Free;
  end;

   if (DB2Name<>'') then begin
      if TR2.Active then TR2.Commit;
      DB2.Close();
      DB2.DatabaseName:=DB2Name;
      DB2.connected:=true;
    end else begin
     iICES.Enabled:=false;
    end;

    IBName:=OD.FileName;

    if TR.Active then TR.Commit;
    DB1.Close();
    DB1.DatabaseName:=IBName;
    DB1.connected:=true;

    Application.Title:=ExtractFileName(IBName);
    Caption:='DB Viewer: '+Application.Title;
    Application.ProcessMessages;

    DatabaseInfo;
  end;

end;

procedure Tfrmmain.iRemoveDuplicatesClick(Sender: TObject);
begin

end;


procedure Tfrmmain.DatabaseInfo;
var
k, i:integer;
begin
ListBox1.Clear;
ListBox2.Clear;

   with q1 do begin
    Close;
        SQL.Clear;
        SQL.Add(' select count(STATION.ABSNUM) as StCount, ');
        SQL.Add(' min(STATION.STLAT) as StLatMin, max(STATION.STLAT) as StLatMax, ');
        SQL.Add(' min(STATION.STLON) as StLonMin, max(STATION.STLON) as StLonMax, ');
        SQL.Add(' min(STATION.StDate) as StDateMin, ');
        SQL.Add(' max(STATION.StDate) as StDateMax ');
        SQL.Add(' from STATION ');
    Open;
      IBCount:=FieldByName('StCount').AsInteger;
       if IBCount>0 then begin
         IBLatMin  :=FieldByName('StLatMin').AsFloat;
         IBLatMax  :=FieldByName('StLatMax').AsFloat;
         IBLonMin  :=FieldByName('StLonMin').AsFloat;
         IBLonMax  :=FieldByName('StLonMax').AsFloat;
         IBDateMin :=FieldByName('StDateMin').AsDateTime;
         IBDateMax :=FieldByName('StDateMax').AsDateTime;

         with StatusBar1 do begin
           Panels[1].Text:='LtMin: '+floattostr(IBLatMin);
           Panels[2].Text:='LtMax: '+floattostr(IBLatMax);
           Panels[3].Text:='LnMin: '+floattostr(IBLonMin);
           Panels[4].Text:='LnMax: '+floattostr(IBLonMax);
           Panels[5].Text:='DateMin: '+datetostr(IBDateMin);
           Panels[6].Text:='DateMax: '+datetostr(IBDateMax);
           Panels[7].Text:='Stations: '+inttostr(IBCount);
         end;
      end else for k:=1 to 7 do StatusBar1.Panels[k].Text:='---';
    Close;
   end;

   DB1.GetTableNames(ListBox1.Items,False);

    ListBox2.Clear;
    for k:=0 to ListBox1.Items.Count-1 do
     if (copy(ListBox1.Items.Strings[k],1,2)='P_') then
       ListBox2.Items.Add(ListBox1.Items.Strings[k]);

  seLatMin.Value:=IBLatMin;
  seLatMax.Value:=IBLatMax;
  seLonMin.Value:=IBLonMin;
  seLonMax.Value:=IBLonMax;

  dtpDateMin.Date:=IBDateMin;
  dtpDateMax.Date:=IBDateMax;

  for k:=1 to 7 do StatusBar2.Panels[k].Text:='---';

end;


procedure Tfrmmain.CDSNavigation;
Var
ID:integer;
begin
ID:=CDS.FieldByName('absnum').AsInteger;
if NavigationOrder=false then exit;

 If NavigationOrder=true then begin
  NavigationOrder:=false; //blocking everthing until previous operations have been completed

     if frmmap_open=true then frmmap.ChangeID; //Map
     if frmprofile_station_all_open=true then frmprofile_station_all.ChangeID(ID); //
    // if frmprofile_station_single_open =true then frmprofile_station_single.ChangeID(ID);
     if frmprofile_plot_all_open=true then frmprofile_plot_all.ChangeID(ID);
 //    if frmmeteo_open=true then frmmeteo.ChangeID(ID);
 //  if InfoOpen      =true then Info.ChangeID;
 //  if QProfilesOpen =true then QProfiles.ChangeStation(ID);
 //  if DensOpen      =true then QDensity.ChangeDensStation(ID);
 //  if TSOPen        =true then frmToolTSDiagram.ChangeID;


 //  if MeteoOpen     =true then Meteo.ChangeAbsnum;
 //  if MLDOpen       =true then MLD.ChangeID;
 //  if TrackOpen     =true then frmVesselSpeed.ChangeID;
 //  if RossbyOpen    =true then Rossby.ChangeID;
 //  if QCTDOpen      =true then QCTD.ChangeID;
 //  if VertIntOpen   =true then VertInt.TblChange(ID)

  NavigationOrder:=true; //Р—Р°РІРµСЂС€РёР»Рё, РѕС‚РєСЂС‹РІР°РµРј РґРѕСЃС‚СѓРї Рє РЅР°РІРёРіР°С†РёРё
 end;
end;




procedure Tfrmmain.btnSelectClick(Sender: TObject);
var
i, k, fl:integer;
SSLatMin,SSLatMax,SSLonMin,SSLonMax :Real;
SSDateMin,SSDateMax :TDateTime;

NotCondCountry, NotCondVessel, NotCondSource, str, buf_str:string;
NotCondCruise, NotCondInstr, NotCondOrigin, instr:string;

Lat, Lon:real;
begin

 SaveSettings;

 SSLatMax  :=strtofloat(seLatMax.text);
 SSLatMin  :=strtofloat(seLatMin.text);
 SSLonMin  :=strtofloat(seLonMin.text);
 SSLonMax  :=strtofloat(seLonMax.text);
 SSDateMin :=dtpDateMin.Date;
 SSDateMax :=dtpDateMax.Date;


   if (SSDateMin>SSDateMax) then begin
       showmessage('First date exceeds the last one');
       exit;
   end;

   with CDS do begin
    Close;
    sql.Clear;
    SQL.Add(' select Station.Absnum, stlat, stlon, stdate,sttime,stdepthsource,stlastlevel, ');
    SQL.Add(' stsource, stcountryname, stvesselname, stflag, stversion, stdepthgrid, ');
    SQL.Add(' stdepthGridMin, stdepthgridmax, countrycode, vesselcode, projectcode, ');
    SQL.Add(' stnumincruise, institutecode, instrument, sourceuniqueId, vesselcruiseID, ');
    SQL.Add(' sourcedataorigin');
    SQL.Add(' from STATION, Station_Info where ');
    SQL.Add(' Station.absnum=Station_info.absnum ');
    SQL.Add(' and StLat between :SSLatMin and :SSLatMax ');
    if SSLonMax>=SSLonMin then
     SQL.Add(' and StLon between :SSLonMin and :SSLonMax ');
    if SSLonMax<SSLonMin then begin
     SQL.Add(' and ((StLon>=:SSLonMin and StLon<=180) or (StLon >=-180 and StLon<=:SSLonMax)) ');
    end;

         if SSDateMin<SSDateMax then begin
            SQL.Add('  and (((Stdate between :SSDateMin and :SSDateMax)) ');
            SQL.Add('  or   ((StDate=:SSDateMinF) and (StTime>=:SSTimeMin)) ');
            SQL.Add('  or   ((StDate=:SSDateMaxF) and (StTime<=:SSTimeMax))) ');
         end;
         if SSDateMin=SSDateMax then begin
            SQL.Add('  and (Stdate=:SSDateMin) ');
            SQL.Add('  and (StTime between :SSTimeMin and :SSTimeMax) ');
         end;

    if chkNOTCountry.Checked  =true then NotCondCountry  :='NOT' else NotCondCountry  :='';
    if chkNOTVessel.Checked   =true then NotCondVessel   :='NOT' else NotCondVessel   :='';
    if chkNOTSource.Checked   =true then NotCondSource   :='NOT' else NotCondSource   :='';

    if cbCountry.text<>''      then SQL.Add(' and '+NotCondCountry +' STCOUNTRYNAME='+QuotedStr(cbCountry.Text));
    if cbVessel.text<>''       then SQL.Add(' and '+NotCondVessel  +' STVESSELNAME='+QuotedStr(cbVessel.Text));
    if cbSource.text<>''       then SQL.Add(' and '+NotCondSource  +' STSOURCE='+QuotedStr(cbSource.Text));

    SQL.Add(' order by StDate, stTime ' );
 //   Showmessage(SQL.text);
    ParamByName('SSLatMin')  .AsFloat:=SSLatMin;
    ParamByName('SSLatMax')  .AsFloat:=SSLatMax;
    ParamByName('SSLonMin')  .AsFloat:=SSLonMin;
    ParamByName('SSLonMax')  .AsFloat:=SSLonMax;
    ParamByName('SSDateMin') .AsDateTime:=SSDateMin;
    ParamByName('SSDateMax') .AsDateTime:=SSDateMax;
    Open;
    Last;
    First;
  end;


  SelectionInfo;

 //Application.ProcessMessages;
end;

procedure Tfrmmain.cbCountryDropDown(Sender: TObject);
begin
   if cbCountry.Items.Count=0 then begin
       q1.SQL.Text:=' select distinct StCountryName from Station ';
       q1.Open;
      while not q1.Eof do begin
        cbCountry.Items.Add(q1.Fields[0].AsString);
        q1.Next;
      end;
        q1.Close;
        TR.Commit;
  //    DBGridEh1.Columns[8].PickList:=cbCountry.Items;
    end;
end;

procedure Tfrmmain.cbSourceDropDown(Sender: TObject);
begin
 if cbSource.Items.Count=0 then begin
   q1.close;
   q1.SQL.Text:=' select distinct(StSource) from Station order by StSource ';
   q1.Open;

   cbSource.Clear;
   while not q1.Eof do begin
     cbSource.AddItem(Q1.Fields[0].AsString, cbUnchecked, true);
    q1.Next;
   end;
    q1.Close;
    TR.Commit;
   // DBGridEh1.Columns[7].PickList:=cbSource.Items;
  //  CLBSources.Items:=cbSource.Items;
 end;
end;

procedure Tfrmmain.cbVesselDropDown(Sender: TObject);
begin
   if CbVessel.Items.Count=0 then begin
     q1.SQL.Text:=' select distinct StVesselName from Station ';
     q1.Open;
   while not q1.Eof do begin
     CbVessel.Items.Add(q1.Fields[0].AsString);
     q1.Next;
   end;
     q1.Close;
     TR.Commit;
   // DBGridEh1.Columns[9].PickList:=cbVessel.Items;
  end;
end;

procedure Tfrmmain.DBGridStationCellClick(Column: TColumn);
begin
  CDSNavigation;
end;

procedure Tfrmmain.DBGridStationKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   if (key=VK_UP) or (key=VK_DOWN) then CDSNavigation;
end;

procedure Tfrmmain.SelectionInfo;
var
k: integer;
lat1, lon1:real;
dat1:TDateTime;
items_enabled:boolean;
yy, mn, dd:word;
begin

 if CDS.RecordCount=0  then begin
     For k:=1 to StatusBar2.Panels.Count-1 do statusbar2.Panels[k].Text:='';
   Exit;
 end;


  CDS.DisableControls;
  try
  SLatMin:=90;  SLatMax:=-90;
  SLonMin:=180; SLonMax:=-180;
  SDateMin:=Now;
  yy:=1; mn:=1; dd:=1;
  SDateMax:=EncodeDate(yy, mn, dd);

  SCount:=CDS.RecordCount;
  SetLength(MapDataset, SCount+1);

  CDS.First;
  k:=-1;
  while not CDS.EOF do begin
   inc(k);
   lat1:=CDS.FieldByName('STLAT').AsFloat;
   lon1:=CDS.FieldByName('STLON').AsFloat;
   dat1:=CDS.FieldByName('STDATE').AsDateTime;

     if lat1<SLatMin then SLatMin:=lat1;
     if lat1>SLatMax then SLatMax:=lat1;
     if lon1<SLonMin then SLonMin:=lon1;
     if lon1>SLonMax then SLonMax:=lon1;
     if CompareDate(dat1, SDateMin)<0 then SDateMin:=dat1;
     if CompareDate(dat1, SDateMax)>0 then SDateMax:=dat1;

     MapDataset[k].ID:=frmmain.CDS.FieldByName('absnum').Value;
     MapDataset[k].Latitude :=lat1;
     MapDataset[k].Longitude:=lon1;

    CDS.Next;
  end;
  CDS.First;

     if SCount>0 then begin
       with StatusBar2 do begin
         Panels[1].Text:='LtMin: '+floattostr(SLatMin);
         Panels[2].Text:='LtMax: '+floattostr(SLatMax);
         Panels[3].Text:='LnMin: '+floattostr(SLonMin);
         Panels[4].Text:='LnMax: '+floattostr(SLonMax);
         Panels[5].Text:='DateMin: '+datetostr(SDateMin);
         Panels[6].Text:='DateMax: '+datetostr(SDateMax);
         Panels[7].Text:='Stations: '+inttostr(SCount);
       end;

       PageControl1.ActivePageIndex:=1;
     end else for k:=1 to 7 do StatusBar2.Panels[k].Text:='---';

  (* if there are selected station enabling some menu items *)
 // if SCount>0 then items_enabled:=true else items_enabled:=false;
    CDSNavigation;
  finally
     CDS.EnableControls;
  end;
end;


procedure Tfrmmain.DBGridStationPrepareCanvas(sender: TObject; DataCol: Integer;
  Column: TColumn; AState: TGridDrawState);
begin
   if (column.FieldName='ABSNUM') then begin
    TDBGrid(sender).Canvas.Brush.Color := clBtnFace;
   end;

 if (gdRowHighlight in AState) then begin
    TDBGrid(Sender).Canvas.Brush.Color := clNavy;
    TDBGrid(Sender).Canvas.Font.Color  := clYellow;
    TDBGrid(Sender).Canvas.Font.Style  := [fsBold];
 end;
end;

procedure Tfrmmain.DBGridStationTitleClick(Column: TColumn);
begin
  sortbufds.SortBufDataSet(frmmain.CDS, Column.FieldName);
end;


procedure Tfrmmain.SaveSettings;
Var
  Ini:TIniFile;
begin
  Ini := TIniFile.Create(IniFileName);
  try
    Ini.WriteFloat   ( 'ODBViewer', 'station_latmin',   seLatMin.Value);
    Ini.WriteFloat   ( 'ODBViewer', 'station_latmax',   seLatMax.Value);
    Ini.WriteFloat   ( 'ODBViewer', 'station_lonmin',   seLonMin.Value);
    Ini.WriteFloat   ( 'ODBViewer', 'station_lonmax',   seLonMax.Value);
    Ini.WriteString  ( 'ODBViewer', 'station_platform', cbVessel.Text);
    Ini.WriteString  ( 'ODBViewer', 'station_country',  cbCountry.Text);
    Ini.WriteString  ( 'ODBViewer', 'station_source',   cbSource.Text);
    Ini.WriteBool    ( 'ODBViewer', 'station_period',   chkPeriod.Checked);
    Ini.WriteDateTime( 'ODBViewer', 'station_datemin',  dtpDateMin.DateTime);
    Ini.WriteDateTime( 'ODBViewer', 'station_datemax',  dtpDateMax.DateTime);
  finally
    Ini.Free;
  end;
end;


procedure Tfrmmain.iICESClick(Sender: TObject);
begin
  frmLoadICES := TfrmLoadICES.Create(Self);
   try
    if not frmLoadICES.ShowModal = mrOk then exit;
   finally
     frmLoadICES.Free;
     frmLoadICES:= nil;
   end;
end;

procedure Tfrmmain.iLastLevelClick(Sender: TObject);
var
ci1, CurrentID, cnt, k:integer;
AbsNum:integer;
Max_Level, result:real;
begin
try
  With q1 do begin
   Close;
    SQL.Clear;
    SQL.Add(' Select absnum from Station order by StDate, StTime ');
   Open;
   Last;
   First;
  end;
  cnt:=Q1.RecordCount;

  q1.First;
  k:=0;
  while not q1.Eof do begin
   Absnum:=q1.FieldByName('Absnum').AsInteger;

    Max_Level:=-9;
    for ci1:=0 to ListBox2.Count-1 do begin
      With q2 do begin
       Close;
        SQL.Clear;
        SQL.Add(' Select max(Level_) from ');
        SQL.Add(ListBox2.Items.Strings[ci1]);
        SQL.Add(' where AbsNum=:pAbsNum ');
        Parambyname('pAbsnum').asInteger:=AbsNum;
       Open;
         Result:=q2.Fields[0].asFloat;
       Close;
      end;
      Max_Level:=Max(Max_Level, Result);
    end;

    With q3 do begin
     Close;
      SQL.Clear;
      SQL.Add(' Update Station set ');
      SQL.Add(' STLASTLEVEL=:Lev where absnum=:ID ');
      Parambyname('ID').asInteger:=AbsNum;
      Parambyname('Lev').asFloat:=Round(Max_Level);
     ExecSQL;
    end;

    inc(k);
    ProgressTaskbar(k, cnt);
   q1.Next;
 end;
finally
 TR.Commit;
 Showmessage('Done!');
end;
end;

procedure Tfrmmain.iLoad_IAOOCClick(Sender: TObject);
begin
 frmload_iaoos := Tfrmload_iaoos.Create(Self);
  try
   if not frmload_iaoos.ShowModal = mrOk then exit;
  finally
    frmload_iaoos.Free;
    frmload_iaoos:= nil;
  end;
end;

procedure Tfrmmain.imapClick(Sender: TObject);
begin
   if frmmap_open=true then frmmap.SetFocus else
    begin
       frmmap := Tfrmmap.Create(Self);
       frmmap.Show;
    end;
  frmmap.btnShowAllStationsClick(self);
  frmmap_open:=true;
end;


procedure Tfrmmain.MenuItem1Click(Sender: TObject);
begin
 frmsettings := Tfrmsettings.Create(Self);
  try
   if not frmsettings.ShowModal = mrOk then exit;
  finally
    frmsettings.Free;
    frmsettings:= nil;
  end;
end;

procedure Tfrmmain.MenuItem4Click(Sender: TObject);
begin
 frmimport_odb := Tfrmimport_odb.Create(Self);
  try
   if not frmimport_odb.ShowModal = mrOk then exit;
  finally
    frmimport_odb.Free;
    frmimport_odb:= nil;
  end;
end;

procedure Tfrmmain.MenuItem6Click(Sender: TObject);
begin
 frmloadkirillov := Tfrmloadkirillov.Create(Self);
  try
   if not frmloadkirillov.ShowModal = mrOk then exit;
  finally
    frmloadkirillov.Free;
    frmloadkirillov:= nil;
  end;
end;

procedure Tfrmmain.MenuItem8Click(Sender: TObject);
begin
   if frmparameters_list_open=true then frmparameters_list.SetFocus else
       begin
         frmparameters_list := Tfrmparameters_list.Create(Self);
         frmparameters_list.Show;
       end;
    frmparameters_list.Caption:='PROFILES';
    frmparameters_list_open:=true;
end;


procedure Tfrmmain.itestClick(Sender: TObject);
begin
 frmtest := Tfrmtest.Create(Self);
  try
   if not frmtest.ShowModal = mrOk then exit;
  finally
    frmtest.Free;
    frmtest:= nil;
  end;
end;


procedure Tfrmmain.iASCIIClick(Sender: TObject);
begin
  ExportASCII;

 if MessageDlg('Export completed', mtInformation, [mbOk], 0)=mrOk then
    OpenDocument(Globalpath+'export'+pathdelim);
end;

procedure Tfrmmain.iGEBCOClick(Sender: TObject);
Var
 ID, gebco, k, cnt:integer;
 Lat, Lon: real;
begin
 with q1 do begin
  Close;
   SQL.Clear;
   SQL.Add(' SELECT ABSNUM, STLAT, STLON FROM STATION');
//   SQL.Add(' WHERE ');
//   SQL.Add(' STDEPTHGRID=-9');
   SQL.Add(' ORDER BY ABSNUM');
  Open;
  Last;
  First;
 end;
 cnt:=q1.RecordCount;

 k:=0;
 q1.First;
 while not q1.EOF do begin
   ID   :=q1.FieldByName('ABSNUM').Value;
   Lat  :=q1.FieldByName('STLAT').Value;
   Lon  :=q1.FieldByName('STLON').Value;

   gebco:=-GetGEBCODepth(Lon, Lat);

   if gebco<>-99999 then begin
     with q2 do begin
      Close;
       SQL.Clear;
       SQL.Add(' UPDATE STATION SET STDEPTHGRID=:gebco ');
       SQL.Add(' WHERE ');
       SQL.Add(' ABSNUM=:ID');
       ParamByName('ID').Value:=ID;
       ParamByName('gebco').Value:=gebco;
      ExecSQL;
     end;
   end;
  inc(k);
  ProgressTaskbar(k, cnt);
  q1.Next;
 end;
 TR.Commit;
end;

procedure Tfrmmain.iIARCClick(Sender: TObject);
begin
 frmLoadIARC := TfrmLoadIARC.Create(Self);
  try
   if not frmLoadIARC.ShowModal = mrOk then exit;
  finally
    frmLoadIARC.Free;
    frmLoadIARC:= nil;
  end;
end;


procedure Tfrmmain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
Var
  Ini:TIniFile;
  k: integer;
begin
  Ini := TIniFile.Create(IniFileName);
   try
    Ini.WriteInteger( 'ODBViewer', 'top',    Top);
    Ini.WriteInteger( 'ODBViewer', 'left',   Left);
    Ini.WriteInteger( 'ODBViewer', 'width',  Width);
    Ini.WriteInteger( 'ODBViewer', 'weight', Height);

    (* cruise table columns *)
    With DBGridStation do begin
     Ini.WriteInteger( 'ODBViewer', 'DBGridCruise_Col00', Columns[0].Width);
     Ini.WriteInteger( 'ODBViewer', 'DBGridCruise_Col01', Columns[1].Width);
     Ini.WriteInteger( 'ODBViewer', 'DBGridCruise_Col02', Columns[2].Width);
     Ini.WriteInteger( 'ODBViewer', 'DBGridCruise_Col03', Columns[3].Width);
     Ini.WriteInteger( 'ODBViewer', 'DBGridCruise_Col04', Columns[4].Width);
     Ini.WriteInteger( 'ODBViewer', 'DBGridCruise_Col05', Columns[5].Width);
     Ini.WriteInteger( 'ODBViewer', 'DBGridCruise_Col06', Columns[6].Width);
     Ini.WriteInteger( 'ODBViewer', 'DBGridCruise_Col07', Columns[7].Width);
     Ini.WriteInteger( 'ODBViewer', 'DBGridCruise_Col08', Columns[8].Width);
     Ini.WriteInteger( 'ODBViewer', 'DBGridCruise_Col09', Columns[9].Width);
     Ini.WriteInteger( 'ODBViewer', 'DBGridCruise_Col10', Columns[10].Width);
     Ini.WriteInteger( 'ODBViewer', 'DBGridCruise_Col11', Columns[11].Width);
     Ini.WriteInteger( 'ODBViewer', 'DBGridCruise_Col12', Columns[12].Width);
    end;

    with DBGridStationInfo do begin
     Ini.writeInteger( 'ODBViewer', 'DBGridStation1_Col00',  Columns[0].Width);
     Ini.writeInteger( 'ODBViewer', 'DBGridStation1_Col01',  Columns[1].Width);
     Ini.writeInteger( 'ODBViewer', 'DBGridStation1_Col02',  Columns[2].Width);
     Ini.writeInteger( 'ODBViewer', 'DBGridStation1_Col03',  Columns[3].Width);
     Ini.writeInteger( 'ODBViewer', 'DBGridStation1_Col04',  Columns[4].Width);
     Ini.writeInteger( 'ODBViewer', 'DBGridStation1_Col05',  Columns[5].Width);
     Ini.writeInteger( 'ODBViewer', 'DBGridStation1_Col06',  Columns[6].Width);
     Ini.writeInteger( 'ODBViewer', 'DBGridStation1_Col07',  Columns[7].Width);
     Ini.writeInteger( 'ODBViewer', 'DBGridStation1_Col08',  Columns[8].Width);
    end;

  {  for k:=0 to cgQCFlag.Items.Count-1 do
      Ini.WriteBool( 'ODBViewer', 'QCF'+inttostr(k), cgQCFlag.Checked[k]);  }

   finally
     Ini.Free;
   end;


  DB1.Close;
  DB2.Close;

  FreeLibrary(libgswteos);
  FreeLibrary(netcdf);
end;

end.

