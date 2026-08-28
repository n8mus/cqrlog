{ Proves CQRLOG's HTTPS actually works on the machine it is run on.

  Built from the same in-tree Synapse units the program itself uses, and it
  repeats TdmUtils.GetDataFromHttp exactly: THTTPSend + ssl_openssl, same
  dlopen of the bare 'libssl.so' soname. Installing a package only shows the
  dependency names resolve; this shows a TLS handshake completes against the
  real services, which is what every online feature depends on.

  A failure here is silent in the application: no error is shown, the update
  check, LoTW, eQSL, QRZ.com upload, callbook lookups and POTA spots simply
  stop doing anything.

  Exit code 0 = every required host answered over TLS, non-zero = at least
  one failed. Any HTTP status counts as success: we are testing that TLS
  works, not that a service likes our (absent) credentials. }
program ssltest;
{$mode objfpc}{$H+}
uses
  SysUtils, Classes, httpsend, ssl_openssl, ssl_openssl_lib;

type
  TCheck = record
    Host    : string;   { what it is used for }
    Url     : string;
    Required: boolean;  { third-party outages must not fail the build }
  end;

const
  Checks : array[0..5] of TCheck = (
    (Host: 'raw.githubusercontent.com (update check)';
     Url: 'https://raw.githubusercontent.com/n8mus/cqrlog/refs/heads/master/compiled/version.txt';
     Required: True),
    (Host: 'LoTW.arrl.org (LoTW upload/download)';
     Url: 'https://LoTW.arrl.org/lotwuser/lotwreport.adi'; Required: False),
    (Host: 'www.eqsl.cc (eQSL)';
     Url: 'https://www.eqsl.cc/qslcard/DownloadInBox.cfm'; Required: False),
    (Host: 'logbook.qrz.com (QRZ.com logbook upload)';
     Url: 'https://logbook.qrz.com/api'; Required: False),
    (Host: 'www.hamqth.com (callbook + web spots)';
     Url: 'https://www.hamqth.com/dxc_csv.php'; Required: False),
    (Host: 'api.pota.app (POTA spots)';
     Url: 'https://api.pota.app/spot/activator'; Required: False)
  );

function Fetch(const Url: string; out Status: integer; out Bytes: integer;
  out Err: string): boolean;
var
  HTTP: THTTPSend;
begin
  Result := False; Status := 0; Bytes := 0; Err := '';
  HTTP := THTTPSend.Create;
  try
    try
      if HTTP.HTTPMethod('GET', Url) then
      begin
        Status := HTTP.ResultCode;
        Bytes  := HTTP.Document.Size;
        { A completed transaction means the TLS handshake succeeded. }
        Result := True;
      end
      else
        Err := 'no response (TLS handshake or connection failed)';
    except
      on E: Exception do Err := E.ClassName + ': ' + E.Message;
    end;
  finally
    HTTP.Free;
  end;
end;

var
  i, Status, Bytes, Failed, Skipped: integer;
  Err: string;
begin
  Failed := 0; Skipped := 0;

  Write('OpenSSL: ');
  if InitSSLInterface then
  begin
    { OpenSSL 3 renamed SSLeay_version to OpenSSL_version, so this string is
      often empty on a modern system. That is cosmetic - the load succeeded. }
    if SSLeayversion(0) <> '' then
      WriteLn('loaded (', SSLeayversion(0), ')')
    else
      WriteLn('loaded (version string unavailable on OpenSSL 3)')
  end
  else
  begin
    WriteLn('FAILED TO LOAD');
    WriteLn('  Synapse could not dlopen the bare "libssl.so"/"libcrypto.so".');
    WriteLn('  On Debian/Ubuntu that symlink ships in libssl-dev.');
    WriteLn('  Every HTTPS feature in CQRLOG is dead without it.');
    Halt(1);
  end;
  WriteLn;

  for i := Low(Checks) to High(Checks) do
  begin
    Write('  ', Checks[i].Host, ' ... ');
    if Fetch(Checks[i].Url, Status, Bytes, Err) then
      WriteLn('OK over TLS (HTTP ', Status, ', ', Bytes, ' bytes)')
    else
    begin
      if Checks[i].Required then
      begin
        WriteLn('FAILED - ', Err);
        Inc(Failed);
      end
      else
      begin
        WriteLn('unreachable, not counted - ', Err);
        Inc(Skipped);
      end;
    end;
  end;

  WriteLn;
  if Failed > 0 then
  begin
    WriteLn('RESULT: HTTPS is broken here (', Failed, ' required host(s) failed).');
    Halt(1);
  end;
  if Skipped > 0 then
    WriteLn('RESULT: TLS works. ', Skipped,
            ' third-party host(s) did not answer - treated as their outage, not ours.')
  else
    WriteLn('RESULT: TLS works against every service CQRLOG uses.');
end.
