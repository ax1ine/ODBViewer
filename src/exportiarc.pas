unit ExportIARC;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Menus, Dialogs, StdCtrls, Buttons, ExtCtrls, DB,
  ComCtrls, IBConnection, sqldb, sqldblib, DateUtils;

type

  { TImportDatabase }

  TImportDatabase = class(TForm)
    Button1: TButton;
    DB1: TIBConnection;
    Q: TSQLQuery;
    Q1: TSQLQuery;
    TR1: TSQLTransaction;
    BtnMergeDatabases: TBitBtn;

    procedure BtnMergeDatabasesClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private

  public
    { Public declarations }
  end;

var
  ImportDatabase: TImportDatabase;
  MCount:Integer;
  logf:text;


implementation


{$R *.lfm}

(* Открываем путь по-умолчанию *)
procedure TImportDatabase.FormShow(Sender: TObject);
begin
// DB1.DatabaseName:='C:\OceanShell\data\_merge_final\ODB_NA_ARCTIC.FDB';
 //DB1.DatabaseName:='C:\OceanShell\data\WOD18\WOD2018_NODUP.FDB';

DB1.DatabaseName:='x:\OceanShell_old\databases\ODB\ODB_NA_20200220_FB3.FDB';
DB1.connected:=true;

end;



procedure TImportDatabase.BtnMergeDatabasesClick(Sender: TObject);
Var
ff, ID: integer;
tbl, source, plat, tbl_suf: string;
Lat, lon, lev_d, lev_m: real;
depth, gebco:integer;
dat1:TDateTime;

out1, out2, out3: text;
yy, mn, dd:word;
cnt:integer;
begin

Source:='ArcticDataset';


AssignFile(out1, Source+'_MD_Full.txt');
AssignFile(out2, Source+'_MD.txt');
AssignFile(out3, Source+'_data.txt');

rewrite(out1);
rewrite(out2);
rewrite(out3);

{append(out1);
append(out2);
append(out3);}

with Q do begin
  Close;
   SQL.Clear;
   SQL.Add(' Select absnum, stlat, stlon, stdate, stvesselname, ');
   SQL.Add(' stdepthsource from STATION ');
   SQL.Add(' where stlat>=72 and stlat<=74 and stlon>=15 and stlon<=30 ');
   SQL.Add(' and stdate>='+quotedstr('01.01.2008')+' and stdate<='+quotedstr('31.12.2018'));
   SQL.Add(' order by stdate ');
  Open;
  Last;
  First;
end;

try
 cnt:=0;

 Q.DisableControls;
 Q.First;
 while not Q.EOF do begin

  ID  := Q.FieldByName('absnum').AsInteger;
  lat := Q.FieldByName('stlat').AsFloat;
  lon := Q.FieldByName('stlon').AsFloat;
  dat1:= Q.FieldByName('stdate').AsDateTime;
  plat:= Q.FieldByName('stvesselname').AsString;
  gebco:= Q.FieldByName('stdepthsource').AsInteger;


  decodedate(dat1, yy, mn, dd);

//  gebco := -GetBathymetry(lon,lat);

 { if (gebco>0) and (lat>0) then begin}
    inc(cnt);
    caption:=inttostr(cnt)+'   '+inttostr(id);
    Application.ProcessMessages;

 // if (cnt>127670) then begin


  Writeln(out1, inttostr(cnt)+' '+
                floattostr(lat)+' '+
                floattostr(lon)+' '+
                inttostr(yy)+' '+
                inttostr(mn)+' '+
                inttostr(dd)+' '+
                inttostr(gebco)+' '+
                Plat);

  Writeln(out2, inttostr(cnt)+' '+
                floattostr(lat)+' '+
                floattostr(lon)+' '+
                inttostr(yy)+' '+
                inttostr(mn)+' '+
                inttostr(dd));

     with Q1 do begin
      Close;
       SQL.Clear;
       SQL.Add(' SELECT P_TEMPERATURE.LEVEL_, ');
       SQL.Add(' P_TEMPERATURE.VALUE_, P_SALINITY.VALUE_ ');
       SQL.Add(' FROM P_TEMPERATURE, P_SALINITY ');
       SQL.Add(' WHERE P_TEMPERATURE.absnum=P_SALINITY.absnum ');
       SQL.Add(' AND P_TEMPERATURE.LEVEL_=P_SALINITY.LEVEL_ ');
       SQL.Add(' AND P_TEMPERATURE.ABSNUM=:ID ');
       SQL.Add(' ORDER BY P_TEMPERATURE.ABSNUM, P_TEMPERATURE.LEVEL_ ');
       ParamByName('ID').AsInteger:=ID;
      Open;
     end;

       while not Q1.eof do begin
         writeln(out3, inttostr(cnt)+' '+
                       floattostr(Q1.Fields[0].AsFloat)+' '+
                       floattostr(Q1.Fields[1].AsFloat)+' '+
                       floattostr(Q1.Fields[2].AsFloat));

        Q1.Next;
  //     end;
   end;

   Q.Next;
    end; //Q

  finally
     Q.EnableControls;
   // ProgressTaskbar(0, 0);

    CloseFile(out1);
    CloseFile(out2);
    CloseFile(out3);
  end;
end;



procedure TImportDatabase.Button1Click(Sender: TObject);
Var
ff, ID: integer;
tbl, source, plat, tbl_suf: string;
Lat, lon, lev_d, lev_m: real;
depth, gebco:integer;
dat1:TDateTime;

dat, out1, out2, out3: text;
yy, mn, dd:word;
cnt:integer;
begin

AssignFile(dat, 'salinity_90s.txt'); rewrite(dat);

Q.Close;
Q.SQL.Text:=' Select absnum, stlat, stlon, stdate '+
            ' from STATION WHERE stdate>='+QuotedStr('01.01.1990')+
            ' and stdate<='+QuotedStr('31.12.1999')+' order by stdate';
Q.Open;
Q.Last;
Q.First;

Q.DisableControls;
Q.First;
while not Q.EOF do begin

 ID  := Q.FieldByName('absnum').AsInteger;
 lat := Q.FieldByName('stlat').AsFloat;
 lon := Q.FieldByName('stlon').AsFloat;
 dat1:= Q.FieldByName('stdate').AsDateTime;

 decodedate(dat1, yy, mn, dd);

  with Q1 do begin
      Close;
       SQL.Clear;
       SQL.Add(' SELECT LEVEL_, VALUE_ ');
       SQL.Add(' FROM P_SALINITY ');
       SQL.Add(' WHERE ABSNUM=:ID ');
       SQL.Add(' AND flag_<=4096 AND LEVEL_<=150 ');
       SQL.Add(' ORDER BY LEVEL_ ');
       ParamByName('ID').AsInteger:=ID;
      Open;
     end;

       while not Q1.eof do begin
         writeln(dat,  inttostr(yy)+' '+inttostr(mn)+' '+inttostr(dd)+' '+
                       floattostrF(lon, fffixed, 8, 5)+' '+
                       floattostrF(lat, fffixed, 8, 5)+' '+
                       floattostr(Q1.Fields[0].AsFloat)+' '+
                       floattostr(Q1.Fields[1].AsFloat));

        Q1.Next;
  //     end;
   end;

   Q.Next;
    end; //Q
CloseFile(dat);
end;


end.
