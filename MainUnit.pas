unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, StdCtrls, Spin, Grids, pngextra, ExtCtrls, ComCtrls;


type
  TfmMain = class(TForm)
    OpenDialog: TOpenDialog;
    lbList: TListBox;
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
    Memo1: TMemo;
    Memo2: TMemo;
    Button1: TButton;
    Button2: TButton;
    Label4: TLabel;
    cbCompression: TComboBox;
    Image: TImage;
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
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
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
  public
  end;

var
  fmMain: TfmMain;

implementation
{$R *.dfm}

uses uCommon, uCompress, uTiles;


var
  Spr: pVisual;
  MobTiles: array[0..1000, 0..7, 0..7] of byte;
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
//  LoadROM('D:\Emulators\GBA\ROM\2564 - Final Fantasy V Advance (U)(Independent).gba');
//  LoadROM('D:\Emulators\GBA\ROM\1805 - Final Fantasy I & II - Dawn of Souls (U)(Independent).gba');
  for i := 1 to cTmplNum do
    cbTemplate.AddItem(cTemplate[i].Name, tObject(i));

  for i := 0 to cCmpNum do
    cbCompression.Items.Add(cCompression[i].Name);

  GetMem( PalBMP, Sizeof( TLogPalette ) + Sizeof( TPaletteEntry ) * 255 );
  PalBMP.palVersion := $300;
  PalBMP.palNumEntries := 256;
  hPalBMP := CreatePalette(PalBMP^);

  SetLength(Buf, 1024*1024);
  LoadROM('S:\Test\FFV\work\2564 - Final Fantasy V Advance (U)(Independent).gba');
end;


procedure TfmMain.FormDestroy(Sender: TObject);
begin
  DeleteObject(hPalBMP);
  FreeMem(PalBMP);

  SetLength(Buf, 0);
end;



procedure TfmMain.SetCaption;
begin
  Caption := format('Visual SAK:> %s  <:>  %s', [DocName, RomName]);
end;


procedure TfmMain.UpdatePreview;
begin
  fmMain.Repaint;
  if Spr.Tmpl = 0 then exit;

  case Spr.Tmpl of
    1: ConvertTileGBA(@buf[Spr.Off], @MobTiles, Spr.W * Spr.H);
    2: ConvertTileGBA(@ROM[Spr.Address+Spr.Off], @MobTiles, Spr.W * Spr.H);
    3: ConvertTileSNES4Bpp(@ROM[Spr.Address+Spr.Off], @MobTiles, Spr.W * Spr.H);
    4: ConvertTileSNES3Bpp(@ROM[Spr.Address+Spr.Off], @MobTiles, Spr.W * Spr.H);
    5: ConvertTileSNES2Bpp(@ROM[Spr.Address+Spr.Off], @MobTiles, Spr.W * Spr.H);
    6: ConvertTileSNES1Bpp(@ROM[Spr.Address+Spr.Off], @MobTiles, Spr.W * Spr.H);
    7: ConvertTileSNES8Bpp(@ROM[Spr.Address+Spr.Off], @MobTiles, Spr.W * Spr.H);
    8: ConvertTileSNES8Bpp(@buf[Spr.Off], @MobTiles, Spr.W * Spr.H);
  end;
  DrawMobSpriteGBA(fmMain.Handle, 170, 60, Spr.W, Spr.H, seZoom.Value, true, @MobTiles, @Spr.Pal)
  //DrawSprite(fmMain.Handle, 170, 60, Spr.W, Spr.H, seZoom.Value, true, @MobTiles, @Spr.Pal, 8, 16)
end;


procedure TfmMain.CompressionChange;
  var n: integer;
