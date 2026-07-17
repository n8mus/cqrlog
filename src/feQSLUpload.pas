unit feQSLUpload;

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,FileUtil,LResources,Forms,Controls,Graphics,Dialogs,StdCtrls,
  ExtCtrls, httpsend, blcksock, synautil, lcltype, dateutils, synacode;

type

  { TfrmeQSLUpload }

  TfrmeQSLUpload = class(TForm)
    btnPreferences : TButton;
    btnUpload : TButton;
    btnClose : TButton;
    edtQTH : TEdit;
    chkAutoUp : TCheckBox;   //runtime: auto-upload enable (LoTW/eAutoUpload)
    grbWebExport : TGroupBox;
    GroupBox1 : TGroupBox;
    gbProgress : TGroupBox;
    Label1 : TLabel;
    lblInfo: TLabel;
    mStat : TMemo;
    pnlUpload : TPanel;
    rbWebExportAll : TRadioButton;
    rbWebExportNotExported : TRadioButton;
    procedure btnPreferencesClick(Sender : TObject);
    procedure btnUploadClick(Sender : TObject);
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure FormShow(Sender : TObject);
    procedure chkAutoUpChange(Sender: TObject);
    procedure mStatChange(Sender: TObject);
  private
    FileSize     : Int64;
    QSOCount     : Integer;
    function  ExportData(const FileName : String) : Boolean;
    function  HttpPostFile(const URL, FieldName, FileName: string;
                const Data: TStream; const ResultData: TStrings; var err : String): Boolean;
    function  FormatOutput(ResultText : String) : String;

    procedure Upload(const FileName : String);
    procedure SockCallBack(Sender: TObject; Reason:  THookSocketReason; const  Value: string);
  public


end;


var
  frmeQSLUpload : TfrmeQSLUpload;

//Auto-eQSL: call after every QSO save. When LoTW/eAutoUpload is on,
//unsent QSOs (eqsl_qslsdate null) are batched in a quiet period and
//POSTed to eQSL's ImportADIF.cfm in a background thread, then marked
//exactly like the manual upload. eQSL has no delete API: mistakes
//removed after upload need manual cleanup on their site — the quiet
//period is the protection window.
procedure AutoEqslQsoSaved;

implementation
{$R *.lfm}

uses dUtils,dData,uMyIni, fPreferences, uVersion, dLogUpload, dSatellite,
     sqldb, fLogUploadStatus, fMain;

procedure TfrmeQSLUpload.chkAutoUpChange(Sender: TObject);
begin
  cqrini.WriteBool('LoTW','eAutoUpload',chkAutoUp.Checked)
end;

procedure TfrmeQSLUpload.SockCallBack(Sender: TObject; Reason:  THookSocketReason; const  Value: string);
begin
  if Reason = HR_WriteCount then
  begin
    FileSize := FileSize + StrToInt(Value);
    mStat.Lines.Strings[mStat.Lines.Count-2] := 'Size: '+ IntToStr(FileSize);
    mStat.Lines.Strings[mStat.Lines.Count-1] := 'After upload, please wait, eQSL will return some information!';
    Repaint;
    Application.ProcessMessages
  end
end;

function TfrmeQSLUpload.ExportData(const FileName : String) : Boolean;
var
  nr         : integer = 0;
  tmp        : String = '';
  ModeOut,
  SubmodeOut : String;
  f          : TextFile;

