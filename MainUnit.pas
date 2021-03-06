unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, StdCtrls, Spin, Grids, pngextra, pngimage, ComCtrls,
  ExtCtrls, Menus, ImgList, ExtDlgs, XPMan;


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
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    Label8: TLabel;
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
    dOpenPal: TOpenDialog;
    popList: TPopupMenu;
    miNewAddressfromtheEnd: TMenuItem;
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
    Test: TImage;
    Button1: TButton;
    seLen: TSpinEdit;
    eAddr: TEdit;
    bPrev: TSpeedButton;
    bNext: TSpeedButton;
    Label6: TLabel;
    dOpenImage: TOpenPictureDialog;
    Image1: TImage;
    bOpenPal: TPNGButton;
    bSavePal: TPNGButton;
    Image2: TImage;
    bOpenROM: TPNGButton;
    bSaveROM: TPNGButton;
    bLoad: TPNGButton;
    Image3: TImage;
    bSave: TPNGButton;
    Image4: TImage;
    bImport: TPNGButton;
    bExport: TPNGButton;
    bNew: TPNGButton;
    XPManifest1: TXPManifest;
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
    procedure Button1Click(Sender: TObject);
    procedure bPrevClick(Sender: TObject);
    procedure bNextClick(Sender: TObject);
    procedure bImportClick(Sender: TObject);
    procedure bSaveROMClick(Sender: TObject);
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
    procedure ClearImage;
    procedure DrawSprite;
  public
  end;

var
  fmMain: TfmMain;

implementation
{$R *.dfm}

uses uCommon, uCompress, uTiles, uExport;


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
  //n := GetLastError;
  //ShowMessage(IntToStr(n));
  if f = INVALID_HANDLE_VALUE then raise Exception.Create(format('%s not found', [FileName]));
  n := GetFileSize(f, nil);
  SetLength(ROM, n);
  ReadFile(f, ROM[0], n, n, nil);
  CloseHandle(f);

  // Enable controls
  bSaveROM.Visible := true;

  bNew.Visible  := true;
  bLoad.Visible := true;
  bSave.Visible := true;

  ePalAddress.Enabled := true;
  bLoadPalROM.Enabled := true;
  bOpenPal.Visible := true;
  bSavePal.Visible := true;

  eAddress.Enabled    := true;
  bAddAddress.Enabled := true;
  bDelAddress.Enabled := true;
end;


procedure TfmMain.bOpenROMClick(Sender: TObject);
begin
  OpenDialog.Filter := cRomExt;
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
  SetLength(TmpFile, 1024*1024);
  SetLength(Pal, 256);

  //LoadROM('S:\Test\FFV\work\2564 - Final Fantasy V Advance (U)(Independent).gba');
  //LoadROM('D:\Emulators\GBA\ROM\2564 - Final Fantasy V Advance (U)(Independent).gba');
end;


procedure TfmMain.FormDestroy(Sender: TObject);
begin
  DeleteObject(hPalBMP);
  FreeMem(PalBMP);
  bmp.Free;

  SetLength(Buf, 0);
  SetLength(TmpFile, 0);
  SetLength(Pal, 0);
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
    if Spr.Bpp < 9 then begin
      Spr.PalNum := 1 shl Spr.BPP;
      sePalNum.Value := Spr.PalNum;
      MakeMonoPal(Spr.Pal, Spr.PalNum);
    end else begin
      Spr.PalNum := 0;
      FillChar(Spr.Pal, 256*4, 0);
    end;
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
  //New(v);
  //FillChar(v^, Sizeof(v^), 0);
  v := NewVisual;
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
  //var i: integer;
      //f: file of tVisual;
