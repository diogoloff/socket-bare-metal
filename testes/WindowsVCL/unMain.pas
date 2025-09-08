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
    { O SBM roda dentro de uma Thread, por isto aqui foi utilizado o TTaks,
      que é uma forma simples de criar um Thread no Delphi. Se ele não estiver
      em Thread a aplicação ficará presa a mainthread no momento do FListener.Start.
    }
    FTask := TTask.Run(
    procedure
    begin
        { TSBMThreadPoolManager é o componente primordial do controle das requisições
          ele irá gerenciar a carga suportada, possui três parâmetros em ordem:
          * AMaxQueueSize: Tamanho máximo da fila de um worker, default 10.
          * ADefaultThreadCount: Quantidade de workers, default 4.
          * AScaleThreshold: Tamanho máximo da fila para escalar automaticamente novos workers,
                             se este valor for >= a AMaxQueueSize não escala automaticamente, default 10.
        }
        FPoolManager := TSBMThreadPoolManager.Create;

        { TSBMListener responsável por escutar a porta, abrir o socket, possui dois parâmetros em ordem:
          * APort: Número da porta.
          * APoolManager: Objeto de TSBMThreadPoolManager.
        }
        FListener := TSBMListener.Create(8080, FPoolManager);
        FListener.Start;
    end);

    ShowMessage('Servidor iniciado na porta 8080');
end;

procedure TfrmMain.btnPararServerClick(Sender: TObject);
begin
    if Assigned(FListener) then
    begin
        // Para de escutar a porta e libera o componente
        FListener.Stop;
        FListener.Free;
    end;
end;

end.
