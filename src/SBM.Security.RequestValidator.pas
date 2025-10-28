{
  Nesta falta definir algum objeto de configuração, onde seja possivel setar na criação do listener o padrão das coisas,
  como que header são exigidos, que metodos, tipo de conteudo, tamanho do conteudo e dos headers
}

unit SBM.Security.RequestValidator;

interface

uses
    System.SysUtils, System.Classes, System.Generics.Collections, System.RegularExpressions, System.StrUtils;

type
    // Aqui poderia ter também o query param, e até os parâmetros em path
    TSBMRequest = record
        Method: string;
        Path: string;
        Headers: TDictionary<String, String>;
        Body: string;

        procedure Finalize;
    end;

    TSBMRequestPolicy = class
    public
        AllowedMethods: TArray<string>;
        RequiredHeaders: TArray<string>;
        AllowedContentTypes: TArray<string>;
        AllowedHosts: TArray<string>;
        BlockedUserAgents: TArray<string>;
        MaxRequestSize: Integer;
        MaxHeaderKeySize: Integer;
        MaxHeaderValueSize: Integer;
        MaxHeaderSize: Integer;
        MaxHeaderCount: Integer;
        constructor Create;
    end;

    TSBMRequestValidator = class
    public
        // Validação geral do método HTTP
        class function IsValidRequest(const ARaw: String): Boolean;

        // Proteção contra HTTP Request Smuggling
        class function IsRequestSmugglingSafe(const ARaw: String): Boolean;

        // Validação de tamanho da requisição
        class function IsRequestSizeAcceptable(const ARaw: String; const APolicy: TSBMRequestPolicy): Boolean;

        // Parse da requisição
        class function ParseRequest(const ARaw: String; const APolicy: TSBMRequestPolicy): TSBMRequest;

        // Validação de método permitido
        class function IsMethodAllowed(const ARaw: String; const APolicy: TSBMRequestPolicy): Boolean;

        // Validação de headers obrigatórios
        class function HasRequiredHeaders(const AHeaders: TDictionary<String, String>; const APolicy: TSBMRequestPolicy): Boolean;

        // Validação de segurança dos headers
        class function AreHeadersSafe(const AHeaders: TDictionary<String, String>; const APolicy: TSBMRequestPolicy): Boolean;

        // Validação de Content-Type
        class function IsContentTypeValid(const AHeaders: TDictionary<String, String>; const APolicy: TSBMRequestPolicy): Boolean;

        // Validação de Host
        class function IsHostValid(const AHeaders: TDictionary<String, String>; const APolicy: TSBMRequestPolicy): Boolean;

        // Validação de User-Agent
        class function IsUserAgentAllowed(const AHeaders: TDictionary<String, String>; const APolicy: TSBMRequestPolicy): Boolean;
    end;

implementation

{ TSBMRequest }

procedure TSBMRequest.Finalize;
begin
    if Assigned(Headers) then
        FreeAndNil(Headers);
end;

{ TSBMRequestPolicy }

constructor TSBMRequestPolicy.Create;
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

{ TSBMRequestValidator }

class function TSBMRequestValidator.IsValidRequest(const ARaw: String): Boolean;
begin
    Result :=
        ARaw.StartsWith('GET ') or
        ARaw.StartsWith('POST ') or
        ARaw.StartsWith('HEAD ') or
        ARaw.StartsWith('PUT ') or
        ARaw.StartsWith('DELETE ') or
        ARaw.StartsWith('OPTIONS ') or
        ARaw.StartsWith('PATCH ');
end;

class function TSBMRequestValidator.IsRequestSmugglingSafe(const ARaw: String): Boolean;
begin
    Result := (ARaw.IndexOf('Content-Length:') = ARaw.LastIndexOf('Content-Length:')) and (not ARaw.Contains('Transfer-Encoding: chunked'));
end;

class function TSBMRequestValidator.IsRequestSizeAcceptable(const ARaw: String; const APolicy: TSBMRequestPolicy): Boolean;
begin
    Result := Length(ARaw) <= APolicy.MaxRequestSize;
end;

class function TSBMRequestValidator.IsMethodAllowed(const ARaw: String; const APolicy: TSBMRequestPolicy): Boolean;
var
    FirstLine: String;
    LineEnd: Integer;
    Method: String;
