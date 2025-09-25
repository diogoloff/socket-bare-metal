unit SBM.Connection;

interface

uses
    System.Classes, System.SysUtils, WinApi.WinSock, System.Generics.Collections, SBM.Security.RequestValidator, SBM.Exception;

type
    TSBMConnection = class
    private
        FSocket: TSocket;
        FRequestPolicy: TSBMRequestPolicy;
    public
        constructor Create(ASocket: TSocket; ARequestPolicy: TSBMRequestPolicy);
        procedure Close;
        function ReadData : Boolean;
        procedure ProcessRequest;
        procedure SendData(const AData: String);
        procedure SendAndClose(const AData: String);
        procedure SendHttpResponse(AStatusCode: Integer; const AStatusMessage: String;
          const ABody: String = ''; const AContentType: String = 'text/plain'; const AExtraHeaders: TStrings = nil);
    end;

implementation

{ TSBMConnection }

constructor TSBMConnection.Create(ASocket: TSocket; ARequestPolicy: TSBMRequestPolicy);
begin
    FSocket := ASocket;
    FRequestPolicy := ARequestPolicy;
end;

procedure TSBMConnection.Close;
begin
    shutdown(FSocket, SD_SEND);
    closesocket(FSocket);
end;

function TSBMConnection.ReadData : Boolean;
var
    Buffer: array[0..1023] of Byte;
    BytesReceived: Integer;
    RawRequest: String;
    Headers: TDictionary<String, String>;
begin
    BytesReceived := recv(FSocket, Buffer, Length(Buffer), 0);
    if BytesReceived = SOCKET_ERROR then
        raise Exception.Create('Failed to receive data from socket');

    SetString(RawRequest, PAnsiChar(@Buffer), BytesReceived);

    if (not TSBMRequestValidator.IsValidRequest(RawRequest)) then
        raise EHttpErrors.BadRequest;

    if (not TSBMRequestValidator.IsRequestSmugglingSafe(RawRequest)) then
        raise EHttpErrors.BadRequest;

    if (not Assigned(FRequestPolicy)) then
        Exit(True);

    if (not TSBMRequestValidator.IsRequestSizeAcceptable(RawRequest, FRequestPolicy)) then
        raise EHttpErrors.PayloadTooLarge;

    if (not TSBMRequestValidator.IsMethodAllowed(RawRequest, FRequestPolicy)) then
        raise EHttpErrors.MethodNotAllowed;

    Headers := TSBMRequestValidator.ParseHeaders(RawRequest, FRequestPolicy);
    try
        if (not TSBMRequestValidator.HasRequiredHeaders(Headers, FRequestPolicy)) then
            raise EHttpErrors.BadRequest;

        if (not TSBMRequestValidator.AreHeadersSafe(Headers, FRequestPolicy)) then
            raise EHttpErrors.HeaderFieldsTooLarge;

        if (not TSBMRequestValidator.IsContentTypeValid(Headers, FRequestPolicy)) then
            raise EHttpErrors.UnsupportedMediaType;

        if (not TSBMRequestValidator.IsHostValid(Headers, FRequestPolicy)) then
            raise EHttpErrors.BadRequest;

        if (not TSBMRequestValidator.IsUserAgentAllowed(Headers, FRequestPolicy)) then
            raise EHttpErrors.Forbidden;
    finally
        Headers.Free;
    end;

    Result := True;
end;

procedure TSBMConnection.ProcessRequest;
var
    Headers: TStringList;
begin
    if (not ReadData) then
        Exit;

    // Exemplo fixo de retorno, os headers extras poderia até ser configurados
    Headers := TStringList.Create;
    try
        Headers.Add('Connection: close');
        Headers.Add('X-Custom-Header: SocketBareMetal');

        SendHttpResponse(200, 'OK', '{"msg":"done"}', 'application/json', Headers);
    finally
        Headers.Free;
    end;

    // Futuras etapas: autenticação, roteamento, etc.
end;

procedure TSBMConnection.SendData(const AData: String);
begin
    if send(FSocket, PAnsiChar(AnsiString(AData))^, Length(AData), 0) = SOCKET_ERROR then
        raise Exception.Create('Failed to send data to socket');
end;

procedure TSBMConnection.SendAndClose(const AData: String);
begin
    try
        SendData(AData);
    finally
        Close;
        Free;
    end;
end;


procedure TSBMConnection.SendHttpResponse(AStatusCode: Integer; const AStatusMessage: string;
  const ABody: String; const AContentType: String; const AExtraHeaders: TStrings);
var
    Response: TStringBuilder;
begin
    Response := TStringBuilder.Create;
    try
        // Linha do Status
        Response.AppendFormat('HTTP/1.1 %d %s'#13#10, [AStatusCode, AStatusMessage]);

        // Content-Type
        if ABody <> '' then
            Response.AppendFormat('Content-Type: %s'#13#10, [AContentType]);

        // Content-Length
        Response.AppendFormat('Content-Length: %d'#13#10, [Length(ABody)]);

        // Headers extras
        if Assigned(AExtraHeaders) then
            Response.Append(AExtraHeaders.Text);

        // Fim dos headers
        Response.Append(#13#10);

        // Corpo
        Response.Append(ABody);

        // Envia e fecha
        SendAndClose(Response.ToString);
    finally
        Response.Free;
    end;
end;

end.
