program scorereal;
{ Scores a real dump of logged QSOs through uContestRules using the SAME
  algorithm as TfrmContest.RulesStatus, so the engine is checked against
  actual log data rather than fixtures. }
{$mode objfpc}{$H+}
uses SysUtils, Classes, uContestRules;
var
  r : TContestRules;
  f : TStringList;
  worked : TStringList;
  mults : array[1..3] of TStringList;
  i,j,qsos,dupes,pts : Integer;
  flagged : array[1..3] of Integer;
  a : TStringArray;
  c : TQsoCtx;
  key,mk : String;
begin
  if ParamCount < 2 then begin WriteLn('usage: scorereal <def> <tsv>'); Halt(2) end;
  r := TContestRules.Create;
  if not r.LoadFromFile(ParamStr(1)) then begin WriteLn('cannot load ',ParamStr(1)); Halt(1) end;
  WriteLn('Rules: ',r.DisplayName,'   (',r.CabrilloName,')');

  f := TStringList.Create; f.LoadFromFile(ParamStr(2));
  worked := TStringList.Create; worked.Sorted:=True; worked.Duplicates:=dupIgnore;
  for i:=1 to 3 do begin mults[i]:=TStringList.Create; mults[i].Sorted:=True; mults[i].Duplicates:=dupIgnore end;
  qsos:=0; dupes:=0; pts:=0;
  for j:=1 to 3 do flagged[j]:=0;

  for i:=0 to f.Count-1 do
  begin
    if Trim(f[i])='' then Continue;
    a := f[i].Split(['|']);
    if Length(a) < 11 then Continue;
    c := Default(TQsoCtx);
    c.Call:=UpperCase(Trim(a[0])); c.Band:=UpperCase(Trim(a[1])); c.Mode:=UpperCase(Trim(a[2]));
    c.Continent:=UpperCase(Trim(a[3])); c.ZoneCQ:=Trim(a[4]); c.ZoneITU:=Trim(a[5]);
    c.Grid:=Trim(a[6]); c.State:=Trim(a[7]); c.SerialRcvd:=Trim(a[8]); c.ExchRcvd:=Trim(a[9]);
    c.CountryPfx:=UpperCase(Trim(a[10]));
    c.MyCountryPfx:='K'; c.MyContinent:='NA';

    case r.DupeType of
      dpOncePerContest : key := c.Call;
      dpPerBandMode    : key := c.Call+'|'+c.Band+'|'+c.Mode;
      dpNone           : key := '';
    else                  key := c.Call+'|'+c.Band
    end;
    c.IsDupe := (key<>'') and (worked.IndexOf(key)>=0);
    if key<>'' then worked.Add(key);

    Inc(qsos); if c.IsDupe then Inc(dupes);
    Inc(pts,r.QsoPoints(c));
    for j:=1 to 3 do begin
      mk:=r.MultKey(j,c);
      if (mk<>'') and (mults[j].IndexOf(mk)<0) then begin mults[j].Add(mk); Inc(flagged[j]) end
    end;
  end;

  WriteLn('QSOs   : ',qsos,'   (dupes ',dupes,')');
  WriteLn('Points : ',pts);
  for j:=1 to 3 do if mults[j].Count>0 then
    WriteLn('Mult ',j,' (',r.MultName(j),') : ',mults[j].Count);
  WriteLn('SCORE  : ',r.Score(pts,mults[1].Count,mults[2].Count,mults[3].Count));
  for j:=1 to 3 do
    if mults[j].Count>0 then
      if flagged[j]=mults[j].Count then
        WriteLn('  ok   ismult',j,' rows flagged (',flagged[j],') = distinct mults (',mults[j].Count,')')
      else
        WriteLn('  FAIL ismult',j,' flagged ',flagged[j],' but ',mults[j].Count,' distinct mults');
end.
