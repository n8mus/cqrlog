unit fContest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, LCLType, Buttons, ComCtrls, ExtDlgs, Menus, Spin, Grids,
  strutils, fscp, iniFiles, uContestRules, uCallHistory;

type

  { TfrmContest }

  TfrmContest = class(TForm)
    btClearAll: TButton;
    btSave: TButton;
    btClearQso : TButton;
    btDupChkStart: TButton;
    btnCQstart: TButton;
    cdDupeDate: TCalendarDialog;
    chkNRstr: TCheckBox;
    chkNRString: TCheckBox;
    chkSetFilter: TCheckBox;
    chkHint: TCheckBox;
    chkMarkDupe: TCheckBox;
    chkSP: TCheckBox;
    chkTabAll: TCheckBox;
    chkQsp: TCheckBox;
    chkTrueRST: TCheckBox;
    chkNoNr: TCheckBox;
    chkSpace: TCheckBox;
    chkLoc: TCheckBox;
    chkNRInc: TCheckBox;
    cmbContestName: TComboBox;
    edtCall: TEdit;
    edtRSTs: TEdit;
    edtSTX: TEdit;
    edtSTXStr: TEdit;
    edtRSTr: TEdit;
    edtSRX: TEdit;
    edtSRXStr: TEdit;
    gbStatus: TGroupBox;
    lblQSOSince: TLabel;
    lblRate10: TLabel;
    lblRate60: TLabel;
    lblCqFreq: TLabel;
    lblCqMode: TLabel;
    lblCQLbl: TLabel;
    lblCQperiod: TLabel;
    lblCQrepeat: TLabel;
    lblSpeed: TLabel;
    lblContestName: TLabel;
    lblCall: TLabel;
    lblRSTs: TLabel;
    lblMSGs: TLabel;
    lblRSTr: TLabel;
    lblNRr: TLabel;
    lblMSGr: TLabel;
    lblNRs: TLabel;
    btnHelp : TSpeedButton;
    Band_070: TMenuItem;
    Band_160: TMenuItem;
    Load: TMenuItem;
    Band_023: TMenuItem;
    AdifExp: TMenuItem;
    CabrilloExp: TMenuItem;
    EdiExp: TMenuItem;
    mnuModeRelated: TMenuItem;
    mnuReSetAllHF: TMenuItem;
    mnuReSetAllVHF: TMenuItem;
    OpenDialog1: TOpenDialog;
    Save: TMenuItem;
    Band_2: TMenuItem;
    Band_4: TMenuItem;
    Band_6: TMenuItem;
    Band_10: TMenuItem;
    Band_15: TMenuItem;
    Band_20: TMenuItem;
    Band_40: TMenuItem;
    Band_80: TMenuItem;
    mnuReSetAllCounters: TMenuItem;
    mnuExit: TMenuItem;
    mnuQSOcount: TMenuItem;
    mnuDXQSOCount: TMenuItem;
    mnuCountyrCountAll: TMenuItem;
    mnuDXCountryCount: TMenuItem;
    mnuDXCountryList: TMenuItem;
    mnuOwnCountryCount: TMenuItem;
    mnuOwnCountryList: TMenuItem;
    mnuMsgMultipCount: TMenuItem;
    mnuMsgMultipList: TMenuItem;
    mStatus: TMemo;
    mnuGrid: TMenuItem;
    mnyIOTA: TMenuItem;
    mnuState: TMenuItem;
    mnuCounty: TMenuItem;
    mnuAward: TMenuItem;
    mnuQSLvia: TMenuItem;
    mnuComment: TMenuItem;
    mnuName: TMenuItem;
    CQpanel: TPanel;
    popQuickExport: TPopupMenu;
    popSetMsg: TPopupMenu;
    popCommonStatus: TPopupMenu;
    rbDupeCheck: TRadioButton;
    rbNoMode4Dupe: TRadioButton;
    rbIgnoreDupes: TRadioButton;
    SaveDialog1: TSaveDialog;
    sbContest: TStatusBar;
    Separator1: TMenuItem;
    Separator2: TMenuItem;
    spCQperiod: TSpinEdit;
    spCQrepeat: TSpinEdit;
    sgStatus: TStringGrid;
    tmrScore: TTimer;
    tmrCQ: TTimer;
    tmrESC2: TTimer;
    procedure btClearAllClick(Sender: TObject);
    procedure btDupChkStartClick(Sender: TObject);
    procedure btnCQstartClick(Sender: TObject);
    procedure btSaveClick(Sender: TObject);
    procedure btClearQsoClick(Sender : TObject);
    procedure chkHintChange(Sender: TObject);
    procedure chkNoNrChange(Sender: TObject);
    procedure chkNRIncChange(Sender: TObject);
    procedure chkNRIncClick(Sender : TObject);
    procedure chkNRStringChange(Sender: TObject);
    procedure chkQspChange(Sender: TObject);
    procedure chkSetFilterClick(Sender: TObject);
    procedure chkSetFilterMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure chkSpaceChange(Sender: TObject);
    procedure chkSPClick(Sender: TObject);
    procedure chkTrueRSTChange(Sender: TObject);
    procedure chkTabAllChange(Sender: TObject);
    procedure cmbContestNameChange(Sender: TObject);
    procedure cmbContestNameEnter(Sender: TObject);
    procedure cmbContestNameExit(Sender: TObject);
    procedure edtRSTrEnter(Sender: TObject);
    procedure edtRSTsEnter(Sender: TObject);
    procedure edtSRXStrKeyPress(Sender: TObject; var Key: char);
    procedure edtSTXStrChange(Sender: TObject);
    procedure edtSTXStrKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure lblCqFreqClick(Sender: TObject);
    procedure LoadClick(Sender: TObject);
    procedure mnuReSetAllCountersClick(Sender: TObject);
    procedure edtCallChange(Sender: TObject);
    procedure edtCallExit(Sender: TObject);
    procedure edtCallKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure edtCallKeyPress(Sender: TObject; var Key: char);
    procedure edtSRXChange(Sender: TObject);
    procedure edtSRXStrChange(Sender: TObject);
    procedure edtSRXExit(Sender: TObject);
    procedure edtSTXStrEnter(Sender: TObject);
    procedure edtSTXStrExit(Sender: TObject);
    procedure edtSTXExit(Sender: TObject);
    procedure edtSTXKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure btnHelpClick(Sender : TObject);
    procedure mnuQSOcountClick(Sender: TObject);
    procedure mnuGridClick(Sender: TObject);
    procedure mnuReSetAllHFClick(Sender: TObject);
    procedure mnuReSetAllVHFClick(Sender: TObject);
    procedure mnyIOTAClick(Sender: TObject);
    procedure mnuStateClick(Sender: TObject);
    procedure mnuCountyClick(Sender: TObject);
    procedure mnuAwardClick(Sender: TObject);
    procedure mnuQSLviaClick(Sender: TObject);
    procedure mnuCommentClick(Sender: TObject);
    procedure mnuNameClick(Sender: TObject);
    procedure rbIgnoreDupesChange(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure sgStatusMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure sgStatusPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure spCQperiodChange(Sender: TObject);
    procedure tmrCQTimer(Sender: TObject);
    procedure tmrESC2Timer(Sender: TObject);
    procedure tmrScoreTimer(Sender: TObject);
  private
    { private declarations }
      AllQsos,
      AllDx,
      AllOwnC,
      AllCountries,
      QsoRate10,
      QsoRate60    : integer;
      CQcount      : integer;
      //ESM state, all per-QSO and reset the moment the callsign text
      //changes, so a half-finished QSO can never leak into the next one.
      //throwaway receivers for ScoreContest's out params when the caller only
      //wants the side effect
      ScQsos,ScDupes,ScPts,
      ScM1,ScM2,ScM3 : Integer;
      ESMBeat      : Integer;     //how far through this QSO Enter has got
      ESMIsDupe    : Boolean;     //cached: CheckDupe hits the DB, and the
                                  //hint refreshes on every keystroke
      chkESM       : TCheckBox;   //created at runtime, no .lfm edit
      lblESMNext   : TLabel;      //shows what Enter will do next
      popRescore   : TPopupMenu;  //right-click the status pane
      CallHist     : TCallHistory;
      lblCallHist  : TLabel;      //what we know about him before he sends it
      miN1MM       : TMenuItem;   //N1MM UDP broadcast on/off
      miOnTop      : TMenuItem;   //keep the entry window above the rest
      //Rule engine. Nil-safe everywhere: a contest with no definition file
      //behaves exactly as it did before this existed.
      ContestRules : TContestRules;

    procedure SetActualReportForModeFromRadio;
    procedure InitInput;
    procedure ChkSerialNrUpd(IncNr: boolean);
    procedure SetTabOrders;
    procedure TabStopAllOn;
    procedure QspMsg;
    procedure ClearStatusBar;
    procedure ShowStatusBarInfo;
    procedure MsgIsPopChk(nr:integer);
    procedure MWCStatus;
    procedure NACStatus;
    procedure SRALFt8Status;
    procedure CommonStatus;
    procedure Rates;
    procedure SendFmemory(key:word);
    function CheckDupe(call:string):boolean;
    procedure CQstart(start:boolean);
    procedure ChangeStatusPop(Sender: TObject);
    procedure ESMCreateControls;
    procedure ESMCheckChange(Sender: TObject);
    procedure N1MMCheckChange(Sender: TObject);
    procedure OnTopClick(Sender: TObject);
    procedure SaveLayoutClick(Sender: TObject);
    procedure LoadLayoutClick(Sender: TObject);
    procedure LayoutForms(l : TList);
    function  ESMOn : Boolean;
    function  ESMKeyFor(const role : String; def : Word) : Word;
    function  ESMCallLoggable : Boolean;
    function  ESMExchangeValid : Boolean;
    function  ESMNextAction : Integer;
    procedure ESMUpdateHint;
    procedure ESMFocusExchange;
    procedure ESMDoEnter;
    procedure RescoreClick(Sender: TObject);
    function  CurrentQsoCtx : TQsoCtx;
    procedure ShowMultStatus;
    procedure LoadCallHistory;
    procedure PrefillFromHistory;
    procedure LoadContestRules;
    function  RulesLoaded : Boolean;
    procedure RulesStatus;
  public
    { public declarations }
    ContestReady: Boolean;
    //Scores a contest from the log. Returns -1 when that contest has no rule
    //definition. markLastAsRun is 0/1 to stamp isrunqso on the newest QSO
    //(only the caller who just saved it knows), or -1 to leave it alone.
    //Public because the Cabrillo export needs it for CLAIMED-SCORE.
    //Calls from the loaded call history containing this fragment.
    procedure HistoryCallsLike(const partial : String; l : TStrings);
    function ScoreContest(const contestName : String;
                          writeBack : Boolean;
                          markLastAsRun : Integer;
                          out qsos,dupes,pts,m1,m2,m3 : Integer) : Integer;
    procedure SaveSettings;
  end;

var
  frmContest: TfrmContest;
  ResetStx: string = ''; //contest mode serial numbers store
  ResetStxStr: string = ''; //contest mode additional string store
  EscTimes         :integer = 0;
  DupeFromDate :string = '1900-01-01';
  MsgIs        :integer = 0;
  MWC40,MWC80  :integer;
  UseStatus    :integer;  //can be used for status procedure specific operations
                          //-1:no status, 0:common status, 1..x specific status procedures

  MyAdif   : word;        //These will be filled in FormShow
  Mypfx    : String = '';
  Mycont   : String = '';
  Mycountry: String = '';
  Mywaz    : String = '';
  Myposun  : String = '';
  Myitu    : String = '';
  Mylat    : String = '';
  Mylong   : String = '';

  FmemorySent: Boolean;  //for semiAuto sending

  C
  : integer;
  ContestBandPtr  : array[0..10] of byte =
   // contest bands 160M to 23cm  Points to dUtils.cBands [0..30]
   // 160M  80M  40M  20M  15M  10M   6M    4M    2M    0,7M   0,23M
      (2,    3,   5,   7,   9,  11,   13,   15,   16,    18,    20);

  WasContestName:string;
  WasContestNameChange:String;

implementation

{$R *.lfm}

uses dData, dUtils, dDXCC, fNewQSO, fMain, fWorkedGrids, fTRXControl, fCWKeys, fCWType, uMyIni,
     fMultipliers, uN1MMUdp, fBandMap, fCWReader, fDXCluster;

procedure TfrmContest.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
var
  tmp: string;
  speed: integer = 0;
  i: integer = 0;
  n: string;
begin
  // enter anywhere
  if key = VK_RETURN then
  begin
    if ESMOn then
      //ESM acts from ANY field, callsign box included - the state machine
      //decides whether this Enter sends, logs, or does nothing at all.
      ESMDoEnter
    else
    if (length(edtCall.Text) > 2) and (not edtCall.Focused) then   //must be some kind of call and cursor away from edtCall
      btSave.Click;
    key := 0;
    Exit;
  end;

  //Ctrl+esc
  if ((Shift = [ssShift]) and (key = VK_ESCAPE)) then
    EscTimes:=2;  //removes callsing on following "case EscTimes of"

  //esc, double and triple esc
  if key = VK_ESCAPE then
  begin
    case EscTimes of

      0:Begin  //1st press stops CW/voice memory;
        case frmNewQSO.cmbMode.Text of
         'SSB',
         'FM',
         'AM'  :  frmTRXControl.StopVoice;
         'CW'  :   if Assigned(frmNewQSO.CWint)then
                              Begin
                                frmNewQSO.CWint.StopSending;
                                CQstart(false);
                              end;
         end;
         inc(EscTimes);
         tmrESC2.Enabled := True;
        end;

      1:Begin //2nd returns to callsign column
         frmNewQSO.old_call:='';             //this is stupid hack but only way to reproduce
         frmNewQSO.edtName.Text :='';        //new seek from log (important to see if wkd before,
         frmNewQSO.edtQth.Text  :='';        //and qrz, if one wants)
         frmNewQSO.edtGrid.Text :='';        //otherwise we do not get cursor at the end of call
         edtCall.SetFocus;
         edtCall.SelStart:=length(edtCall.Text);
         edtCall.SelLength:=0;
         FmemorySent:=false;
         CQstart(false);
         inc(EscTimes);
        end;
      2:Begin   // 3rd removes callsign
         frmNewQSO.ClearAll;
         if dmData.DebugLevel >= 1 then
             writeln('Clear all done next focus');
         initInput;
         tmrESC2Timer(nil);
         end;
    end; //case
    key := 0;
    Exit;
  end;

  //memory keys
  if (Key >= VK_F1) and (Key <= VK_F10) and (Shift = []) then
  begin

     if key=VK_F1 then
        Begin
          lblCqMode.Caption:=frmTRXControl.GetRawMode;
          lblCqFreq.Caption := FormatFloat('0.00',frmTRXControl.GetFreqkHz);

          if Assigned(frmNewQSO.CWint) and (chkSP.Checked=False) and (edtCall.Text<>'') then//run mode with uncomplete call
           Begin
              frmNewQSO.CWint.SendText(edtCall.Text);
              Key := 0;
              Exit;
            end;

        end;

    SendFmemory(key);
    key := 0;
  end;

  //CQ timer
  if (Key = VK_F1) and (Shift = [ssShift]) and (edtCall.Text='') then
   begin
     CQstart(true);
     key := 0;
     Exit;
   end;

   n:=IntToStr(frmTRXControl.cmbRig.ItemIndex);

  if( (key in [33,34]) and (Assigned(frmNewQSO.CWint)) )then
   begin
     case key of
       33 : speed := frmNewQSO.CWint.GetSpeed+ cqrini.ReadInteger('CW','SpeedStep', 2);
       34 : speed := frmNewQSO.CWint.GetSpeed+ -1*cqrini.ReadInteger('CW','SpeedStep', 2);
     end;
    frmNewQSO.CWint.SetSpeed(speed);
    if (cqrini.ReadInteger('CW'+n,'Type',0)=1) and cqrini.ReadBool('CW'+n,'PotSpeed',False) then
        frmNewQSO.sbNewQSO.Panels[4].Text := 'Pot WPM'
       else
        frmNewQSO.sbNewQSO.Panels[4].Text := IntToStr(speed) + 'WPM';
    lblSpeed.Caption:= frmNewQSO.sbNewQSO.Panels[4].Text;
    if (frmCWType <> nil ) then
         frmCWType.UpdateTop;
    key := 0;
    Exit;
   end;


  //S&P mode
  if (key = VK_Tab) then
   begin
     if (Shift = [ssShift]) then  //off
      Begin
          chkSP.Checked:= False;
          key:=0;
          Exit;
      end;
     if (Shift = [ssCTRL]) then  //on
      Begin
          chkSP.Checked:= True;
          key := 0;
          Exit;
      end;
   end;

  if ((Shift = [ssCtrl]) and (key = VK_A)) then
  begin
    frmNewQSO.acAddToBandMap.Execute;
    key := 0;
    Exit;
  end;

  //split keys
   if (Shift = [ssCTRL]) then
    if key in [VK_1..VK_9] then frmNewQSO.SetSplit(chr(key));
  if ((Shift = [ssCTRL]) and (key = VK_0)) then
   begin
    frmTRXControl.DisableSplit;
    key := 0;
    Exit;
   end;

  //Jump to last CQ freq,mode
  if  ((Shift = [ssCTRL]) and (key = VK_L)) then
                          begin
                              lblCqFreqClick(nil);
                              key := 0;
                              Exit;
                          end;

  //tune
   if  ((Shift = [ssCTRL]) and (key = VK_T)) then
                           Begin
                            frmNewQSO.acTuneExecute(nil);
                            Key := 0;
                            Exit;
                           end;
end;

procedure TfrmContest.edtCallExit(Sender: TObject);
var
  dupe : Integer;
begin
  //be sure report is ok for radio mode;
  frmContest.SetActualReportForModeFromRadio;

  // if frmNewQSO is in viewmode or editmode it overwrites old data or will not save
  // because saving is disabled in view mode. this if statement starts a fresh newqso form
  if frmNewQSO.ViewQSO or frmNewQSO.EditQSO then
  begin
    frmNewQSO.Caption := dmUtils.GetNewQSOCaption('New QSO');
    frmNewQSO.UnsetEditLabel;
    frmNewQSO.BringToFront;
    frmNewQSO.ClearAll;
    edtCallExit(nil);
  end;

  frmNewQSO.edtCall.Text := edtCall.Text;

  frmNewQSO.edtHisRST.Text := edtRSTs.Text;
  frmNewQSO.edtContestSerialSent.Text := edtSTX.Text;
  frmNewQSO.edtContestExchangeMessageSent.Text := edtSTXStr.Text;
  //so that CW macros work
  frmNewQSO.edtCallExit(nil);
  frmContest.ShowOnTop;
  frmContest.SetFocus;

   ESMIsDupe := CheckDupe(edtCall.Text);
   if ESMIsDupe then
    Begin
     //send macro F3 - but not under ESM, where the dupe message is one of the
     //things Enter decides to send; firing it here too would double-key it
     if ((not ESMOn) and (not chkSP.Checked) and (length(edtCall.Text)>2)) then
              Begin
                FmemorySent:=true;
                SendFmemory(VK_F3);
              end;
    end;

  ShowStatusBarInfo;
  //Only now does frmNewQSO have the country lookup done, so this is the
  //earliest point the multiplier colour can be decided.
  ShowMultStatus;
  PrefillFromHistory;
  ESMUpdateHint;
end;

procedure TfrmContest.btSaveClick(Sender: TObject);
begin
  if frmNewQSO.AnyRemoteOn then
    begin
      Application.MessageBox('Log is in remote mode, please disable it.','Info ...',mb_ok + mb_IconInformation);
      edtCall.SetFocus;
      exit
    end;
  tmrScore.Enabled:=false;
  if chkLoc.Checked then
   begin
     case MsgIs of
     0:   frmNewQSO.edtName.Caption:=edtSRXStr.Text;             //Name
     1:   if dmUtils.isLocOK(edtSRXStr.Text) then
             frmNewQSO.edtGrid.Text := edtSRXStr.Text;           //Grid copied only if it is valid
     2:   frmNewQSO.cmbIOTA.Caption:= edtSRXStr.Text;            //IOTA
     3:   Begin
              if frmNewQSO.edtState.Visible then
                frmNewQSO.edtState.Caption:= edtSRXStr.Text       //State
               else
                frmNewQSO.edtDOK.Caption:=edtSRXStr.Text;         //DOK
          end;
     4:   frmNewQSO.edtCounty.Caption:= edtSRXStr.Text;          //County
     5:   frmNewQSO.edtAward.Caption:= edtSRXStr.Text;           //Award
     6:   frmNewQSO.edtQSL_VIA.Caption:= edtSRXStr.Text;         //QSL via
     7:   frmNewQSO.edtRemQSO.Caption:=edtSRXStr.Text;           //Comment.
    end;
   end;

  //NOTE! if mode is not in list program dies! In that case skip next
  if frmNewQSO.cmbMode.ItemIndex >=0 then
   begin
     case frmNewQSO.cmbMode.Items[frmNewQSO.cmbMode.ItemIndex] of
       'SSB','AM','FM' :   begin
                             edtRSTs.Text := copy(edtRSTs.Text,0,2);
                             edtRSTr.Text := copy(edtRSTr.Text,0,2);
                           end;
       else
                           begin
                             edtRSTs.Text := copy(edtRSTs.Text,0,3);
                             edtRSTr.Text := copy(edtRSTr.Text,0,3);
                           end;
     end;
   end;

  frmNewQSO.edtHisRST.Text := edtRSTs.Text;
  if chkMarkDupe.Checked and CheckDupe(edtCall.Text) then
        frmNewQSO.edtHisRST.Text:=frmNewQSO.edtHisRST.Text+'/Dupe';
  frmNewQSO.edtMyRST.Text := edtRSTr.Text;
  frmNewQSO.edtContestSerialReceived.Text := edtSRX.Text;
  frmNewQSO.edtContestSerialSent.Text := edtSTX.Text;
  frmNewQSO.edtContestExchangeMessageReceived.Text := edtSRXStr.Text;
  frmNewQSO.edtContestExchangeMessageSent.Text := edtSTXStr.Text;
  frmNewQSO.edtContestName.Text := cmbContestName.Text;

  if (not chkSP.Checked) then
                             SendFmemory(VK_F4);
  frmNewQSO.btnSave.Click;
  if dmData.DebugLevel >= 1 then
    Writeln('input finale');
  ChkSerialNrUpd(chkNRInc.Checked);

  //Score the QSO we just wrote. Appending to the log can only ever change the
  //new row - a dupe or multiplier is decided by what came BEFORE it - so this
  //writes exactly one row, and stamps run/S&P while we still know it.
  if RulesLoaded then
    ScoreContest(cmbContestName.Text,True,Ord(not chkSP.Checked),
                 ScQsos,ScDupes,ScPts,ScM1,ScM2,ScM3);

  tmrScore.Enabled:=true;
  initInput;
end;

procedure TfrmContest.btClearAllClick(Sender: TObject);
var
   f:integer;
begin
  chkTabAll.Checked:=False;
  chkHint.Checked:=True;
  chkSetFilter.Checked:=False;

  rbDupeCheck.Checked := True;
  rbNoMode4Dupe.Checked := False;
  rbIgnoreDupes.Checked := False;

  chkSpace.Checked :=  False;
  chkTrueRST.Checked := False;
  chkNRInc.Checked := False;
  chkQsp.Checked := False;
  chkSP.Checked:=True;       //this prevents automated release of Messages F2..F4 by accident
  chkNoNr.Checked := False;
  chkLoc.Checked := False;

  edtSTX.Text := '';
  edtSTXStr.Text := '';
  cmbContestName.Text:= '';

  for f:=0 to 8 do
     popCommonStatus.Items[f].Checked:=True;
end;

procedure TfrmContest.btDupChkStartClick(Sender: TObject);
begin
  cdDupeDate.Date := StrToDate(DupeFromDate,'-');
  if cdDupeDate.Execute then
    begin
      DupeFromDate:=FormatDateTime( 'yyyy-mm-dd',cdDupeDate.Date );
      cqrini.WriteString('frmContest', 'DupeFrom', DupeFromDate);
      btDupChkStart.Caption:=DupeFromDate;
    end

end;

procedure TfrmContest.btnCQstartClick(Sender: TObject);
begin
    if btnCQstart.Font.Color = clGreen then
     begin
      CQstart(true);
      lblCqMode.Caption:=frmTRXControl.GetRawMode;
      lblCqFreq.Caption := FormatFloat('0.00',frmTRXControl.GetFreqkHz);
      edtCall.SetFocus;
     end
  else
     Cqstart(false);
end;

procedure TfrmContest.CQstart(start:boolean);
begin
    if start and (tmrCQ.Enabled=False) then
   Begin
     btnCQstart.Font.Color:=clRed;
     btnCQstart.Repaint;
     tmrCQ.Enabled:=True;
     tmrCQTimer(nil);
   end
  else
   Begin
     if (tmrCQ.Enabled=True) then
      begin
       btnCQstart.Font.Color:=clGreen;
       btnCQstart.Repaint;
       tmrCQ.Enabled:=false;
       CQcount:=0;
       btnCQstart.Caption:='CQ start';
       if Assigned(frmNewQSO.CWint) then
        frmNewQSO.CWint.StopSending;
      end;
   end;
end;
 
procedure TfrmContest.tmrCQTimer(Sender: TObject);
begin
  if (CQcount<spCQrepeat.Value) then
     Begin
      inc(CQcount);
      btnCQstart.Caption:='CQ '+IntToStr(CQcount);
      SendFmemory(VK_F1);
      exit;
     end;
  CQstart(false);
end;

procedure TfrmContest.spCQperiodChange(Sender: TObject);
begin
    tmrCQ.Interval:=spCQperiod.Value;
end;

procedure TfrmContest.btClearQsoClick(Sender : TObject);
begin
  frmNewQSO.ClearAll;
  initInput
end;

procedure TfrmContest.chkHintChange(Sender: TObject);
var
   i      :integer;
   chk,rb :TCheckBox;
   b      :boolean;

begin
   b:=cmbContestName.ShowHint;
   try
    for i := 0 to frmContest.ComponentCount - 1 do
    begin
      if frmContest.Components[i] is TCheckBox then
      begin
        chk := frmContest.Components[i] as TCheckBox;
        chk.ShowHint:=not b ;
      end;
    end;
    spCQperiod.ShowHint:=not b;
    spCQrepeat.ShowHint:=not b;
    btnCQStart.ShowHint:=not b;
    rbDupeCheck.ShowHint:=not b;
    btDupChkStart.ShowHint:=not b;
    rbNoMode4Dupe.ShowHint:=not b;
    rbIgnoreDupes.ShowHint:=not b;;
    cmbContestName.ShowHint:=not b;
    mStatus.ShowHint:=not b;
    lblCqMode.ShowHint:=not b;
    lblCqFreq.ShowHint:=not b;
    lblQSOSince.ShowHint:=not b;
    lblRate10.ShowHint:=not b;
    lblRate60.ShowHint:=not b;
   finally
   end;
end;

procedure TfrmContest.chkNoNrChange(Sender: TObject);
Begin
  SetTabOrders;
end;

procedure TfrmContest.chkNRIncChange(Sender: TObject);
begin
  if chkNRInc.Checked then
          chkNRString.Checked := False;
  SetTabOrders;
end;

procedure TfrmContest.chkNRIncClick(Sender : TObject);
begin
  if chkNRInc.Checked and (edtSTX.Text = '') then
    begin
      edtSTX.Text := '001';
      edtCall.SetFocus
    end
end;

procedure TfrmContest.chkNRStringChange(Sender: TObject);
begin
  if chkNRString.Checked then
               Begin
                   chkNRInc.Checked:=false;
                   edtSTX.Text:='';
                   edtSRX.Text:='';
               end;

end;

procedure TfrmContest.chkQspChange(Sender: TObject);
begin
  SetTabOrders;
end;

procedure TfrmContest.chkSetFilterClick(Sender: TObject);

begin
  if chkSetFilter.Checked then
   Begin
    if(cmbContestName.Text <>'') then
     Begin
      dmData.qCQRLOG.Close;
      dmData.qCQRLOG.SQL.Text :=  'SELECT * FROM view_cqrlog_main_by_qsodate WHERE contestname='
                                   + QuotedStr(cmbContestName.Text);
      if dmData.DebugLevel >=1 then
        Writeln(dmData.qCQRLOG.SQL.Text);
      if dmData.trCQRLOG.Active then
        dmData.trCQRLOG.Rollback;
      dmData.trCQRLOG.StartTransaction;
      dmData.qCQRLOG.Open;
      dmData.IsFilter := True;
      frmMain.sbMain.Panels[2].Text := 'Filter is ACTIVE!';
      WasContestName:=cmbContestName.Text;
     end;
   end
  else
   if dmData.IsFilter then
        frmMain.acCancelFilterExecute(nil);

  if ContestReady then
                edtCall.SetFocus;
end;

procedure TfrmContest.chkSetFilterMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button=mbRight) and chkSetFIlter.Checked then
   Begin
    AdifExp.Checked:=False;
    AdifExp.ShortCut:=0000;
    CabrilloExp.Checked:=False;
    EdiExp.Checked:=False;
    popQuickExport.PopUp;
   end;
