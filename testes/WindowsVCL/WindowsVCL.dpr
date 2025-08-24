program WindowsVCL;

uses
  System.SysUtils,
  Vcl.Forms,
  unMain in 'unMain.pas' {frmMain};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
