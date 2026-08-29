program checkksqp;
{$mode objfpc}{$H+}
uses SysUtils, uContestRules;
var r : TContestRules; c : TQsoCtx; bad : Integer = 0;
procedure W(const what : String; got,exp : Integer);
begin
  if got=exp then WriteLn('  ok   ',what,' = ',got)
  else begin WriteLn('  FAIL ',what,' = ',got,' expected ',exp); Inc(bad) end
end;
function Mk(const call,band,mode,county : String) : TQsoCtx;
begin
  Result := Default(TQsoCtx);
  Result.Call:=call; Result.Band:=band; Result.Mode:=mode;
  Result.CountryPfx:='K'; Result.Continent:='NA';
  Result.ExchRcvd:=county;
  Result.MyCountryPfx:='K'; Result.MyContinent:='NA';
end;
begin
  r := TContestRules.Create;
  if not r.LoadFromFile(ContestDefFile('/home/jon/.config/cqrlog/','KS-QSO-PARTY')) then
  begin WriteLn('FAIL cannot load'); Halt(1) end;
  WriteLn('KS-QSO-PARTY  cabrillo=',r.CabrilloName,'  sent="',r.SentExch,'"');
  W('CW = 2 points',  r.QsoPoints(Mk('N0E','20M','CW','SED')),2);
  W('SSB = 1 point',  r.QsoPoints(Mk('N0E','20M','SSB','SED')),1);
  W('RTTY = 1 point', r.QsoPoints(Mk('N0E','20M','RTTY','SED')),1);
  c := Mk('N0E','20M','CW','SED'); c.IsDupe := True;
  W('dupe = 0',       r.QsoPoints(c),0);
  WriteLn('  dupe scope per band+mode: ',r.DupeType = dpPerBandMode);
  //county mult must be once per contest, so no band in the key
  c := Mk('N0E','20M','CW','SED');
  WriteLn('  mult key 20m = "',r.MultKey(1,c),'"');
  c.Band := '40M';
  WriteLn('  mult key 40m = "',r.MultKey(1,c),'"  (must match - once per contest)');
  if r.MultKey(1,c) <> 'SED' then begin WriteLn('  FAIL county mult carries a band'); Inc(bad) end;
  c := Mk('N0E','20M','CW','');
  if r.MultKey(1,c) <> '' then begin WriteLn('  FAIL empty county counted as a mult'); Inc(bad) end
  else WriteLn('  ok   no county = no multiplier');
  WriteLn('  F2 = ',r.MacroFor('F2',False));
  WriteLn('  score 50 CW qsos x 30 counties = ',r.Score(100,30,0,0));
  r.Free;
  WriteLn;
  if bad=0 then WriteLn('KSQP definition OK') else Halt(1)
end.