end;

procedure TfrmContest.chkSpaceChange(Sender: TObject);
begin

end;

procedure TfrmContest.chkSPClick(Sender: TObject);
begin
     if chkSP.Checked then
     Begin
        lblCall.Font.Color:=clRed;
        lblRSTs.Font.Color:=clRed;
        lblNRs.Font.Color:=clRed;
        lblMSGs.Font.Color:=clRed;
     end
    else
     Begin
        lblCall.Font.Color:=clGreen;
        lblRSTs.Font.Color:=clGreen;
        lblNRs.Font.Color:=clGreen;
        lblMSGs.Font.Color:=clGreen;
     end;
   cqrini.WriteBool('CW','S&P',chkSP.Checked);
   frmNewQSO.UpdateFKeyLabels;
   //Run and S&P walk different ESM paths, so a mid-QSO switch has to start
   //that QSO's beat count over rather than carry it across.
   ESMBeat := 0;
   ESMUpdateHint;
end;

procedure TfrmContest.chkTrueRSTChange(Sender: TObject);
begin
  SetTabOrders;
end;

procedure TfrmContest.chkTabAllChange(Sender: TObject);
begin
  SetTabOrders;
end;

procedure TfrmContest.cmbContestNameChange(Sender: TObject);

begin
  cmbContestName.Caption:= dmUtils.NoNonAsciiChrs(cmbContestName.Caption,True);
  //cmbContestName.SelStart:=length(cmbContestName.Caption);
end;

procedure TfrmContest.cmbContestNameEnter(Sender: TObject);
begin
  tmrScore.Enabled:=False;
  WasContestName:=cmbContestName.Text;
end;

procedure TfrmContest.cmbContestNameExit(Sender: TObject);
var
   f: integer;

begin
    cmbContestName.Text:= Trim(ExtractWord(1,cmbContestName.Text,['|']));

    if (cmbContestName.Text='') then
       begin
         UseStatus:=-1; //no Contest name, noStatus
         mStatus.Clear;
         sgStatus.Visible:=False;
         gbStatus.Visible:=False;
         if chkSetFilter.Checked then
             chkSetFilter.Checked:=false;
         WasContestName:='';
         tmrScore.Enabled:=False;
         Exit;
       end;

    gbStatus.Visible:=True;

    //this happen when Contest window is opened with saved value of SetFilter and ContestName
    if  chkSetFilter.Checked and (not dmData.IsFilter) and ContestReady then
             chkSetFilterClick(nil);

    //contest name changed while filter was active
    if (WasContestName <> cmbContestName.Text) and chkSetFilter.Checked and dmData.IsFilter  then
             chkSetFilterClick(nil);

    if ((pos('MWC',uppercase(cmbContestName.Text))>0)
     or (pos('OK1WC',uppercase(cmbContestName.Text))>0)) then
      Begin
        if (WasContestNameChange <> cmbContestName.Text) then
         Begin //do some presets
           frmTRXControl.DisableRitXit;
           chkSpace.Checked:=true;
           chkTrueRST.Checked:=false;
           chkNRInc.Checked:=true;
           chkQsp.Checked:=false;
           chkSP.Checked:=true;
           chkNoNr.Checked:=false;
           chkLoc.Checked:=false;
           rbDupeCheck.Checked:=true;
           chkMarkDupe.Checked:=true;
           chkHint.Checked:=false;
           chkNRString.Checked:=false;
           WasContestNameChange :=cmbContestName.Text
         end;
        UseStatus:=1; //OK1WC memorial contest
        MWCStatus;
        tmrScore.Enabled:=True;
        Exit;
      end;

    if (pos('NAC',uppercase(cmbContestName.Text))>0) then
      Begin
        if (WasContestNameChange <> cmbContestName.Text) then
         Begin //do some presets
           frmTRXControl.DisableRitXit;
           mnuGridClick(nil);
           chkSpace.Checked:=true;
           chkTrueRST.Checked:=false;
           chkNRInc.Checked:=false;
           edtSTX.Text:='';
           edtSTXStr.Text:='';
           chkQsp.Checked:=false;
           chkSP.Checked:=true;
           chkNoNr.Checked:=true;
           chkLoc.Checked:=true;
           rbDupeCheck.Checked:=true;
           chkMarkDupe.Checked:=true;
           chkHint.Checked:=false;
           chkNRString.Checked:=false;
           WasContestNameChange :=cmbContestName.Text
         end;
        UseStatus:=2; //Nordic V,U,SHF activity contest
        NACStatus;
        tmrScore.Enabled:=True;
        Exit;
      end;

    if ((pos('SRAL',uppercase(cmbContestName.Text))>0)
     and (pos('FT8',uppercase(cmbContestName.Text))>0)) then
      Begin
        if (WasContestNameChange <> cmbContestName.Text) then
         Begin //do some presets
           frmTRXControl.DisableRitXit;
           mnuGridClick(nil);
           chkSpace.Checked:=true;
           chkTrueRST.Checked:=false;
           chkNRInc.Checked:=false;
           edtSTX.Text:='';
           edtSTXStr.Text:='';
           chkQsp.Checked:=false;
           chkSP.Checked:=true;
           chkNoNr.Checked:=true;
           chkLoc.Checked:=true;
           rbDupeCheck.Checked:=true;
           chkMarkDupe.Checked:=true;
           chkHint.Checked:=false;
           chkNRString.Checked:=false;
           WasContestNameChange :=cmbContestName.Text
         end;
        UseStatus:=3; //SRAL FT8 contest for OH stations
        SRALFt8Status;
        tmrScore.Enabled:=True;
        Exit;
      end;

    {
    //if you create a Status procedure you can call it here
    if (pos('xxxx',uppercase(cmbContestName.Text))>0) then
      Begin
        UseStatus:=4; //Next status counting procedure to be #4
        xxxxStatus;
        Exit;
      end;
     }
     if (WasContestNameChange <> cmbContestName.Text) then
     begin
        frmTRXControl.DisableRitXit;
        //Reload the rule file only when the contest actually changed, so the
        //score timer is not re-reading it off disk every few seconds.
        LoadContestRules
     end;
     WasContestNameChange :=cmbContestName.Text;

     //A contest with a definition file scores itself; everything else falls
     //through to the generic counters exactly as before.
     //Tell the ecosystem which contest is now live. N1MM sends AppInfo on
     //program start and whenever the contest selection changes.
     N1MMUdp.Configure;
     N1MMUdp.SendAppInfo(dmData.DBName,cmbContestName.Text,
                         dmUtils.GetHostName,
                         UpperCase(cqrini.ReadString('Station','Call','')),1);

     if RulesLoaded then
     begin
       UseStatus:=5;
       sgStatus.Visible:=False;
       RulesStatus;
       tmrScore.Enabled:=True;
       Exit
     end;

     UseStatus:=0;  //Common status display for contests where name is not '' and does not fit to any above
     for f:=10 to 20 do
      sgStatus.Columns.Items[f-9].Visible:=popCommonStatus.Items[f].Checked;
     tmrScore.Enabled:=True;
     CommonStatus;
