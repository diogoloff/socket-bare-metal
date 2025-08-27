unit SBM.Connection;

interface

uses
    System.SysUtils, WinApi.WinSock, System.Generics.Collections, SBM.Security.RequestValidator;

type
    TSBMConnection = class
    private
        FSocket: TSocket;
    public
        constructor Create(ASocket: TSocket);
        function ReadData : Boolean;
        procedure ProcessRequest;
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

function TSBMConnection.ReadData : Boolean;
var
    Buffer: array[0..1023] of Byte;
    BytesReceived: Integer;
    RawRequest: string;
    Headers: TDictionary<String, String>;
begin
    Result := False;

    BytesReceived := recv(FSocket, Buffer, Length(Buffer), 0);
    if BytesReceived = SOCKET_ERROR then
        raise Exception.Create('Erro ao receber dados');

    SetString(RawRequest, PAnsiChar(@Buffer), BytesReceived);

    if not TSBMRequestValidator.IsValidRequest(RawRequest) then
    begin
        SendAndClose('HTTP/1.1 400 Bad Request'#13#10 + 'Content-Length: 0'#13#10#13#10);
        Exit;
    end;

    if not TSBMRequestValidator.IsRequestSizeAcceptable(RawRequest) then
    begin
        SendAndClose('HTTP/1.1 413 Payload Too Large'#13#10 + 'Content-Length: 0'#13#10#13#10);
        Exit;
    end;

    Headers := TSBMRequestValidator.ParseHeaders(RawRequest);
    try
        if not TSBMRequestValidator.HasRequiredHeaders(Headers) then
        begin
            SendAndClose('HTTP/1.1 400 Missing Required Headers'#13#10 + 'Content-Length: 0'#13#10#13#10);
            Exit;
        end;

        if not TSBMRequestValidator.AreHeadersSafe(Headers) then
        begin
            SendAndClose('HTTP/1.1 431 Request Header Fields Too Large'#13#10 + 'Content-Length: 0'#13#10#13#10);
            Exit;
        end;
    finally
        Headers.Free;
    end;

    Result := True;
end;

procedure TSBMConnection.ProcessRequest;
begin
    if (not ReadData) then
        Exit;

    SendAndClose('HTTP/1.1 200 OK'#13#10 + 'Content-Length: 0'#13#10#13#10);

    // Futuras etapas: autenticação, roteamento, etc.
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
