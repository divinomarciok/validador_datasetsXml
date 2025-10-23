object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Validador NFe DataSets'
  ClientHeight = 500
  ClientWidth = 700
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object MemoInput: TMemo
    Left = 8
    Top = 8
    Width = 681
    Height = 200
    Anchors = [akLeft, akTop, akRight]
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object ButtonCheck: TButton
    Left = 8
    Top = 214
    Width = 681
    Height = 25
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Verificar Duplicatas'
    TabOrder = 1
    OnClick = ButtonCheckClick
  end
  object MemoOutput: TMemo
    Left = 8
    Top = 245
    Width = 681
    Height = 247
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 2
  end
end