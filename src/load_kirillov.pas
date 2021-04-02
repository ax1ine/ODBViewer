unit load_kirillov;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { Tfrmloadkirillov }

  Tfrmloadkirillov = class(TForm)
    btnStart: TButton;
    chkWrite: TCheckBox;
    Edit1: TEdit;
    Memo1: TMemo;
    procedure btnStartClick(Sender: TObject);
  private

  public

  end;

var
  frmloadkirillov: Tfrmloadkirillov;

implementation

{$R *.lfm}

{ Tfrmloadkirillov }

uses main, StandartQueries;

procedure Tfrmloadkirillov.btnStartClick(Sender: TObject);
Var
dat: text;
DFile: string;
k, i, count, absnum, levnum, k_file, instrument, num1, nlev:integer;
st, buf_str, DB2Name,oldNum, Inst:string;
plat, num, time:string;
lat, lon, lev, lev_old, oldLat, OldLon, Pres:real;
yy, mn, dd, hh, mm:word;
Temp, Salt, Oxy, Phos, NO3, NO2, Ph, Alk, H2S:real;
snd, totP, totN, Sil, Amm, Chl:real;
StDate, StTime, OldTime, OldDate:TDateTime;
StCountryname, StVesselName, StSource:string;
begin


   StSource:='Kirillov';
   StCountryName:='UNKNOWN';
   memo1.Clear;
   btnStart.Enabled:=false;
   chkWrite.Enabled:=false;

   absnum:=0;
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


  DFile:=edit1.text;

  AssignFile(dat, dFile); Reset(dat);

  for k:=1 to 5 do readln(dat);

  repeat
   readln(dat, st);
    Plat:=trim(copy(st, 1, 15));
    Lat :=strtofloat(trim(copy(st, 23, 7)));
    Lon :=strtofloat(trim(copy(st, 38, 8)));
      if lon>180 then Lon:=Lon-360;
    yy:=strtoint(trim(copy(st, 55, 5)));
    mn:=strtoint(trim(copy(st, 61, 2)));
    dd:=strtoint(trim(copy(st, 64, 2)));

    sttime:=0;

    try
    stdate:=EncodeDate(yy, mn, dd);

    except
      stdate:=0;
    end;

   readln(dat, st);
    nlev:=strtoint(trim(copy(st, 18, 5)));

    inc(absnum);

    if chkWrite.Checked=false then
     memo1.lines.add(inttostr(absnum)+'   '+
                     floattostr(lat)+'   '+
                     floattostr(lon)+'   '+
                     datetostr(stdate)+'   '+
                     inttostr(nlev));

    if chkWrite.Checked=true then
  //   try
     StandartQueries.InsertMetadata(Absnum, 0, Lat, Lon, StDate, StTime,
                   StSource, 0, StCountryName, plat, -9,
                   '', '', '', -9, -9 ,
                   7, '', stsource, '');
    //  frmmain.TR.CommitRetaining;
 {    except
      frmmain.TR.RollbackRetaining;
     end;  }


    readln(dat);
    for k:=1 to nlev do begin
     readln(dat, lev, temp, salt);

     if (chkWrite.Checked=true) and (lev<>-9) then begin
        if Temp<>-9 then InsertParameters('P_TEMPERATURE', Absnum, lev, k, Temp, 0);
        if Salt<>-9 then InsertParameters('P_SALINITY',    Absnum, lev, k, Salt, 0);
    end;
   end;

    readln(dat);
  until eof(dat);
 closefile(dat);

 btnStart.Enabled:=true;
 chkWrite.Enabled:=true;
 showmessage('Done!');
end;

end.

