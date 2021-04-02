unit load_ices;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, IniFiles,
  dynlibs;

type

  { TForm1 }

  { TfrmLoadICES }

  TfrmLoadICES = class(TForm)
    Button1: TButton;
    btnStart: TButton;
    chkWrite: TCheckBox;
    eDataPath: TEdit;
    Label1: TLabel;
    lbC: TListBox;
    Memo1: TMemo;

    procedure btnStartClick(Sender: TObject);
    procedure eDataPathChange(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private

  public

  end;

var
  frmLoadICES: TfrmLoadICES;
  path_data: string;

implementation

{$R *.lfm}

{ TForm1 }

uses main, StandartQueries, gibbsseawater;


procedure TfrmLoadICES.FormShow(Sender: TObject);
begin
 eDataPath.Text:=GlobalPath+'data\ICES\';
end;

procedure TfrmLoadICES.eDataPathChange(Sender: TObject);
Var
fdb:TSearchRec;
begin
  path_data:=eDataPath.text;

   fdb.Name:='';
   lbC.Clear;
    FindFirst(Path_data+'*.csv',faAnyFile, fdb);
   if fdb.Name<>'' then lbC.Items.Add(fdb.Name);
   while findnext(fdb)=0 do lbC.Items.Add(fdb.Name);

  If lbC.Items.count>0 then btnStart.Enabled:=true;
end;


procedure TfrmLoadICES.btnStartClick(Sender: TObject);
Var
Ini:TIniFile;
dat: text;
DFile: string;
k, i, count, absnum, levnum, k_file, instrument, num1:integer;
st, buf_str, DB2Name,oldNum, Inst:string;
plat, num, time:string;
lat, lon, lev, lev_old, oldLat, OldLon, Pres:real;
yy, mn, dd, hh, mm:word;
Temp, Salt, Oxy, Phos, NO3, NO2, Ph, Alk, H2S:real;
snd, totP, totN, Sil, Amm, Chl:real;
StDate, StTime, OldTime, OldDate:TDateTime;
StCountryname, StVesselName, StSource:string;

Func:Tgsw_z_from_p;
begin


   StSource:='ICES';
   memo1.Clear;
   btnStart.Enabled:=false;
   chkWrite.Enabled:=false;

    if chkWrite.Checked then begin
      with frmmain.q1 do begin
       Close;
        SQL.Clear;
        SQL.ADD(' Select max(absnum) from STATION ');
       Open;
         absnum:=frmmain.q1.Fields[0].AsInteger;
       Close;
      end;
    end;


 for k_file:=0 to lbC.Count-1 do begin
  DFile:=path_data+lbC.Items.Strings[k_file];

  AssignFile(dat, dFile); Reset(dat);
  readln(dat);

 lev_old:=-9; Count:=0;
 while not eof(dat) do begin
  readln(dat, st);

  Lat:=-9; Lon:=-9; snd:=-9;
  Lev:=-9; Temp:=-9; Salt:=-9; Oxy:=-9; Phos:=-9; NO3:=-9; NO2:=-9; Ph:=-9;
  Alk:=-9; H2S:=-9; totP:=-9; totN:=-9; Sil:=-9; Amm:=-9; Chl:=-9;


  i:=0; k:=0;
  repeat
   buf_str:='';
   repeat
     inc(i);
     if (st[i]<>',') then buf_str:=buf_str+st[i];
   until (st[i]=',') or (i=length(st));
   inc(k);

   if (trim(buf_str)<>'') and (copy(buf_str,1,1)<>'<') then begin
    if copy(DFile, length(DFile)-4, 1)='c' then begin
      Case k of
       1: Plat:=trim(buf_str);
       2: Num :=trim(buf_str);
       3: Inst:=trim(buf_str);
       4: Time:=trim(buf_str);
       5: Lat :=StrtoFloat(trim(buf_str));
       6: Lon :=StrtoFloat(trim(buf_str));
       7: Snd :=StrToFloat(trim(buf_str));
       8: Pres:=StrToFloat(trim(buf_str)); //pressure!!!
       9: Temp:=StrToFloat(trim(buf_str));
      10: Salt:=StrToFloat(trim(buf_str));
      11: Oxy :=StrToFloat(trim(buf_str));
     end;
     instrument:=4;
    end;


    if copy(DFile, length(DFile)-4, 1)='b' then begin
      Case k of
       1: Plat:=trim(buf_str);
       2: Num :=trim(buf_str);
       3: Inst:=trim(buf_str);
       4: Time:=trim(buf_str);
       5: Lat :=StrtoFloat(trim(buf_str));
       6: Lon :=StrtoFloat(trim(buf_str));
       7: Snd :=StrToFloat(trim(buf_str));
       8: Pres:=StrToFloat(trim(buf_str)); //pressure!!!
       9: Temp:=StrToFloat(trim(buf_str));
      10: Salt:=StrToFloat(trim(buf_str));
      11: Alk :=StrToFloat(trim(buf_str));
      12: Amm :=StrToFloat(trim(buf_str));
      13: Chl :=StrToFloat(trim(buf_str));
      14: Oxy :=StrToFloat(trim(buf_str));
      15: H2S :=StrToFloat(trim(buf_str));
      16: totN:=StrToFloat(trim(buf_str));
      17: NO3 :=StrToFloat(trim(buf_str));
      18: NO2 :=StrToFloat(trim(buf_str));
      19: Phos:=StrToFloat(trim(buf_str));
      20: PH  :=StrToFloat(trim(buf_str));
      21: Sil :=StrToFloat(trim(buf_str));
      22: totP:=StrToFloat(trim(buf_str));
     end;
    instrument:=7;
   end;
 end; // buf_str<>''

 until i=Length(St);

  //   if trystrtoint(num, num1)=true then inttostr(strtoint(num));

 // showmessage('here');

   yy:=StrToint(Copy(time, 1,4));
   mn:=StrToint(Copy(time, 6,2));
   dd:=StrToint(Copy(time, 9,2));
   hh:=StrToint(Copy(time,12,2));
   mm:=StrToint(Copy(time,15,2));

   StDate:=EncodeDate(yy,mn,dd);

   if hh=24 then hh:=0;
   if time<>'' then Sttime:=EncodeTime(hh,mm,0,0) else StTime:=Encodetime(0,0,0,0);

   if (Count=0) or (OldTime<>StTime) or (oldDate<>stdate) or
      (OldLat<>Lat) or (OldLon<>Lon) then begin

   StCountryName:='UNKNOWN';
   StVesselName:='UNKNOWN';
   if plat<>'????' then begin
     with frmmain.ib2q1 do begin
      Close;
       SQL.Clear;
       SQL.Add(' select name from Country ');
       SQL.Add(' where NODC_Code=:pNODCCode ');
       ParamByName('pNODCCode').AsString:=Copy(Plat,1,2);
      Open;
        if frmmain.ib2q1.IsEmpty=false then StCountryName:=Fields[0].AsString;
      Close;
     end;
     with frmmain.ib2q1 do begin
      Close;
       SQL.Clear;
       SQL.Add(' select Name from Platform ');
       SQL.Add(' where NODC_Code=:pNODCCode ');
       ParamByName('pNODCCode').AsString:=Plat;
      Open;
        if frmmain.ib2q1.IsEmpty=false then StVesselName:=Fields[0].AsString;
      Close;
     end;
   end else plat:='9999';

   inc(absnum);

    if chkWrite.Checked then
     StandartQueries.InsertMetadata(Absnum, 0, Lat, Lon, StDate, StTime,
                   StSource, 0, StCountryName, stVesselName, Snd,
                   strtoint(Copy(plat,1,2)), plat, Num, -9, -9 ,
                   instrument, num, stsource, '');

        oldtime:=StTime;
        olddate:=StDate;
        oldnum:=num;
        oldLat:=Lat;
        oldLon:=Lon;

      inc(Count);

      if chkWrite.Checked=false then begin
        //label1.Caption:=IntToStr(Count);
        Application.ProcessMessages;
      end;

      if chkWrite.Checked then frmmain.TR.CommitRetaining;

      levnum:=0;
    end;

   Func:=Tgsw_z_from_p(GetProcedureAddress(libgswteos, 'gsw_z_from_p'));
   lev:=-Func(pres, lat, 0, 0);


  //  if instrument=7 then lev:=round(lev);
    if (chkWrite.Checked=true) and (lev<>-9) then begin

     if Temp<>-9 then InsertParameters('P_TEMPERATURE',     Absnum, lev, levnum, Temp, 0);
     if Salt<>-9 then InsertParameters('P_SALINITY',        Absnum, lev, levnum, Salt, 0);
     if Oxy<>-9  then InsertParameters('P_OXYGEN',          Absnum, lev, levnum, Oxy,  0);
     if Phos<>-9 then InsertParameters('P_PHOSPHATE',       Absnum, lev, levnum, Phos, 0);
 //    if totP<>-9 then InsertParameters('P_TOTALPHOSPHORUS', Absnum, lev, totP, 0);
     if Sil<>-9  then InsertParameters('P_SILICATE',        Absnum, lev, levnum, Sil,  0);
     if NO3<>-9  then InsertParameters('P_NITRATE',         Absnum, lev, levnum, NO3,  0);
     if NO2<>-9  then InsertParameters('P_NITRITE',         Absnum, lev, levnum, NO2,  0);
  //   if Amm<>-9  then InsertParameters('P_AMMONIUM',        Absnum, lev, Amm,  0);
  //   if totN<>-9 then InsertParameters('P_TOTALNITROGEN',   Absnum, lev, totN, 0);
   //  if H2S<>-9  then InsertParameters('P_SULPHIDE',        Absnum, lev, H2S,  0);
     if PH<>-9   then InsertParameters('P_PH',              Absnum, lev, levnum, ph,   0);
     if Alk<>-9  then InsertParameters('P_ALKALINITY',      Absnum, lev, levnum, Alk,  0);
  //   if Chl<>-9  then InsertParameters('P_CHLOROPHYLL',     Absnum, lev, Chl,  0);

     inc(levNum);
    end;
  end;
  memo1.Lines.Add(DFile+#9+inttostr(count));
  CloseFile(dat);
 end;

 frmmain.TR2.Commit;
 if chkWrite.Checked then begin
   frmmain.TR.Commit;
 end;

 btnStart.Enabled:=true;
 chkWrite.Enabled:=true;
 showmessage('Done!');
end;



end.

