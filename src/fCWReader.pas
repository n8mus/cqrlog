unit fCWReader;

{
  CW reader: mirrors the Orion SDR console's CW decode pane inside cqrlog.

  The console decodes CW from the radio's audio and datagrams every decoded
  chunk to localhost as plain UTF-8 (CwWindow::appendRx). We just listen and
  display it, so there is no decoder here and no dependency on the console
  being visible - its CW window may sit minimized.

  Those datagrams are plain unicast with no SO_REUSEPORT, so a port can only
  ever feed ONE reader: the console sends the same text to cw/feedPort (2336,
  where Not1MM's decode dock listens) and cw/feedPort2 (2337, ours). If this
  window shows nothing, check that the console's CW window is open at all -
  UDP to a port nobody bound fails silently in both directions.
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Menus, LCLType, blcksock;

type

  { TfrmCWReader }

  TfrmCWReader = class(TForm)
    btnClear: TButton;
    btnBigger: TButton;
    btnSmaller: TButton;
    mReader: TMemo;
    pnlBottom: TPanel;
    sbReader: TStatusBar;
    tmrPoll: TTimer;
    procedure btnBiggerClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnSmallerClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure mReaderDblClick(Sender: TObject);
    procedure tmrPollTimer(Sender: TObject);
  private
    Sock     : TUDPBlockSocket;
    fPort    : String;
    procedure StartListen;
    procedure StopListen;
    procedure Append(const txt : String);
    procedure SetFontSize(size : Integer);
    function  WordAtCursor : String;
    function  LooksLikeCall(const s : String) : Boolean;
  public
    { public declarations }
  end;

var
  frmCWReader : TfrmCWReader;

implementation

{$R *.lfm}

uses dUtils, dData, uMyIni, fNewQSO, fContest;

const
  cMaxChars = 8000;   //keep the pane bounded on long monitoring sessions
  cMinFont  = 8;
  cMaxFont  = 24;

{ TfrmCWReader }

procedure TfrmCWReader.FormCreate(Sender: TObject);
begin
  Sock := nil;
  mReader.Clear;
  //never take focus - the operator is typing in the contest/QSO window and a
  //decode arriving must not move the caret out from under them
  mReader.TabStop := False;
  mReader.ReadOnly := True;
  SetFontSize(cqrini.ReadInteger('CWReader','FontSize',12))
end;

procedure TfrmCWReader.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(Self);
  StartListen
end;

procedure TfrmCWReader.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  StopListen;
  cqrini.WriteInteger('CWReader','FontSize',mReader.Font.Size);
  dmUtils.SaveWindowPos(Self)
end;

procedure TfrmCWReader.StartListen;
begin
  if Sock <> nil then exit;                    //already listening
  fPort := cqrini.ReadString('CWReader','Port','2337');
  Sock := TUDPBlockSocket.Create;
  Sock.EnableReuse(True);
  Sock.Bind('127.0.0.1',fPort);
  if Sock.LastError <> 0 then
  begin
    //Almost always "another process already owns this port" - Not1MM's decode
    //dock on 2336, or a second cqrlog. Say so instead of sitting silent.
    sbReader.SimpleText := 'Could not listen on UDP 127.0.0.1:'+fPort+
                           ' - is another decoder using it?';
    if dmData.DebugLevel>=1 then
      Writeln('CW reader: UDP bind failed on port ',fPort);
    FreeAndNil(Sock);
    exit
  end;
  tmrPoll.Enabled := True;
  sbReader.SimpleText := 'Listening on UDP 127.0.0.1:'+fPort+
                         ' - double click a call to load it';
  if dmData.DebugLevel>=1 then
    Writeln('CW reader listening on UDP 127.0.0.1:',fPort)
end;

procedure TfrmCWReader.StopListen;
begin
  tmrPoll.Enabled := False;
  if Sock <> nil then FreeAndNil(Sock)
end;

procedure TfrmCWReader.tmrPollTimer(Sender: TObject);
var
  Buf : String;
begin
  if Sock = nil then exit;
  tmrPoll.Enabled := False;
  try
    while Sock.WaitingData > 0 do
    begin
      Buf := Sock.RecvPacket(50);
      if Sock.LastError <> 0 then Break;
      if Buf <> '' then Append(Buf)
    end
  finally
    tmrPoll.Enabled := True
  end
end;

procedure TfrmCWReader.Append(const txt : String);
var
  s : String;
begin
  //The console streams chunks, not lines, so append into the last line rather
  //than calling Lines.Add - otherwise every few characters start a new row.
  //Appending through SelText leaves the rest of the document untouched;
  //reassigning .Text on every datagram would rebuild the whole pane and make
  //the operator's double-click selection vanish mid-gesture.
  mReader.SelStart  := MaxInt;
  mReader.SelLength := 0;
  mReader.SelText   := txt;
  mReader.SelStart  := MaxInt;
  //Trimming IS a full rebuild, so only pay for it when the cap is passed.
  if Length(mReader.Text) > cMaxChars then
  begin
    s := mReader.Text;
    mReader.Text := Copy(s,Length(s)-cMaxChars+1,cMaxChars);
    mReader.SelStart := MaxInt
  end
end;

procedure TfrmCWReader.SetFontSize(size : Integer);
begin
  if size < cMinFont then size := cMinFont;
  if size > cMaxFont then size := cMaxFont;
  mReader.Font.Size := size
end;

procedure TfrmCWReader.btnBiggerClick(Sender: TObject);
begin
  SetFontSize(mReader.Font.Size+2)
end;

procedure TfrmCWReader.btnSmallerClick(Sender: TObject);
begin
  SetFontSize(mReader.Font.Size-2)
end;

procedure TfrmCWReader.btnClearClick(Sender: TObject);
begin
  mReader.Clear
end;

function TfrmCWReader.LooksLikeCall(const s : String) : Boolean;
var
  i        : Integer;
  hasDigit,
  hasAlpha : Boolean;
begin
  Result := False;
  if Length(s) < 3 then exit;
  hasDigit := False;
  hasAlpha := False;
  for i := 1 to Length(s) do
    case s[i] of
      '0'..'9' : hasDigit := True;
      'A'..'Z' : hasAlpha := True;
      '/'      : ;                   //portable calls are fine
      else       exit                //anything else and it is not a callsign
    end;
  //A decode full of QRM produces plenty of 3-char junk; requiring both a digit
  //and a letter is the same gate Not1MM's dock uses and it holds up on air.
  Result := hasDigit and hasAlpha
end;

function TfrmCWReader.WordAtCursor : String;
var
  s     : String;
  p,a,b : Integer;
begin
  //A double click has already selected the word under the pointer, so take
  //that when it is there and only fall back to scanning if the widget gave us
  //an empty selection.
  Result := UpperCase(Trim(mReader.SelText));
  if Result <> '' then exit;

  s := mReader.Text;
  if s = '' then exit;
  p := mReader.SelStart + 1;          //SelStart is 0-based, the string is not
  if p < 1 then p := 1;
  if p > Length(s) then p := Length(s);
  if s[p] <= ' ' then exit;           //clicked in whitespace
  a := p;
  while (a > 1) and (s[a-1] > ' ') do Dec(a);
  b := p;
  while (b < Length(s)) and (s[b+1] > ' ') do Inc(b);
  Result := UpperCase(Trim(Copy(s,a,b-a+1)))
end;

procedure TfrmCWReader.mReaderDblClick(Sender: TObject);
var
  call : String;
begin
  call := WordAtCursor;
  if not LooksLikeCall(call) then
  begin
    sbReader.SimpleText := 'Not a callsign: '+call;
    exit
  end;
  //The contest window owns the entry field while it is up; fall back to the
  //New QSO window so the reader is useful outside a contest too.
  if frmContest.Showing then
  begin
    frmContest.edtCall.Text := call;
    frmContest.edtCall.SelStart := Length(call);
    frmContest.edtCall.SetFocus
  end
  else begin
    frmNewQSO.edtCall.Text := call;
    frmNewQSO.edtCall.SelStart := Length(call);
    frmNewQSO.edtCall.SetFocus
  end;
  sbReader.SimpleText := 'Loaded '+call
end;

end.
