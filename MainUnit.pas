unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, StdCtrls, Spin, Grids, pngextra, pngimage, ComCtrls,
  ExtCtrls, Menus, ImgList;


type
  TfmMain = class(TForm)
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    ColorDialog: TColorDialog;
    Panel1: TPanel;
    gPal: TDrawGrid;
    Label9: TLabel;
    ePalAddress: TEdit;
    Label10: TLabel;
    sePalNum: TSpinEdit;
    bLoadPalROM: TPNGButton;
    Label11: TLabel;
    eAddress: TEdit;
    bAddAddress: TPNGButton;
    bDelAddress: TPNGButton;
    Panel2: TPanel;
    bOpenROM: TSpeedButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    Label8: TLabel;
    bNew: TPNGButton;
    bLoad: TPNGButton;
    bSave: TPNGButton;
    Label12: TLabel;
    seWidth: TSpinEdit;
    seHeight: TSpinEdit;
    seOffset: TSpinEdit;
    eName: TEdit;
    seZoom: TSpinEdit;
    cbTemplate: TComboBox;
    sBar: TStatusBar;
    bPalMono: TPNGButton;
    bPalMonoReverse: TPNGButton;
    Label4: TLabel;
    cbCompression: TComboBox;
    Image: TImage;
    bExport: TPNGButton;
    bOpenPal: TPNGButton;
    dOpenPal: TOpenDialog;
    popList: TPopupMenu;
    miNewAddressfromtheEnd: TMenuItem;
    bSavePal: TPNGButton;
    dSavePal: TSaveDialog;
    Panel3: TPanel;
    lbList: TListBox;
    Panel4: TPanel;
    bGraphicUp: TPNGButton;
    bGraphicDown: TPNGButton;
    bAddAfterEnd: TPNGButton;
    bSortName: TPNGButton;
    miMoveUp: TMenuItem;
    miMoveDown: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    miAddAddress: TMenuItem;
    miDelAddress: TMenuItem;
    N3: TMenuItem;
    miSortByName: TMenuItem;
    miSortByAddress: TMenuItem;
    ImageList1: TImageList;
    bSortAddress: TPNGButton;
    procedure bOpenROMClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lbListClick(Sender: TObject);
    procedure ValueChange(Sender: TObject);
    procedure bAddAddressClick(Sender: TObject);
    procedure seZoomChange(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
    procedure bLoadClick(Sender: TObject);
    procedure bDelAddressClick(Sender: TObject);
    procedure gPalDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure bPalMonoClick(Sender: TObject);
    procedure gPalMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure bLoadPalROMClick(Sender: TObject);
    procedure eAddressKeyPress(Sender: TObject; var Key: Char);
    procedure bNewClick(Sender: TObject);
    procedure ePalAddressKeyPress(Sender: TObject; var Key: Char);
    procedure FormDestroy(Sender: TObject);
    procedure bExportClick(Sender: TObject);
    procedure bOpenPalClick(Sender: TObject);
    procedure miNewAddressfromtheEndClick(Sender: TObject);
    procedure bSavePalClick(Sender: TObject);
    procedure bGraphicUpClick(Sender: TObject);
    procedure bGraphicDownClick(Sender: TObject);
    procedure bSortByNameClick(Sender: TObject);
  private
    ROM: array of byte;
    NoChange: boolean;
    RomName, DocName: string;

    procedure LoadROM(const FileName:string);
    procedure UpdatePreview;
    procedure EmptyList;
    procedure EnableContols(State: boolean; Index: integer);
    procedure CompressionChange;
    procedure SetCaption;
    procedure NewDraw;
  public
  end;

var
  fmMain: TfmMain;

implementation
{$R *.dfm}

uses uCommon, uCompress, uTiles;


var
  Spr: pVisual;
  //MobTiles: array[0..1000, 0..7, 0..7] of byte;
  Pal: tPalette;


procedure MakeMonoPal(var Pal: tPalette; Num: integer; Reverse: boolean = false);
  var i, r: integer;
begin
  for i:= 0 to Num - 1 do begin
    r := (i * 255) div (Num -1);
    if Reverse then Pal[Num -1 -i] := R + R shl 8 + R shl 16
               else Pal[i] := R + R shl 8 + R shl 16;
  end;
end;


function Power2(N: cardinal): cardinal;
  var i: integer;
begin
  Result := 1;
  for i := 1 to n do
    Result := Result shl 1;
end;




procedure TfmMain.LoadROM(const FileName:string);
  var f, n: cardinal;
begin
  RomName := FileName;
  SetCaption;
  f := CreateFile(pchar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if f = INVALID_HANDLE_VALUE then raise Exception.Create(format('%s not found', [Caption]));
  n := GetFileSize(f, nil);
  SetLength(ROM, n);
  ReadFile(f, ROM[0], n, n, nil);
  CloseHandle(f);

  // Enable controls
  bNew.Enabled := true;
  bLoad.Enabled := true;
  bSave.Enabled := true;

  ePalAddress.Enabled := true;
  bLoadPalROM.Enabled := true;

  eAddress.Enabled    := true;
  bAddAddress.Enabled := true;
  bDelAddress.Enabled := true;
end;


procedure TfmMain.bOpenROMClick(Sender: TObject);
begin
  OpenDialog.Filter := 'SNES/GBA ROM|*.smc; *.sfc; *.gba|SNES ROM|*.smc; *.sfc|GBA ROM|*.gba|ALL|*.*';
  if OpenDialog.Execute then
    LoadROM(OpenDialog.FileName);
end;


procedure TfmMain.FormCreate(Sender: TObject);
  var i: integer;
begin
//  LoadROM('D:\Emulators\GBA\ROM\1805 - Final Fantasy I & II - Dawn of Souls (U)(Independent).gba');
  for i := 1 to cTmplNum do
    cbTemplate.AddItem(cTemplate[i].Name, tObject(i));

  for i := 0 to cCmpNum do
    cbCompression.Items.Add(cCompression[i].Name);

  GetMem( PalBMP, Sizeof( TLogPalette ) + Sizeof( TPaletteEntry ) * 255 );
  FillChar(PalBMP.palPalEntry[0], 256*4, 0);
  PalBMP.palVersion := $300;
  PalBMP.palNumEntries := 256;
  hPalBMP := CreatePalette(PalBMP^);


  bmp := TBitmap.Create;
  bmp.PixelFormat := pf8bit;
  bmp.Palette := hPalBMP;

  SetLength(Buf, 1024*1024);
  //LoadROM('S:\Test\FFV\work\2564 - Final Fantasy V Advance (U)(Independent).gba');
  //LoadROM('D:\Emulators\GBA\ROM\2564 - Final Fantasy V Advance (U)(Independent).gba');
end;


procedure TfmMain.FormDestroy(Sender: TObject);
begin
  DeleteObject(hPalBMP);
  FreeMem(PalBMP);
  bmp.Free;

  SetLength(Buf, 0);
end;



procedure TfmMain.SetCaption;
begin
  Caption := format('Visual SAK - %s  -  %s', [DocName, RomName]);
end;


procedure TfmMain.UpdatePreview;
begin
  if Spr.Tmpl = 0 then exit;

  NewDraw;
  //DrawMobSpriteGBA(fmMain.Handle, 170, 60, Spr.W, Spr.H, seZoom.Value, true, @MobTiles, @Spr.Pal)
  //DrawSprite(fmMain.Handle, 170, 60, Spr.W, Spr.H, seZoom.Value, true, @MobTiles, @Spr.Pal, 8, 16)
end;


procedure TfmMain.CompressionChange;
  var n: integer;
begin
  FillChar(Buf[0], 1024*1024, 0);
  case Spr.Cmp of
    ctNone:
      Spr.SizeRaw := (Spr.W * Spr.H * Spr.tW * Spr.tH * Spr.BPP) shr 3;
    ctLZ77_10: begin
      Spr.SizeRaw := pCardinal( @ROM[Spr.Address] )^ shr 8;
      Spr.SizeCmp := DecodeLZ77InMem( @ROM[Spr.Address], tLZStream(Buf));
     end;
    ctLZSS_FF5: begin
      Spr.SizeRaw := pWord( @ROM[Spr.Address] )^;
      Spr.SizeCmp := DecodeLZSS_FF5( @ROM[Spr.Address], tLZStream(Buf));
    end;
    ctLZSS_FF6: begin
      Spr.SizeCmp := pWord( @ROM[Spr.Address] )^;
      Spr.SizeRaw := DecodeLZSS_FF6( @ROM[Spr.Address], tLZStream(Buf));
    end;
    ctLZSS_CT: begin
      Spr.SizeCmp := pWord( @ROM[Spr.Address] )^;
      Spr.SizeRaw := DecodeLZSS_CT( @ROM[Spr.Address], tLZStream(Buf));
    end;
  end;

  if (Spr.tW = 1) and (Spr.tH = 1) then n := 0
                                   else n := Spr.SizeRaw div (Spr.BPP shl 3);
  sBar.Panels[0].Text := format('#Tiles: '+cFmt, [n, n]);
  sBar.Panels[1].Text := format('RawSize: '+cFmt, [Spr.SizeRaw, Spr.SizeRaw]);
  sBar.Panels[2].Text := format('Compr.Size: '+cFmt, [Spr.SizeCmp, Spr.SizeCmp]);

  FillChar(Pal, 256*4, 0);
  Move(Spr.Pal, Pal, Spr.PalNum * 4);
  gPal.Repaint;
end;


procedure TfmMain.lbListClick(Sender: TObject);
begin
  bExport.Enabled := lbList.ItemIndex >=0;
  if lbList.ItemIndex < 0 then exit;
  Spr := pointer(lbList.Items.Objects[lbList.ItemIndex]);

  NoChange := true;
  seWidth.Value  := Spr.W;
  seHeight.Value := Spr.H;
  seOffset.Value := Spr.Off;
  eName.Text     := Spr.Name;
  eAddress.Text  := format('$%.6x',[Spr.Address]);
  ePalAddress.Text := format('$%.6x',[Spr.PalAdr]);
  sePalNum.Value := Spr.PalNum;
  EnableContols(true, cbTemplate.Items.IndexOfObject(tObject(Spr.Tmpl)) );
  cbCompression.ItemIndex := Spr.Cmp;
  CompressionChange;
  NoChange := false;

  UpdatePreview;
end;


procedure TfmMain.ValueChange(Sender: TObject);
begin
  if (NoChange) or (Spr = nil) then exit;

  if Sender = cbTemplate then begin
    EnableContols(true, cbTemplate.ItemIndex);
    Spr.Tmpl := byte(cbTemplate.Items.Objects[cbTemplate.ItemIndex]);
    Spr.BPP  := cTemplate[Spr.Tmpl].BPP;
    Spr.tW   := cTemplate[Spr.Tmpl].tW;
    Spr.tH   := cTemplate[Spr.Tmpl].tH;
    Spr.PalNum := 1 shl Spr.BPP;
    sePalNum.Value := Spr.PalNum;
    MakeMonoPal(Spr.Pal, Spr.PalNum);
  end else begin
    Spr.W    := seWidth.Value;
    Spr.H    := seHeight.Value;
    Spr.Off  := seOffset.Value;
    Spr.Name := eName.Text;
    lbList.Items[lbList.ItemIndex] := Spr.Name;
    Spr.Cmp := cbCompression.ItemIndex;
    CompressionChange;
  end;

  if Sender <> eName then UpdatePreview;
end;


procedure TfmMain.bAddAddressClick(Sender: TObject);
  var v: pVisual;
      n: integer;
begin
  New(v);
  FillChar(v^, Sizeof(v^), 0);
  v.Address := StrToInt(eAddress.Text);
  v.Name := eAddress.Text;
  v.H    := seHeight.Value;
  v.W    := seWidth.Value;
  v.Off  := seOffset.Value;

  if cbTemplate.ItemIndex < 0 then n := 0
                              else n := integer(cbTemplate.Items.Objects[cbTemplate.ItemIndex]);
  v.Tmpl := n;
  v.BPP  := cTemplate[n].BPP;
  v.tW   := cTemplate[n].tW;
  v.tH   := cTemplate[n].tH;
  v.PalNum := 1 shl v.BPP;;
  MakeMonoPal(v.Pal, v.PalNum);

  lbList.AddItem(v.Name, tObject(v));
  lbList.ItemIndex := lbList.Count -1;
  lbListClick(Self);
end;

procedure TfmMain.seZoomChange(Sender: TObject);
begin
  UpdatePreview;
end;


procedure TfmMain.bSaveClick(Sender: TObject);
  var i: integer;
      f: file of tVisual;
begin
  SaveDialog.Filter := 'Visual SAK (*.vsk)|*.vsk|ALL (*.*)|*.*';
  if not SaveDialog.Execute then exit;

  AssignFile(f, SaveDialog.FileName);
  Rewrite(f);
  for i := 0 to lbList.Count -1 do
    Write(f, pVisual(lbList.Items.Objects[i])^);
  CloseFile(f);
end;


procedure TfmMain.bLoadClick(Sender: TObject);
  var i, n: integer;
      f: file of tVisual;
      v: pVisual;
begin
  OpenDialog.Filter := 'Visual SAK (*.vsk)|*.vsk|ALL (*.*)|*.*';
  if not OpenDialog.Execute then exit;
  DocName := OpenDialog.FileName;
  SetCaption;

  AssignFile(f, OpenDialog.FileName);
  Reset(f);
  n := FileSize(f);  // return number of records, no size in bytes
  EmptyList;
  for i := 1 to n do begin
    New(v);
    Read(f, v^);
    lbList.AddItem(v.Name, tObject(v));
  end;
  CloseFile(f);
end;


procedure TfmMain.bDelAddressClick(Sender: TObject);
  var ind: integer;
begin
  ind := lbList.ItemIndex;
  if ind < 0 then exit;

  lbList.Items.Delete(ind);
  if ind = lbList.Count then dec(ind);
  if ind < 0 then exit;
  lbList.Selected[ind] := true;
end;


procedure TfmMain.gPalDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
  var r: cardinal;
begin
  r := aCol + aRow shl 4;
  gPal.Canvas.Brush.Color := Pal[r]{r + r shl 8 + r shl 16};
  gPal.Canvas.Rectangle(Rect);
  DrawEdge(gPal.Canvas.Handle, Rect, EDGE_SUNKEN, BF_RECT);
end;


procedure TfmMain.bPalMonoClick(Sender: TObject);
begin
  ZeroMemory(@Pal[0], 256*4);
  MakeMonoPal(Pal, sePalNum.Value, Sender = bPalMonoReverse);
  gPal.Repaint;

  if Spr = nil then exit;
  MakeMonoPal(Spr.Pal, Spr.PalNum, Sender = bPalMonoReverse);
  UpdatePreview;
end;


procedure TfmMain.gPalMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  var c, r, i: integer;
begin
  gPal.MouseToCell(X, Y, c, r);
  i := c + r shl 4;
  ColorDialog.Color := Pal[i];
  if not ColorDialog.Execute then exit;

  Pal[i] := ColorDialog.Color;

  if lbList.ItemIndex < 0 then exit;
  pVisual(lbList.Items.Objects[lbList.ItemIndex]).Pal[i] := ColorDialog.Color;
  UpdatePreview;
end;


procedure TfmMain.bLoadPalROMClick(Sender: TObject);
  var i: integer;
      p: pWord;
      R, G, B: byte;
begin
  if Spr = nil then exit;
  ZeroMemory(@Pal[0], 256*4);
  Spr.PalAdr := StrToInt(ePalAddress.Text);
  p := @ROM[Spr.PalAdr];
  for i := 0 to sePalNum.Value -1 do begin
    R := p^ and $1F;
    G := (p^ shr 5) and $1F;
    B := (p^ shr 10) and $1F;
    Pal[i] := (R * 255) div 31 + ((G*255) div 31) shl 8 + ((B*255) div 31 ) shl 16;
    inc(p);
  end;
  gPal.Repaint;

  Move(Pal, Spr.Pal, Spr.PalNum * 4);
  UpdatePreview;
end;


procedure TfmMain.eAddressKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then begin
    Key := #0;
    bAddAddressClick(nil);
  end;
end;


procedure TfmMain.bNewClick(Sender: TObject);
begin
  EmptyList;
  Spr := nil;
end;


procedure TfmMain.EmptyList;
  var i: integer;
begin
  for i := 0 to lbList.Count - 1 do
    Dispose(pointer(lbList.Items.Objects[i]));
  lbList.Clear;
end;


procedure TfmMain.ePalAddressKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then begin
    Key := #0;
    bLoadPalROMClick(nil);
  end;
end;


procedure TfmMain.EnableContols(State: boolean; Index: integer);
begin
  NoChange := true;
  cbTemplate.Enabled := State;
  cbTemplate.ItemIndex := Index;
  cbCompression.Enabled := State;

  seZoom.Enabled    := Index >= 0;
  seWidth.Enabled   := Index >= 0;
  seHeight.Enabled  := Index >= 0;
  seOffset.Enabled  := Index >= 0;
  NoChange := false;
end;


procedure  TfmMain.NewDraw;
  var w, h : integer;
      Src: pByte;
      tmp: array[0..255] of cardinal;
begin
  bmp.Width  := Spr.W * Spr.tW;
  bmp.Height := Spr.H * Spr.tH;

  Move(Spr.Pal[0], tmp[0], 256 *4);
  tmp[0] := ColorToRGB(Color);
  ByteSwapColors(tmp[0], 256);
  SetDIBColorTable(bmp.Canvas.Handle, 0, 256, tmp[0]);

  if Spr.Cmp > 0 then Src := @buf[Spr.Off]
                 else Src := @ROM[Spr.Address+Spr.Off];
  case Spr.Tmpl of
     1: Convert_4BppGBA   (bmp, Src, Spr.W, Spr.H);
     2: Convert_4BppSNES  (bmp, pByteArray(Src), Spr.W, Spr.H);
     3: Convert_3BppSNES  (bmp, pByteArray(Src), Spr.W, Spr.H);
     4: Convert_2BppSNES  (bmp, pByteArray(Src), Spr.W, Spr.H);
     6: Convert_8BppMode7 (bmp, pByteArray(Src), Spr.W, Spr.H);
     7: Convert_8BppMode7b(bmp, pByteArray(Src), Spr.W, Spr.H);
     8: Convert_8BppMode3 (bmp, pByteArray(Src), Spr.W, Spr.H);
     9: Convert_8BppPC    (bmp, Src, Spr.W, Spr.H);
    10: Convert_4BppFX    (bmp, Src, Spr.W, Spr.H);
  end;

  w := bmp.Width * seZoom.Value;
  h := bmp.Height * seZoom.Value;
  Image.Picture.Bitmap.Width  := w;
  Image.Picture.Bitmap.Height := h;
  Image.Canvas.StretchDraw(Bounds(0, 0, w, h), bmp);
end;


procedure TfmMain.bExportClick(Sender: TObject);
  var png: tPngObject;
begin
  SaveDialog.Filter := 'PNG Image (*.png)|*.png|ALL (*.*)|*.*';
  if not SaveDialog.Execute then exit;

  //bmp.TransparentColor := $1000000;
  //bmp.TransparentMode := tmFixed;
  bmp.Transparent := true;
  png := TPNGObject.Create;
  png.Assign(bmp);
  png.CompressionLevel := 9;
  //png.TransparentColor := $1000000;
  //png.Transparent := true;
  png.SaveToFile(SaveDialog.FileName);
  png.Free;
  bmp.Transparent := false;
end;


procedure TfmMain.bOpenPalClick(Sender: TObject);
  var e: string;
begin
  if not dOpenPal.Execute then exit;

  e := UpperCase(ExtractFileExt(dOpenPal.FileName));
  if      e = '.ACO' then LoadPalAco(dOpenPal.FileName, @Pal)
  else if e = '.ACT' then LoadPalAct(dOpenPal.FileName, @Pal)
  else if (e[2] = 'Z') and (e[3] = 'S') then LoadPalZst(dOpenPal.FileName, @Pal)
  else exit;

  gPal.Repaint;

  if Spr <> nil then begin
    Move(Pal, Spr.Pal, 256 * 4);
    UpdatePreview;
  end;
end;


procedure TfmMain.bSavePalClick(Sender: TObject);
  var e: string;
begin
  if not dSavePal.Execute then exit;

  e := UpperCase(ExtractFileExt(dSavePal.FileName));
  if      e = '.ACO' then SavePalAco(dSavePal.FileName, @Pal)
  else if e = '.ACT' then SavePalAct(dSavePal.FileName, @Pal)
  else if (e[2] = 'Z') and (e[3] = 'S') then SavePalZst(dSavePal.FileName, @Pal)
end;


procedure TfmMain.miNewAddressfromtheEndClick(Sender: TObject);
begin
  if Spr = nil then exit;
  eAddress.Text := format('$%.6x',[Spr.Address + Spr.SizeRaw]);
  bAddAddressClick(nil);
end;


procedure TfmMain.bGraphicUpClick(Sender: TObject);
  var ind: integer;
begin
  ind := lbList.ItemIndex;
  if ind < 1 then exit;
  lbList.Items.Exchange(ind, ind-1);
end;


procedure TfmMain.bGraphicDownClick(Sender: TObject);
  var ind: integer;
begin
  ind := lbList.ItemIndex;
  if (ind < 0) or (ind = (lbList.Count - 1)) then exit;
  lbList.Items.Exchange(ind, ind+1);
end;


procedure TfmMain.bSortByNameClick(Sender: TObject);
  var sl: TStringList;
begin
  sl := TStringList.Create;
  sl.Assign(lbList.Items);
  sl.Sort;
  lbList.Items.Assign(sl);
  sl.Free;
end;

end.
