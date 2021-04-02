unit load_iaoos;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, SQLDB, DB,
  DateUtils, Variants, BufDataset, LCLIntf, Buttons, ExtCtrls, math, dynlibs,
  IniFiles;

type

  { Tfrmload_iaoos }

  Tfrmload_iaoos = class(TForm)
    btnStart: TButton;
    chkWrite: TCheckBox;
    ePath: TEdit;
    Label1: TLabel;
    lbC: TListBox;
    Memo1: TMemo;

    procedure FormShow(Sender: TObject);
    procedure btnStartClick(Sender: TObject);

  private
    procedure WriteProfile(fname:string);
  public

  end;

var
  frmload_iaoos: Tfrmload_iaoos;
  path_data: string;
  absnum: integer;

implementation

{$R *.lfm}

{ Tfrmload_iaoos }

uses main, declarations_netcdf, GibbsSeaWater, procedures, StandartQueries;


procedure Tfrmload_iaoos.FormShow(Sender: TObject);
Var
fdb:TSearchRec;
begin
  path_data:=ePath.text;

   fdb.Name:='';
   lbC.Clear;
    FindFirst(Path_data+'*.nc',faAnyFile, fdb);
   if fdb.Name<>'' then lbC.Items.Add(fdb.Name);
   while findnext(fdb)=0 do lbC.Items.Add(fdb.Name);

  If lbC.Items.count>0 then btnStart.Enabled:=true;
end;


(* Running tasks one by one *)
procedure Tfrmload_iaoos.btnStartClick(Sender: TObject);
Var
  k:integer;
begin
 memo1.Clear;
 absnum:=0;
 for k:=0 to lbC.Count-1 do begin
   lbC.ItemIndex:=k;
    WriteProfile(path_data+lbC.Items.Strings[k]);
 end;
end;


procedure Tfrmload_iaoos.WriteProfile(fname:string);
Var
 ncid, varidp, ll, k, c, units_id, k_prof, k_pres, k_par, QF: integer;
 lat_varidp, lon_varidp, tim_varidp, tem_varidp, tqc_varidp:integer;
 lev_varidp, sal_varidp, sqc_varidp:integer;

 precision: integer;
 var_name, tbl, QF_str: string;
 n_prof, n_levels, n_param: size_t;
 ip: array of single;
 ff: array of PAnsiChar;
 dd: array of double;

 start: PArraySize_t;
 pres_QF, val_QF, QF_ll, pres_tbl, stsource, plat: String;

 limit_min, limit_max, stlat, stlon, stdate:double;
 val1, lev_m, pres, lev, tem, sal, tqc, sqc: double;
 isCore, isBest: boolean;
 IniDate, CurDate:TDateTime;
 levnum:integer;

 Func:Tgsw_z_from_p;

  nc_open:Tnc_open;
  nc_get_var_text:Tnc_get_var_text;
  nc_inq_varid:Tnc_inq_varid;
  nc_inq_dimid:Tnc_inq_dimid;
  nc_inq_dimlen:Tnc_inq_dimlen;
  nc_get_var1_double:Tnc_get_var1_double;
  nc_get_var1_text:Tnc_get_var1_text;
  nc_get_var1_float:Tnc_get_var1_float;
  nc_get_att_text:Tnc_get_att_text;
  nc_close:Tnc_close;
begin
 try

   nc_open:=Tnc_open(GetProcedureAddress(netcdf, 'nc_open'));
   nc_inq_dimid:=Tnc_inq_dimid(GetProcedureAddress(netcdf, 'nc_inq_dimid'));
   nc_inq_dimlen:=Tnc_inq_dimlen(GetProcedureAddress(netcdf, 'nc_inq_dimlen'));
   nc_inq_varid:=Tnc_inq_dimid(GetProcedureAddress(netcdf, 'nc_inq_varid'));
   nc_get_var_text:=Tnc_get_var_text(GetProcedureAddress(netcdf, 'nc_get_var_text'));
   nc_get_var1_double:=Tnc_get_var1_double(GetProcedureAddress(netcdf, 'nc_get_var1_double'));
   nc_get_var1_text:=Tnc_get_var1_text(GetProcedureAddress(netcdf, 'nc_get_var1_text'));
   nc_get_var1_float:=Tnc_get_var1_float(GetProcedureAddress(netcdf, 'nc_get_var1_float'));
   nc_get_att_text:=Tnc_get_att_text(GetProcedureAddress(netcdf, 'nc_get_att_text'));
   nc_close:=Tnc_close(GetProcedureAddress(netcdf, 'nc_close'));


  // opening NC file
  nc_open(pansichar(AnsiString(fname)), NC_NOWRITE, ncid); // only for reading

  // getting number of profiles
  nc_inq_dimid (ncid, pAnsiChar('PROFILE'), varidp);
  nc_inq_dimlen(ncid, varidp, n_prof);
