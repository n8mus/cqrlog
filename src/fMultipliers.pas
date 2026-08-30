unit fMultipliers;

{
  Multipliers window: which multipliers are worked, on which band.

  N1MM's Multipliers window in miniature. The point is not the total - the
  contest status pane already shows that - it is seeing the HOLES, so a spot
  for a country you are missing on 40 is recognisable as worth chasing.

  Rows are multiplier values, columns are bands, a mark means worked. The grid
  is rebuilt from the log through the same rule engine that scores the contest,
  so what it shows and what the score counts can never disagree.
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, Grids, ExtCtrls, uContestRules;

type

  { TfrmMultipliers }

  TfrmMultipliers = class(TForm)
    cmbMult: TComboBox;
    lblMult: TLabel;
    pnlTop: TPanel;
    sgMults: TStringGrid;
    sbMult: TStatusBar;
    procedure cmbMultChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure sgMultsPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
  private
    fBands : TStringList;   //column order
    procedure Rebuild;
  public
    //Called by the contest window after a score refresh so the grid follows
    //the log without this window having to poll it.
    procedure RefreshIfShowing;
  end;

var
  frmMultipliers : TfrmMultipliers;

implementation

{$R *.lfm}

uses dUtils, dData, fContest, uMyIni;

const
  cWorked = 'X';

{ TfrmMultipliers }

procedure TfrmMultipliers.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(Self);
  if fBands = nil then fBands := TStringList.Create;
  Rebuild
end;

procedure TfrmMultipliers.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(Self)
end;

procedure TfrmMultipliers.cmbMultChange(Sender: TObject);
begin
  Rebuild
end;

procedure TfrmMultipliers.RefreshIfShowing;
begin
  if Showing then Rebuild
end;

procedure TfrmMultipliers.sgMultsPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
  aState: TGridDrawState);
begin
  if (aRow = 0) or (aCol = 0) then exit;
  //Worked cells read as solid, missing ones stay blank - the eye is looking
  //for the gaps, so the gaps are what must be visually quiet.
  if sgMults.Cells[aCol,aRow] = cWorked then
  begin
    sgMults.Canvas.Brush.Color := $00D8F0D8;   //muted green
    sgMults.Canvas.Font.Color  := clBlack
  end
end;

procedure TfrmMultipliers.Rebuild;
var
  rules   : TContestRules;
  ctx     : TQsoCtx;
  seen    : TStringList;   //"value" -> worked band list
  worked  : TStringList;   //dupe keys, in log order
  idx,i,r : Integer;
  key,val,
  band,fn : String;
  bandIdx : Integer;
  vals    : TStringList;
