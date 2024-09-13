unit uGoogleAuthenticator;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdGlobal, IdHMACSHA1,
  IdSSLOpenSSL, DateUtils, Math, GoogleOTP, uGoogleAuthenticcatorComponent,
  frxClass, frxPreview, Vcl.ExtCtrls, dxGDIPlusClasses, JvExControls, JvLED;

const
  Base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567=';

type
  TfrmGoogleAuthenticator = class(TForm)
    btngerarqrcode: TButton;
    GoogleAuthenticator: TGoogleAuthenticator;
    edtkey: TEdit;
    btngettoken: TButton;
    btnvalida: TButton;
    edtqrcode: TEdit;
    edtkeygerada: TEdit;
    led02: TJvLED;
    Label2: TLabel;
    lblqrcode: TLabel;
    lblkey: TLabel;
    Label1: TLabel;
    led01: TJvLED;
    procedure btngerarqrcodeClick(Sender: TObject);
    procedure btngettokenClick(Sender: TObject);
    procedure btnvalidaClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmGoogleAuthenticator: TfrmGoogleAuthenticator;

implementation

{$R *.dfm}

function ExtrairSecret(const qrCode: string): string;
var
  secretStart, secretEnd: Integer;
begin
  // Procurar a posição onde começa o secret=
  secretStart := Pos('secret=', qrCode);

  if secretStart = 0 then
    Exit(''); // Se não encontrar 'secret=', retorna uma string vazia

  // Avançar para depois do 'secret=' (7 caracteres)
  secretStart := secretStart + Length('secret=');

  // Procurar o '&' depois do secret
  secretEnd := Pos('&', qrCode, secretStart);

  if secretEnd = 0 then
    Exit(''); // Se não encontrar o '&', retorna uma string vazia

  // Copiar a parte entre 'secret=' e '&'
  Result := Copy(qrCode, secretStart, secretEnd - secretStart);
end;

function GenerateSecretKey(Length: Integer = 16): string;
const
  Base32Chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
var
  I: Integer;
begin
  Randomize;
  Result := '';
  for I := 1 to Length do
    Result := Result + Base32Chars[Random(32) + 1];
end;

function GenerateQRCodeURL(SecretKey, AccountName, IssuerName: string): string;
begin
  Result := Format('otpauth://totp/%s?secret=%s&issuer=%s',
    [AccountName, SecretKey, IssuerName]);
end;

function ToIdBytes(const AInput: TArray<System.Byte>): TIdBytes;
var
  I: Integer;
begin
  SetLength(Result, Length(AInput));
  for I := 0 to High(AInput) do
    Result[I] := AInput[I];
end;

function Base32Decode(const Encoded: string): TIdBytes;
var
  I, J, Bits: Integer;
  Decoded: TIdBytes;
  Value: Byte;
  TempBuffer: Integer;
begin
  TempBuffer := 0;
  Bits := 0;
  SetLength(Decoded, (Length(Encoded) * 5) div 8);
  J := 0;
  for I := 1 to Length(Encoded) do
  begin
    Value := Pos(Encoded[I], Base32Chars) - 1;
    if Value < 0 then
      Continue; // Ignorar caracteres inválidos (como '=')
    TempBuffer := (TempBuffer shl 5) or Value;
    Bits := Bits + 5;
    if Bits >= 8 then
    begin
      Bits := Bits - 8;
      Decoded[J] := (TempBuffer shr Bits) and $FF;
      Inc(J);
    end;
  end;
  SetLength(Decoded, J);
  Result := Decoded;
end;

function GenerateTOTP(SecretKey: string; TimeStepSeconds: Integer = 30;
  Digits: Integer = 6): string;
var
  UnixTime, TimeCounter: Int64;
  TimeBytes, Hash, KeyBytes: TIdBytes;
  Offset, BinaryCode: Integer;
  TruncatedHash: Int64;
  HMACSHA1: TIdHMACSHA1;
begin
  KeyBytes := Base32Decode(SecretKey);
  UnixTime := DateTimeToUnix(Now);
  TimeCounter := UnixTime div TimeStepSeconds;
  SetLength(TimeBytes, 8);
  for Offset := 7 downto 0 do
  begin
    TimeBytes[7 - Offset] := TimeCounter and $FF;
    TimeCounter := TimeCounter shr 8;
  end;
  HMACSHA1 := TIdHMACSHA1.Create;
  try
    HMACSHA1.Key := KeyBytes;
    Hash := HMACSHA1.HashValue(TimeBytes);
  finally
    HMACSHA1.Free;
  end;
  Offset := Hash[High(Hash)] and $0F;
  BinaryCode := ((Hash[Offset] and $7F) shl 24) or
    ((Hash[Offset + 1] and $FF) shl 16) or ((Hash[Offset + 2] and $FF) shl 8) or
    (Hash[Offset + 3] and $FF);
  TruncatedHash := BinaryCode mod Trunc(Power(10, Digits));
  Result := Format('%.*d', [Digits, TruncatedHash]);
end;

procedure TfrmGoogleAuthenticator.btnvalidaClick(Sender: TObject);
begin
  GoogleAuthenticator.Key := edtkey.Text;

  if GoogleAuthenticator.Validar then
    ShowMessage('Validado')
  else
    ShowMessage('Falha');
end;

procedure TfrmGoogleAuthenticator.btngettokenClick(Sender: TObject);
begin
  edtkey.Text := GoogleAuthenticator.GeraToken;
end;

procedure TfrmGoogleAuthenticator.btngerarqrcodeClick(Sender: TObject);
var
  SecretKey, QRCodeURL: string;
begin
  SecretKey := GenerateSecretKey;
  QRCodeURL := GenerateQRCodeURL(SecretKey, GoogleAuthenticator.AccountName, GoogleAuthenticator.IssuerName);
  edtqrcode.Text := QRCodeURL;

  GoogleAuthenticator.QRCodeURL := QRCodeURL;
  GoogleAuthenticator.OTPSECRET := ExtrairSecret(edtqrcode.Text);
  edtkeygerada.Text := GoogleAuthenticator.OTPSECRET;
end;

function ValidateTOTP(UserToken: string; SecretKey: string): Boolean;
begin
  Result := GenerateTOTP(SecretKey) = UserToken;
end;

end.
