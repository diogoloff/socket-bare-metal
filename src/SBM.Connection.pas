unit SBM.Connection;

interface

uses
    System.SysUtils, WinApi.WinSock;

type
    TSBMConnection = class
    private
        FSocket: TSocket;
    public
        constructor Create(ASocket: TSocket);
        procedure ReadData;
        procedure SendData(const AData: string);
        procedure SendAndClose(const AData: string);
        procedure Close;
    end;

implementation

{ TSBMConnection }

constructor TSBMConnection.Create(ASocket: TSocket);
begin
    FSocket := ASocket;
end;

procedure TSBMConnection.ReadData;
var
    Buffer: array[0..1023] of Byte;
    BytesReceived: Integer;
begin
    BytesReceived := recv(FSocket, Buffer, Length(Buffer), 0);
    if BytesReceived = SOCKET_ERROR then
        raise Exception.Create('Erro ao receber dados');

    // Aqui você pode converter o buffer para string e processar
end;

procedure TSBMConnection.SendData(const AData: string);
begin
    if send(FSocket, PAnsiChar(AnsiString(AData))^, Length(AData), 0) = SOCKET_ERROR then
        raise Exception.Create('Erro ao enviar dados');
end;

procedure TSBMConnection.SendAndClose(const AData: string);
begin
    try
        SendData(AData);
    finally
        Close;
        Free;
    end;
end;

procedure TSBMConnection.Close;
begin
    shutdown(FSocket, SD_SEND);
    closesocket(FSocket);
end;

end.
