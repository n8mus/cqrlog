unit fImportLoTWWeb;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
  httpsend, blcksock, StdCtrls, ExtCtrls, inifiles, ssl_openssl, ssl_openssl_lib,
  synacode, DateUtils;

type

  { TfrmImportLoTWWeb }

  TfrmImportLoTWWeb = class(TForm)
    btnClose: TButton;
    btnDownload: TButton;
    btnPreferences: TButton;
    cbImports: TCheckBox;
    chkChangeDate: TCheckBox;
    chkShowNew: TCheckBox;
    edtCall: TEdit;
    edtDateFrom: TEdit;
    gbProgress: TGroupBox;
    gbSettings: TGroupBox;
    lblForCall: TLabel;
    lblReturnQsl: TLabel;
    Label4: TLabel;
    mStat: TMemo;
    pnlSettings: TPanel;
    pnlButtons: TPanel;
    procedure cbImportsChange(Sender: TObject);
    procedure chkChangeDateChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormShow(Sender: TObject);
    procedure btnDownloadClick(Sender: TObject);
    procedure btnPreferencesClick(Sender: TObject);
    procedure mStatChange(Sender: TObject);
  private
    Done : Boolean;
    FileSize : Int64;
    chkAutoDownload : TCheckBox;   //runtime opt-in for the daily auto-pull (no .lfm edit)
    procedure SockCallBack (Sender: TObject; Reason:  THookSocketReason; const  Value: string);
  public
    //Headless once-a-day confirmation pull: fetch lotwreport.adi with the
    //stored credentials and mark matches silently. Returns True if the
    //fetch+import ran. Driven from fNewQSO's daily timer.
    function RunAutoDownload : Boolean;
  end;

var
  frmImportLoTWWeb: TfrmImportLoTWWeb;

implementation
{$R *.lfm}

uses fPreferences, dUtils, dData, fImportProgress, uMyini;

procedure TfrmImportLoTWWeb.btnPreferencesClick(Sender: TObject);
begin
  btnClose.Font.Style:=[];
  btnClose.Repaint;
  with TfrmPreferences.Create(self) do
  try
    pgPreferences.ActivePage := tabLoTW;
    ShowModal
  finally
    Free
  end
end;

procedure TfrmImportLoTWWeb.mStatChange(Sender: TObject);
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

procedure TfrmImportLoTWWeb.btnDownloadClick(Sender: TObject);
var
  user : String = '';
  pass : String = '';
  http : THTTPSend;
  m    : TFileStream;
  url  : String = '';
  AdifFile : String = '';
  QSOList : TStringList;
  Count : Word = 0;
