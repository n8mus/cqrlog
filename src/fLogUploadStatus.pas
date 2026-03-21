unit fLogUploadStatus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  Menus, ActnList, ExtCtrls, uColorMemo, lcltype,  dLogUpload, lclintf, lmessages,
  Regexpr;

type

  { TfrmLogUploadStatus }

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
    mFont     : TFont;
    mStatus   : TColorMemo;
    procedure LoadFonts;
    procedure UploadDataToOnlineLogs(where : TWhereToUpload; ToAll : Boolean = False);
  public
    SyncMsg    : String;
    SyncColor  : TColor;
    SyncUpdate : String;
    thRunning  : Boolean;

    procedure UploadDataToHamQTH(ToAll : Boolean = False);
    procedure UploadDataToClubLog(ToAll : Boolean = False);
    procedure UploadDataToHrdLog(ToAll : Boolean = False);
    procedure UploadDataToQrzLog(ToAll : Boolean = False);
    procedure UploadDataToLoTW;
    procedure UploadDataToAll;
    procedure SyncUploadInformation;
  end; 

type
  TUploadThread = class(TThread)
  private
    function CheckEnabledOnlineLogs : Boolean;
    function GetLogName : String;

    procedure ToMainThread(Message,Update : String);
  protected
    procedure Execute; override;
  public
    WhereToUpload : TWhereToUpload;
    ToAll         : Boolean;
  end;



var
  frmLogUploadStatus: TfrmLogUploadStatus;

implementation
{$R *.lfm}

uses dData, dUtils, uMyIni, fNewQSO, process;

function TUploadThread.CheckEnabledOnlineLogs : Boolean;
const
  C_IS_NOT_ENABLED = 'Upload to %s is not enabled! Go to Preferences and change settings.';
begin
  Result := True;
  case WhereToUpload of
    upHamQTH :  begin
                  if not cqrini.ReadBool('OnlineLog','HaUP',False) then
                  begin
                    if (not ToAll) then
                    begin
                      frmLogUploadStatus.SyncMsg := Format(C_IS_NOT_ENABLED,['HamQTH']);
                      Synchronize(@frmLogUploadStatus.SyncUploadInformation)
                    end;
                    Result := False
                  end
                end;
    upClubLog : begin
                  if not cqrini.ReadBool('OnlineLog','ClUP',False) then
                  begin
                    if (not ToAll) then
                    begin
                      frmLogUploadStatus.SyncMsg := Format(C_IS_NOT_ENABLED,['ClubLog']);
                      Synchronize(@frmLogUploadStatus.SyncUploadInformation)
                    end;
                    Result := False
                  end
                end;
    upHrdLog : begin
                  if not cqrini.ReadBool('OnlineLog','HrUP',False) then
                  begin
                    if (not ToAll) then
                    begin
                      frmLogUploadStatus.SyncMsg := Format(C_IS_NOT_ENABLED,['HRDLog']);
                      Synchronize(@frmLogUploadStatus.SyncUploadInformation)
                    end;
                    Result := False
                  end
                end;
    upQrzLog : begin
                  if not cqrini.ReadBool('OnlineLog','QrzUP',False) then
                  begin
                    if (not ToAll) then
                    begin
                      frmLogUploadStatus.SyncMsg := Format(C_IS_NOT_ENABLED,['qrz.com']);
                      Synchronize(@frmLogUploadStatus.SyncUploadInformation)
                    end;
                    Result := False
                  end
                end
  end //case
end;

procedure TUploadThread.Execute;
const
  C_SEL_UPLOAD_STATUS = 'select * from upload_status where logname=%s';
  C_SEL_LOG_CHANGES   = 'select * from log_changes where id > %d order by id';
var
  data       : TStringList;
  err        : String = '';
  LastId     : Integer = 0;
  Response   : String;
  ResultCode : Integer;
  Command    : String;
  UpSuccess  : Boolean = False;
  ErrorCode  : Integer = 0;
  AlreadyDel : Boolean = False;
  tre        : String;
  qrzLogId   : String;
  cqrlogId   : String;
  ErrPos     : integer = 0;
