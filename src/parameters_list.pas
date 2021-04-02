unit parameters_list;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, SysUtils, Variants, Classes, Controls,
  StdCtrls, CheckLst, ComCtrls, Forms, Dialogs, ExtCtrls, IniFiles, SQLDB;

type

  { Tfrmparameters_list }

  Tfrmparameters_list = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    lbParameters: TListBox;
    btnAmountOfProfiles: TButton;
    btnCancel: TButton;

    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lbParametersClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure btnAmountOfProfilesClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnCancelClick(Sender: TObject);

  private
    { Private declarations }
    procedure SaveSettings;
  public
    { Public declarations }
  end;

var
  frmparameters_list: Tfrmparameters_list;
  cancel_fl:boolean=false;

implementation

uses main, profile_plot_all;

{$R *.lfm}


procedure Tfrmparameters_list.FormShow(Sender: TObject);
Var
 Ini:TIniFile;
 k: integer;
begin
 Ini := TIniFile.Create(IniFileName);
   try
    Width := Ini.ReadInteger( 'osparameters_list', 'width',  423);
    Height:= Ini.ReadInteger( 'osparameters_list', 'weight', 525);

   finally
     Ini.Free;
   end;

  lbParameters.Clear;
   for k:=0 to frmmain.ListBox2.Items.Count-1 do
    lbParameters.Items.Add(frmmain.ListBox2.Items.Strings[k]+' ');

end;


procedure Tfrmparameters_list.lbParametersClick(Sender: TObject);
var
par:string;
begin

 SaveSettings;

 try
   Par:=lbParameters.Items.Strings[lbParameters.ItemIndex];
   if Copy(par,1,1)='-' then exit;

   CurrentParTable:=trim(copy(Par,1,LastDelimiter(' ',Par)));

    // All profiles for selected stations
    if Caption='PROFILES' then begin
      if frmprofile_plot_all_open=true then begin
        frmprofile_plot_all_open:=false;
        frmprofile_plot_all.Close;
      end;
      frmprofile_plot_all:= Tfrmprofile_plot_all.Create(nil);
      frmprofile_plot_all_open:=true;
    end;

 {   //Запускаем временные серии
    if Caption='TDDIAGRAMS' then begin
     frmtimedepthdiagram := Tfrmtimedepthdiagram.Create(Self);
     try
      if not frmtimedepthdiagram.ShowModal = mrOk then exit;
     finally
      frmtimedepthdiagram.Free;
      frmtimedepthdiagram := nil;
     end;
    end;    }

 {   if Caption='TIME SERIES' then begin
     frmTimeSeries:= TfrmTimeSeries.Create(Self);
     try
      if not frmTimeSeries.ShowModal = mrOk then exit;
     finally
       frmTimeSeries.Free;
       frmTimeSeries := nil;
     end;
    end;

     if Caption='MEAN PROFILE' then begin
      MeanProfile:=TMeanProfile.Create(Self);
      try
        if MeanProfile.ShowModal = mrOk then
       finally
        MeanProfile.Free;
        MeanProfile := nil;
       end;
     end;     }

    {
    //Разрезы
    if Caption='SECTIONS'  then Sections:= TSections.Create(Self);

    if Caption='SECTIONS DIVA'  then Sections:= TSections.Create(Self);

     //Аномалии на разрезах
    if Caption='SECTION ANOMALIES' then begin
      if SectAnomOpen=false then SectionAnomalies:=TSectionAnomalies.Create(Self) else
                                 SectionAnomalies.SetFocus;
      SectAnomOpen:=true;
    end;

    //Поля
    if Caption='FIELDS' then begin
      if FieldsOpen=false then frmToolField:= TfrmToolField.Create(Self) else frmToolField.SetFocus;
        FieldsOpen:=true;
    end;

    if Caption='STATISTICS' then StandartLevels:= TStandartLevels.Create(Self);
    }

     lbParameters.ItemIndex:=-1; //Убираем фокус с выбранной строчки
   except
     //catching exception if the click is outside of the list
   end;
end;



procedure Tfrmparameters_list.btnAmountOfProfilesClick(Sender: TObject);
Var
prfCount,k_prf, ID_cur:integer;
tblPar:string;

TRt:TSQLTransaction;
Qt:TSQLQuery;
begin
TRt:=TSQLTransaction.Create(self);
TRt.DataBase:=frmmain.DB1;

Qt:=TSQLQuery.Create(self);
Qt.Database:=frmmain.DB1;
Qt.Transaction:=TRt;

btnAmountOfProfiles.Enabled:=false;
lbParameters.Enabled:=false;
lbParameters.Items.Clear;
try
 ID_cur:=frmmain.CDS.FieldByName('absnum').AsInteger;
 frmmain.CDS.DisableControls;
  for k_prf:=0 to frmmain.ListBox2.Count-1 do begin
   tblPar:=frmmain.ListBox2.Items.Strings[k_prf];

   if cancel_fl=false then begin
    prfCount:=0;
    frmmain.CDS.First;
     while not frmmain.CDS.Eof do begin
      with Qt do begin
       Close;
           SQL.Clear;
           SQL.Add(' SELECT ABSNUM FROM '+tblPar);
           SQL.Add(' WHERE ABSNUM=:ID ');
           SQL.Add(' ROWS 1 ');
           ParamByName('ID').AsInteger:=frmmain.CDS.FieldByName('ABSNUM').AsInteger;
         Open;
          if not Qt.IsEmpty then prfCount:=prfCount+1;
       Close;
      end;
      frmmain.CDS.Next;
    end;

     if prfCount>0 then begin
       lbParameters.Items.Add(tblPar+'   ['+inttostr(prfCount)+']');
       Application.ProcessMessages;
     end;

   end;
 end;
 Finally
  btnAmountOfProfiles.Enabled:=true;
  lbParameters.Enabled:=true;

  Qt.Close;
  Trt.Commit;
  Qt.Free;
  TrT.Free;
  frmmain.CDS.Locate('ABSNUM', ID_cur, []);
  frmmain.CDS.EnableControls;
 end;
end;


procedure Tfrmparameters_list.SaveSettings;
Var
  k :integer;
  Ini:TIniFile;
begin
  Ini := TIniFile.Create(IniFileName);
  try
   Ini.WriteInteger( 'osparameters_list', 'top',    Top);
   Ini.WriteInteger( 'osparameters_list', 'left',   Left);
   Ini.WriteInteger( 'osparameters_list', 'width',  Width);
   Ini.WriteInteger( 'osparameters_list', 'weight', Height);
  finally
    Ini.Free;
  end;
end;

procedure Tfrmparameters_list.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SaveSettings;
  frmparameters_list_open:=false;
end;


procedure Tfrmparameters_list.btnCancelClick(Sender: TObject);
begin
  cancel_fl:= true;
end;


procedure Tfrmparameters_list.FormResize(Sender: TObject);
begin
  if Width<=450 then lbParameters.Columns:=1;
  if (Width>450) and (Width<700) then lbParameters.Columns:=2;
  if Width>=700 then lbParameters.Columns:=3;
end;

{ Принудительно закрываем дочерние формы перед закрытием основной }
procedure Tfrmparameters_list.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
 {if DensOpen=true      then QDensity.Close;
 if QProfilesOpen=true then QProfiles.Close;
 if FieldsOpen=true    then frmToolField.Close; }
end;

end.