end;

procedure TfrmContest.edtRSTrEnter(Sender: TObject); //launch memory key F2 when RSTr,NRr or MSGr is entered
begin
   if FmemorySent then exit;
   //Under ESM the exchange goes out on Enter, not on arriving in this field.
   if ESMOn then exit;

    //send macro F2
    if ((not chkSP.Checked) and (length(edtCall.Text)>2)) then
             Begin
                FmemorySent:=true;
                SendFmemory(VK_F2);
              end;
end;

procedure TfrmContest.edtRSTsEnter(Sender: TObject);
begin
  if chkTrueRST.Checked then
     Begin
          edtRSTs.Text:='';
          edtRSTr.Text:='';
     end;
end;

procedure TfrmContest.edtSRXStrKeyPress(Sender: TObject; var Key: char);
begin
   if ((chkLoc.Checked) and (MsgIs=1 ))then
                         dmUtils.KeyInLoc(edtSRXStr.Text,Key);
end;

procedure TfrmContest.edtSTXStrChange(Sender: TObject);
begin
  edtSTXStr.Text := dmUtils.NoNonAsciiChrs(edtSTXStr.Text, true);
  edtSTXStr.SelStart:=length(edtSTXStr.Text);
end;

procedure TfrmContest.edtSTXStrKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   if ((Key = VK_SPACE) and (chkSpace.Checked)) then
  begin
    Key := 0;
    SelectNext(Sender as TWinControl, True, True);
  end;
end;

procedure TfrmContest.lblCqFreqClick(Sender: TObject);
var
   f:double;
Begin
 if TryStrToFloat(lblCqFreq.Caption,f) then
     frmtrxcontrol.SetModeFreq(lblCqMode.Caption,lblCqFreq.Caption);
end;

procedure TfrmContest.edtCallChange(Sender: TObject);
begin
  //A different station means a fresh QSO: restart the beat count so a
  //corrected callsign cannot inherit the previous station's progress.
  ESMBeat := 0;
  CQstart(false);
  if frmSCP.Showing then
    frmSCP.UpdateCheck(edtCall.Text);
  //This is the one place the dupe query already runs per keystroke; cache it
  //so ESMUpdateHint does not fire a second WkdCall lookup on every character.
  ESMIsDupe := CheckDupe(edtCall.Text);
  ESMUpdateHint;
  if not (edtCall.Text='') then //This prevents focus move to NewQSO when edtCall deleted to empty
      frmNewQSO.edtCall.text:=edtCall.Text;

end;

procedure TfrmContest.edtCallKeyDown(Sender: TObject; var Key: word;
  Shift: TShiftState);
begin
  if ((Key = VK_SPACE) and (chkSpace.Checked)) then
  begin
    Key := 0;
    SelectNext(Sender as TWinControl, True, True);
  end;

  if not (key in [VK_A..VK_Z, VK_0..VK_9, VK_NUMPAD0..VK_NUMPAD9,
    VK_TAB, VK_LCL_SLASH, VK_DELETE,VK_BACK,VK_RIGHT,VK_LEFT,
    VK_HOME,VK_DIVIDE, VK_END]) then
     key := 0;

  if (Shift = [ssCTRL]) then
    if key in [VK_A..VK_Z] then  Key:=0;
end;

