program checkmacros;
{$mode objfpc}{$H+}
uses SysUtils, uContestRules;
var r : TContestRules; bad : Integer = 0;
procedure T(const contest : String);
var i : Integer; m : String;
begin
  WriteLn(contest);
  if not r.LoadFromFile(ContestDefFile('/home/jon/.config/cqrlog/',contest)) then
  begin WriteLn('  FAIL no definition'); Inc(bad); exit end;
  WriteLn('  SentExchange = "',r.SentExch,'"');
  for i := 1 to 10 do
  begin
    m := r.MacroFor('F'+IntToStr(i),False);
    if m <> '' then WriteLn('   F',i,' = ',m)
  end;
  //run bank must fall back to the S&P text when not separately defined
  if r.MacroFor('F1',True) <> r.MacroFor('F1',False) then
  begin WriteLn('  FAIL run bank did not fall back'); Inc(bad) end;
  if r.MacroFor('F9',False) <> '' then
  begin WriteLn('  FAIL undefined key should be empty'); Inc(bad) end;
end;
begin
  r := TContestRules.Create;
  T('CQ-WW-CW'); T('CWOPS-CWT'); T('ICWC-MST');
  r.Free;
  WriteLn;
  if bad=0 then WriteLn('macros OK') else begin WriteLn(bad,' problems'); Halt(1) end
end.
