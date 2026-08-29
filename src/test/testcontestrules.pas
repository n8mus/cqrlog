program testcontestrules;

{
  Bench test for uContestRules. Compile and run standalone - no GUI, no
  database, no Lazarus:

      cd src/test && fpc -Fu.. testcontestrules.pas && ./testcontestrules

  The scoring rules are arithmetic over a lookup and get subtly wrong in ways
  that are invisible in a contest until the Cabrillo is checked, so they are
  worth pinning down here rather than in a pileup.
}

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, uContestRules;

var
  Passed : Integer = 0;
  Failed : Integer = 0;

procedure Check(const what, got, want : String);
begin
  if got = want then
  begin
    Inc(Passed);
    WriteLn('  ok   ',what,'  -> ',got)
  end
  else
  begin
    Inc(Failed);
    WriteLn('  FAIL ',what,'  -> got "',got,'" want "',want,'"')
  end
end;

procedure CheckI(const what : String; got, want : Integer);
begin
  Check(what,IntToStr(got),IntToStr(want))
end;

procedure CheckB(const what : String; got, want : Boolean);
begin
  Check(what,BoolToStr(got,True),BoolToStr(want,True))
end;

{ ------------------------------------------------------------------ WPX }

procedure TestWpx;
begin
  WriteLn('WPX prefix');
  Check('N8EM',        WpxPrefix('N8EM'),        'N8');
  Check('W1AW',        WpxPrefix('W1AW'),        'W1');
  Check('DL1ABC',      WpxPrefix('DL1ABC'),      'DL1');
  Check('OH2BH',       WpxPrefix('OH2BH'),       'OH2');
  Check('4X4AA',       WpxPrefix('4X4AA'),       '4X4');
  Check('VP2E',        WpxPrefix('VP2E'),        'VP2');
  //A bare digit suffix renumbers the home prefix rather than adding one.
  Check('W1AW/4',      WpxPrefix('W1AW/4'),      'W4');
  Check('N8EM/9',      WpxPrefix('N8EM/9'),      'N9');
  //Shorter segment designates: both orders resolve to the same DX prefix.
  Check('DL/N8EM',     WpxPrefix('DL/N8EM'),     'DL0');
  Check('N8EM/DL',     WpxPrefix('N8EM/DL'),     'DL0');
  //Suffixes that mean nothing geographically fall back to the home call.
  Check('N8EM/P',      WpxPrefix('N8EM/P'),      'N8');
  Check('N8EM/QRP',    WpxPrefix('N8EM/QRP'),    'N8');
  Check('empty',       WpxPrefix(''),            '');
  WriteLn
end;

{ -------------------------------------------------------------- test files }

procedure WriteDef(const fn : String; const lines : array of String);
var
  l : TStringList;
  i : Integer;
begin
  l := TStringList.Create;
  try
    for i := Low(lines) to High(lines) do l.Add(lines[i]);
    l.SaveToFile(fn)
  finally
    l.Free
  end
end;

function Ctx(const call,band,mode,pfx,cont : String) : TQsoCtx;
begin
  //Default(), not FillChar: the record holds managed strings and zeroing
  //their pointers behind the compiler's back skips the refcount.
  Result := Default(TQsoCtx);
  Result.Call         := call;
  Result.Band         := band;
  Result.Mode         := mode;
  Result.CountryPfx   := pfx;
  Result.Continent    := cont;
  Result.MyCountryPfx := 'K';
  Result.MyContinent  := 'NA';
  Result.IsDupe       := False
end;

{ ------------------------------------------------------------------ CQ WW }

procedure TestCqWw;
var
  r : TContestRules;
  c : TQsoCtx;
