program testn1mm;
{$mode objfpc}{$H+}
uses SysUtils, uN1MMUdp;
var pass : Integer = 0; fail : Integer = 0;

procedure Check(const what,got,want : String);
begin
  if got=want then begin Inc(pass); WriteLn('  ok   ',what,' -> ',got) end
  else begin Inc(fail); WriteLn('  FAIL ',what,' -> got ',got,' want ',want) end
end;

begin
  WriteLn('frequency encoding (tens of Hz)');
  //The manual's own examples, which is the only safe source of truth here.
  Check('3525.19 kHz', IntToStr(N1MMFreq(3525.19)), '352519');
  Check('3522.11 kHz', IntToStr(N1MMFreq(3522.11)), '352211');
  Check('14025.19 kHz',IntToStr(N1MMFreq(14025.19)),'1402519');
  Check('1812.34 kHz', IntToStr(N1MMFreq(1812.34)), '181234');
  Check('7123.45 kHz', IntToStr(N1MMFreq(7123.45)), '712345');
  //Rounding, not truncation: a value a hair under must not drift down.
  Check('7000.009 kHz rounds', IntToStr(N1MMFreq(7000.009)), '700001');
  Check('14000 kHz exact',     IntToStr(N1MMFreq(14000)),    '1400000');
  Check('zero',                IntToStr(N1MMFreq(0)),        '0');

  WriteLn;
  WriteLn('xml escaping');
  //A comment with an ampersand must not produce an unparseable document.
  Check('ampersand', XmlEsc('R&S'),        'R&amp;S');
  Check('angle',     XmlEsc('a<b>c'),      'a&lt;b&gt;c');
  Check('quote',     XmlEsc('say "hi"'),   'say &quot;hi&quot;');
  Check('apostrophe',XmlEsc('it''s'),      'it&apos;s');
  Check('clean',     XmlEsc('N8EM'),       'N8EM');
  //Order matters: escaping & after < would double-escape the &lt;.
  Check('no double escape', XmlEsc('<&>'), '&lt;&amp;&gt;');

  WriteLn;
  WriteLn(pass,' passed, ',fail,' failed');
  if fail>0 then Halt(1)
end.
