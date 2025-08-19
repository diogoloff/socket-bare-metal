unit unMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, SBM.Listener;

type
  TfrmMain = class(TForm)
    btnIniciarServer: TButton;
    procedure btnIniciarServerClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.btnIniciarServerClick(Sender: TObject);
var
    Listener : TSBMListener;
begin
    Listener := TSBMListener.Create(8080);
    Listener.Start;
    ShowMessage('Servidor iniciado na porta 8080');

    Listener.Free;
end;

end.
