unit uContestRules;

{
  Contest rule engine.

  Before this unit a "contest" in cqrlog was nothing but a name: ContestName.tab
  is 224 lines of ADIF_ID|Description and the only contests that scored were
  MWC, NAC and SRAL FT8, hardcoded in fContest. Everything else fell through to
  a generic QSO counter.

  A contest is now a small declarative file - one per contest, in
  ~/.config/cqrlog/contests/<NAME>.contest - that says how to dupe, what the
  multipliers are, and what a QSO is worth. The key names deliberately follow
  N1MM's published User Defined Contest vocabulary, because that format is
  documented, stable, and there are hundreds of community files already written
  in it; importing one should be transcription, not translation.

  Deliberately NOT a scripting language. Anything genuinely algorithmic (WAE
  QTCs, Sweepstakes' five-part exchange) stays in Pascal, exactly as N1MM keeps
  those as compiled modules rather than UDCs. The file covers the 90% that is
  just arithmetic over a lookup.

  A contest with no definition file behaves exactly as it did before: no
  scoring, dupe checking from the radio buttons, generic counters.
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, StrUtils, Math;

type
  //What a multiplier IS. Names match the UDC Multiplier<N>Name values.
  TMultType = (mtNone,
               mtCountry,      //DXCC entity, via the country file
               mtWPXPrefix,    //CQ WPX style call prefix
               mtZoneCQ,
               mtZoneITU,
               mtGrid,         //6 char locator
               mtGrid4,        //4 char field+square, the VHF rule
               mtGridField,    //2 char field only - WW Digi counts these
               mtContinent,
               mtCallsign,     //unique calls worked, e.g. ICWC MST
               mtState,        //state/province from the log field
               mtExchange);    //whatever landed in the received message box

  //How often a multiplier counts. UDC IsMultPer.
  TMultScope = (msOnce,        //once for the whole contest
                msPerBand,
                msPerMode,
                msPerBandMode);

  //UDC DupeType 1..4
  TDupeType = (dpOncePerContest, dpPerBand, dpPerBandMode, dpNone);

  //Everything the evaluators need to know about one QSO. Filled by the caller
  //from the entry fields plus a country-file lookup, so this unit never has to
  //touch the database or the DXCC tables itself - which is what keeps it
  //testable and keeps the country lookup on the caller's cache.
  TQsoCtx = record
    Call        : String;
    Band        : String;   //cqrlog band string, e.g. '20M'
    Mode        : String;   //'CW','SSB',...
    CountryPfx  : String;   //DXCC primary prefix of the worked station
    Continent   : String;   //'EU','NA',...
    ZoneCQ      : String;
    ZoneITU     : String;
    Grid        : String;
    MyGrid      : String;   //needed for distance-scored contests
    State       : String;
    ExchRcvd    : String;   //received message box
    SerialRcvd  : String;
    MyCountryPfx: String;
    MyContinent : String;
    IsDupe      : Boolean;
  end;

  { TContestRules }

  TContestRules = class
  private
    fLoaded       : Boolean;
    fName         : String;
    fDisplayName  : String;
    fCabrilloName : String;
    fModeCat      : String;
    fDupeType     : TDupeType;
    fSerialByBand : Boolean;
    fWorkable     : String;
    fShowWarc     : Boolean;
    fHistExch     : String;
    fHistName     : Boolean;
    fSentExch     : String;
    fMacros       : TStringList;   //KEY=text, KEY is F1..F10 / RUNF1..RUNF10
    fMultName     : array[1..3] of String;
    fMultType     : array[1..3] of TMultType;
    fMultScope    : array[1..3] of TMultScope;
    fMultScores   : array[1..3] of Boolean;
    fPointsBase   : Integer;
    fCtryIsFinal  : Boolean;       //a country match skips the multiplier layers
    fDistKm       : Integer;       //>0: add a point per this many km
    fPointsByBand : TStringList;   //band=points
    fPointsByCont : TStringList;   //continent=points
    fPointsByCtry : TStringList;   //prefix=points
    fMultByBand   : TStringList;   //band=factor
    fMultByCont   : TStringList;   //continent=factor
    fMultByMode   : TStringList;   //mode=factor
    function  ParseMultType(s : String) : TMultType;
    function  ParseMultScope(n : Integer) : TMultScope;
    function  LookupNum(list : TStringList; const key : String;
                        def : Double; out found : Boolean) : Double;
    procedure LoadPairs(ini : TIniFile; const key : String; list : TStringList);
  public
    constructor Create;
    destructor  Destroy; override;
    function  LoadFromFile(const fn : String) : Boolean;
    procedure Clear;

    //Is this station workable at all for this contest? An unworkable QSO is
    //still logged - sponsors want it in the Cabrillo - but scores zero.
    function  IsWorkable(const ctx : TQsoCtx) : Boolean;
    //Points for one QSO. Dupes and unworkable stations score 0.
    function  QsoPoints(const ctx : TQsoCtx) : Integer;
    //Identity of multiplier idx for this QSO, '' when it is not one. The
    //string already carries the scope, so callers can just count distinct
    //values without knowing whether the mult is per band or per contest.
    function  MultKey(idx : Integer; const ctx : TQsoCtx) : String;
    //Display name of multiplier idx, as written in the definition file.
    function  MultName(idx : Integer) : String;
    //Total score. Multipliers declared with MultMult<N>=0 are shown but do
    //not touch the score, which is how contests display a count they do not
    //actually multiply by.
    function  Score(points, m1, m2, m3 : Integer) : Integer;

    property Loaded       : Boolean read fLoaded;
    property Name         : String read fName;
    property DisplayName  : String read fDisplayName;
    property CabrilloName : String read fCabrilloName;
    property ModeCat      : String read fModeCat;
    property DupeType     : TDupeType read fDupeType;
    property SerialByBand : Boolean read fSerialByBand;
    property ShowWarc     : Boolean read fShowWarc;
    //Template used to prefill the received-exchange box from call history,
    //e.g. "%NAME% %STATE%" for CWT. Empty disables exchange prefill.
    property HistExch     : String read fHistExch;
    //Whether to prefill the operator's name too.
    property HistName     : Boolean read fHistName;
    //What this contest sends. Set into the MSG s box when the contest is
    //selected, because the sent exchange is a property of the contest, not
    //something to remember from the last one.
    property SentExch     : String read fSentExch;
    //Per-contest F-key text. key is 'F1'..'F10'; runMode picks the run bank.
    //Empty result means "no contest macro", fall back to the global set.
    function  MacroFor(const key : String; runMode : Boolean) : String;
  end;

  { TMultTracker }

  { Which multipliers are already worked, so a spot can be coloured by whether
    it is still needed.

    Lives here rather than in the contest form because the DX cluster spot
    threads need it too, and a global in this unit avoids fDXCluster having to
    depend on fContest.

    THREADING: the contest form rebuilds this on the main thread while the
    Tel/Web/POTA spot threads read it. One lock guards BOTH the rule set and
    the worked keys, because a contest change swaps them together. The lock is
    only ever held for a few sorted-list lookups - never across a Synchronize,
    which is the deadlock this codebase has already been bitten by once. }
  TMultTracker = class
  private
    fLock   : TRTLCriticalSection;
    fSets   : array[1..3] of TStringList;
    fRules  : TContestRules;      //owned
    fActive : Boolean;
    fMyPfx  : String;
    fMyCont : String;
  public
    constructor Create;
    destructor  Destroy; override;
    //Swap in a new contest. '' or an unreadable file switches tracking off.
    procedure SetRulesFile(const fn : String);
    //My own entity, so callers do not each have to know it. Workability rules
    //("DX only", "EU only") are meaningless without it.
    procedure SetMyStation(const pfx, cont : String);
    //Rebuild the worked-key sets. Call Begin, then AddWorked per QSO, then End.
    procedure BeginRebuild;
    procedure AddWorked(idx : Integer; const key : String);
    procedure EndRebuild;
    //How many NEW multipliers this station would give: 0 none, 1 single,
    //2+ double. N1MM's colour language maps straight onto this.
    function  NeededCount(const ctx : TQsoCtx) : Integer;
    //Snapshot of the rules for callers that need names/scoring. Nil when off.
    function  RulesRef : TContestRules;
    //Contest F-key text, or '' to use the global macro set.
    function  MacroFor(const key : String; runMode : Boolean) : String;
    property  Active : Boolean read fActive;
  end;

var
  //Global, created with the unit. Always non-nil; inactive until a contest
  //with a rule definition is selected.
  MultTracker : TMultTracker;

//Maidenhead locator -> degrees, at the centre of the square. Accepts 2, 4 or
//6 characters; a bare field resolves to the middle of that field.
function GridToLatLon(grid : String; out lat, lon : Double) : Boolean;
//Great circle km between two locators. 0 when either will not parse.
function GridDistanceKm(const a, b : String) : Double;
//CQ WPX prefix of a callsign. cqrlog had no such helper.
function WpxPrefix(call : String) : String;
//Directory contest definitions live in, and the file name for one contest.
function ContestDefFile(const homeDir, contestName : String) : String;

implementation

const
  cContestDir = 'contests';

{ ------------------------------------------------------------------ helpers }

function ContestDefFile(const homeDir, contestName : String) : String;
var
  s : String;
  i : Integer;
begin
  //Contest names come from ContestName.tab and are already ADIF-shaped
  //(upper case, hyphens), but they arrive from a combo the operator can type
  //into, so strip anything that could walk out of the directory.
  s := '';
  for i := 1 to Length(contestName) do
    case contestName[i] of
      'A'..'Z','0'..'9','-','_' : s := s + contestName[i];
      'a'..'z'                  : s := s + UpCase(contestName[i]);
    end;
  if s = '' then
    Result := ''
  else
    Result := homeDir + cContestDir + PathDelim + s + '.contest'
end;

function GridToLatLon(grid : String; out lat, lon : Double) : Boolean;
var
  g : String;
begin
  Result := False;
  lat := 0; lon := 0;
  g := UpperCase(Trim(grid));
  if Length(g) < 2 then exit;
  if not (g[1] in ['A'..'R']) or not (g[2] in ['A'..'R']) then exit;
  //field: 20 deg of longitude, 10 of latitude
  lon := (Ord(g[1]) - Ord('A')) * 20 - 180;
  lat := (Ord(g[2]) - Ord('A')) * 10 - 90;
  if Length(g) >= 4 then
  begin
    if not (g[3] in ['0'..'9']) or not (g[4] in ['0'..'9']) then exit;
    lon := lon + (Ord(g[3]) - Ord('0')) * 2;
    lat := lat + (Ord(g[4]) - Ord('0')) * 1;
    if Length(g) >= 6 then
    begin
      if not (g[5] in ['A'..'X']) or not (g[6] in ['A'..'X']) then exit;
      lon := lon + (Ord(g[5]) - Ord('A')) * (2/24) + (1/24);
      lat := lat + (Ord(g[6]) - Ord('A')) * (1/24) + (0.5/24)
    end
    else
    begin
      //centre of the 2x1 degree square
      lon := lon + 1; lat := lat + 0.5
    end
  end
  else
  begin
    //centre of the 20x10 degree field
    lon := lon + 10; lat := lat + 5
  end;
  Result := True
end;

function GridDistanceKm(const a, b : String) : Double;
const
  R = 6371.0;   //mean earth radius, km
var
  la1,lo1,la2,lo2,dLa,dLo,h : Double;
begin
  Result := 0;
  if not GridToLatLon(a,la1,lo1) then exit;
  if not GridToLatLon(b,la2,lo2) then exit;
  la1 := la1 * Pi/180; lo1 := lo1 * Pi/180;
  la2 := la2 * Pi/180; lo2 := lo2 * Pi/180;
  dLa := la2 - la1;
  dLo := lo2 - lo1;
  h := Sqr(Sin(dLa/2)) + Cos(la1)*Cos(la2)*Sqr(Sin(dLo/2));
  if h > 1 then h := 1;
  Result := 2 * R * ArcSin(Sqrt(h))
end;

function WpxPrefix(call : String) : String;
var
  i,p,lastSlash : Integer;
  a,b,longest,seg,digits : String;
  hasDigit : Boolean;
begin
  //CQ WPX: the prefix is letters+digits up to and including the last digit.
  //A portable call takes the prefix of the "designating" part, which for
  //A/B is whichever segment actually looks like a prefix.
  Result := '';
  call := UpperCase(Trim(call));
  if call = '' then exit;

  lastSlash := 0;
  for i := 1 to Length(call) do
    if call[i] = '/' then lastSlash := i;

  if lastSlash > 0 then
  begin
    a := Copy(call,1,lastSlash-1);
    b := Copy(call,lastSlash+1,Length(call));
    //A bare digit suffix renumbers the home prefix: W1AW/4 -> W4.
    if (Length(b) = 1) and (b[1] in ['0'..'9']) then
    begin
      seg := WpxPrefix(a);
      //replace the trailing digit of the home prefix with the new one
      i := Length(seg);
      while (i > 0) and not (seg[i] in ['0'..'9']) do Dec(i);
      if i > 0 then
        Result := Copy(seg,1,i-1) + b
      else
        Result := seg + b;
      exit
    end;
    //Suffixes that never designate a location.
    if (b = 'P') or (b = 'M') or (b = 'MM') or (b = 'AM') or
       (b = 'QRP') or (b = 'A') then
    begin
      Result := WpxPrefix(a);
      exit
    end;
    //Otherwise the SHORTER segment is the prefix (DL/N8EM and N8EM/DL both
    //mean "N8EM in Germany").
    if Length(b) < Length(a) then longest := b else longest := a;
    call := longest
  end;

  //Walk to the last digit; everything up to and including it is the prefix.
  p := 0;
  hasDigit := False;
  for i := 1 to Length(call) do
    if call[i] in ['0'..'9'] then
    begin
      p := i;
      hasDigit := True
    end;
  if hasDigit then
    Result := Copy(call,1,p)
  else
  begin
    //No digit at all (a country prefix used alone, or junk): WPX appends 0.
    digits := Copy(call,1,2);
    Result := digits + '0'
  end
end;

{ ------------------------------------------------------------- TContestRules }

constructor TContestRules.Create;
begin
  inherited Create;
  fMacros := TStringList.Create;
  fPointsByBand := TStringList.Create;
  fPointsByCont := TStringList.Create;
  fPointsByCtry := TStringList.Create;
  fMultByBand   := TStringList.Create;
  fMultByCont   := TStringList.Create;
  fMultByMode   := TStringList.Create;
  Clear
end;

destructor TContestRules.Destroy;
begin
  fMacros.Free;
  fPointsByBand.Free;
  fPointsByCont.Free;
  fPointsByCtry.Free;
  fMultByBand.Free;
  fMultByCont.Free;
  fMultByMode.Free;
  inherited Destroy
end;

procedure TContestRules.Clear;
var
  i : Integer;
begin
  fLoaded       := False;
  fName         := '';
  fDisplayName  := '';
  fCabrilloName := '';
  fModeCat      := '';
  fDupeType     := dpPerBand;
  fSerialByBand := False;
  fWorkable     := 'ANY';
  fShowWarc     := False;
  fHistExch     := '';
  fHistName     := True;
  fSentExch     := '';
  fMacros.Clear;
  fPointsBase   := 1;
  for i := 1 to 3 do
  begin
    fMultName[i]   := '';
    fMultType[i]   := mtNone;
    fMultScope[i]  := msPerBand;
    fMultScores[i] := True
  end;
  fPointsByBand.Clear;
  fPointsByCont.Clear;
  fPointsByCtry.Clear;
  fMultByBand.Clear;
  fMultByCont.Clear;
  fMultByMode.Clear
end;

function TContestRules.ParseMultType(s : String) : TMultType;
begin
  s := UpperCase(Trim(s));
  if s = 'COUNTRYPREFIX' then Result := mtCountry
  else if s = 'WPXPREFIX'  then Result := mtWPXPrefix
  else if s = 'ZN'         then Result := mtZoneCQ
  else if s = 'ITUZONE'    then Result := mtZoneITU
  else if s = 'GRIDSQUARE' then Result := mtGrid
  else if s = 'GRIDSQUARE4' then Result := mtGrid4
  else if s = 'GRIDFIELD'   then Result := mtGridField
  else if s = 'CONTINENT'  then Result := mtContinent
  else if s = 'CALLSIGN'   then Result := mtCallsign
  else if s = 'STATE'      then Result := mtState
  else if (s = 'SECT') or (s = 'EXCHANGE') or (s = 'MISCTEXT') then
                                Result := mtExchange
  else Result := mtNone
end;

function TContestRules.ParseMultScope(n : Integer) : TMultScope;
begin
  //UDC IsMultPer: 0 none, 1 per band, 2 per mode, 3 per band+mode, 4 once.
  case n of
    1 : Result := msPerBand;
    2 : Result := msPerMode;
    3 : Result := msPerBandMode;
    4 : Result := msOnce;
  else
    Result := msPerBand
  end
end;

procedure TContestRules.LoadPairs(ini : TIniFile; const key : String;
                                  list : TStringList);
var
  raw : String;
  a   : TStringArray;
  i   : Integer;
begin
  list.Clear;
  raw := Trim(ini.ReadString('Contest',key,''));
  if raw = '' then exit;
  //"OH, 5, SM, 5" - alternating key, value, exactly as UDC writes it.
  a := raw.Split([',']);
  i := 0;
  while i + 1 <= High(a) do
  begin
    list.Values[UpperCase(Trim(a[i]))] := Trim(a[i+1]);
    Inc(i,2)
  end
end;

function TContestRules.LoadFromFile(const fn : String) : Boolean;
var
  ini : TIniFile;
  i   : Integer;
  s2  : String;
begin
  Result := False;
  Clear;
  if (fn = '') or (not FileExists(fn)) then exit;
  ini := TIniFile.Create(fn);
  try
    fName         := Trim(ini.ReadString('Contest','Name',''));
    fDisplayName  := Trim(ini.ReadString('Contest','DisplayName',fName));
    fCabrilloName := Trim(ini.ReadString('Contest','CabrilloName',fName));
    fModeCat      := UpperCase(Trim(ini.ReadString('Contest','Mode','CW')));
    fWorkable     := UpperCase(Trim(ini.ReadString('Contest','IsWorkable','ANY')));
    fHistExch     := Trim(ini.ReadString('Contest','CallHistoryExchange',''));
    fHistName     := ini.ReadBool('Contest','CallHistoryName',True);
    fSentExch     := Trim(ini.ReadString('Contest','SentExchange',''));
    for i := 1 to 10 do
    begin
      s2 := Trim(ini.ReadString('Contest','CWF'+IntToStr(i),''));
      if s2 <> '' then fMacros.Values['F'+IntToStr(i)] := s2;
      s2 := Trim(ini.ReadString('Contest','CWRunF'+IntToStr(i),''));
      if s2 <> '' then fMacros.Values['RUNF'+IntToStr(i)] := s2
    end;
    fShowWarc     := ini.ReadBool('Contest','ShowWarcBands',False);

    case ini.ReadInteger('Contest','DupeType',2) of
      1 : fDupeType := dpOncePerContest;
      3 : fDupeType := dpPerBandMode;
      4 : fDupeType := dpNone;
    else  fDupeType := dpPerBand
    end;

    //0 single sequence, 1 per band. UDC's "2" (per band, multi-multi only)
    //collapses to single-op behaviour here because cqrlog is single-op.
    fSerialByBand := ini.ReadInteger('Contest','QsoNumbersByBand',0) = 1;

    for i := 1 to 3 do
    begin
      fMultName[i]  := Trim(ini.ReadString('Contest','Multiplier'+IntToStr(i)+'Name',''));
      fMultType[i]  := ParseMultType(fMultName[i]);
      fMultScope[i] := ParseMultScope(
                         ini.ReadInteger('Contest','IsMult'+IntToStr(i)+'Per',
                           ini.ReadInteger('Contest','IsMultPer',1)));
      //MultMult<N>=0 shows a multiplier without letting it touch the score.
      fMultScores[i]:= ini.ReadInteger('Contest','MultMult'+IntToStr(i),1) <> 0
    end;

    fPointsBase := ini.ReadInteger('Contest','PointsPerContact',1);
    //CQ WPX is the motivating case: low bands are worth double, EXCEPT inside
    //your own country, which is flat 1 point on every band. Without this the
    //band factor would silently double those too.
    fCtryIsFinal := ini.ReadBool('Contest','PointsByCountryIsFinal',False);
    fDistKm      := ini.ReadInteger('Contest','PointsPerDistanceKm',0);
    LoadPairs(ini,'PointsByBand',fPointsByBand);
    LoadPairs(ini,'PointsByContinent',fPointsByCont);
    LoadPairs(ini,'PointsByCountry',fPointsByCtry);
    LoadPairs(ini,'PointsMultByBand',fMultByBand);
    LoadPairs(ini,'PointsMultByContinent',fMultByCont);
    LoadPairs(ini,'PointsMultByMode',fMultByMode);

    fLoaded := fName <> '';
    Result  := fLoaded
  finally
    ini.Free
  end
end;

function TContestRules.LookupNum(list : TStringList; const key : String;
                                 def : Double; out found : Boolean) : Double;
var
  s : String;
begin
  found  := False;
  Result := def;
  if (list.Count = 0) or (key = '') then exit;
  s := list.Values[UpperCase(key)];
  if s = '' then exit;
  //A malformed value must not silently score as 0 - fall back to the default.
  if TryStrToFloat(s,Result) then
    found := True
  else
    Result := def
end;

function TContestRules.IsWorkable(const ctx : TQsoCtx) : Boolean;
var
  w : String;
begin
  Result := True;
  w := fWorkable;
  if (w = '') or (w = 'ANY') then exit;

  if w = 'MYCONTINENTONLY' then
    Result := (ctx.Continent <> '') and (ctx.Continent = ctx.MyContinent)
  else if w = 'NOTMYCONTINENT' then
    Result := (ctx.Continent <> '') and (ctx.Continent <> ctx.MyContinent)
  else if w = 'MYCOUNTRYONLY' then
    Result := (ctx.CountryPfx <> '') and (ctx.CountryPfx = ctx.MyCountryPfx)
  else if w = 'EXCEPTMYCOUNTRY' then
    Result := (ctx.CountryPfx <> '') and (ctx.CountryPfx <> ctx.MyCountryPfx)
  else if (w = 'EUONLY') or (w = 'NAONLY') or (w = 'SAONLY') or
          (w = 'ASIAONLY') or (w = 'AFONLY') or (w = 'OCONLY') then
    Result := ctx.Continent = Copy(w,1,Length(w)-4)
  else
    //Anything else is a comma separated country prefix list.
    Result := (ctx.CountryPfx <> '') and
              (Pos(','+ctx.CountryPfx+',' , ','+StringReplace(w,' ','',[rfReplaceAll])+',') > 0)
end;

function TContestRules.QsoPoints(const ctx : TQsoCtx) : Integer;
var
  pts   : Double;
  f     : Double;
  found : Boolean;
begin
  Result := 0;
  if not fLoaded then exit;
  //A dupe is logged but worth nothing - sponsors want it in the Cabrillo.
  if ctx.IsDupe then exit;
  if not IsWorkable(ctx) then exit;

  //Base value: the most specific list that names this QSO wins, country
  //before continent before band, then the plain scalar.
  pts := LookupNum(fPointsByCtry,ctx.CountryPfx,0,found);
  if found and fCtryIsFinal then
  begin
    //Named country, and this contest says a country match is the last word.
    Result := Round(pts);
    exit
  end;
  if not found then
    pts := LookupNum(fPointsByCont,ctx.Continent,0,found);
  if not found then
    pts := LookupNum(fPointsByBand,ctx.Band,0,found);
  if not found then
    pts := fPointsBase;

  //Distance contests (WW Digi) add a point per N km between grid centres on
  //top of the base point, rather than scaling it.
  if (fDistKm > 0) and (ctx.Grid <> '') and (ctx.MyGrid <> '') then
    pts := pts + Trunc(GridDistanceKm(ctx.MyGrid,ctx.Grid) / fDistKm);

  //Then the multiplicative layers stack on top.
  f := LookupNum(fMultByBand,ctx.Band,1,found);   pts := pts * f;
  f := LookupNum(fMultByCont,ctx.Continent,1,found); pts := pts * f;
  f := LookupNum(fMultByMode,ctx.Mode,1,found);   pts := pts * f;

  Result := Round(pts)
end;

function TContestRules.MacroFor(const key : String; runMode : Boolean) : String;
begin
  Result := '';
  if not fLoaded then exit;
  //A run-bank macro falls back to the S&P text when the contest only defines
  //one set - most contests send the same exchange either way.
  if runMode then
    Result := fMacros.Values['RUN'+UpperCase(key)];
  if Result = '' then
    Result := fMacros.Values[UpperCase(key)]
end;

function TContestRules.MultName(idx : Integer) : String;
begin
  if (idx < 1) or (idx > 3) then Result := '' else Result := fMultName[idx]
end;

function TContestRules.Score(points, m1, m2, m3 : Integer) : Integer;
var
  totalMult : Integer;
begin
  if not fLoaded then
  begin
    Result := points;
    exit
  end;
  totalMult := 0;
  if (fMultType[1] <> mtNone) and fMultScores[1] then Inc(totalMult,m1);
  if (fMultType[2] <> mtNone) and fMultScores[2] then Inc(totalMult,m2);
  if (fMultType[3] <> mtNone) and fMultScores[3] then Inc(totalMult,m3);
  //A contest with no scoring multipliers scores its points, not zero.
  if totalMult = 0 then
    Result := points
  else
    Result := points * totalMult
end;

function TContestRules.MultKey(idx : Integer; const ctx : TQsoCtx) : String;
var
  v : String;
begin
  Result := '';
  if (idx < 1) or (idx > 3) or (not fLoaded) then exit;
  if fMultType[idx] = mtNone then exit;
  //An unworkable station is not a multiplier either, or a zero-point QSO
  //would still inflate the mult count.
  if not IsWorkable(ctx) then exit;

  case fMultType[idx] of
    mtCountry   : v := ctx.CountryPfx;
    mtWPXPrefix : v := WpxPrefix(ctx.Call);
    mtZoneCQ    : v := ctx.ZoneCQ;
    mtZoneITU   : v := ctx.ZoneITU;
    mtGrid      : v := UpperCase(Copy(Trim(ctx.Grid),1,6));
    mtGrid4     : v := UpperCase(Copy(Trim(ctx.Grid),1,4));
    mtGridField : v := UpperCase(Copy(Trim(ctx.Grid),1,2));
    mtContinent : v := ctx.Continent;
    mtCallsign  : v := UpperCase(Trim(ctx.Call));
    mtState     : v := UpperCase(Trim(ctx.State));
    mtExchange  : v := UpperCase(Trim(ctx.ExchRcvd));
  else
    v := ''
  end;
  v := Trim(v);
  if (v = '') or (v = '0') then exit;

  //Bake the scope into the key so the caller counts distinct strings and
  //never has to know whether this mult is per band, per mode or once.
  case fMultScope[idx] of
    msPerBand     : Result := v + '|' + UpperCase(ctx.Band);
    msPerMode     : Result := v + '|' + UpperCase(ctx.Mode);
    msPerBandMode : Result := v + '|' + UpperCase(ctx.Band) + '|' + UpperCase(ctx.Mode);
  else
    Result := v
  end
end;

{ ------------------------------------------------------------- TMultTracker }

constructor TMultTracker.Create;
var
  i : Integer;
begin
  inherited Create;
  InitCriticalSection(fLock);
  fRules := TContestRules.Create;
  for i := 1 to 3 do
  begin
    fSets[i] := TStringList.Create;
    fSets[i].Sorted := True;
    fSets[i].Duplicates := dupIgnore
  end;
  fActive := False
end;

destructor TMultTracker.Destroy;
var
  i : Integer;
begin
  EnterCriticalSection(fLock);
  try
    for i := 1 to 3 do FreeAndNil(fSets[i]);
    FreeAndNil(fRules)
  finally
    LeaveCriticalSection(fLock)
  end;
  DoneCriticalSection(fLock);
  inherited Destroy
end;

procedure TMultTracker.SetRulesFile(const fn : String);
var
  i : Integer;
begin
  EnterCriticalSection(fLock);
  try
    for i := 1 to 3 do fSets[i].Clear;
    //Rules and worked keys change together; a spot thread must never see the
    //new rules against the old contest's keys.
    if fn = '' then
      fRules.Clear
    else
      fRules.LoadFromFile(fn);
    fActive := fRules.Loaded
  finally
    LeaveCriticalSection(fLock)
  end
end;

procedure TMultTracker.BeginRebuild;
var
  i : Integer;
begin
  EnterCriticalSection(fLock);
  try
    for i := 1 to 3 do fSets[i].Clear
  finally
    LeaveCriticalSection(fLock)
  end
end;

procedure TMultTracker.AddWorked(idx : Integer; const key : String);
begin
  if (idx < 1) or (idx > 3) or (key = '') then exit;
  EnterCriticalSection(fLock);
  try
    fSets[idx].Add(key)
  finally
    LeaveCriticalSection(fLock)
  end
end;

procedure TMultTracker.EndRebuild;
begin
  EnterCriticalSection(fLock);
  try
    fActive := fRules.Loaded
  finally
    LeaveCriticalSection(fLock)
  end
end;

function TMultTracker.RulesRef : TContestRules;
begin
  if fActive then Result := fRules else Result := nil
end;

procedure TMultTracker.SetMyStation(const pfx, cont : String);
begin
  EnterCriticalSection(fLock);
  try
    fMyPfx  := UpperCase(Trim(pfx));
    fMyCont := UpperCase(Trim(cont))
  finally
    LeaveCriticalSection(fLock)
  end
end;

function TMultTracker.MacroFor(const key : String; runMode : Boolean) : String;
begin
  Result := '';
  EnterCriticalSection(fLock);
  try
    if fActive then Result := fRules.MacroFor(key,runMode)
  finally
    LeaveCriticalSection(fLock)
  end
end;

function TMultTracker.NeededCount(const ctx : TQsoCtx) : Integer;
var
  i  : Integer;
  mk : String;
  c  : TQsoCtx;
begin
  Result := 0;
  EnterCriticalSection(fLock);
  try
    if not fActive then exit;
    //Fill in my own entity when the caller did not - a spot thread has no
    //business knowing it, and IsWorkable is wrong without it.
    c := ctx;
    if c.MyCountryPfx = '' then c.MyCountryPfx := fMyPfx;
    if c.MyContinent  = '' then c.MyContinent  := fMyCont;
    for i := 1 to 3 do
    begin
      mk := fRules.MultKey(i,c);
      //A multiplier that is displayed but does not score is still worth
      //showing as needed, so this deliberately does not consult MultMult.
      if (mk <> '') and (fSets[i].IndexOf(mk) < 0) then Inc(Result)
    end
  finally
    LeaveCriticalSection(fLock)
  end
end;

initialization
  MultTracker := TMultTracker.Create;

finalization
  FreeAndNil(MultTracker);

end.
