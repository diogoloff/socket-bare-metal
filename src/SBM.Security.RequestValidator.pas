unit SBM.Security.RequestValidator;

interface

uses
    System.SysUtils, System.Classes, System.Generics.Collections;

type
    TSBMRequestValidator = class
    public
        class function IsValidRequest(const Raw: string): Boolean;
        class function ParseHeaders(const Raw: string): TDictionary<string, string>;
        class function AreHeadersSafe(const Headers: TDictionary<string, string>): Boolean;
        class function HasRequiredHeaders(const Headers: TDictionary<string, string>): Boolean;
        class function IsRequestSizeAcceptable(const Raw: string; MaxSize: Integer = 8192): Boolean;
    end;

implementation

class function TSBMRequestValidator.IsValidRequest(const Raw: string): Boolean;
begin
  Result :=
    Raw.StartsWith('GET ') or
    Raw.StartsWith('POST ') or
    Raw.StartsWith('HEAD ') or
    Raw.StartsWith('PUT ') or
    Raw.StartsWith('DELETE ') or
    Raw.StartsWith('OPTIONS ') or
    Raw.StartsWith('PATCH ');
end;

class function TSBMRequestValidator.IsRequestSizeAcceptable(const Raw: string; MaxSize: Integer): Boolean;
begin
    Result := Length(Raw) <= MaxSize;
end;

class function TSBMRequestValidator.ParseHeaders(const Raw: string): TDictionary<string, string>;
var
  Lines: TArray<string>;
  Line, Key, Value: string;
  I, SepPos: Integer;
begin
    Result := TDictionary<string, string>.Create;
    Lines := Raw.Split([#13#10]);
    for I := 1 to High(Lines) do
    begin
        Line := Lines[I].Trim;
        if Line = '' then
            Break;

        SepPos := Line.IndexOf(':');
        if SepPos > 0 then
        begin
            Key := Line.Substring(0, SepPos).Trim;
            Value := Line.Substring(SepPos + 1).Trim;
            Result.AddOrSetValue(Key.ToLower, Value);
        end;
    end;
end;

class function TSBMRequestValidator.AreHeadersSafe(const Headers: TDictionary<string, string>): Boolean;
var
    Key: string;
begin
    Result := Headers.Count <= 50;
    if not Result then
        Exit;

    for Key in Headers.Keys do
        if Length(Key) > 100 then
            Exit(False);
end;

class function TSBMRequestValidator.HasRequiredHeaders(const Headers: TDictionary<string, string>): Boolean;
begin
    Result := Headers.ContainsKey('host');
end;

end.

