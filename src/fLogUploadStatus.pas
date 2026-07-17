unit fLogUploadStatus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs, StrUtils,
  Menus, ActnList, ExtCtrls, uColorMemo, lcltype, dLogUpload, lclintf, lmessages,
  contnrs;

const
  CRLF = #13#10;
type

  { TfrmLogUploadStatus }

  { Parallel upload dispatcher. Historically one TUploadThread ran at a
    time (a single thRunning gate), sharing the datamodule's query objects
    and the form's message slots — five QSOs x four services meant twenty
    HTTP round trips in single file. Now every service gets its own worker:
    the MAIN thread pre-builds a fully-rendered work list per service
    (dmLogUpload.BuildUploadWork — all database access stays here), workers
    do nothing but HTTP + Synchronize, and results (upload_status marks,
    QRZ LOGIDs) are applied back on the main thread. Wall time for an
    upload round is now max-of-services instead of sum-of-services. }
  TfrmLogUploadStatus = class(TForm)
    acLogUploadStatus: TActionList;
    acClearMessages: TAction;
    acFontSettings: TAction;
    dlgFont: TFontDialog;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    mnuStatus: TMenuItem;
    pnlLogStatus: TPanel;
    procedure acClearMessagesExecute(Sender: TObject);
    procedure acFontSettingsExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    mFont      : TFont;
    mStatus    : TColorMemo;
    runningArr : array[TWhereToUpload] of Boolean;
    lineOf     : array[TWhereToUpload] of Integer;  //last status line per service
    roundClean : Boolean;                    //no worker failed this round
    roundDone  : set of TWhereToUpload;      //services completed OK this round
    closeDelay : TTimer;                     //readable pause before auto-close
    procedure LoadFonts;
    procedure UploadDataToOnlineLogs(where : TWhereToUpload; ToAll : Boolean = False);
    procedure UploadThreadDone(Sender : TObject);
    procedure FinishRoundIfIdle;
    procedure CloseDelayTimer(Sender : TObject);
    function  ServiceEnabled(where : TWhereToUpload) : Boolean;
  public
    function  thRunning : Boolean;                    //any worker busy (legacy name)
    function  Running(where : TWhereToUpload) : Boolean;
    //Main-thread status feed (workers reach these via Synchronize): each
    //service owns its last line, so "... OK" updates can never land on
    //another service's message the way a shared last-line did.
    procedure ServiceLine(where : TWhereToUpload; const msg : String; aColor : TColor);
    procedure ServiceLineUpdate(where : TWhereToUpload; const upd : String);

    procedure UploadDataToHamQTH(ToAll : Boolean = False);
    procedure UploadDataToClubLog(ToAll : Boolean = False);
    procedure UploadDataToHrdLog(ToAll : Boolean = False);
    procedure UploadDataToUDPLog(ToAll : Boolean = False);
    procedure UploadDataToQrzLog(ToAll : Boolean = False);
    procedure UploadDataToAll;
  end;

type
  { HTTP-only worker: owns a pre-rendered work list (or a ClubLog bulk
    POST) and never touches the shared database connection. Progress and
    result marks are marshaled to the main thread; each thread carries its
    own scratch fields, so concurrent workers cannot clobber each other's
    messages (the old shared SyncMsg slots could). }
  TUploadThread = class(TThread)
  private
    fWhere    : TWhereToUpload;
    fWork     : TFPObjectList;   //owned; nil/empty when bulk
    fBulk     : TStringList;     //owned; non-nil = ClubLog putlogs.php path
    fBulkNote : String;
    fColor    : TColor;
    fClean    : Boolean;
    //Synchronize scratch — only this thread writes, only during its own
    //Synchronize calls does the main thread read.
    mMsg      : String;
    mUpd      : String;
    mMarkId   : Integer;
    mUpDelId  : Integer;
    mQrzLogId : String;
    mQrzMainId: String;
    procedure SyncLine;
    procedure SyncLineUpdate;
    procedure SyncMark;
    procedure SyncMarkBulk;
    procedure SyncUpDel;
    procedure SyncQrzId;
    procedure Say(const msg : String);
    procedure SayOK;
    procedure ExecuteBulk;
    procedure ExecuteList;
  protected
    procedure Execute; override;
  public
    constructor Create(AWhere : TWhereToUpload; AWork : TFPObjectList;
                       ABulk : TStringList; const ABulkNote : String;
                       AColor : TColor);
    destructor Destroy; override;
    property Where : TWhereToUpload read fWhere;
    property Clean : Boolean read fClean;
  end;



