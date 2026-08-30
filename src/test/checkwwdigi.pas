program checkwwdigi;
{$mode objfpc}{$H+}
uses SysUtils, uContestRules;
var r:TContestRules; bad:Integer=0;
function Mk(const call,band,mode,grid:String):TQsoCtx;
begin
  Result:=Default(TQsoCtx);
  Result.Call:=call; Result.Band:=band; Result.Mode:=mode;
  Result.Grid:=grid; Result.MyGrid:='EN82';   //Jon, SE Michigan
  Result.CountryPfx:='DL'; Result.Continent:='EU';
  Result.MyCountryPfx:='K'; Result.MyContinent:='NA';
end;
procedure W(const what:String; got,exp:Integer);
begin
  if got=exp then WriteLn('  ok   ',what,' = ',got)
  else begin WriteLn('  FAIL ',what,' = ',got,' expected ',exp); Inc(bad) end
end;
var c:TQsoCtx;
begin
  r:=TContestRules.Create;
  if not r.LoadFromFile(ContestDefFile('/home/jon/.config/cqrlog/','WW-DIGI')) then
  begin WriteLn('FAIL cannot load'); Halt(1) end;
  WriteLn('WW-DIGI  cabrillo=',r.CabrilloName);
  WriteLn('  EN82 -> JN58 is ',Round(GridDistanceKm('EN82','JN58')),' km');
  //1 point + 1 per 3000 km: 6876 km -> 1 + 2 = 3
  W('DL (6876 km) = 3 pts', r.QsoPoints(Mk('DL1ABC','20M','FT8','JN58')),3);
  //local contact, under 3000 km -> just the base point
  W('nearby (702 km) = 1 pt',r.QsoPoints(Mk('W3ABC','20M','FT8','FN20')),1);
  //long haul 15261 km -> 1 + 5 = 6
  W('VK (15261 km) = 6 pts',r.QsoPoints(Mk('VK2ABC','20M','FT8','QF56')),6);
  //no grid received -> cannot compute distance, base point only
  W('no grid = 1 pt',       r.QsoPoints(Mk('DL1ABC','20M','FT8','')),1);
  c:=Mk('DL1ABC','20M','FT8','JN58'); c.IsDupe:=True;
  W('dupe = 0',             r.QsoPoints(c),0);
  //multiplier is the 2-char FIELD, per band
  c:=Mk('DL1ABC','20M','FT8','JN58');
  WriteLn('  mult 20m JN58 = "',r.MultKey(1,c),'"');
  if r.MultKey(1,c)<>'JN|20M' then begin WriteLn('  FAIL want JN|20M'); Inc(bad) end;
  c.Grid:='JN99';
  if r.MultKey(1,c)<>'JN|20M' then begin WriteLn('  FAIL JN99 must be the same field JN'); Inc(bad) end
  else WriteLn('  ok   JN58 and JN99 are one field on a band');
  c.Band:='40M';
  if r.MultKey(1,c)<>'JN|40M' then begin WriteLn('  FAIL field must count per band'); Inc(bad) end
  else WriteLn('  ok   same field on another band is a new mult');
  r.Free;
  WriteLn;
  if bad=0 then WriteLn('WW-DIGI definition OK') else Halt(1)
end.
