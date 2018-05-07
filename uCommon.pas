unit uCommon;

interface
uses Windows, Graphics;


const
  cFmt = '%3d ($%.2x)';


type
  tTemplate = record
    Name: string[20];
    BPP,
    tW,
    tH: byte;
  end;
  pTemplate = ^tTemplate;

const
  // Tile Format constants
  cTmplNum = 10;
  cTemplate: array[0 .. cTmplNum] of tTemplate = (
    (Name: '';               BPP: 1; tW:1; tH:1),
    (Name: '4bpp (GBA)';     BPP: 4; tW:8; tH:8),
    (Name: '4bpp (SNES)';    BPP: 4; tW:8; tH:8),
    (Name: '3bpp (SNES)';    BPP: 3; tW:8; tH:8),
    (Name: '2bpp (SNES)';    BPP: 2; tW:8; tH:8),
    (Name: '1bpp';           BPP: 1; tW:8; tH:8),
    (Name: '8bpp (Mode7-1)'; BPP: 8; tW:8; tH:8),
    (Name: '8bpp (Mode7-2)'; BPP: 8; tW:8; tH:8),
    (Name: '8bpp (Mode3)';   BPP: 8; tW:8; tH:8),
    (Name: '8bpp (PC)';      BPP: 8; tW:1; tH:1),
    (Name: '4bpp (SNES-FX)'; BPP: 4; tW:1; tH:1)
  );


type
  tCompression = record
    Name: string[20];
    CmpType: byte;
  end;

const
  // compression type constants
  ctNone     = 0;
  ctLZ77_10  = 1;  // GBA BIOS compression
  ctLZSS_FF5 = 2;  // SNES Final Fantasy V
  ctLZSS_FF6 = 3;  // SNES Final Fantasy VI
  ctLZSS_CT  = 4;  // SNES Chrono trigger

  cCmpNum = 4;
  cCompression: array[0 .. cCmpNum] of tCompression = (
    (Name: '(none)';   CmpType: ctNone),
    (Name: 'LZ77-10';  CmpType: ctLZ77_10),
    (Name: 'LZSS-FF5'; CmpType: ctLZSS_FF5),
    (Name: 'LZSS-FF6'; CmpType: ctLZSS_FF6),
    (Name: 'LZSS-CT';  CmpType: ctLZSS_CT)
  );


type
  tPalEntry = cardinal;
  tPalette = array[0..255] of tPalEntry;
  pPalette = ^tPalette;

  tVisual = record
    Name:    string[30];
    Address: cardinal;
    SizeRaw,
    SizeCmp: cardinal;
    W, H,
    Off:     cardinal;
    Kind,
    BPP,
    Tmpl,
    Cmp:     byte;
    tW, tH:  byte;
    Pal:     tPalette;
    PalAdr:  cardinal;
    PalNum:  cardinal;
  end;
  pVisual = ^tVisual;


var
  bmp: tBitmap;
  PalBMP: pLogPalette;
  hPalBMP: hPalette;

  Buf: array of byte;


procedure ByteSwapColors(var Colors; Count: Integer);

procedure LoadPalAco(const FileName: string; Pal: pPalette);
procedure LoadPalAct(const FileName: string; Pal: pPalette);
procedure LoadPalZst(const FileName: string; Pal: pPalette);

procedure SavePalAct(const FileName: string; Pal: pPalette);
procedure SavePalAco(const FileName: string; Pal: pPalette);
procedure SavePalZst(const FileName: string; Pal: pPalette);


implementation
uses SysUtils;


procedure ByteSwapColors(var Colors; Count: Integer);
var   // convert RGB to BGR and vice-versa.  TRGBQuad <-> TPaletteEntry
  SysInfo: TSystemInfo;
begin
  GetSystemInfo(SysInfo);
  asm
        MOV   EDX, Colors
        MOV   ECX, Count
        DEC   ECX
        JS    @@END
        LEA   EAX, SysInfo
        CMP   [EAX].TSystemInfo.wProcessorLevel, 3
        JE    @@386
  @@1:  MOV   EAX, [EDX+ECX*4]
        BSWAP EAX
        SHR   EAX,8
        MOV   [EDX+ECX*4],EAX
        DEC   ECX
        JNS   @@1
        JMP   @@END
  @@386:
        PUSH  EBX
  @@2:  XOR   EBX,EBX
        MOV   EAX, [EDX+ECX*4]
        MOV   BH, AL
        MOV   BL, AH
        SHR   EAX,16
        SHL   EBX,8
        MOV   BL, AL
        MOV   [EDX+ECX*4],EBX
        DEC   ECX
        JNS   @@2
        POP   EBX
    @@END:
  end;
end;



procedure LoadPalAco(const FileName: string; Pal: pPalette);
  var i: integer;
      v, m, c: word;
      tmp: array of byte;
      f, n, p: cardinal;
