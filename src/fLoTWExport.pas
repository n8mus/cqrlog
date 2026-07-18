unit fLoTWExport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ExtCtrls, lcltype, iniFiles, process, httpsend, ssl_openssl, synautil,
  blcksock, ssl_openssl_lib, dateutils, synacode;

type

  { TfrmLoTWExport }

  TfrmLoTWExport = class(TForm)
    btnClose: TButton;
    btnClose1: TButton;
    btnExportSign: TButton;
    btnFileBrowse: TButton;
    btnFileExport: TButton;
    btnHelp: TButton;
    btnHelp1: TButton;
    btnUpload: TButton;
    chkFileMarkAfterExport: TCheckBox;
    edtTqsl: TEdit;
    edtFileName: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    grbWebExport: TGroupBox;
    grbTqsl: TGroupBox;
    GroupBox6: TGroupBox;
    lblInfo: TLabel;
    lblExpToFile: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    lblLotwUpNull: TLabel;
    mStat: TMemo;
    pnlButtons1: TPanel;
    pgLoTWExport: TPageControl;
    pnlButtons: TPanel;
    pnlUpload: TPanel;
    rbFileExportAll: TRadioButton;
    rbWebExportAll: TRadioButton;
    rbFileExportNotExported: TRadioButton;
    dlgSave: TSaveDialog;
    rbWebExportNotExported: TRadioButton;
    tabLocalFile: TTabSheet;
    tabUpload: TTabSheet;
    tmrLoTW: TTimer;
    chkAutoUp : TCheckBox;   //runtime: auto-upload enable (LoTW/AutoUpload)
    procedure FormCreate(Sender: TObject);
    procedure chkAutoUpChange(Sender: TObject);
    procedure btnExportSignClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormShow(Sender: TObject);
    procedure btnFileExportClick(Sender: TObject);
    procedure btnFileBrowseClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure btnUploadClick(Sender: TObject);
    procedure mStatChange(Sender: TObject);
    procedure tabLocalFileEnter(Sender: TObject);
    procedure tmrLoTWTimer(Sender: TObject);
  private
    FileName  : String;
    MarkAfter : Boolean;
    AProcess  : TProcess;
    FileSize : Int64;

    function ExportToAdif : Word;
    procedure SockCallBack (Sender: TObject; Reason:  THookSocketReason; const  Value: string);
  public
    Running : Integer;
    command : String;

  end;

var
  frmLoTWExport: TfrmLoTWExport;

//Auto-LoTW (GridTracker-style): call after every QSO save. When
//LoTW/AutoUpload is enabled, unsigned QSOs are batched (a quiet period
//after the last save), exported, signed and uploaded with the operator's
//existing tqsl template plus -u, in a background thread; tqsl's own
//duplicate detection makes retries harmless. Successful batches are
//marked lotw_qsls='Y' exactly like the manual export.
procedure AutoLotwQsoSaved;

implementation
{$R *.lfm}

{ TfrmLoTWExport }

uses dData, dUtils, uMyIni, dLogUpload, sqldb, fLogUploadStatus, StrUtils, fMain;

procedure TfrmLoTWExport.btnFileBrowseClick(Sender: TObject);
begin
  if dlgSave.Execute then
  begin
    edtFileName.Text := dlgSave.FileName
  end
end;

procedure TfrmLoTWExport.btnHelpClick(Sender: TObject);
begin
  ShowHelp
end;

procedure TfrmLoTWExport.btnUploadClick(Sender: TObject);
const
  UPLOAD_URL = 'https://LoTW.arrl.org/lotwuser/upload?login=%s&password=%s';
  CR = #$0d;
  LF = #$0a;
  CRLF = CR + LF;
var
  http : THTTPSend;
  m    : TMemoryStream;
  Bound, s: string;
  res  : Boolean;
  l    : TStringList;
  suc  : Boolean = False;
  date : String = '';
  url  : String = '';
  upl  : integer;
  acc  : integer;
