unit uExport;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TfmExport = class(TForm)
    Bevel1: TBevel;
    cExpImage: TCheckBox;
    eExpImgFile: TEdit;
    bImageFile: TButton;
    cExpTiles: TCheckBox;
    eExpTileFile: TEdit;
    bTileFile: TButton;
    Bevel2: TBevel;
    cExpPal: TCheckBox;
    eExpPalFile: TEdit;
    bPalFile: TButton;
    Bevel3: TBevel;
    bOK: TButton;
    bCancel: TButton;
    cbTileFormat: TComboBox;
    lTileFormat: TLabel;
    lPalFormat: TLabel;
    cbPalFormat: TComboBox;
    SaveDialog: TSaveDialog;
    procedure bImageFileClick(Sender: TObject);
    procedure cExpPalClick(Sender: TObject);
    procedure cExpImageClick(Sender: TObject);
    procedure cExpTilesClick(Sender: TObject);
    procedure bTileFileClick(Sender: TObject);
    procedure bPalFileClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bOKClick(Sender: TObject);
  private
    { Private declarations }
  public
    Act: integer;
  end;

var
  fmExport: TfmExport;


implementation
{$R *.dfm}

uses uCommon;


procedure TfmExport.bImageFileClick(Sender: TObject);
begin
  SaveDialog.Filter := 'PNG Image (*.png)|*.png|BMP Image (*.bmp)|*.bmp|ALL (*.*)|*.*';
  if SaveDialog.Execute then
    eExpImgFile.Text := SaveDialog.FileName;
end;

procedure TfmExport.bTileFileClick(Sender: TObject);
begin
  SaveDialog.Filter := 'Binary file (*.bin)|*.bin|ALL (*.*)|*.*';
  if SaveDialog.Execute then
    eExpTileFile.Text := SaveDialog.FileName;
end;

procedure TfmExport.bPalFileClick(Sender: TObject);
begin
  SaveDialog.Filter := 'Binary file (*.bin)|*.bin|ALL (*.*)|*.*';
  if SaveDialog.Execute then
    eExpPalFile.Text := SaveDialog.FileName;
end;


procedure TfmExport.cExpImageClick(Sender: TObject);
begin
  eExpImgFile.Enabled := cExpImage.Checked;
  bImageFile.Enabled  := cExpImage.Checked;
end;

procedure TfmExport.cExpTilesClick(Sender: TObject);
begin
  lTileFormat.Enabled  := cExpTiles.Checked;
  cbTileFormat.Enabled := cExpTiles.Checked;
  eExpTileFile.Enabled := cExpTiles.Checked;
  bTileFile.Enabled    := cExpTiles.Checked;
end;

procedure TfmExport.cExpPalClick(Sender: TObject);
begin
  lPalFormat.Enabled  := cExpPal.Checked;
  cbPalFormat.Enabled := cExpPal.Checked;
  eExpPalFile.Enabled := cExpPal.Checked;
  bPalFile.Enabled    := cExpPal.Checked;
end;


procedure TfmExport.FormCreate(Sender: TObject);
  var i: integer;
begin
  for i := 0 to cFmtTileNum do
    cbTileFormat.Items.Add(cFmtTile[i]);
  cbTileFormat.ItemIndex := 1;

  for i := 0 to cFmtPalNum do
    cbPalFormat.Items.Add(cFmtPal[i]);
  cbPalFormat.ItemIndex := 1;

  //cExpImage.Checked := false;
  //cExpTiles.Checked := false;
  cExpPal.Checked := false;
end;


procedure TfmExport.bOKClick(Sender: TObject);
begin
  Act := 0;
  if cExpTiles.Checked then
    if (cbTileFormat.ItemIndex < 1) or (eExpTileFile.Text = '') then exit
    else Act := 1;

  if cExpPal.Checked then
    if (cbPalFormat.ItemIndex < 1) or (eExpPalFile.Text = '') then exit
    else Act := Act or 2;

  if cExpImage.Checked then
    if eExpImgFile.Text = '' then exit
    else Act := Act or 4;

  ModalResult := mrOk;
end;

end.
