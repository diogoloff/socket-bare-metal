unit unMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Threading,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  SBM.Listener, SBM.ThreadPoolManager;

type
  TfrmMain = class(TForm)
    btnIniciarServer: TButton;
    btnPararServer: TButton;
    procedure btnIniciarServerClick(Sender: TObject);
    procedure btnPararServerClick(Sender: TObject);
  private
    { Private declarations }
    FListener : TSBMListener;
    FPoolManager: TSBMThreadPoolManager;
    FTask: ITask;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.btnIniciarServerClick(Sender: TObject);
begin
    FTask := TTask.Run(
    procedure
    begin
        FPoolManager := TSBMThreadPoolManager.Create; // posso indicar tamanho e quantos workers padrão cada fila tera


        FListener := TSBMListener.Create(8080, FPoolManager);
        FListener.Start;
    end);

    ShowMessage('Servidor iniciado na porta 8080');
end;

procedure TfrmMain.btnPararServerClick(Sender: TObject);
begin
    if Assigned(FListener) then
    begin
        FListener.Stop;
        FListener.Free;
    end;
end;

end.