begin
  SaveDialog.Filter := 'Visual SAK (*.vsk)|*.vsk|ALL (*.*)|*.*';
  if not SaveDialog.Execute then exit;
  SaveVisuals(SaveDialog.FileName, lbList.Items);

  {AssignFile(f, SaveDialog.FileName);
  Rewrite(f);
  for i := 0 to lbList.Count -1 do
    Write(f, pVisual(lbList.Items.Objects[i])^);
  CloseFile(f); }
end;


procedure TfmMain.bLoadClick(Sender: TObject);
  //var i, n: integer;
      //f: file of tVisual;
  //    v: pVisual;
begin
  OpenDialog.Filter := 'Visual SAK (*.vsk)|*.vsk|ALL (*.*)|*.*';
  if not OpenDialog.Execute then exit;
  DocName := OpenDialog.FileName;
  SetCaption;
  EmptyList;
  LoadVisuals(OpenDialog.FileName, lbList.Items);


  {AssignFile(f, OpenDialog.FileName);
  Reset(f);
  n := FileSize(f);  // return number of records, no size in bytes
  EmptyList;
  for i := 1 to n do begin
    New(v);
    Read(f, v^);
    lbList.AddItem(v.Name, tObject(v));
  end;
  CloseFile(f); }
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

  Move(Pal[0], Spr.Pal[0], Spr.PalNum * 4);
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
  DocName := '';
  SetCaption;
  ClearImage;
end;


procedure TfmMain.EmptyList;
  var i: integer;
begin
  for i := 0 to lbList.Count - 1 do
    DelVisual(pointer(lbList.Items.Objects[i]));
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
  bImport.Visible := State;
  bExport.Visible := State;

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

  if Spr.BPP < 9 then begin
    bmp.PixelFormat := pf8bit;
    Move(Spr.Pal[0], tmp[0], 256 *4);
    tmp[0] := ColorToRGB(Color);
    ByteSwapColors(tmp[0], 256);
    SetDIBColorTable(bmp.Canvas.Handle, 0, 256, tmp[0]);
  end else
    bmp.PixelFormat := pf24bit;

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
    11: Convert_2BppNES   (bmp, pByteArray(Src), Spr.W, Spr.H);
    12: Convert_2BppNGP   (bmp, pByteArray(Src), Spr.W, Spr.H);
    13: Convert_4BppPC    (bmp, Src, Spr.W, Spr.H);
    14: Convert_4BppPCRev (bmp, Src, Spr.W, Spr.H);
    15: Convert_15BppBGR  (bmp, pWord(Src), Spr.W, Spr.H);
  end;

  w := bmp.Width * seZoom.Value;
  h := bmp.Height * seZoom.Value;
  Image.Picture.Bitmap.Width  := w;
  Image.Picture.Bitmap.Height := h;
  Image.Canvas.StretchDraw(Bounds(0, 0, w, h), bmp);
end;


procedure TfmMain.ClearImage;
begin
  with Image.Picture.Bitmap do begin
    Canvas.Brush.Color := Color;
    Canvas.FillRect(Bounds(0, 0, Width, Height));
  end;
end;


procedure TfmMain.bExportClick(Sender: TObject);
  var png: tPngObject;
      ext: string;
      f, n, w, h: cardinal;
