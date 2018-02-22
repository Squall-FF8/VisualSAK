unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, StdCtrls, Spin, Grids, pngextra;

const
  cFmt = '%3d ($%.2x)';



type
  tPalEntry = cardinal;
  tPalette = array[0..255] of tPalEntry;
  pPalette = ^tPalette;

  tVisual = record
    Name:    string[20];
    Address: cardinal;
    SizeRaw,
    SizeCmp: cardinal;
    W, H,
    Off:     cardinal;
    Kind,
    BPP,
    CmpType: byte;
    Pal:     tPalette;
    PalAdr:  cardinal;
    PalNum:  cardinal;
  end;
  pVisual = ^tVisual;


type
  TfmMain = class(TForm)
    bOpenROM: TSpeedButton;
    OpenDialog: TOpenDialog;
    lbList: TListBox;
    seWidth: TSpinEdit;
    Label1: TLabel;
    Label2: TLabel;
    seHeight: TSpinEdit;
    Label3: TLabel;
    seOffset: TSpinEdit;
    Label4: TLabel;
    seBPP: TSpinEdit;
    eName: TEdit;
    Label5: TLabel;
    eSizeRaw: TEdit;
    Label6: TLabel;
    Label7: TLabel;
    eSizeCmp: TEdit;
    eAddress: TEdit;
    seZoom: TSpinEdit;
    Label8: TLabel;
    SaveDialog: TSaveDialog;
    gPal: TDrawGrid;
    ColorDialog: TColorDialog;
    ePalAddress: TEdit;
    sePalNum: TSpinEdit;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    bSave: TPNGButton;
    bLoad: TPNGButton;
    bNew: TPNGButton;
    bLoadPalROM: TPNGButton;
    bPalMono16: TPNGButton;
    bPalMono256: TPNGButton;
    bAddAddress: TPNGButton;
    bDelAddress: TPNGButton;
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
    procedure bPalMono16Click(Sender: TObject);
    procedure gPalMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure bLoadPalROMClick(Sender: TObject);
    procedure eAddressKeyPress(Sender: TObject; var Key: Char);
    procedure bPalMono256Click(Sender: TObject);
    procedure bNewClick(Sender: TObject);
  private
    ROM: array of byte;
    NoChange: boolean;

    procedure LoadROM(const FileName:string);
    procedure UpdatePreview;
    procedure EmptyList;
  public
  end;

var
  fmMain: TfmMain;

implementation
{$R *.dfm}

uses uCompress, uTiles;

const
  cPal16: tPal4bpp = (
    $E0E0E0, $111111, $222222, $333333, $444444, $555555, $666666, $777777,
    $888888, $999999, $AAAAAA, $BBBBBB, $CCCCCC, $DDDDDD, $EEEEEE, $FFFFFF);

