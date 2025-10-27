unit unMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Threading,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  SBM.Listener, SBM.ThreadPoolManager, SBM.Security.REquestValidator;

type
  TfrmMain = class(TForm)
    btnIniciarServer: TButton;
    btnPararServer: TButton;
    procedure btnIniciarServerClick(Sender: TObject);
    procedure btnPararServerClick(Sender: TObject);
  private
    { Private declarations }
    FListener: TSBMListener;
    FPoolManager: TSBMThreadPoolManager;
    FRequestPolicy: TSBMRequestPolicy;
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

        { TSBMRequestPolicy é o componente para validar algumas questões de segurança da
          estrutura da requisição. O exemplo abaixo esta com os mesmos valores Default que
          já são criados no TSBMRequestPolicy.Create então não é necessário declarar todos,
          somente os que deseja sobrescrever.
        }
        FRequestPolicy := TSBMRequestPolicy.Create;

        with FRequestPolicy do
        begin
            AllowedMethods := ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'];
            RequiredHeaders := ['host', 'user-agent'];
            AllowedContentTypes := ['application/json', 'text/plain'];
            AllowedHosts := [];
            BlockedUserAgents := ['curl', 'bot'];
            MaxRequestSize := 8192;
            MaxHeaderKeySize := 100;
            MaxHeaderValueSize := 1024;
            MaxHeaderSize := 2048;
            MaxHeaderCount := 50;
        end;

        { TSBMListener responsável por escutar a porta, abrir o socket, possui dois parâmetros em ordem:
          * APort: Número da porta.
          * APoolManager: Objeto de TSBMThreadPoolManager.
          * ARequestPolicy: Objeto de TSBMRequestPolicy, se não for informado, não faz nenhum tipo de validação da estrutura, não faz parse dos Headers.
        }
        FListener := TSBMListener.Create(8080, FPoolManager, FRequestPolicy, nil);
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
