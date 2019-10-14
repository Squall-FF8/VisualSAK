unit uCommon;

interface
uses Windows, Graphics, Classes;


const
  cFmt = '%3d ($%.2x)';

  cRomExt =
    'All Consoles|*.smc; *.sfc; *.gba; *.nes; *.ngp|'+
    'Super Nintendo (SNES)|*.smc; *.sfc|'+
    'Gameboy Advance (GBA)|*.gba|'+
    'Nintendo (NES)|*.nes|'+
    'Neo-Geo Portable ROM|*.ngp|'+
    'ZSNES savestate|*.zs?|'+
    'ALL|*.*';

type
  tVSKHeader = packed record
    ID: array[1..4] of char;
    Revision: byte;
    Count: cardinal;
  end;

  tTemplate = record
    Name: string[20];
    BPP,
    tW,
    tH: byte;
  end;
  pTemplate = ^tTemplate;

const
  // Tile Format constants
  cTmplNum = 14;
  cTemplate: array[0 .. cTmplNum] of tTemplate = (
    (Name: '';                BPP: 1;  tW:1; tH:1),
    (Name: '4bpp (GBA)';      BPP: 4;  tW:8; tH:8),
    (Name: '4bpp (SNES)';     BPP: 4;  tW:8; tH:8),
    (Name: '3bpp (SNES)';     BPP: 3;  tW:8; tH:8),
    (Name: '2bpp (SNES)';     BPP: 2;  tW:8; tH:8),
    (Name: '1bpp';            BPP: 1;  tW:8; tH:8),
    (Name: '8bpp (Mode7-1)';  BPP: 8;  tW:8; tH:8),
    (Name: '8bpp (Mode7-2)';  BPP: 8;  tW:8; tH:8),
    (Name: '8bpp (Mode3)';    BPP: 8;  tW:8; tH:8),
    (Name: '8bpp (PC)';       BPP: 8;  tW:1; tH:1),
    (Name: '4bpp (SNES-FX)';  BPP: 4;  tW:1; tH:1),
    (Name: '2bpp (NES)';      BPP: 2;  tW:8; tH:8),
    (Name: '2bpp (NGP)';      BPP: 2;  tW:8; tH:8),
    (Name: '4bpp (PC    )';   BPP: 4;  tW:1; tH:1),
    (Name: '15bpp (BGR 555)'; BPP: 15; tW:1; tH:1)
  );

  cFmtTileNum = 1;
  cFmtTile: array[0 .. cFmtTileNum] of string =  (
    '',
    '4bpp tiles (GBA)' );

  cFmtPalNum = 3;
  cFmtPal: array[0 .. cFmtPalNum] of string =  (
    '',
    'RGB: 888 (24bit)',
    'RGB: 555 (15bit)',
    'RGB: 444 (12bit)' );

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
  tPalette = array of tPalEntry;
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
    Reserved: array[1..20] of byte;  //for future extentions
  end;
  pVisual = ^tVisual;


var
  bmp: tBitmap;
  PalBMP: pLogPalette;
  hPalBMP: hPalette;

  Buf, TmpFile: array of byte;

  vHeader: tVSKHeader = (ID: 'VSAK'; Revision: 4);


procedure ByteSwapColors(var Colors; Count: Integer);

procedure LoadPalAco(const FileName: string; var Pal: tPalette);
procedure LoadPalAct(const FileName: string; var Pal: tPalette);
procedure LoadPalZst(const FileName: string; var Pal: tPalette);

procedure SavePalAct(const FileName: string; const Pal: tPalette);
procedure SavePalAco(const FileName: string; const Pal: tPalette);
procedure SavePalZst(const FileName: string; const Pal: tPalette);

function NewVisual: pVisual;
procedure DelVisual(v: pVisual);
procedure SaveVisuals(const DocName: string; Items: tStrings);
procedure LoadVisuals(const DocName: string; Items: tStrings);


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



procedure LoadPalAco(const FileName: string; var Pal: tPalette);
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

  FillChar(Pal, 256*4, 0);
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


procedure LoadPalACT(const FileName: string; var Pal: tPalette);
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


procedure LoadPalZst(const FileName: string; var Pal: tPalette);
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



procedure SavePalAct(const FileName: string; const Pal: tPalette);
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


procedure SavePalAco(const FileName: string; const Pal: tPalette);
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


procedure SavePalZst(const FileName: string; const Pal: tPalette);
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


{
  Visual Manipulations
}
function NewVisual: pVisual;
begin
  New(Result);
  FillChar(Result^, Sizeof(Result^), 0);
  SetLength(Result.Pal, 256);
end;


procedure DelVisual(v: pVisual);
begin
  SetLength(v.Pal, 0);
  Dispose(v);
end;


procedure SaveVisuals(const DocName: string; Items: tStrings);
  var i: integer;
      f, n: cardinal;
begin
  vHeader.Count := Items.Count;

  f := CreateFile(pchar(DocName), GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if f = INVALID_HANDLE_VALUE then raise Exception.Create(format('%s not found', [DocName]));
  WriteFile(f, vHeader, SizeOf(vHeader), n, nil);

  for i := 0 to Items.Count -1 do
    WriteFile(f, pVisual(Items.Objects[i])^, SizeOf(tVisual), n, nil);

  for i := 0 to Items.Count -1 do
    WriteFile(f, pVisual(Items.Objects[i])^.Pal[0], 4 * pVisual(Items.Objects[i])^.PalNum, n, nil);

  CloseHandle(f);
end;


procedure LoadVisuals(const DocName: string; Items: tStrings);
  var i: integer;
      f, n: cardinal;
      Header: tVSKHeader;
      v: pVisual;
begin
  f := CreateFile(pchar(DocName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if f = INVALID_HANDLE_VALUE then raise Exception.Create(format('%s not found', [DocName]));
  ReadFile(f, Header, SizeOf(Header), n, nil);

  for i := 1 to Header.Count do begin
    New(v);
    ReadFile(f, v^, SizeOf(v^), n, nil);
    pInteger(@v.Pal)^ := 0;
    //v^.Pal := nil;
    //SetLength(v.Pal, 0);
    Items.AddObject(v.Name, tObject(v));
  end;

  for i := 0 to Header.Count -1 do begin
    v := pVisual(Items.Objects[i]);
    SetLength(v.Pal, 256);
    ReadFile(f, v.Pal[0], 4 * v.PalNum, n, nil);
  end;

  CloseHandle(f);
end;

end.