begin
    LineEnd := Pos(#13#10, ARaw);
    if (LineEnd > 0) then
        FirstLine := Copy(ARaw, 1, LineEnd - 1)
    else
        FirstLine := ARaw;

    Method := Trim(Copy(FirstLine, 1, Pos(' ', FirstLine) - 1));

    Result := IndexStr(Method, APolicy.AllowedMethods) >= 0;
end;

class function TSBMRequestValidator.ParseRequest(const ARaw: String; const APolicy: TSBMRequestPolicy): TSBMRequest;
var
    Lines: TArray<String>;
    i: Integer;
    InHeaders: Boolean;
    RequestLine: TArray<String>;
    Line: String;
    SepPos: Integer;
    Key: String;
    Value: String;
    Bytes: TBytes;
begin
    Lines := ARaw.Split([#13#10]);
    Result.Headers := TDictionary<String, String>.Create;
    Result.Body := '';
    Result.Method := '';
    Result.Path := '';

    if Length(Lines) > 0 then
    begin
        RequestLine := Lines[0].Split([' ']);
        if Length(RequestLine) >= 2 then
        begin
            Result.Method := RequestLine[0];
            Result.Path := RequestLine[1];
        end;
    end;

    InHeaders := True;
    for I := 1 to High(Lines) do
    begin
        Line := Lines[I].Trim;

        if InHeaders then
        begin
            if Line = '' then
            begin
                InHeaders := False;
                Continue;
            end;

            SepPos := Line.IndexOf(':');
            if SepPos > 0 then
            begin
                Key := Line.Substring(0, SepPos).Trim;
                Value := Line.Substring(SepPos + 1).Trim;

                // Remover caracteres de controle #0 a #31
                Value := TRegEx.Replace(Value, '[\x00-\x1F]', '');
                Value := Trim(Value);

                // Validar encoding UTF-8
                // Ignora header com encoding inválido
                try
                    Bytes := TEncoding.UTF8.GetBytes(Value);
                    Value := TEncoding.UTF8.GetString(Bytes);
                except
                    Continue;
                end;

                // Algumas verificações de politicas de segurança
                if Assigned(APolicy) then
                begin
                    if Length(Key) > APolicy.MaxHeaderKeySize then Continue;
                    if Length(Value) > APolicy.MaxHeaderValueSize then Continue;
                    if Length(Key) + Length(Value) > APolicy.MaxHeaderSize then Continue;
                end;

                Result.Headers.AddOrSetValue(Key.ToLower, Value);
            end;
        end
        else
            Result.Body := Result.Body + Line + #13#10;
    end;

    Result.Body := Result.Body.Trim;
end;

class function TSBMRequestValidator.HasRequiredHeaders(const AHeaders: TDictionary<String, String>; const APolicy: TSBMRequestPolicy): Boolean;
var
    RequiredHeader: string;
begin
    for RequiredHeader in APolicy.RequiredHeaders do
    begin
        if not AHeaders.ContainsKey(RequiredHeader.ToLower) then
            Exit(False);
    end;

    Result := True;
end;

class function TSBMRequestValidator.AreHeadersSafe(const AHeaders: TDictionary<String, String>; const APolicy: TSBMRequestPolicy): Boolean;
begin
    Result := AHeaders.Count <= APolicy.MaxHeaderCount;
    if (not Result) then
        Exit;
end;

class function TSBMRequestValidator.IsContentTypeValid(const AHeaders: TDictionary<String, String>; const APolicy: TSBMRequestPolicy): Boolean;
var
    ContentType, Allowed: string;
begin
    if (not AHeaders.TryGetValue('content-type', ContentType)) then
        Exit(True);

    ContentType := ContentType.ToLower;

    for Allowed in APolicy.AllowedContentTypes do
    begin
        if ContentType.StartsWith(Allowed.ToLower) then
            Exit(True);
    end;

    Result := False;
end;

class function TSBMRequestValidator.IsHostValid(const AHeaders: TDictionary<String, String>; const APolicy: TSBMRequestPolicy): Boolean;
var
    Host: string;
begin
    if (not AHeaders.TryGetValue('host', Host)) then
        Exit(False);

    Host := Host.ToLower;

    if Length(APolicy.AllowedHosts) > 0 then
        Result := (Host <> '') and (not Host.Contains(' ')) and (MatchText(Host, APolicy.AllowedHosts))
    else
        Result := (Host <> '') and (not Host.Contains(' '));
end;

class function TSBMRequestValidator.IsUserAgentAllowed(const AHeaders: TDictionary<String, String>; const APolicy: TSBMRequestPolicy): Boolean;
var
    UA, Blocked: string;
begin
    if not AHeaders.TryGetValue('user-agent', UA) then
        Exit(True);

    UA := UA.ToLower;

    for Blocked in APolicy.BlockedUserAgents do
    begin
        if UA.Contains(Blocked.ToLower) then
            Exit(False);
    end;

    Result := True;
end;

end.