//  showmessage(inttostr(varidp));

  // getting number of levels
  nc_inq_dimid (ncid, pAnsiChar('PRES'), varidp);
  nc_inq_dimlen(ncid, varidp, n_levels);
 // showmessage(inttostr(varidp));

  nc_inq_varid (ncid, pAnsiChar('PRES'),      lev_varidp);
  nc_inq_varid (ncid, pAnsiChar('LATITUDE'),  lat_varidp);
  nc_inq_varid (ncid, pAnsiChar('LONGITUDE'), lon_varidp);
  nc_inq_varid (ncid, pAnsiChar('TIME'),      tim_varidp);
  nc_inq_varid (ncid, pAnsiChar('TEMP'),      tem_varidp);
  nc_inq_varid (ncid, pAnsiChar('TEMP_QC_FLAGS'), tqc_varidp);
  nc_inq_varid (ncid, pAnsiChar('PSAL'),      sal_varidp);
  nc_inq_varid (ncid, pAnsiChar('PSAL_QC_FLAGS'), sqc_varidp);

  setlength(ff, 0);
  setlength(ff, 50);
  nc_get_att_text(ncid, NC_GLOBAL, pAnsiChar('platform_code'), ff);
  stsource:=pAnsiChar(ff);

  setlength(ff, 0);
  setlength(ff, 50);
  nc_get_att_text(ncid, NC_GLOBAL, pAnsiChar('cruise_ID'), ff);
  plat:=pAnsiChar(ff);

 // showmessage(stsource+'   '+plat);
  start:=GetMemory(SizeOf(TArraySize_t)*2);

  (* Loop over profiles *)
  For k_prof:=0 to n_prof-1 do begin
     levnum:=0;
    for k_pres:=0 to n_levels-1 do begin
    //  showmessage(inttostr(k_prof)+'   '+inttostr(k_pres));
     inc(levnum);

     start^[0]:=k_prof;
     start^[1]:=k_pres;

     SetLength(dd, 1);
      nc_get_var1_double(ncid, tim_varidp, start^, dd);
     if not isNan(dd[0]) then StDate:=dd[0] else stdate:=99999;

     if (stdate<>99999) then begin
       IniDate:=EncodeDateTime(1, 1, 1, 0, 0, 0, 0);
       CurDate:=IniDate+StDate;
       CurDate:=incyear(curdate, -1);
     end;

     SetLength(dd, 1);
      nc_get_var1_double(ncid, lat_varidp, start^, dd);
     if not isNan(dd[0]) then StLat:=dd[0] else StLat:=99999;

     SetLength(dd, 1);
      nc_get_var1_double(ncid, lon_varidp, start^, dd);
     if not isNan(dd[0]) then StLon:=dd[0] else StLon:=99999;

     SetLength(dd, 1);
      nc_get_var1_double(ncid, lev_varidp, start^, dd);
     if not isNan(dd[0]) then pres:=dd[0] else pres:=99999;

     if pres<>99999 then begin
       Func:=Tgsw_z_from_p(GetProcedureAddress(libgswteos, 'gsw_z_from_p'));
       lev:=-Func(pres, stlat, 0, 0);
     end;

     SetLength(dd, 1);
      nc_get_var1_double(ncid, tem_varidp, start^, dd);
     if not isNan(dd[0]) then Tem:=dd[0] else Tem:=99999;

     SetLength(dd, 1);
      nc_get_var1_double(ncid, tqc_varidp, start^, dd);
     if not isNan(dd[0]) then tqc:=dd[0] else tqc:=99999;

     SetLength(dd, 1);
      nc_get_var1_double(ncid, sal_varidp, start^, dd);
     if not isNan(dd[0]) then Sal:=dd[0] else Sal:=99999;

     SetLength(dd, 1);
      nc_get_var1_double(ncid, sqc_varidp, start^, dd);
     if not isNan(dd[0]) then sqc:=dd[0] else sqc:=99999;

     if (stlat<>99999) and (stlon<>99999) and (tem<>99999) and (sal<>99999) then begin

      if k_pres=0 then begin
       inc(absnum);
         if chkWrite.Checked=true then
          StandartQueries.InsertMetadata(Absnum, 0, StLat, StLon, CurDate, CurDate,
                   'IAOSS', 0, 'UNKNOWN', plat, -9,
                   '', '', '', -9, -9 ,
                   4, '', stsource, '');
       frmmain.TR.CommitRetaining;
      end;

      if chkWrite.Checked=true then begin
        if (tqc<3) and (sqc<3) then begin
          InsertParameters('P_TEMPERATURE', Absnum, lev, levnum, Tem, 0);
          InsertParameters('P_SALINITY',    Absnum, lev, levnum, Sal, 0);
        end;

      end;

      if chkWrite.Checked=false then
    memo1.lines.add(floattostr(stlat)+'   '+
                    floattostr(stlon)+'    '+
                    datetimetostr(curdate)+'    '+
                    floattostr(lev)+'    '+
                    floattostr(tem)+'    '+
                    floattostr(tqc)+'    '+
                    floattostr(sal)+'    '+
                    floattostr(sqc));

  end;
  end; // loop over n_level
 end; // loop over n_prof

 finally
  nc_close(ncid);
  FreeMemory(start);
  frmmain.TR.commit;
 end;
end;


{
procedure Tfrmload_iaoos.QFMapping(argo_QF:integer; var QF:integer);
begin
  QF:=0;
   case argo_QF of
     0: QF:=0;
     1: QF:=4;
     2: QF:=2;
     3: QF:=1;
     4: QF:=1;
     5: QF:=3;
     8: QF:=3;
   end;
end; }


end.

