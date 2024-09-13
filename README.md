Primeiro deve ser gerada o link do qrcode

var
  SecretKey, QRCodeURL, Email: string;
begin
  // Gera uma chave secreta
  SecretKey := GenerateSecretKey;
  // Gera a URL de configuração do Authenticator (QRCode)
  QRCodeURL := GenerateQRCodeURL(SecretKey, Email, 'qbtech');
  // Exibe a URL do QR Code
  // ShowMessage(QRCodeURL);
end;

Após você tem que ir no celular no aplicativo do google autenticator e escanear o qrcode.

Para Capturar o Token

Token := GoogleAuthenticator1.GeraToken;

Para Validar o Token Capturado com o informado

  if GoogleAuthenticator1.Validar then
    ShowMessage('Validado')
  else
    ShowMessage('Falha')


    https://www.instagram.com/delphidevmaster/