begin
  QSOCount := 0;
  Result := True;
  dmData.Q.Close;
  if dmData.trQ.Active then dmData.trQ.Rollback;
  if rbWebExportNotExported.Checked then
    dmData.Q.SQL.Text := 'select id_cqrlog_main,qsodate,time_on,callsign,mode,band,freq,rst_s,rst_r,remarks, satellite, prop_mode, rxfreq '+
                         'from cqrlog_main where eqsl_qslsdate is null'
  else begin
    if dmData.IsFilter then
      dmData.Q.SQL.Text := dmData.qCQRLOG.SQL.Text
    else
      dmData.Q.SQL.Text := 'select id_cqrlog_main,qsodate,time_on,callsign,mode,band,freq,rst_s,rst_r,remarks, satellite, prop_mode, rxfreq '+
                           'from cqrlog_main'
  end;
  dmData.Q.Open;
  dmData.Q.First;
  if dmData.Q.RecordCount = 0 then
  begin
    Application.MessageBox('Nothing to export ... ','Info ...',mb_Ok+mb_IconInformation);
    dmData.Q.Close;
    dmData.trQ.Rollback;
    Result := False;
    exit
  end;
  mStat.Lines.Add('Please wait, exporting QSO for eQSL ...');
  mStat.Lines.Add('Filename: '+FileName);
  Application.ProcessMessages;

  AssignFile(f,FileName);
  try try
    Rewrite(f);
    Writeln(f);
    Writeln(f, 'ADIF export from CQRLOG for Linux version '+dmData.VersionString);
    Writeln(f, 'Copyright (C) ',YearOf(now),' by Petr, OK2CQR and Martin, OK1RR');
    Writeln(f);
    Writeln(f, 'Internet: http://www.cqrlog.com');
    Writeln(f, '<ADIF_VER:5>3.1.0');
    Writeln(f,'<CREATED_TIMESTAMP:15>',FormatDateTime('YYYYMMDD hhmmss',dmUtils.GetDateTime(0)));
    Writeln(f, '<PROGRAMID:6>CQRLOG');
    Writeln(f, '<PROGRAMVERSION:',Length(cVERSION),'>',cVERSION);
    Writeln(f);
    Writeln(f,dmUtils.StringToADIF('<EQSL_USER',cqrini.ReadString('LoTW','eQSLName','')));
    Writeln(f,dmUtils.StringToADIF('<EQSL_PSWD',cqrini.ReadString('LoTW','eQSLPass','')));
    Writeln(f,'<EOH>');
    while not dmData.Q.Eof do
    begin
      lblInfo.Caption := 'Exporting QSO nr. ' + IntToStr(Nr);
      tmp :=  dmData.Q.FieldByName('qsodate').AsString;
      tmp := copy(tmp,1,4) + copy(tmp,6,2) +copy(tmp,9,2);
      tmp := dmUtils.StringToADIF('<QSO_DATE',tmp);
      Writeln(f, tmp);

      tmp := dmData.Q.FieldByName('time_on').AsString;
      tmp := copy(tmp,1,2) + copy(tmp,4,2);
      tmp := dmUtils.StringToADIF('<TIME_ON',tmp);
      Writeln(f, tmp);

      tmp := dmUtils.StringToADIF('<CALL' ,dmUtils.RemoveSpaces(dmData.Q.FieldByName('callsign').AsString));
      Writeln(f,tmp);

      dmUtils.ModeFromCqr(dmData.Q.FieldByName('mode').AsString,0,dmData.DebugLevel >= 1,ModeOut,SubmodeOut);
      tmp := dmUtils.StringToADIF('<MODE',ModeOut);
      Writeln(f,tmp);
      if SubmodeOut<>'' then
                       Begin
                         tmp := dmUtils.StringToADIF('<SUBMODE',SubmodeOut);
                         Writeln(f,tmp);
                       end;

      tmp := dmUtils.StringToADIF('<BAND' ,dmData.Q.FieldByName('band').AsString);
      Writeln(f,tmp);

      tmp := dmUtils.StringToADIF( '<FREQ' ,dmData.Q.FieldByName('freq').AsString);
      Writeln(f,tmp);

      tmp := dmUtils.StringToADIF('<RST_SENT' , dmData.Q.FieldByName('rst_s').AsString);
      Writeln(f,tmp);

      tmp := dmUtils.StringToADIF('<RST_RCVD' ,dmData.Q.FieldByName('rst_r').AsString);
      Writeln(f,tmp);

      if (dmData.Q.FieldByName('prop_mode').AsString <> '') then
      begin
        Writeln(f, dmUtils.StringToADIF('<PROP_MODE' ,dmData.Q.FieldByName('prop_mode').AsString));
        if (dmData.Q.FieldByName('prop_mode').AsString = 'SAT') then
        begin
          tmp := dmSatellite.GetSatMode(dmData.Q.FieldByName('freq').AsString, dmData.Q.FieldByName('rxfreq').AsString);
          if (tmp <> '') then
            Writeln(f, dmUtils.StringToADIF('<SAT_MODE' , tmp));
        end;
      end;

      if (dmData.Q.FieldByName('satellite').AsString <> '') then
        Writeln(f, dmUtils.StringToADIF('<SAT_NAME' ,dmData.Q.FieldByName('satellite').AsString));

      if (dmData.Q.FieldByName('rxfreq').AsString <> '') then
        Writeln(f, dmUtils.StringToADIF('<FREQ_RX' ,dmData.Q.FieldByName('rxfreq').AsString));

      if (dmData.Q.FieldByName('remarks').AsString<>'') and cqrini.ReadBool('LoTW', 'ExpComment', True) then
      begin
        tmp := dmUtils.StringToADIF('<COMMENT' ,dmData.Q.FieldByName('remarks').AsString);
        Writeln(f,tmp);
        tmp := dmUtils.StringToADIF('<QSLMSG' ,dmData.Q.FieldByName('remarks').AsString);
        Writeln(f,tmp)
      end;

      tmp := dmUtils.StringToADIF('<APP_EQSL_QTH_NICKNAME',edtQTH.Text);
      Writeln(f,tmp);

      Writeln(f,'<EOR>');
      Writeln(f);
      if (nr mod 100 = 0) then
      begin
        lblInfo.Repaint;
        Application.ProcessMessages
      end;
      inc(nr);
      Inc(QSOCount);
      dmData.Q.Next
    end
  except
    on E : Exception do
    begin
      mStat.Lines.Add('Export to '+FileName+' failed!'+LineEnding+'Error:'+E.Message);
      Result := False
    end
  end
  finally
    lblInfo.Caption := 'Done ...';
    dmData.Q.Close;
    dmData.trQ.Rollback;
    CloseFile(f)
  end
