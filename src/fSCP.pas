unit fSCP;

{
  Check window.

  Was a plain list of MASTER.SCP partial matches. N1MM's Check window answers a
  bigger question - "who could this actually be?" - by matching the partial
  call against everything it knows at once: the master file, your own log, the
  contest call history, and calls currently spotted. Colour says where each
  candidate came from, and whether you have already worked it.

  Double-click a candidate to load it into the callsign box, which is the
  point of the window - correcting a busted call should not mean retyping it.
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, lcltype;

type
  //Where a candidate came from. Order matters: it is the display order, most
  //trustworthy first - a station you have actually worked beats a guess from
  //a master file that has not been updated since last season.
  TCheckSource = (csLog, csSpot, csHistory, csMaster);

  { TfrmSCP }

  TfrmSCP = class(TForm)
    lbCheck: TListBox;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure lbCheckDblClick(Sender: TObject);
    procedure lbCheckDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
  private
    procedure AddCandidate(const call : String; src : TCheckSource;
                           seen, wkd : TStringList);
  public
    //Rebuild for a partial callsign. Safe to call on every keystroke.
    procedure UpdateCheck(const partial : String);
    //Kept so the old call sites still compile and still clear the window.
    procedure Clear;
  end;

var
  frmSCP: TfrmSCP;

implementation
{$R *.lfm}

uses dUtils, dData, fNewQSO, fContest, fBandMap;

const
  //Colours by source. Grey means "already worked" and overrides everything -
  //that is the one fact that changes what you do next.
  cColWorked  = clGray;
  cColLog     = clBlack;
  cColSpot    = clBlue;
  cColHistory = clNavy;
  cColMaster  = $00707070;
  //The window refreshes on every keystroke; an unbounded master-file match
  //would make typing feel like wading.
  cMaxItems   = 120;

procedure TfrmSCP.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmSCP)
end;

procedure TfrmSCP.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmSCP)
end;

procedure TfrmSCP.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (key= VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0
  end
end;

procedure TfrmSCP.Clear;
begin
  lbCheck.Items.Clear
end;

procedure TfrmSCP.AddCandidate(const call : String; src : TCheckSource;
                               seen, wkd : TStringList);
var
  s   : String;
  tg : PtrInt;
begin
  s := UpperCase(Trim(call));
  if Length(s) < 3 then exit;
  //One line per callsign: the first (most trustworthy) source wins, so the
  //same call cannot appear four times under four different colours.
  if seen.IndexOf(s) >= 0 then exit;
  if lbCheck.Items.Count >= cMaxItems then exit;
  seen.Add(s);

  //Worked-before comes from a set fetched ONCE per keystroke, not a query per
  //candidate and certainly not a query per repaint.
  tg := Ord(src);
  if wkd.IndexOf(s) >= 0 then tg := tg or (1 shl 8);
  lbCheck.Items.AddObject(s,TObject(tg))
end;

procedure TfrmSCP.lbCheckDrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  src  : TCheckSource;
  call : String;
  tg   : PtrInt;
begin
  if (Index < 0) or (Index >= lbCheck.Items.Count) then exit;
  call := lbCheck.Items[Index];
  tg   := PtrInt(lbCheck.Items.Objects[Index]);
  src  := TCheckSource(tg and $FF);

  lbCheck.Canvas.FillRect(ARect);
  if odSelected in State then
    lbCheck.Canvas.Font.Color := clHighlightText
  else if (tg shr 8) <> 0 then
    //Worked-before greys the entry out whatever its source: it is the one
    //fact that changes what you do next.
    lbCheck.Canvas.Font.Color := cColWorked
  else
    case src of
      csLog     : lbCheck.Canvas.Font.Color := cColLog;
      csSpot    : lbCheck.Canvas.Font.Color := cColSpot;
      csHistory : lbCheck.Canvas.Font.Color := cColHistory;
    else          lbCheck.Canvas.Font.Color := cColMaster
    end;
  lbCheck.Canvas.TextOut(ARect.Left+3,ARect.Top+1,call)
end;

procedure TfrmSCP.lbCheckDblClick(Sender: TObject);
var
  call : String;
begin
  if lbCheck.ItemIndex < 0 then exit;
  call := lbCheck.Items[lbCheck.ItemIndex];
  //The contest window owns the entry field while it is up.
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
  end
end;

procedure TfrmSCP.UpdateCheck(const partial : String);
var
  seen : TStringList;
  tmp  : TStringList;
  wkd  : TStringList;
  s,p  : String;
  i    : Integer;
begin
  p := UpperCase(Trim(partial));
  lbCheck.Items.BeginUpdate;
  seen := TStringList.Create;
  tmp  := TStringList.Create;
  wkd  := TStringList.Create;
  try
    lbCheck.Items.Clear;
    if Length(p) < 3 then exit;

    seen.Sorted := True;
    seen.Duplicates := dupIgnore;
    wkd.Sorted := True;
    wkd.Duplicates := dupIgnore;

    //One query for everything already worked on this band and mode that could
    //match. Membership is then a binary search per candidate.
    if frmContest.Showing then
      dmData.GetWorkedCallsLike(p,
        dmUtils.GetBandFromFreq(frmNewQSO.cmbFreq.Text),
        frmNewQSO.cmbMode.Text,wkd);

    //1. Calls already in the log. Strongest evidence, and it is the source
    //   that knows about the operators you personally keep running into.
    tmp.Clear;
    dmData.GetLogCallsLike(p,tmp);
    for i := 0 to tmp.Count-1 do AddCandidate(tmp[i],csLog,seen,wkd);

    //2. Calls currently on the band map - somebody is on the air with it now.
    tmp.Clear;
    frmBandMap.MatchingCalls(p,tmp);
    for i := 0 to tmp.Count-1 do AddCandidate(tmp[i],csSpot,seen,wkd);

    //3. The contest's call history file.
    if frmContest.Showing then
    begin
      tmp.Clear;
      frmContest.HistoryCallsLike(p,tmp);
      for i := 0 to tmp.Count-1 do AddCandidate(tmp[i],csHistory,seen,wkd)
    end;

    //4. MASTER.SCP, the broad net.
    s := dmData.GetSCPCalls(p);
    tmp.Clear;
    tmp.Delimiter := ' ';
    tmp.DelimitedText := s;
    for i := 0 to tmp.Count-1 do AddCandidate(tmp[i],csMaster,seen,wkd)
  finally
    wkd.Free;
    tmp.Free;
    seen.Free;
    lbCheck.Items.EndUpdate
  end
end;

end.
