unit load_iarc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TfrmLoadIARC }

  TfrmLoadIARC = class(TForm)
    btnMetadata: TButton;
    Button2: TButton;
    Memo1: TMemo;
    procedure btnMetadataClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private

  public

  end;

var
  frmLoadIARC: TfrmLoadIARC;

implementation

{$R *.lfm}

{ TfrmLoadIARC }

uses main, StandartQueries;

procedure TfrmLoadIARC.btnMetadataClick(Sender: TObject);
Var
  dat:text;
  st, buf_str, platf, orig_src, src:string;
  c, pp, ID, yy, mn, dd:integer;
  lat, lon:real;
  date1, time1:TDateTime;
begin
  AssignFile(dat, 'X:\OceanShell_old\databases\ArcticDataset\IARC\merged_MetaData_v1.009.ascii'); reset(dat);
 // 1 77.07170   9.51470 2015 5 26 "AWI  Polarstern PLSXXIX_1"
 // 2 81.17380  19.13450 2015 5 28 "AWI  Polarstern PLSXXIX_1"

  repeat
    readln(dat, st);

    c:=0;

    if st[c+1]=' ' then begin
     repeat
       inc(c);
     until (st[c]<> ' ') or (c=length(st));
     c:=c-1;
    end;

    for pp:=1 to 6 do begin
     buf_str:='';
     repeat
      inc(c);
      if st[c]<>' ' then buf_str:=buf_str+st[c];
     until (st[c]=' ') or (c=length(st));

     if st[c+1]=' ' then begin
     repeat
       inc(c);
     until (st[c]<> ' ') or (c=length(st));
     c:=c-1;
     end;


     case pp of
       1: ID:=strtoint(buf_str);
       2: Lat:=strtofloat(buf_str);
       3: Lon:=strtofloat(buf_str);
       4: yy:=strtoint(buf_str);
       5: mn:=strtoint(buf_str);
       6: dd:=strtoint(buf_str);
     end;

    // if id=2046 then showmessage(buf_str);
    end;
    src:=trim(copy(st, c, length(st)));
    src:=StringReplace(src, '"', '', [rfReplaceAll]);
    orig_src:=trim(copy(src, 1, pos(' ', src)-1));
    orig_src:=copy(orig_src, 1, 15);
    platf:=trim(copy(src, pos(' ', src), length(src)));

    try
    if (id<54990) or (id>55054) then
     date1:=encodedate(yy, mn,dd) else
     date1:=encodedate(1998, mn, yy);
    except
      showmessage(inttostr(id)+'   '+inttostr(yy)+'   '+inttostr(mn)+'   '+inttostr(dd));
    end;

    time1:=encodetime(12,0,0,0);

    StandartQueries.InsertMetadata(ID, 0, Lat, Lon, Date1, Time1,
       'IARC',0,'UNKNOWN', platf, -9, '', '', '', -9, -9,
       7, '', orig_src, '');

 { with frmmain.q1 do begin
   Close;
    SQL.Clear;
    SQL.Add(' UPDATE STATION SET' );
    SQL.Add(' STLAT=:STLAT, STLON=:STLON, STDATE=:STDATE, STVESSELNAME=:STVESSELNAME ');
    SQL.Add(' WHERE ' );
    SQL.Add(' ABSNUM=:ABSNUM ');
    ParamByName('ABSNUM'       ).Value:=ID;
    ParamByName('STLAT'        ).Value:=Lat;
    ParamByName('STLON'        ).Value:=Lon;
    ParamByName('STDATE'       ).Value:=Date1;
    ParamByName('STVesselName' ).Value:=Platf;
    ExecSQL;
 end; }

//  frmmain.TR.CommitRetaining;


 {   memo1.Lines.add(inttostr(ID)+'   '+
    floattostr(lat)+'   '+
    floattostr(lon)+'   '+
    inttostr(yy)+'   '+
    inttostr(mn)+'   '+
    inttostr(dd)+'   '+
    orig_src+'   '+
    platf);  }

  until eof(dat);
  closefile(dat);
  frmmain.TR.Commit;

