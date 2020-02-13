unit mainGUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  LCLType, Spin, processor;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnStart: TButton;
    btnAddFiles: TButton;
    btnFindFFmpeg: TButton;
    ckbDeinterlace: TCheckBox;
    ckbStabilize: TCheckBox;
    ckbProxy: TCheckBox;
    edtFFmpegPath: TEdit;
    lblBitrate: TLabel;
    lbxFiles: TListBox;
    dlgFindFFmpeg: TOpenDialog;
    dlgOpenFiles: TOpenDialog;
    dlgOutputFolder: TSelectDirectoryDialog;
    spnBitrate: TSpinEdit;
    spnShakiness: TSpinEdit;
    procedure btnAddFilesClick(Sender: TObject);
    procedure btnFindFFmpegClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure ckbProxyChange(Sender: TObject);
    procedure ckbStabilizeChange(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure lbxFilesKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.btnStartClick(Sender: TObject);
begin
  //test: any videos selected?
  if lbxFiles.Count = 0 then
    Application.MessageBox('Select at least one video to process!', 'No Videos', MB_ICONERROR)
  else
  //test: ffmpeg selected?
    if not FileExists(edtFFmpegPath.Text) then
      Application.MessageBox('Please select FFmpeg first!', 'Missing FFmpeg', MB_ICONERROR)
  else
    //select output folder
    if dlgOutputFolder.Execute then begin
       //push information to processor
       FFmpegPath:=edtFFmpegPath.Text;
       OutputPath := dlgOutputFolder.FileName;
       Shakiness := spnShakiness.Value;
       Bitrate := spnBitrate.Value;
       Deinterlace := ckbDeinterlace.Checked;
       Stabilize := ckbStabilize.Checked;
       InputFiles := lbxFiles.Items;
       //run, ffmpeg, run!
       Form2.Show;
       if ckbProxy.Checked then begin
         Form2.makeProxy();
       end else begin
         Form2.run();
       end;
    end else
      Application.MessageBox('Please select an output folder!', 'No Output Selected', MB_ICONERROR)
end;

procedure TForm1.ckbProxyChange(Sender: TObject);
begin
  spnShakiness.Enabled:=not ckbProxy.Checked;
  ckbStabilize.Enabled:=not ckbProxy.Checked;
  ckbDeinterlace.Enabled:=not ckbProxy.Checked;
end;

procedure TForm1.ckbStabilizeChange(Sender: TObject);
begin
  spnShakiness.Enabled:=ckbStabilize.Checked;
end;

procedure TForm1.FormDropFiles(Sender: TObject; const FileNames: array of String
  );
begin
  lbxFiles.Items.AddStrings(FileNames);
end;

procedure TForm1.lbxFilesKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i: Integer;
begin
  if Key = VK_DELETE then
    for i := lbxFiles.Count-1 downto 0 do
      if lbxFiles.Selected[i] then
        lbxFiles.Items.Delete(i);
end;

procedure TForm1.btnAddFilesClick(Sender: TObject);
begin
  if dlgOpenFiles.Execute then
    lbxFiles.Items.AddStrings(dlgOpenFiles.Files);
end;

procedure TForm1.btnFindFFmpegClick(Sender: TObject);
begin
  if dlgFindFFmpeg.Execute then
    edtFFmpegPath.Text:=dlgFindFFmpeg.FileName;
end;

end.