end;

procedure TfrmeQSLUpload.FormShow(Sender : TObject);
begin
  if chkAutoUp = nil then
  begin
    chkAutoUp := TCheckBox.Create(Self);
    chkAutoUp.Parent  := Self;
    chkAutoUp.Align   := alBottom;
    chkAutoUp.Caption := 'Upload new QSOs to eQSL automatically '+
                         '(background, ~2 min after logging)';
    chkAutoUp.Checked := cqrini.ReadBool('LoTW','eAutoUpload',False);
    chkAutoUp.OnChange := @chkAutoUpChange
  end;
  dmUtils.LoadWindowPos(Self);
  edtQTH.Text := cqrini.ReadString('eQSL','QTH','');
  if dmData.IsFilter then
    begin
      rbWebExportNotExported.Caption:='Export all QSOs which have never been uploaded (bypass filter results)';
      rbWebExportAll.Caption:='Export QSOs from filter result';
      rbWebExportAll.Checked:=true;
    end
   else
    begin
      rbWebExportNotExported.Caption:='Export only QSOs which have never been uploaded';
      rbWebExportAll.Caption:='Export all QSOs in log';
      rbWebExportNotExported.Checked:=true;
    end;

end;

procedure TfrmeQSLUpload.mStatChange(Sender: TObject);
begin
  with mStat do
     begin
      //this does not always scroll to end (why?)
      SelStart := GetTextLen;
      SelLength := 0;
      ScrollBy(0, Lines.Count);
      Refresh;
      //added
      VertScrollBar.Position:=100000;
     end;
end;

procedure TfrmeQSLUpload.FormClose(Sender : TObject;
  var CloseAction : TCloseAction);
