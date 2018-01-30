program VisualSAK;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {fmMain},
  uCompress in '..\FFV_Viewer\uCompress.pas',
  uTiles in '..\FFV_Viewer\uTiles.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
