{
  Nesta falta definir algum objeto de configuração, onde seja possivel setar na criação do listener o padrão das coisas,
  como que header são exigidos, que metodos, tipo de conteudo, tamanho do conteudo e dos headers
}

unit SBM.Security.RequestValidator;

interface

uses
    System.SysUtils, System.Classes, System.Generics.Collections, System.RegularExpressions, System.StrUtils;

type
    TSBMRequestValidator = class
    public
        // Validação geral do método HTTP
        class function IsValidRequest(const ARaw: String): Boolean;

        // Validação de tamanho da requisição
        class function IsRequestSizeAcceptable(const ARaw: String; AMaxSize: Integer = 8192): Boolean;

        // Parse dos headers em dicionário
        class function ParseHeaders(const ARaw: String): TDictionary<String, String>;

        // Proteção contra HTTP Request Smuggling
        class function IsRequestSmugglingSafe(const ARaw: String): Boolean;

        // Validação de método permitido
        class function IsMethodAllowed(const ARaw: String): Boolean;

        // Validação de headers obrigatórios
        class function HasRequiredHeaders(const AHeaders: TDictionary<String, String>): Boolean;

        // Validação de segurança dos headers
        class function AreHeadersSafe(const AHeaders: TDictionary<String, String>): Boolean;

        // Validação de Content-Type
        class function IsContentTypeValid(const AHeaders: TDictionary<String, String>): Boolean;

        // Validação de Host
        class function IsHostValid(const AHeaders: TDictionary<String, String>): Boolean;

        // Validação de User-Agent
        class function IsUserAgentAllowed(const AHeaders: TDictionary<String, String>): Boolean;
    end;

implementation

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

class function TSBMRequestValidator.IsRequestSizeAcceptable(const ARaw: String; AMaxSize: Integer): Boolean;
begin
    Result := Length(ARaw) <= AMaxSize;
end;

class function TSBMRequestValidator.IsRequestSmugglingSafe(const ARaw: String): Boolean;
begin
    Result := (ARaw.IndexOf('Content-Length:') = ARaw.LastIndexOf('Content-Length:')) and (not ARaw.Contains('Transfer-Encoding: chunked'));
end;

class function TSBMRequestValidator.IsMethodAllowed(const ARaw: String): Boolean;
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

    Result := IndexStr(Method, ['GET', 'POST', 'PUT', 'DELETE']) >= 0;
end;

class function TSBMRequestValidator.ParseHeaders(const ARaw: String): TDictionary<String, String>;
var
    Lines: TArray<String>;
    Line, Key, Value: String;
    I, SepPos: Integer;
    Bytes: TBytes;
begin
    Result := TDictionary<String, String>.Create;
    Lines := ARaw.Split([#13#10]);
    for I := 1 to High(Lines) do
    begin
        Line := Lines[I].Trim;
        if (Line = '') then
            Break;

        SepPos := Line.IndexOf(':');
        if (SepPos > 0) then
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

            // Limite de tamanho por valor individual
            if (Length(Value) > 1024) then
                Continue;

            // Descarta header com tamanho total superior ao limite
            if (Length(Key) + Length(Value) > 4096) then
                Continue;

            Result.AddOrSetValue(Key.ToLower, Value);
        end;
    end;
end;

class function TSBMRequestValidator.HasRequiredHeaders(const AHeaders: TDictionary<String, String>): Boolean;
begin
    Result := AHeaders.ContainsKey('host');
end;

class function TSBMRequestValidator.AreHeadersSafe(const AHeaders: TDictionary<String, String>): Boolean;
var
    Key: string;
begin
    Result := AHeaders.Count <= 50;
    if (not Result) then
        Exit;

    for Key in AHeaders.Keys do
        if Length(Key) > 100 then
            Exit(False);
end;

class function TSBMRequestValidator.IsContentTypeValid(const AHeaders: TDictionary<String, String>): Boolean;
var
    ContentType: string;
begin
    if (not AHeaders.TryGetValue('content-type', ContentType)) then
        Exit(True);

    Result := ContentType.StartsWith('application/json') or ContentType.StartsWith('text/plain');
end;

class function TSBMRequestValidator.IsHostValid(const AHeaders: TDictionary<String, String>): Boolean;
var
    Host: string;
begin
    if (not AHeaders.TryGetValue('host', Host)) then
        Exit(False);

    Result := (Host <> '') and (not Host.Contains(' '));
end;

class function TSBMRequestValidator.IsUserAgentAllowed(const AHeaders: TDictionary<String, String>): Boolean;
var
    UA: String;
begin
    if (not AHeaders.TryGetValue('user-agent', UA)) then
        Exit(True);

    Result := (not UA.Contains('curl')) and (not UA.Contains('bot'));
end;

end.

