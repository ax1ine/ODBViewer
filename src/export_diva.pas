unit export_DIVA;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Main, Dialogs;

//Procedure ExportDIVAMetadata;
Procedure ExportDIVA;


implementation


Procedure ExportDIVA;
Var
 f, f2: text;
 ID, ff, k, yymin, yymax, dec, GEBCO: integer;
 Lat, Lon, lev_m, lev_b, Val, dval, TVal, SVal, lev: real;
 yy, mn, dd, hh, mm, ss, ms:word;
 parname, fname, instr, mn_str, dd_str, hh_str, mm_str, id_str:string;
 d:string;
 x, y, LatMax, LonMax, LatMin, LonMin: real;
 ddd, ttt:TDateTime;
begin

   parname:='P_SALINITY';

    for dec:=1 to 1 {7} do begin
      case dec of
        1: begin
           yymin:=1950;
           yymax:=1959;
        end;
        2: begin
           yymin:=1960;
           yymax:=1969;
        end;
        3: begin
           yymin:=1970;
           yymax:=1979;
        end;
        4: begin
           yymin:=1980;
           yymax:=1989;
        end;
        5: begin
           yymin:=1990;
           yymax:=1999;
        end;
        6: begin
           yymin:=2000;
           yymax:=2009;
        end;
        7: begin
           yymin:=2010;
           yymax:=2019;
        end;
      end;

  //    showmessage(inttostr(dec));

 with frmmain.q1 do begin
  Close;
   SQL.Clear;
   SQL.Add(' SELECT ');
   SQL.Add(' STATION.ABSNUM, STATION.STLAT, STATION.STLON, ');
   SQL.Add(' STATION.STDATE, STATION.STDEPTHSOURCE FROM STATION ');
   SQL.Add(' WHERE ');
   SQL.Add(' Extract(Year from STATION.STDATE)>=:SSYear1 and ');
   SQL.Add(' Extract(Year from STATION.STDATE)<=:SSYear2 ');
   SQL.Add(' order by STATION.STDATE, STATION.absnum ');
   ParamByName('SSYear1').AsInteger:=yymin;
   ParamByName('SSYear2').AsInteger:=yymax;
  Open;
 end;


 AssignFile(f, inttostr(yymin)+inttostr(yymax)+'.txt'); rewrite(f);
 AssignFile(f2, inttostr(yymin)+inttostr(yymax)+'_MD.txt'); rewrite(f2);

 frmmain.q1.First;
 while not frmmain.q1.Eof do begin
    ID   :=frmmain.q1.FieldByName('absnum').asInteger;
    Lat  :=frmmain.q1.FieldByName('STLAT').asFloat;
    Lon  :=frmmain.q1.FieldByName('STLON').asFloat;
    ddd  :=frmmain.q1.FieldByName('STDATE').asDateTime;
    gebco:=frmmain.q1.FieldByName('STDEPTHSOURCE').asInteger;

    DecodeDate(ddd, yy, mn, dd);

    if GEBCO>=500 then
       writeln(f2, inttostr(ID)+#9+
                   floattostr(Lat)+#9+
                   floattostr(Lon)+#9+
                   datetostr(ddd));


  with frmmain.q2 do begin
  Close;
   SQL.Clear;
   SQL.Add(' SELECT ');
   SQL.Add( parname+'.level_, '+parname+'.value_ ');
   SQL.Add(' from '+parname);
   SQL.Add(' WHERE ');
   SQL.Add(' ABSNUM=:ID AND ');
   SQL.Add(parname+'.level_<=150 ');
   SQL.Add(' order by '+parname+'.level_');
   ParamByName('ID').AsInteger:=ID;
  Open;
 end;

 while not frmmain.q2.EOF do begin

    Lev  :=frmmain.q2.FieldByName('LEVEL_').asFloat;
    Val  :=frmmain.q2.FieldByName('VALUE_').asFloat;

    if GEBCO>=500 then begin
    try
    writeln(f, inttostr(yy)+' '+
               inttostr(mn)+' '+
               inttostr(dd)+' '+
               Floattostr(Lon)+' '+
               Floattostr(Lat)+' '+
               Floattostr(Lev)+' '+
               Floattostr(Val)+' '+
               inttostr(ID));

    except
    //  memo1.lines.add(inttostr(id));
    end;

    //sleep(1);
    end;
    frmmain.q2.Next;
  end;

  frmmain.q1.Next;
 end;
 frmmain.q1.Close;
 CloseFile(f);
 closefile(f2);
 end;

end;

end.

