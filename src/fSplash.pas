(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fSplash;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  buttons, ExtCtrls;

type

  { TfrmSplash }

  TfrmSplash = class(TForm)
    Image1: TImage;
    Image2: TImage;
    procedure FormCreate(Sender: TObject);

  private
    { private declarations }
  public
    { public declarations }
    procedure ImageVText(I:TImage;c:Tcolor=clRed);
  end;

const
  // The version is right-aligned into the clear white corner of the splash
  // artwork. Do NOT go back to a fixed-width, Clipping=True rectangle: the
  // version string grows a character on every release ("(9)" -> "(12)") and a
  // centred, clipped rect silently ate a letter off each end per bump until
  // "Enhanced" had lost its E. Clipping is off and the rect spans most of the
  // image width so the text can never be trimmed without it being obvious.
  VersionMarginRight  = 10;  // px from the right edge of the artwork
  VersionMarginBottom = 4;   // px from the bottom edge of the artwork
  VersionFontHeight   = 19;  // px; bold
  VersionStyle: TTextStyle =
   (
     Alignment  : taRightJustify;
     Layout     : tlBottom;
     SingleLine : True;
     Clipping   : False;
     ExpandTabs : False;
     ShowPrefix : False;
     Wordbreak  : False;
     Opaque     : False;
     SystemFont : False;
     RightToLeft: False;
     EndEllipsis: False
   );
var
  frmSplash: TfrmSplash;

implementation
{$R *.lfm}

uses uVersion;

{ TfrmSplash }

procedure TfrmSplash.FormCreate(Sender: TObject);
begin
  Width  := Image1.Picture.Width;
  Height := Image1.Picture.Height;
end;

// cVERSION carries the widget set ('Enhanced_(12)_Gtk2') for the About box and
// the update check; the splash only wants the human-readable fork + release.
function SplashVersionText : String;
Begin
  Result := Trim(StringReplace(cVersionBase, '_', ' ', [rfReplaceAll]))
end;

procedure TfrmSplash.ImageVText(I:Timage;c:Tcolor=clRed);
var
  ATextRect: TRect;
  Cnv      : TCanvas;
Begin
  Cnv := I.Picture.Bitmap.Canvas;
  Cnv.Font.Style  := [fsBold];
  Cnv.Font.Color  := c;
  Cnv.Font.Height := VersionFontHeight;
  Cnv.Brush.Style := bsClear;
  ATextRect := Rect(0,
                    I.Picture.Height - VersionMarginBottom - VersionFontHeight,
                    I.Picture.Width  - VersionMarginRight,
                    I.Picture.Height - VersionMarginBottom);
  Cnv.TextRect(ATextRect, ATextRect.Left, ATextRect.Top, SplashVersionText, VersionStyle);
  Application.ProcessMessages;
end;

end.

