program checkdefs;
{$mode objfpc}{$H+}
uses SysUtils, uContestRules;
var
  r : TContestRules;
  c : TQsoCtx;
  bad : Integer = 0;

function Mk(const call,band,mode,pfx,cont : String) : TQsoCtx;
begin
  Result := Default(TQsoCtx);
  Result.Call:=call; Result.Band:=band; Result.Mode:=mode;
  Result.CountryPfx:=pfx; Result.Continent:=cont;
  Result.MyCountryPfx:='K'; Result.MyContinent:='NA';
end;

procedure Want(const what : String; got,exp : Integer);
begin
  if got=exp then WriteLn('    ok   ',what,' = ',got)
  else begin WriteLn('    FAIL ',what,' = ',got,' expected ',exp); Inc(bad) end
end;

procedure Load(const f : String);
begin
  WriteLn(f);
  if not r.LoadFromFile('../../contests/'+f+'.contest') then
  begin WriteLn('    FAIL could not load'); Inc(bad) end
  else WriteLn('    loaded: ',r.DisplayName,'  cabrillo=',r.CabrilloName);
end;

begin
  r := TContestRules.Create;

  Load('CQ-WW-CW');
  Want('own country',      r.QsoPoints(Mk('W1AW','20M','CW','K','NA')),0);
  Want('same continent',   r.QsoPoints(Mk('VE3X','20M','CW','VE','NA')),1);
  Want('DX',               r.QsoPoints(Mk('DL1X','20M','CW','DL','EU')),3);

  Load('CQ-WPX-CW');
  Want('own country 20m',  r.QsoPoints(Mk('W1AW','20M','CW','K','NA')),1);
  Want('NA 20m',           r.QsoPoints(Mk('VE3X','20M','CW','VE','NA')),2);
  Want('EU 20m',           r.QsoPoints(Mk('DL1X','20M','CW','DL','EU')),3);
  Want('EU 40m doubled',   r.QsoPoints(Mk('DL1X','40M','CW','DL','EU')),6);
  Want('own country 80m NOT doubled',r.QsoPoints(Mk('W1AW','80M','CW','K','NA')),1);
  c := Mk('DL1X','40M','CW','DL','EU');
  if r.MultKey(1,c) <> 'DL1' then begin WriteLn('    FAIL wpx mult = ',r.MultKey(1,c)); Inc(bad) end
  else WriteLn('    ok   wpx mult once per contest = ',r.MultKey(1,c));

  Load('ARRL-DX-CW');
  Want('DX',               r.QsoPoints(Mk('DL1X','20M','CW','DL','EU')),3);
  Want('own country',      r.QsoPoints(Mk('W1AW','20M','CW','K','NA')),0);

  Load('CWOPS-CWT');
  Want('any qso',          r.QsoPoints(Mk('DL1X','20M','CW','DL','EU')),1);
  Want('score 10 q x 10 c',r.Score(10,10,0,0),100);

  Load('ICWC-MST');
  Want('any qso',          r.QsoPoints(Mk('DL1X','20M','CW','DL','EU')),1);

  r.Free;
  WriteLn;
  if bad=0 then WriteLn('all definitions OK') else begin WriteLn(bad,' problems'); Halt(1) end
end.