{  cPal256: tPalette = (
    $000000, $010101, $020202, $030303, $040404, $050505, $060606, $070707, $080808, $090909, $0A0A0A, $0B0B0B, $0C0C0C, $0D0D0D, $0E0E0E, $0F0F0F,
    $101010, $111111, $121212, $131313, $141414, $151515, $161616, $171717, $181818, $191919, $1A1A1A, $1B1B1B, $1C1C1C, $1D1D1D, $1E1E1E, $1F1F1F,
    $202020, $212121, $222222, $232323, $242424, $252525, $262626, $272727, $080808, $090909, $0A0A0A, $0B0B0B, $0C0C0C, $0D0D0D, $0E0E0E, $0F0F0F,
    $303030, $313131, $323232, $333333, $343434, $353535, $363636, $373737, $383838, $393939, $3A3A3A, $3B3B3B, $3C3C3C, $3D3D3D, $3E3E3E, $3F3F3F,}

var
  Spr: pVisual;
  Buf: tLZStream;
  MobTiles: array[0..1000, 0..7, 0..7] of byte;
  Pal: tPalette;


{procedure MakeMonoPal16(var Pal: tPalette);
  var i, r: integer;
begin
  for i:= 0 to 15 do begin
    r := i shl 4 + i;
    Pal[i] := R + R shl 8 + R shl 16;
  end;
end;

procedure MakeMonoPal256(var Pal: tPalette);
  var i: integer;
begin
  for i:= 0 to 255 do
    Pal[i] := i + i shl 8 + i shl 16;
end;
}
procedure MakeMonoPal(var Pal: tPalette; Num: integer);
  var i, r: integer;
begin
  for i:= 0 to Num - 1 do begin
//    r := i * 256 div Num + i* 256 div (Num * Num);
    r := (i * 255) div (Num -1);
    Pal[i] := R + R shl 8 + R shl 16;
  end;
end;




procedure TfmMain.LoadROM(const FileName:string);
  var f, n: cardinal;
begin
  Caption := FileName;
  f := CreateFile(pchar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if f = INVALID_HANDLE_VALUE then raise Exception.Create(format('%s not found', [Caption]));
  n := GetFileSize(f, nil);
  SetLength(ROM, n);
  ReadFile(f, ROM[0], n, n, nil);
  CloseHandle(f);
end;


procedure TfmMain.bOpenROMClick(Sender: TObject);
begin
  OpenDialog.Filter := 'SNES/GBA ROM|*.smc; *.gba|SNES ROM|*.smc|GBA ROM|*.gba|ALL|*.*';
  if OpenDialog.Execute then
    LoadROM(OpenDialog.FileName)
end;


procedure TfmMain.FormCreate(Sender: TObject);
begin
//  LoadROM('D:\Emulators\GBA\ROM\2564 - Final Fantasy V Advance (U)(Independent).gba');
//  LoadROM('D:\Emulators\GBA\ROM\1805 - Final Fantasy I & II - Dawn of Souls (U)(Independent).gba');
  LoadROM('s:\2564 - Final Fantasy V Advance (U)(Independent).gba');
end;


procedure TfmMain.UpdatePreview;
begin
  fmMain.Repaint;
  ConvertTileGBA(@buf[Spr.Off], @MobTiles, Spr.W * Spr.H);
  DrawMobSpriteGBA(fmMain.Handle, 170, 60, Spr.W, Spr.H, seZoom.Value, true, @MobTiles, @Spr.Pal)
end;


procedure TfmMain.lbListClick(Sender: TObject);
begin
  if lbList.ItemIndex < 0 then exit;
  Spr := pointer(lbList.Items.Objects[lbList.ItemIndex]);
  Spr.SizeRaw := pCardinal( @ROM[Spr.Address] )^ shr 8;
  Spr.SizeCmp := DecodeLZ77InMem( @ROM[Spr.Address], Buf);

  NoChange := true;
  seWidth.Value  := Spr.W;
  seHeight.Value := Spr.H;
  seOffset.Value := Spr.Off;
  seBPP.Value    := Spr.BPP;
  eName.Text     := Spr.Name;
  eSizeRaw.Text  := format(cFmt, [Spr.SizeRaw, Spr.SizeRaw]);
  eSizeCmp.Text  := format(cFmt, [Spr.SizeCmp, Spr.SizeCmp]);
  eAddress.Text  := format('$%.6x',[Spr.Address]);
  ePalAddress.Text := format('$%.6x',[Spr.PalAdr]);
  NoChange := false;

  UpdatePreview;

  Move(Spr.Pal, Pal, Spr.PalNum * 4);
  gPal.Repaint;
end;


procedure TfmMain.ValueChange(Sender: TObject);
begin
  if NoChange then exit;

  Spr.W    := seWidth.Value;
  Spr.H    := seHeight.Value;
  Spr.Off  := seOffset.Value;
  Spr.BPP  := seBPP.Value;
  Spr.Name := eName.Text;
  lbList.Items[lbList.ItemIndex] := Spr.Name;

  if Sender <> eName then UpdatePreview;
end;


procedure TfmMain.bAddAddressClick(Sender: TObject);
  var v: pVisual;
begin
  New(v);
  v.Address := StrToInt(eAddress.Text);
  v.Name := eAddress.Text;
  v.BPP  := 4;
  v.H    := 1;
  v.W    := 1;
  v.Off  := 8;

  v.PalNum := 16;
  MakeMonoPal(v.Pal, 16);
  lbList.AddItem(v.Name, tObject(v));
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


procedure TfmMain.bPalMono16Click(Sender: TObject);
begin
  ZeroMemory(@Pal[0], 256*4);
  MakeMonoPal(Pal, 16);
  gPal.Repaint;

  if Spr = nil then exit;
  Spr.PalNum := 16;
  MakeMonoPal(Spr.Pal, 16);
  UpdatePreview;
end;


procedure TfmMain.bPalMono256Click(Sender: TObject);
begin
  MakeMonoPal(Pal, 256);
  gPal.Repaint;

  if Spr = nil then exit;
  Spr.PalNum := 256;
  MakeMonoPal(Spr.Pal, 256);
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


end.
