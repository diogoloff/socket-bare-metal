unit SBM.Exception;

interface

uses
    System.SysUtils, System.Classes;

type
    EHttpException = class(Exception)
    private
        FStatusCode: Integer;
        FStatusMessage: String;
    public
        constructor Create(AStatusCode: Integer; const AStatusMessage: String);
        property StatusCode: Integer read FStatusCode;
        property StatusMessage: String read FStatusMessage;
    end;

    EHttpErrors = class
    public
        class function BadRequest: EHttpException;
        class function Forbidden: EHttpException;
        class function PayloadTooLarge: EHttpException;
        class function MethodNotAllowed: EHttpException;
        class function UnsupportedMediaType: EHttpException;
        class function HeaderFieldsTooLarge: EHttpException;
    end;

implementation

{ EHttpException }

constructor EHttpException.Create(AStatusCode: Integer; const AStatusMessage: String);
begin
    inherited Create(FStatusMessage);
    FStatusCode := AStatusCode;
    FStatusMessage := AStatusMessage;
end;

{ TEHttpErrors }

class function EHttpErrors.BadRequest: EHttpException;
begin
    Result := EHttpException.Create(400, 'Bad Request');
end;

class function EHttpErrors.Forbidden: EHttpException;
begin
    Result := EHttpException.Create(403, 'Forbidden');
end;

class function EHttpErrors.MethodNotAllowed: EHttpException;
begin
    Result := EHttpException.Create(405, 'Method Not Allowed');
end;

class function EHttpErrors.PayloadTooLarge: EHttpException;
begin
    Result := EHttpException.Create(413, 'Payload Too Large');
end;

class function EHttpErrors.UnsupportedMediaType: EHttpException;
begin
    Result := EHttpException.Create(415, 'Unsupported Media Type');
end;

class function EHttpErrors.HeaderFieldsTooLarge: EHttpException;
begin
    Result := EHttpException.Create(431, 'Request Header Fields Too Large');
end;

end.
