unit unMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, 
  System.Threading, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  SBM.Listener, SBM.ThreadPoolManager, SBM.Security.RequestValidator, SBM.Routes;

type
  TTestController = class
  public
    procedure Ping(const Request: TSBMRequest; var Response: String);
    procedure Echo(const Request: TSBMRequest; var Response: String);
  end;

  TfrmMain = class(TForm)
    btnIniciarServer: TButton;
    btnPararServer: TButton;
    procedure btnIniciarServerClick(Sender: TObject);
    procedure btnPararServerClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FListener: TSBMListener;
    FPoolManager: TSBMThreadPoolManager;
    FRequestPolicy: TSBMRequestPolicy;
    FRouteRegistry: TSBMRouteRegistry;
    FTask: ITask;

    FControllers: TObjectList<TObject>;
    FTestController: TTestController;
    
    procedure RegisterAllRoutes;
    procedure UnRegisterAllRoutes;
    procedure CloseListener;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

{ TTestController }

procedure TTestController.Echo(const Request: TSBMRequest; var Response: String);
begin
    Response := '{"echo":' + Request.Body + '}';
end;

procedure TTestController.Ping(const Request: TSBMRequest; var Response: String);
begin
    Response := '{"msg":"pong"}';
end;

{ TfrmMain }

procedure TfrmMain.RegisterAllRoutes;
begin
    
    FControllers := TObjectList<TObject>.Create(True);
    
    FTestController := TTestController.Create;
    FControllers.Add(FTestController);
    

    { TSBMRouteRegistry é o componente para definição das rotas, toda rota é baseada em um evento.
      O evento da rota ele possui um parametro que é a Requisição Completa e outro que é o Body de Resposta.
      * Implementar que seja possivel trabalhar com a Resposta completa customizando Headers.
      * Implementar os métodos, por exemplo dizer que determinada rota somente pode aceitar POST ou GET, ou todos.
      * Implementar sistema de middleware, semelhante o que temos no express.
    }
    FRouteRegistry := TSBMRouteRegistry.Create;
    FRouteRegistry.RegisterRoute('/ping', FTestController.Ping);
    FRouteRegistry.RegisterRoute('/echo', FTestController.Echo);
end;

procedure TfrmMain.UnRegisterAllRoutes;
begin
    if (Assigned(FRouteRegistry)) then
    begin
        FreeAndNil(FRouteRegistry);
        FreeAndNil(FControllers); 
    end;
end;

procedure TfrmMain.CloseListener;
begin
    if Assigned(FListener) then
    begin
        // Para de escutar a porta, libera as rotas e libera o componente
        FListener.Stop;
        UnRegisterAllRoutes;
        FreeAndNil(FListener);
    end;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
    CloseListener;
end;

procedure TfrmMain.btnIniciarServerClick(Sender: TObject);
var
    ListenerEncerrrado: Boolean;
begin    
    try
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

        // Procedimento para registrar as rotas
        RegisterAllRoutes;

        { TSBMListener responsável por escutar a porta, abrir o socket, possui dois parâmetros em ordem:
          * APort: Número da porta.
          * APoolManager: Objeto de TSBMThreadPoolManager.
          * ARequestPolicy: Objeto de TSBMRequestPolicy, se não for informado, não faz nenhum tipo de validação da estrutura, não faz parse dos Headers.
        }
    
        FListener := TSBMListener.Create(8080, FPoolManager, FRequestPolicy, FRouteRegistry);
    except
        on E : Exception do
        begin
            if (Assigned(FPoolManager)) then
                FreeAndNil(FPoolManager);

            if (Assigned(FRequestPolicy)) then
                FreeAndNil(FRequestPolicy);

            UnRegisterAllRoutes;
        
            ShowMessage(E.Message);
            Exit;
        end;
    end;
    
    { O SBM roda dentro de uma Thread, por isto aqui foi utilizado o TTaks,
      que é uma forma simples de criar um Thread no Delphi. Se ele não estiver
      em Thread a aplicação ficará presa a mainthread no momento do FListener.Start.
    }
    ListenerEncerrrado := False;
    FTask := TTask.Run(
    procedure
    begin
        try
            FListener.Start;
        except
            on E : Exception do
            begin
                ListenerEncerrrado := True;
                TThread.Synchronize(TThread.Current,
                procedure
                begin 
                    ShowMessage(E.Message);
                end);
            end;
        end;
    end);

    // Aguarda Iniciar
    while (not FListener.Running) do
    begin
        if (ListenerEncerrrado) then
        begin
            FreeAndNil(FListener);
            Exit;
        end;
        
        Sleep(10);
    end;

    ShowMessage('Servidor iniciado na porta 8080');
end;

procedure TfrmMain.btnPararServerClick(Sender: TObject);
begin
    CloseListener;
end;

end.
