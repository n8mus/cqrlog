program sendn1mm;
{ Drives uN1MMUdp for real: builds its own ini, points it at a local port and
  sends one of each datagram. A listener started alongside prints the bytes,
  so the wire format can be checked against the N1MM spec rather than assumed. }
{$mode objfpc}{$H+}
uses SysUtils, uMyIni, uN1MMUdp;
var
  c : TN1MMContact;
begin
  cqrini := TMyIni.Create('/tmp/n1mmtest.ini','/tmp/n1mmtest.ini');
  cqrini.WriteBool('N1MM','Enabled',True);
  cqrini.WriteBool('N1MM','Spots',True);
  cqrini.WriteString('N1MM','Dest','127.0.0.1:12060');
  N1MMUdp.Configure;
  WriteLn('enabled=',N1MMUdp.Enabled);

  N1MMUdp.SendAppInfo('cqrlog001','CQ-WPX-CW','shack','N8EM',1);

  c := Default(TN1MMContact);
  c.ContestName:='CQ-WPX-CW'; c.ContestNr:=1;
  c.TimeStamp:='2026-08-29 13:45:00';
  c.MyCall:='N8EM'; c.Call:='DL1ABC';
  c.BandMHz:='14'; c.RxFreqKHz:=14025.19; c.TxFreqKHz:=14025.19;
  c.Mode:='CW'; c.Snt:='599'; c.Rcv:='599'; c.SntNr:='12'; c.RcvNr:='34';
  c.CountryPfx:='DL'; c.WpxPrefix:='DL1'; c.Continent:='EU';
  c.Points:=3; c.IsMultiplier1:=1; c.IsRunQSO:=1;
  c.StationName:='shack'; c.ID:='deadbeefdeadbeefdeadbeefdeadbeef';
  c.Comment:='R&S "test" <ok>';
  N1MMUdp.SendContact(c);

  N1MMUdp.SendRadioInfo('shack','N8EM','N8EM','CW',1,3522.11,3522.11,True,False,False);
  N1MMUdp.SendSpot('shack','K1ABC','N8EM-#','CW','CQ TEST','single mult',
                   '2026-08-29 13:46:00',7061.2,True);
  Sleep(300);
  WriteLn('sent');
end.
