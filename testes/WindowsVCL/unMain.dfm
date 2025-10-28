object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Server Teste'
  ClientHeight = 299
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object btnIniciarServer: TButton
    Left = 40
    Top = 24
    Width = 113
    Height = 25
    Caption = 'Iniciar Server'
    TabOrder = 0
    OnClick = btnIniciarServerClick
  end
  object btnPararServer: TButton
    Left = 40
    Top = 64
    Width = 113
    Height = 25
    Caption = 'Parar Server'
    TabOrder = 1
    OnClick = btnPararServerClick
  end
end