begin
  btnUpload.Enabled:=false; //allow only one click
  btnExportSign.Enabled:=True;
  mStat.Lines.Add('');
  Bound := IntToHex(Random(MaxInt), 8) + '_Synapse_boundary';
  FileName := ChangeFileExt(Filename,'.tq8');
  mStat.Lines.Add('Uploading file ...');
  mStat.Lines.Add('Size: ');
  http := THTTPSend.Create;
  m    := TMemoryStream.Create;
  l    := TStringList.Create;
  try
    http.ProxyHost := cqrini.ReadString('Program','Proxy','');
    http.ProxyPort := cqrini.ReadString('Program','Port','');
    http.UserName  := cqrini.ReadString('Program','User','');
    http.Password  := cqrini.ReadString('Program','Passwd','');

    m.LoadFromFile(FileName);
    http.Sock.OnStatus := @SockCallBack;
    s := '--' + Bound + CRLF;
    s := s + 'content-disposition: form-data; name="upfile";';
    s := s + ' filename="' + FileName +'"' + CRLF;
    s := s + 'Content-Type: Application/octet-string' + CRLF + CRLF;
    WriteStrToStream(http.Document, s);
    http.Document.CopyFrom(m, 0);
    s := CRLF + '--' + Bound + '--' + CRLF;
    WriteStrToStream(http.Document, s);
    http.MimeType := 'multipart/form-data; boundary=' + Bound;

    url := Format(UPLOAD_URL,[cqrini.ReadString('LoTW','LoTWName',''),dmUtils.EncodeURLData(cqrini.ReadString('LoTW','LoTWPass',''))]);
    if dmData.DebugLevel >= 1 then Writeln(url);

    Res := HTTP.HTTPMethod('POST', url);
    if Res then
    begin
      l.LoadFromStream(HTTP.Document);
      upl:= Pos('.UPL.',l.Text);
      acc:= Pos('accepted',l.Text);

      if ( (upl>0) and (acc>0) and ((acc-upl)<10) )  //should hit for same line "<!-- .UPL. accepted -->" even when they adjust space count between words
      then
      begin
        mStat.Lines.Add('Uploading was successful');
        mStat.Lines.Add('---------');
        mStat.Lines.Add(' ');
        suc := True
      end
      else begin
        mStat.Lines.Add('File was rejected with this error:');
        mStat.Lines.Add(l.Text);
        mStat.Lines.Add('---------');
        mStat.Lines.Add(' ');
      end;
      if dmData.DebugLevel >= 1 then Writeln(l.Text);
    end
    else begin
      mStat.Lines.Add('Error: '+IntToStr(http.Sock.LastError))
    end;
    if suc then
    begin
      btnUpload.Enabled:=false;
      date := FormatDateTime('yyyy-mm-dd',now);
      dmData.Q1.Close();
      dmData.trQ1.Rollback;
      dmData.trQ1.StartTransaction;
      try
        if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) and dmLogUpload.LogUploadEnabled then
          dmLogUpload.DisableOnlineLogSupport;

        dmData.Q1.Open();
        dmData.Q1.First;
        dmData.Q.Close;
        if dmData.trQ.Active then
          dmData.trQ.RollBack;
        dmData.trQ.StartTransaction;
        while not dmData.Q1.Eof do
        begin
          dmData.Q.SQL.Text := 'update cqrlog_main set lotw_qsls = ' + QuotedStr('Y') +
                               ',lotw_qslsdate = ' + QuotedStr(date) + 'where id_cqrlog_main = '+
                               dmData.Q1.FieldByName('id_cqrlog_main').AsString;
          if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
          dmData.Q.ExecSQL;
          dmData.Q1.Next
        end;
      finally
        dmData.Q.Close();
        dmData.trQ.Commit;
        dmData.trQ1.Rollback;
        if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) and dmLogUpload.LogUploadEnabled then
          dmLogUpload.EnableOnlineLogSupport(False)
      end
    end
  finally
    http.Free;
    l.Free;
    m.Free
  end;
  btnClose.Font.Style:=[fsBold,fsItalic];
  btnClose.Repaint;
  btnUpload.Font.Style:=[];
  btnUpload.Repaint;
  mStat.SelStart:=length(mStat.Text);
  mStat.SelLength:=0;
  mStat.Refresh;
  Application.ProcessMessages;
