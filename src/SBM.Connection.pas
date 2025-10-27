unit SBM.Connection;

interface

uses
    System.Classes, System.SysUtils, WinApi.WinSock, System.Generics.Collections, SBM.Security.RequestValidator, SBM.Exception,
    SBM.Routes;

type
    TSBMConnection = class
    private
        FSocket: TSocket;
        FRequestPolicy: TSBMRequestPolicy;
        FRouteRegistry: TSBMRouteRegistry;
    public
        constructor Create(ASocket: TSocket; ARequestPolicy: TSBMRequestPolicy; ARouteRegistry: TSBMRouteRegistry);
        procedure Close;
        function ReadData(var Request: TSBMRequest) : Boolean;
        procedure ProcessRequest;
        procedure SendData(const AData: String);
        procedure SendAndClose(const AData: String);
        procedure SendHttpResponse(AStatusCode: Integer; const AStatusMessage: String;
          const ABody: String = ''; const AContentType: String = 'text/plain'; const AExtraHeaders: TStrings = nil);
    end;

implementation

{ TSBMConnection }

constructor TSBMConnection.Create(ASocket: TSocket; ARequestPolicy: TSBMRequestPolicy; ARouteRegistry: TSBMRouteRegistry);
begin
    FSocket := ASocket;
    FRequestPolicy := ARequestPolicy;
    FRouteRegistry := ARouteRegistry;
end;

procedure TSBMConnection.Close;
begin
    shutdown(FSocket, SD_SEND);
    closesocket(FSocket);
end;

function TSBMConnection.ReadData(var Request: TSBMRequest) : Boolean;
var
    Buffer: array[0..1023] of Byte;
    BytesReceived: Integer;
    RawRequest: String;
begin
    BytesReceived := recv(FSocket, Buffer, Length(Buffer), 0);
    if BytesReceived = SOCKET_ERROR then
        raise Exception.Create('Failed to receive data from socket');

    SetString(RawRequest, PAnsiChar(@Buffer), BytesReceived);

    if (not TSBMRequestValidator.IsValidRequest(RawRequest)) then
        raise EHttpErrors.BadRequest;

    if (not TSBMRequestValidator.IsRequestSmugglingSafe(RawRequest)) then
        raise EHttpErrors.BadRequest;

    Request := TSBMRequestValidator.ParseRequest(RawRequest, FRequestPolicy);

    if (not Assigned(FRequestPolicy)) then
        Exit(True);

    if (not TSBMRequestValidator.IsRequestSizeAcceptable(RawRequest, FRequestPolicy)) then
        raise EHttpErrors.PayloadTooLarge;

    if (not TSBMRequestValidator.IsMethodAllowed(RawRequest, FRequestPolicy)) then
        raise EHttpErrors.MethodNotAllowed;

    if (not TSBMRequestValidator.HasRequiredHeaders(Request.Headers, FRequestPolicy)) then
        raise EHttpErrors.BadRequest;

    if (not TSBMRequestValidator.AreHeadersSafe(Request.Headers, FRequestPolicy)) then
        raise EHttpErrors.HeaderFieldsTooLarge;

    if (not TSBMRequestValidator.IsContentTypeValid(Request.Headers, FRequestPolicy)) then
        raise EHttpErrors.UnsupportedMediaType;

    if (not TSBMRequestValidator.IsHostValid(Request.Headers, FRequestPolicy)) then
        raise EHttpErrors.BadRequest;

    if (not TSBMRequestValidator.IsUserAgentAllowed(Request.Headers, FRequestPolicy)) then
        raise EHttpErrors.Forbidden;

    Result := True;
end;

procedure TSBMConnection.ProcessRequest;
var
    Handler: TSBMRouteHandler;
    ResponseBody: string;
    Headers: TStringList;
    Request: TSBMRequest;
begin
    if (not ReadData(Request)) then
        Exit;

    Handler := FRouteRegistry.GetHandler(Request.Path);

    // Exemplo fixo de retorno, os headers extras poderia até ser configurados
    Headers := TStringList.Create;
    try
        Headers.Add('Connection: close');
        Headers.Add('X-Custom-Header: SocketBareMetal');

        if Assigned(Handler) then
        begin
            Handler(Request, ResponseBody);
            SendHttpResponse(200, 'OK', ResponseBody, 'application/json', Headers);
        end
        else
            raise EHttpErrors.NotFound('{"error":"Route not found"}');
    finally
        Headers.Free;
    end;

    // Futuras etapas: autenticação, etc.
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


procedure TSBMConnection.SendHttpResponse(AStatusCode: Integer; const AStatusMessage: String;
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
