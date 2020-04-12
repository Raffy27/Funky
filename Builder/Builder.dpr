program Builder;

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils;

type
  PByte = ^Byte;

type
  TFuncInRecord = Record
    GetProcAddress: function(hModule: Cardinal; lpProcName: PAnsiChar)
      : Pointer; stdcall;
    LoadLibrary: function(lpLibFileName: PAnsiChar): Cardinal; stdcall;
    Str: TArray<PAnsiChar>;
  end;

  PFuncInRecord = ^TFuncInRecord;

  TFuncIn = procedure(Data: PFuncInRecord);
  PFuncIn = ^TFuncIn;

  TBuilder = class
  private
    FProc: Pointer;
    FSize: Cardinal;
    FStr: TArray<String>;
    function Save: TMemoryStream;
    function SizeOfProc(Proc: Pointer): Cardinal;
  public
    constructor Create(Proc: Pointer; Str: TArray<String>);
    procedure SaveToFile(FileName: String);
  end;

function TBuilder.SizeOfProc(Proc: Pointer): Cardinal;
begin
  Result := 0;
  Repeat
    Inc(Result);
  Until PByte(Cardinal(Proc) + Result - 1)^ = $C3;
end;

constructor TBuilder.Create(Proc: Pointer; Str: TArray<String>);
begin
  FProc := Proc;
  FSize := SizeOfProc(FProc);
  FStr := Str;
{$IFDEF DEBUG}
  Writeln('TBuilder initialization');
  Writeln(#9, Format('Proc = %p', [FProc]));
  Writeln(#9, Format('Size = %d', [FSize]));
  Writeln(#9, Format('StrCount = %d', [Length(FStr)]));
{$ENDIF}
end;

function TBuilder.Save;
var
  M: TMemoryStream;
  S: String;
  Magic: PAnsiChar;
  Len: Cardinal;

  procedure WriteString(S: String);
  var
    U: UTF8String;
    L: Cardinal;
  Begin
    U := UTF8String(S);
    L := Length(U);
    M.Write(L, SizeOf(L));
    M.Write(PAnsiChar(U)^, L);
  End;

begin
  Magic := 'F00D';
  M := TMemoryStream.Create;

  M.Write(Magic^, SizeOf(Magic));
  M.Write(FSize, SizeOf(FSize));
  M.Write(FProc^, FSize);
  Len := Length(FStr);
  M.Write(Len, SizeOf(Len));
  for S in FStr do
    WriteString(S);

  Result := M;
end;

procedure TBuilder.SaveToFile(FileName: String);
var
  M: TMemoryStream;
Begin
  M := Save;
  M.SaveToFile(FileName);
  M.Free;
End;

procedure Notepad(Data: PFuncInRecord);
type
  TMessageBoxA = function(hWnd: Cardinal; lpText, lpCaption: PAnsiChar;
    uType: LongWord): LongWord; stdcall;
  TShellExecuteA = function(hWnd: Cardinal; lpOperation, lpFile, lpParameters,
    lpDirectory: PAnsiChar; nShowCmd: Integer): THandle; stdcall;
var
  Msg: TMessageBoxA;
  Exec: TShellExecuteA;
begin
  with Data^ do
  begin
    Msg := GetProcAddress(LoadLibrary(Str[0]), Str[1]);
    Exec := GetProcAddress(LoadLibrary(Str[5]), Str[6]);
    Msg(0, Str[3], Str[2], 0);
    if Msg(0, Str[4], Str[2], 4) = 6 then
      Exec(0, Str[7], Str[8], Str[9], Nil, SW_SHOWNORMAL);
  end;
end;

procedure FileProc(Data: PFuncInRecord);
type
  TCreateFileA = function(lpFileName: PAnsiChar;
    dwDesiredAccess, dwShareMode: DWORD; lpSecurityAttributes: Pointer;
    dwCreationDisposition, dwFlagsAndAttributes: DWORD; hTemplateFile: THandle)
    : THandle; stdcall;
  TWriteFile = function(hFile: THandle; lpBuffer: Pointer;
    nNumberOfBytesToWrite: DWORD; lpNumberOfBytesWritten: Pointer;
    lpOverlapped: Pointer): Bool; stdcall;
  TCloseHandle = function(hWnd: THandle): Bool; stdcall;
var
  F, L: THandle;
  NewFile: TCreateFileA;
  WriteFile: TWriteFile;
  CloseHandle: TCloseHandle;
  Len: DWORD;
Begin
  with Data^ do
  Begin
    L := LoadLibrary(Str[0]);
    NewFile := GetProcAddress(L, Str[1]);
    WriteFile := GetProcAddress(L, Str[2]);
    CloseHandle := GetProcAddress(L, Str[3]);
    F := NewFile(Str[4], GENERIC_WRITE, 0, Nil, CREATE_ALWAYS,
      FILE_ATTRIBUTE_NORMAL, 0);
    Len := 0;
    while Str[5][Len] <> #0 do
      Inc(Len);
    WriteFile(F, Str[5], Len, Nil, Nil);
    CloseHandle(F);
  End;
End;

var
  B: TBuilder;

begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
  try
    Writeln('Creating function "File.bin"');
    B := TBuilder.Create(@FileProc, ['Kernel32', 'CreateFileA', 'WriteFile',
      'CloseHandle', 'Test.txt', 'This is an example of Func-In Technology.']);
    B.SaveToFile('File.bin');
    B.Free;

    Writeln('Creating function "Msg.bin"');
    B := TBuilder.Create(@Notepad, ['User32', 'MessageBoxA', 'Func-In Example',
      'This is an example of Func-In Technology.' + #10 +
      'See the source code for details!',
      'Would you like me to open Notepad for you?', 'Shell32', 'ShellExecuteA',
      'open', 'notepad.exe', 'Test.txt']);
    B.SaveToFile('Msg.bin');
    B.Free;

    Writeln('Done');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