var
  frmLogUploadStatus: TfrmLogUploadStatus;

implementation
{$R *.lfm}

uses dData, dUtils, uMyIni, fNewQSO;

const
  C_IS_NOT_ENABLED = 'Upload to %s is not enabled! Go to Preferences and change settings.';

{ TUploadThread }

constructor TUploadThread.Create(AWhere : TWhereToUpload; AWork : TFPObjectList;
  ABulk : TStringList; const ABulkNote : String; AColor : TColor);
begin
  inherited Create(True);
  fWhere    := AWhere;
  fWork     := AWork;
  fBulk     := ABulk;
  fBulkNote := ABulkNote;
  fColor    := AColor;
  fClean    := True
end;

destructor TUploadThread.Destroy;
begin
  FreeAndNil(fWork);
  FreeAndNil(fBulk);
  inherited Destroy
end;

procedure TUploadThread.SyncLine;
begin
  frmLogUploadStatus.ServiceLine(fWhere,
    dmLogUpload.GetLogName(fWhere) + ': ' + mMsg, fColor)
end;

procedure TUploadThread.SyncLineUpdate;
begin
  frmLogUploadStatus.ServiceLineUpdate(fWhere, mUpd)
end;

procedure TUploadThread.SyncMark;
begin
  dmLogUpload.MarkAsUploaded(dmLogUpload.GetLogName(fWhere), mMarkId)
end;

procedure TUploadThread.SyncMarkBulk;
begin
  dmLogUpload.MarkAsUploaded(C_CLUBLOG)
end;

procedure TUploadThread.SyncUpDel;
begin
  dmLogUpload.MarkAsUpDeleted(mUpDelId)
end;

procedure TUploadThread.SyncQrzId;
begin
  //QRZ LOGID lands in cqrlog_main so a later delete can reference it.
  dmLogUpload.Q2.Close;
  if dmLogUpload.trQ2.Active then dmLogUpload.trQ2.RollBack;
  dmLogUpload.trQ2.StartTransaction;
  dmLogUpload.Q2.SQL.Text := 'update cqrlog_main set qrz_logid='+''''+mQrzLogId+''''+
                             ' where id_cqrlog_main='+mQrzMainId;
  dmLogUpload.Q2.ExecSQL;
  dmLogUpload.trQ2.Commit;
  if dmData.DebugLevel >= 1 then
    Writeln('QRZ LOGID saved: ', mQrzLogId, ' for id_cqrlog_main=', mQrzMainId)
end;

procedure TUploadThread.Say(const msg : String);
begin
  mMsg := msg;
  Synchronize(@SyncLine)
end;

procedure TUploadThread.SayOK;
begin
  mUpd := 'OK';
  Synchronize(@SyncLineUpdate)
end;

procedure TUploadThread.Execute;
begin
  try
    if fBulk <> nil then
      ExecuteBulk
    else
      ExecuteList
  except
    on E : Exception do
    begin
      fClean := False;
      Writeln(E.Message)
    end
  end
end;

procedure TUploadThread.ExecuteBulk;
var
  Response   : String = '';
  ResultCode : Integer = 0;
  ErrorCode  : Integer = 0;
  UpSuccess  : Boolean;
  BulkResp1,
  BulkResp2  : String;