begin
  if fBands = nil then fBands := TStringList.Create;
  sgMults.Clear;
  sgMults.RowCount := 1;
  sgMults.ColCount := 1;
  sbMult.SimpleText := '';
  if frmContest = nil then exit;

  fn := ContestDefFile(dmData.HomeDir,frmContest.cmbContestName.Text);
  rules := TContestRules.Create;
  seen := TStringList.Create;
  worked := TStringList.Create;
  vals := TStringList.Create;
  try
    if not rules.LoadFromFile(fn) then
    begin
      sbMult.SimpleText := 'No contest rule definition for '+
                           frmContest.cmbContestName.Text;
      exit
    end;

    //Which of the (up to three) multipliers are we showing?
    if cmbMult.Items.Count = 0 then
    begin
      for i := 1 to 3 do
        if rules.MultName(i) <> '' then
          cmbMult.Items.AddObject(IntToStr(i)+': '+rules.MultName(i),TObject(PtrInt(i)));
      if cmbMult.Items.Count > 0 then cmbMult.ItemIndex := 0
    end;
    if cmbMult.ItemIndex < 0 then
    begin
      sbMult.SimpleText := 'This contest defines no multipliers';
      exit
    end;
    idx := PtrInt(cmbMult.Items.Objects[cmbMult.ItemIndex]);

    worked.Sorted := True;
    worked.Duplicates := dupIgnore;
    seen.Sorted := True;
    seen.Duplicates := dupIgnore;
    fBands.Clear;

    dmData.Q.Close;
    if dmData.trQ.Active then dmData.trQ.Rollback;
    dmData.trQ.StartTransaction;
    try
      dmData.Q.SQL.Text :=
        'select m.callsign,m.band,m.mode,m.cont,m.waz,m.itu,m.loc,m.my_loc,m.state,'+
        'm.srx,m.srx_string,d.dxcc_ref '+
        'from cqrlog_main m left join dxcc_id d on d.adif=m.adif '+
        'where m.contestname='+QuotedStr(frmContest.cmbContestName.Text)+' '+
        'order by m.qsodate,m.time_on,m.id_cqrlog_main';
      dmData.Q.Open;
      while not dmData.Q.Eof do
      begin
        ctx := Default(TQsoCtx);
        ctx.Call       := UpperCase(Trim(dmData.Q.FieldByName('callsign').AsString));
        ctx.Band       := UpperCase(Trim(dmData.Q.FieldByName('band').AsString));
        ctx.Mode       := UpperCase(Trim(dmData.Q.FieldByName('mode').AsString));
        ctx.Continent  := UpperCase(Trim(dmData.Q.FieldByName('cont').AsString));
        ctx.CountryPfx := UpperCase(Trim(dmData.Q.FieldByName('dxcc_ref').AsString));
        ctx.ZoneCQ     := Trim(dmData.Q.FieldByName('waz').AsString);
        ctx.ZoneITU    := Trim(dmData.Q.FieldByName('itu').AsString);
        ctx.Grid       := Trim(dmData.Q.FieldByName('loc').AsString);
        ctx.MyGrid     := Trim(dmData.Q.FieldByName('my_loc').AsString);
        ctx.State      := Trim(dmData.Q.FieldByName('state').AsString);
        ctx.SerialRcvd := Trim(dmData.Q.FieldByName('srx').AsString);
        ctx.ExchRcvd   := Trim(dmData.Q.FieldByName('srx_string').AsString);

        //Same dupe recomputation as the scorer: a dupe is not a multiplier,
        //and it is decided by what came before, never by the entry form.
        case rules.DupeType of
          dpOncePerContest : key := ctx.Call;
          dpPerBandMode    : key := ctx.Call+'|'+ctx.Band+'|'+ctx.Mode;
          dpNone           : key := '';
        else                  key := ctx.Call+'|'+ctx.Band
        end;
        ctx.IsDupe := (key <> '') and (worked.IndexOf(key) >= 0);
        if key <> '' then worked.Add(key);

        //MultKey bakes the scope in; we want the bare value plus the band it
        //was worked on, so ask for the value and track bands ourselves.
        val := rules.MultKey(idx,ctx);
        if val <> '' then
        begin
          //strip the scope suffix the engine appended
          i := Pos('|',val);
          if i > 0 then val := Copy(val,1,i-1);
          band := ctx.Band;
          if fBands.IndexOf(band) < 0 then fBands.Add(band);
          r := seen.IndexOf(val);
          if r < 0 then
            seen.AddObject(val,TObject(TStringList.Create));
          r := seen.IndexOf(val);
          if TStringList(seen.Objects[r]).IndexOf(band) < 0 then
            TStringList(seen.Objects[r]).Add(band)
        end;
        dmData.Q.Next
      end;
      dmData.Q.Close
    finally
      dmData.trQ.Rollback
    end;

    fBands.Sort;
    sgMults.ColCount := fBands.Count + 1;
    sgMults.RowCount := seen.Count + 1;
    sgMults.Cells[0,0] := rules.MultName(idx);
    for i := 0 to fBands.Count-1 do
      sgMults.Cells[i+1,0] := fBands[i];
    for r := 0 to seen.Count-1 do
    begin
      sgMults.Cells[0,r+1] := seen[r];
      for i := 0 to fBands.Count-1 do
        if TStringList(seen.Objects[r]).IndexOf(fBands[i]) >= 0 then
          sgMults.Cells[i+1,r+1] := cWorked
    end;
    sgMults.AutoSizeColumns;

    sbMult.SimpleText := IntToStr(seen.Count)+' '+rules.MultName(idx)+
                         ' multipliers worked across '+IntToStr(fBands.Count)+' bands'
  finally
    for r := 0 to seen.Count-1 do
      if seen.Objects[r] <> nil then TStringList(seen.Objects[r]).Free;
    vals.Free;
    worked.Free;
    seen.Free;
    rules.Free
  end
end;

finalization
  if frmMultipliers <> nil then FreeAndNil(frmMultipliers.fBands);

end.
