object frmGoogleAuthenticator: TfrmGoogleAuthenticator
  Left = 0
  Top = 0
  Caption = 'Google Authenticator'
  ClientHeight = 300
  ClientWidth = 844
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object led02: TJvLED
    Left = 705
    Top = 116
    Active = True
  end
  object Label2: TLabel
    Left = 24
    Top = 117
    Width = 675
    Height = 16
    Caption = 
      'Grave a chave gerada no banco de dados ou outros; Grave a inform' +
      'a'#231#227'o do link qrcode no banco de dados ou outros;'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lblqrcode: TLabel
    Left = 40
    Top = 68
    Width = 62
    Height = 13
    Caption = 'Link QrCode:'
  end
  object lblkey: TLabel
    Left = 67
    Top = 95
    Width = 35
    Height = 13
    Caption = 'Chave:'
  end
  object Label1: TLabel
    Left = 167
    Top = 37
    Width = 568
    Height = 16
    Caption = 
      'Para Gerar a Imagem do QrCode Copie o Link e Cole no site: https' +
      '://www.qr-code-generator.com/'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object led01: TJvLED
    Left = 743
    Top = 38
    Active = True
  end
  object btngerarqrcode: TButton
    Left = 40
    Top = 32
    Width = 121
    Height = 25
    Caption = 'Gerar QrCode'
    TabOrder = 0
    OnClick = btngerarqrcodeClick
  end
  object edtkey: TEdit
    Left = 151
    Top = 191
    Width = 121
    Height = 21
    TabOrder = 1
  end
  object btngettoken: TButton
    Left = 24
    Top = 189
    Width = 121
    Height = 25
    Caption = 'Get Token'
    TabOrder = 2
    OnClick = btngettokenClick
  end
  object btnvalida: TButton
    Left = 151
    Top = 220
    Width = 121
    Height = 25
    Caption = 'Validar Token'
    TabOrder = 3
    OnClick = btnvalidaClick
  end
  object edtqrcode: TEdit
    Left = 112
    Top = 63
    Width = 673
    Height = 21
    TabOrder = 4
  end
  object edtkeygerada: TEdit
    Left = 112
    Top = 90
    Width = 161
    Height = 21
    TabOrder = 5
  end
  object GoogleAuthenticator: TGoogleAuthenticator
    AccountName = 'email@email.com.br'
    IssuerName = 'evertonbuenolima'
    Left = 792
    Top = 8
  end
end
