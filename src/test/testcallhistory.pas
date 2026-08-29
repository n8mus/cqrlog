program testcallhistory;
{$mode objfpc}{$H+}
uses SysUtils, Classes, uCallHistory;
var
  h : TCallHistory;
  r : TCallHistRec;
  pass : Integer = 0;
  fail : Integer = 0;

procedure Check(const what,got,want : String);
begin
  if got=want then begin Inc(pass); WriteLn('  ok   ',what,' -> "',got,'"') end
  else begin Inc(fail); WriteLn('  FAIL ',what,' -> got "',got,'" want "',want,'"') end
end;

procedure CheckB(const what : String; got,want : Boolean);
begin
  Check(what,BoolToStr(got,True),BoolToStr(want,True))
end;

procedure W(const fn : String; const lines : array of String);
var l : TStringList; i : Integer;
begin
  l := TStringList.Create;
  try
    for i := Low(lines) to High(lines) do l.Add(lines[i]);
    l.SaveToFile(fn)
  finally l.Free end
end;

begin
  h := TCallHistory.Create;

  WriteLn('default column order');
  W('/tmp/ch1.txt',[
    '# a comment',
    'N8EM,Jon,EN82,,MI,MI,,,,,,4,8,note'
  ]);
  CheckB('loads',h.LoadFromFile('/tmp/ch1.txt'),True);
  CheckB('found',h.Lookup('n8em',r),True);
  Check('name',r.Name,'Jon');
  Check('state',r.State,'MI');
  Check('cqzone',r.CqZone,'4');
  CheckB('miss',h.Lookup('W1AW',r),False);

  WriteLn;
  WriteLn('!!Order!! redefines columns');
  W('/tmp/ch2.txt',[
    '!!Order!!,Call,Exch1,Name,Loc1,Sect,UserText',
    'G2CWO,20000,Club,G,G,CWops'
  ]);
  h.LoadFromFile('/tmp/ch2.txt');
  h.Lookup('G2CWO',r);
  Check('exch1 from order',r.Exch1,'20000');
  Check('name from order',r.Name,'Club');
  Check('sect from order',r.Sect,'G');
  Check('usertext',r.UserText,'CWops');

  WriteLn;
  WriteLn('the CWops duplicate-Misc trap');
  //Two columns both called Misc: the SECOND must not overwrite the first,
  //and the caller must be able to see that the file is malformed.
  W('/tmp/ch3.txt',[
    '!!Order!!,Call,Name,Misc,Misc,State',
    'K1ABC,Fred,1234,REGION,NH'
  ]);
  h.LoadFromFile('/tmp/ch3.txt');
  h.Lookup('K1ABC',r);
  Check('first Misc wins',r.Misc,'1234');
  Check('state still lands right',r.State,'NH');
  Check('duplicate reported',h.DuplicateColumns,'MISC');

  WriteLn;
  WriteLn('template expansion');
  W('/tmp/ch4.txt',['!!Order!!,Call,Name,State','K2XY,Ann,NY']);
  h.LoadFromFile('/tmp/ch4.txt');
  h.Lookup('K2XY',r);
  Check('two fields',h.Expand('%NAME% %STATE%',r),'Ann NY');
  Check('case insensitive',h.Expand('%name% %state%',r),'Ann NY');
  Check('unknown drops out',h.Expand('%NAME% %NOSUCH%',r),'Ann');
  //An empty field must not leave a double space or a trailing one.
  W('/tmp/ch5.txt',['!!Order!!,Call,Name,State','K3ZZ,Bob,']);
  h.LoadFromFile('/tmp/ch5.txt');
  h.Lookup('K3ZZ',r);
  Check('empty field collapses',h.Expand('%NAME% %STATE%',r),'Bob');

  WriteLn;
  WriteLn('edges');
  CheckB('missing file',h.LoadFromFile('/tmp/nope-does-not-exist.txt'),False);
  CheckB('miss after failed load',h.Lookup('N8EM',r),False);
  W('/tmp/ch6.txt',['#only comments','!!Order!!,Call,Name']);
  CheckB('no data rows',h.LoadFromFile('/tmp/ch6.txt'),False);
  //First entry wins so an appended correction cannot shadow the real row.
  W('/tmp/ch7.txt',['!!Order!!,Call,Name','K4AA,First','K4AA,Second']);
  h.LoadFromFile('/tmp/ch7.txt');
  h.Lookup('K4AA',r);
  Check('first duplicate row wins',r.Name,'First');
  Check('path sanitised',CallHistoryFile('/h/','../../etc/x'),'/h/callhistory'+PathDelim+'ETCX.txt');

  WriteLn;
  WriteLn('the real CWops file');
  if h.LoadFromFile('/home/jon/not1mm-config/data/cwops_call_history.txt') then
  begin
    WriteLn('  loaded ',h.Count,' calls');
    if h.Lookup('G2CWO',r) then
      WriteLn('  G2CWO -> exch1="',r.Exch1,'" name="',r.Name,'" sect="',r.Sect,'"')
    else
      WriteLn('  (G2CWO not present)');
    if h.DuplicateColumns <> '' then
      WriteLn('  duplicate columns seen: ',h.DuplicateColumns)
  end
  else
    WriteLn('  (file not present, skipped)');

  h.Free;
  WriteLn;
  WriteLn(pass,' passed, ',fail,' failed');
  if fail>0 then Halt(1)
end.
