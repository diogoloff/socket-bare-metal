unit SBM.Routes;

interface

uses
    System.SysUtils, System.Generics.Collections, SBM.Security.RequestValidator;

type
    TSBMRouteHandler = procedure(const Request: TSBMRequest; var Response: String) of object;

    TSBMRouteRegistry = class
    private
        FRoutes: TDictionary<String, TSBMRouteHandler>;
    public
        constructor Create;
        destructor Destroy; override;

        procedure RegisterRoute(const Path: String; Handler: TSBMRouteHandler);
        function GetHandler(const Path: String): TSBMRouteHandler;
    end;

implementation

{ TSBMRouteRegistry }

constructor TSBMRouteRegistry.Create;
begin
    FRoutes := TDictionary<string, TSBMRouteHandler>.Create;
end;

destructor TSBMRouteRegistry.Destroy;
begin
    FreeAndNil(FRoutes);
    inherited;
end;

function TSBMRouteRegistry.GetHandler(const Path: String): TSBMRouteHandler;
begin
    if not FRoutes.TryGetValue(Path, Result) then
        Result := nil;
end;

procedure TSBMRouteRegistry.RegisterRoute(const Path: String; Handler: TSBMRouteHandler);
begin
    FRoutes.AddOrSetValue(Path, Handler);
end;

end.