end;

procedure TfrmLoTWExport.mStatChange(Sender: TObject);
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

procedure TfrmLoTWExport.tabLocalFileEnter(Sender: TObject);
begin
  btnClose1.Font.Style:=[];
  btnClose1.Repaint;
end;

procedure TfrmLoTWExport.tmrLoTWTimer(Sender: TObject);
var
  OutputLines: TStringList;
begin
  if not AProcess.Running then
  begin
    OutputLines := TStringList.Create;
    try
      OutputLines.LoadFromStream(Aprocess.Output);
      mStat.Lines.AddStrings(OutputLines);
      OutputLines.LoadFromStream(Aprocess.Stderr);
      mStat.Lines.AddStrings(OutputLines);
    finally
      OutputLines.Free;
    end;

    if Aprocess.ExitCode = 0 then
      begin
       mStat.Lines.Add('Signed ...');
       mStat.Lines.Add('If you did not see any errors, you can send signed file to LoTW website by' +
                      ' pressing Upload button');
       btnUpload.Enabled := True;
       btnUpload.Font.Style:=[fsBold,fsItalic];
       btnUpload.Repaint;
      end
     else
      Begin
        mStat.Lines.Add('Sign failed somehow. The exit code was '+IntToStr(Aprocess.ExitCode)+ ' it should be 0 (zero)');
        mStat.Lines.Add('Try to find reason for this!');
      end;
    mStat.Lines.Add('---------');
    mStat.Lines.Add(' ');

    grbWebExport.Enabled := True;
    grbTqsl.Enabled      := True;
    pnlUpload.Enabled    := True;
    pnlUpload.Repaint;
    tmrLoTW.Enabled      := False;
    mStat.SelStart:=length(mStat.Text);
    mStat.SelLength:=0;
    mStat.Refresh;
    Application.ProcessMessages;
  end
end;


procedure TfrmLoTWExport.btnFileExportClick(Sender: TObject);
begin
  if edtFileName.Text = '' then
  begin
    Application.MessageBox('Please select file to export!','Warning ...', mb_ok + mb_IconWarning);
    exit
  end;
  FileName  := edtFileName.Text;
  MarkAfter := chkFileMarkAfterExport.Checked;
  btnClose1.Enabled:=false;
  ExportToAdif;
  btnClose1.Enabled:=true;
  btnClose1.Font.Style:=[fsBold,fsItalic];
  btnClose1.Repaint;
end;

procedure TfrmLoTWExport.FormShow(Sender: TObject);
begin
  dlgSave.InitialDir := dmData.HomeDir;
  dmUtils.LoadWindowPos(Self);

  edtTqsl.Text := cqrini.ReadString('LoTWExp','cmd','/usr/bin/tqsl -d -l "your qth name" %f -x');
  if pgLoTWExport.ActivePageIndex = 1 then
    rbWebExportNotExported.SetFocus
end;

procedure TfrmLoTWExport.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  if AProcess.Running then
  begin
    CanClose := False;
    exit
  end;
  dmUtils.SaveWindowPos(Self);

  cqrini.WriteString('LoTWExp','cmd',edtTqsl.Text);
  AProcess.Free;
  dmData.Q1.Close
end;

procedure TfrmLoTWExport.btnExportSignClick(Sender: TObject);
var
  tmp : String;
  paramList :TStringList;
  index,
  res : Integer;
