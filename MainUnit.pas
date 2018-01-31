unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, StdCtrls, Spin;

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

const
  cGoblin: tVisual = (
    Name: 'Goblin';
    Address: $1C7E54;
    W:   4;
    H:   5;
    Off: 8;
    BPP: 4;
    );
  cCrab: tVisual = (
    Name: 'Devil Crab';
    Address: $1C887C;
    W:   6;
    H:   3;
    Off: 8;
    BPP: 4;
    );


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
    bAddAddress: TSpeedButton;
    bDelAddress: TSpeedButton;
    eAddress: TEdit;
    seZoom: TSpinEdit;
    Label8: TLabel;
    bSave: TSpeedButton;
    SaveDialog: TSaveDialog;
    bLoad: TSpeedButton;
    procedure bOpenROMClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lbListClick(Sender: TObject);
    procedure ValueChange(Sender: TObject);
    procedure bAddAddressClick(Sender: TObject);
    procedure seZoomChange(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
    procedure bLoadClick(Sender: TObject);
  private
    ROM: array of byte;
    NoChange: boolean;

    procedure LoadROM(const FileName:string);
    procedure UpdatePreview;
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

var
  Spr: pVisual;
  Buf: tLZStream;
  MobTiles: array[0..1000, 0..7, 0..7] of byte;


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
  if OpenDialog.Execute then
    LoadROM(OpenDialog.FileName)
end;


procedure TfmMain.FormCreate(Sender: TObject);
begin
  //lbList.AddItem(cGoblin.Name, @cGoblin);
  //lbList.AddItem(cCrab.Name, @cCrab);

//  LoadROM('D:\Emulators\GBA\ROM\2564 - Final Fantasy V Advance (U)(Independent).gba');
  LoadROM('s:\2564 - Final Fantasy V Advance (U)(Independent).gba');
end;


procedure TfmMain.UpdatePreview;
begin
  fmMain.Repaint;
  ConvertTileGBA(@buf[Spr.Off], @MobTiles, Spr.W * Spr.H);
  DrawMobSpriteGBA(fmMain.Handle, 170, 60, Spr.W, Spr.H, seZoom.Value, false, @MobTiles, @Spr.Pal)
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
  NoChange := false;

  UpdatePreview
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
  var i: integer;
      v: pVisual;
begin
  New(v);
  v.Address := StrToInt(eAddress.Text);
  v.Name := eAddress.Text;
  v.BPP  := 4;
  v.H    := 1;
  v.W    := 1;
  v.Off  := 8;

  for i:= 0 to 15 do v.Pal[i] := cPal16[i];
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
  lbList.Clear;
  for i := 1 to n do begin
    New(v);
    Read(f, v^);
    lbList.AddItem(v.Name, tObject(v));
  end;
  CloseFile(f);
end;


end.