begin
  f := CreateFile(pChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if f = INVALID_HANDLE_VALUE then raise Exception.Create(format('%s not found', [FileName]));
  n := GetFileSize(f, nil);
  SetLength(tmp, n);
  ReadFile(f, tmp[0], n, n, nil);
  CloseHandle(f);

  v := tmp[0] shl 8 + tmp[1];
  if (v < 1) or (v > 2) then
    raise Exception.Create(format('Unknown palette version: %d', [v]));
  m := tmp[2] shl 8 + tmp[3];
  if (m*10 + 4) > n then
    raise Exception.Create('Wrong data/extention');
  if m > 256 then m := 256;

  FillChar(Pal^, 256*4, 0);
  p := 4;
  if v = 1 then begin
    for i := 0 to m-1 do begin
      c := tmp[p] shl 8 + tmp[p+1];
      if c <> 0 then
        raise Exception.Create(format('Unknown color space ID: %d', [c]));
      Pal[i] := tmp[p+2] + tmp[p+4] shl 8 + tmp[p+6] shl 16;
      inc(p, 10);
    end;
  end else begin
  end;

  SetLength(tmp, 0);
end;


procedure LoadPalACT(const FileName: string; Pal: pPalette);
  var i: integer;
      tmp: array[0..771] of byte;
      f, n: cardinal;
begin
  f := CreateFile(pChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if f = INVALID_HANDLE_VALUE then raise Exception.Create(format('%s not found', [FileName]));
  n := GetFileSize(f, nil);
  if (n <> 768) and (n <> 772) then
    raise Exception.Create('Invalid file size');
  ReadFile(f, tmp[0], n, n, nil);
  CloseHandle(f);

  for i := 0 to 255 do
    Pal[i] := tmp[3*i] + tmp[3*i+1] shl 8 + tmp[3*i+2] shl 16;
end;


procedure LoadPalZst(const FileName: string; Pal: pPalette);
  var i: integer;
      tmp: array[0..255] of Word;
      p: pWord;
      R, G, B: byte;
      f, n: cardinal;
begin
  f := CreateFile(pchar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if f = INVALID_HANDLE_VALUE then raise Exception.Create(format('%s not found', [FileName]));
  SetFilePointer(f, $618, nil, FILE_BEGIN);
  ReadFile(f, tmp[0], 512, n, nil);
  CloseHandle(f);

  p := @tmp[0];
  for i := 0 to 255 do begin
    R := p^ and $1F;
    G := (p^ shr 5) and $1F;
    B := (p^ shr 10) and $1F;
    Pal[i] := (R * 255) div 31 + ((G*255) div 31) shl 8 + ((B*255) div 31 ) shl 16;
    inc(p);
  end;
end;



procedure SavePalAct(const FileName: string; Pal: pPalette);
  var i: integer;
      tmp: array[0..771] of byte;
      f, n: cardinal;
begin
  for i := 0 to 255 do begin
    tmp[3*i]   := Pal[i];        //there should be and $FF. But since we assign to byte no need!
    tmp[3*i+1] := Pal[i] shr 8;
    tmp[3*i+2] := Pal[i] shr 16;
  end;

  f := CreateFile(pchar(FileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  WriteFile(f, tmp[0], 768, n, nil);
  CloseHandle(f);
end;


procedure SavePalAco(const FileName: string; Pal: pPalette);
  const cAco256 = 256*10 + 4;
  var i: integer;
      tmp: array[0 .. cAco256-1] of byte;
      f, n: cardinal;
begin
  FillChar(tmp[0], cAco256, 0);
  tmp[1] := 1;   // Version 1
  tmp[2] := 1;   // We will write 256 colors. Optimization?

  for i := 0 to 255 do begin
    tmp[10*i + 6]  := Pal[i] and $FF;
    tmp[10*i + 8]  := (Pal[i] shr 8) and $FF;
    tmp[10*i + 10] := (Pal[i] shr 16) and $FF;
  end;

  f := CreateFile(pchar(FileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  WriteFile(f, tmp[0], cAco256, n, nil);
  CloseHandle(f);
end;


procedure SavePalZst(const FileName: string; Pal: pPalette);
  var i: integer;
      tmp: array[0..255] of Word;
      f, n: cardinal;
begin
  for i := 0 to 255 do
    tmp[i] :=
      (Pal[i] and $FF) shr 3 +      // R
      (Pal[i] shr 6) and $3E0 +     // G
      (Pal[i] shr 9) and $7C00;     // B

  f := CreateFile(pchar(FileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  SetFilePointer(f, $618, nil, FILE_BEGIN);
  WriteFile(f, tmp[0], 512, n, nil);
  CloseHandle(f);
end;


end.
