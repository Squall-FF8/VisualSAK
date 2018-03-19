unit uCommon;

interface
uses Windows, Graphics;

var
  bmp: tBitmap;
  PalBMP: pLogPalette;
  hPalBMP: hPalette;

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