begin
  WriteLn('CQ WW style: 0 pts same country, 1 same continent, 3 other, zone+country mults per band');
  WriteDef('/tmp/T1.contest',[
    '[Contest]',
    'Name=CQ-WW-CW',
    'CabrilloName=CQ-WW-CW',
    'Mode=CW',
    'DupeType=2',
    'PointsPerContact=3',
    'PointsByCountry=K, 0',
    'PointsByContinent=NA, 1',
    'Multiplier1Name=ZN',
    'IsMult1Per=1',
    'Multiplier2Name=CountryPrefix',
    'IsMult2Per=1'
  ]);
  r := TContestRules.Create;
  try
    CheckB('loads',r.LoadFromFile('/tmp/T1.contest'),True);
    Check('cabrillo name',r.CabrilloName,'CQ-WW-CW');
    CheckB('dupe per band',r.DupeType = dpPerBand,True);

    //Country list is more specific than continent, so a W is 0 not 1.
    c := Ctx('W1AW','20M','CW','K','NA');
    CheckI('own country = 0',r.QsoPoints(c),0);

    c := Ctx('VE3ABC','20M','CW','VE','NA');
    CheckI('same continent = 1',r.QsoPoints(c),1);

    c := Ctx('DL1ABC','20M','CW','DL','EU');
    CheckI('other continent = 3',r.QsoPoints(c),3);

    c := Ctx('DL1ABC','20M','CW','DL','EU');
    c.IsDupe := True;
    CheckI('dupe scores 0',r.QsoPoints(c),0);

    //Mults carry their scope, so the same entity on two bands is two keys.
    c := Ctx('DL1ABC','20M','CW','DL','EU');
    c.ZoneCQ := '14';
    Check('zone mult 20m',r.MultKey(1,c),'14|20M');
    Check('country mult 20m',r.MultKey(2,c),'DL|20M');
    c.Band := '40M';
    Check('country mult 40m',r.MultKey(2,c),'DL|40M');
  finally
    r.Free
  end;
  WriteLn
end;

{ -------------------------------------------------------------- ARRL DX }

procedure TestArrlDx;
var
  r : TContestRules;
  c : TQsoCtx;
begin
  WriteLn('ARRL DX from the US: only DX counts, 3 pts, state/prov not workable');
  WriteDef('/tmp/T2.contest',[
    '[Contest]',
    'Name=ARRL-DX-CW',
    'CabrilloName=ARRL-DX-CW',
    'DupeType=2',
    'IsWorkable=ExceptMyCountry',
    'PointsPerContact=3',
    'Multiplier1Name=CountryPrefix',
    'IsMult1Per=1'
  ]);
  r := TContestRules.Create;
  try
    r.LoadFromFile('/tmp/T2.contest');
    c := Ctx('DL1ABC','20M','CW','DL','EU');
    CheckB('DX workable',r.IsWorkable(c),True);
    CheckI('DX = 3 pts',r.QsoPoints(c),3);

    c := Ctx('W1AW','20M','CW','K','NA');
    CheckB('own country not workable',r.IsWorkable(c),False);
    CheckI('own country = 0 pts',r.QsoPoints(c),0);
    //An unworkable station must not inflate the multiplier count either.
    Check('own country is no mult',r.MultKey(1,c),'');
  finally
    r.Free
  end;
  WriteLn
end;

{ ------------------------------------------------------------------- WAE }

procedure TestWaeWeights;
var
  r : TContestRules;
  c : TQsoCtx;
begin
  WriteLn('WAE style: EU only from the US, band-weighted country mults');
  WriteDef('/tmp/T3.contest',[
    '[Contest]',
    'Name=DARC-WAEDC-CW',
    'CabrilloName=DARC-WAEDC-CW',
    'DupeType=2',
    'IsWorkable=EUonly',
    'PointsPerContact=1',
    'PointsByBand=160M, 0',
    'Multiplier1Name=CountryPrefix',
    'IsMult1Per=1'
  ]);
  r := TContestRules.Create;
  try
    r.LoadFromFile('/tmp/T3.contest');
    c := Ctx('DL1ABC','20M','CW','DL','EU');
    CheckI('EU on 20m = 1',r.QsoPoints(c),1);

    c := Ctx('DL1ABC','160M','CW','DL','EU');
    CheckI('160m scores 0 (not a WAE band)',r.QsoPoints(c),0);

    c := Ctx('VE3ABC','20M','CW','VE','NA');
    CheckB('NA not workable in WAE from US',r.IsWorkable(c),False);
    CheckI('NA = 0 pts',r.QsoPoints(c),0);
  finally
    r.Free
  end;
  WriteLn
end;

{ ------------------------------------------------------------------- MST }

procedure TestMst;
var
  r : TContestRules;
  c : TQsoCtx;
begin
  WriteLn('ICWC MST: 1 pt, mults are unique callsigns once per contest');
  WriteDef('/tmp/T4.contest',[
    '[Contest]',
    'Name=ICWC-MST',
    'CabrilloName=ICWC-MST',
    'DupeType=2',
    'PointsPerContact=1',
    'Multiplier1Name=CallSign',
    'IsMult1Per=4'
  ]);
  r := TContestRules.Create;
  try
    r.LoadFromFile('/tmp/T4.contest');
    c := Ctx('DL1ABC','20M','CW','DL','EU');
    CheckI('1 pt',r.QsoPoints(c),1);
    //Once per contest means the key must NOT carry a band.
    Check('call mult has no band',r.MultKey(1,c),'DL1ABC');
    c.Band := '40M';
    Check('same call on 40m is the same mult',r.MultKey(1,c),'DL1ABC');
  finally
    r.Free
  end;
  WriteLn
