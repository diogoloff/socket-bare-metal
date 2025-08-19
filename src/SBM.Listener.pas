unit SBM.Listener;

interface

uses
    System.SysUtils, WinApi.Windows, WinApi.WinSock;

type
    TSBMListener = class
    private
        FServerSocket: TSocket;
        FPort: Word;
        procedure InitWinSock;
        procedure CreateSocket;
        procedure BindAndListen;
    public
        constructor Create(APort: Word);
        procedure Start;
        procedure Stop;
    end;

implementation

{ TSBMListener }

constructor TSBMListener.Create(APort: Word);
begin
    FPort := APort;
end;

procedure TSBMListener.InitWinSock;
var
    WSAData: TWSAData;
begin
    if WSAStartup($0202, WSAData) <> 0 then
        raise Exception.Create('Erro ao iniciar WinSock');
end;

procedure TSBMListener.CreateSocket;
begin
    // Criar o socket no padrao TCP e foco em IPV4, como seria se pudesse trabalhar com IPV6 tb ou UDP?
    FServerSocket := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if FServerSocket = INVALID_SOCKET then
        raise Exception.Create('Erro ao criar socket');
end;

procedure TSBMListener.BindAndListen;
var
    Addr: TSockAddrIn;
begin
    ZeroMemory(@Addr, SizeOf(Addr));
    Addr.sin_family := AF_INET;  // Foco em IPV4, como seria se pudesse trabalhar com IPV6 tb?
    Addr.sin_port := htons(FPort);
    Addr.sin_addr.S_addr := INADDR_ANY;

    // Abre a porta
    if bind(FServerSocket, Addr, SizeOf(Addr)) = SOCKET_ERROR then
        raise Exception.Create('Erro no bind');

    // Passa escutar a porta, SOMAXCONN representa o máximo de conexões aceitas, vem do SO, ver mais sobre
    if listen(FServerSocket, SOMAXCONN) = SOCKET_ERROR then
        raise Exception.Create('Erro no listen');
end;

procedure TSBMListener.Start;
begin
    InitWinSock;
    CreateSocket;
    BindAndListen;

    // Aqui futuramente vamos aceitar conexões e repassar para o thread pool
end;

procedure TSBMListener.Stop;
begin
    closesocket(FServerSocket);
    WSACleanup;
end;

end.

