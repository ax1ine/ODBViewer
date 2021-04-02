unit export_ASCII;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, main, procedures;


procedure ExportASCII;

implementation

procedure ExportASCII;
Var
ff, ID: integer;
tbl, source, plat, tbl_suf, path: string;
Lat, lon, lev_d, lev_m: real;
depth, gebco:integer;
dat1:TDateTime;

out1, out2, out3: text;
yy, mn, dd:word;
cnt:integer;
begin
  path:=Globalpath+'export'+pathdelim;
    if not DirectoryExists(path) then CreateDir(path);

  Source:=ExtractFileName(IBName);
  Source:=copy(Source, 1, length(Source)-4);

 // showmessage(path+Source+'_MD_Full.txt');

  AssignFile(out1, path+Source+'_MD_Full.txt'); rewrite(out1);
  AssignFile(out2, path+Source+'_MD.txt'); rewrite(out2);
  AssignFile(out3, path+Source+'_data.txt'); rewrite(out3);

  try
   cnt:=0;
   frmmain.CDS.DisableControls;
   frmmain.CDS.First;
   while not frmmain.CDS.EOF do begin
    inc(cnt);

    ID   := frmmain.CDS.FieldByName('absnum').AsInteger;
    lat  := frmmain.CDS.FieldByName('stlat').AsFloat;
    lon  := frmmain.CDS.FieldByName('stlon').AsFloat;
    dat1 := frmmain.CDS.FieldByName('stdate').AsDateTime;
    plat := frmmain.CDS.FieldByName('stvesselname').AsString;
    gebco:= frmmain.CDS.FieldByName('stdepthsource').AsInteger;

    decodedate(dat1, yy, mn, dd);


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

     with frmmain.q1 do begin
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

       while not frmmain.Q1.eof do begin
         writeln(out3, inttostr(cnt)+' '+
                       floattostr(frmmain.Q1.Fields[0].AsFloat)+' '+
                       floattostr(frmmain.Q1.Fields[1].AsFloat)+' '+
                       floattostr(frmmain.Q1.Fields[2].AsFloat));

        frmmain.Q1.Next;
      end;

   ProgressTaskbar(cnt, frmmain.CDS.RecordCount);

   frmmain.CDS.Next;
  end; //Q

  finally
    frmmain.CDS.EnableControls;
    ProgressTaskbar(0, 0);
    CloseFile(out1);
    CloseFile(out2);
    CloseFile(out3);
  end;
end;

end.

