unit uGoogleAuthenticcatorComponent;

interface

uses
  System.Classes, IdGlobal, IdHMACSHA1, System.SysUtils, Vcl.ExtCtrls,
  GoogleOTP, Base32U;

const
  Base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567=';

type
  TGoogleAuthenticator = class(TComponent)
  private
    FAccountName: string;
    FIssuerName: String;
    FOTPSECRET: string;
    FQRCodeURL: string;
    function ToIdBytes(const AInput: TArray<System.Byte>): TIdBytes;
    function Base32Decode(const Encoded: string): TIdBytes;
    function GenerateTOTP(SecretKey: string; TimeStepSeconds: Integer = 30;
      Digits: Integer = 6): string;
    procedure SetAccountName(const Value: string);
    procedure SetQRCodeURL(const Value: string);
    procedure SetOTPSECRET(const Value: string);
    procedure SetIssuerName(const Value: String);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    function GenerateSecretKey(Length: Integer = 16): string;
    function GenerateQRCodeURL: string;
    function GeraToken: String;
    function Validar: Boolean;

    property AccountName: string read FAccountName write SetAccountName;
    property OTPSECRET: string read FOTPSECRET write SetOTPSECRET;
    property QRCodeURL: string read FQRCodeURL write SetQRCodeURL;
    property IssuerName: String read FIssuerName write SetIssuerName;
  end;

procedure Register;

implementation

uses DateUtils, Math;

procedure Register;
begin
  RegisterComponents('Everton', [TGoogleAuthenticator]);
end;

function TGoogleAuthenticator.GenerateSecretKey(Length: Integer = 16): string;
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

constructor TGoogleAuthenticator.Create(AOwner: TComponent);
begin
  inherited;

end;

destructor TGoogleAuthenticator.Destroy;
begin

  inherited;
end;

function TGoogleAuthenticator.GenerateQRCodeURL: string;
begin
  Result := Format('otpauth://totp/%s?secret=%s&issuer=%s',
    [AccountName, OTPSECRET, IssuerName]);
  QRCodeURL := Result;
end;

function TGoogleAuthenticator.ToIdBytes(const AInput: TArray<System.Byte>)
  : TIdBytes;
var
  I: Integer;
begin
  SetLength(Result, Length(AInput));
  for I := 0 to High(AInput) do
    Result[I] := AInput[I];
end;

function TGoogleAuthenticator.Base32Decode(const Encoded: string): TIdBytes;
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
      Continue;
    // Ignorar caracteres inválidos (como '=')
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

function TGoogleAuthenticator.GenerateTOTP(SecretKey: string;
  TimeStepSeconds: Integer = 30; Digits: Integer = 6): string;
var
  UnixTime, TimeCounter: Int64;
  TimeBytes, Hash, KeyBytes: TIdBytes;
  Offset, BinaryCode: Integer;
  TruncatedHash: Int64;
  HMACSHA1: TIdHMACSHA1;
begin
  // Decodificar a chave secreta Base32 para bytes
  KeyBytes := Base32Decode(SecretKey);
  // Obtém o tempo Unix (segundos desde 01/01/1970) e divide pelo intervalo de tempo
  UnixTime := DateTimeToUnix(Now);
  TimeCounter := UnixTime div TimeStepSeconds;
  // Converter TimeCounter para bytes (big-endian)
  SetLength(TimeBytes, 8);
  for Offset := 7 downto 0 do
  begin
    TimeBytes[7 - Offset] := TimeCounter and $FF;
    TimeCounter := TimeCounter shr 8;
  end;
  // Calcular o HMAC-SHA1 da chave e do contador de tempo
  HMACSHA1 := TIdHMACSHA1.Create;
  try
    HMACSHA1.Key := KeyBytes;
    Hash := HMACSHA1.HashValue(TimeBytes); // Hash será do tipo TIdBytes
  finally
    HMACSHA1.Free;
  end;
  // Extrair os últimos 4 bits do último byte do hash como o offset
  Offset := Hash[High(Hash)] and $0F;
  // Extrair o valor de 4 bytes do hash com o offset
  BinaryCode := ((Hash[Offset] and $7F) shl 24) or
    ((Hash[Offset + 1] and $FF) shl 16) or ((Hash[Offset + 2] and $FF) shl 8) or
    (Hash[Offset + 3] and $FF);
  // Truncar para o número de dígitos solicitados
  TruncatedHash := BinaryCode mod Trunc(Power(10, Digits));
  // Retornar o token formatado com zeros à esquerda, se necessário
  Result := Format('%.*d', [Digits, TruncatedHash]);
end;

function TGoogleAuthenticator.GeraToken: String;
var
  vToken: Integer;
begin
  if OTPSECRET.IsEmpty then
    raise Exception.Create('Key não informada!');

  vToken := CalculateOTP(OTPSECRET);

  Result := copy(Format('%.6d', [vToken]), 1, 3) + ' ' +
    copy(Format('%.6d', [vToken]), 4, 6);
end;

procedure TGoogleAuthenticator.SetAccountName(const Value: string);
begin
  FAccountName := Value;
end;

procedure TGoogleAuthenticator.SetIssuerName(const Value: String);
begin
  FIssuerName := Value;
end;

procedure TGoogleAuthenticator.SetQRCodeURL(const Value: string);
begin
  FQRCodeURL := Value;
end;

procedure TGoogleAuthenticator.SetOTPSECRET(const Value: string);
begin
  FOTPSECRET := Value;
end;

function TGoogleAuthenticator.Validar: Boolean;
var
  Codigo: Integer;
begin
  Result := False;
  Codigo := CalculateOTP(OTPSECRET);

  if ValidateTOTP(OTPSECRET, Codigo) then
    Result := True;
end;

end.