begin
  Say(fBulkNote);
  UpSuccess := dmLogUpload.UploadLogData(fWhere,'BULK',fBulk,Response,ResultCode);

  if dmData.DebugLevel >= 1 then
  begin
    Writeln('-----------');
    Writeln('Response  : ',Response);
    Writeln('ResultCode: ',ResultCode);
    Writeln('-----------')
  end;

  if UpSuccess then
  begin
    BulkResp1 := trim(ExtractWord(1,Response,[':']));
    BulkResp2 := trim(ExtractWord(2,Response,[':']));
    Response  := dmLogUpload.GetResultMessage(fWhere,Response,ResultCode,ErrorCode);
    if (Response='OK') then
      SayOK
    else
      Say(Response)
  end
  else
    ErrorCode := 1;

  if (ErrorCode = 0) then
  begin
    Say(BulkResp1);
    Say(BulkResp2);
    Synchronize(@SyncMarkBulk);
    Say('Done ...')
  end
  else begin
    fClean := False;
    Say('Failed - check settings')
  end
end;

procedure TUploadThread.ExecuteList;
var
  i          : Integer;
  item       : TUploadWorkItem;
  Response   : String = '';
  ResultCode : Integer = 0;
  ErrorCode  : Integer = 0;
  UpSuccess  : Boolean = False;
  AlreadyDel : Boolean;
  qrzLogId   : String;
begin
  for i := 0 to fWork.Count-1 do
  begin
    item := TUploadWorkItem(fWork[i]);
    AlreadyDel := False;

    if (item.Cmd = 'INSERT') then
    begin
      Say('Uploading '+item.Callsign);
      UpSuccess := dmLogUpload.UploadLogData(fWhere,item.Cmd,item.InsData,Response,ResultCode);
      //QRZ hands back a LOGID on insert — stored so a delete can find it.
      if (fWhere = upQrzLog) and UpSuccess and (Pos('LOGID=', Response) > 0) then
      begin
        qrzLogId := Trim(copy(Response, Pos('LOGID=',Response)+6, Length(Response)));
        if Pos('&', qrzLogId) > 0 then
          qrzLogId := copy(qrzLogId, 1, Pos('&',qrzLogId)-1);
        if (qrzLogId <> '') then
        begin
          mQrzLogId  := qrzLogId;
          mQrzMainId := IntToStr(item.MainId);
          Synchronize(@SyncQrzId)
        end
      end
    end
    else if (item.Cmd = 'UPDATE') then
    begin
      if (fWhere = upUDPLog) then
      begin
        UpSuccess  := True;
        Response   := '';
        ResultCode := 200
      end
      else if item.UpdDeleted then
      begin
        Say('Deleting original '+item.OldCallsign);
        if dmData.DebugLevel >= 1 then
        begin
          Writeln('data.Text:');
          Writeln(item.DelData.Text)
        end;
        UpSuccess := dmLogUpload.UploadLogData(fWhere,'DELETE',item.DelData,Response,ResultCode);
        if dmData.DebugLevel >= 1 then
        begin
          Writeln('Response  : ',Response);
          Writeln('ResultCode: ',ResultCode)
        end
      end
      else begin
        Say('Already deleted '+item.OldCallsign);
        UpSuccess  := True;
        Response   := '';
        ResultCode := 200
      end;

      if UpSuccess then
      begin
        Response := dmLogUpload.GetResultMessage(fWhere,Response,ResultCode,ErrorCode);
        if (ErrorCode = 1) then
        begin
          Say('Could not delete original QSO data!');
          Break
        end
        else if (ErrorCode = 2) then
        begin
          Say('Could not delete original QSO data. Reason: ' + Response)
        end
        else if (fWhere <> upUDPLog) then
          SayOK;
        AlreadyDel := True;
        Say('Uploading updated '+item.Callsign);
        UpSuccess := dmLogUpload.UploadLogData(fWhere,item.Cmd,item.InsData,Response,ResultCode)
      end
      else
        Say('Update failed! Check Internet connection')
    end
    else if (item.Cmd = 'DELETE') then
    begin
      Say('Deleting '+item.OldCallsign);
      UpSuccess := dmLogUpload.UploadLogData(fWhere,item.Cmd,item.DelData,Response,ResultCode)
    end;

    if dmData.DebugLevel >= 1 then
    begin
      Writeln('-----------');
      Writeln('Response  : ',Response);
      Writeln('ResultCode: ',ResultCode);
      Writeln('-----------')
    end;

    if UpSuccess then
    begin
      Response := dmLogUpload.GetResultMessage(fWhere,Response,ResultCode,ErrorCode);

      if (Response='OK') or (LeftStr(Response,2)='OK') then
        SayOK
      else
        Say(Response);

      if (ErrorCode = 1) then
      begin
        if AlreadyDel then  //cmd was update, delete succeeded, insert did not
        begin
          mUpDelId := item.ChangeId;
          Synchronize(@SyncUpDel)
        end;
        Break //cannot continue when fatal error
      end
      else begin
        mMarkId := item.ChangeId;
        Synchronize(@SyncMark);
        ErrorCode := 0  //reset duplicate/warning codes so Done... is shown
      end
    end
    else
    begin
      if AlreadyDel then
      begin
        mUpDelId := item.ChangeId;
        Synchronize(@SyncUpDel)
      end;
      Say('Upload failed! Check Internet connection');
      ErrorCode := 1;
      Break
    end;
    Sleep(500) //we don't want to make small DDOS attack to server
  end; //for each work item

  if (ErrorCode = 1) then
  begin
    fClean := False;
    Say('Failed - check settings')
  end
  else
    Say('Done ...')
