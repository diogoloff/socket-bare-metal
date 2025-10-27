unit SBM.Exception;

interface

uses
    System.SysUtils, System.Classes;

type
    EHttpException = class(Exception)
    private
        FStatusCode: Integer;
        FStatusMessage: String;
        FStatusBody: String;
    public
        constructor Create(AStatusCode: Integer; const AStatusMessage: String; const AStatusBody: String);
        property StatusCode: Integer read FStatusCode;
        property StatusMessage: String read FStatusMessage;
        property StatusBody: String read FStatusBody;
    end;

    EHttpErrors = class
    public
        class function BadRequest(const AStatusBody: String = ''): EHttpException;
        class function Forbidden(const AStatusBody: String = ''): EHttpException;
        class function NotFound(const AStatusBody: String = ''): EHttpException;
        class function PayloadTooLarge(const AStatusBody: String = ''): EHttpException;
        class function MethodNotAllowed(const AStatusBody: String = ''): EHttpException;
        class function UnsupportedMediaType(const AStatusBody: String = ''): EHttpException;
        class function HeaderFieldsTooLarge(const AStatusBody: String = ''): EHttpException;
    end;

implementation

{ EHttpException }

constructor EHttpException.Create(AStatusCode: Integer; const AStatusMessage: String; const AStatusBody: String);
begin
    inherited Create(FStatusMessage);
    FStatusCode := AStatusCode;
    FStatusMessage := AStatusMessage;
    FStatusBody := AStatusBody;
end;

{ TEHttpErrors }

class function EHttpErrors.BadRequest(const AStatusBody: String): EHttpException;
begin
    Result := EHttpException.Create(400, 'Bad Request', AStatusBody);
end;

class function EHttpErrors.Forbidden(const AStatusBody: String): EHttpException;
begin
    Result := EHttpException.Create(403, 'Forbidden', AStatusBody);
end;

class function EHttpErrors.NotFound(const AStatusBody: String): EHttpException;
begin
    Result := EHttpException.Create(404, 'Not Found', AStatusBody);
end;

class function EHttpErrors.MethodNotAllowed(const AStatusBody: String): EHttpException;
begin
    Result := EHttpException.Create(405, 'Method Not Allowed', AStatusBody);
end;

class function EHttpErrors.PayloadTooLarge(const AStatusBody: String): EHttpException;
begin
    Result := EHttpException.Create(413, 'Payload Too Large', AStatusBody);
end;

class function EHttpErrors.UnsupportedMediaType(const AStatusBody: String): EHttpException;
begin
    Result := EHttpException.Create(415, 'Unsupported Media Type', AStatusBody);
end;

class function EHttpErrors.HeaderFieldsTooLarge(const AStatusBody: String): EHttpException;
begin
    Result := EHttpException.Create(431, 'Request Header Fields Too Large', AStatusBody);
end;

end.
