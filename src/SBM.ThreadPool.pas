unit SBM.ThreadPool;

interface

uses
    System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs, SBM.Connection, SBM.Exception;

type
    ISBMThreadPool = interface
        ['{A738988F-399C-4234-8FF9-90FA1AC31A30}']
        function EnqueueConnection(AConnection: TSBMConnection): Boolean;
        function QueueLoad: Integer;
    end;

    TSBMThreadPool = class(TInterfacedObject, ISBMThreadPool)
    private
        FQueue: TQueue<TSBMConnection>;
        FLock: TCriticalSection;
        FThreads: TList<TThread>;
        FMaxQueueSize: Integer;

        function GetQueueLoad: Integer;
    public
        constructor Create(AThreadCount, AMaxQueueSize: Integer);
        destructor Destroy; override;

        function EnqueueConnection(AConnection: TSBMConnection): Boolean;
        function QueueLoad: Integer;

        procedure WorkerExecute;
    end;

implementation

{ TSBMThreadPool }

constructor TSBMThreadPool.Create(AThreadCount, AMaxQueueSize: Integer);
var
    T: TThread;
    Thread: TThread;
begin
    FQueue := TQueue<TSBMConnection>.Create;
    FLock := TCriticalSection.Create;
    FThreads := TList<TThread>.Create;
    FMaxQueueSize := AMaxQueueSize;

    while AThreadCount > 0 do
    begin
        Thread := TThread.CreateAnonymousThread(WorkerExecute);
        Thread.FreeOnTerminate := False;
        FThreads.Add(Thread);
        Dec(AThreadCount);
    end;

    for T in FThreads do
        T.Start;
end;

destructor TSBMThreadPool.Destroy;
var
    T: TThread;
begin
    for T in FThreads do
    begin
        T.Terminate;
        T.WaitFor;
        T.Free;
    end;

    FLock.Free;
    FQueue.Free;
    FThreads.Free;
    inherited;
end;

function TSBMThreadPool.EnqueueConnection(AConnection: TSBMConnection): Boolean;
begin
    FLock.Enter;
    try
        if (FQueue.Count >= FMaxQueueSize) then
            Exit(False);

        FQueue.Enqueue(AConnection);
        Result := True;
    finally
        FLock.Leave;
    end;
end;

function TSBMThreadPool.QueueLoad: Integer;
begin
    Result := GetQueueLoad;
end;

function TSBMThreadPool.GetQueueLoad: Integer;
begin
    FLock.Enter;
    try
        Result := FQueue.Count;
    finally
        FLock.Leave;
    end;
end;

procedure TSBMThreadPool.WorkerExecute;
var
    Conn: TSBMConnection;
begin
    while not TThread.CurrentThread.CheckTerminated do
    begin
        FLock.Enter;
        try
            if FQueue.Count > 0 then
                Conn := FQueue.Dequeue
            else
                Conn := nil;
        finally
            FLock.Leave;
        end;

        if Assigned(Conn) then
        begin
            try
                Conn.ProcessRequest;
            except
                on E: EHttpException do
                    Conn.SendHttpResponse(E.StatusCode, E.StatusMessage, E.StatusBody);

                on E: Exception do
                    Conn.SendHttpResponse(500, E.Message);
            end;
        end;

        TThread.Sleep(10);
    end;
end;

end.
