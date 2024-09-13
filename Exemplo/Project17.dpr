program Project17;

uses
  Vcl.Forms,
  uGoogleAuthenticator in 'uGoogleAuthenticator.pas' {frmGoogleAuthenticator},
  GoogleOTP in 'Google\GoogleOTP.pas',
  Base32U in 'Base32U.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmGoogleAuthenticator, frmGoogleAuthenticator);
  Application.Run;
end.
