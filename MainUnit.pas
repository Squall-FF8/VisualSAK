unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, StdCtrls, Spin, Grids, pngextra, ExtCtrls, ComCtrls;

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
    Tmpl:    byte;
    Pal:     tPalette;
    PalAdr:  cardinal;
    PalNum:  cardinal;
  end;
  pVisual = ^tVisual;

  tTemplate = record
    Name: string[20];
    BPP,
    CmpType: byte;
  end;
  pTemplate = ^tTemplate;


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
    bPalMono16: TPNGButton;
    bPalMono256: TPNGButton;
    sBar: TStatusBar;
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
    procedure ePalAddressKeyPress(Sender: TObject; var Key: Char);
  private
    ROM: array of byte;
    NoChange: boolean;

    procedure LoadROM(const FileName:string);
    procedure UpdatePreview;
    procedure EmptyList;
    procedure EnableContols(State: boolean; Index: integer);
    procedure CompressionChange;
  public
  end;

var
  fmMain: TfmMain;

implementation
{$R *.dfm}

uses uCompress, uTiles;


const
  // compression type constants
  ctNone = 0;
  ctLZ10 = 1;

  cTmplNum = 2;
  cTemplate: array[0 .. cTmplNum] of tTemplate = (
    (Name: ''; BPP: 0; CmpType: ctNone),
    (Name: 'GBA 4bpp LZ10'; BPP: 4; CmpType: ctLZ10),
    (Name: 'GBA 4bpp NO'; BPP: 4; CmpType: ctNone)
  );


var
  Spr: pVisual;
  Buf: tLZStream;
  MobTiles: array[0..1000, 0..7, 0..7] of byte;
  Pal: tPalette;


procedure MakeMonoPal(var Pal: tPalette; Num: integer);
  var i, r: integer;
begin
  for i:= 0 to Num - 1 do begin
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
  if OpenDialog.Execute then begin
    LoadROM(OpenDialog.FileName);

    bNew.Enabled := true;
    bLoad.Enabled := true;
    bSave.Enabled := true;

    ePalAddress.Enabled := true;
    bLoadPalROM.Enabled := true;

    eAddress.Enabled    := true;
    bAddAddress.Enabled := true;
    bDelAddress.Enabled := true;
  end;
end;


procedure TfmMain.FormCreate(Sender: TObject);
  var i: integer;
begin
//  LoadROM('D:\Emulators\GBA\ROM\2564 - Final Fantasy V Advance (U)(Independent).gba');
//  LoadROM('D:\Emulators\GBA\ROM\1805 - Final Fantasy I & II - Dawn of Souls (U)(Independent).gba');
//  LoadROM('s:\2564 - Final Fantasy V Advance (U)(Independent).gba');
  for i := 1 to cTmplNum do
    cbTemplate.AddItem(cTemplate[i].Name, tObject(i));

end;


procedure TfmMain.UpdatePreview;
begin
  fmMain.Repaint;
  if Spr.Tmpl = 0 then exit;

  case cTemplate[Spr.Tmpl].CmpType of
    ctNone: ConvertTileGBA(@ROM[Spr.Address+Spr.Off], @MobTiles, Spr.W * Spr.H);
    ctLZ10: ConvertTileGBA(@buf[Spr.Off], @MobTiles, Spr.W * Spr.H);
  end;
  DrawMobSpriteGBA(fmMain.Handle, 170, 60, Spr.W, Spr.H, seZoom.Value, true, @MobTiles, @Spr.Pal)
end;


procedure TfmMain.CompressionChange;
  var n: integer;
begin
  if cTemplate[Spr.Tmpl].CmpType = ctNone then
    Spr.SizeRaw := (Spr.W * Spr.H * Spr.BPP) shl 3;
  if cTemplate[Spr.Tmpl].CmpType = ctLZ10 then begin
    Spr.SizeRaw := pCardinal( @ROM[Spr.Address] )^ shr 8;
    Spr.SizeCmp := DecodeLZ77InMem( @ROM[Spr.Address], Buf);
  end;

  n := Spr.SizeRaw div (Spr.BPP shl 3);
  sBar.Panels[0].Text := format('#Tiles: '+cFmt, [n, n]);
  sBar.Panels[1].Text := format('RawSize: '+cFmt, [Spr.SizeRaw, Spr.SizeRaw]);
  sBar.Panels[2].Text := format('Compr.Size: '+cFmt, [Spr.SizeCmp, Spr.SizeCmp]);
end;


procedure TfmMain.lbListClick(Sender: TObject);
begin
  if lbList.ItemIndex < 0 then exit;
  Spr := pointer(lbList.Items.Objects[lbList.ItemIndex]);
  CompressionChange;

  NoChange := true;
  seWidth.Value  := Spr.W;
  seHeight.Value := Spr.H;
  seOffset.Value := Spr.Off;
  eName.Text     := Spr.Name;
  eAddress.Text  := format('$%.6x',[Spr.Address]);
  ePalAddress.Text := format('$%.6x',[Spr.PalAdr]);
  //cbTemplate.ItemIndex := cbTemplate.Items.IndexOfObject(tObject(Spr.Tmpl));
  EnableContols(true, cbTemplate.Items.IndexOfObject(tObject(Spr.Tmpl)) );
  NoChange := false;

  UpdatePreview;

  Move(Spr.Pal, Pal, Spr.PalNum * 4);
  gPal.Repaint;
end;


procedure TfmMain.ValueChange(Sender: TObject);
begin
  if NoChange then exit;

  if Sender = cbTemplate then EnableContols(true, cbTemplate.ItemIndex)
  else begin
    Spr.W    := seWidth.Value;
    Spr.H    := seHeight.Value;
    Spr.Off  := seOffset.Value;
    Spr.Name := eName.Text;
    lbList.Items[lbList.ItemIndex] := Spr.Name;
  end;

  Spr.Tmpl := Byte(cbTemplate.Items.Objects[cbTemplate.ItemIndex]);
  Spr.BPP  := cTemplate[Spr.Tmpl].BPP;

  if Sender = cbTemplate then CompressionChange;
  if Sender <> eName then UpdatePreview;
end;


procedure TfmMain.bAddAddressClick(Sender: TObject);
  var v: pVisual;
begin
  New(v);
  FillChar(v^, Sizeof(v^), 0);
  v.Address := StrToInt(eAddress.Text);
  v.Name := eAddress.Text;
  v.H    := 1;
  v.W    := 1;
  v.Off  := 8;
  v.BPP  := 1;

  v.PalNum := 16;
  MakeMonoPal(v.Pal, 16);
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

  seZoom.Enabled    := Index >= 0;
  seWidth.Enabled   := Index >= 0;
  seHeight.Enabled  := Index >= 0;
  seOffset.Enabled := Index >= 0;
  NoChange := false;
end;


end.
