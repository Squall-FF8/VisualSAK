unit uCommon;

interface
uses Windows, Graphics;


const
  cFmt = '%3d ($%.2x)';


type
  tTemplate = record
    Name: string[20];
    BPP : byte;
  end;
  pTemplate = ^tTemplate;

const
  // Tile Format constants
  cTmplNum = 9;
  cTemplate: array[0 .. cTmplNum] of tTemplate = (
    (Name: '';               BPP: 0),
    (Name: '4bpp (GBA)';     BPP: 4),
    (Name: '4bpp (SNES)';    BPP: 4),
    (Name: '3bpp (SNES)';    BPP: 3),
    (Name: '2bpp (SNES)';    BPP: 2),
    (Name: '1bpp';           BPP: 1),
    (Name: '8bpp (Mode7-1)'; BPP: 8),
    (Name: '8bpp (Mode7-2)'; BPP: 8),
    (Name: '8bpp (Mode3)';   BPP: 8),
    (Name: '8bpp (PC)';      BPP: 8)
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


implementation


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



end.