begin
  dmUtils.SaveWindowPos(Self);
  cqrini.WriteString('eQSL','QTH',edtQTH.Text)
end;

procedure TfrmeQSLUpload.btnUploadClick(Sender : TObject);
var
  FileName : String;
begin
  btnClose.Font.Style:=[];
  btnClose.Repaint;
  mStat.Clear;
  edtQTH.Text := trim(edtQTH.Text);
  if (edtQTH.Text = '') then
  begin
    Application.MessageBox('QTH field is empty!','Error',mb_ok+mb_IconError);
    edtQTH.SetFocus;
    exit
  end;
  if (cqrini.ReadString('LoTW','eQSLName','') = '') or (cqrini.ReadString('LoTW','eQSLName','')='') then
  begin
    Application.MessageBox('Username or password is empty!','Error',mb_ok+mb_IconError);
    exit
  end;
  FileName := dmData.HomeDir+'eQSL'+PathDelim+FormatDateTime('yyyy-mm-dd_hh-mm-ss',now)+'.adi';
  try
    if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) then
      dmLogUpload.DisableOnlineLogSupport;

    if ExportData(FileName) then
    begin
      if (QSOCount > 1000) then
      begin
        if Application.MessageBox('It seems that you have a lot of QSO to upload. eQSL server can process about '+
                                  '1000 qso per minute, so maybe it will be better to log into eQSL website and '+
                                  'use background upload mode.'+LineEnding+LineEnding+'Do you want to continue?',
                                  'Question ...',mb_YesNo+mb_IconQuestion) = idYes then
          Upload(FileName)
        else
          Close()
      end
      else
        Upload(FileName)
    end

  finally
    btnClose.Font.Style:=[fsBold,fsItalic];
    btnClose.Repaint;
    if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) then
      dmLogUpload.EnableOnlineLogSupport(False)
  end
end;

procedure TfrmeQSLUpload.btnPreferencesClick(Sender : TObject);
begin
  cqrini.WriteInteger('Pref', 'ActPageIdx', 18);  //set lotw tab active. Number may change if preferences page change
  with TfrmPreferences.Create(self) do
  try
    ShowModal
  finally
    Free
  end
end;

function TfrmeQSLUpload.HttpPostFile(const URL, FieldName, FileName: string;
  const Data: TStream; const ResultData: TStrings; var err : String): Boolean;
var
  HTTP: THTTPSend;
  Bound, s: string;
begin
  err := '';
  Bound := IntToHex(Random(MaxInt), 8) + '_Synapse_boundary';
  HTTP := THTTPSend.Create;
  try
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.ProxyUser := cqrini.ReadString('Program','User','');
    HTTP.ProxyPass := cqrini.ReadString('Program','Passwd','');
    HTTP.Sock.OnStatus := @SockCallBack;
    s := '--' + Bound + CRLF;
    s := s + 'content-disposition: form-data; name="' + FieldName + '";';
    s := s + ' filename="' + FileName +'"' + CRLF;
    s := s + 'Content-Type: Application/octet-string' + CRLF + CRLF;
    WriteStrToStream(HTTP.Document, s);
    HTTP.Document.CopyFrom(Data, 0);
    s := CRLF + '--' + Bound + '--' + CRLF;
    WriteStrToStream(HTTP.Document, s);
    HTTP.MimeType := 'multipart/form-data; boundary=' + Bound;
    //eQSL server can handle only 1000QSO per minute
    HTTP.Timeout := 100000*((QSOCount div 1000)+1);
    if dmData.DebugLevel>=1 then
     begin
        Writeln('Timeout:',HTTP.Timeout div 1000, 's');
        Writeln('QSO count:',QSOCount);
     end;
    Result := HTTP.HTTPMethod('POST', URL);
    if Result then
      ResultData.LoadFromStream(HTTP.Document)
    else
      err := IntToStr(HTTP.Sock.LastError)+' - '+HTTP.Sock.LastErrorDesc
  finally
    HTTP.Free
  end
