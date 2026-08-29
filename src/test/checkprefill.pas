program checkprefill;
{ End-to-end: the REAL installed contest definition + the REAL installed call
  history, driven exactly as TfrmContest.PrefillFromHistory drives them. }
{$mode objfpc}{$H+}
uses SysUtils, uContestRules, uCallHistory;
var
  r : TContestRules;
  h : TCallHistory;
  rec : TCallHistRec;
  bad : Integer = 0;

procedure Try_(const contest, call : String);
var def,hist,got : String;
begin
  def  := ContestDefFile('/home/jon/.config/cqrlog/',contest);
  hist := CallHistoryFile('/home/jon/.config/cqrlog/',contest);
  WriteLn(contest);
  if not r.LoadFromFile(def) then begin WriteLn('  FAIL no definition: ',def); Inc(bad); exit end;
  if not h.LoadFromFile(hist) then begin WriteLn('  FAIL no call history: ',hist); Inc(bad); exit end;
  WriteLn('  template = "',r.HistExch,'"   history = ',h.Count,' calls');
  if h.DuplicateColumns <> '' then WriteLn('  NOTE duplicate columns: ',h.DuplicateColumns);
  if not h.Lookup(call,rec) then begin WriteLn('  FAIL ',call,' not in history'); Inc(bad); exit end;
  got := h.Expand(r.HistExch,rec);
  if Trim(got) = '' then begin WriteLn('  FAIL ',call,' expanded to nothing'); Inc(bad) end
  else WriteLn('  ok   ',call,' -> exchange box would prefill "',got,'"');
end;

begin
  r := TContestRules.Create; h := TCallHistory.Create;
  Try_('CWOPS-CWT','G2CWO');
  Try_('CWOPS-CWT','K1ESE');
  Try_('ICWC-MST','G2CWO');
  h.Free; r.Free;
  WriteLn;
  if bad=0 then WriteLn('prefill chain OK') else begin WriteLn(bad,' problems'); Halt(1) end
end.
