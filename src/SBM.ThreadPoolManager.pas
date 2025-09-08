unit SBM.ThreadPoolManager;

interface

uses
    System.SysUtils, System.Classes, System.Generics.Collections, System.DateUtils, System.SyncObjs, SBM.Connection, SBM.ThreadPool;

type
    TPoolInfo = class
    public
        Pool: ISBMThreadPool;
        LastActive: TDateTime;
    end;

    TSBMThreadPoolManager = class
    private
        FAutoPools: TObjectList<TPoolInfo>;
        FMaxQueueSize: Integer;
        FDefaultThreadCount: Integer;
        FScaleThreshold: Integer;
        FMonitorThread: TThread;
        FMonitorStopEvent: TEvent;
        procedure ScalePoolsIfNeeded;
        function GetLeastLoadedPool: TPoolInfo;
        function CreateNewPool: TPoolInfo;
        procedure DescalePoolsIfNeeded;
    procedure StartMonitorThread;
    public
        constructor Create(AMaxQueueSize: Integer = 10; ADefaultThreadCount: Integer = 4; AScaleThreshold: Integer = 10);
        destructor Destroy; override;
        function AddConnection(AConnection: TSBMConnection): Boolean;
    end;

implementation

{ TSBMThreadPoolManager }

constructor TSBMThreadPoolManager.Create(AMaxQueueSize: Integer; ADefaultThreadCount: Integer; AScaleThreshold: Integer);
begin
    FAutoPools := TObjectList<TPoolInfo>.Create;
    FMaxQueueSize := AMaxQueueSize;
    FDefaultThreadCount := ADefaultThreadCount;
    FScaleThreshold := AScaleThreshold;
    StartMonitorThread;
end;

destructor TSBMThreadPoolManager.Destroy;
begin
    if Assigned(FMonitorStopEvent) then
        FMonitorStopEvent.SetEvent;

    if Assigned(FMonitorThread) then
    begin
        FMonitorThread.WaitFor;
        FMonitorThread.Free;
    end;

    FMonitorStopEvent.Free;
    FAutoPools.Clear;
    FAutoPools.Free;

    inherited;
end;

function TSBMThreadPoolManager.CreateNewPool: TPoolInfo;
var
    Info: TPoolInfo;
begin
    Info := TPoolInfo.Create;
    Info.Pool := TSBMThreadPool.Create(FDefaultThreadCount, FMaxQueueSize);
    Info.LastActive := Now;
    FAutoPools.Add(Info);
    Result := Info;
end;

function TSBMThreadPoolManager.AddConnection(AConnection: TSBMConnection): Boolean;
var
    Info: TPoolInfo;
begin
    try
        Info := GetLeastLoadedPool;
        if not Assigned(Info) then
            Info := CreateNewPool;

        Info.LastActive := Now;
        Result := Info.Pool.EnqueueConnection(AConnection);

        if not Result then
            AConnection.SendHttpResponse(503, 'Service Unavailable');

        ScalePoolsIfNeeded;
    except
        on E: Exception do
        begin
            AConnection.SendHttpResponse(500, 'Internal Server Error');
            Result := False;
        end;
    end;
end;

function TSBMThreadPoolManager.GetLeastLoadedPool: TPoolInfo;
var
    Info: TPoolInfo;
    MinLoad, Load: Integer;
    I: Integer;
begin
    Result := nil;
    MinLoad := MaxInt;
    for I := 0 to FAutoPools.Count - 1 do
    begin
        Info := FAutoPools[i];
        Load := Info.Pool.QueueLoad;
        if Load < MinLoad then
        begin
            MinLoad := Load;
            Result := Info;
        end;
    end;
end;

procedure TSBMThreadPoolManager.ScalePoolsIfNeeded;
var
    Pool: ISBMThreadPool;
begin
    Pool := GetLeastLoadedPool.Pool;

    if Assigned(Pool) and (Pool.QueueLoad > FScaleThreshold) then
        CreateNewPool;
end;

procedure TSBMThreadPoolManager.DescalePoolsIfNeeded;
var
    I: Integer;
    PoolInfo: TPoolInfo;
begin
    for I := FAutoPools.Count - 1 downto 0 do
    begin
        PoolInfo := FAutoPools[I];
        if (PoolInfo.Pool.QueueLoad = 0) and
           (MinutesBetween(Now, PoolInfo.LastActive) > 5) then
        begin
            FAutoPools.Delete(I); // O pool será liberado automaticamente se não houver referências
        end;
    end;
end;

procedure TSBMThreadPoolManager.StartMonitorThread;
begin
    FMonitorStopEvent := TEvent.Create(nil, True, False, '');

    FMonitorThread := TThread.CreateAnonymousThread(
    procedure
    begin
        while FMonitorStopEvent.WaitFor(30000) = wrTimeout do
        begin
            DescalePoolsIfNeeded;
        end;
    end
    );
    FMonitorThread.FreeOnTerminate := False;
    FMonitorThread.Start;
end;

end.