end;


function TfrmeQSLUpload.FormatOutput(ResultText: String) : String;
begin
  ResultText := copy(ResultText,Pos('<BODY>',ResultText)+6,Length(ResultText));
  ResultText := copy(ResultText,1,Pos('</BODY>',ResultText)-1);
  ResultText := StringReplace(ResultText,'<BR>',LineEnding,[rfReplaceAll, rfIgnoreCase]);
  Result     := trim(dmUtils.StripHTML(ResultText))
end;

procedure TfrmeQSLUpload.Upload(const FileName : String);
const
  CR = #$0d;
  LF = #$0a;
  CRLF = CR + LF;
var
  m    : TMemoryStream;
  url : String = '';
  res  : Boolean;
  l    : TStringList;
  suc  : Boolean = False;
  err  : String;
  date : String;
begin
  lblInfo.Caption := '';
  Application.ProcessMessages;
  mStat.Lines.Add('');
  url  := 'https://www.eqsl.cc/qslcard/ImportADIF.cfm';
  mStat.Lines.Add('eQSL server can process about 1000 QSO per minute. If you have ');
  mStat.Lines.Add('a lot of QSO to upload, it will take long time. So please be patient.');
  mStat.Lines.Add('');
  mStat.Lines.Add('Uploading file ...');
  mStat.Lines.Add('Size: ');
  mStat.Lines.Add('After upload, please wait, eQSL will return some information!');
  m := TMemoryStream.Create;
  l := TStringList.Create;
  try
    m.LoadFromFile(FileName);
    lblInfo.Caption := 'Waiting for eQSL server ...';
    Res := HttpPostFile(url,'Filename',FileName,m,l,err);
    if Res then
    begin
      mStat.Lines.Add(FormatOutput(l.Text));
      if dmData.DebugLevel >= 1 then Writeln(l.Text);
      suc := Pos('ERROR',upcase(l.Text)) = 0
    end
    else begin
      mStat.Lines.Add('Error: '+err);
      suc := False
    end;
    mStat.Lines.Add('');
    mStat.Lines.Add('');
    mStat.Lines.Add('');
    Application.ProcessMessages;
    //mStat.VertScrollBar.Position := mStat.VertScrollBar.Range;
    mStat.SelStart := Length(mStat.Text)-1;
    if suc then
    begin
      date := FormatDateTime('yyyy-mm-dd',now);
      dmData.Q1.Close();
      if dmData.trQ1.Active then dmData.trQ1.Rollback;
      dmData.trQ1.StartTransaction;
      dmData.trQ.StartTransaction;
      try
        dmData.Q.Open;
        dmData.Q.First;
        while not dmData.Q.Eof do
        begin
          dmData.Q1.SQL.Text := 'update cqrlog_main set eqsl_qsl_sent = ' + QuotedStr('Y') +
                               ',eqsl_qslsdate = ' + QuotedStr(date) + 'where id_cqrlog_main = '+
                               dmData.Q.FieldByName('id_cqrlog_main').AsString;
          if dmData.DebugLevel>=1 then Writeln(dmData.Q1.SQL.Text);
          dmData.Q1.ExecSQL;
          dmData.Q.Next
        end
      finally
        dmData.Q.Close();
        dmData.trQ1.Commit;
        dmData.trQ.Rollback;
        lblInfo.Caption := 'Upload complete!';
        btnUpload.Enabled:=false;
      end
    end
  finally
    l.Free;
    m.Free
  end
end;


{ ------------------------------------------------------------------ }
{ Auto-eQSL engine (mirror of the auto-LoTW pattern)                  }
{ ------------------------------------------------------------------ }

type
  TAutoEqslThread = class(TThread)
  private
    fFile : String;
    fIds  : TStringList;   //owned
    fOk   : Boolean;
    fTail : String;
    procedure SyncDone;
  protected
    procedure Execute; override;
  public
    constructor Create(const AFile : String; AIds : TStringList);
    destructor Destroy; override;
  end;

  TAutoEqsl = class
  private
    tmr  : TTimer;
    busy : Boolean;
    procedure OnTimer(Sender : TObject);
    procedure StartBatch;
  public
    constructor Create;
    procedure Kick;
    procedure BatchFinished;
  end;