end;

{ TfrmLogUploadStatus }

function TfrmLogUploadStatus.thRunning : Boolean;
var
  w : TWhereToUpload;
begin
  Result := False;
  for w := Low(TWhereToUpload) to High(TWhereToUpload) do
    if runningArr[w] then exit(True)
end;

function TfrmLogUploadStatus.Running(where : TWhereToUpload) : Boolean;
begin
  Result := runningArr[where]
end;

procedure TfrmLogUploadStatus.ServiceLine(where : TWhereToUpload;
  const msg : String; aColor : TColor);
begin
  if mStatus = nil then exit;
  mStatus.AddLine(msg,aColor,clWhite,0);
  lineOf[where] := mStatus.LastLineNumber;
  if (dmData.DebugLevel >= 1) then
    Writeln('upload[',dmLogUpload.GetLogName(where),']: ',msg)
end;

procedure TfrmLogUploadStatus.ServiceLineUpdate(where : TWhereToUpload;
  const upd : String);
var
  item : String;
  tmp  : LongInt;
  c    : TColor;
begin
  if (mStatus = nil) or (lineOf[where] < 0) then exit;
  mStatus.ReadLine(item,c,c,tmp,lineOf[where]);
  item := item + ' ... ' + upd;
  mStatus.ReplaceLine(item,dmLogUpload.GetLogUploadColor(where),clWhite,0,
                      lineOf[where],0)
end;

function TfrmLogUploadStatus.ServiceEnabled(where : TWhereToUpload) : Boolean;
begin
  Result := True;
  case where of
    upHamQTH  : Result := cqrini.ReadBool('OnlineLog','HaUP',False);
    upClubLog : Result := cqrini.ReadBool('OnlineLog','ClUP',False);
    upHrdLog  : Result := cqrini.ReadBool('OnlineLog','HrUP',False);
    upUDPLog  : Result := cqrini.ReadBool('OnlineLog','UdUP',False);
    upQrzLog  : ;  //no enable flag upstream; credential check gates it
  end //case
end;

