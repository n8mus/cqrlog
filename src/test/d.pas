program d; {$mode objfpc}{$H+}
uses SysUtils, uContestRules;
procedure S(const a,b:String);
var km:Double; begin km:=GridDistanceKm(a,b);
  WriteLn(Format('  %s -> %-6s %7.0f km  => %d points',[a,b,km,1+Trunc(km/3000)])) end;
begin S('EN83','QG62'); S('EN83','EM80'); end.
