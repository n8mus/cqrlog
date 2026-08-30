program testgrid;
{$mode objfpc}{$H+}
uses SysUtils, Math, uContestRules;
var pass:Integer=0; fail:Integer=0;
procedure Near(const what:String; got,want,tol:Double);
begin
  if Abs(got-want)<=tol then begin Inc(pass); WriteLn(Format('  ok   %-34s %8.0f (want ~%.0f)',[what,got,want])) end
  else begin Inc(fail); WriteLn(Format('  FAIL %-34s %8.0f want %.0f +/-%.0f',[what,got,want,tol])) end
end;
var la,lo:Double;
begin
  WriteLn('grid -> lat/lon (square centre)');
  //EN82 is south-east Michigan; well known reference values.
  if GridToLatLon('EN82',la,lo) then
  begin
    Near('EN82 lat',la,42.5,0.6); Near('EN82 lon',lo,-83.0,1.2)
  end else begin WriteLn('  FAIL EN82 did not parse'); Inc(fail) end;
  //JN58 is Munich.
  if GridToLatLon('JN58',la,lo) then
  begin
    Near('JN58 lat',la,48.5,0.6); Near('JN58 lon',lo,11.0,1.2)
  end else begin WriteLn('  FAIL JN58 did not parse'); Inc(fail) end;
  //A bare 2-char field resolves to the middle of the field.
  if GridToLatLon('EN',la,lo) then begin Near('EN field lat',la,45,0.1); Near('EN field lon',lo,-90,0.1) end;

  WriteLn;
  WriteLn('great circle distance (km)');
  Near('EN82 -> JN58  Detroit-Munich', GridDistanceKm('EN82','JN58'), 6800, 400);
  Near('EN82 -> EN82  same square',    GridDistanceKm('EN82','EN82'), 0,    1);
  Near('EN82 -> FN20  Detroit-Philly', GridDistanceKm('EN82','FN20'), 750,  200);
  Near('JN58 -> PM95  Munich-Tokyo',   GridDistanceKm('JN58','PM95'), 9400, 600);
  Near('EN82 -> QF56  Detroit-Sydney', GridDistanceKm('EN82','QF56'),15900, 800);

  WriteLn;
  WriteLn('bad input must not blow up or invent a distance');
  Near('empty',   GridDistanceKm('',''),      0,0.1);
  Near('garbage', GridDistanceKm('ZZ99','EN82'),0,0.1);
  Near('too short',GridDistanceKm('E','EN82'), 0,0.1);

  WriteLn;
  WriteLn(pass,' passed, ',fail,' failed');
  if fail>0 then Halt(1)
end.
