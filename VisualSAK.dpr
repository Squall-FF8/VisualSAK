program VisualSAK;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {fmMain},
  uCompress in 'uCompress.pas',
  uTiles in 'uTiles.pas',
  uCommon in 'uCommon.pas',
  uExport in 'uExport.pas' {fmExport};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TfmExport, fmExport);
  Application.Run;
end.