begin
  if fmExport.ShowModal <> mrOK then exit;
  w := Spr.W * Spr.tW;
  h := Spr.H * Spr.tH;

  if (fmExport.Act and 1) > 0 then begin
    Transform_4BppGBA(bmp, @TmpFile[0], Spr.W, Spr.H);
    f := CreateFile(pchar(fmExport.eExpTileFile.Text), GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    if f = INVALID_HANDLE_VALUE then RaiseLastOSError;
    WriteFile(f, TmpFile[0], w*h, n, nil);
    CloseHandle(f);
  end;

  if (fmExport.Act and 2) > 0 then begin
    Transform_4BppGBA(bmp, @TmpFile[0], Spr.W, Spr.H);
    f := CreateFile(pchar(fmExport.eExpTileFile.Text), GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    if f = INVALID_HANDLE_VALUE then RaiseLastOSError;
    WriteFile(f, TmpFile[0], w*h, n, nil);
    CloseHandle(f);
  end;

  if (fmExport.Act and 4) > 0 then begin
    ext := LowerCase(ExtractFileExt(fmExport.eExpImgFile.Text));
    if ext = '.bmp' then
      bmp.SaveToFile(fmExport.eExpImgFile.Text)
    else if ext = '.png' then begin
      //bmp.TransparentColor := $1000000;
      //bmp.TransparentMode := tmFixed;
      bmp.Transparent := true;
      png := TPNGObject.Create;
      png.Assign(bmp);
      png.CompressionLevel := 9;
      //png.TransparentColor := $1000000;
      //png.Transparent := true;
      png.SaveToFile(fmExport.eExpImgFile.Text);
      png.Free;
      bmp.Transparent := false;
    end;
  end;
end;


procedure TfmMain.bOpenPalClick(Sender: TObject);
  var e: string;
begin
  if not dOpenPal.Execute then exit;

  e := UpperCase(ExtractFileExt(dOpenPal.FileName));
  if      e = '.ACO' then LoadPalAco(dOpenPal.FileName, Pal)
  else if e = '.ACT' then LoadPalAct(dOpenPal.FileName, Pal)
  else if (e[2] = 'Z') and (e[3] = 'S') then LoadPalZst(dOpenPal.FileName, Pal)
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
  if Spr <> nil then
    lbList.ItemIndex := lbList.Items.IndexOfObject(tObject(Spr));
end;



var Index: integer = 106;

procedure TfmMain.Button1Click(Sender: TObject);
  var tmp: array[0..255] of cardinal;
begin
  Test.Picture.Bitmap.Width := 256;
  Test.Picture.Bitmap.Height := 256;
  Test.Picture.Bitmap.PixelFormat := pf8bit;
  Test.Picture.Bitmap.Palette := hPalBMP;

  Move(Spr.Pal[0], tmp[0], 256 *4);
  tmp[0] := ColorToRGB(Color);
  ByteSwapColors(tmp[0], 256);
  SetDIBColorTable(Test.Canvas.Handle, 0, 256, tmp[0]);

{  FillChar(Test.Picture.Bitmap.ScanLine[255]^, 256*256, 0);

  m := StrToInt(eAddr.Text);
  //m := $1926C;
  //m := $1B6E8;
  for i := 0 to seLen.Value -1 do begin
    b := ROM[m];
    t := ROM[m+1];
    X := ROM[m+2] + 128;
    Y := ROM[m+3] + 128;

    Ys := t and $F0;
    Xs := (t and $0F) shl 4;

    DrawTile16(Test.Picture.Bitmap, X, Y, bmp, Xs, Ys, b shr 6);

    inc(m, 4);
  end;

  for i := 0 to 255 do begin
    s := bmp.ScanLine[i];
    d := Test.Picture.Bitmap.ScanLine[i];
    Move(s^, Test.Picture.Bitmap.ScanLine[i]^, 256);
  end;
  //Test.Transparent := false;
  Test.Repaint; }
end;

procedure TfmMain.DrawSprite;
  var i, m, n, Xs, Ys: integer;
      b, t, X, Y: Byte;
begin
  FillChar(Test.Picture.Bitmap.ScanLine[255]^, 256*256, 0);

  m := $19008 + Index * 4;
  n := pWord(@ROM[m])^;
  m := $19008 + 4 * pWord(@ROM[m + 2])^;
  //m := StrToInt(eAddr.Text);
  //m := $1926C;
  //m := $1B6E8;
  Label6.Caption := format('%d - %x - %d:%d', [Index, m, (ROM[m] shr 2) and $03, ROM[m] and $03]);
  for i := 0 to n-1 do begin
    b := ROM[m];
    t := ROM[m+1];
    X := ROM[m+2] + 128;
    Y := ROM[m+3] + 128;

    Ys := (b and $03) shl 8 + t and $F0;
    Xs := (t and $0F) shl 4;

    DrawTile16(Test.Picture.Bitmap, X, Y, bmp, Xs, Ys, b shr 6);

    inc(m, 4);
  end;
  Test.Repaint;
end;

procedure TfmMain.bPrevClick(Sender: TObject);
begin
  if Index = 0 then exit;
  dec(Index);
  DrawSprite;
end;

procedure TfmMain.bNextClick(Sender: TObject);
begin
  if Index >= 152 then exit;
  inc(Index);
  DrawSprite;
end;



procedure TfmMain.bImportClick(Sender: TObject);
  var ext: string;
      png: TPNGObject;
      _bmp: tBitmap;
      tmp: array[0..255] of cardinal;
      i: integer;
      p: pWord;
      R, G, B: byte;
begin
  if Spr.Cmp <> 0 then exit;
  if not dOpenImage.Execute then exit;
  ext := LowerCase(ExtractFileExt(dOpenImage.FileName));

  _bmp := tBitmap.Create;
  if ext = '.png' then begin
    png := TPNGObject.Create;
    png.LoadFromFile(dOpenImage.FileName);
    _bmp.Assign(png);
    png.Free;
  end else if ext = '.bmp' then
    _bmp.LoadFromFile(dOpenImage.FileName)
  else begin
    _bmp.Free;
    exit;
  end;

  // Typecast Integer to remove warnings of compiler
  if (_bmp.Width <> Integer(Spr.W * Spr.tW)) or (_bmp.Height <> Integer(Spr.H * Spr.tH)) or (_bmp.PixelFormat <> pf8bit) then
    ShowMessage('Not cottect size or BPP!')
  else begin
    case Spr.Tmpl of
      1: Transform_4BppGBA( _bmp, @ROM[Spr.Address+Spr.Off], Spr.W, Spr.H);
      2: Transform_4BppSNES(_bmp, @ROM[Spr.Address+Spr.Off], Spr.W, Spr.H);
      3: Transform_3BppSNES(_bmp, @ROM[Spr.Address+Spr.Off], Spr.W, Spr.H);
      4: Transform_2BppSNES(_bmp, @ROM[Spr.Address+Spr.Off], Spr.W, Spr.H);
    end;
    Test.Picture.Bitmap.Assign(_bmp);
  end;

  // update Palette in Sprites
  GetDIBColorTable(_bmp.Canvas.Handle, 0, 256, tmp[0]);
  //GetPaletteEntries(_bmp.Palette, 0, 256, tmp[0]);
  //tmp[0] := ColorToRGB(Color);
  ByteSwapColors(tmp[0], 256);
  Move(tmp[0], Spr.Pal[0], 256 *4);

  //update Palette in ROM
  if Spr.PalAdr <> 0 then begin
    p := @ROM[Spr.PalAdr];
    for i := 0 to Spr.PalNum -1 do begin
      R := (Spr.Pal[i] and $0000FF) shr 3;
      G := (Spr.Pal[i] and $00FF00) shr 11;
      B := (Spr.Pal[i] and $FF0000) shr 19;
      p^ := R + G shl 5 + B shl 10;
      inc(p);
    end;
  end;

  _bmp.Free;
end;


procedure TfmMain.bSaveROMClick(Sender: TObject);
  var f, n: cardinal;
begin
  SaveDialog.Filter := cRomExt;
  SaveDialog.FileName := RomName;
  if not SaveDialog.Execute then exit;

  RomName := SaveDialog.FileName;
  SetCaption;

  f := CreateFile(pchar(RomName), GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if f = INVALID_HANDLE_VALUE then raise Exception.Create(format('%s not found', [RomName]));
  WriteFile(f, ROM[0], Length(ROM), n, nil);
  CloseHandle(f);
end;

end.