end;

{ ---------------------------------------------------------------- misc }

procedure TestEdges;
var
  r : TContestRules;
  c : TQsoCtx;
begin
  WriteLn('Edges');
  r := TContestRules.Create;
  try
    //No file at all: unloaded rules must score nothing rather than guess.
    CheckB('missing file does not load',r.LoadFromFile('/tmp/does-not-exist.contest'),False);
    c := Ctx('DL1ABC','20M','CW','DL','EU');
    CheckI('unloaded scores 0',r.QsoPoints(c),0);
    Check('unloaded has no mult',r.MultKey(1,c),'');

    //A malformed points value must fall back, not silently zero the contest.
    WriteDef('/tmp/T5.contest',[
      '[Contest]','Name=X','PointsPerContact=2','PointsByBand=20M, banana'
    ]);
    r.LoadFromFile('/tmp/T5.contest');
    c := Ctx('DL1ABC','20M','CW','DL','EU');
    CheckI('bad list value falls back to base',r.QsoPoints(c),2);

    //An empty multiplier value is not a multiplier.
    WriteDef('/tmp/T6.contest',[
      '[Contest]','Name=Y','Multiplier1Name=GridSquare','IsMult1Per=4'
    ]);
    r.LoadFromFile('/tmp/T6.contest');
    c := Ctx('DL1ABC','20M','CW','DL','EU');
    c.Grid := '';
    Check('empty grid is no mult',r.MultKey(1,c),'');
    c.Grid := 'JO31AB';
    Check('grid mult',r.MultKey(1,c),'JO31AB');

    //Path traversal in a contest name must not escape the contests dir.
    Check('def file sanitises',ContestDefFile('/home/x/','../../etc/passwd'),
          '/home/x/contests'+PathDelim+'ETCPASSWD.contest');
    Check('def file normal',ContestDefFile('/home/x/','CQ-WW-CW'),
          '/home/x/contests'+PathDelim+'CQ-WW-CW.contest');
  finally
    r.Free
  end;
  WriteLn
end;

{ ---------------------------------------------------------- TMultTracker }

procedure TestTracker;
var
  c : TQsoCtx;
begin
  WriteLn('MultTracker (spot colouring)');
  WriteDef('/tmp/T7.contest',[
    '[Contest]',
    'Name=TRK',
    'DupeType=2',
    'PointsPerContact=1',
    'Multiplier1Name=ZN',
    'IsMult1Per=1',
    'Multiplier2Name=CountryPrefix',
    'IsMult2Per=1'
  ]);

  //Inactive until a contest with rules is loaded - a spot must never be
  //coloured as a multiplier when no contest is running.
  MultTracker.SetRulesFile('');
  CheckB('inactive with no rules',MultTracker.Active,False);
  c := Ctx('DL1ABC','20M','CW','DL','EU');
  c.ZoneCQ := '14';
  CheckI('inactive reports no mults',MultTracker.NeededCount(c),0);

  MultTracker.SetRulesFile('/tmp/T7.contest');
  CheckB('active after load',MultTracker.Active,True);

  //Nothing worked yet, so zone AND country are both new = double mult.
  CheckI('unworked = double mult',MultTracker.NeededCount(c),2);

  MultTracker.BeginRebuild;
  MultTracker.AddWorked(1,'14|20M');
  MultTracker.EndRebuild;
  CheckI('zone worked = single mult',MultTracker.NeededCount(c),1);

  MultTracker.AddWorked(2,'DL|20M');
  CheckI('both worked = no mult',MultTracker.NeededCount(c),0);

  //Scope is baked into the key, so the same entity on another band is new.
  c.Band := '40M';
  CheckI('same station other band = double',MultTracker.NeededCount(c),2);

  //Switching contest must drop the previous contest's worked keys, or the
  //new contest starts out thinking everything is already worked.
  c.Band := '20M';
  MultTracker.SetRulesFile('/tmp/T7.contest');
  CheckI('contest switch clears worked keys',MultTracker.NeededCount(c),2);

  MultTracker.SetRulesFile('');
  CheckB('cleared again',MultTracker.Active,False);
  WriteLn
end;

begin
  WriteLn('uContestRules bench test');
  WriteLn('========================');
  WriteLn;
  TestWpx;
  TestCqWw;
  TestArrlDx;
  TestWaeWeights;
  TestMst;
  TestEdges;
  TestTracker;
  WriteLn('========================');
  WriteLn(Passed,' passed, ',Failed,' failed');
  if Failed > 0 then Halt(1)
end.