var
  AutoEqsl : TAutoEqsl = nil;

const
  C_AUTOEQSL_FILE = 'autoeqsl.adi';
  C_AUTOEQSL_CAP  = 500;

procedure AutoEqslStatus(const msg : String);
begin
  if dmData.DebugLevel >= 1 then Writeln('AutoEQSL: ',msg);
  if (frmLogUploadStatus <> nil) and frmLogUploadStatus.Showing then
    frmLogUploadStatus.ServiceLineRaw('eQSL: '+msg, clOlive)
end;

constructor TAutoEqslThread.Create(const AFile : String; AIds : TStringList);
begin
  inherited Create(True);
  fFile := AFile;
  fIds  := AIds;
  FreeOnTerminate := True
end;

destructor TAutoEqslThread.Destroy;
begin
  FreeAndNil(fIds);
  inherited Destroy
end;

procedure TAutoEqslThread.Execute;
const
  CRLF = #$0d#$0a;
var
  HTTP  : THTTPSend;
  m     : TMemoryStream;
  l     : TStringList;
  Bound : String;
  s     : String;
begin
  fOk := False;
  HTTP := THTTPSend.Create;
  m    := TMemoryStream.Create;
  l    := TStringList.Create;
  try
    try
      m.LoadFromFile(fFile);
      Bound := IntToHex(Random(MaxInt), 8) + '_Synapse_boundary';
      HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
      HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
      HTTP.ProxyUser := cqrini.ReadString('Program','User','');
      HTTP.ProxyPass := cqrini.ReadString('Program','Passwd','');
      s := '--' + Bound + CRLF;
      s := s + 'content-disposition: form-data; name="Filename";';
      s := s + ' filename="' + ExtractFileName(fFile) +'"' + CRLF;
      s := s + 'Content-Type: Application/octet-string' + CRLF + CRLF;
      WriteStrToStream(HTTP.Document, s);
      HTTP.Document.CopyFrom(m, 0);
      s := CRLF + '--' + Bound + '--' + CRLF;
      WriteStrToStream(HTTP.Document, s);
      HTTP.MimeType := 'multipart/form-data; boundary=' + Bound;
      HTTP.Timeout  := 100000;   //eQSL: ~1000 QSO/min; our cap fits easily
      if HTTP.HTTPMethod('POST','https://www.eqsl.cc/qslcard/ImportADIF.cfm') then
      begin
        l.LoadFromStream(HTTP.Document);
        //Upstream heuristic: any 'ERROR' in the body = failure.
        fOk := Pos('ERROR',UpCase(l.Text)) = 0;
        fTail := Trim(dmUtils.StripHTML(l.Text));
        fTail := Trim(StringReplace(fTail, LineEnding, ' ', [rfReplaceAll]));
        if Length(fTail) > 120 then fTail := copy(fTail,1,120)+'...'
      end
      else
        fTail := 'connection failed: '+HTTP.Sock.LastErrorDesc
    except
      on E : Exception do
        fTail := E.Message
    end
  finally
    l.Free;
    m.Free;
    HTTP.Free
  end;
  Synchronize(@SyncDone)
end;

procedure TAutoEqslThread.SyncDone;
var
  q    : TSQLQuery;
  tr   : TSQLTransaction;
  i    : Integer;
  date : String;