end;

procedure TfrmLoadIARC.Button2Click(Sender: TObject);
Var
  dat:text;
  st, buf_str, platf:string;
  c, pp, ID, ID_OLD, yy, mn, dd, cnt, levelnum:integer;
  lat, lon:real;
  date1, time1:TDateTime;
  lev, temp, salt:real;
begin
  AssignFile(dat, 'X:\OceanShell_old\databases\ArcticDataset\IARC\merged_Data_v1.009.ascii'); reset(dat);

  with frmmain.q1 do begin
   Close;
     SQL.Clear;
     SQL.Add(' insert into ');
     SQL.Add(' P_TEMPERATURE ');
     SQL.Add(' (absnum, Level_, levelnum, Value_, Flag_) ');
     SQL.Add(' values ');
     SQL.Add(' (:absnum, :Level_, :levelnum, :Value_, :Flag_) ');
   Prepare;
  end;

  with frmmain.q2 do begin
   Close;
     SQL.Clear;
     SQL.Add(' insert into ');
     SQL.Add(' P_SALINITY ');
     SQL.Add(' (absnum, Level_, levelnum, Value_, Flag_) ');
     SQL.Add(' values ');
     SQL.Add(' (:absnum, :Level_, :levelnum, :Value_, :Flag_) ');
   Prepare;
 end;

  cnt:=0;
  levelnum:=0;
  repeat
   inc(cnt);
    readln(dat, st);     //id, lev, temp, salt);

    c:=0;

    if st[c+1]=' ' then begin
     repeat
       inc(c);
     until (st[c]<> ' ') or (c=length(st));
     c:=c-1;
    end;

    for pp:=1 to 4 do begin
     buf_str:='';
     repeat
      inc(c);
      if st[c]<>' ' then buf_str:=buf_str+st[c];
     until (st[c]=' ') or (c=length(st));

     if st[c+1]=' ' then begin
     repeat
       inc(c);
     until (st[c]<> ' ') or (c=length(st));
      c:=c-1;
     end;

     case pp of
       1: ID:=strtoint(buf_str);
       2: Lev:=strtofloat(buf_str);
       3: if trim (buf_str)<>'NaN' then Temp:=strtofloat(buf_str) else temp:=-9999;
       4: if trim (buf_str)<>'NaN' then Salt:=strtofloat(buf_str) else salt:=-9999;
     end;
    end;

    if (ID<>ID_OLD) then begin
     levelnum:=0;
     ID_OLD:=ID;
    end;


    if (temp<>-9999) and (salt<>-9999) then begin

    inc(levelnum);

      {    memo1.lines.add(inttostr(id)+'   '+
                      floattostr(lev)+'   '+
                      inttostr(levelnum)+'   '+
                      floattostr(temp)+'   '+
                      floattostr(salt));  }

   //    if id=3 then exit;
    //end;

      with frmmain.q1 do begin
        ParamByName('absnum').AsInteger:=ID;
        ParamByName('Level_').AsFloat:=Lev;
        ParamByName('Levelnum').AsInteger:=Levelnum;
        ParamByName('Value_').AsFloat:=Temp;
        ParamByName('Flag_').AsInteger:=0;
       ExecSQL;
      end;

      with frmmain.q2 do begin
        ParamByName('absnum').AsInteger:=ID;
        ParamByName('Level_').AsFloat:=Lev;
        ParamByName('Levelnum').AsInteger:=Levelnum;
        ParamByName('Value_').AsFloat:=Salt;
        ParamByName('Flag_').AsInteger:=0;
       ExecSQL;
      end;

 //   caption:=inttostr(ID);
 //   Application.ProcessMessages;
    end;

   if cnt=1000 then begin
    frmmain.Tr.CommitRetaining;
    cnt:=0;
   end;

  until eof(dat);
  closefile(dat);
  frmmain.Tr.Commit;


end;

end.