procedure TfrmLogUploadStatus.UploadDataToOnlineLogs(where : TWhereToUpload; ToAll : Boolean = False);
var
  work    : TFPObjectList;
  bulk    : TStringList;
  note    : String;
  nothing : Boolean;
  err     : String;
  th      : TUploadThread;
begin
  if runningArr[where] then
  begin
    if not ToAll then
      Application.MessageBox('Previous job is sill running, please try again later.','Info ...',mb_OK+mb_IconInformation);
    exit
  end;
  if not Showing then  //status window has to be visible when working
    Show;

  if not ServiceEnabled(where) then
  begin
    if not ToAll then
      ServiceLine(where, Format(C_IS_NOT_ENABLED,[dmLogUpload.GetLogName(where)]),
                  dmLogUpload.GetLogUploadColor(where));
    exit
  end;
  err := dmLogUpload.CheckUserUploadSettings(where);
  if (err <> '') then
  begin
    ServiceLine(where, err, dmLogUpload.GetLogUploadColor(where));
    exit
  end;

  //All database work happens here on the main thread; the worker gets a
  //finished shopping list and a network connection.
  work := dmLogUpload.BuildUploadWork(where, bulk, note, nothing);
  if nothing then
  begin
    work.Free;
    FreeAndNil(bulk);
    ServiceLine(where, dmLogUpload.GetLogName(where)+': All QSO already uploaded',
                dmLogUpload.GetLogUploadColor(where));
    if not thRunning then
    begin
      Include(roundDone, where);
      FinishRoundIfIdle
    end
    else
      Include(roundDone, where);
    exit
  end;

  if not thRunning then
  begin
    roundClean := True;      //first worker of a fresh round
    roundDone  := []
  end;
  runningArr[where] := True;
  th := TUploadThread.Create(where, work, bulk, note,
                             dmLogUpload.GetLogUploadColor(where));
  th.OnTerminate := @UploadThreadDone;
  th.FreeOnTerminate := True;
  th.Start
end;

procedure TfrmLogUploadStatus.UploadThreadDone(Sender : TObject);
var
  th : TUploadThread;
begin
  th := Sender as TUploadThread;
  runningArr[th.Where] := False;
  if th.Clean then
    Include(roundDone, th.Where)
  else
    roundClean := False;
  FinishRoundIfIdle
end;

procedure TfrmLogUploadStatus.FinishRoundIfIdle;
var
  w        : TWhereToUpload;
  allDone  : Boolean;
begin
  if thRunning then exit;   //workers still out — round not over
  //Collapse the log_changes ledger only when EVERY enabled service has
  //synced cleanly this round. (The old sequential code collapsed whenever
  //qrz.com finished — which force-marked services that never ran, silently
  //dropping their pending uploads. Deliberate behavior fix.)
  allDone := roundClean;
  for w := Low(TWhereToUpload) to High(TWhereToUpload) do
    if ServiceEnabled(w) and (dmLogUpload.CheckUserUploadSettings(w)='')
       and not (w in roundDone) then
      allDone := False;
  if allDone and (upQrzLog in roundDone) then
    dmLogUpload.MarkAsUploadedToAllOnlineLogs;
  //Parallel rounds finish in seconds — an immediate auto-close made the
  //window an unreadable flash (operator report). Give the eyes 5 s.
  if cqrini.ReadBool('OnlineLog','CloseAfterUpload',False) then
    closeDelay.Enabled := True;
  roundDone  := [];
  roundClean := True
end;

procedure TfrmLogUploadStatus.CloseDelayTimer(Sender : TObject);
begin
  closeDelay.Enabled := False;
  if not thRunning then   //a new round may have started during the grace
    Close
end;

procedure TfrmLogUploadStatus.acClearMessagesExecute(Sender: TObject);
var
  w : TWhereToUpload;
begin
  mStatus.RemoveAllLines;
  for w := Low(TWhereToUpload) to High(TWhereToUpload) do
    lineOf[w] := -1
end;