begin
  if fOk then
  begin
    date := FormatDateTime('yyyy-mm-dd',now);
    q  := TSQLQuery.Create(nil);
    tr := TSQLTransaction.Create(nil);
    try
      tr.DataBase   := dmData.MainCon;
      q.DataBase    := dmData.MainCon;
      q.Transaction := tr;
      tr.StartTransaction;
      //status marks must not churn the online-log ledger (see auto-LoTW)
      q.SQL.Text := 'SET @cqr_qsl_mark=1';
      q.ExecSQL;
      for i := 0 to fIds.Count-1 do
      begin
        q.SQL.Text := 'update cqrlog_main set eqsl_qsl_sent='+QuotedStr('Y')+
                      ', eqsl_qslsdate='+QuotedStr(date)+
                      ' where id_cqrlog_main='+fIds[i];
        q.ExecSQL
      end;
      q.SQL.Text := 'SET @cqr_qsl_mark=NULL';
      q.ExecSQL;
      tr.Commit;
      AutoEqslStatus(IntToStr(fIds.Count)+' QSO uploaded ('+fTail+')');
      if frmMain <> nil then
        frmMain.acRefreshExecute(nil)
    finally
      q.Free;
      tr.Free
    end
  end
  else
    AutoEqslStatus('upload FAILED: '+fTail+' - QSOs stay queued for the next batch');
  if AutoEqsl <> nil then
    AutoEqsl.BatchFinished
end;

constructor TAutoEqsl.Create;
begin
  inherited Create;
  tmr := TTimer.Create(nil);
  tmr.Enabled  := False;
  tmr.Interval := 1000 * cqrini.ReadInteger('LoTW','eAutoDelaySec',120);
  tmr.OnTimer  := @OnTimer
end;

procedure TAutoEqsl.Kick;
begin
  tmr.Interval := 1000 * cqrini.ReadInteger('LoTW','eAutoDelaySec',120);
  tmr.Enabled := False;
  tmr.Enabled := True
end;

procedure TAutoEqsl.BatchFinished;
begin
  busy := False
end;

procedure TAutoEqsl.OnTimer(Sender : TObject);
begin
  tmr.Enabled := False;
  if busy then
  begin
    tmr.Enabled := True;
    exit
  end;
  StartBatch
end;

procedure TAutoEqsl.StartBatch;
var
  q        : TSQLQuery;
  tr       : TSQLTransaction;
  f        : TextFile;
  ids      : TStringList;
  FileName : String;
  qthNick  : String;
  tmp,
  ModeOut,
  SubmodeOut : String;
