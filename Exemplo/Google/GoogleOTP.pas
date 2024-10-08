unit GoogleOTP;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Math, Base32U, DateUtils
  {$IFNDEF FPC}
    , IdGlobal, IdHMACSHA1
  {$ELSE}
    , HMAC
  {$IFEND};

function CalculateOTP(const Secret: String; const Counter: Integer = -1): Integer;
function ValidateTOTP(const Secret: String; const Token: Integer; const WindowSize: Integer = 4): Boolean;
function GenerateOTPSecret(len: Integer = -1): String;

implementation

type
  {$IFNDEF FPC}
  OTPBytes = TIdBytes;
  {$ELSE}
  OTPBytes = TBytes;
  {$IFEND}

const
  otpLength = 6;
  keyRegeneration = 30; // 30 segundos, padr�o TOTP
  SecretLengthDef = 20;

{$IFDEF FPC}
function BytesToStringRaw(const InValue: TBytes): RawByteString;
begin
  SetString(Result, PAnsiChar(Pointer(InValue)), Length(InValue));
end;

function RawByteStringToBytes(const InValue: RawByteString): TBytes;
begin
  Result := [];
  SetLength(Result, Length(InValue));
  Move(InValue[1], Result[0], Length(InValue));
end;

function ToBytes(const InValue: Int64): TBytes;
begin
  Result := [];
  SetLength(Result, SizeOf(Int64));
  Move(InValue, Result[0], SizeOf(Int64));
end;
{$ENDIF}

/// <summary>
///   Gera um HMAC-SHA1 do buffer com a chave fornecida
/// </summary>
function HMACSHA1(const _Key: OTPBytes; const Buffer: OTPBytes): OTPBytes;
begin
  {$IFNDEF FPC}
  with TIdHMACSHA1.Create do
  begin
    Key := _Key;
    Result := HashValue(Buffer);
    Free;
  end;
  {$ELSE}
    Result := HMAC.HMACSHA1Digest(BytesToStringRaw(_Key), BytesToStringRaw(Buffer));
  {$IFEND}
end;

/// <summary>
///   Reverte TIdBytes (de baixo->alto para alto->baixo)
/// </summary>
function ReverseIdBytes(const inBytes: OTPBytes): OTPBytes;
var
  i: Integer;
begin
  SetLength(Result, Length(inBytes));
  for i := Low(inBytes) to High(inBytes) do
    Result[High(inBytes) - i] := inBytes[i];
end;

/// <summary>
///   Converte uma string para TIdBytes
/// </summary>
function StrToIdBytes(const inString: String): OTPBytes;
var
  ch: Char;
  i: Integer;
begin
  SetLength(Result, Length(inString));

  i := 0;
  for ch in inString do
  begin
    Result[i] := Ord(ch);
    Inc(i);
  end;
end;

/// <summary>
///   Calcula a senha OTP (One-Time Password) com base no segredo e no contador
/// </summary>
function CalculateOTP(const Secret: String; const Counter: Integer = -1): Integer;
var
  BinSecret: String;
  Hash: OTPBytes;
  Offset: Integer;
  Part1, Part2, Part3, Part4: Integer;
  Key: Integer;
  Time: Int64;
begin
  // Calcula o tempo atual se o contador n�o for fornecido
  if Counter <> -1 then
    Time := Counter
  else
    Time := DateTimeToUnix(Now, False) div keyRegeneration;

  // Decodifica o segredo Base32 para bytes
  BinSecret := Base32.Decode(Secret);
  // Gera o HMAC-SHA1 com o segredo e o contador
  Hash := HMACSHA1(StrToIdBytes(BinSecret), ReverseIdBytes(ToBytes(Int64(Time))));

  // Obt�m o valor din�mico do hash
  Offset := Hash[High(Hash)] and $0F;

  Part1 := (Hash[Offset] and $7F);
  Part2 := (Hash[Offset + 1] and $FF);
  Part3 := (Hash[Offset + 2] and $FF);
  Part4 := (Hash[Offset + 3] and $FF);

  Key := (Part1 shl 24) or (Part2 shl 16) or (Part3 shl 8) or (Part4);
  Result := Key mod Trunc(IntPower(10, otpLength)); // Trunca para o comprimento OTP
end;

/// <summary>
///   Valida o token TOTP fornecido
/// </summary>
function ValidateTOTP(const Secret: String; const Token: Integer; const WindowSize: Integer = 4): Boolean;
var
  TimeStamp: Int64;
  TestValue: Integer;
begin
  Result := False;

  TimeStamp := DateTimeToUnix(Now, False) div keyRegeneration;
  for TestValue := TimeStamp - WindowSize to TimeStamp + WindowSize do
  begin
    if CalculateOTP(Secret, TestValue) = Token then
      Exit(True);
  end;
end;

/// <summary>
///   Gera um novo segredo OTP aleat�rio no formato Base32
/// </summary>
function GenerateOTPSecret(len: Integer = -1): String;
var
  i: Integer;
  ValCharLen: Integer;
begin
  Result := '';
  ValCharLen := Length(Base32U.ValidChars);

  if len < 1 then
    len := SecretLengthDef;

  for i := 1 to len do
    Result := Result + Copy(Base32U.ValidChars, Random(ValCharLen) + 1, 1);
end;

end.