begin
  grbWebExport.Enabled := False;
  grbTqsl.Enabled      := False;
  pnlUpload.Enabled    := False;

  MarkAfter := False;
  mStat.Clear;
  FileName := dmData.HomeDir + 'lotw'+PathDelim+FormatDateTime('yyyy-mm-dd_hh-mm-ss',now)+'.adi';
  tmp := copy(edtTqsl.Text,1,Pos(' ',edtTqsl.Text)-1);
  if not FileExists(tmp) then
  begin
    mStat.Lines.Add('tqsl file not found!');
    mStat.Lines.Add(tmp);
    mStat.Lines.Add('Correct path to the tqsl binary or if you do not have tqsl installed, please install it from ' +
                     'software repository');
    exit
  end;
  mStat.Lines.Add('Starting export to adif ...');
  mStat.Repaint;
  btnExportSign.Enabled:=false;
  res := ExportToAdif;
  if res > 1 then
  begin
    mStat.Lines.Add('Error creating adif file!');
    mStat.Lines.Add('File:');
    mStat.Lines.Add(FileName);
    lblInfo.Caption := '';
    exit
  end else
    if res = 1 then
      exit;
  lblInfo.Caption := '';
  mStat.Lines.Add('Export to the adif file completed.');
  mStat.Lines.Add('File:');
  mStat.Lines.Add(FileName);
  mStat.Lines.Add('Signing adif file, running (one parameter shown on each line):');
  Application.ProcessMessages;

  index:=0;
  paramList := TStringList.Create;
  paramList.Delimiter := ' ';
  //Force -q (quiet). Without it tqsl can pop its "configuration file out
  //of date" / certificate-password dialog; this synchronous wait then
  //freezes the whole GUI until that (often hidden) window is dismissed -
  //the "force upload locked up" bug. -q makes tqsl fail with a status
  //instead of blocking on a dialog. The auto-upload path already adds it.
  tmp := StringReplace(edtTqsl.Text,'%f',FileName,[]);
  if Pos(' -q',tmp) = 0 then tmp := tmp + ' -q';
  paramList.DelimitedText := tmp;
  AProcess.Parameters.Clear;
  while index < paramList.Count do
  begin
    if (index = 0) then AProcess.Executable := paramList[index]
      else AProcess.Parameters.Add(paramList[index]);
    inc(index);
  end;
  paramList.Free;
  AProcess.Options := [poUsePipes];
  if dmData.DebugLevel>=1 then Writeln('AProcess.Executable: ',AProcess.Executable,' Parameters: ',AProcess.Parameters.Text);
  mStat.Lines.Add(AProcess.Executable);
  mStat.Lines.Add(AProcess.Parameters.Text);
  AProcess.Execute;

  tmrLoTW.Enabled      := True
end;

procedure TfrmLoTWExport.FormCreate(Sender: TObject);
begin
  AProcess := TProcess.Create(nil);
  //Auto-LoTW toggle, created at runtime (no .lfm surgery): batched
  //background sign+upload after every logged QSO.
  chkAutoUp := TCheckBox.Create(Self);
  chkAutoUp.Parent  := tabUpload;
  chkAutoUp.Align   := alBottom;
  chkAutoUp.Caption := 'Upload new QSOs to LoTW automatically '+
                       '(background, ~2 min after logging)';
  chkAutoUp.Checked := cqrini.ReadBool('LoTW','AutoUpload',False);
  chkAutoUp.OnChange := @chkAutoUpChange
end;

procedure TfrmLoTWExport.chkAutoUpChange(Sender: TObject);
begin
  cqrini.WriteBool('LoTW','AutoUpload',chkAutoUp.Checked)
end;

function TfrmLoTWExport.ExportToAdif : Word;
var
  f         : TextFile;
  tmp       : String  = '';
  nr        : Integer = 1;
  date,
  ModeOut,
  SubmodeOut: String;
