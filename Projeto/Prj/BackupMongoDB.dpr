program BackupMongoDB;

uses
  Vcl.Forms,
  UMain in '..\Src\Forms\UMain.pas' {frmMain},
  UBackupScript in '..\Src\Units\UBackupScript.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.ShowMainForm := True;
  Application.Run;
end.