begin
  Done := False;
  btnClose.Font.Style:=[];
  btnClose.Repaint;
  FileSize := 0;
  mStat.Clear;
  Application.ProcessMessages;
  if not dmUtils.IsDateOK(edtDateFrom.Text) then
  begin
    mStat.Lines.Add('Please insert correct date (YYYY-MM-DD)!');
    edtDateFrom.SetFocus;
    exit
  end;

  cqrini.WriteString('LoTWImp','Call',edtCall.Text);
  AdifFile := dmData.HomeDir + 'lotw/'+FormatDateTime('yyyy-mm-dd_hh-mm-ss',now)+'.adi';
  QSOList  := TStringList.Create;
  http     := THTTPSend.Create;

  if dmData.DebugLevel>=1 then
  begin
    Writeln('DLLSSLName:',DLLSSLName);
    Writeln('DLLUtilName:',DLLUtilName)
  end;

  m        := TFileStream.Create(AdifFile,fmCreate);
  try
    btnClose.Enabled       := False;
    btnDownload.Enabled    := False;
    btnPreferences.Enabled := False;
    edtDateFrom.Enabled    := False;
    edtCall.Enabled        := False;

    user := cqrini.ReadString('LoTW','LoTWName','');
    pass :=dmUtils.EncodeURLData(cqrini.ReadString('LoTW','LoTWPass',''));
    http.Sock.OnStatus := @SockCallBack;
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');

    if (user = '') or (pass='') then
    begin
      mStat.Lines.Add('User name or password is not set!');
      exit
    end;
    cqrini.WriteString('LoTWImp','DateFrom',edtDateFrom.Text);

    url := 'https://LoTW.arrl.org/lotwuser/lotwreport.adi?login='+user+'&password='+pass+'&qso_query=1&qso_qsldetail="yes"'+
           '&qso_qslsince='+edtDateFrom.Text;

    if edtCall.Text <> '' then
      url := url+'&qso_owncall='+edtCall.Text;
    if dmData.DebugLevel>=1 then Writeln(url);
    http.MimeType := 'text/xml';
    http.Protocol := '1.1';
    if http.HTTPMethod('GET',url) then
    begin
      http.Document.Seek(0,soBeginning);
      m.CopyFrom(http.Document,HTTP.Document.Size);
      http.Clear;
      mStat.Lines.Add('File downloaded successfully');
      mStat.Lines.Add('File: '+ AdifFile);
      Done := True;
      Repaint;
      Application.ProcessMessages;
      mStat.Lines.Add('Preparing import ....');
      if not FileExists(AdifFile) then
      begin
        mStat.Lines.Add('File: '+ AdifFile);
        mStat.Lines.Add('DOES NOT exist!');
        exit
      end;
      with TfrmImportProgress.Create(self) do
      try
        FileName    := AdifFile;
        ImportType  := imptImportLoTWAdif;
        LoTWShowNew := chkShowNew.Checked;
        ShowModal;
        QSOList.Text := LoTWQSOList.Text;
        Count        := LoTWQSOList.Count
      finally
        Free
      end;
      mStat.Lines.Add('Import complete ...');
      if chkChangeDate.Checked then
        Begin
         edtDateFrom.Caption:= FormatDateTime('YYYY-MM-DD', IncDay(Today, -1));
         cqrini.WriteString('LoTWImp','DateFrom',FormatDateTime('YYYY-MM-DD', IncDay(Today, -1)));
        end;
      if chkShowNew.Checked then
      begin
        mStat.Lines.Add('');
        mStat.Lines.Add('New QSOs confirmed by LoTW:');
        mStat.Lines.AddStrings(QSOList);
        mStat.Lines.Add('-----------------------------');
        mStat.Lines.Add('Total: ' + IntToStr(Count) + ' new QSOs');
      end;
    end
    else begin
      if dmData.DebugLevel >= 1 then
      begin
        http.Document.Seek(0,soBeginning);
        m.CopyFrom(http.Document,HTTP.Document.Size);
        mStat.Lines.LoadFromStream(m)
      end;
      mStat.Lines.Add('NOT logged');
      mStat.Lines.Add('Error: '+IntToStr(http.Sock.LastError));
      mStat.Lines.Add('Error: '+http.Sock.LastErrorDesc);
      mStat.Lines.Add('Error: '+http.Sock.SSL.LibName)
    end
  finally
    http.Free;
    m.Free;
    QSOList.Free;
    btnClose.Enabled       := True;
    btnClose.Font.Style:=[fsBold];
    btnClose.Repaint;
    btnDownload.Enabled    := True;
    btnPreferences.Enabled := True;
    edtDateFrom.Enabled    := True;
    edtCall.Enabled        := True
  end
end;

procedure TfrmImportLoTWWeb.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(Self);
  chkShowNew.Checked := cqrini.ReadBool('LoTWImp','ShowNewQSOs',True);
  chkChangeDate.Checked:=cqrini.ReadBool('LoTWImp','ChangeDate',False);
  edtDateFrom.Text   := cqrini.ReadString('LoTWImp','DateFrom','1990-01-01');
  edtCall.Text       := cqrini.ReadString('LoTWImp','Call',
                        cqrini.ReadString('Station','Call',''));
  cbImports.Checked  := cqrini.ReadBool('LoTWImp','Import',True);
  if chkAutoDownload = nil then
  begin
    //Runtime opt-in (no .lfm edit, per the auto-LoTW pattern). Grow the
    //settings area so the extra row isn't clipped, then anchor below the
    //last checkbox so no pixel math is needed.
    pnlSettings.Height := pnlSettings.Height + 28;
    chkAutoDownload := TCheckBox.Create(Self);
    chkAutoDownload.Parent := cbImports.Parent;      //gbSettings
    chkAutoDownload.AnchorSideLeft.Control := cbImports;
    chkAutoDownload.AnchorSideTop.Control  := cbImports;
    chkAutoDownload.AnchorSideTop.Side     := asrBottom;
    chkAutoDownload.BorderSpacing.Top      := 3;
    chkAutoDownload.Width   := 470;
    chkAutoDownload.Caption := 'Automatically download confirmations once a day (background)';
  end;
  chkAutoDownload.Checked := cqrini.ReadBool('LoTWImp','AutoDownload',False);
  Done := False;
  btnClose.Font.Style:=[];
  btnClose.Repaint;