begin
  if FileExists(FileName) then
    DeleteFile(FileName);

  AssignFile(f,FileName);
  {$i-}
  Rewrite(f);
  {$i+}
  Result := IOResult;
  If IOresult<>0 then
  begin
    Application.MessageBox(PChar('Error opening file : ' + IntToStr(IOResult)),'Error ...',mb_ok + mb_IconError);
    exit
  end;

  date := FormatDateTime('yyyy-mm-dd',now);
  Writeln(f);
  Writeln(f, '<ADIF_VER:5>3.1.0');
  Writeln(f, '<CREATED_TIMESTAMP:15>',FormatDateTime('YYYYMMDD hhmmss',dmUtils.GetDateTime(0)));
  Writeln(f, 'ADIF export from CQRLOG for Linux version '+dmData.VersionString);
  Writeln(f, 'Copyright (C) ',YearOf(now),' by Petr, OK2CQR and Martin, OK1RR');
  Writeln(f);
  Writeln(f, 'Internet: http://www.cqrlog.com');
  Writeln(f);
  Writeln(f, '<EOH>');

  if dmData.trQ1.Active then
    dmData.trQ1.RollBack;
  dmData.Q1.Close;
  if (dmData.IsFilter and (rbWebExportAll.Checked or rbFileExportAll.Checked)) then
  begin
    dmData.Q1.SQL.Text := dmData.qCQRLOG.SQL.Text
  end
  else begin
     if rbWebExportAll.Checked then
       dmData.Q1.SQL.Text := 'select * from cqrlog_main'
     else
       dmData.Q1.SQL.Text := 'select * from cqrlog_main where lotw_qslsdate is null'
  end;
  dmData.trQ1.StartTransaction;
  if dmData.DebugLevel >= 1 then Writeln(dmData.Q1.SQL.Text);
  dmData.Q1.Open();
  if MarkAfter then
    dmData.trQ.StartTransaction;
  try
    dmData.Q1.First;
    while not dmData.Q1.EOF do
    begin
      lblInfo.Caption := 'Exporting QSO nr. ' + IntToStr(Nr);
      if not rbWebExportAll.Checked then
      begin
        if dmData.Q1.FieldByName('lotw_qsls').AsString <> '' then
        begin
          dmData.Q1.Next;
          Continue
        end
      end;

      //DL7OAP 2020-06-14: github.com/ok2cqr/cqrlog/issues/292
      //Propagation type RPT (repeater) should not be uploaded to LoTW
      //because repeater contacts don't count and do not match the LoTW rule
      if (uppercase(dmData.Q1.FieldByName('prop_mode').AsString) = 'RPT') then
      begin
        dmData.Q1.Next;
        Continue
      end;

      tmp :=  dmData.Q1.FieldByName('qsodate').AsString;
      tmp := copy(tmp,1,4) + copy(tmp,6,2) +copy(tmp,9,2);
      tmp := dmUtils.StringToADIF('<QSO_DATE',tmp);
      Writeln(f, tmp);

      tmp := dmData.Q1.FieldByName('time_on').AsString;
      tmp := copy(tmp,1,2) + copy(tmp,4,2);
      tmp := dmUtils.StringToADIF('<TIME_ON',tmp);
      Writeln(f, tmp);

      tmp := dmUtils.StringToADIF('<CALL',dmUtils.RemoveSpaces(dmData.Q1.FieldByName('callsign').AsString));
      Writeln(f,tmp);

      dmUtils.ModeFromCqr(dmData.Q1.FieldByName('mode').AsString,0,dmData.DebugLevel >= 1,ModeOut,SubmodeOut);
      tmp := dmUtils.StringToADIF('<MODE',ModeOut);
      Writeln(f,tmp);
      if SubmodeOut<>'' then
                        Begin
                          tmp := dmUtils.StringToADIF('<SUBMODE',SubmodeOut);
                          Writeln(f,tmp);
                        end;

      tmp :=dmUtils.StringToADIF( '<BAND' , dmData.Q1.FieldByName('band').AsString);
      Writeln(f,tmp);

      tmp := dmUtils.StringToADIF('<FREQ' , dmData.Q1.FieldByName('freq').AsString);
      Writeln(f,tmp);

      tmp := dmUtils.StringToADIF('<RST_SENT' , dmData.Q1.FieldByName('rst_s').AsString);
      Writeln(f,tmp);

      tmp := dmUtils.StringToADIF('<RST_RCVD' ,dmData.Q1.FieldByName('rst_r').AsString);
      Writeln(f,tmp);

      if (dmData.Q1.FieldByName('prop_mode').AsString <> '') then
        Writeln(f, dmUtils.StringToADIF('<PROP_MODE' ,dmData.Q1.FieldByName('prop_mode').AsString));

      if (dmData.Q1.FieldByName('satellite').AsString <> '') then
        Writeln(f, dmUtils.StringToADIF('<SAT_NAME' ,dmData.Q1.FieldByName('satellite').AsString));

      if (dmData.Q1.FieldByName('rxfreq').AsString <> '') then
        Writeln(f, dmUtils.StringToADIF('<FREQ_RX' , dmData.Q1.FieldByName('rxfreq').AsString));

      Writeln(f,'<EOR>');
      Writeln(f);
      if (nr mod 100 = 0) then
      begin
        lblInfo.Repaint;
        Application.ProcessMessages
      end;
      inc(nr);
      if MarkAfter and (pgLoTWExport.ActivePageIndex = 0) then
      begin
        dmData.Q.SQL.Text := 'update cqrlog_main set lotw_qsls = ' + QuotedStr('Y') +
                             ',lotw_qslsdate = ' + QuotedStr(date) + ' where id_cqrlog_main = '+
                             dmData.Q1.FieldByName('id_cqrlog_main').AsString;
        dmData.Q.ExecSQL
      end;
      dmData.Q1.Next
    end;
    if nr=1 then
    begin
      mStat.Lines.Add('Nothing to export ...');
      Result := 1
    end
  finally
   if MarkAfter  and (pgLoTWExport.ActivePageIndex = 0)  then
      dmData.trQ.Commit;
    dmData.Q1.Close();
    dmData.trQ1.Rollback;
    CloseFile(f)
  end
