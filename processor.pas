unit processor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, Process, LCLType;

type

  { TForm2 }

  TForm2 = class(TForm)
    memOutput: TMemo;
    procedure run();
    procedure makeProxy();
    procedure readOutput(S: TStringList; M: TMemoryStream);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form2: TForm2;
  FFmpegProcess: TProcess;
  FFmpegPath, OutputPath: String;
  Shakiness, Bitrate: Integer;
  Deinterlace, Stabilize: Boolean;
  InputFiles: TStrings;

implementation

{$R *.lfm}



{ TForm2 }

procedure TForm2.run();
var
  S: TStringList;
  M: TMemoryStream;
  i, Result: Integer;
  AlwaysSkipDeinterlace, AlwaysContinueDeinterlace, AlwaysSkipAnalyze, AlwaysContinueAnalyze, Continue: Boolean;
begin
  AlwaysSkipDeinterlace := false;
  AlwaysContinueDeinterlace := false;
  AlwaysSkipAnalyze := false;
  AlwaysContinueAnalyze := false;

  //deinterlace
  for i := 0 to InputFiles.Count-1 do begin
  if Deinterlace = true then begin

    memOutput.Lines.Add('Deinterlacing ' + InputFiles.Strings[i]);

    // Abort if Overwrite Dialogs are answered to not overwrite
    Continue := true;
    if (Stabilize = true) and AlwaysSkipDeinterlace and FileExists('tmp_'+ExtractFileName(InputFiles.Strings[i])) then Continue:=false;
    if AlwaysContinueDeinterlace then Continue:=true;
    if ((Stabilize = true) and FileExists('tmp_'+ExtractFileName(InputFiles.Strings[i]))) and not (AlwaysSkipDeinterlace or AlwaysContinueDeinterlace) then begin
      Result := MessageDlg('You''ve been here before', 'Found deinterlaced version. Do you want to use it? Otherwise it will be overwritten.', mtConfirmation, [mbYes, mbNo, mbYesToAll, mbNoToAll], 0);
      if (Result = mrYes) or (Result = mrYesToAll) then Continue:=false else Continue:=true;
      if Result = mrYestoAll then AlwaysSkipDeinterlace:=true;
      if Result = mrNotoAll then AlwaysContinueDeinterlace:=true;
    end;



    if Continue then begin
    S := TStringList.Create;
    M := TMemoryStream.Create;
    Sleep(1000);
    //init ffmpeg
    FFmpegProcess := TProcess.Create(nil);
    FFmpegProcess.Executable := FFmpegPath;
    FFmpegProcess.Parameters.Add('-y');
    FFmpegProcess.Parameters.Add('-i');
    FFmpegProcess.Parameters.Add(InputFiles.Strings[i]);
    FFmpegProcess.Parameters.Add('-q:v');
    FFmpegProcess.Parameters.Add('0');
    if Stabilize = false then begin
      FFmpegProcess.Parameters.Add('-b:v');
      FFmpegProcess.Parameters.Add(IntToStr(Bitrate)+'k');
    end;
    FFmpegProcess.Parameters.Add('-vf');
    FFmpegProcess.Parameters.Add('yadif=1');
    FFmpegProcess.Parameters.Add('-acodec');
    FFmpegProcess.Parameters.Add('copy');
    if Stabilize = true then
      FFmpegProcess.Parameters.Add('tmp_'+ExtractFileName(InputFiles.Strings[i]))
        else
          FFmpegProcess.Parameters.Add(OutputPath+'\'+ExtractFileName(InputFiles.Strings[i]));
    FFmpegProcess.Options := [poUsePipes,poStderrToOutPut];
    FFmpegProcess.ShowWindow := swoHIDE;
    FFmpegProcess.Execute;

    //show log
    while FFmpegProcess.Running do
    begin
      readOutput(S,M);
    end;
    //read last output part
    readOutput(S,M);


    S.Free;
    FFmpegProcess.Free;
    M.Free;

    end else memOutput.Lines.Add('Skipped.');

  end;
  //stabilize(analyze)
  if Stabilize = true then begin
    memOutput.Lines.Add('Analysing ' + InputFiles.Strings[i]);

    // Abort if Overwrite Dialogs are answered to not overwrite
    Continue := true;
    if (Stabilize = true) and AlwaysSkipAnalyze and FileExists(ExtractFileName(InputFiles.Strings[i])+'_transform_vectors.trf') then Continue:=false;
    if AlwaysContinueAnalyze then Continue:=true;
    if ((Stabilize = true) and FileExists(ExtractFileName(InputFiles.Strings[i])+'_transform_vectors.trf')) and not (AlwaysSkipAnalyze or AlwaysContinueAnalyze) then begin
      Result := MessageDlg('You''ve been here before', 'Found analysing data. Do you want to use it? Otherwise it will be overwritten.', mtConfirmation, [mbYes, mbNo, mbYesToAll, mbNoToAll], 0);
      if (Result = mrYes) or (Result = mrYesToAll) then Continue:=false else Continue:=true;
      if Result = mrYestoAll then AlwaysSkipAnalyze:=true;
      if Result = mrNotoAll then AlwaysContinueAnalyze:=true;
    end;

    if Continue then begin
    S := TStringList.Create;
    M := TMemoryStream.Create;
    Sleep(1000);
    //init ffmpeg
    FFmpegProcess := TProcess.Create(nil);
    FFmpegProcess.Executable := FFmpegPath;
    FFmpegProcess.Parameters.Add('-y');
    FFmpegProcess.Parameters.Add('-i');
    if Deinterlace = true then
      FFmpegProcess.Parameters.Add('tmp_'+ExtractFileName(InputFiles.Strings[i]))
        else
          FFmpegProcess.Parameters.Add(InputFiles.Strings[i]);
    FFmpegProcess.Parameters.Add('-vf');
    FFmpegProcess.Parameters.Add('vidstabdetect=stepsize=6:shakiness='+IntToStr(Shakiness)+':accuracy=9:result='+ExtractFileName(InputFiles.Strings[i])+'_transform_vectors.trf');
    FFmpegProcess.Parameters.Add('-f');
    FFmpegProcess.Parameters.Add('null');
    FFmpegProcess.Parameters.Add('-');
    FFmpegProcess.Options := [poUsePipes,poStderrToOutPut];
    FFmpegProcess.ShowWindow := swoHIDE;
    FFmpegProcess.Execute;

    //show log
    while FFmpegProcess.Running do
    begin
      readOutput(S,M);
    end;
    //read last output part
    readOutput(S,M);


    S.Free;
    FFmpegProcess.Free;
    M.Free;

    end else memOutput.Lines.Add('Skipped.');

    //stabilize(render)

    memOutput.Lines.Add('Stabilising ' + InputFiles.Strings[i]);

    Continue := true;

    if Continue then begin
    S := TStringList.Create;
    M := TMemoryStream.Create;
    Sleep(1000);
    //init ffmpeg
    FFmpegProcess := TProcess.Create(nil);
    FFmpegProcess.Executable := FFmpegPath;
    FFmpegProcess.Parameters.Add('-y');
    FFmpegProcess.Parameters.Add('-i');
    if Deinterlace = true then
      FFmpegProcess.Parameters.Add('tmp_'+ExtractFileName(InputFiles.Strings[i]))
        else
          FFmpegProcess.Parameters.Add(InputFiles.Strings[i]);
    FFmpegProcess.Parameters.Add('-q:v');
    FFmpegProcess.Parameters.Add('0');   
    FFmpegProcess.Parameters.Add('-b:v');
    FFmpegProcess.Parameters.Add(IntToStr(Bitrate)+'k');
    FFmpegProcess.Parameters.Add('-vf');
    FFmpegProcess.Parameters.Add('vidstabtransform=input='+ExtractFileName(InputFiles.Strings[i])+'_transform_vectors.trf:zoom=1:smoothing=30,unsharp=5:5:0.8:3:3:0.4');
    FFmpegProcess.Parameters.Add('-acodec');
    FFmpegProcess.Parameters.Add('copy');
    FFmpegProcess.Parameters.Add(OutputPath+'\'+ExtractFileName(InputFiles.Strings[i]));
    FFmpegProcess.Options := [poUsePipes,poStderrToOutPut];
    FFmpegProcess.ShowWindow := swoHIDE;
    FFmpegProcess.Execute;

    //show log
    while FFmpegProcess.Running do
    begin
      readOutput(S,M);
    end;
    //read last output part
    readOutput(S,M);


    S.Free;
    FFmpegProcess.Free;
    M.Free;
  end else memOutput.Lines.Add('Skipped.');



  //stabilize(cleanup)
  memOutput.Lines.Add('Cleanup');
  if Stabilize = true then DeleteFile(ExtractFileName(InputFiles.Strings[i])+'_transform_vectors.trf');
  if Deinterlace and Stabilize then DeleteFile('tmp_'+ExtractFileName(InputFiles.Strings[i]));


  memOutput.Lines.Add(IntToStr(i+1)+'/'+IntToStr(InputFiles.Count)+' Done!');
  end;
  end;
end;


procedure TForm2.makeProxy();
var
  S: TStringList;
  M: TMemoryStream;
  i: Integer;
  Continue: Boolean;
begin

  //deinterlace
  for i := 0 to InputFiles.Count-1 do begin

    memOutput.Lines.Add('Proxying ' + InputFiles.Strings[i]);

    // Abort if Overwrite Dialogs are answered to not overwrite
    Continue := true;

    if Continue then begin
    S := TStringList.Create;
    M := TMemoryStream.Create;
    Sleep(1000);
    //init ffmpeg
    FFmpegProcess := TProcess.Create(nil);
    FFmpegProcess.Executable := FFmpegPath;
    FFmpegProcess.Parameters.Add('-y');
    FFmpegProcess.Parameters.Add('-i');
    FFmpegProcess.Parameters.Add(InputFiles.Strings[i]);
    FFmpegProcess.Parameters.Add('-q:v');
    FFmpegProcess.Parameters.Add('15');
    FFmpegProcess.Parameters.Add('-vf');
    FFmpegProcess.Parameters.Add('scale=iw/4:ih/4');
    FFmpegProcess.Parameters.Add('-acodec');
    FFmpegProcess.Parameters.Add('copy');
    FFmpegProcess.Parameters.Add(OutputPath+'\'+ExtractFileName(InputFiles.Strings[i]));
    FFmpegProcess.Options := [poUsePipes,poStderrToOutPut];
    FFmpegProcess.ShowWindow := swoHIDE;
    FFmpegProcess.Execute;

    //show log
    while FFmpegProcess.Running do
    begin
      readOutput(S,M);
    end;
    //read last output part
    readOutput(S,M);


    S.Free;
    FFmpegProcess.Free;
    M.Free;

    end else memOutput.Lines.Add('Skipped.');

    memOutput.Lines.Add(IntToStr(i+1)+'/'+IntToStr(InputFiles.Count)+' Done!');
  end;
end;

procedure TForm2.readOutput(S: TStringList; M: TMemoryStream);
var
  n: LongInt = 0;
  BytesRead: LongInt = 0;
  READ_BYTES: LongInt = 0;
begin
  READ_BYTES := FFmpegProcess.Output.NumBytesAvailable;
  if READ_BYTES > 0
  then begin
  //reserve memory
  M.SetSize(BytesRead + READ_BYTES);
  //read output
  n := FFmpegProcess.Output.Read((M.Memory + BytesRead)^, READ_BYTES);
  if n > 0
  then
    Inc(BytesRead, n);
  end else begin
    Sleep(100);
  end;
  //print to log
  M.SetSize(BytesRead);
  S.LoadFromStream(M);
  M.Clear;
  BytesRead := 0;
  memOutput.Lines.AddText(S.Text);
  memOutput.Update;
  memOutput.SelStart:=Length(memOutput.Text);
  Application.ProcessMessages;
end;

end.