begin
  data := TStringList.Create;
  try
    frmLogUploadStatus.thRunning := True;
    FreeOnTerminate := True;
    frmLogUploadStatus.SyncMsg    := '';
    frmLogUploadStatus.SyncUpdate := '';
    frmLogUploadStatus.SyncColor  := dmLogUpload.GetLogUploadColor(WhereToUpload);

    if not CheckEnabledOnlineLogs then
      exit;

    err :=  dmLogUpload.CheckUserUploadSettings(WhereToUpload);
    if (err<>'') then
    begin
      frmLogUploadStatus.SyncMsg := err;
      Synchronize(@frmLogUploadStatus.SyncUploadInformation);
      exit
    end;

    if dmLogUpload.trQ.Active then dmLogUpload.trQ.RollBack;
    dmLogUpload.trQ.StartTransaction;
    try try
      dmLogUpload.Q.Close;
      dmLogUpload.Q.SQL.Text := Format(C_SEL_UPLOAD_STATUS,[QuotedStr(GetLogName)]);
      dmLogUpload.Q.Open;
      LastId := dmLogUpload.Q.FieldByName('id_log_changes').AsInteger;

      dmLogUpload.Q.Close;
      dmLogUpload.Q.SQL.Text := Format(C_SEL_LOG_CHANGES,[LastId]);
      dmLogUpload.Q.Open;
      if dmLogUpload.Q.Fields[0].IsNull then
      begin
        ToMainThread('All QSO already uploaded','');
        exit
      end;
      while not dmLogUpload.Q.Eof do
      begin
        AlreadyDel := False;
        Command := dmLogUpload.Q.FieldByName('cmd').AsString;
        if (Command<>'INSERT') and (Command<>'UPDATE') and (Command<>'DELETE') then
        begin
          Writeln('Unknown command:',Command);
          dmLogUpload.Q.Next;
          Continue
        end;
        data.Clear;
        dmLogUpload.PrepareUserInfoHeader(WhereToUpload,data);

        if (Command = 'INSERT') then
        begin
          ToMainThread('Uploading '+dmLogUpload.Q.FieldByName('callsign').AsString,'');
          dmLogUpload.PrepareInsertHeader(WhereToUpload,dmLogUpload.Q.Fields[0].AsInteger,dmLogUpload.Q.FieldByName('id_cqrlog_main').AsInteger,data);
          UpSuccess := dmLogUpload.UploadLogData(WhereToUpload, dmLogUpload.GetUploadUrl(WhereToUpload,Command),data,Response,ResultCode)
        end


        else if (Command = 'UPDATE') then
        begin
          ToMainThread('Deleting original '+dmLogUpload.Q.FieldByName('old_callsign').AsString,'');

          if dmLogUpload.Q.FieldByName('upddeleted').asInteger = 1 then
          begin
            dmLogUpload.PrepareDeleteHeader(WhereToUpload,dmLogUpload.Q.Fields[0].AsInteger,data);

            if dmData.DebugLevel >= 1 then
            begin
              Writeln('data.Text:');
              Writeln(data.Text)
            end;

            UpSuccess := dmLogUpload.UploadLogData(WhereToUpload,dmLogUpload.GetUploadUrl(WhereToUpload,'DELETE'),data,Response,ResultCode);

            if dmData.DebugLevel >= 1 then
            begin
              Writeln('Response  : ',Response);
              Writeln('ResultCode: ',ResultCode)
            end
          end
          else begin
            ToMainThread('Already deleted '+dmLogUpload.Q.FieldByName('old_callsign').AsString,'');
            UpSuccess  := True;
            Response   := '';
            ResultCode := 200
          end;

          if UpSuccess then
          begin
            Response := dmLogUpload.GetResultMessage(WhereToUpload,Response,ResultCode,ErrorCode);
            if (ErrorCode = 1) then
            begin
              ToMainThread('Could not delete original QSO data!','');
              Break
            end
            else if (ErrorCode = 2) then
            begin
              ToMainThread('Could not delete original QSO data. Reason: ' + Response,'');
            end
            else
              ToMainThread('','OK');
            AlreadyDel := True;
            data.Clear;
            dmLogUpload.PrepareUserInfoHeader(WhereToUpload,data);
            ToMainThread('Uploading updated '+dmLogUpload.Q.FieldByName('callsign').AsString,'');
            dmLogUpload.PrepareInsertHeader(WhereToUpload,dmLogUpload.Q.Fields[0].AsInteger,dmLogUpload.Q.FieldByName('id_cqrlog_main').AsInteger,data);
            UpSuccess := dmLogUpload.UploadLogData(WhereToUpload,dmLogUpload.GetUploadUrl(WhereToUpload,Command),data,Response,ResultCode);
          end
          else
            ToMainThread('Update failed! Check Internet connection','')
        end
        else if (Command = 'DELETE') then
        begin
          ToMainThread('Deleting '+dmLogUpload.Q.FieldByName('old_callsign').AsString,'');

          dmLogUpload.PrepareDeleteHeader(WhereToUpload,dmLogUpload.Q.Fields[0].AsInteger,data);
          UpSuccess := dmLogUpload.UploadLogData(WhereToUpload,dmLogUpload.GetUploadUrl(WhereToUpload,Command),data,Response,ResultCode);
          if (ErrorCode = 1) then
          begin
            ToMainThread(Response, '');
          end;
        end;

        if dmData.DebugLevel >= 1 then
        begin
          Writeln('data.Text:');
          Writeln(data.Text);
          Writeln('-----------');
          Writeln('Response  : ',Response);
          Writeln('ResultCode: ',ResultCode);
          Writeln('-----------')
        end;
        if UpSuccess then
        begin
          Response := dmLogUpload.GetResultMessage(WhereToUpload,Response,ResultCode,ErrorCode);
          if (WhereToUpload = upQrzLog) and cqrini.ReadBool('OnlineLog','QrzUP',False) and ((Command = 'INSERT') or (Command = 'UPDATE') or (Command = 'DELETE')) and (ErrorCode = 0) then
          begin
            if (LeftStr(Response,2)='OK') then
            begin
              // Extract just the numeric LOGID from 'OK (12345)'
              qrzLogId := '';
              if Pos('(', Response) > 0 then
                qrzLogId := copy(Response, Pos('(',Response)+1, Pos(')',Response)-Pos('(',Response)-1);
              cqrlogId := dmLogUpload.Q.FieldByName('id_cqrlog_main').AsString;
              // As QSO data is inserted into the db before qrz.com is log uploaded
              // we need to update cqrlog_main and log_changes tables after upload
              if (qrzLogId <> '') and (cqrlogId <> '') then
              begin
                if dmData.trQ.Active then dmData.trQ.RollBack;
                dmData.trQ.StartTransaction;
                dmData.Q.SQL.Text := 'UPDATE cqrlog_main SET `qrz_logid` = '+qrzLogId+' WHERE id_cqrlog_main='+cqrlogId;
                if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
                dmData.Q.ExecSQL;
                dmData.trQ.Commit;
               dmData.Q.SQL.Text := 'UPDATE log_changes SET `qrz_logid` = '+qrzLogId+' WHERE id_cqrlog_main='+cqrlogId;
                if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
                dmData.Q.ExecSQL;
                dmData.trQ.Commit;
                  // Due to triggers being triggered on update of cqrlog_main we need to get rid of this
                  // useless update that only updated the qrz.com logid
                dmData.Q.SQL.Text := 'DELETE FROM log_changes WHERE `cmd` = "UPDATE" ORDER BY `id` DESC LIMIT 1';
                dmData.Q.ExecSQL;
                dmData.trQ.Commit;
                dmData.Q.Close;
                dmData.trQ.Rollback;
              end
            end;
          end;
          if (Response='OK') or (LeftStr(Response,2)='OK') then
            ToMainThread('','OK')
          else
            ToMainThread(Response,'');

          if (ErrorCode = 1) then
          begin
            if AlreadyDel then  //if cmd was update, delete was successful but new insert was not
            begin
              dmLogUpload.MarkAsUpDeleted(dmLogUpload.Q.Fields[0].AsInteger)
            end;
            Break //cannot continue when fatal error
          end
          else begin
            dmLogUpload.MarkAsUploaded(GetLogName,dmLogUpload.Q.FieldByName('id').AsInteger);
            ErrorCode := 0  //reset duplicate/warning codes so Done... is shown
          end
        end
        else begin
          if AlreadyDel then  //if cmd was update, delete was successful but new insert was not
          begin
            dmLogUpload.MarkAsUpDeleted(dmLogUpload.Q.Fields[0].AsInteger)
          end;
          ToMainThread('Upload failed! Check Internet connection','');
          ErrorCode := 1;
          Break
        end;
        Sleep(500); //we don't want to make small DDOS attack to server
        dmLogUpload.Q.Next
      end; //while not dmLogUpload.Q.Eof do

      // Always send Done so next service in timer cycle can start
      if (ErrorCode = 1) then
        ToMainThread('Failed - continuing to next service','')
      else
        ToMainThread('Done ...','')
    finally
      dmLogUpload.Q.Close;
      dmLogUpload.trQ.RollBack
    end;
    Sleep(500)
  except
    on E : Exception do
      Writeln(E.Message)
  end
  finally
    FreeAndNil(data);
    frmLogUploadStatus.thRunning := False
  end
