program ValidateNFeDataSets;

{$APPTYPE GUI}

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