end;

procedure TfrmLoTWExport.SockCallBack (Sender: TObject; Reason:  THookSocketReason; const  Value: string);
begin
  if Reason = HR_WriteCount then
  begin
    FileSize := FileSize + StrToInt(Value);
    mStat.Lines.Strings[mStat.Lines.Count-1] := 'Size: '+ IntToStr(FileSize);
    Repaint;
    Application.ProcessMessages
  end
end;


{ ------------------------------------------------------------------ }
{ Auto-LoTW engine                                                    }
{ ------------------------------------------------------------------ }

type
  TAutoLotwThread = class(TThread)
  private
    fCmd     : String;
    fIds     : TStringList;   //owned; id_cqrlog_main of the batch
    fTail    : String;        //last interesting tqsl output line
    fExit    : Integer;
    procedure SyncDone;
  protected
    procedure Execute; override;
  public
    constructor Create(const ACmd : String; AIds : TStringList);
    destructor Destroy; override;
  end;

  TAutoLotw = class
  private
    tmr    : TTimer;
    busy   : Boolean;
    procedure OnTimer(Sender : TObject);
    procedure StartBatch;
  public
    constructor Create;
    procedure Kick;
    procedure BatchFinished;
  end;

var
  AutoLotw : TAutoLotw = nil;

const
  C_AUTOLOTW_FILE = 'autolotw.adi';
  C_AUTOLOTW_CAP  = 500;    //bigger backlogs belong in the manual window

procedure AutoLotwStatus(const msg : String);
begin
  if dmData.DebugLevel >= 1 then Writeln('AutoLoTW: ',msg);
  if (frmLogUploadStatus <> nil) and frmLogUploadStatus.Showing then
    frmLogUploadStatus.ServiceLineRaw('LoTW: '+msg, clTeal)
end;

constructor TAutoLotwThread.Create(const ACmd : String; AIds : TStringList);
begin
  inherited Create(True);
  fCmd := ACmd;
  fIds := AIds;
  FreeOnTerminate := True
end;

destructor TAutoLotwThread.Destroy;
begin
  FreeAndNil(fIds);
  inherited Destroy
end;

procedure TAutoLotwThread.Execute;
var
  P   : TProcess;
  buf : array[0..2047] of char;
  n   : Integer;
  raw : String = '';
  i   : Integer;
  lst : TStringList;