begin
  if (cqrini.ReadString('LoTW','eQSLName','') = '') or
     (cqrini.ReadString('LoTW','eQSLPass','') = '') then
  begin
    AutoEqslStatus('eQSL user/password not set - see Preferences');
    exit
  end;
  qthNick := cqrini.ReadString('eQSL','QTH','');
  if qthNick = '' then
  begin
    AutoEqslStatus('QTH nickname not set - open the eQSL upload window once');
    exit
  end;

  FileName := dmUtils.GetHomeDirectory+'.config/cqrlog/'+C_AUTOEQSL_FILE;
  ids := TStringList.Create;
  q   := TSQLQuery.Create(nil);
  tr  := TSQLTransaction.Create(nil);
  try
    tr.DataBase   := dmData.MainCon;
    q.DataBase    := dmData.MainCon;
    q.Transaction := tr;
    tr.StartTransaction;
    q.SQL.Text := 'select * from cqrlog_main where eqsl_qslsdate is null'+
                  ' order by id_cqrlog_main limit '+IntToStr(C_AUTOEQSL_CAP+1);
    q.Open;
    if q.Eof then exit;

    AssignFile(f,FileName);
    {$i-} ReWrite(f); {$i+}
    if IOResult <> 0 then
    begin
      AutoEqslStatus('cannot write '+FileName);
      exit
    end;
    Writeln(f,'<ADIF_VER:5>3.1.0');
    Writeln(f,'auto-eQSL export from CQRLOG');
    Writeln(f,dmUtils.StringToADIF('<EQSL_USER',cqrini.ReadString('LoTW','eQSLName','')));
    Writeln(f,dmUtils.StringToADIF('<EQSL_PSWD',cqrini.ReadString('LoTW','eQSLPass','')));
    Writeln(f,'<EOH>');
    while not q.Eof do
    begin
      if ids.Count >= C_AUTOEQSL_CAP then
      begin
        CloseFile(f);
        AutoEqslStatus('more than '+IntToStr(C_AUTOEQSL_CAP)+
                       ' unsent QSOs - use the eQSL upload window for the backlog');
        exit
      end;
      tmp := q.FieldByName('qsodate').AsString;
      Writeln(f,dmUtils.StringToADIF('<QSO_DATE',copy(tmp,1,4)+copy(tmp,6,2)+copy(tmp,9,2)));
      tmp := q.FieldByName('time_on').AsString;
      Writeln(f,dmUtils.StringToADIF('<TIME_ON',copy(tmp,1,2)+copy(tmp,4,2)));
      Writeln(f,dmUtils.StringToADIF('<CALL',dmUtils.RemoveSpaces(q.FieldByName('callsign').AsString)));
      dmUtils.ModeFromCqr(q.FieldByName('mode').AsString,0,dmData.DebugLevel >= 1,ModeOut,SubmodeOut);
      Writeln(f,dmUtils.StringToADIF('<MODE',ModeOut));
      if SubmodeOut <> '' then
        Writeln(f,dmUtils.StringToADIF('<SUBMODE',SubmodeOut));
      Writeln(f,dmUtils.StringToADIF('<BAND',q.FieldByName('band').AsString));
      Writeln(f,dmUtils.StringToADIF('<FREQ',q.FieldByName('freq').AsString));
      Writeln(f,dmUtils.StringToADIF('<RST_SENT',q.FieldByName('rst_s').AsString));
      Writeln(f,dmUtils.StringToADIF('<RST_RCVD',q.FieldByName('rst_r').AsString));
      if (q.FieldByName('prop_mode').AsString <> '') then
      begin
        Writeln(f,dmUtils.StringToADIF('<PROP_MODE',q.FieldByName('prop_mode').AsString));
        if (q.FieldByName('prop_mode').AsString = 'SAT') then
        begin
          tmp := dmSatellite.GetSatMode(q.FieldByName('freq').AsString,
                                        q.FieldByName('rxfreq').AsString);
          if (tmp <> '') then
            Writeln(f,dmUtils.StringToADIF('<SAT_MODE',tmp))
        end
      end;
      if (q.FieldByName('satellite').AsString <> '') then
        Writeln(f,dmUtils.StringToADIF('<SAT_NAME',q.FieldByName('satellite').AsString));
      if (q.FieldByName('rxfreq').AsString <> '') then
        Writeln(f,dmUtils.StringToADIF('<FREQ_RX',q.FieldByName('rxfreq').AsString));
      if (q.FieldByName('remarks').AsString <> '') and cqrini.ReadBool('LoTW','ExpComment',True) then
      begin
        Writeln(f,dmUtils.StringToADIF('<COMMENT',q.FieldByName('remarks').AsString));
        Writeln(f,dmUtils.StringToADIF('<QSLMSG',q.FieldByName('remarks').AsString))
      end;
      Writeln(f,dmUtils.StringToADIF('<APP_EQSL_QTH_NICKNAME',qthNick));
      Writeln(f,'<EOR>');
      ids.Add(q.FieldByName('id_cqrlog_main').AsString);
      q.Next
    end;
    CloseFile(f);

    AutoEqslStatus('uploading '+IntToStr(ids.Count)+' QSO ...');
    busy := True;
    TAutoEqslThread.Create(FileName, ids).Start;
    ids := nil
  finally
    q.Close;
    if tr.Active then tr.RollBack;
    q.Free;
    tr.Free;
    ids.Free
  end
end;

procedure AutoEqslQsoSaved;
begin
  if not cqrini.ReadBool('LoTW','eAutoUpload',False) then exit;
  if AutoEqsl = nil then
    AutoEqsl := TAutoEqsl.Create;
  AutoEqsl.Kick
end;


end.