end;

function TUploadThread.GetLogName : String;
begin
  Result := '';
  case WhereToUpload of
    upHamQTH  : Result := C_HAMQTH;
    upClubLog : Result := C_CLUBLOG;
    upHrdLog  : Result := C_HRDLOG;
    upQrzLog  : Result := C_QRZLOG;
  end //case
end;

procedure TUploadThread.ToMainThread(Message,Update : String);
begin
  frmLogUploadStatus.SyncUpdate := Update;
  frmLogUploadStatus.SyncMsg    := GetLogName + ': ' + Message;
  Synchronize(@frmLogUploadStatus.SyncUploadInformation);
  frmLogUploadStatus.SyncUpdate := '';
  frmLogUploadStatus.SyncMsg    := ''
end;

procedure TfrmLogUploadStatus.SyncUploadInformation;
var
  item : String;
  tmp  : LongInt;
  c    : TColor;
begin
  Writeln('SyncUpdate:',SyncUpdate);
  Writeln('SyncMsg   :',SyncMsg);
  if (SyncUpdate<>'') then
  begin
    //cti_vetu(var te:string;var bpi,bpo:Tcolor;var pom:longint;kam:longint):boolean;
    mStatus.ReadLine(item,c,c,tmp,mStatus.LastLineNumber);
    item := item + ' ... ' + SyncUpdate;
    Writeln('Item:',item);
    //prepis_vetu(te:string;bpi,bpo:Tcolor;pom:longint;kam:longint;msk:longint):boolean;
    mStatus.ReplaceLine(item,SyncColor,clWhite,0,mStatus.LastLineNumber,0)
  end
  else
    mStatus.AddLine(SyncMsg,SyncColor,clWhite,0);

  if (Pos('Done ...',SyncMsg)>0) or (Pos('All QSO already uploaded',SyncMsg)>0) then
  begin
    if cqrini.ReadBool('OnlineLog','CloseAfterUpload',False) then
      Close
  end