begin
  P := TProcess.Create(nil);
  try
    //sh -c handles the quoted station-location in the operator's template.
    P.Executable := '/bin/sh';
    P.Parameters.Add('-c');
    P.Parameters.Add(fCmd);
    P.Options := [poUsePipes, poStderrToOutPut];
    P.Execute;
    while P.Running do
    begin
      if P.Output.NumBytesAvailable > 0 then
      begin
        n := P.Output.Read(buf, SizeOf(buf));
        if n > 0 then raw := raw + copy(buf, 1, n)
      end
      else
        Sleep(100)
    end;
    while P.Output.NumBytesAvailable > 0 do
    begin
      n := P.Output.Read(buf, SizeOf(buf));
      if n <= 0 then break;
      raw := raw + copy(buf, 1, n)
    end;
    fExit := P.ExitStatus;
    lst := TStringList.Create;
    try
      lst.Text := raw;
      for i := lst.Count-1 downto 0 do
        if Trim(lst[i]) <> '' then
        begin
          fTail := Trim(lst[i]);
          break
        end
    finally
      lst.Free
    end
  finally
    P.Free
  end;
  Synchronize(@SyncDone)
end;

procedure TAutoLotwThread.SyncDone;
var
  q    : TSQLQuery;
  tr   : TSQLTransaction;
  i    : Integer;
  date : String;
begin
  //tqsl exit codes: 0 = uploaded, 8 = all were already uploaded
  //(duplicates), 9 = mixed — all three mean LoTW has the QSOs.
  if (fExit = 0) or (fExit = 8) or (fExit = 9) then
  begin
    date := FormatDateTime('yyyy-mm-dd',now);
    q  := TSQLQuery.Create(nil);
    tr := TSQLTransaction.Create(nil);
    try
      tr.DataBase   := dmData.MainCon;
      q.DataBase    := dmData.MainCon;
      q.Transaction := tr;
      tr.StartTransaction;
      //QSL-status marks must not churn the online-log ledger: the update
      //trigger skips queueing while @cqr_qsl_mark is set (live-found: one
      //auto-LoTW batch re-queued every marked QSO as an UPDATE for
      //ClubLog/HRD/QRZ).
      q.SQL.Text := 'SET @cqr_qsl_mark=1';
      q.ExecSQL;
      for i := 0 to fIds.Count-1 do
      begin
        q.SQL.Text := 'update cqrlog_main set lotw_qsls='+QuotedStr('Y')+
                      ', lotw_qslsdate='+QuotedStr(date)+
                      ' where id_cqrlog_main='+fIds[i];
        q.ExecSQL
      end;
      q.SQL.Text := 'SET @cqr_qsl_mark=NULL';
      q.ExecSQL;
      tr.Commit;
      AutoLotwStatus(IntToStr(fIds.Count)+' QSO signed and uploaded ('+fTail+')');
      //The manual export refreshes the grids after marking; without this
      //the sent-flags sit invisible until the next natural refresh
      //(live-found: "they do not show as sent").
      if frmMain <> nil then
        frmMain.acRefreshExecute(nil)
    finally
      q.Free;
      tr.Free
    end
  end
  else
    AutoLotwStatus('upload FAILED (tqsl exit '+IntToStr(fExit)+'): '+fTail+
                   ' - QSOs stay queued for the next batch');
  if AutoLotw <> nil then
    AutoLotw.BatchFinished
end;

constructor TAutoLotw.Create;
begin
  inherited Create;
  tmr := TTimer.Create(nil);
  tmr.Enabled  := False;
  tmr.Interval := 1000 * cqrini.ReadInteger('LoTW','AutoDelaySec',120);
  tmr.OnTimer  := @OnTimer
end;

procedure TAutoLotw.Kick;
begin
  //restart the quiet-period timer: a run of QSOs becomes one batch
  tmr.Interval := 1000 * cqrini.ReadInteger('LoTW','AutoDelaySec',120);
  tmr.Enabled := False;
  tmr.Enabled := True
end;

procedure TAutoLotw.BatchFinished;
begin
  busy := False
end;

procedure TAutoLotw.OnTimer(Sender : TObject);
begin
  tmr.Enabled := False;
  if busy then
  begin
    tmr.Enabled := True;   //previous batch still signing: wait another period
    exit
  end;
  StartBatch
end;

procedure TAutoLotw.StartBatch;
var
  q        : TSQLQuery;
  tr       : TSQLTransaction;
  f        : TextFile;
  ids      : TStringList;
  FileName : String;
  cmd      : String;
  tqslBin  : String;
  tmp,
  ModeOut,
  SubmodeOut : String;
