unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, StdCtrls, Spin;

const
  cFmt = '%3d ($%.2x)';


type
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
    procedure bOpenROMClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lbListClick(Sender: TObject);
  private
    ROM: array of byte;

    procedure LoadROM(const FileName:string);
  public
  end;

var
  fmMain: TfmMain;

implementation
{$R *.dfm}

uses uCompress, uTiles;

const
  cPal16: tPal4bpp = (
    $A0A0A0, $111111, $222222, $333333, $444444, $555555, $666666, $777777,
    $888888, $999999, $AAAAAA, $BBBBBB, $CCCCCC, $DDDDDD, $EEEEEE, $FFFFFF);


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
  lbList.AddItem(cGoblin.Name, @cGoblin);
  lbList.AddItem(cCrab.Name, @cCrab);

  LoadROM('S:\2564 - Final Fantasy V Advance (U)(Independent).gba');
end;


procedure TfmMain.lbListClick(Sender: TObject);
  var Spr: pVisual;
      Buf: tLZStream;
      MobTiles: array[0..1000, 0..7, 0..7] of byte;
begin
  if lbList.ItemIndex < 0 then exit;
  Spr := pointer(lbList.Items.Objects[lbList.ItemIndex]);
  Spr.SizeRaw := pCardinal( @ROM[Spr.Address] )^ shr 8;
  Spr.SizeCmp := DecodeLZ77InMem( @ROM[Spr.Address], Buf);

  seWidth.Value  := Spr.W;
  seHeight.Value := Spr.H;
  seOffset.Value := Spr.Off;
  seBPP.Value    := Spr.BPP;
  eName.Text     := Spr.Name;
  eSizeRaw.Text  := format(cFmt, [Spr.SizeRaw, Spr.SizeRaw]);
  eSizeCmp.Text  := format(cFmt, [Spr.SizeCmp, Spr.SizeCmp]);

  ConvertTileGBA(@buf[Spr.Off], @MobTiles, Spr.W * Spr.H);
  DrawMobSpriteGBA(fmMain.Handle, 170, 60, Spr.W, Spr.H, 2, false, @MobTiles, @cPal16)

end;

end.