begin
  if Spr.Cmp = ctNone then
    Spr.SizeRaw := (Spr.W * Spr.H * Spr.BPP) shl 3;
  if Spr.Cmp = ctLZ77_10 then begin
    Spr.SizeRaw := pCardinal( @ROM[Spr.Address] )^ shr 8;
    Spr.SizeCmp := DecodeLZ77InMem( @ROM[Spr.Address], tLZStream(Buf));
  end;

  n := Spr.SizeRaw div (Spr.BPP shl 3);
  sBar.Panels[0].Text := format('#Tiles: '+cFmt, [n, n]);
  sBar.Panels[1].Text := format('RawSize: '+cFmt, [Spr.SizeRaw, Spr.SizeRaw]);
  sBar.Panels[2].Text := format('Compr.Size: '+cFmt, [Spr.SizeCmp, Spr.SizeCmp]);

  FillChar(Pal, 256*4, 0);
  Move(Spr.Pal, Pal, Spr.PalNum * 4);
  gPal.Repaint;
end;


procedure TfmMain.lbListClick(Sender: TObject);
begin
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
    Spr.Tmpl := Byte(cbTemplate.Items.Objects[cbTemplate.ItemIndex]);
    Spr.BPP  := cTemplate[Spr.Tmpl].BPP;
    Spr.PalNum := 1 shl Spr.BPP;
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
begin
  New(v);
  FillChar(v^, Sizeof(v^), 0);
  v.Address := StrToInt(eAddress.Text);
  v.Name := eAddress.Text;
  v.H    := seHeight.Value;
  v.W    := seWidth.Value;
  v.Off  := seOffset.Value;
  v.BPP  := 1;
  v.tW   := 8;
  v.tH   := 8;

  //v.PalNum := 16;
  //MakeMonoPal(v.Pal, 16);
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
  //Spr.PalNum := 16;
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
    B := (p^shr 10) and $1F;
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


procedure TfmMain.Button1Click(Sender: TObject);
  var LZ, LZ1: tLZStream;
      n: cardinal;
begin
  StrToLZ(Memo1.Lines.Text, LZ);
  SetLength(LZ1, 3000);
  n := DecodeLZSS1(LZ, LZ1);
  Memo2.Lines.Text := LZToStr(LZ1);
  Memo2.Lines.Insert(0, IntToStr(n));
end;


procedure TfmMain.Button2Click(Sender: TObject);
  type
    TLogPal = record
      lpal : TLogPalette;
      colorSpace : Array[0..255] of TPaletteEntry;
    end;
  var i, j, tx, ty, w, h : integer;
      //Pal: TLogPal;
      bmp: TBitmap;
      Src, Dst: pByte;
      p: PByteArray;
      Bitmap, Mask: TBitmap;
      tmp: array[0..255] of cardinal;
begin
{  for i := 0 to 255 do
    with PalBMP.palPalEntry[i] do begin
      peRed   := Spr.Pal[i] and $0000FF;
      peGreen := (Spr.Pal[i] shr 8)  and $0000FF;
      peBlue  := (Spr.Pal[i] shr 16) and $0000FF;
      peFlags := PC_RESERVED;
    end;
  hPalBMP := CreatePalette(PalBMP^); }
  //Pal.lpal.palPalEntry[0].peRed   := $E0;
  //Pal.lpal.palPalEntry[0].peGreen := $E0;
  //Pal.lpal.palPalEntry[0].peBlue  := $E0;
  //Cardinal(Pal.lpal.palPalEntry[0]) := $01000000 + TransColor;{ $01E0E0E0;}

  bmp := TBitmap.Create;
  bmp.PixelFormat := pf8bit;
  bmp.Width  := Spr.W shl 3;
  bmp.Height := -Spr.H shl 3;
  //bmp.Palette := CreatePalette(Pal.lpal);
  bmp.Palette := hPalBMP;
  Move(Spr.Pal[0], tmp[0], 256 *4);
  ByteSwapColors(tmp[0], 256);
  SetDIBColorTable(bmp.Canvas.Handle, 0, 256, tmp[0]);
  if bmp.HandleType = bmDDB	then
    ShowMessage('Not DIB');

  if Spr.Cmp > 0 then Src := @buf[Spr.Off]
                 else Src := @ROM[Spr.Address+Spr.Off];
  Dst := bmp.ScanLine[0];
  for i := 0 to Spr.H -1 do
    for j := 0 to Spr.W -1 do
      for ty := 0 to 7 do begin
        p := bmp.ScanLine[i*8 + ty];
        p[j*8]     := Src^ and $0F;
        p[j*8 + 1] := Src^ shr 4;
        inc(Src);
        p[j*8 + 2] := Src^ and $0F;
        p[j*8 + 3] := Src^ shr 4;
        inc(Src);
        p[j*8 + 4] := Src^ and $0F;
        p[j*8 + 5] := Src^ shr 4;
        inc(Src);
        p[j*8 + 6] := Src^ and $0F;
        p[j*8 + 7] := Src^ shr 4;
        inc(Src);
      end;

  //Canvas.Draw(170, 60, bmp);
  //bmp.Transparent := true;
  //bmp.TransparentMode := tmAuto;
  //bmp.TransparentMode := tmFixed;
  //bmp.TransparentColor :=  $01000000;  {TColor($01000000 + Integer(Pal.colorSpace[0]));}
  Canvas.Draw(470, 60, bmp);