end;

procedure TfrmLogUploadStatus.acClearMessagesExecute(Sender: TObject);
begin
  mStatus.RemoveAllLines
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
  dmUtils.SaveWindowPos(frmLogUploadStatus);
end;

procedure TfrmLogUploadStatus.FormCloseQuery(Sender: TObject;
  var CanClose: boolean);
begin
  FreeAndNil(mStatus);
  FreeAndNil(mFont)
end;

procedure TfrmLogUploadStatus.FormCreate(Sender: TObject);
begin
  thRunning := False
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
  mFont              := TFont.Create;
  mStatus            := TColorMemo.Create(pnlLogStatus);
  mStatus.parent     := pnlLogStatus;
  mStatus.AutoScroll := True;
  mStatus.Align      := alClient;
  dmUtils.LoadWindowPos(frmLogUploadStatus);
  LoadFonts
end;

procedure TfrmLogUploadStatus.LoadFonts;
begin
  dmUtils.LoadFontSettings(self);
  mFont.Name := cqrini.ReadString('LogUploadStatus','FontName','Monospace');
  mFont.Size := cqrini.ReadInteger('LogUploadStatus','FontSize',8);
  mStatus.SetFont(mFont)
end;

procedure TfrmLogUploadStatus.UploadDataToOnlineLogs(where : TWhereToUpload; ToAll : Boolean = False);
var
  UploadThread : TUploadThread;
