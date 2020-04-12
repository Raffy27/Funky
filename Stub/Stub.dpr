program Stub;

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.AnsiStrings;

type
  TFuncInRecord = Record
    GetProcAddress: function(hModule: Cardinal; lpProcName: pAnsiChar)
      : Pointer; stdcall;
    LoadLibrary: function(lpLibFileName: pAnsiChar): Cardinal; stdcall;
    Str: TArray<pAnsiChar>;
  end;

  PFuncInRecord = ^TFuncInRecord;

  PFuncIn = ^TFuncIn;
  TFuncIn = procedure(Data: PFuncInRecord);

  TStub = class
  const
    CMagic = 'F00D';
  private
    FProc: TFuncIn;
    FSize: Cardinal;
    FRec: TFuncInRecord;
    procedure LoadFromMemory(M: TMemoryStream);
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFile(FileName: String);
    procedure Run;
  end;

constructor TStub.Create;
begin
  FRec.GetProcAddress := @GetProcAddress;
  FRec.LoadLibrary := @LoadLibraryA;
end;

destructor TStub.Destroy;
var
  I: Cardinal;
begin
  VirtualFree(@FProc, 0, MEM_RELEASE);
  for I := 0 to High(FRec.Str) do
    System.AnsiStrings.StrDispose(FRec.Str[I]);
end;

procedure CopyMemory(Destination, Source: Pointer; dwSize: LongWord);
asm
  PUSH ECX
  PUSH ESI
  PUSH EDI
  MOV EDI, Destination
  MOV ESI, Source
  MOV ECX, dwSize
  REP MOVSB
  POP EDI
  POP ESI
  POP ECX
end;

procedure TStub.LoadFromMemory(M: TMemoryStream);
var
  Magic: Array [1 .. 4] of AnsiChar;
  Len, I: Cardinal;

  function ReadString: pAnsiChar;
  var
    U: UTF8String;
    L: Cardinal;
  Begin
    M.Read(L, SizeOf(L));
    SetLength(U, L);
    M.Read(pAnsiChar(U)^, L);
    Result := pAnsiChar(U);
  End;

begin
  M.Read(Magic[1], SizeOf(Magic));
  Assert(Magic = CMagic);

  M.Read(FSize, SizeOf(FSize));
  FProc := VirtualAlloc(Nil, FSize, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  CopyMemory(@FProc, Pointer(Cardinal(M.Memory) + M.Position), FSize);
  M.Seek(FSize, soCurrent);

  M.Read(Len, SizeOf(Len));
  SetLength(FRec.Str, Len);
  for I := 0 to Len - 1 do
  Begin
    FRec.Str[I] := System.AnsiStrings.StrNew(ReadString);
  End;

{$IFDEF DEBUG}
  Writeln('TStub initialization');
  Writeln(#9, Format('Size = %d', [FSize]));
  Writeln(#9, Format('Proc = %p', [@FProc]));
  Writeln(#9, Format('StrCount = %d', [Len]));
{$ENDIF}
end;

procedure TStub.LoadFromFile(FileName: string);
var
  M: TMemoryStream;
begin
  M := TMemoryStream.Create;
  M.LoadFromFile(FileName);
  M.Position := 0;
  LoadFromMemory(M);
  M.Free;
end;

procedure TStub.Run;
begin
{$IFDEF DEBUG}
  Writeln('Executing.');
{$ENDIF}
  FProc(@FRec);
{$IFDEF DEBUG}
  Writeln('Execution complete.');
{$ENDIF}
end;

var
  S: TStub;

begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
  try
    Writeln('Running function "File.bin"');
    S := TStub.Create;
    try
      S.LoadFromFile('File.bin');
      S.Run;
    finally
      S.Free;
    end;

    Writeln('Running function "Msg.bin"');
    S := TStub.Create;
    try
      S.LoadFromFile('Msg.bin');
      S.Run;
    finally
      S.Free;
    end;

    Writeln('Done');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
