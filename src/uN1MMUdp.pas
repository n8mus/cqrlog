unit uN1MMUdp;

{
  N1MM Logger+ compatible UDP broadcasts.

  N1MM publishes what it is doing as XML datagrams on port 12060, and a whole
  ecosystem consumes them. Emitting the same datagrams means cqrlog inherits
  that ecosystem without writing any of it:

    - QSOrder (K3IT) keeps a rolling audio buffer and dumps a per-QSO
      recording when a contactinfo arrives. That is how N1MM users get contest
      audio; there is nothing to build.
    - Contest Online Scoreboard and friends take the dynamicresults document.
    - Waterfall/panadapter apps follow RadioInfo.
    - Log4OM, DXKeeper, Logger32 and others sync from contactinfo.

  BEWARE - three different frequency units in one protocol, which is the
  classic implementation bug:

    contactinfo rxfreq/txfreq   tens of Hz   (14025.19 kHz -> 1402519)
    RadioInfo   Freq/TXFreq     tens of Hz
    contactinfo band            decimal MHz  (14.0)
    spot        frequency       decimal kHz  (7061.2)

  Send-only and fire-and-forget: a logger that stalls because a scoreboard is
  down would be worse than no scoreboard.
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, blcksock, uMyIni;

type
  TN1MMContact = record
    ContestName : String;
    ContestNr   : Integer;
    TimeStamp   : String;   //'YYYY-MM-DD HH:NN:SS'
    MyCall      : String;
    BandMHz     : String;   //decimal MHz, e.g. '3.5'
    RxFreqKHz   : Double;   //kHz; converted to tens of Hz on the wire
    TxFreqKHz   : Double;
    OperatorCall: String;
    Mode        : String;
    Call        : String;
    CountryPfx  : String;
    WpxPrefix   : String;
    StationPfx  : String;
    Continent   : String;
    Snt, SntNr  : String;
    Rcv, RcvNr  : String;
    GridSquare  : String;
    Exchange1   : String;
    Section     : String;
    Comment     : String;
    Qth, Name   : String;
    Power       : String;
    Zone        : String;
    IsMultiplier1,
    IsMultiplier2,
    IsMultiplier3 : Integer;
    Points      : Integer;
    IsRunQSO    : Integer;
    StationName : String;
    ID          : String;   //32 hex chars, the join key for edits/deletes
    SentExchange: String;
  end;

  { TN1MMUdp }

  TN1MMUdp = class
  private
    fSock    : TUDPBlockSocket;
    fDests   : TStringList;   //host:port
    fEnabled : Boolean;
    fSendContacts,
    fSendRadio,
    fSendSpots,
    fSendScore : Boolean;
    procedure Emit(const xml : String);
  public
    constructor Create;
    destructor  Destroy; override;
    //Re-read settings from the ini. Safe to call at any time.
    procedure Configure;
    procedure SendAppInfo(const dbName, contestName, stationName, myCall : String;
                          contestNr : Integer);
    procedure SendContact(const c : TN1MMContact; const root : String = 'contactinfo');
    procedure SendContactDelete(const c : TN1MMContact);
    procedure SendRadioInfo(const stationName, myCall, opCall, mode : String;
                            radioNr : Integer; freqKHz, txFreqKHz : Double;
                            isRunning, isSplit, isTransmitting : Boolean);
    procedure SendSpot(const stationName, dxCall, spotterCall, mode,
                       comment, status, timeStamp : String; freqKHz : Double;
                       adding : Boolean);
    procedure SendScore(const xml : String);
    property Enabled : Boolean read fEnabled;
  end;

//kHz -> the protocol's "tens of Hz" integer. 14025.19 kHz -> 1402519.
function N1MMFreq(kHz : Double) : Int64;
//Minimal XML escaping - a comment field with an ampersand in it must not
//produce a document the other end cannot parse.
function XmlEsc(const s : String) : String;

var
  N1MMUdp : TN1MMUdp;

implementation

function N1MMFreq(kHz : Double) : Int64;
begin
  //kHz * 100 = tens of Hz. Round, never truncate: 7000.009 kHz must not
  //become 7000.00 and drift the reported frequency down.
  Result := Round(kHz * 100)
end;

function XmlEsc(const s : String) : String;
begin
  Result := StringReplace(s,'&','&amp;',[rfReplaceAll]);
  Result := StringReplace(Result,'<','&lt;',[rfReplaceAll]);
  Result := StringReplace(Result,'>','&gt;',[rfReplaceAll]);
  Result := StringReplace(Result,'"','&quot;',[rfReplaceAll]);
  Result := StringReplace(Result,'''','&apos;',[rfReplaceAll])
end;

{ TN1MMUdp }

constructor TN1MMUdp.Create;
begin
  inherited Create;
  fSock  := TUDPBlockSocket.Create;
  fDests := TStringList.Create;
  fEnabled := False
end;

destructor TN1MMUdp.Destroy;
begin
  fDests.Free;
  fSock.Free;
  inherited Destroy
end;

procedure TN1MMUdp.Configure;
var
  raw : String;
  i   : Integer;
begin
  fEnabled      := cqrini.ReadBool('N1MM','Enabled',False);
  fSendContacts := cqrini.ReadBool('N1MM','Contacts',True);
  fSendRadio    := cqrini.ReadBool('N1MM','Radio',True);
  fSendSpots    := cqrini.ReadBool('N1MM','Spots',False);
  fSendScore    := cqrini.ReadBool('N1MM','Score',True);

  //Space separated host:port list, N1MM's own syntax. Broadcast addresses
  //work; multicast does not, exactly as in N1MM.
  raw := Trim(cqrini.ReadString('N1MM','Dest','127.0.0.1:12060'));
  fDests.Clear;
  fDests.Delimiter := ' ';
  fDests.DelimitedText := raw;
  for i := fDests.Count-1 downto 0 do
    if Pos(':',fDests[i]) = 0 then fDests.Delete(i)
end;

procedure TN1MMUdp.Emit(const xml : String);
var
  i    : Integer;
  host,
  port : String;
  p    : Integer;
begin
  if not fEnabled then exit;
  for i := 0 to fDests.Count-1 do
  begin
    p := LastDelimiter(':',fDests[i]);
    if p < 2 then Continue;
    host := Copy(fDests[i],1,p-1);
    port := Copy(fDests[i],p+1,Length(fDests[i]));
    try
      //Broadcast has to be asked for explicitly or a .255 destination is
      //refused by the kernel.
      fSock.EnableBroadcast(True);
      fSock.Connect(host,port);
      fSock.SendString(xml)
    except
      //Fire and forget on purpose: a scoreboard being down must never be
      //able to interrupt logging.
      on E : Exception do ;
    end
  end
end;

procedure TN1MMUdp.SendAppInfo(const dbName, contestName, stationName, myCall : String;
                               contestNr : Integer);
begin
  if not fEnabled then exit;
  Emit('<?xml version="1.0" encoding="utf-8"?>'+LineEnding+
       '<AppInfo>'+LineEnding+
       '<app>CQRLOG</app>'+LineEnding+
       '<dbname>'+XmlEsc(dbName)+'</dbname>'+LineEnding+
       '<contestnr>'+IntToStr(contestNr)+'</contestnr>'+LineEnding+
       '<contestname>'+XmlEsc(contestName)+'</contestname>'+LineEnding+
       '<StationName>'+XmlEsc(stationName)+'</StationName>'+LineEnding+
       '<mycall>'+XmlEsc(myCall)+'</mycall>'+LineEnding+
       '</AppInfo>')
end;

procedure TN1MMUdp.SendContact(const c : TN1MMContact; const root : String);
begin
  if (not fEnabled) or (not fSendContacts) then exit;
  Emit('<?xml version="1.0" encoding="utf-8"?>'+LineEnding+
       '<'+root+'>'+LineEnding+
       '<app>CQRLOG</app>'+LineEnding+
       '<contestname>'+XmlEsc(c.ContestName)+'</contestname>'+LineEnding+
       '<contestnr>'+IntToStr(c.ContestNr)+'</contestnr>'+LineEnding+
       '<timestamp>'+XmlEsc(c.TimeStamp)+'</timestamp>'+LineEnding+
       '<mycall>'+XmlEsc(c.MyCall)+'</mycall>'+LineEnding+
       '<band>'+XmlEsc(c.BandMHz)+'</band>'+LineEnding+
       '<rxfreq>'+IntToStr(N1MMFreq(c.RxFreqKHz))+'</rxfreq>'+LineEnding+
       '<txfreq>'+IntToStr(N1MMFreq(c.TxFreqKHz))+'</txfreq>'+LineEnding+
       '<operator>'+XmlEsc(c.OperatorCall)+'</operator>'+LineEnding+
       '<mode>'+XmlEsc(c.Mode)+'</mode>'+LineEnding+
       '<call>'+XmlEsc(c.Call)+'</call>'+LineEnding+
       '<countryprefix>'+XmlEsc(c.CountryPfx)+'</countryprefix>'+LineEnding+
       '<wpxprefix>'+XmlEsc(c.WpxPrefix)+'</wpxprefix>'+LineEnding+
       '<stationprefix>'+XmlEsc(c.StationPfx)+'</stationprefix>'+LineEnding+
       '<continent>'+XmlEsc(c.Continent)+'</continent>'+LineEnding+
       '<snt>'+XmlEsc(c.Snt)+'</snt>'+LineEnding+
       '<sntnr>'+XmlEsc(c.SntNr)+'</sntnr>'+LineEnding+
       '<rcv>'+XmlEsc(c.Rcv)+'</rcv>'+LineEnding+
       '<rcvnr>'+XmlEsc(c.RcvNr)+'</rcvnr>'+LineEnding+
       '<gridsquare>'+XmlEsc(c.GridSquare)+'</gridsquare>'+LineEnding+
       '<exchange1>'+XmlEsc(c.Exchange1)+'</exchange1>'+LineEnding+
       '<section>'+XmlEsc(c.Section)+'</section>'+LineEnding+
       '<comment>'+XmlEsc(c.Comment)+'</comment>'+LineEnding+
       '<qth>'+XmlEsc(c.Qth)+'</qth>'+LineEnding+
       '<name>'+XmlEsc(c.Name)+'</name>'+LineEnding+
       '<power>'+XmlEsc(c.Power)+'</power>'+LineEnding+
       '<misctext></misctext>'+LineEnding+
       '<zone>'+XmlEsc(c.Zone)+'</zone>'+LineEnding+
       '<prec></prec>'+LineEnding+
       '<ck>0</ck>'+LineEnding+
       '<ismultiplier1>'+IntToStr(c.IsMultiplier1)+'</ismultiplier1>'+LineEnding+
       '<ismultiplier2>'+IntToStr(c.IsMultiplier2)+'</ismultiplier2>'+LineEnding+
       '<ismultiplier3>'+IntToStr(c.IsMultiplier3)+'</ismultiplier3>'+LineEnding+
       '<points>'+IntToStr(c.Points)+'</points>'+LineEnding+
       '<radionr>1</radionr>'+LineEnding+
       '<run1run2>1</run1run2>'+LineEnding+
       '<RoverLocation></RoverLocation>'+LineEnding+
       '<RadioInterfaced>1</RadioInterfaced>'+LineEnding+
       '<NetworkedCompNr>0</NetworkedCompNr>'+LineEnding+
       '<IsOriginal>True</IsOriginal>'+LineEnding+
       '<NetBiosName>'+XmlEsc(c.StationName)+'</NetBiosName>'+LineEnding+
       '<IsRunQSO>'+IntToStr(c.IsRunQSO)+'</IsRunQSO>'+LineEnding+
       '<StationName>'+XmlEsc(c.StationName)+'</StationName>'+LineEnding+
       '<ID>'+XmlEsc(c.ID)+'</ID>'+LineEnding+
       '<IsClaimedQso>1</IsClaimedQso>'+LineEnding+
       '<oldtimestamp>'+XmlEsc(c.TimeStamp)+'</oldtimestamp>'+LineEnding+
       '<oldcall>'+XmlEsc(c.Call)+'</oldcall>'+LineEnding+
       '<SentExchange>'+XmlEsc(c.SentExchange)+'</SentExchange>'+LineEnding+
       '</'+root+'>')
end;

procedure TN1MMUdp.SendContactDelete(const c : TN1MMContact);
begin
  if (not fEnabled) or (not fSendContacts) then exit;
  Emit('<?xml version="1.0" encoding="utf-8"?>'+LineEnding+
       '<contactdelete>'+LineEnding+
       '<app>CQRLOG</app>'+LineEnding+
       '<timestamp>'+XmlEsc(c.TimeStamp)+'</timestamp>'+LineEnding+
       '<mycall>'+XmlEsc(c.MyCall)+'</mycall>'+LineEnding+
       '<band>'+XmlEsc(c.BandMHz)+'</band>'+LineEnding+
       '<call>'+XmlEsc(c.Call)+'</call>'+LineEnding+
       '<contestnr>'+IntToStr(c.ContestNr)+'</contestnr>'+LineEnding+
       '<StationName>'+XmlEsc(c.StationName)+'</StationName>'+LineEnding+
       '<ID>'+XmlEsc(c.ID)+'</ID>'+LineEnding+
       '</contactdelete>')
end;

procedure TN1MMUdp.SendRadioInfo(const stationName, myCall, opCall, mode : String;
                                 radioNr : Integer; freqKHz, txFreqKHz : Double;
                                 isRunning, isSplit, isTransmitting : Boolean);
  function B(v : Boolean) : String;
  begin
    if v then B := 'True' else B := 'False'
  end;
begin
  if (not fEnabled) or (not fSendRadio) then exit;
  Emit('<?xml version="1.0" encoding="utf-8"?>'+LineEnding+
       '<RadioInfo>'+LineEnding+
       '<app>CQRLOG</app>'+LineEnding+
       '<StationName>'+XmlEsc(stationName)+'</StationName>'+LineEnding+
       '<RadioNr>'+IntToStr(radioNr)+'</RadioNr>'+LineEnding+
       '<Freq>'+IntToStr(N1MMFreq(freqKHz))+'</Freq>'+LineEnding+
       '<TXFreq>'+IntToStr(N1MMFreq(txFreqKHz))+'</TXFreq>'+LineEnding+
       '<Mode>'+XmlEsc(mode)+'</Mode>'+LineEnding+
       '<OpCall>'+XmlEsc(opCall)+'</OpCall>'+LineEnding+
       '<IsRunning>'+B(isRunning)+'</IsRunning>'+LineEnding+
       '<FocusEntry>0</FocusEntry>'+LineEnding+
       '<Antenna>0</Antenna>'+LineEnding+
       '<Rotors></Rotors>'+LineEnding+
       '<FocusRadioNr>'+IntToStr(radioNr)+'</FocusRadioNr>'+LineEnding+
       '<IsStereo>False</IsStereo>'+LineEnding+
       '<IsSplit>'+B(isSplit)+'</IsSplit>'+LineEnding+
       '<ActiveRadioNr>'+IntToStr(radioNr)+'</ActiveRadioNr>'+LineEnding+
       '<IsTransmitting>'+B(isTransmitting)+'</IsTransmitting>'+LineEnding+
       '<FunctionKeyCaption></FunctionKeyCaption>'+LineEnding+
       '<RadioName>CQRLOG</RadioName>'+LineEnding+
       '<AuxAntSelected>-1</AuxAntSelected>'+LineEnding+
       '<AuxAntSelectedName></AuxAntSelectedName>'+LineEnding+
       '<IsConnected>True</IsConnected>'+LineEnding+
       '<mycall>'+XmlEsc(myCall)+'</mycall>'+LineEnding+
       '</RadioInfo>')
end;

procedure TN1MMUdp.SendSpot(const stationName, dxCall, spotterCall, mode,
                            comment, status, timeStamp : String; freqKHz : Double;
                            adding : Boolean);
var
  act : String;
begin
  if (not fEnabled) or (not fSendSpots) then exit;
  if adding then act := 'add' else act := 'delete';
  //Spot frequency is decimal kHz here, NOT the tens-of-Hz integer the
  //contact and radio datagrams use.
  Emit('<?xml version="1.0" encoding="utf-8"?>'+LineEnding+
       '<spot>'+LineEnding+
       '<app>CQRLOG</app>'+LineEnding+
       '<StationName>'+XmlEsc(stationName)+'</StationName>'+LineEnding+
       '<dxcall>'+XmlEsc(dxCall)+'</dxcall>'+LineEnding+
       '<frequency>'+FormatFloat('0.0',freqKHz)+'</frequency>'+LineEnding+
       '<spottercall>'+XmlEsc(spotterCall)+'</spottercall>'+LineEnding+
       '<timestamp>'+XmlEsc(timeStamp)+'</timestamp>'+LineEnding+
       '<action>'+act+'</action>'+LineEnding+
       '<mode>'+XmlEsc(mode)+'</mode>'+LineEnding+
       '<comment>'+XmlEsc(comment)+'</comment>'+LineEnding+
       '<status>'+XmlEsc(status)+'</status>'+LineEnding+
       '<statuslist>'+XmlEsc(status)+'</statuslist>'+LineEnding+
       '</spot>')
end;

procedure TN1MMUdp.SendScore(const xml : String);
begin
  if (not fEnabled) or (not fSendScore) then exit;
  Emit(xml)
end;

initialization
  N1MMUdp := TN1MMUdp.Create;

finalization
  FreeAndNil(N1MMUdp);

end.