procedure TfrmLogUploadStatus.acFontSettingsExecute(Sender: TObject);
begin
  dlgFont.Font.Name := cqrini.ReadString('LogUploadStatus','FontName','Monospace');
  dlgFont.Font.Size := cqrini.ReadInteger('LogUploadStatus','FontSize',8);
  if dlgFont.Execute then
  begin
    cqrini.WriteString('LogUploadStatus','FontName',dlgFont.Font.Name);
    cqrini.WriteInteger('LogUploadStatus','FontSize',dlgFont.Font.Size);
    LoadFonts
  end
end;

procedure TfrmLogUploadStatus.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(Self);
end;

procedure TfrmLogUploadStatus.FormCloseQuery(Sender: TObject;
  var CanClose: boolean);
begin
  //Workers Synchronize into mStatus — never tear it down under them.
  CanClose := not thRunning;
  if not CanClose then
  begin
    Application.MessageBox('Upload in progress — window will stay open until it finishes.','Info ...',mb_OK+mb_IconInformation);
    exit
  end;
  FreeAndNil(mStatus);
  FreeAndNil(mFont)
end;

procedure TfrmLogUploadStatus.FormCreate(Sender: TObject);
var
  w : TWhereToUpload;
begin
  for w := Low(TWhereToUpload) to High(TWhereToUpload) do
  begin
    runningArr[w] := False;
    lineOf[w]     := -1
  end;
  roundClean := True;
  roundDone  := [];
  closeDelay := TTimer.Create(Self);
  closeDelay.Enabled  := False;
  closeDelay.Interval := 5000;
  closeDelay.OnTimer  := @CloseDelayTimer
end;

procedure TfrmLogUploadStatus.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key= VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0
  end
end;

procedure TfrmLogUploadStatus.FormShow(Sender: TObject);
begin
  if mStatus <> nil then exit;    //re-shown while workers run: keep memo
  mFont              := TFont.Create;
  mStatus            := TColorMemo.Create(pnlLogStatus);
  mStatus.parent     := pnlLogStatus;
  mStatus.AutoScroll := True;
  mStatus.Align      := alClient;
  dmUtils.LoadWindowPos(Self);
  LoadFonts
end;

procedure TfrmLogUploadStatus.LoadFonts;
begin
  dmUtils.LoadFontSettings(self);
  mFont.Name := cqrini.ReadString('LogUploadStatus','FontName','Monospace');
  mFont.Size := cqrini.ReadInteger('LogUploadStatus','FontSize',8);
  mStatus.SetFont(mFont)
end;

procedure TfrmLogUploadStatus.UploadDataToHamQTH(ToAll : Boolean = False);
begin
  UploadDataToOnlineLogs(upHamQTH, ToAll)
end;

procedure TfrmLogUploadStatus.UploadDataToClubLog(ToAll : Boolean = False);
begin
  UploadDataToOnlineLogs(upClubLog, ToAll)
end;

procedure TfrmLogUploadStatus.UploadDataToHrdLog(ToAll : Boolean = False);
begin
  UploadDataToOnlineLogs(upHrdLog, ToAll)
end;

procedure TfrmLogUploadStatus.UploadDataToUDPLog(ToAll : Boolean = False);
begin
  UploadDataToOnlineLogs(upUDPLog, ToAll)
end;

procedure TfrmLogUploadStatus.UploadDataToQrzLog(ToAll : Boolean = False);
begin
  UploadDataToOnlineLogs(upQrzLog, ToAll)
end;

procedure TfrmLogUploadStatus.UploadDataToAll;
begin
  //Genuinely parallel now: five workers, wall time = the slowest service.
  UploadDataToOnlineLogs(upHamQTH, True);
  UploadDataToOnlineLogs(upClubLog, True);
  UploadDataToOnlineLogs(upHrdLog, True);
  UploadDataToOnlineLogs(upUDPLog, True);
  UploadDataToOnlineLogs(upQrzLog, True)
end;

end.
