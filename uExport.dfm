object fmExport: TfmExport
  Left = 434
  Top = 118
  Width = 552
  Height = 403
  Caption = 'fmExport'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    536
    364)
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 16
    Top = 32
    Width = 505
    Height = 65
    Anchors = [akLeft, akTop, akRight]
    Shape = bsBottomLine
  end
  object Bevel2: TBevel
    Left = 16
    Top = 128
    Width = 505
    Height = 65
    Anchors = [akLeft, akTop, akRight]
    Shape = bsBottomLine
  end
  object Bevel3: TBevel
    Left = 16
    Top = 224
    Width = 505
    Height = 65
    Anchors = [akLeft, akTop, akRight]
    Shape = bsBottomLine
  end
  object lTileFormat: TLabel
    Left = 264
    Top = 123
    Width = 81
    Height = 13
    Alignment = taRightJustify
    AutoSize = False
    Caption = 'Tile format:'
  end
  object lPalFormat: TLabel
    Left = 264
    Top = 219
    Width = 81
    Height = 13
    Alignment = taRightJustify
    AutoSize = False
    Caption = 'Palette format:'
  end
  object cExpImage: TCheckBox
    Left = 32
    Top = 24
    Width = 129
    Height = 17
    Caption = 'Export as Image:'
    Checked = True
    State = cbChecked
    TabOrder = 0
    OnClick = cExpImageClick
  end
  object eExpImgFile: TEdit
    Left = 32
    Top = 56
    Width = 441
    Height = 21
    TabOrder = 1
  end
  object bImageFile: TButton
    Left = 480
    Top = 56
    Width = 25
    Height = 21
    Caption = '...'
    TabOrder = 2
    OnClick = bImageFileClick
  end
  object cExpTiles: TCheckBox
    Left = 32
    Top = 120
    Width = 129
    Height = 17
    Caption = 'Export Tiles:'
    Checked = True
    State = cbChecked
    TabOrder = 3
    OnClick = cExpTilesClick
  end
  object eExpTileFile: TEdit
    Left = 32
    Top = 152
    Width = 441
    Height = 21
    TabOrder = 4
  end
  object bTileFile: TButton
    Left = 480
    Top = 152
    Width = 25
    Height = 21
    Caption = '...'
    TabOrder = 5
    OnClick = bTileFileClick
  end
  object cExpPal: TCheckBox
    Left = 32
    Top = 216
    Width = 129
    Height = 17
    Caption = 'Export a Palette:'
    Checked = True
    State = cbChecked
    TabOrder = 6
    OnClick = cExpPalClick
  end
  object eExpPalFile: TEdit
    Left = 32
    Top = 248
    Width = 441
    Height = 21
    TabOrder = 7
  end
  object bPalFile: TButton
    Left = 480
    Top = 248
    Width = 25
    Height = 21
    Caption = '...'
    TabOrder = 8
    OnClick = bPalFileClick
  end
  object bOK: TButton
    Left = 120
    Top = 320
    Width = 100
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'OK'
    TabOrder = 9
    OnClick = bOKClick
  end
  object bCancel: TButton
    Left = 280
    Top = 320
    Width = 100
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 10
  end
  object cbTileFormat: TComboBox
    Left = 360
    Top = 120
    Width = 145
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 11
  end
  object cbPalFormat: TComboBox
    Left = 360
    Top = 216
    Width = 145
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 12
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'vsk'
    Filter = 'Visual SAK (*.vsk)|*.vsk|ALL (*.*)|*.*'
    Left = 264
    Top = 16
  end
end
