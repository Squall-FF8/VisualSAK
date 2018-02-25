program VisualSAK;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {fmMain},
  uCompress in 'uCompress.pas',
  uTiles in 'uTiles.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