{  //bmp.ReleasePalette;
  for i := 0 to 4 do begin
    Pal.lpal.palPalEntry[i].peRed   := $FF;
    Pal.lpal.palPalEntry[i].peGreen := $00;
    Pal.lpal.palPalEntry[i].peBlue  := $00;
    Pal.lpal.palPalEntry[i].peFlags := $01;
  end;
  tx := SetPaletteEntries(bmp.Palette, 0, 5, Pal.lpal.palPalEntry[0]);
  if tx = 0 then
    ShowMessage('SetPaletteEntries failed');
  //Canvas.Draw(270, 60, bmp);
  //bmp.Palette := CreatePalette(Pal.lpal);                           }

  Bitmap := TBitmap.Create;
  Mask := TBitmap.Create;
  try
    Bitmap.Assign(bmp);
    Mask.Assign(bmp);
    Mask.Mask($01000000);
    w := bmp.Width;
    h := bmp.Height;
    {if $01000000 <> clBlack then begin
      BitBlt(Mask.Canvas.Handle, 0, 0, Mask.Width, Mask.Height, 0, 0, 0, DSTINVERT);
      BitBlt(Bitmap.Canvas.Handle, 0, 0, Bitmap.Width, Bitmap.Height, Mask.Canvas.Handle, 0, 0, SRCAND);
      BitBlt(Mask.Canvas.Handle, 0, 0, Mask.Width, Mask.Height, 0, 0, 0, DSTINVERT);
    end; }
    //StretchBlt(Canvas.Handle, 300, 60, 3*w, 3*h, Mask.Canvas.Handle, 0, 0, w, h, SRCAND);
    //StretchBlt(Canvas.Handle, 300, 60, 3*w, 3*h, Bitmap.Canvas.Handle, 0, 0, w, h, SRCPAINT);
    //BitBlt(Canvas.Handle, 270, 60, w, h, Mask.Canvas.Handle, 0, 0, SRCAND);
    //BitBlt(bmp.Canvas.Handle, 0, 0, w, h, Bitmap.Canvas.Handle, 0, 0, SRCPAINT);
    //Canvas.Draw(270, 60, bmp);
  finally
    Bitmap.Free;
    Mask.Free;
  end;

  //Canvas.StretchDraw(Bounds(170, 60, bmp.Width*3, bmp.Height*3), bmp);
  w := bmp.Width * seZoom.Value;
  h := bmp.Height * seZoom.Value;
  Image.Picture.Bitmap.Width  := w;
  Image.Picture.Bitmap.Height := h;
  //Image.Picture.Bitmap.Canvas.FillRect(Bounds(0, 0, w, h));
  Image.Canvas.StretchDraw(Bounds(0, 0, w, h), bmp);
  Image.Transparent := true;
  //Image.Picture.Bitmap.Transparent := true;

  bmp.Free
end;

end.