begin
  cmd := cqrini.ReadString('LoTWExp','cmd','/usr/bin/tqsl -d -l "your qth name" %f -x');
  tqslBin := Trim(ExtractWord(1,cmd,[' ']));
  if not FileExists(tqslBin) then
  begin
    AutoLotwStatus('tqsl not found ('+tqslBin+') - check the LoTW export window settings');
    exit
  end;
  if Pos('your qth name',cmd) > 0 then
  begin
    AutoLotwStatus('station location not set - open the LoTW export window once');
    exit
  end;

  FileName := dmUtils.GetHomeDirectory+'.config/cqrlog/'+C_AUTOLOTW_FILE;
  ids := TStringList.Create;
  q   := TSQLQuery.Create(nil);
  tr  := TSQLTransaction.Create(nil);
  try
    tr.DataBase   := dmData.MainCon;
    q.DataBase    := dmData.MainCon;
    q.Transaction := tr;
    tr.StartTransaction;
    q.SQL.Text := 'select * from cqrlog_main where lotw_qslsdate is null'+
                  ' and (lotw_qsls is null or lotw_qsls='+QuotedStr('')+')'+
                  ' and upper(coalesce(prop_mode,'+QuotedStr('')+'))<>'+QuotedStr('RPT')+
                  ' order by id_cqrlog_main limit '+IntToStr(C_AUTOLOTW_CAP+1);
    q.Open;
    if q.Eof then exit;                       //nothing unsigned

    AssignFile(f,FileName);
    {$i-} ReWrite(f); {$i+}
    if IOResult <> 0 then
    begin
      AutoLotwStatus('cannot write '+FileName);
      exit
    end;
    Writeln(f,'<ADIF_VER:5>3.1.0');
    Writeln(f,'auto-LoTW export from CQRLOG');
    Writeln(f,'<EOH>');
    while not q.Eof do
    begin
      if ids.Count >= C_AUTOLOTW_CAP then
      begin
        CloseFile(f);
        AutoLotwStatus('more than '+IntToStr(C_AUTOLOTW_CAP)+
                       ' unsigned QSOs - use the LoTW export window for the backlog');
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
      if (q.FieldByName('prop_mode').AsString <> '') then
        Writeln(f,dmUtils.StringToADIF('<PROP_MODE',q.FieldByName('prop_mode').AsString));
      if (q.FieldByName('satellite').AsString <> '') then
        Writeln(f,dmUtils.StringToADIF('<SAT_NAME',q.FieldByName('satellite').AsString));
      if (q.FieldByName('rxfreq').AsString <> '') then
        Writeln(f,dmUtils.StringToADIF('<FREQ_RX',q.FieldByName('rxfreq').AsString));
      Writeln(f,'<EOR>');
      ids.Add(q.FieldByName('id_cqrlog_main').AsString);
      q.Next
    end;
    CloseFile(f);

    //Operator's template does the signing; -u makes tqsl upload the
    //result itself and -a compliant skips already-uploaded QSOs without
    //asking. %f -> our batch file.
    cmd := StringReplace(cmd,'%f',AnsiQuotedStr(FileName,'"'),[rfReplaceAll]);
    if Pos(' -u',cmd) = 0 then cmd := cmd + ' -u';
    if Pos(' -a ',cmd) = 0 then cmd := cmd + ' -a compliant';
    if Pos(' -q',cmd) = 0 then cmd := cmd + ' -q';

    AutoLotwStatus('signing + uploading '+IntToStr(ids.Count)+' QSO ...');
    busy := True;
    TAutoLotwThread.Create(cmd, ids).Start;
    ids := nil                                 //thread owns the list now
  finally
    q.Close;
    if tr.Active then tr.RollBack;
    q.Free;
    tr.Free;
    ids.Free
  end
end;

procedure AutoLotwQsoSaved;
begin
  if not cqrini.ReadBool('LoTW','AutoUpload',False) then exit;
  if AutoLotw = nil then
    AutoLotw := TAutoLotw.Create;
  AutoLotw.Kick
end;


end.

