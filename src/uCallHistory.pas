unit uCallHistory;

{
  Call history: what you already know about a station before he sends it.

  In CWT, NAQP, Sweepstakes and the QSO parties most of the exchange is fixed
  per operator - his name, his state, his member number. A call history file
  lets the exchange boxes fill themselves the moment the callsign is complete,
  so the operator only types what actually differs. It is the single biggest
  typing saver in N1MM and cqrlog had nothing like it.

  Format is N1MM's, so the published files work unmodified:

      # comment
      !!Order!!,Call,Exch1,Name,Loc1,Sect,UserText
      G2CWO,20000,Club,G,G,CWops

  Fields default to N1MM's column order and can be redefined by !!Order!! at
  any point in the file, applying to every line that follows.

  IMPORTANT - the duplicate column trap: the published CWops file names TWO
  columns "Misc", so a naive name-keyed parser silently drops the member
  number and lands the state in the exchange field. Here a repeated column
  name binds to its FIRST position and later ones are ignored, and the caller
  can see what happened through DuplicateColumns.
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils;

type
  TCallHistRec = record
    Call, Name, Loc1, Loc2, Sect, State, CK, BirthDate,
    Exch1, Misc, Power, CqZone, ITUZone, UserText : String;
  end;

  { TCallHistory }

  TCallHistory = class
  private
    fCalls    : TStringList;         //sorted, Objects[] = index into fRecs
    fRecs     : array of TCallHistRec;
    fOrder    : TStringList;         //current column order
    fDupCols  : String;
    fFileName : String;
    procedure SetDefaultOrder;
    procedure ApplyOrderLine(const line : String);
    procedure ParseDataLine(const line : String);
    procedure StoreField(var rec : TCallHistRec; const col, val : String);
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Clear;
    function  LoadFromFile(const fn : String) : Boolean;
    function  Lookup(const call : String; out rec : TCallHistRec) : Boolean;
    //Expand a template like "%NAME% %STATE%" against a record. Unknown
    //placeholders expand to nothing rather than being left on screen.
    function  Expand(const tmpl : String; const rec : TCallHistRec) : String;
    //Calls containing this fragment, capped - the Check window asks on every
    //keystroke and a two-character fragment matches most of the file.
    procedure MatchingCalls(const partial : String; l : TStrings; max : Integer);
    function  Count : Integer;
    property  FileName : String read fFileName;
    //Column names that appeared more than once, '' when none. Worth showing:
    //it is almost always a broken published file rather than a broken parser.
    property  DuplicateColumns : String read fDupCols;
  end;

//Where a contest's call history file lives.
function CallHistoryFile(const homeDir, contestName : String) : String;

implementation

const
  cHistDir = 'callhistory';

function CallHistoryFile(const homeDir, contestName : String) : String;
var
  s : String;
  i : Integer;
begin
  //Same sanitising as the contest definitions: the name comes from a combo
  //the operator can type into, so it must not be able to walk out of the dir.
  s := '';
  for i := 1 to Length(contestName) do
    case contestName[i] of
      'A'..'Z','0'..'9','-','_' : s := s + contestName[i];
      'a'..'z'                  : s := s + UpCase(contestName[i]);
    end;
  if s = '' then
    Result := ''
  else
    Result := homeDir + cHistDir + PathDelim + s + '.txt'
end;

{ TCallHistory }

constructor TCallHistory.Create;
begin
  inherited Create;
  fCalls := TStringList.Create;
  fCalls.Sorted := True;
  fCalls.Duplicates := dupIgnore;
  fOrder := TStringList.Create;
  Clear
end;

destructor TCallHistory.Destroy;
begin
  fCalls.Free;
  fOrder.Free;
  inherited Destroy
end;

procedure TCallHistory.Clear;
begin
  fCalls.Clear;
  SetLength(fRecs,0);
  fDupCols  := '';
  fFileName := '';
  SetDefaultOrder
end;

function TCallHistory.Count : Integer;
begin
  Result := fCalls.Count
end;

procedure TCallHistory.SetDefaultOrder;
begin
  fOrder.Clear;
  fOrder.CommaText := 'CALL,NAME,LOC1,LOC2,SECT,STATE,CK,BIRTHDATE,EXCH1,'+
                      'MISC,POWER,CQZONE,ITUZONE,USERTEXT'
end;

procedure TCallHistory.ApplyOrderLine(const line : String);
var
  a : TStringArray;
  i : Integer;
  c : String;
begin
  fOrder.Clear;
  a := line.Split([',']);
  for i := 0 to High(a) do
  begin
    c := UpperCase(Trim(a[i]));
    if c = '' then Continue;
    if c = '!!ORDER!!' then Continue;
    //A repeated name binds to its first position; later ones become dead
    //columns rather than overwriting the earlier field.
    if fOrder.IndexOf(c) >= 0 then
    begin
      if Pos(c,fDupCols) = 0 then
        fDupCols := fDupCols + IfThen(fDupCols='','',', ') + c;
      fOrder.Add('')          //placeholder keeps positions aligned
    end
    else
      fOrder.Add(c)
  end
end;

procedure TCallHistory.StoreField(var rec : TCallHistRec; const col, val : String);
begin
  if (col = '') or (val = '') then exit;
  case col of
    'CALL'      : rec.Call := val;
    'NAME'      : rec.Name := val;
    'LOC1'      : rec.Loc1 := val;
    'LOC2'      : rec.Loc2 := val;
    'SECT'      : rec.Sect := val;
    'STATE'     : rec.State := val;
    'CK'        : rec.CK := val;
    'BIRTHDATE' : rec.BirthDate := val;
    'EXCH1'     : rec.Exch1 := val;
    'MISC'      : rec.Misc := val;
    'POWER'     : rec.Power := val;
    'CQZONE'    : rec.CqZone := val;
    'ITUZONE'   : rec.ITUZone := val;
    'USERTEXT'  : rec.UserText := val;
    //LASTUPDATENOTE and anything unrecognised is deliberately dropped
  end
end;

procedure TCallHistory.ParseDataLine(const line : String);
var
  a   : TStringArray;
  i,n : Integer;
  rec : TCallHistRec;
begin
  rec := Default(TCallHistRec);
  //Semicolon is the other delimiter N1MM accepts.
  if (Pos(';',line) > 0) and (Pos(',',line) = 0) then
    a := line.Split([';'])
  else
    a := line.Split([',']);
  for i := 0 to High(a) do
    if i < fOrder.Count then
      StoreField(rec,fOrder[i],Trim(a[i]));

  rec.Call := UpperCase(Trim(rec.Call));
  if rec.Call = '' then exit;

  //The FIRST entry for a call wins. Checked explicitly rather than relying on
  //dupIgnore, which still rebinds the object and let the last row through -
  //so an appended correction quietly shadowed the real row.
  if fCalls.IndexOf(rec.Call) >= 0 then exit;

  n := Length(fRecs);
  SetLength(fRecs,n+1);
  fRecs[n] := rec;
  fCalls.AddObject(rec.Call,TObject(PtrInt(n)))
end;

function TCallHistory.LoadFromFile(const fn : String) : Boolean;
var
  f : TStringList;
  i : Integer;
  s : String;
begin
  Result := False;
  Clear;
  if (fn = '') or (not FileExists(fn)) then exit;
  f := TStringList.Create;
  try
    try
      f.LoadFromFile(fn)
    except
      exit
    end;
    for i := 0 to f.Count-1 do
    begin
      s := Trim(f[i]);
      if s = '' then Continue;
      if Copy(s,1,2) = '!!' then
      begin
        if Pos('!!ORDER!!',UpperCase(s)) = 1 then ApplyOrderLine(s);
        Continue
      end;
      if s[1] = '#' then Continue;        //comment
      ParseDataLine(s)
    end;
    fFileName := fn;
    Result := fCalls.Count > 0
  finally
    f.Free
  end
end;

function TCallHistory.Lookup(const call : String; out rec : TCallHistRec) : Boolean;
var
  i : Integer;
begin
  rec := Default(TCallHistRec);
  Result := False;
  if fCalls.Count = 0 then exit;
  i := fCalls.IndexOf(UpperCase(Trim(call)));
  if i < 0 then exit;
  rec := fRecs[PtrInt(fCalls.Objects[i])];
  Result := True
end;

procedure TCallHistory.MatchingCalls(const partial : String; l : TStrings; max : Integer);
var
  i : Integer;
  p : String;
begin
  p := UpperCase(Trim(partial));
  if Length(p) < 3 then exit;
  for i := 0 to fCalls.Count-1 do
  begin
    if Pos(p,fCalls[i]) > 0 then
    begin
      l.Add(fCalls[i]);
      if l.Count >= max then exit
    end
  end
end;

function TCallHistory.Expand(const tmpl : String; const rec : TCallHistRec) : String;
  procedure Sub(const key, val : String);
  begin
    Result := StringReplace(Result,'%'+key+'%',val,[rfReplaceAll,rfIgnoreCase])
  end;
begin
  Result := tmpl;
  Sub('CALL',rec.Call);
  Sub('NAME',rec.Name);
  Sub('LOC1',rec.Loc1);
  Sub('LOC2',rec.Loc2);
  Sub('SECT',rec.Sect);
  Sub('STATE',rec.State);
  Sub('CK',rec.CK);
  Sub('EXCH1',rec.Exch1);
  Sub('MISC',rec.Misc);
  Sub('POWER',rec.Power);
  Sub('CQZONE',rec.CqZone);
  Sub('ITUZONE',rec.ITUZone);
  Sub('USERTEXT',rec.UserText);
  //Anything still wrapped in %% is a placeholder we do not know. Drop it
  //rather than transmitting "%NOSUCH%" on the air.
  while (Pos('%',Result) > 0) and (PosEx('%',Result,Pos('%',Result)+1) > 0) do
    Delete(Result,Pos('%',Result),
           PosEx('%',Result,Pos('%',Result)+1) - Pos('%',Result) + 1);
  //Collapse the gaps an empty field leaves behind, so "%NAME% %STATE%" with
  //no state does not send a trailing space.
  while Pos('  ',Result) > 0 do
    Result := StringReplace(Result,'  ',' ',[rfReplaceAll]);
  Result := Trim(Result)
end;

end.