procedure TfrmContest.edtCallKeyPress(Sender: TObject; var Key: char);
begin
  if not (key in ['a'..'z','A'..'Z', '0'..'9',
    '/',#08]) then
    key := #0;
end;

procedure TfrmContest.edtSRXChange(Sender: TObject);
begin
  frmNewQSO.edtContestSerialReceived.Text:=edtSRX.Text;
  //Copying his number is what flips the pending action from AGN? to TU+log,
  //so the hint has to follow the keystrokes, not just the Enters.
  ESMUpdateHint;
end;

procedure TfrmContest.edtSRXStrChange(Sender: TObject);
var
   Key:char;
begin
  edtSRXStr.Text := dmUtils.NoNonAsciiChrs(edtSRXStr.Text, true);
  edtSRXStr.SelStart:=length(edtSRXStr.Text);
  if ((chkLoc.Checked) and (MsgIs=1 ))then
  begin
   edtSRXStr.Text := dmUtils.StdFormatLocator(edtSRXStr.Text);
   edtSRXStr.SelStart := Length(edtSRXStr.Text);
   edtSRXStr.SelLength:=0;
   if ( Length(edtSRXStr.Text) in [1,3,5] )then
       edtSRXStr.Font.Color:=clRed
      else
       edtSRXStr.Font.Color:=clDefault;
   if ( Length(edtSRXStr.Text) > 6 )then
          edtSRXStr.Text:=copy(edtSRXStr.Text,1,6); //accept only 6chr locator input here
  end;
  frmNewQSO.edtContestExchangeMessageReceived.Text:=edtSRXStr.Text;
end;
procedure TfrmContest.edtSRXExit(Sender: TObject);
begin
  ChkSerialNrUpd(False); //just save it
end;

procedure TfrmContest.edtSTXStrEnter(Sender: TObject);
begin
  if chkQsp.Checked then
   QspMsg;
end;

procedure TfrmContest.edtSTXStrExit(Sender: TObject);
begin
  ChkSerialNrUpd(False); //just save it
end;

procedure TfrmContest.edtSTXExit(Sender: TObject);
begin
  ChkSerialNrUpd(False); //just save it
end;

procedure TfrmContest.edtSTXKeyPress(Sender: TObject; var Key: char);
begin
  if chkNRString.Checked then
   begin
    if not (key in ['0'..'9','A'..'Z','a'..'z', chr(VK_SPACE), chr(VK_DELETE), chr(VK_BACK),
    chr(VK_RIGHT), chr(VK_LEFT)]) then
                                  key := #0;
   end
  else
   begin
    if not (key in ['0'..'9', chr(VK_SPACE), chr(VK_DELETE), chr(VK_BACK),
    chr(VK_RIGHT), chr(VK_LEFT)]) then
                                  key := #0;
   end;
end;

procedure TfrmContest.FormCreate(Sender: TObject);
begin
  ContestReady:=False;
  WasContestName:='';
  WasContestNameChange:='';
  frmContest.KeyPreview := True;
  dmUtils.InsertContests(cmbContestName);
  sgStatus.Cells[0,0]:='Settings';
  sgStatus.Cells[0,1]:='QSOs';
  sgStatus.Cells[0,2]:='DXs';
  sgStatus.Cells[0,3]:='Ctrys';
  sgStatus.Cells[0,4]:='DXCtrys';
  sgStatus.Cells[0,5]:='OwnCtrys';
  sgStatus.Cells[0,6]:='MMults';
  sgStatus.Cells[0,7]:='Dupes';
  sgStatus.ColWidths[0]:=80;
end;
procedure TfrmContest.SaveSettings;
var
  f       :integer;
begin
  dmUtils.SaveWindowPos(Self);
  cqrini.WriteString('frmContest', 'ContestName', cmbContestName.Text);

  cqrini.WriteBool('frmContest', 'TabAll', chkTabAll.Checked);
  cqrini.WriteBool('frmContest', 'ShowHint', chkHint.Checked);
  cqrini.WriteBool('frmContest', 'SetFilter', chkSetFilter.Checked);
  cqrini.WriteInteger('frmContest','CQperiod',spCQperiod.Value);
  cqrini.WriteInteger('frmContest','CQrepeat',spCQrepeat.Value);

  cqrini.WriteBool('frmContest', 'DupeCheck', rbDupeCheck.Checked);
  cqrini.WriteBool('frmContest', 'NoMode4Dupe', rbNoMode4Dupe.Checked);
  cqrini.WriteBool('frmContest', 'IgnoreDupes', rbIgnoreDupes.Checked);
  cqrini.WriteString('frmContest', 'DupeFrom', DupeFromDate);
  cqrini.WriteBool('frmContest', 'MarkDupe', chkMarkDupe.Checked);

  cqrini.WriteBool('frmContest', 'SpaceIsTab', chkSpace.Checked);
  cqrini.WriteBool('frmContest', 'TrueRST', chkTrueRST.Checked);
  cqrini.WriteBool('frmContest', 'NRInc', chkNRInc.Checked);
  cqrini.WriteBool('frmContest', 'NRString', chkNRString.Checked);
  cqrini.WriteBool('frmContest', 'QSP', chkQsp.Checked);
  cqrini.WriteBool('frmContest', 'NoNR', chkNoNr.Checked);
  cqrini.WriteBool('frmContest', 'Loc', chkLoc.Checked);
  cqrini.WriteString('frmContest','MsgIsStr',chkLoc.Caption);
  cqrini.WriteInteger('frmContest','MsgIs',MsgIs);

  cqrini.WriteString('frmContest', 'STX', edtSTX.Text);
  cqrini.WriteString('frmContest', 'STXStr', edtSTXStr.Text);

  cqrini.WriteBool('frmContest', 'SP', chkSP.Checked);

  cqrini.WriteBool('frmContest', 'mnuQSOcount',mnuQSOcount.Checked);
  cqrini.WriteBool('frmContest', 'mnuDXQSOCount',mnuDXQSOCount.Checked);
  cqrini.WriteBool('frmContest', 'mnuCountyrCountAll',mnuCountyrCountAll.Checked);
  cqrini.WriteBool('frmContest', 'mnuDXCountryCount',mnuDXCountryCount.Checked);
  cqrini.WriteBool('frmContest', 'mnuDXCountryList',mnuDXCountryList.Checked);
  cqrini.WriteBool('frmContest', 'mnuDXCountryList',mnuDXCountryList.Checked);
  cqrini.WriteBool('frmContest', 'mnuOwnCountryList',mnuOwnCountryList.Checked);
  cqrini.WriteBool('frmContest', 'mnuMsgMultipCount',mnuMsgMultipCount.Checked);
  cqrini.WriteBool('frmContest', 'mnuMsgMultipList',mnuMsgMultipList.Checked);
  cqrini.WriteBool('frmContest', 'mnuModeRelated',mnuModeRelated.Checked);
  cqrini.WriteBool('frmContest', 'Band_160',Band_160.Checked);
  cqrini.WriteBool('frmContest', 'Band_80',Band_80.Checked);
  cqrini.WriteBool('frmContest', 'Band_40',Band_40.Checked);
  cqrini.WriteBool('frmContest', 'Band_20',Band_20.Checked);
  cqrini.WriteBool('frmContest', 'Band_15',Band_15.Checked);
  cqrini.WriteBool('frmContest', 'Band_10',Band_10.Checked);
  cqrini.WriteBool('frmContest', 'Band_6',Band_6.Checked);
  cqrini.WriteBool('frmContest', 'Band_4',Band_4.Checked);
  cqrini.WriteBool('frmContest', 'Band_2',Band_2.Checked);
  cqrini.WriteBool('frmContest', 'Band_070',Band_070.Checked);
  cqrini.WriteBool('frmContest', 'Band_023',Band_023.Checked);


end;
procedure TfrmContest.FormClose(Sender: TObject; var CloseAction: TCloseAction);
Begin
   ContestReady:=False;
   SaveSettings;
   cqrini.WriteBool('CW','S&P',True);  //set default CW memories
   frmNewQSO.UpdateFKeyLabels;
   tmrScore.Enabled:=false;
   tmrESC2.Enabled:=false;
   tmrCQ.Enabled:=false;
   if dmData.IsFilter then
        frmMain.acCancelFilterExecute(nil);
end;

procedure TfrmContest.FormHide(Sender: TObject);
begin
  frmNewQSO.gbContest.Visible := false;
  dmUtils.SaveWindowPos(Self);
  tmrScore.Enabled:=false;
  tmrESC2.Enabled:=false;
  tmrCQ.Enabled:=false;
  frmContest.Hide;
end;

procedure TfrmContest.FormShow(Sender: TObject);
var
  f: integer;

begin
  frmNewQSO.gbContest.Visible := true;
  dmUtils.LoadWindowPos(Self);

  chkTabAll.Checked         := cqrini.ReadBool('frmContest', 'TabAll', False);
  chkHint.Checked           := cqrini.ReadBool('frmContest', 'ShowHint', True);
  spCQperiod.Value          :=cqrini.ReadInteger('frmContest','CQperiod',5000);
  spCQrepeat.Value          :=cqrini.ReadInteger('frmContest','CQrepeat',1);

  rbDupeCheck.Checked       := cqrini.ReadBool('frmContest', 'DupeCheck', True);
  rbNoMode4Dupe.Checked     := cqrini.ReadBool('frmContest', 'NoMode4Dupe', False);
  rbIgnoreDupes.Checked     := cqrini.ReadBool('frmContest', 'IgnoreDupes', False);
  DupeFromDate              := cqrini.ReadString('frmContest', 'DupeFrom', FormatDateTime( 'yyyy-mm-dd',now() ));
  chkMarkDupe.Checked       := cqrini.ReadBool('frmContest', 'MarkDupe', True);
  chkSpace.Checked          := cqrini.ReadBool('frmContest', 'SpaceIsTab', False);
  chkTrueRST.Checked        := cqrini.ReadBool('frmContest', 'TrueRST', False);
  chkNRInc.Checked          := cqrini.ReadBool('frmContest', 'NRInc', False);
  chkNRString.Checked        := cqrini.ReadBool('frmContest', 'NRString', False);
  chkQsp.Checked            := cqrini.ReadBool('frmContest', 'QSP', False);
  chkNoNr.Checked           := cqrini.ReadBool('frmContest', 'NoNR', False);
  chkLoc.Checked            := cqrini.ReadBool('frmContest', 'Loc', False);
  chkLoc.Caption            :=cqrini.ReadString('frmContest','MsgIsStr','MSG is Grid');
  MsgIs                     :=cqrini.ReadInteger('frmContest','MsgIs',1); //defaults to MSG is Grid
  chkSP.Checked             := cqrini.ReadBool('frmContest', 'SP', False);
  ESMCreateControls;

  edtSTX.Text               := cqrini.ReadString('frmContest', 'STX', '');
  ResetStx                  := edtSTX.Text;
  edtSTXStr.Text            := cqrini.ReadString('frmContest', 'STXStr', '');
  ResetStxStr               := edtSTXStr.Text;

  popSetMsg.Items[MsgIs].Checked:=true;

  mnuQSOcount.Checked       :=cqrini.ReadBool('frmContest', 'mnuQSOcount',True);
  mnuDXQSOCount.Checked     :=cqrini.ReadBool('frmContest', 'mnuDXQSOCount',True);
  mnuCountyrCountAll.Checked:=cqrini.ReadBool('frmContest', 'mnuCountyrCountAll',True);
  mnuDXCountryCount.Checked :=cqrini.ReadBool('frmContest', 'mnuDXCountryCount',True);
  mnuDXCountryList.Checked  :=cqrini.ReadBool('frmContest', 'mnuDXCountryList',True);
  mnuDXCountryList.Checked  :=cqrini.ReadBool('frmContest', 'mnuDXCountryList',True);
  mnuOwnCountryList.Checked :=cqrini.ReadBool('frmContest', 'mnuOwnCountryList',True);
  mnuMsgMultipCount.Checked :=cqrini.ReadBool('frmContest', 'mnuMsgMultipCount',True);
  mnuMsgMultipList.Checked  :=cqrini.ReadBool('frmContest', 'mnuMsgMultipList',True);
  mnuModeRelated.Checked    :=cqrini.ReadBool('frmContest', 'mnuModeRelated',True);
  Band_160.Checked          :=cqrini.ReadBool('frmContest', 'Band_160',True);
  Band_80.Checked           :=cqrini.ReadBool('frmContest', 'Band_80',True);
  Band_40.Checked           :=cqrini.ReadBool('frmContest', 'Band_40',True);
  Band_20.Checked           :=cqrini.ReadBool('frmContest', 'Band_20',True);
  Band_15.Checked           :=cqrini.ReadBool('frmContest', 'Band_15',True);
  Band_10.Checked           :=cqrini.ReadBool('frmContest', 'Band_10',True);
  Band_6.Checked            :=cqrini.ReadBool('frmContest', 'Band_6',True);
  Band_4.Checked            :=cqrini.ReadBool('frmContest', 'Band_4',True);
  Band_2.Checked            :=cqrini.ReadBool('frmContest', 'Band_2',True);
  Band_070.Checked          :=cqrini.ReadBool('frmContest', 'Band_070',True);
  Band_023.Checked          :=cqrini.ReadBool('frmContest', 'Band_023',True);

  sbContest.Panels[0].Width := 450;
  sbContest.Panels[1].Width := 65;
  sbContest.Panels[2].Width := 65;
  sbContest.Panels[3].Width := 65;
  sbContest.Panels[4].Width := 20;
  lblSpeed.Caption:= frmNewQSO.sbNewQSO.Panels[4].Text;
  cmbContestName.Text := cqrini.ReadString('frmContest', 'ContestName','');
  btDupChkStart.Caption := DupeFromDate;
  btDupChkStart.Visible:=not(rbIgnoreDupes.Checked);
  MWC40:=0;
  MWC80:=0;

  MyAdif:= dmDXCC.id_country(cqrini.ReadString('Station', 'Call', ''), Now(), Mypfx, Mycont,  Mycountry, MyWAZ, Myposun, MyITU, Mylat, Mylong);
  //Hand my own entity to the tracker so the spot threads can evaluate
  //"EU only"/"DX only" rules without reaching into this form.
  MultTracker.SetMyStation(Mypfx,Mycont);
  mnuOwnCountryCount.Caption:=Mycont+' country count';
  mnuOwnCountryList.Caption:=Mycont+' country list';
  FmemorySent:=False;

  tmrCQ.Enabled:=False;
  tmrCQ.Interval:=spCQperiod.Value;
  tmrScore.Enabled:=(cmbContestName.Text<>'');
  CQcount:=0;
  chkSPClick(nil); //to set the right color to TX labels
  sgStatus.Visible:=False;

  InitInput;

  cmbContestName.Text       := cqrini.ReadString('frmContest', 'ContestName', '');
  chkSetFilter.Checked      := cqrini.ReadBool('frmContest', 'SetFilter', False);
  ContestReady:=True; //indicates that all values are loaded and ready to go
end;

procedure TfrmContest.MsgIsPopChk(nr:integer);
var i:integer ;
begin
   for i:=0 to popSetMsg.Items.Count-1 do
       popSetMsg.Items[i].Checked:=false;
   popSetMsg.Items[nr].Checked:=true;
end;

procedure TfrmContest.btnHelpClick(Sender : TObject);
begin
  ShowHelp
end;

procedure TfrmContest.mnuQSOcountClick(Sender: TObject);   //This works for all selections
var
   f:integer;
   p:TPoint;
Begin
  p:=popCommonStatus.PopupPoint;
  TMenuitem(Sender).checked:= not TMenuitem(Sender).checked;
  for f:=10 to 20 do                                            //redefine sgStatus grid's band columns visible
     sgStatus.Columns.Items[f-9].Visible:=popCommonStatus.Items[f].Checked;
  popCommonStatus.PopUp(p.x,p.y);
  //frmContest.Left,frmContest.Top);
end;

procedure TfrmContest.mnuReSetAllCountersClick(Sender: TObject);     //9
var
    f: integer;
    b: boolean;
    p:TPoint;
Begin
  p:=popCommonStatus.PopupPoint;
  b:= not popCommonStatus.Items[0].Checked;
  for f:=0 to 8 do
    popCommonStatus.Items[f].Checked:=b;
  popCommonStatus.PopUp(p.x,p.y);
end;

procedure TfrmContest.mnuReSetAllHFClick(Sender: TObject);
var
    f: integer;
    b: boolean;
    p:TPoint;
Begin
  p:=popCommonStatus.PopupPoint;
   b:= not popCommonStatus.Items[10].Checked;
   for f:=10 to 15 do
    begin
     popCommonStatus.Items[f].Checked:=b;
     sgStatus.Columns.Items[f-9].Visible:=popCommonStatus.Items[f].Checked;
    end;
  popCommonStatus.PopUp(p.x,p.y);
end;

procedure TfrmContest.mnuReSetAllVHFClick(Sender: TObject);
var
    f: integer;
    b: boolean;
    p:TPoint;
Begin
  p:=popCommonStatus.PopupPoint;
   b:= not popCommonStatus.Items[16].Checked;
   for f:=16 to 20 do
     begin
      popCommonStatus.Items[f].Checked:=b;
      sgStatus.Columns.Items[f-9].Visible:=popCommonStatus.Items[f].Checked;
     end;
   popCommonStatus.PopUp(p.x,p.y);
end;

procedure TfrmContest.SaveClick(Sender: TObject);            //11
var
  CTST : TIniFile;
  f:integer;
begin
  SaveDialog1.InitialDir := dmData.HomeDir;
  if SaveDialog1.Execute then
  begin
    if pos('.',SaveDialog1.FileName)=0 then
            SaveDialog1.FileName:=SaveDialog1.FileName+'.ctst'; //in case no extension
    CTST := TIniFile.Create(SaveDialog1.FileName);
    try
      CTST.WriteString('frmContest', 'ContestName', cmbContestName.Text);

      CTST.WriteBool('frmContest', 'SetFilter', chkSetFilter.Checked);
      CTST.WriteBool('frmContest', 'TabAll', chkTabAll.Checked);
      CTST.WriteBool('frmContest', 'ShowHint', chkHint.Checked);
      CTST.WriteInteger('frmContest','CQperiod',spCQperiod.Value);
      CTST.WriteInteger('frmContest','CQrepeat',spCQrepeat.Value);

      CTST.WriteBool('frmContest', 'DupeCheck', rbDupeCheck.Checked);
      CTST.WriteBool('frmContest', 'NoMode4Dupe', rbNoMode4Dupe.Checked);
      CTST.WriteBool('frmContest', 'IgnoreDupes', rbIgnoreDupes.Checked);
      CTST.WriteString('frmContest', 'DupeFrom', DupeFromDate);
      CTST.WriteBool('frmContest', 'MarkDupe', chkMarkDupe.Checked);

      CTST.WriteBool('frmContest', 'SpaceIsTab', chkSpace.Checked);
      CTST.WriteBool('frmContest', 'TrueRST', chkTrueRST.Checked);
      CTST.WriteBool('frmContest', 'NRInc', chkNRInc.Checked);
      CTST.WriteBool('frmContest', 'NString', chkNRString.Checked);

      CTST.WriteBool('frmContest', 'QSP', chkQsp.Checked);
      CTST.WriteBool('frmContest', 'NoNR', chkNoNr.Checked);
      CTST.WriteBool('frmContest', 'Loc', chkLoc.Checked);
      CTST.WriteString('frmContest','MsgIsStr',chkLoc.Caption);
      CTST.WriteInteger('frmContest','MsgIs',MsgIs);

      CTST.WriteString('frmContest', 'STX', edtSTX.Text);
      CTST.WriteString('frmContest', 'STXStr', edtSTXStr.Text);
      CTST.WriteBool('frmContest', 'SP', chkSP.Checked);

      CTST.WriteBool('frmContest', 'mnuQSOcount',mnuQSOcount.Checked);
      CTST.WriteBool('frmContest', 'mnuDXQSOCount',mnuDXQSOCount.Checked);
      CTST.WriteBool('frmContest', 'mnuCountyrCountAll',mnuCountyrCountAll.Checked);
      CTST.WriteBool('frmContest', 'mnuDXCountryCount',mnuDXCountryCount.Checked);
      CTST.WriteBool('frmContest', 'mnuDXCountryList',mnuDXCountryList.Checked);
      CTST.WriteBool('frmContest', 'mnuDXCountryList',mnuDXCountryList.Checked);
      CTST.WriteBool('frmContest', 'mnuOwnCountryList',mnuOwnCountryList.Checked);
      CTST.WriteBool('frmContest', 'mnuMsgMultipCount',mnuMsgMultipCount.Checked);
      CTST.WriteBool('frmContest', 'mnuMsgMultipList',mnuMsgMultipList.Checked);
      CTST.WriteBool('frmContest', 'mnuModeRelated',mnuModeRelated.Checked);
      CTST.WriteBool('frmContest', 'Band_160',Band_160.Checked);
      CTST.WriteBool('frmContest', 'Band_80',Band_80.Checked);
      CTST.WriteBool('frmContest', 'Band_40',Band_40.Checked);
      CTST.WriteBool('frmContest', 'Band_20',Band_20.Checked);
      CTST.WriteBool('frmContest', 'Band_15',Band_15.Checked);
      CTST.WriteBool('frmContest', 'Band_10',Band_10.Checked);
      CTST.WriteBool('frmContest', 'Band_6',Band_6.Checked);
      CTST.WriteBool('frmContest', 'Band_4',Band_4.Checked);
      CTST.WriteBool('frmContest', 'Band_2',Band_2.Checked);
      CTST.WriteBool('frmContest', 'Band_070',Band_070.Checked);
      CTST.WriteBool('frmContest', 'Band_023',Band_023.Checked);


      CTST.UpdateFile;
    finally
      FreeAndNil(CTST);
    end;
  end;
end;

procedure TfrmContest.sgStatusMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var w,h:integer;
begin
  w:=sgStatus.ColWidths[0];
  h:=sgStatus.RowHeights[0];
  if ( (x<w) and (y<h) and (UseStatus=0) ) then
     popCommonStatus.PopUp;
end;

procedure TfrmContest.sgStatusPrepareCanvas(Sender: TObject; aCol,aRow: Integer; aState: TGridDrawState);
var
  f:integer;
  BandColor:TColor;
begin
   if (aCol = 0) and (aRow = 0)then
      sgStatus.Canvas.Brush.Color := clLime;
   for f:=0 to 10 do
    Begin
     if dUtils.cBands[ContestBandPtr[f]] = dmUtils.GetBandFromFreq(frmNewQSO.cmbFreq.Text) then
       Break;  //found current band
    end;
   if dUtils.cBands[ContestBandPtr[f]] <> dmUtils.GetBandFromFreq(frmNewQSO.cmbFreq.Text) then
       exit;   //not in contest band list

   if ((Red(ColorToRGB(GetDefaultColor(dctBrush))))>$77) then
    Begin             //this is selected if background is light
      if cqrini.ReadBool('Fonts', 'GridGreenBar', False) then
       BandColor:=$E1A3A1
      else
       BandColor:=$CCFEFF;
    end
   else
    Begin             //this is selected if background is dark
      if cqrini.ReadBool('Fonts', 'GridGreenBar', False) then
       BandColor:=$054445        //this may need fixing!!!
      else
       BandColor:=$054445;
    end;

   if (aCol = f+2) and ((aRow >= 1) and (aRow <= 7)) then
      sgStatus.Canvas.Brush.Color := BandColor;
end;


procedure TfrmContest.LoadClick(Sender: TObject);          //12
  var
  CTST : TIniFile;
  f    : integer;
begin
 OpenDialog1.InitialDir := dmData.HomeDir;
 if OpenDialog1.Execute then
 begin
   CTST := TIniFile.Create(OpenDialog1.FileName);
   try
      cmbContestName.Text       := CTST.ReadString('frmContest', 'ContestName', '');
      chkSetFilter.Checked      := CTST.ReadBool('frmContest', 'SetFilter',False);
      chkTabAll.Checked         := CTST.ReadBool('frmContest', 'TabAll', False);

      chkHint.Checked           := CTST.ReadBool('frmContest', 'ShowHint', True);
      spCQperiod.Value          := CTST.ReadInteger('frmContest','CQperiod',5000);
      spCQrepeat.Value          := CTST.ReadInteger('frmContest','CQrepeat',1);
      rbDupeCheck.Checked       := CTST.ReadBool('frmContest', 'DupeCheck', True);
      rbNoMode4Dupe.Checked     := CTST.ReadBool('frmContest', 'NoMode4Dupe', False);
      rbIgnoreDupes.Checked     := CTST.ReadBool('frmContest', 'IgnoreDupes', False);
      DupeFromDate              := CTST.ReadString('frmContest', 'DupeFrom', FormatDateTime( 'yyyy-mm-dd',now() ));
      chkMarkDupe.Checked       := CTST.ReadBool('frmContest', 'MarkDupe', True);
      chkSpace.Checked          := CTST.ReadBool('frmContest', 'SpaceIsTab', False);
      chkTrueRST.Checked        := CTST.ReadBool('frmContest', 'TrueRST', False);
      chkNRInc.Checked          := CTST.ReadBool('frmContest', 'NRInc', False);
      chkNRString.Checked       := CTST.ReadBool('frmContest', 'NRString', False);
      chkQsp.Checked            := CTST.ReadBool('frmContest', 'QSP', False);
      chkNoNr.Checked           := CTST.ReadBool('frmContest', 'NoNR', False);
      chkLoc.Checked            := CTST.ReadBool('frmContest', 'Loc', False);
      chkLoc.Caption            := CTST.ReadString('frmContest','MsgIsStr','MSG is Grid');
      MsgIs                     := CTST.ReadInteger('frmContest','MsgIs',1); //defaults to MSG is Grid
      chkSP.Checked             := CTST.ReadBool('frmContest', 'SP', False);
      edtSTX.Text               := CTST.ReadString('frmContest', 'STX', '');
      ResetStx                  := edtSTX.Text;
      edtSTXStr.Text            := CTST.ReadString('frmContest', 'STXStr', '');
      ResetStxStr               := edtSTXStr.Text;

      mnuQSOcount.Checked       :=CTST.ReadBool('frmContest', 'mnuQSOcount',True);
      mnuDXQSOCount.Checked     :=CTST.ReadBool('frmContest', 'mnuDXQSOCount',True);
      mnuCountyrCountAll.Checked:=CTST.ReadBool('frmContest', 'mnuCountyrCountAll',True);
      mnuDXCountryCount.Checked :=CTST.ReadBool('frmContest', 'mnuDXCountryCount',True);
      mnuDXCountryList.Checked  :=CTST.ReadBool('frmContest', 'mnuDXCountryList',True);
      mnuDXCountryList.Checked  :=CTST.ReadBool('frmContest', 'mnuDXCountryList',True);
      mnuOwnCountryList.Checked :=CTST.ReadBool('frmContest', 'mnuOwnCountryList',True);
      mnuMsgMultipCount.Checked :=CTST.ReadBool('frmContest', 'mnuMsgMultipCount',True);
      mnuMsgMultipList.Checked  :=CTST.ReadBool('frmContest', 'mnuMsgMultipList',True);
      mnuModeRelated.Checked    :=CTST.ReadBool('frmContest', 'mnuModeRelated',True);
      Band_160.Checked          :=CTST.ReadBool('frmContest', 'Band_160',True);
      Band_80.Checked           :=CTST.ReadBool('frmContest', 'Band_80',True);
      Band_40.Checked           :=CTST.ReadBool('frmContest', 'Band_40',True);
      Band_20.Checked           :=CTST.ReadBool('frmContest', 'Band_20',True);
      Band_15.Checked           :=CTST.ReadBool('frmContest', 'Band_15',True);
      Band_10.Checked           :=CTST.ReadBool('frmContest', 'Band_10',True);
      Band_6.Checked            :=CTST.ReadBool('frmContest', 'Band_6',True);
      Band_4.Checked            :=CTST.ReadBool('frmContest', 'Band_4',True);
      Band_2.Checked            :=CTST.ReadBool('frmContest', 'Band_2',True);
      Band_070.Checked          :=CTST.ReadBool('frmContest', 'Band_070',True);
      Band_023.Checked          :=CTST.ReadBool('frmContest', 'Band_023',True);
   finally
     FreeAndNil(CTST);
   end;
 end;
end;

procedure TfrmContest.ChangeStatusPop(Sender: TObject);
 Begin
  TMenuitem(Sender).checked:= not TMenuitem(Sender).checked;
  popCommonStatus.PopUp;
 end;

procedure TfrmContest.mnuNameClick(Sender: TObject);
begin
  MsgIs:=0;
  chkLoc.Caption:='MSG is Name';
  MsgIsPopChk(MsgIs);
end;


procedure TfrmContest.mnuGridClick(Sender: TObject);
begin
  MsgIs:=1;
  chkLoc.Caption:='MSG is Grid';
  MsgIsPopChk(MsgIs);
end;

procedure TfrmContest.mnyIOTAClick(Sender: TObject);
begin
  MsgIs:=2;
  chkLoc.Caption:='MSG is IOTA';
  MsgIsPopChk(MsgIs);
end;

procedure TfrmContest.mnuStateClick(Sender: TObject);
begin
  MsgIs:=3;
  chkLoc.Caption:='MSG is Stat';
  MsgIsPopChk(MsgIs);
end;

procedure TfrmContest.mnuCountyClick(Sender: TObject);
begin
    MsgIs:=4;
    chkLoc.Caption:='MSG is Cnty';
    MsgIsPopChk(MsgIs);
end;

procedure TfrmContest.mnuAwardClick(Sender: TObject);
begin
  MsgIs:=5;
  chkLoc.Caption:='MSG is Awrd';
  MsgIsPopChk(MsgIs);
end;

procedure TfrmContest.mnuQSLviaClick(Sender: TObject);
begin
  MsgIs:=6;
  chkLoc.Caption:='MSG is Qvia';
  MsgIsPopChk(MsgIs);
end;

procedure TfrmContest.mnuCommentClick(Sender: TObject);
begin
  MsgIs:=7;
  chkLoc.Caption:='MSG is Cmnt';
  MsgIsPopChk(MsgIs);
end;

procedure TfrmContest.rbIgnoreDupesChange(Sender: TObject);
begin
  btDupChkStart.Visible:=not(rbIgnoreDupes.Checked);
end;
procedure TfrmContest.tmrESC2Timer(Sender: TObject);
begin
  EscTimes := 0; //time for counts passed
  tmrESC2.Enabled := False;
end;

procedure TfrmContest.tmrScoreTimer(Sender: TObject);
begin
  tmrScore.Enabled:=false;
  cmbContestNameExit(nil);
end;

procedure TfrmContest.SetActualReportForModeFromRadio;
 var
   mode,
   band:  string;

begin
  edtRSTs.Text := '599';
  edtRSTr.Text := '599';

  if frmTRXControl.GetModeBand(mode, band) then
   case mode of
    'SSB','AM','FM' :  begin
                         edtRSTs.Text := '59';
                         edtRSTr.Text := '59';
                       end;
   end;
end;
procedure TfrmContest.InitInput;
Begin
  SetActualReportForModeFromRadio;
  FmemorySent:=False;
  ESMBeat:=0;

  if not ((edtSTX.Text <> '') and (ResetStx = ''))  then
    edtSTX.Text := ResetStx;

  edtSTXStr.Text := ResetStxStr;
  edtSRX.Text := '';
  edtSRXStr.Text := '';
  edtCall.Font.Color:=clDefault;
  edtCall.Font.Style:= [];
  edtCall.Clear;
  EscTimes := 0;

  SetTabOrders;
  ClearStatusBar;
  frmContest.ShowOnTop;
  frmContest.SetFocus;
  edtCall.SetFocus;

end;

procedure TfrmContest.ChkSerialNrUpd(IncNr: boolean);   // do we need serial nr inc
var                                                    //otherwise just update memos
  stxLen, stxInt: integer;
  lZero: boolean;
  stx: string;

begin
  stx := trim(edtSTX.Text);

  if IncNr then
  begin
    stxlen := length(stx);
    if chkNRInc.Checked then //inc of number requested
    begin
      lZero := stx[1] = '0'; //do we have leading zero(es)
      if dmData.DebugLevel >= 1 then
        Writeln('Need inc number:', stx, ' Has leading zero:', lZero, ' len:', stxlen);
      if TryStrToInt(stx, stxint) then
      begin
        if dmData.DebugLevel >= 1 then
          Writeln('Integer is:', stxInt);
        Inc(stxInt);
        stx := IntToStr(stxInt);
        if dmData.DebugLevel >= 1 then
          Writeln('New number is:', stx);
        if (length(stx) < stxLen) and lZero then //pad with zero(es)
        begin
          //AddChar('0',stx,stxLen); // why does this NOT work???
          while length(stx) < stxlen do
            stx := '0' + stx;
          if dmData.DebugLevel >= 1 then
            Writeln('After leading zero(es) added:', stx);
        end;
      end;
    end;
  end;

  ResetStx := stx;
  ResetStxStr := edtSTXStr.Text;

  if dmData.DebugLevel >= 1 then
    Writeln(' Inc number is: ', IncNr);
end;
procedure  TfrmContest.SetTabOrders;
begin
  TabStopAllOn;
  if not chkTabAll.Checked then
    begin
      //NRs no need to touch
      edtSTX.TabStop      := False;
      //"Qsp" adds MSGs, else drops
      edtSTXStr.TabStop:= chkQsp.Checked;
      //"No" drops NRr
      edtSRX.TabStop   := not chkNoNr.Checked;
      //"Tru" checked adds RST fields, else drops
      edtRSTs.TabStop  := chkTrueRST.Checked;
      edtRSTr.TabStop  := chkTrueRST.Checked;
    end;
end;

procedure  TfrmContest.TabStopAllOn;
//set all tabstops
Begin
    edtCall.TabStop     := True;
    edtCall.TabOrder    := 0;
    edtRSTs.TabStop     := True;
    edtRSTs.TabOrder    := 1;
    edtSTX.TabStop      := True;
    edtSTX.TabOrder     := 2;
    edtSTXStr.TabStop   := True;
    edtSTXStr.TabOrder  := 3;

    edtRSTr.TabStop     := True;
    edtRSTr.TabOrder    := 4;
    edtSRX.TabStop      := True;
    edtSRX.TabOrder     := 5;
    edtSRXStr.TabStop   := True;
    edtSRXStr.TabOrder  := 6;

    btSave.TabStop      := True;
    btSave.TabOrder     := 7;
    btClearQso.TabStop  := True;
    btClearQso.TabOrder := 8;

    rbDupeCheck.TabStop:=false;
    rbNoMode4Dupe.TabStop:=false;
    rbIgnoreDupes.TabStop:=false;
    btClearAll.TabStop:=false;
    chkTabAll.TabStop:=false;
    cmbContestName.TabStop:=false;
    btDupChkStart.TabStop:=False;
    chkSetFilter.TabStop:=False;
    chkHint.TabStop:=False;
end;
procedure TfrmContest.QspMsg;
Begin
   try
    dmData.Q.Close;
    if dmData.trQ.Active then dmData.trQ.Rollback;
    dmData.Q.SQL.Text := 'SELECT srx_string FROM cqrlog_main ORDER BY qsodate DESC, time_on DESC LIMIT 1';
    dmData.trQ.StartTransaction;
    if dmData.DebugLevel >=1 then
      Writeln(dmData.Q.SQL.Text);
    dmData.Q.Open();
    edtSTXStr.Text := dmData.Q.Fields[0].AsString;
    dmData.Q.Close();
    dmData.trQ.Rollback;
   finally
     edtSTXStr.SetFocus;
     edtSTXStr.SelStart:=length(edtSTXStr.Text);
     edtSTXStr.SelLength:=0;
   end;
end;

procedure TfrmContest.ClearStatusBar;
var
  i : Integer;
begin
  for i:=0 to sbContest.Panels.Count-1 do
    sbContest.Panels.Items[i].Text := '';

end;

procedure TfrmContest.ShowStatusBarInfo;
begin
      sbContest.Panels.Items[0].Text := ExtractWord(1,Trim(frmNewQSO.mCountry.Text),[#$0A]);
      sbContest.Panels.Items[1].Text := 'WAZ: ' + frmNewQSO.lblWAZ.Caption;
      sbContest.Panels.Items[2].Text := 'ITU: ' + frmNewQSO.lblITU.Caption;
      sbContest.Panels.Items[3].Text := 'AZ: ' + frmNewQSO.lblAzi.Caption;
      sbContest.Panels.Items[4].Text := frmNewQSO.lblCont.Caption;
end;

{ ---------------------------------------------------------------------------
  Rule-driven contest scoring.

  Everything here is a no-op unless the selected contest has a definition file
  in ~/.config/cqrlog/contests/. Without one the window behaves exactly as it
  did before the rule engine existed - dupe radio buttons, generic counters.

  The score is computed by scanning the contest's QSOs, NOT by trusting the UI
  or accumulating as we go. Two reasons: a multiplier is only "new" relative to
  everything worked before it, so it can only be decided in log order; and any
  scorer that reads live entry-field state will eventually score the whole log
  against whatever call happens to be typed at the time.

  The scan is cheap because cqrlog already stores adif, cont, waz, itu, loc and
  state on every QSO - no per-row country lookup, which is what would otherwise
  make this far too slow to run on a timer.
  --------------------------------------------------------------------------- }

function TfrmContest.RulesLoaded : Boolean;
begin
  Result := (ContestRules <> nil) and ContestRules.Loaded
end;

{ The station in the callsign box, described the way the rule engine wants it.

  Everything here is already on screen: frmNewQSO.edtCallExit has just run a
  country lookup and parked the results in its labels. Re-deriving them would
  cost another 5-10 ms of country-file scanning per keystroke for no gain. }
function TfrmContest.CurrentQsoCtx : TQsoCtx;
begin
  Result := Default(TQsoCtx);
  Result.Call         := UpperCase(Trim(edtCall.Text));
  Result.Band         := UpperCase(dmUtils.GetBandFromFreq(frmNewQSO.cmbFreq.Text));
  Result.Mode         := UpperCase(Trim(frmNewQSO.cmbMode.Text));
  Result.CountryPfx   := UpperCase(Trim(frmNewQSO.lblDXCC.Caption));
  Result.Continent    := UpperCase(Trim(frmNewQSO.lblCont.Caption));
  Result.ZoneCQ       := Trim(frmNewQSO.lblWAZ.Caption);
  Result.ZoneITU      := Trim(frmNewQSO.lblITU.Caption);
  Result.Grid         := Trim(frmNewQSO.edtGrid.Text);
  Result.MyGrid       := Trim(cqrini.ReadString('Station','LOC',''));
  Result.State        := Trim(frmNewQSO.edtState.Text);
  Result.SerialRcvd   := Trim(edtSRX.Text);
  Result.ExchRcvd     := Trim(edtSRXStr.Text);
  Result.MyCountryPfx := Mypfx;
  Result.MyContinent  := Mycont;
  Result.IsDupe       := ESMIsDupe
end;

{ N1MM's colour language on the callsign box: red = single multiplier,
  green = double or better, blue = new station, grey = dupe.

  Only applied while a contest with rules is loaded. Without it cqrlog's own
  red-bold-for-dupe stays, which matters because red meaning "dupe" in one
  contest and "multiplier" in another is how you work a dupe thinking it is a
  new mult. }
procedure TfrmContest.ShowMultStatus;
var
  ctx  : TQsoCtx;
  need : Integer;
begin
  if not MultTracker.Active then exit;         //leave the legacy colouring
  if Trim(edtCall.Text) = '' then exit;

  ctx := CurrentQsoCtx;
  if ctx.IsDupe then
  begin
    edtCall.Font.Color := clGray;
    edtCall.Font.Style := [];
    exit
  end;

  need := MultTracker.NeededCount(ctx);
  case need of
    0 : begin                                  //workable, but nothing new
          edtCall.Font.Color := clBlue;
          edtCall.Font.Style := []
        end;
    1 : begin
          edtCall.Font.Color := clRed;
          edtCall.Font.Style := [fsBold]
        end;
  else
        begin                                  //double mult or better
          edtCall.Font.Color := clGreen;
          edtCall.Font.Style := [fsBold]
        end
  end
end;

{ Call history: what we already know about this operator.

  Loaded per contest from ~/.config/cqrlog/callhistory/<CONTEST>.txt in N1MM's
  format, so the published files work unmodified. }
procedure TfrmContest.HistoryCallsLike(const partial : String; l : TStrings);
begin
  if (CallHist = nil) or (CallHist.Count = 0) then exit;
  CallHist.MatchingCalls(partial,l,40)
end;

procedure TfrmContest.LoadCallHistory;
var
  fn : String;
begin
  if CallHist = nil then CallHist := TCallHistory.Create;
  CallHist.Clear;
  fn := CallHistoryFile(dmData.HomeDir,cmbContestName.Text);
  if fn = '' then exit;
  if CallHist.LoadFromFile(fn) then
  begin
    if dmData.DebugLevel>=1 then
      Writeln('Call history: ',CallHist.Count,' calls from ',fn);
    //A malformed published file is worth saying out loud - the CWops list
    //ships with two columns both named Misc, which silently drops the member
    //number and lands the state in the exchange field.
    if (CallHist.DuplicateColumns <> '') and (lblCallHist <> nil) then
      lblCallHist.Caption := 'call history: duplicate column '+
                             CallHist.DuplicateColumns
  end
  else
    if dmData.DebugLevel>=1 then
      Writeln('No call history for ',cmbContestName.Text,' (looked for ',fn,')')
end;

{ Fill the blanks - and only the blanks.

  N1MM's rule, and it matters: prefill must never overwrite something the
  operator typed, because what he copied off the air beats what a file from
  last year believes. }
procedure TfrmContest.PrefillFromHistory;
var
  rec : TCallHistRec;
  s   : String;
begin
  if lblCallHist <> nil then lblCallHist.Caption := '';
  if (CallHist = nil) or (CallHist.Count = 0) then exit;
  if not RulesLoaded then exit;
  if not CallHist.Lookup(edtCall.Text,rec) then exit;

  //Show what we know whether or not anything gets filled, so the operator can
  //see the prefill came from a real hit.
  s := Trim(rec.Name);
  if rec.State <> '' then s := s + ' ' + rec.State;
  if rec.Exch1 <> '' then s := s + ' #' + rec.Exch1;
  if rec.CqZone <> '' then s := s + ' z' + rec.CqZone;
  if lblCallHist <> nil then lblCallHist.Caption := Trim(s);

  if ContestRules.HistName and (Trim(frmNewQSO.edtName.Text) = '') and
     (rec.Name <> '') then
    frmNewQSO.edtName.Text := rec.Name;

  if (ContestRules.HistExch <> '') and (Trim(edtSRXStr.Text) = '') then
  begin
    s := CallHist.Expand(ContestRules.HistExch,rec);
    if s <> '' then edtSRXStr.Text := s
  end
end;

procedure TfrmContest.LoadContestRules;
var
  fn : String;
begin
  if ContestRules = nil then ContestRules := TContestRules.Create;
  ContestRules.Clear;
  fn := ContestDefFile(dmData.HomeDir,cmbContestName.Text);
  //The spot threads colour against their own copy of the rules; swapping it
  //here keeps them from scoring the new contest with the old contest's keys.
  MultTracker.SetRulesFile(fn);
  LoadCallHistory;
  if fn = '' then exit;
  if ContestRules.LoadFromFile(fn) then
  begin
    if dmData.DebugLevel>=1 then
      Writeln('Contest rules loaded: ',fn);
    //The sent exchange belongs to the contest, so selecting one replaces
    //whatever the last contest left in the box - which is how a stale "61"
    //from a previous session ends up going out on the air.
    if ContestRules.SentExch <> '' then
    begin
      edtSTXStr.Text := ContestRules.SentExch;
      ResetStxStr    := ContestRules.SentExch;
      cqrini.WriteString('frmContest','STXStr',ContestRules.SentExch)
    end;
    frmNewQSO.UpdateFKeyLabels
  end
  else
    if dmData.DebugLevel>=1 then
      Writeln('No contest rules for ',cmbContestName.Text,' (looked for ',fn,')')
end;

function TfrmContest.ScoreContest(const contestName : String;
                                  writeBack : Boolean;
                                  markLastAsRun : Integer;
                                  out qsos,dupes,pts,m1,m2,m3 : Integer) : Integer;
var
  rules      : TContestRules;
  ctx        : TQsoCtx;
  worked     : TStringList;   //dupe keys already seen, in log order
  mults      : array[1..3] of TStringList;
  upd        : TStringList;   //UPDATEs collected while the cursor is open
  i,rowPts   : Integer;
  isM        : array[1..3] of Integer;
  key,mk,fn  : String;
  rowId,lastId : LongInt;
  feedTracker  : Boolean;
begin
  Result := -1;
  qsos := 0; dupes := 0; pts := 0; m1 := 0; m2 := 0; m3 := 0;
  if Trim(contestName) = '' then exit;

  //Only the contest actually being operated feeds the spot-colouring tracker.
  //The Cabrillo export scores OTHER contests through here and must not
  //repopulate it with a contest that is not on the air.
  feedTracker := SameText(Trim(contestName),Trim(cmbContestName.Text));

  rules := TContestRules.Create;
  worked := TStringList.Create;
  upd := TStringList.Create;
  for i := 1 to 3 do mults[i] := TStringList.Create;
  try
    fn := ContestDefFile(dmData.HomeDir,contestName);
    if not rules.LoadFromFile(fn) then exit;   //no definition, no score
    if feedTracker then MultTracker.BeginRebuild;

    worked.Sorted := True;
    worked.Duplicates := dupIgnore;
    for i := 1 to 3 do
    begin
      mults[i].Sorted := True;
      mults[i].Duplicates := dupIgnore
    end;
    lastId := -1;

    dmData.Q.Close;
    if dmData.trQ.Active then dmData.trQ.Rollback;
    dmData.trQ.StartTransaction;
    try
      //dxcc_id carries the entity prefix, so the country multiplier and the
      //workability test both come out of one join instead of 5-10 ms of
      //country-file scanning per row.
      dmData.Q.SQL.Text :=
        'select m.id_cqrlog_main,m.callsign,m.band,m.mode,m.cont,m.waz,m.itu,'+
        'm.loc,m.my_loc,m.state,m.srx,m.srx_string,m.points,m.ismult1,m.ismult2,'+
        'm.ismult3,d.dxcc_ref '+
        'from cqrlog_main m left join dxcc_id d on d.adif=m.adif '+
        'where m.contestname='+QuotedStr(contestName)+' '+
        'order by m.qsodate,m.time_on,m.id_cqrlog_main';
      dmData.Q.Open;
      while not dmData.Q.Eof do
      begin
        rowId := dmData.Q.FieldByName('id_cqrlog_main').AsInteger;
        ctx := Default(TQsoCtx);
        ctx.Call         := UpperCase(Trim(dmData.Q.FieldByName('callsign').AsString));
        ctx.Band         := UpperCase(Trim(dmData.Q.FieldByName('band').AsString));
        ctx.Mode         := UpperCase(Trim(dmData.Q.FieldByName('mode').AsString));
        ctx.Continent    := UpperCase(Trim(dmData.Q.FieldByName('cont').AsString));
        ctx.CountryPfx   := UpperCase(Trim(dmData.Q.FieldByName('dxcc_ref').AsString));
        ctx.ZoneCQ       := Trim(dmData.Q.FieldByName('waz').AsString);
        ctx.ZoneITU      := Trim(dmData.Q.FieldByName('itu').AsString);
        ctx.Grid         := Trim(dmData.Q.FieldByName('loc').AsString);
        //From the log, not the config: a distance-scored contest worked
        //portable must score from where you actually were.
        ctx.MyGrid       := Trim(dmData.Q.FieldByName('my_loc').AsString);
        if ctx.MyGrid = '' then ctx.MyGrid := cqrini.ReadString('Station','LOC','');
        ctx.State        := Trim(dmData.Q.FieldByName('state').AsString);
        ctx.SerialRcvd   := Trim(dmData.Q.FieldByName('srx').AsString);
        ctx.ExchRcvd     := Trim(dmData.Q.FieldByName('srx_string').AsString);
        ctx.MyCountryPfx := Mypfx;
        ctx.MyContinent  := Mycont;

        //Dupe is recomputed from what came BEFORE this row, never from the
        //entry form - a stuck UI flag would otherwise rescore the whole log.
        case rules.DupeType of
          dpOncePerContest : key := ctx.Call;
          dpPerBandMode    : key := ctx.Call+'|'+ctx.Band+'|'+ctx.Mode;
          dpNone           : key := '';
        else                  key := ctx.Call+'|'+ctx.Band
        end;
        ctx.IsDupe := (key <> '') and (worked.IndexOf(key) >= 0);
        if key <> '' then worked.Add(key);

        rowPts := rules.QsoPoints(ctx);
        Inc(qsos);
        if ctx.IsDupe then Inc(dupes);
        Inc(pts,rowPts);
        for i := 1 to 3 do
        begin
          mk := rules.MultKey(i,ctx);
          //"Is this row a multiplier" means it is the FIRST row to show that
          //key - which is only knowable here, in log order.
          if (mk <> '') and (mults[i].IndexOf(mk) < 0) then
          begin
            mults[i].Add(mk);
            isM[i] := 1
          end
          else
            isM[i] := 0;
          if feedTracker and (mk <> '') then MultTracker.AddWorked(i,mk)
        end;

        if writeBack then
        begin
          //Only rows whose stored values actually changed, so a rescore of an
          //already-scored contest writes nothing at all.
          if (dmData.Q.FieldByName('points').AsInteger <> rowPts) or
             (dmData.Q.FieldByName('ismult1').AsInteger <> isM[1]) or
             (dmData.Q.FieldByName('ismult2').AsInteger <> isM[2]) or
             (dmData.Q.FieldByName('ismult3').AsInteger <> isM[3]) then
            upd.Add('update cqrlog_main set points='+IntToStr(rowPts)+
                    ',ismult1='+IntToStr(isM[1])+
                    ',ismult2='+IntToStr(isM[2])+
                    ',ismult3='+IntToStr(isM[3])+
                    ' where id_cqrlog_main='+IntToStr(rowId));
          lastId := rowId
        end;

        dmData.Q.Next
      end;
      dmData.Q.Close
    finally
      dmData.trQ.Rollback
    end;

    //Run/S&P is not derivable from the log - it is only known at save time,
    //so the caller tells us about the row it just wrote.
    if writeBack and (markLastAsRun >= 0) and (lastId >= 0) then
      upd.Add('update cqrlog_main set isrunqso='+IntToStr(markLastAsRun)+
              ' where id_cqrlog_main='+IntToStr(lastId));

    if writeBack and (upd.Count > 0) then
    begin
      //CRITICAL: the cqrlog_main_bu trigger queues every UPDATE into
      //log_changes for online re-upload unless @cqr_qsl_mark is set. Scoring
      //touches every QSO in the contest, so without this guard one rescore
      //re-uploads the whole contest to LoTW, eQSL and QRZ.
      dmData.Q1.Close;
      if dmData.trQ1.Active then dmData.trQ1.Rollback;
      try
        dmData.trQ1.StartTransaction;
        try
          dmData.Q1.SQL.Text := 'SET @cqr_qsl_mark=1';
          dmData.Q1.ExecSQL;
          for i := 0 to upd.Count-1 do
          begin
            dmData.Q1.SQL.Text := upd[i];
            dmData.Q1.ExecSQL
          end;
          dmData.trQ1.Commit
        except
          //Roll back rather than let the reset below commit us: a contest
          //scored half way is worse than one not scored at all.
          if dmData.trQ1.Active then dmData.trQ1.Rollback;
          raise
        end
      finally
        //@cqr_qsl_mark is CONNECTION scoped, so a rollback does not clear it.
        //It has to be reset explicitly or every QSO saved afterwards would
        //quietly skip the upload ledger for the rest of the session.
        if not dmData.trQ1.Active then dmData.trQ1.StartTransaction;
        dmData.Q1.SQL.Text := 'SET @cqr_qsl_mark=NULL';
        dmData.Q1.ExecSQL;
        dmData.trQ1.Commit
      end;
      if dmData.DebugLevel>=1 then
        Writeln('Contest rescore: ',upd.Count,' rows updated for ',contestName)
    end;

    if feedTracker then MultTracker.EndRebuild;

    m1 := mults[1].Count;
    m2 := mults[2].Count;
    m3 := mults[3].Count;
    Result := rules.Score(pts,m1,m2,m3)
  finally
    for i := 1 to 3 do mults[i].Free;
    upd.Free;
    worked.Free;
    rules.Free
  end
end;

procedure TfrmContest.RulesStatus;
var
  qsos,dupes,pts,
  m1,m2,m3,score : Integer;
  i              : Integer;
begin
  if not RulesLoaded then exit;
  score := ScoreContest(cmbContestName.Text,False,-1,qsos,dupes,pts,m1,m2,m3);
  if score < 0 then exit;

  mStatus.Clear;
  mStatus.Lines.Add(ContestRules.DisplayName);
  mStatus.Lines.Add('-----------------------------------------------------------');
  mStatus.Lines.Add('QSOs:  '+IntToStr(qsos)+'    (dupes: '+IntToStr(dupes)+')');
  mStatus.Lines.Add('Points: '+IntToStr(pts));
  for i := 1 to 3 do
    if ((i=1) and (m1>0)) or ((i=2) and (m2>0)) or ((i=3) and (m3>0)) then
      case i of
        1 : mStatus.Lines.Add('Mult 1 ('+ContestRules.MultName(1)+'): '+IntToStr(m1));
        2 : mStatus.Lines.Add('Mult 2 ('+ContestRules.MultName(2)+'): '+IntToStr(m2));
        3 : mStatus.Lines.Add('Mult 3 ('+ContestRules.MultName(3)+'): '+IntToStr(m3));
      end;
  mStatus.Lines.Add('-----------------------------------------------------------');
  mStatus.Lines.Add('SCORE: '+IntToStr(score));

  //Keep the multiplier grid in step with the score rather than making it poll.
  if frmMultipliers <> nil then frmMultipliers.RefreshIfShowing
end;

{ ---------------------------------------------------------------------------
  ESM - Enter Sends Message.

  Enter stops meaning "save" and starts meaning "send whatever comes next in
  this QSO, and save when there is nothing left to send". Off by default; the
  checkbox is built at runtime so no .lfm surgery is needed.

  Role -> F-key mapping is read from the ini and defaults to the convention
  cqrlog's contest window already used before ESM existed (F1 CQ, F2 exchange,
  F3 QSO-B4, F4 TU), so turning ESM on does not move anybody's macros. The
  keys are looked up per role, not hardcoded, so a N1MM layout is an ini edit.

  Remember cqrlog keeps TWO macro banks: in run mode GetCWMessage silently
  reads F11..F20 for F1..F10, so "F2" below means "the exchange key of the
  bank that is currently active" - run and S&P each get their own text.
  --------------------------------------------------------------------------- }

const
  esmNothing = 0;
  esmCQ      = 1;   //run: CQ  /  S&P: send my call
  esmExch    = 2;   //send the exchange
  esmDupe    = 3;   //tell him he is a dupe
  esmAgn     = 4;   //ask for a repeat
  esmLog     = 5;   //log; in run btSaveClick keys TU on the way out

function TfrmContest.ESMOn : Boolean;
begin
  Result := (chkESM <> nil) and chkESM.Checked
end;

function TfrmContest.ESMKeyFor(const role : String; def : Word) : Word;
var
  s : String;
  n : Integer;
begin
  Result := def;
  s := UpperCase(Trim(cqrini.ReadString('frmContest','ESM'+role,'')));
  if (Length(s) < 2) or (s[1] <> 'F') then exit;
  if not TryStrToInt(Copy(s,2,Length(s)-1),n) then exit;
  if (n < 1) or (n > 10) then exit;          //only F1..F10 are memory keys
  Result := VK_F1 + Word(n-1)
end;

function TfrmContest.ESMCallLoggable : Boolean;
var
  i        : Integer;
  s        : String;
  hasDigit,
  hasAlpha : Boolean;
begin
  //frmNewQSO.btnSave silently refuses a call that is not callsign-shaped, so
  //without this gate Enter would key TU while the QSO went nowhere.
  Result := False;
  s := UpperCase(Trim(edtCall.Text));
  if Length(s) < 3 then exit;
  hasDigit := False;
  hasAlpha := False;
  for i := 1 to Length(s) do
    case s[i] of
      '0'..'9' : hasDigit := True;
      'A'..'Z' : hasAlpha := True;
    end;
  Result := hasDigit and hasAlpha
end;

function TfrmContest.ESMExchangeValid : Boolean;
begin
  //Until the contest rule engine lands there is no per-contest exchange
  //schema, so this is deliberately the loosest rule that still catches an
  //empty form: a report, plus a serial unless this contest has none.
  Result := False;
  if Trim(edtRSTr.Text) = '' then exit;
  if (not chkNoNr.Checked) and (Trim(edtSRX.Text) = '') then exit;
  Result := True
end;

function TfrmContest.ESMNextAction : Integer;
begin
  if Trim(edtCall.Text) = '' then
  begin
    //Nothing on frequency: in run that is a CQ. In S&P it is nothing at all -
    //throwing your call at an empty box is how you answer the wrong station.
    if chkSP.Checked then Result := esmNothing else Result := esmCQ;
    exit
  end;

  if not chkSP.Checked then
  begin
    //RUN. Beat 0 answers him, beat 1 closes the QSO.
    //chkMarkDupe checked means "work dupes and flag them in the log", which is
    //N1MM's "work dupes when running" - so only refuse when it is unchecked.
    if (ESMBeat = 0) and ESMIsDupe and (not chkMarkDupe.Checked) then
    begin
      Result := esmDupe;
      exit
    end;
    if ESMBeat = 0 then
    begin
      Result := esmExch;
      exit
    end;
    if ESMExchangeValid then
      Result := esmLog             //btSaveClick keys TU on its way out
    else
      Result := esmAgn;            //he gave us nothing usable, ask again
    exit
  end;

  //S&P is a strict THREE-BEAT: my call, my exchange, log.
  //Beat 1 fires whether or not his serial is copied yet, so working him in
  //either order behaves the same. Beat 2 is SILENT - he is the one saying TU,
  //and the field wipe is the only "it logged" signal.
  case ESMBeat of
    0 : Result := esmCQ;           //the S&P bank's F1 holds my call
    1 : Result := esmExch;
  else
    if ESMExchangeValid then Result := esmLog else Result := esmAgn
  end
end;

procedure TfrmContest.ESMUpdateHint;
var
  s : String;
begin
  if lblESMNext = nil then exit;
  if not ESMOn then
  begin
    lblESMNext.Caption := '';
    exit
  end;
  case ESMNextAction of
    esmCQ    : if chkSP.Checked then s := 'my call' else s := 'CQ';
    esmExch  : s := 'exchange';
    esmDupe  : s := 'QSO B4';
    esmAgn   : s := 'AGN?';
    esmLog   : if chkSP.Checked then s := 'log' else s := 'TU + log';
    else       s := '-';
  end;
  lblESMNext.Caption := 'Enter: '+s
end;

procedure TfrmContest.ESMFocusExchange;
begin
  //After sending the exchange the operator is copying his, so put the caret
  //where the next keystroke belongs instead of leaving it on the callsign.
  if edtSRX.CanFocus and edtSRX.TabStop then
    edtSRX.SetFocus
  else if edtSRXStr.CanFocus and edtSRXStr.TabStop then
    edtSRXStr.SetFocus
  else if edtRSTr.CanFocus and edtRSTr.TabStop then
    edtRSTr.SetFocus
end;

procedure TfrmContest.ESMDoEnter;
begin
  case ESMNextAction of
    esmNothing : ;                //deliberately silent

    esmCQ      : begin
                   SendFmemory(ESMKeyFor('CQ',VK_F1));
                   //In run this is a CQ and the QSO has not started, so the
                   //beat stays at 0. In S&P it IS beat 0 - we just answered.
                   if chkSP.Checked then
                   begin
                     ESMBeat := 1;
                     ESMFocusExchange
                   end
                 end;

    esmExch    : begin
                   SendFmemory(ESMKeyFor('Exch',VK_F2));
                   if chkSP.Checked then ESMBeat := 2 else ESMBeat := 1;
                   //FmemorySent stops edtRSTrEnter keying the exchange a
                   //second time when the caret lands in the received report.
                   FmemorySent := True;
                   ESMFocusExchange
                 end;

    esmDupe    : SendFmemory(ESMKeyFor('Dupe',VK_F3));

    esmAgn     : SendFmemory(ESMKeyFor('Agn',VK_F7));

    esmLog     : begin
                   //The log action is never bundled with a send. btSaveClick
                   //wipes the fields, so a "?" answered right after a bundled
                   //send would go out with the next, zeroed, serial.
                   if not ESMCallLoggable then
                   begin
                     if lblESMNext <> nil then
                       lblESMNext.Caption := edtCall.Text+' is not loggable';
                     exit
                   end;
                   if not ESMExchangeValid then exit;
                   //Run mode's TU comes from btSaveClick itself; S&P logs
                   //silently, because there he is the one sending TU.
                   btSave.Click
                 end;
  end;
  ESMUpdateHint
end;

procedure TfrmContest.ESMCheckChange(Sender: TObject);
begin
  cqrini.WriteBool('frmContest','ESM',ESMOn);
  ESMBeat := 0;
  ESMUpdateHint
end;

procedure TfrmContest.ESMCreateControls;
var
  mi : TMenuItem;
begin
  if chkESM <> nil then exit;                //only once

  //Anchored rather than positioned: every control on this row rides an anchor
  //chain, so their .Top/.Left in the .lfm are design-time snapshots. chkLoc is
  //the last box on the row and nothing anchors to it, so we extend the chain.
  chkESM := TCheckBox.Create(Self);
  chkESM.Parent   := chkLoc.Parent;
  chkESM.AnchorSideLeft.Control := chkLoc;
  chkESM.AnchorSideLeft.Side    := asrBottom;      //asrBottom on Left = right edge
  chkESM.AnchorSideTop.Control  := chkLoc;
  chkESM.AnchorSideTop.Side     := asrCenter;
  chkESM.Anchors  := [akLeft,akTop];
  chkESM.BorderSpacing.Left := 12;
  chkESM.Caption  := 'ESM';
  chkESM.Hint     := 'Enter Sends Message.'+LineEnding+
                     'Enter keys the next message of the QSO instead of saving, '+
                     'and saves only when there is nothing left to send.'+LineEnding+
                     'Run: Enter=exchange, Enter=TU+log.'+LineEnding+
                     'S&P: Enter=my call, Enter=exchange, Enter=log (silent).'+LineEnding+
                     'While ESM is on, the automatic F2-on-entering-RSTr and '+
                     'F3-on-dupe sends are suppressed so nothing is keyed twice.';
  chkESM.ParentShowHint := False;
  chkESM.ShowHint := True;
  chkESM.TabStop  := False;
  chkESM.Checked  := cqrini.ReadBool('frmContest','ESM',False);
  chkESM.OnChange := @ESMCheckChange;

  lblESMNext := TLabel.Create(Self);
  lblESMNext.Parent := chkESM.Parent;
  lblESMNext.AnchorSideLeft.Control := chkESM;
  lblESMNext.AnchorSideLeft.Side    := asrBottom;
  lblESMNext.AnchorSideTop.Control  := chkESM;
  lblESMNext.AnchorSideTop.Side     := asrCenter;
  lblESMNext.Anchors := [akLeft,akTop];
  lblESMNext.BorderSpacing.Left := 8;
  lblESMNext.Font.Style := [fsBold];
  lblESMNext.Caption := '';

  //Call-history readout, on the row below. N1MM puts this on the bearing
  //line; here it sits under the ESM hint where the eye already is.
  lblCallHist := TLabel.Create(Self);
  lblCallHist.Parent := chkESM.Parent;
  lblCallHist.AnchorSideLeft.Control := chkESM;
  lblCallHist.AnchorSideLeft.Side    := asrLeft;
  lblCallHist.AnchorSideTop.Control  := chkESM;
  lblCallHist.AnchorSideTop.Side     := asrBottom;
  lblCallHist.Anchors := [akLeft,akTop];
  lblCallHist.BorderSpacing.Top := 2;
  lblCallHist.Font.Color := clNavy;
  lblCallHist.Caption := '';

  //Rescore, N1MM's Tools > Rescore. Saving a QSO scores that QSO, but editing
  //or deleting an earlier one changes every dupe and multiplier decision after
  //it, and only a full re-scan can put that right.
  if popRescore = nil then
  begin
    popRescore := TPopupMenu.Create(Self);
    mi := TMenuItem.Create(popRescore);
    mi.Caption := 'Recalculate score for this contest';
    mi.OnClick := @RescoreClick;
    popRescore.Items.Add(mi);

    //The N1MM broadcast toggle lives here rather than on the entry rows:
    //it is a station-wide setting, not a per-QSO one, and the entry rows are
    //already full to the right edge of a 770px form.
    miN1MM := TMenuItem.Create(popRescore);
    miN1MM.Caption := 'Broadcast to N1MM apps (UDP 12060)';
    miN1MM.AutoCheck := True;
    miN1MM.Checked := cqrini.ReadBool('N1MM','Enabled',False);
    miN1MM.OnClick := @N1MMCheckChange;
    popRescore.Items.Add(miN1MM);

    mi := TMenuItem.Create(popRescore);
    mi.Caption := '-';
    popRescore.Items.Add(mi);

    mi := TMenuItem.Create(popRescore);
    mi.Caption := 'Save contest layout';
    mi.OnClick := @SaveLayoutClick;
    popRescore.Items.Add(mi);

    mi := TMenuItem.Create(popRescore);
    mi.Caption := 'Restore contest layout';
    mi.OnClick := @LoadLayoutClick;
    popRescore.Items.Add(mi);

    miOnTop := TMenuItem.Create(popRescore);
    miOnTop.Caption := 'Keep this window on top';
    miOnTop.AutoCheck := True;
    miOnTop.Checked := cqrini.ReadBool('frmContest','OnTop',False);
    miOnTop.OnClick := @OnTopClick;
    popRescore.Items.Add(miOnTop);
    if miOnTop.Checked then FormStyle := fsSystemStayOnTop;
    mStatus.PopupMenu := popRescore
  end;

  ESMBeat := 0;
  ESMUpdateHint
end;

{ ---------------------------------------------------------------------------
  Contest layout.

  A snapshot of where the contest windows are and which are open, saved and
  restored as one unit, so setting up for a contest is one action instead of
  arranging seven windows.

  NOTE what this deliberately does NOT do: lock the windows in place. Not1MM
  can lock its layout because its panels are dock widgets inside one window;
  cqrlog's are real top-level windows and the window manager owns moving them.
  Promising a lock we cannot enforce would be worse than not offering one.
  Always-on-top is the part that is actually achievable, and it is the part
  that matters mid-contest.
  --------------------------------------------------------------------------- }

procedure TfrmContest.LayoutForms(l : TList);
begin
  //The windows a contest operator actually arranges. Order is irrelevant;
  //each is stored under its own name.
  l.Add(frmContest);
  l.Add(frmSCP);
  l.Add(frmMultipliers);
  l.Add(frmBandMap);
  l.Add(frmCWReader);
  l.Add(frmDXCluster);
  l.Add(frmCWType)
end;

procedure TfrmContest.SaveLayoutClick(Sender: TObject);
var
  l : TList;
  i : Integer;
  f : TForm;
  n : String;
begin
  l := TList.Create;
  try
    LayoutForms(l);
    for i := 0 to l.Count-1 do
    begin
      f := TForm(l[i]);
      if f = nil then Continue;
      n := f.Name;
      cqrini.WriteBool   ('ContestLayout',n+'_Vis',f.Showing);
      //Only a window that is actually up has meaningful bounds - a hidden
      //form would save whatever it had when it was last closed.
      if f.Showing then
      begin
        cqrini.WriteInteger('ContestLayout',n+'_L',f.Left);
        cqrini.WriteInteger('ContestLayout',n+'_T',f.Top);
        cqrini.WriteInteger('ContestLayout',n+'_W',f.Width);
        cqrini.WriteInteger('ContestLayout',n+'_H',f.Height)
      end
    end
  finally
    l.Free
  end;
  Application.MessageBox('Contest layout saved.','Layout',mb_OK+mb_IconInformation)
end;

procedure TfrmContest.LoadLayoutClick(Sender: TObject);
var
  l : TList;
  i : Integer;
  f : TForm;
  n : String;
begin
  l := TList.Create;
  try
    LayoutForms(l);
    for i := 0 to l.Count-1 do
    begin
      f := TForm(l[i]);
      if f = nil then Continue;
      n := f.Name;
      if cqrini.ReadBool('ContestLayout',n+'_Vis',False) then
      begin
        f.Show;
        //Bounds after Show: showing a form can re-apply its own saved
        //position, which would undo this if done the other way round.
        f.SetBounds(cqrini.ReadInteger('ContestLayout',n+'_L',f.Left),
                    cqrini.ReadInteger('ContestLayout',n+'_T',f.Top),
                    cqrini.ReadInteger('ContestLayout',n+'_W',f.Width),
                    cqrini.ReadInteger('ContestLayout',n+'_H',f.Height))
      end
      else
        //Never hide the contest window itself - the operator is looking at
        //the menu that lives on it.
        if f <> Self then f.Hide
    end
  finally
    l.Free
  end;
  frmContest.BringToFront
end;

procedure TfrmContest.OnTopClick(Sender: TObject);
begin
  cqrini.WriteBool('frmContest','OnTop',miOnTop.Checked);
  if miOnTop.Checked then
    FormStyle := fsSystemStayOnTop
  else
    FormStyle := fsNormal
end;

procedure TfrmContest.N1MMCheckChange(Sender: TObject);
begin
  cqrini.WriteBool('N1MM','Enabled',miN1MM.Checked);
  N1MMUdp.Configure;
  if miN1MM.Checked then
    N1MMUdp.SendAppInfo(dmData.DBName,cmbContestName.Text,dmUtils.GetHostName,
                        UpperCase(cqrini.ReadString('Station','Call','')),1)
end;

procedure TfrmContest.RescoreClick(Sender: TObject);
var
  qsos,dupes,pts,m1,m2,m3,score : Integer;
begin
  if not RulesLoaded then
  begin
    Application.MessageBox('This contest has no rule definition file, so there '+
                           'is nothing to score.','Rescore',mb_OK+mb_IconInformation);
    exit
  end;
  Screen.Cursor := crHourGlass;
  try
    score := ScoreContest(cmbContestName.Text,True,-1,qsos,dupes,pts,m1,m2,m3)
  finally
    Screen.Cursor := crDefault
  end;
  RulesStatus;
  Application.MessageBox(PChar('Rescored '+IntToStr(qsos)+' QSOs.'+LineEnding+
                               'Score: '+IntToStr(score)),
                         'Rescore',mb_OK+mb_IconInformation)
end;

procedure TfrmContest.SendFmemory(key:word);
Begin
  case frmNewQSO.cmbMode.Text of
    'CW' :if Assigned(frmNewQSO.CWint)  then
            frmNewQSO.CWint.SendText(dmUtils.GetCWMessage(dmUtils.GetDescKeyFromCode(Key),edtCall.Text,
            edtRSTs.Text, edtSTX.Text,edtSTXStr.Text, edtSRX.Text, edtSRXstr.Text, frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''))
            else ShowMessage('CW interface:  No keyer defined for current radio!');
     'SSB',
     'AM',
     'FM': frmNewQSO.RunVK(dmUtils.GetDescKeyFromCode(Key));
  end
end;

function TfrmContest.CheckDupe(call:string):boolean;
var
   dupe:integer;
   isDupe:Boolean;
Begin
   Result:=false;
   if not (rbIgnoreDupes.Checked) then
   begin
     //dupe check
     dupe := frmWorkedGrids.WkdCall(edtCall.Text, dmUtils.GetBandFromFreq(frmNewQSO.cmbFreq.Text) ,frmNewQSO.cmbMode.Text);
     // 1= wkd this band and mode
     // 2= wkd this band but NOT this mode
     // 3= wkd on some other band or mode
     if RulesLoaded then
       //The contest's own rule wins over the radio buttons - "work once per
       //contest" contests like Sweepstakes and NAQP cannot be expressed by
       //them at all, which is why they were unusable here before.
       case ContestRules.DupeType of
         dpOncePerContest : isDupe := dupe in [1,2,3];
         dpPerBandMode    : isDupe := dupe = 1;
         dpNone           : isDupe := False;
       else                  isDupe := dupe in [1,2]
       end
     else
       isDupe := ( (rbNoMode4Dupe.Checked) and (dupe = 1) )
              or ( (not rbNoMode4Dupe.Checked) and ((dupe = 1) or (dupe=2)) );

     if isDupe then
        Begin
          edtCall.Font.Color:=clRed;
          edtCall.Font.Style:= [fsBold];
          Result:=true;
        end
     else
         Begin
          edtCall.Font.Color:=clDefault;
          edtCall.Font.Style:= [];
         end;
    end;
end;

procedure  TfrmContest.MWCStatus;
{
OK1WC memorial contest MWC: OK1WC or MWC (no case sensitive) must appear in contest name to activate score counting
Bands: 40,80M
Modes: CW
Points: 1p/Qso on each band
Multipliers: last letter (or number) in callsign on each band
}
var
   Mlist         : array [1..2] of string[40];
   Band          : integer;
   QSOc,MULc     : array [1..2] of integer;
   DUPEc         : array [1..2] of integer;
   f,p           : integer;
   M             : char;
   bands         : array [1..2] of string=('80M','40M');
Begin
   sgStatus.Visible:=False;
   mStatus.Clear;
    for band:=2 downto 1 do
      begin
       QSOc[band]:=0;
       MULc[band]:=0;
       DUPEc[band]:=0;
       try
        //total qso count
        if dmData.trCQ.Active then dmData.trCQ.Rollback;
          dmData.CQ.SQL.Text :=
               'SELECT COUNT(callsign) AS QSOCount FROM cqrlog_main WHERE contestname='+
               QuotedStr(cmbContestName.Text)+' AND band='+QuotedStr(bands[band])+' AND mode='+QuotedStr('CW');
          if dmData.DebugLevel >=1 then
                                       Writeln(dmData.CQ.SQL.Text);
         dmData.CQ.Open();

         {
         //different ways to check that sql query is not "Empty set"
         Writeln('-------------');
         Writeln('Is EOF:',dmData.CQ.EOF);
         Writeln('Is empty:',dmData.CQ.IsEmpty);
         Writeln('FindField:', dmData.CQ.Fields.FindField('QSOCount')<> nil);
         Writeln('Fieds.Count:',dmData.CQ.Fields.Count);
         }


         if (dmData.CQ.Fields.FindField('QSOCount')<> nil) then
               QSOc[band]:= dmData.CQ.FieldByName('QSOCount').AsInteger;
         //duplicate count
         dmData.CQ.Close;
         if dmData.trCQ.Active then dmData.trCQ.Rollback;
          dmData.CQ.SQL.Text :=
               'SELECT COUNT(callsign) AS Dcount FROM cqrlog_main WHERE contestname='+
               QuotedStr(cmbContestName.Text)+' AND band='+QuotedStr(bands[band])+' AND mode='+QuotedStr('CW')+
               'AND rst_s LIKE '+QuotedStr('%/Dupe');
          if dmData.DebugLevel >=1 then
                                       Writeln(dmData.CQ.SQL.Text);
         dmData.CQ.Open();
         if (dmData.CQ.Fields.FindField('Dcount')<> nil) then
               DUPEc[band]:= dmData.CQ.FieldByName('Dcount').AsInteger;

         //multipliers
          Mlist[band]:='....................................' ; //A-Z0-9
          dmData.CQ.Close;
          if dmData.trCQ.Active then dmData.trCQ.Rollback;
          dmData.CQ.SQL.Text :=
               'SELECT ASCII(MID(callsign,LENGTH(callsign),1)) AS SuffixEnd FROM cqrlog_main WHERE contestname='+
               QuotedStr(cmbContestName.Text)+' AND band='+QuotedStr(bands[band])+' AND mode='+QuotedStr('CW')+
               'AND rst_s NOT LIKE '+QuotedStr('%/Dupe');

          if dmData.DebugLevel >=1 then
                                       Writeln(dmData.CQ.SQL.Text);
          dmData.CQ.Open();
          dmData.CQ.First;
          while not dmData.CQ.EOF do
          Begin
            if (dmData.CQ.Fields.FindField('SuffixEnd')<> nil) then
               f:= dmData.CQ.FieldByName('SuffixEnd').AsInteger;
            if f>0 then
             Begin
               case f of
                    65..90 : p:=0;
                    48..57 : p:=43;
                 else
                   p:=-1;
               end;
               if p>-1 then
                begin
                 if Mlist[band][f+p-64]='.' then
                  Begin
                    inc(MULc[band]);
                    Mlist[band][f+p-64]:=char(f);
                  end;
                end;
             end;
             dmData.CQ.Next;
            end;
          finally
           dmData.CQ.Close();
           dmData.trCQ.Rollback;

           mStatus.Lines.Add(bands[band]+' CW:    '+Mlist[band]+'   '+IntToStr(MULc[band])+
           '   QSOs:' + IntToStr(QSOc[band])+'   DUPEs:' + IntToStr(DUPEc[band]));
          end;
      end;
    mStatus.Lines.Add('-----------------------------------------------------------------------------------------');
    mStatus.Lines.Add(' Total    QSOs: ' + IntToStr(QSOc[1]+QSOc[2])+'   DUPEs: '+ IntToStr( DUPEc[1]+DUPEc[2]) );
    mStatus.Lines.Add(' Total    Pts:  ' + IntToStr(QSOc[1]+QSOc[2]-(DUPEc[1]+DUPEc[2]))+'   Multipliers: '+IntToStr(MULc[1]+MULc[2])+
                      '   Score: '+ IntToStr(  (QSOc[1]+QSOc[2]-DUPEc[1]-DUPEc[2]) * (MULc[1]+MULc[2])  ) );

    AllQsos:= QSOc[1]+QSOc[2];
    Rates;
end; //MWC status end

procedure  TfrmContest.NACStatus;
{
Nordic Activity Contest NAC: (no case sensitive) must appear in contest name to activate score counting
Bands: 28, 50, 70 ,2M, 70cm, 23cm and up (microwaves several bands in same contest, otherwise one band contest)
Modes: CW, SSB, FM, MGM
Points: by qso distance. below 10km=10p, otherwise QSOkm=p.
Exception: 13cm multiply km*2=p and raise multiplier by 1 on every higer band than 13cm
Multipliers: 500p for every 4chr locator grid
}
var
    QSOs,
    Dupes,
    LOCs,
    QRB,
    MaxQRB,
    Points,
    QSOPoints,
    LocPoints: integer;
    LOCList,
    distance: string;
Begin
    sgStatus.Visible:=False;
    QSOs:=0;
    Dupes:=0;
    LOCs:=0;
    MaxQRB:=0;
    Points:=0;
    LocPoints:=0;
    LocList:='';
    mStatus.Clear;

    //QSO count  (28MHz and up)
    //--------------------------------------------------------------
    dmData.CQ.Close;
    if dmData.trCQ.Active then dmData.trCQ.Rollback;
    dmData.CQ.SQL.Text :=
        'SELECT  COUNT(callsign) AS QSOCount FROM cqrlog_main WHERE contestname='+ QuotedStr(cmbContestName.Text)+
         ' AND freq > 27.99999';
    if dmData.DebugLevel >=1 then
                                     Writeln(dmData.CQ.SQL.Text);
    dmData.CQ.Open();
    if (dmData.CQ.Fields.FindField('QSOCount')<> nil) then
               QSOs:= dmData.CQ.FieldByName('QSOCount').AsInteger;

    //Dupe count  (28MHz and up)
    //--------------------------------------------------------------
    dmData.CQ.Close;
    if dmData.trCQ.Active then dmData.trCQ.Rollback;
    dmData.CQ.SQL.Text :=
        'SELECT  COUNT(callsign) AS QSOCount FROM cqrlog_main WHERE contestname='+ QuotedStr(cmbContestName.Text)+
         ' AND freq > 27.99999 AND rst_s LIKE '+ QuotedStr('%Dupe%');
    if dmData.DebugLevel >=1 then
                                     Writeln(dmData.CQ.SQL.Text);
    dmData.CQ.Open();
    if (dmData.CQ.Fields.FindField('QSOCount')<> nil) then
               DUPEs:= dmData.CQ.FieldByName('QSOCount').AsInteger;


    //Points count  (up to 47GHz)
    //--------------------------------------------------------------
    dmData.CQ.Close;
    if dmData.trCQ.Active then dmData.trCQ.Rollback;
    dmData.CQ.SQL.Text :=
        'SELECT  my_loc,loc,band FROM cqrlog_main WHERE contestname='+ QuotedStr(cmbContestName.Text)+
         ' AND freq > 27.99999 AND rst_s NOT LIKE '+ QuotedStr('%Dupe%');
    if dmData.DebugLevel >=1 then
                                     Writeln(dmData.CQ.SQL.Text);
    dmData.CQ.Open();
    dmData.CQ.First;
    while not dmData.CQ.EOF do
      begin
         if (dmData.CQ.Fields.FindField('my_loc')<> nil)
          and (dmData.CQ.Fields.FindField('loc')<> nil) then
             distance:=frmMain.CalcQrb(dmData.CQ.FieldByName('my_loc').AsString,dmData.CQ.FieldByName('loc').AsString,False);
         if distance<>'' then
          Begin
            QRB:=StrToInt(distance);
            if QRB < 10 then
                     QSOPoints := 10
               else
                     QSOPoints := QRB;
            if (dmData.CQ.Fields.FindField('band')<> nil) then
            begin
              case dmData.CQ.FieldByName('band').AsString of
                '13CM'    :  QSOPoints:=QSOPoints*2;
                '9CM'     :  QSOPoints:=QSOPoints*3;
                '6CM'     :  QSOPoints:=QSOPoints*4;
                '3CM'     :  QSOPoints:=QSOPoints*5;
                '1.25CM'  :  QSOPoints:=QSOPoints*6;
                '6MM'     :  QSOPoints:=QSOPoints*7;
               end;
            end;
            if QRB > MaxQRB then
                     MaxQRB :=  QRB;

            Points:=Points+QSOPoints;
          end;
         dmData.CQ.Next;
      end;

    //list of different main locators (locator multipliers)
    //--------------------------------------------------------------
    dmData.CQ.Close;
    if dmData.trCQ.Active then dmData.trCQ.Rollback;
    dmData.CQ.SQL.Text :=
        'SELECT DISTINCT(SUBSTRING(UPPER(loc),1,4)) AS MainLoc FROM cqrlog_main WHERE contestname='+
        QuotedStr(cmbContestName.Text)+' AND rst_s NOT LIKE '+ QuotedStr('%Dupe%')+' ORDER BY MainLoc ASC';
    if dmData.DebugLevel >=1 then
                                     Writeln(dmData.CQ.SQL.Text);
     dmData.CQ.Open();
     dmData.CQ.First;
     while not dmData.CQ.EOF do
      begin
        if (dmData.CQ.Fields.FindField('MainLoc')<> nil) then
         if dmData.CQ.FieldByName('MainLoc').AsString<>'' then
          Begin
           LocList:= LocList+dmData.CQ.FieldByName('Mainloc').AsString+',';
           LocPoints:= LocPoints + 500;
           inc(LOCs);
          end;
        dmData.CQ.Next;
      end;
     dmData.CQ.Close;
     dmData.trCQ.Rollback;

     mStatus.Lines.Add('QSO count: '+IntToStr(QSOs));
     mStatus.Lines.Add('DUPE count: '+IntToStr(Dupes));
     mStatus.Lines.Add('QSO points: '+IntToStr(Points));
     mStatus.Lines.Add('-----------------------------------------------------------');
     mStatus.Lines.Add('Locator count: '+IntToStr(LOCs));
     mStatus.Lines.Add('Locator points: '+IntToStr(LocPoints));
     mStatus.Lines.Add('Locator list: '+LocList);
     mStatus.Lines.Add('-----------------------------------------------------------');
     mStatus.Lines.Add('Total points: '+ IntToStr(Points+LocPoints)+'          Max QRB: '+IntToStr(MaxQRB));

     AllQsos:=Qsos;
     Rates;
end; //NAC status end

procedure  TfrmContest.SRALFt8Status;
{
SRAL FT8 conntest for OH stations: SRAL *and* FT8  (no case sensitive) must appear in contest name to activate score counting
Bands: 40,80M
Modes: FT8
Points: 2p/Qso on each band
Multipliers: each 4chr locator/band
}
var
   Mlist         : array [1..2] of string;
   Band          : integer;
   QSOc,MULc     : array [1..2] of integer;
   DUPEc         : array [1..2] of integer;
   f,p           : integer;
   M             : char;
   bands         : array [1..2] of string=('80M','40M');
Begin
   sgStatus.Visible:=False;
   mStatus.Clear;
    for band:=2 downto 1 do
      begin
       QSOc[band]:=0;
       MULc[band]:=0;
       DUPEc[band]:=0;
       try
        //total qso count
        if dmData.trCQ.Active then dmData.trCQ.Rollback;
          dmData.CQ.SQL.Text :=
               'SELECT COUNT(callsign) AS QSOCount FROM cqrlog_main WHERE contestname='+
               QuotedStr(cmbContestName.Text)+' AND band='+QuotedStr(bands[band])+' AND mode='+QuotedStr('FT8');
          if dmData.DebugLevel >=1 then
                                       Writeln(dmData.CQ.SQL.Text);
         dmData.CQ.Open();
         if (dmData.CQ.Fields.FindField('QSOCount')<> nil) then
               QSOc[band]:= dmData.CQ.FieldByName('QSOCount').AsInteger;
         //duplicate count
         dmData.CQ.Close;
         if dmData.trCQ.Active then dmData.trCQ.Rollback;
          dmData.CQ.SQL.Text :=
               'SELECT COUNT(callsign) AS Dcount FROM cqrlog_main WHERE contestname='+
               QuotedStr(cmbContestName.Text)+' AND band='+QuotedStr(bands[band])+' AND mode='+QuotedStr('FT8')+
               'AND rst_s LIKE '+QuotedStr('%/Dupe');
          if dmData.DebugLevel >=1 then
                                       Writeln(dmData.CQ.SQL.Text);
         dmData.CQ.Open();
         if (dmData.CQ.Fields.FindField('Dcount')<> nil) then
               DUPEc[band]:= dmData.CQ.FieldByName('Dcount').AsInteger;


         //list of different 4chr locators (locator multipliers) in srx_string
         //--------------------------------------------------------------
         Mlist[band]:='';
         dmData.CQ.Close;
         if dmData.trCQ.Active then dmData.trCQ.Rollback;
         dmData.CQ.SQL.Text :=
             'SELECT DISTINCT(SUBSTRING(UPPER(srx_string),1,4)) AS MainLoc FROM cqrlog_main WHERE contestname='+
             QuotedStr(cmbContestName.Text)+' AND band='+QuotedStr(bands[band])+' AND mode='+QuotedStr('FT8')+
             ' AND rst_s NOT LIKE '+ QuotedStr('%Dupe%')+' ORDER BY MainLoc ASC';
         if dmData.DebugLevel >=1 then
                                          Writeln(dmData.CQ.SQL.Text);
          dmData.CQ.Open();
          dmData.CQ.First;
          while not dmData.CQ.EOF do
           begin
            if (dmData.CQ.Fields.FindField('MainLoc')<> nil) then
              if dmData.CQ.FieldByName('MainLoc').AsString<>'' then
               Begin
                MList[band]:= MList[band]+dmData.CQ.FieldByName('Mainloc').AsString+',';
                MULc[band]:= MULc[band]+1;
               end;
             dmData.CQ.Next;
           end;
         finally
           dmData.CQ.Close();
           dmData.trCQ.Rollback;
         end;
           mStatus.Lines.Add(bands[band]+':   Loc:'+IntToStr(MULc[band])+
           '   QSOs:' + IntToStr(QSOc[band])+'   DUPEs:' + IntToStr(DUPEc[band])+LineEnding+
           Mlist[band]+LineEnding);
      end;

    mStatus.Lines.Add('-----------------------------------------------------------------------------------------');
    mStatus.Lines.Add(' Total    QSOs: ' + IntToStr(QSOc[1]+QSOc[2])+'   DUPEs: '+ IntToStr( DUPEc[1]+DUPEc[2]) );
    mStatus.Lines.Add(' Total    Pts:  ' + IntToStr( (QSOc[1]+QSOc[2]-DUPEc[1]-DUPEc[2])*2 )+'   Multipliers: '+IntToStr(MULc[1]+MULc[2])+
                      '   Score: '+ IntToStr(  ((QSOc[1]+QSOc[2]-DUPEc[1]-DUPEc[2])*2) * (MULc[1]+MULc[2])  ) );

    AllQsos:= QSOc[1]+QSOc[2];
    Rates;
end; //SRAL FT8 status end

procedure  TfrmContest.CommonStatus;
var
  DXList,
  SRXSList,
  MyCountList     : string;
  b,f             : byte;

//-------------------------------------------------------------------------
  procedure ByBandsStatus(UseRow:integer;SqlToUse,SqlColumn:string);
  var
    f : integer;

  Begin
      For f:=0 to 10 do
        begin
          dmData.CQ.Close;
          if dmData.trCQ.Active then dmData.trCQ.Rollback;
          if dmData.DebugLevel >=1 then
                                   writeln(popCommonStatus.Items[f+10].Caption);
          if  popCommonStatus.Items[f+10].Checked then
           begin
              dmData.CQ.SQL.Text := SqlToUse + ' AND band='+QuotedStr(dUtils.cBands[ContestBandPtr[f]]);
              if mnuModeRelated.Checked then
                     dmData.CQ.SQL.Text := dmData.CQ.SQL.Text+' AND mode='+QuotedStr(frmNewQso.cmbMode.Text);
              if dmData.DebugLevel >=1 then
                                     Writeln(dmData.CQ.SQL.Text);
              dmData.CQ.Open();
              if (dmData.CQ.Fields.FindField(SqlColumn)<> nil) then
               sgStatus.Cells[f+2,UseRow]:=dmData.CQ.FieldByName(SqlColumn).AsString;
           end;
        end;
      dmData.trCQ.Rollback;
  end;

//--------------------------------------------------------------------------

 Begin
    DXList:='';
    MyCountList:='';
    sgStatus.Visible:=True;
    mStatus.Clear;
    sgStatus.Clean([gzNormal]);
    if popCommonStatus.Items[0].Checked or popCommonStatus.Items[2].Checked  then
     Begin
        //total counts  of QSOs and countries + band & mode counts
        //--------------------------------------------------------------
        if popCommonStatus.Items[0].Checked then
           Begin
            dmData.CQ.Close;
            if dmData.trCQ.Active then dmData.trCQ.Rollback;
            dmData.CQ.SQL.Text :=
               'SELECT COUNT(callsign) AS QSOs '+'FROM cqrlog_main WHERE contestname='+ QuotedStr(cmbContestName.Text);

             if dmData.DebugLevel >=1 then
                                         Writeln(dmData.CQ.SQL.Text);
             dmData.CQ.Open();
             if (dmData.CQ.Fields.FindField('QSOs')<> nil) then
               AllQsos:= dmData.CQ.FieldByName('QSOs').AsInteger;
             sgStatus.Cells[1,1]:=dmData.CQ.FieldByName('QSOs').AsString;
             ByBandsStatus(1,dmData.CQ.SQL.Text,'QSOs');

             dmData.CQ.Close;
            if dmData.trCQ.Active then dmData.trCQ.Rollback;
            dmData.CQ.SQL.Text :=
               'SELECT COUNT(callsign) AS DUPEs '+'FROM cqrlog_main WHERE contestname='
               + QuotedStr(cmbContestName.Text)+ ' AND rst_s LIKE '+ QuotedStr('%Dupe%');

             if dmData.DebugLevel >=1 then
                                         Writeln(dmData.CQ.SQL.Text);
             dmData.CQ.Open();
             if (dmData.CQ.Fields.FindField('DUPEs')<> nil) then
               sgStatus.Cells[1,7]:=dmData.CQ.FieldByName('DUPEs').AsString;
             ByBandsStatus(7,dmData.CQ.SQL.Text,'DUPEs');
           end;


        if popCommonStatus.Items[2].Checked then
            Begin
            dmData.CQ.Close;
            if dmData.trCQ.Active then dmData.trCQ.Rollback;
            dmData.CQ.SQL.Text :=
               'SELECT COUNT(DISTINCT(adif)) AS Countries '+'FROM cqrlog_main WHERE contestname='+QuotedStr(cmbContestName.Text);

            if dmData.DebugLevel >=1 then
                                         Writeln(dmData.CQ.SQL.Text);
             dmData.CQ.Open();
             if (dmData.CQ.Fields.FindField('Countries')<> nil) then
               sgStatus.Cells[1,3]:=dmData.CQ.FieldByName('Countries').AsString;
             ByBandsStatus(3,dmData.CQ.SQL.Text,'Countries');
            end
      end;

    //DX QSO count
    //--------------------------------------------------------------
    if popCommonStatus.Items[1].Checked then
    Begin
      dmData.CQ.Close;
      if dmData.trCQ.Active then dmData.trCQ.Rollback;
      dmData.CQ.SQL.Text :=
          'SELECT COUNT(callsign) AS DXs  FROM cqrlog_main WHERE contestname='+
           QuotedStr(cmbContestName.Text)+' AND cont<>'+QuotedStr(mycont)+ ' AND rst_s NOT LIKE '+ QuotedStr('%Dupe%');
      if dmData.DebugLevel >=1 then
                                       Writeln(dmData.CQ.SQL.Text);
      dmData.CQ.Open();
      if (dmData.CQ.Fields.FindField('DXs')<> nil) then
               sgStatus.Cells[1,2]:=dmData.CQ.FieldByName('DXs').AsString;
      ByBandsStatus(2,dmData.CQ.SQL.Text,'DXs');
    end;

    //DX country count
    //--------------------------------------------------------------
    if popCommonStatus.Items[3].Checked then
    Begin
      dmData.CQ.Close;
      if dmData.trCQ.Active then dmData.trCQ.Rollback;
      dmData.CQ.SQL.Text :=
          'SELECT COUNT(DISTINCT(adif)) AS DXCntrs  FROM cqrlog_main WHERE contestname='+
           QuotedStr(cmbContestName.Text)+' AND cont<>'+QuotedStr(mycont);
      if dmData.DebugLevel >=1 then
                                       Writeln(dmData.CQ.SQL.Text);
      dmData.CQ.Open();
      if (dmData.CQ.Fields.FindField('DXCntrs')<> nil) then
               sgStatus.Cells[1,4]:=dmData.CQ.FieldByName('DXCntrs').AsString;
      ByBandsStatus(4,dmData.CQ.SQL.Text,'DXCntrs');
    end;

     //list of DX country prefixes
     //--------------------------------------------------------------
    if popCommonStatus.Items[4].Checked then
    begin
      dmData.CQ.Close;
      if dmData.trCQ.Active then dmData.trCQ.Rollback;
      dmData.CQ.SQL.Text :=
         'SELECT DISTINCT(pref) FROM cqrlog_common.dxcc_ref RIGHT JOIN cqrlog_main ON '+
         'cqrlog_common.dxcc_ref.adif = cqrlog_main.adif WHERE contestname='+
           QuotedStr(cmbContestName.Text)+' AND cqrlog_main.cont<>'+QuotedStr(mycont)
           +' ORDER BY cqrlog_common.dxcc_ref.pref ASC';
      if dmData.DebugLevel >=1 then
                                       Writeln(dmData.CQ.SQL.Text);
      dmData.CQ.Open();
       dmData.CQ.First;
       while not dmData.CQ.EOF do
        begin
         if (dmData.CQ.Fields.FindField('pref')<> nil) then
           if dmData.CQ.FieldByName('pref').AsString<>'' then
             DXList:= DXList+dmData.CQ.FieldByName('pref').AsString+','
            else
             DXList:= DXList+'?,';
          dmData.CQ.Next;
        end;
        mStatus.Lines.Add('DX Country list : '+DXList);
     end;

    //Own continent country count
    //--------------------------------------------------------------
    if popCommonStatus.Items[5].Checked then
    begin
      dmData.CQ.Close;
      if dmData.trCQ.Active then dmData.trCQ.Rollback;
      dmData.CQ.SQL.Text :=
          'SELECT COUNT(DISTINCT(adif)) AS MYCntrs  FROM cqrlog_main WHERE contestname='+
           QuotedStr(cmbContestName.Text)+' AND cont='+QuotedStr(Mycont);
      if dmData.DebugLevel >=1 then
                                       Writeln(dmData.CQ.SQL.Text);
      dmData.CQ.Open();
      sgStatus.Cells[0,5]:= mycont+'Ctrys';
      if (dmData.CQ.Fields.FindField('MYCntrs')<> nil) then
               sgStatus.Cells[1,5]:= dmData.CQ.FieldByName('MYCntrs').AsString;
      ByBandsStatus(5,dmData.CQ.SQL.Text,'MYCntrs');
    end;

     //list of own continent country prefixes
     //--------------------------------------------------------------
    if popCommonStatus.Items[6].Checked then
    begin
      dmData.CQ.Close;
      if dmData.trCQ.Active then dmData.trCQ.Rollback;
      dmData.CQ.SQL.Text :=
      'SELECT DISTINCT(pref) FROM cqrlog_common.dxcc_ref RIGHT JOIN cqrlog_main ON '+
      'cqrlog_common.dxcc_ref.adif = cqrlog_main.adif WHERE contestname='+
        QuotedStr(cmbContestName.Text)+' AND cqrlog_main.cont='+QuotedStr(Mycont)
        +' ORDER BY cqrlog_common.dxcc_ref.pref ASC';
       if dmData.DebugLevel >=1 then
                                        Writeln(dmData.CQ.SQL.Text);
       dmData.CQ.Open();
        dmData.CQ.First;
        while not dmData.CQ.EOF do
         begin
          if (dmData.CQ.Fields.FindField('pref')<> nil) then
            if dmData.CQ.FieldByName('pref').AsString<>'' then
              MyCountList:= MyCountList+dmData.CQ.FieldByName('pref').AsString+','
             else
              MyCountList:= MyCountList+'?,';
           dmData.CQ.Next;
         end;
      mStatus.Lines.Add(mycont+' Country list : '+MyCountList);
     end;

    //Msg multiplier (srx_string) count
    //--------------------------------------------------------------
    if popCommonStatus.Items[7].Checked then
     begin
      SRXSList:='';
      dmData.CQ.Close;
        if dmData.trCQ.Active then dmData.trCQ.Rollback;
        dmData.CQ.SQL.Text :=
           'SELECT COUNT(DISTINCT(UPPER(srx_string))) AS Msgs FROM cqrlog_main WHERE contestname='+
             QuotedStr(cmbContestName.Text)+' AND srx_string<>""';

        if dmData.DebugLevel >=1 then
                                     Writeln(dmData.CQ.SQL.Text);
      dmData.CQ.Open();
      if (dmData.CQ.Fields.FindField('Msgs')<> nil) then
               sgStatus.Cells[1,6]:=dmData.CQ.FieldByName('Msgs').AsString;
      ByBandsStatus(6,dmData.CQ.SQL.Text,'Msgs');
     end;

    //list of different srx_strings (msg multipliers)
    //--------------------------------------------------------------
    if popCommonStatus.Items[8].Checked then
    begin
      mStatus.Lines.Add('Msg multipliers list:');
      for b:=0 to 10 do
        begin
          dmData.CQ.Close;
          if dmData.trCQ.Active then dmData.trCQ.Rollback;
          dmData.CQ.SQL.Text :=
              'SELECT DISTINCT(UPPER(srx_string)) AS srx_msg FROM cqrlog_main WHERE contestname='+
               QuotedStr(cmbContestName.Text)+ ' AND band='+QuotedStr(dUtils.cBands[ContestBandPtr[b]])
               +' ORDER BY srx_msg ASC';
          if dmData.DebugLevel >=1 then
                                           Writeln(dmData.CQ.SQL.Text);
           dmData.CQ.Open();
           dmData.CQ.First;
           SRXSList:='';
           while not dmData.CQ.EOF do
            begin
             if (dmData.CQ.Fields.FindField('srx_msg')<> nil) then
               if dmData.CQ.FieldByName('srx_msg').AsString<>'' then
                SRXSList:= SRXSList+dmData.CQ.FieldByName('srx_msg').AsString+',';
              dmData.CQ.Next;
            end;
            if SRXSList<>'' then
              mStatus.Lines.Add('-'+dUtils.cBands[ContestBandPtr[b]]+'='+copy(SRXSList,1,length(SRXSList)-1));
        end;
     end;

    dmData.CQ.Close;
    dmData.trCQ.Rollback;
   Rates;
end;

procedure  TfrmContest.Rates;
Begin
  if AllQsos>0 then
    Begin
      try
    //last qso since
    //--------------------------------------------------------------
      dmData.CQ.Close;
      if dmData.trCQ.Active then dmData.trCQ.Rollback;
      dmData.CQ.SQL.Text :=
      'select sec_to_time(timestampdiff(second,concat(qsodate," ",time_off),utc_timestamp())) as last from cqrlog_main order by id_cqrlog_main desc limit 1';
      if dmData.DebugLevel >=1 then
                                       Writeln(dmData.CQ.SQL.Text);
      dmData.CQ.Open();
      if (dmData.CQ.Fields.FindField('last')<> nil) then
               lblQsoSince.Caption:='QS:'+dmData.CQ.FieldByName('last').AsString;

    //qso rate 10min
    //--------------------------------------------------------------
      dmData.CQ.Close;
      if dmData.trCQ.Active then dmData.trCQ.Rollback;
      dmData.CQ.SQL.Text :=
      'select count(callsign) as rate from cqrlog_main where timestampdiff(minute,concat(qsodate," ",time_off),utc_timestamp())<10';
      if dmData.DebugLevel >=1 then
                                       Writeln(dmData.CQ.SQL.Text);
      dmData.CQ.Open();
      if (dmData.CQ.Fields.FindField('rate')<> nil) then
               lblRate10.Caption:=dmData.CQ.FieldByName('rate').AsString+'/10';

    //qso rate 1h
    //--------------------------------------------------------------
    dmData.CQ.Close;
    if dmData.trCQ.Active then dmData.trCQ.Rollback;
    dmData.CQ.SQL.Text :=
    'select count(callsign) as rate from cqrlog_main where timestampdiff(minute,concat(qsodate," ",time_off),utc_timestamp())<60';
    if dmData.DebugLevel >=1 then
                                     Writeln(dmData.CQ.SQL.Text);
    dmData.CQ.Open();
    if (dmData.CQ.Fields.FindField('rate')<> nil) then
               lblRate60.Caption:=dmData.CQ.FieldByName('rate').AsString+'/60';


    finally
      dmData.CQ.Close;
      dmData.trCQ.Rollback;
    end;
    end;   // AllQsos>0

end;

finalization
  //The form is owned by Application and outlives everything, but the rules
  //object is ours, so hand it back rather than leaking it on exit.
  if frmContest <> nil then
  begin
    FreeAndNil(frmContest.ContestRules);
    FreeAndNil(frmContest.CallHist)
  end;

end.