begin
  if thRunning then
  begin
    Application.MessageBox('Previous job is sill running, please try again later.','Info ...',mb_OK+mb_IconInformation)
  end
  else begin
    if not Showing then  //status window has to be visible when working
      Show;
    UploadThread := TUploadThread.Create(True);
    UploadThread.WhereToUpload := where;
    UploadThread.ToAll         := ToAll;
    UploadThread.Start
  end
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

procedure TfrmLogUploadStatus.UploadDataToQrzLog(ToAll : Boolean = False);
begin
  UploadDataToOnlineLogs(upQrzLog, ToAll)
end;


procedure TfrmLogUploadStatus.UploadDataToLoTW;
var
  AdifFile  : String;
  TqslCmd   : String;
  TqslLoc   : String;
  AdifText  : String;
  F         : TextFile;
  Proc      : TProcess;
  ExitCode  : Integer;
begin
  if not Showing then Show;
  if not cqrini.ReadBool('LoTW','LoTWUP',False) then
  begin
    mStatus.AddLine('LoTW: not enabled', clRed, clWhite, 0);
    exit
  end;
  TqslLoc  := cqrini.ReadString('LoTW','LoTWLocation','');
  AdifFile := GetTempDir + 'cqrlog_lotw_upload.adi';
  AdifText := dmLogUpload.GetLoTWAdif;
  if AdifText = '' then
  begin
    mStatus.AddLine('LoTW: All QSO already uploaded', clGreen, clWhite, 0);
    exit
  end;
  AssignFile(F, AdifFile);
  Rewrite(F);
  Writeln(F, '<ADIF_VER:5>3.1.0');
  Writeln(F, '<EOH>');
  Write(F, AdifText);
  CloseFile(F);
  mStatus.AddLine('LoTW: Signing and uploading...', clBlue, clWhite, 0);
  TqslCmd := '/usr/bin/tqsl -d -l "' + TqslLoc + '" -u -x -q -a compliant ' + AdifFile;
  Proc := TProcess.Create(nil);
  try
    Proc.CommandLine := TqslCmd;
    Proc.Options := [poWaitOnExit];
    Proc.Execute;
    ExitCode := Proc.ExitCode;
  finally
    Proc.Free
  end;
  if (ExitCode = 0) or (ExitCode = 8) or (ExitCode = 9) then
  begin
    mStatus.AddLine('LoTW: Upload OK', clGreen, clWhite, 0);
    dmLogUpload.MarkLoTWUploaded
  end
  else
    mStatus.AddLine('LoTW: Upload failed (exit=' + IntToStr(ExitCode) + ')', clRed, clWhite, 0);
end;

procedure TfrmLogUploadStatus.UploadDataToAll;
begin
  UploadDataToOnlineLogs(upHamQTH, True);
  UploadDataToOnlineLogs(upClubLog, True);
  UploadDataToOnlineLogs(upHrdLog, True);
  UploadDataToOnlineLogs(upQrzLog, True);
  UploadDataToLoTW
end;

end.