end;

procedure TfrmImportLoTWWeb.FormCloseQuery(Sender: TObject;
  var CanClose: boolean);
begin
  if chkAutoDownload <> nil then
    cqrini.WriteBool('LoTWImp','AutoDownload',chkAutoDownload.Checked);
  dmUtils.SaveWindowPos(Self)
end;

function TfrmImportLoTWWeb.RunAutoDownload : Boolean;
var
  user, pass, url, AdifFile, sinceDate : String;
  http : THTTPSend;
  m    : TFileStream;
begin
  Result := False;
  user := cqrini.ReadString('LoTW','LoTWName','');
  pass := dmUtils.EncodeURLData(cqrini.ReadString('LoTW','LoTWPass',''));
  if (user = '') or (pass = '') then
    exit;
  //Incremental window: pull since the stored watermark. The first auto-run
  //has none, so it falls back to the last 30 days (not the full 1990 history,
  //which would be a large blocking pull on startup — a manual download still
  //covers older confirmations). Overlap is harmless: the import skips QSOs
  //already marked 'L'.
  sinceDate := cqrini.ReadString('LoTWImp','AutoSince',
               FormatDateTime('yyyy-mm-dd', IncDay(Today,-30)));
  AdifFile := dmData.HomeDir + 'lotw/'+FormatDateTime('yyyy-mm-dd_hh-mm-ss',now)+'_auto.adi';
  http := THTTPSend.Create;
  m    := TFileStream.Create(AdifFile,fmCreate);
  try
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');
    url := 'https://LoTW.arrl.org/lotwuser/lotwreport.adi?login='+user+'&password='+pass+
           '&qso_query=1&qso_qsldetail="yes"&qso_qslsince='+sinceDate;
    http.MimeType := 'text/xml';
    http.Protocol := '1.1';
    if http.HTTPMethod('GET',url) then
    begin
      http.Document.Seek(0,soBeginning);
      m.CopyFrom(http.Document,HTTP.Document.Size);
      http.Clear;
      if FileExists(AdifFile) then
      begin
        with TfrmImportProgress.Create(Self) do
        try
          FileName    := AdifFile;
          ImportType  := imptImportLoTWAdif;
          LoTWShowNew := False;
          Silent      := True;      //no interactive prompts on the daily run
          ShowModal
        finally
          Free
        end;
        //Advance the watermark with a 2-day overlap so a missed day is
        //recovered on the next pull.
        cqrini.WriteString('LoTWImp','AutoSince',
          FormatDateTime('yyyy-mm-dd', IncDay(Today,-2)));
        Result := True
      end
    end
  finally
    http.Free;
    m.Free
  end
end;

procedure TfrmImportLoTWWeb.cbImportsChange(Sender: TObject);
begin
  cqrini.WriteBool('LoTWImp','Import',cbImports.Checked);
end;

procedure TfrmImportLoTWWeb.chkChangeDateChange(Sender: TObject);
begin
  cqrini.WriteBool('LoTWImp','ChangeDate',chkChangeDate.Checked);
end;

procedure TfrmImportLoTWWeb.SockCallBack (Sender: TObject; Reason:  THookSocketReason; const  Value: string);
begin
  case Reason of
      HR_Connect :  Begin
                     if dmData.DebugLevel>=1 then Writeln( 'Connected to LoTW server');
                     mStat.Lines.Add('Connected to LoTW server');
                     mStat.Lines.Add('Downloading...');
                     Repaint;
                     Application.ProcessMessages
                    end;

      HR_ReadCount: begin
                      FileSize := FileSize + StrToInt(Value);
                      if not Done then
                        mStat.Lines.Strings[mStat.Lines.Count-1] := 'Downloading size: '+ IntToStr(FileSize);
                      Repaint;
                      Application.ProcessMessages
                    end;

  end;
end;

end.

