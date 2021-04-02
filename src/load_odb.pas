unit load_odb;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Menus, Dialogs, StdCtrls, CheckLst, Buttons, ExtCtrls, DB,
  FileCtrl, ComCtrls, IniFiles, IBConnection, sqldb, DateUtils, Spin;

type

  { Tfrmimport_odb }

  Tfrmimport_odb = class(TForm)
    Edit2: TEdit;
    btnOpenFolder: TButton;
    CheckListBox1: TCheckListBox;
    DB2TableList: TListBox;
    DB2: TIBConnection;
    ib2q1: TSQLQuery;
    ib2q2: TSQLQuery;
    StatusBar1: TStatusBar;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    DB1TableList: TListBox;
    rgDuplicates: TRadioGroup;
    BtnMergeDatabases: TBitBtn;
    GroupBox2: TGroupBox;
    Label2: TLabel;
    sePos: TSpinEdit;
    TR2: TSQLTransaction;

    procedure BtnMergeDatabasesClick(Sender: TObject);


    (* Сервисные процедуры *)
    procedure btnOpenFolderClick(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
    procedure CheckListBox1Click(Sender: TObject);
    procedure CheckListBox1DragDrop(Sender, Source: TObject; X,
      Y: Integer);
    procedure CheckListBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CheckListBox1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure CheckListBox1DrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure FormShow(Sender: TObject);
    procedure CheckListBox1DblClick(Sender: TObject);

  private
    { Private declarations }
    procedure GetMerged(DBName:string);
   // procedure Metadata(AbsnumFrom, AbsnumTo, Version:integer);
    procedure Meteo(AbsnumFrom, AbsnumTo:integer);
  //  procedure Parameters(AbsnumFrom, AbsnumTo:integer);
    procedure TblExistence(Var MetFl:boolean);

  public
    { Public declarations }
  end;

var
  frmimport_odb: Tfrmimport_odb;
  MCount:Integer;
  logf:text;

implementation


{$R *.lfm}

uses main;

(* Открываем путь по-умолчанию *)
procedure Tfrmimport_odb.FormShow(Sender: TObject);
Var
k:integer;
begin
 Edit2.Text:=GlobalPath;
 Edit2.OnChange(self);

 frmmain.DB1.GetTableNames(DB1TableList.Items, False);
end;



procedure Tfrmimport_odb.BtnMergeDatabasesClick(Sender: TObject);
Var
k:integer;
PathLog:string;
 t_cnt1, t_cnt2, s_cnt1, s_cnt2:integer;
 t_avg1, t_avg2, s_avg1, s_avg2:real;

begin
try

 PathLog:=ExtractFilePath(Application.ExeName);
 if not DirectoryExists(PathLog) then CreateDir(PathLog);

 AssignFile(logf, PathLog+'importlogerr.txt'); rewrite(logf);
 writeln(logf, 'ID_from':10, 'ID_to':10);

 MCount:=0;
 btnMergeDatabases.Enabled:=false;
 PageControl1.Enabled:=false;

  if PageControl1.ActivePageIndex=0 then begin
   for k:=0 to CheckListBox1.Count-1 do begin
    if CheckListBox1.checked[k]=true then begin  //начинаем перебирать базы
     CheckListBox1.ItemIndex:=k;
     StatusBar1.Panels[0].Text:=CheckListBox1.Items.Strings[k];
     Application.ProcessMessages;

     (* Подключаем по одной базе из списка *)
     GetMerged(Edit2.text+CheckListBox1.Items.Strings[k]);
    end;
   end;
  end;



  //TR1.Commit;
 // Main.UpdateIBContent;
 showmessage('OK! '+Inttostr(mCount)+' station(s) has(ve) been added');
finally
 btnMergeDatabases.Enabled:=true;
 PageControl1.Enabled:=true;
 CloseFile(logf);
end;
end;


procedure Tfrmimport_odb.GetMerged(DBName:string);
Var
K, K_fld, k_fld1, MaxVer, StVersion, StVer, Ver, Ver2, LevelNum:integer;
StLat, StLon, Lat2, Lon2:real;
AbsnumFrom, AbsnumTo, Abs2:integer;
flag, CountDup, ID_Dup:integer;
tbl, DB2Table, src:string;
MetFl, WriteFlag, NoWrite:boolean;
StDate, StTime, Date1, Date2, Time1, Time2, DateM:TDateTime;
yy, mn, dd, hh,mm,ss,ms:word;

t_cnt_from, t_cnt_to, s_cnt_from, s_cnt_to:integer;
t_avg_from, t_avg_to, s_avg_from, s_avg_to:real;

cnt:integer;

begin
 DB2.Close;
 DB2.DatabaseName:=DBName;
 DB2.Open;

 DB2TableList.Clear;
 DB2.GetTableNames(DB2TableList.Items,False);
 //TR2.StartTransaction;

{ frmmain.q1.SQL.Text:=' Select max(absnum) from station ';
 frmmain.q1.Open;
 AbsnumTo:=frmmain.q1.Fields[0].AsInteger; }

 (* Проверяем наличие и совпадение таблиц *)
  //TblExistence(MetFl);

  cnt:=0;

  with ib2q1 do begin
   Close;
     SQL.Clear;
     SQL.Add(' Select * from Station ');
     SQL.Add(' order by StDate, StTime');
   Open;
   Last;
   First;
  end;

    while not ib2q1.Eof do begin
     inc(cnt);
     AbsnumFrom:=ib2q1.FieldByName('absnum').AsInteger;
     StLat :=ib2q1.FieldByName('StLat').AsFloat;
     StLon :=ib2q1.FieldByName('StLon').AsFloat;
     StDate:=ib2q1.FieldByName('StDate').AsDateTime;
     StTime:=ib2q1.FieldByName('StTime').AsDateTime;

      with frmmain.q1 do begin
       Close;
        SQL.Clear;
        SQL.Add(' Select * from STATION where ' );
        SQL.Add(' StLat  between :StLat1 and :StLat2 and ');
        SQL.Add(' StLon  between :StLon1 and :StLon2 and ');
        SQL.Add(' StDate=:StDate');
        ParamByName('StLat1').AsFloat:=StLat-(sePos.Value/60);
        ParamByName('StLat2').AsFloat:=StLat+(sePos.Value/60);
        ParamByName('StLon1').AsFloat:=StLon-(sePos.Value/60);
        ParamByName('StLon2').AsFloat:=StLon+(sePos.Value/60);
        ParamByName('StDate').AsDate:=StDate;
        Open;
       end;

       // if there are duplicates
       StVersion:=0; MaxVer:=0; CountDup:=0;
       t_cnt_to:=0; s_cnt_to:=0;
       t_avg_to:=-999; s_avg_to:=-999;
       if frmmain.q1.IsEmpty=false then begin
         WriteFlag:=false;
         while not frmmain.q1.eof do begin
          Abs2 :=frmmain.q1.FieldByName('absnum').AsInteger;
          Lat2 :=frmmain.q1.FieldByName('StLat').AsFloat;
          Lon2 :=frmmain.q1.FieldByName('StLon').AsFloat;
          Date2:=frmmain.q1.FieldByName('StDate').AsDateTime;
          Time2:=frmmain.q1.FieldByName('StTime').AsDateTime;
          Ver2 :=frmmain.q1.FieldByName('StVersion').AsInteger;
          Src  :=frmmain.q1.FieldByName('StSource').AsString;

           inc(CountDup);

            if rgDuplicates.ItemIndex=1 then begin
               with frmmain.q2 do begin
                 Close;
                  SQL.Clear;
                  SQL.Add(' Delete from station ' );
                  SQL.Add(' where absnum=:absnum ' );
                  ParamByName('absnum').AsInteger:=Abs2;
                 ExecSQL;
                end;
            end;

          frmmain.q1.next;
         end;
       end;


     if frmmain.q1.IsEmpty=true then WriteFlag:=true;

     if countdup>0 then begin
       if rgDuplicates.ItemIndex=0 then WriteFlag:=false; //Оставляем текущую станцию
       if rgDuplicates.ItemIndex=1 then WriteFlag:=true; //Замещаем
       if rgDuplicates.ItemIndex=2 then begin
        StVersion:=MaxVer+1;
        WriteFlag:=true;  //Добавляем с новой версией
       end;
     end;

   if WriteFlag=true then begin //Пишем в базу

   //  inc(AbsnumTo);

    AbsnumTo:=AbsnumFrom;

    try
     (* Метаданные *)
      with frmmain.q1 do begin
         Close;
          SQL.Clear;
          SQL.Add(' INSERT INTO Station ' );
          SQL.Add(' (Absnum, STFLAG, STLAT, STLON, STDATE, STTIME, STSOURCE, ' );
          SQL.Add(' STVERSION, STCOUNTRYNAME, STVESSELNAME, STDEPTHSOURCE, ' );
          SQL.Add(' StLastLevel, STDEPTHGRID, STDEPTHGRIDMIN, STDEPTHGRIDMAX) ' );
          SQL.Add(' VALUES ' );
          SQL.Add(' (:Absnum, :STFLAG, :STLAT, :STLON, :STDATE, :STTIME, :STSOURCE, ');
          SQL.Add('  :STVERSION, :STCOUNTRYNAME, :STVESSELNAME, :STDEPTHSOURCE, ' );
          SQL.Add(' :StLastLevel, :STDEPTHGRID, :STDEPTHGRIDMIN, :STDEPTHGRIDMAX) ' );
          ParamByName('ABSNUM').AsInteger :=AbsnumTo;
          ParamByName('STFlag').AsInteger :=ib2q1.FieldByName('StFlag').AsInteger;
          ParamByName('STLAT').AsFloat    :=ib2q1.FieldByName('StLat').AsFloat;
          ParamByName('STLON').AsFloat    :=ib2q1.FieldByName('StLon').AsFloat;
          ParamByName('STDATE').AsDate    :=ib2q1.FieldByName('StDate').AsDateTime;
          ParamByName('STTIME').AsTime    :=ib2q1.FieldByName('StTime').AsDateTime;
          ParamByName('STSOURCE').AsString       :=ib2q1.FieldByName('StSource').AsString;
          ParamByName('STVERSION').AsInteger     :=StVersion;
          ParamByName('STCOUNTRYNAME').AsString  :=ib2q1.FieldByName('StCountryName').AsString;
          ParamByName('STVesselName').AsString   :=ib2q1.FieldByName('StVesselName').AsString;
          ParamByName('STDEPTHSOURCE').AsInteger :=ib2q1.FieldByName('StDepthSource').AsInteger;
          ParamByName('StLastLevel').AsInteger   :=ib2q1.FieldByName('StLastLevel').AsInteger;
          ParamByName('STDEPTHGRID').AsInteger   :=ib2q1.FieldByName('StDepthGrid').AsInteger;
          ParamByName('STDEPTHGRIDMIN').AsInteger:=ib2q1.FieldByName('StDepthGridMin').AsInteger;
          ParamByName('STDEPTHGRIDMAX').AsInteger:=ib2q1.FieldByName('StDepthGridMax').AsInteger;
         ExecSQL;
        Close;
       end;
       frmmain.TR.CommitRetaining;

       with ib2q2 do begin
        Close;
         SQL.Clear;
         SQL.Add(' Select * from STATION_info ' );
         SQL.Add(' where absnum=:absnum ' );
         ParamByName('absnum').AsInteger:=AbsnumFrom;
        Open;
       end;

       with frmmain.q1 do begin
        Close;
         SQL.Clear;
         SQL.Add(' INSERT INTO Station_Info ');
         SQL.Add(' (Absnum, CountryCode, VesselCode, ');
         SQL.Add('  StNumInCruise, ProjectCode, InstituteCode, Instrument, ');
         SQL.Add('  SourceUniqueID, SourceDataOrigin, VesselCruiseID) ');
         SQL.Add(' VALUES ' );
         SQL.Add(' (:Absnum, :CountryCode,:VesselCode, ');
         SQL.Add(' :StNumInCruise,:ProjectCode,:InstituteCode,:Instrument, ');
         SQL.Add(' :SourceUniqueID,:SourceDataOrigin,:VesselCruiseID) ');
         ParamByName('ABSNUM').AsInteger         :=AbsnumTo;
         ParamByName('CountryCode').AsString     :=ib2q2.FieldByName('CountryCode').AsString;
         ParamByName('VesselCode').AsString      :=ib2q2.FieldByName('VesselCode').AsString;
         ParamByName('StNumInCruise').AsString   :=ib2q2.FieldByName('StNumInCruise').AsString;
         ParamByName('ProjectCode').AsInteger    :=ib2q2.FieldByName('ProjectCode').AsInteger;
         ParamByName('InstituteCode').AsInteger  :=ib2q2.FieldByName('InstituteCode').AsInteger;
         ParamByName('Instrument').AsInteger     :=ib2q2.FieldByName('Instrument').AsInteger;
         ParamByName('SourceUniqueID').AsString  :=ib2q2.FieldByName('SourceUniqueID').AsString;
         ParamByName('SourceDataOrigin').AsString:=ib2q2.FieldByName('SourceDataOrigin').AsString;
         ParamByName('VesselCruiseID').AsString  :=ib2q2.FieldByName('VesselCruiseID').AsString;
        ExecSQL;
        Close;
       end;
     frmmain.TR.CommitRetaining;
     ib2q2.Close;

     (* METEO *)
    //  if MetFl=true then Meteo(AbsnumFrom, AbsnumTo);

     (* Таблицы параметров *)
     for k_fld:=1 to 2 do begin //Tables
      case k_fld of
         1: DB2Table:= 'P_TEMPERATURE';
         2: DB2Table:= 'P_SALINITY';
      end;

        with ib2q2 do begin //2
         Close;
           SQL.Clear;
           SQL.Add(' select * from ');
           SQL.Add(DB2Table);
           SQL.Add(' where absnum=:absnum ');
           ParamByName('absnum').AsInteger:=AbsnumFrom;
         Open;
        end; //2

         with frmmain.q1 do begin //5
              Close;
                SQL.Clear;
                SQL.Add(' insert into ');
                SQL.Add(DB2Table);
                SQL.Add(' (absnum, Level_, Value_, Flag_) ');
                SQL.Add(' values ');
                SQL.Add(' (:absnum, :Level_, :Value_, :Flag_) ');
              Prepare;
         end;

        if ib2q2.IsEmpty=false then begin  //3
        LevelNum:=0;
        while not ib2q2.Eof do begin //4
             with frmmain.q1 do begin
                 ParamByName('absnum').AsInteger:=AbsnumTo;
                 ParamByName('Level_').AsFloat:=ib2q2.FieldByName('level_').AsFloat;
                 ParamByName('Value_').AsFloat:=ib2q2.FieldByName('value_').AsFloat;
                 ParamByName('Flag_').AsInteger:=ib2q2.FieldByName('flag_').AsInteger;
              ExecSQL;
           end; //5
          inc(LevelNum);
          ib2q2.Next;
         end; //4
      end;
     end; //Tables

      inc(MCount);
      frmmain.TR.CommitRetaining;
    except
      frmmain.TR.RollbackRetaining;
      writeln(logf, absnumfrom:10, absnumto:10);
    end;

    StatusBar1.Panels[1].Text:=inttostr(MCount);
    Application.ProcessMessages;
  end; //Конец записи в базу

  caption:=inttostr(cnt);
  ib2q1.Next;
  end;
  ib2q1.Close;
 TR2.Commit;
end;



//Ищем заполненные таблицы переметров во второй БД
procedure Tfrmimport_odb.TblExistence(Var MetFl:boolean);
Var
flag:integer;
k_fld, k_fld1:integer;
begin
 For k_fld:=0 to DB2TableList.Count-1 do begin
  if Copy(DB2TableList.Items.Strings[k_fld],1,2)='P_' then begin
    ib2q1.Close;
    ib2q1.SQL.Text:='Select 1 from '+DB2TableList.Items.Strings[k_fld];
    ib2q1.Open;

    If ib2q1.IsEmpty=false then begin
     flag:=0;
     For k_fld1:=0 to DB1TableList.Count-1 do
      if DB1TableList.Items.Strings[k_fld1]=DB2TableList.Items.Strings[k_fld] then flag:=1;
      if flag=0 then begin
       with frmmain.q2 do begin
        Close;
         SQL.Clear;
         SQL.Add(' CREATE TABLE ');
         SQL.Add(DB2TableList.Items.Strings[k_fld]);
         SQL.Add(' LEVEL_    DECIMAL(5,1) NOT NULL, ');
         SQL.Add(' VALUE_    DECIMAL(5,3) NOT NULL, ');
         SQL.Add(' FLAG_     SMALLINT NOT NULL); ');
        ExecSQL;
       end;
       frmmain.TR.CommitRetaining;
      end;
    end;
    ib2q1.Close;
  end;
 end;

 MetFl:=false;
 For k_fld:=0 to DB2TableList.Count-1 do
  If DB2TableList.Items.Strings[k_fld]='METEO' then begin
   for k_fld1:=0 to DB1TableList.Items.Count-1 do
    if DB1TableList.Items.Strings[k_fld1]='METEO' then MetFl:=true;

     if MetFl=false then begin
      with frmmain.q1 do begin
       Close;
        SQL.Clear;
        SQL.Add(' CREATE TABLE METEO ');
        SQL.Add('(ABSNUM	    INTEGER NOT NULL, ');
        SQL.Add(' TEMPDRY	    DECIMAL(5, 2),    ');
        SQL.Add(' TEMPWET	    DECIMAL(5, 2),    ');
        SQL.Add(' PRESSURE	  DECIMAL(5, 1),    ');
        SQL.Add(' WINDDIR	    SMALLINT,         ');
        SQL.Add(' WINDSPEED	  NUMERIC(5, 0),    ');
        SQL.Add(' CLOUDCOMMON	SMALLINT,         ');
        SQL.Add(' CLOUDLOW	  SMALLINT,         ');
        SQL.Add(' CLOUDTYPE	  VARCHAR(20),      ');
        SQL.Add(' VISIBILITY	SMALLINT,         ');
        SQL.Add(' HUMABS	    DECIMAL(4, 1),    ');
        SQL.Add(' HUMREL	    SMALLINT,         ');
        SQL.Add(' WAVEHEIGHT	NUMERIC(5, 1),    ');
        SQL.Add(' WAVEDIR	    SMALLINT,         ');
        SQL.Add(' WAVEPERIOD	SMALLINT,         ');
        SQL.Add(' SEASTATE	  SMALLINT,         ');
        SQL.Add(' WEATHER	    SMALLINT,         ');
        SQL.Add(' WATERCOLOR	SMALLINT,         ');
        SQL.Add(' WATERTRANSP	SMALLINT,         ');
        SQL.Add(' SURFTEMP	  DECIMAL(5, 2),    ');
        SQL.Add(' SURFSALT	  DECIMAL(5, 2),    ');
        SQL.Add(' UNIQUE (ABSNUM)) ');
       ExecSQL;
      end;
      frmmain.TR.CommitRetaining;
     MetFl:=true;
    end;
  end;
end;


(* Копируем метео данные из добавляемой базы в общую *)
procedure Tfrmimport_odb.Meteo(AbsnumFrom, AbsnumTo:integer);
begin
  with ib2q2 do begin
   Close;
    SQL.Clear;
    SQL.Add(' Select * from Meteo ' );
    SQL.Add(' where absnum=:absnum ' );
    ParamByName('absnum').AsInteger:=AbsnumFrom;
   Open;
  end;

  with frmmain.q1 do begin
   Close;
    SQL.Clear;
    SQL.Add(' INSERT INTO METEO ');
    SQL.Add(' (absnum, tempdry, tempwet, pressure, winddir, windspeed, ');
    SQL.Add('  cloudcommon, cloudlow, cloudtype, visibility, humabs,  ');
    SQL.Add('  humrel, waveheight, wavedir, waveperiod, seastate, weather, ');
    SQL.Add('  Watercolor, watertransp, surftemp, surfsalt) ');
    SQL.Add(' VALUES ');
    SQL.Add(' (:absnum, :tempdry, :tempwet, :pressure, :winddir, :windspeed, ');
    SQL.Add('  :cloudcommon, :cloudlow, :cloudtype, :visibility, :humabs,  ');
    SQL.Add('  :humrel, :waveheight, :wavedir, :waveperiod, :seastate, :weather, ');
    SQL.Add('  :watercolor, :watertransp, :surftemp, :surfsalt) ');
    ParamByName('ABSNUM').AsInteger :=AbsnumTo;
    ParamByName('TEMPDRY').Value    :=ib2q2.FieldByName('TEMPDRY').Value;
    ParamByName('TEMPwet').Value    :=ib2q2.FieldByName('TEMPWET').Value;
    ParamByName('Pressure').Value   :=ib2q2.FieldByName('Pressure').Value;
    ParamByName('Winddir').Value    :=ib2q2.FieldByName('Winddir').Value;
    ParamByName('Windspeed').Value  :=ib2q2.FieldByName('windspeed').Value;
    ParamByName('Cloudcommon').Value:=ib2q2.FieldByName('Cloudcommon').Value;
    ParamByName('Cloudlow').Value   :=ib2q2.FieldByName('CloudLow').Value;
    ParamByName('Cloudtype').Value  :=ib2q2.FieldByName('Cloudtype').Value;
    ParamByName('Visibility').Value :=ib2q2.FieldByName('Visibility').Value;
    ParamByName('Humabs').Value     :=ib2q2.FieldByName('Humabs').Value;
    ParamByName('HumRel').Value     :=ib2q2.FieldByName('HumRel').Value;
    ParamByName('waveheight').Value :=ib2q2.FieldByName('waveheight').Value;
    ParamByName('wavedir').Value    :=ib2q2.FieldByName('wavedir').Value;
    ParamByName('waveperiod').Value :=ib2q2.FieldByName('waveperiod').Value;
    ParamByName('Seastate').Value   :=ib2q2.FieldByName('Seastate').Value;
    ParamByName('weather').Value    :=ib2q2.FieldByName('weather').Value;
    ParamByName('watercolor').Value :=ib2q2.FieldByName('watercolor').Value;
    ParamByName('watertransp').Value:=ib2q2.FieldByName('watertransp').Value;
    ParamByName('SurfTemp').Value   :=ib2q2.FieldByName('SurfTemp').Value;
    ParamByName('SurfSalt').Value   :=ib2q2.FieldByName('SurfSalt').Value;
   ExecSQL;
  end;
end;


////////////////////////////////////////////////////////////////////////////////
/////////////////////////////Сервисные процедуры////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


(* Диалог открытия папки *)
procedure Tfrmimport_odb.btnOpenFolderClick(Sender: TObject);
Var
path:string;
begin
SelectDirectory('Select folder', '' , path);
 if path<>'' then begin
   path:=path+'\';
   Edit2.text:=path;
   Edit2.OnChange(self);
 end;
end;

(* Поиск баз по мере ввода *)
procedure Tfrmimport_odb.Edit2Change(Sender: TObject);
Var
fdb:TSearchRec;
CurrentDB:string;
begin
  fdb.Name:='';
 // CurrentDB:='IARC_FINAL';
  CheckListBox1.Clear;
   FindFirst(concat(Edit2.Text,'*.FDB'),faAnyFile, fdb);
     if (fdb.Name<>'') and (fdb.Name<>CurrentDB) then CheckListBox1.Items.Add(fdb.Name);
   while findnext(fdb)=0 do
    if (fdb.Name<>IBName) then CheckListBox1.Items.Add(fdb.Name);
  FindClose(fdb);
end;

(* Раскрашиваем список *)
procedure Tfrmimport_odb.CheckListBox1DrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
begin
{ With (Control as TCheckListBox).Canvas do begin
   if Index mod 2=1 then Brush.Color :=$00CFFFF6 else Brush.Color :=$00CFEFE6;
    FillRect(Rect);
    TextOut(Rect.Left, Rect.Top, (Control as TCheckListBox).Items[Index]);
 end; }
end;

(* Проверяем, есть ли отмеченные базы *)
procedure Tfrmimport_odb.CheckListBox1Click(Sender: TObject);
var
  I: Integer;
  Flag:boolean;
begin
 //Flag:=false;
//  For I:=0 to CheckListBox1.Count-1 do if CheckListBox1.Checked[I] then Flag:=true;
// btnMergeDatabases.Enabled:=flag;
end;

(* Начинаем перетаскивание *)
procedure Tfrmimport_odb.CheckListBox1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) then (Sender as TControl).BeginDrag(false);
end;

(* Проверка доступности "сброса" *)
procedure Tfrmimport_odb.CheckListBox1DragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
 Accept := True;
end;

(* Заканчиваем перетаскивание *)
procedure Tfrmimport_odb.CheckListBox1DragDrop(Sender, Source: TObject; X,
  Y: Integer);
begin
 CheckListBox1.Items.Move(CheckListBox1.ItemIndex, CheckListBox1.ItemAtPos(Point(X, Y), true));
 (Sender as TControl).EndDrag(true);
end;


(* Ставим или снимаем флаги *)
procedure Tfrmimport_odb.CheckListBox1DblClick(Sender: TObject);
var
k:integer;
fl:boolean;
begin
if CheckListBox1.Count=0 then exit;
fl:=CheckListBox1.Checked[0];
 For k:=0 to CheckListBox1.Count-1 do CheckListBox1.Checked[k]:= not fl;
end;


end.
