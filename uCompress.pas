unit uCompress;

interface


type
  tLZStream = array of byte;

procedure StrToLZ(const Str: string; var LZ: tLZStream);
function  LZToStr(LZ: tLZStream): string;

procedure DecodeLZSS(const Src: tLZStream; var Dst: tLZStream; Header: boolean);

procedure DecodeLZ77(const Src: tLZStream; var Dst: tLZStream);

procedure DecodeLZ77InMem(const Src: tLZStream; var Dst: tLZStream; Size: cardinal); overload;
function DecodeLZ77InMem(const Src: tLZStream; var Dst: tLZStream): cardinal; overload;

function DecodeLZSS_FF5(const Src: tLZStream; var Dst: tLZStream): cardinal;
function DecodeLZSS_FF6(const Src: tLZStream; var Dst: tLZStream): cardinal;
function DecodeLZSS_CT(const Src: tLZStream; var Dst: tLZStream): cardinal;

implementation
  uses Dialogs, Classes;

const
  LZ10 = $10;
  LZ_Shift = 1;
  LZ_Mask = $80;
  LZ_Threshold = 2;


procedure StrToLZ(const Str: string; var LZ: tLZStream);
  var i, n: integer;
      s: string;
begin
  s := '';
  for i := 1 to Length(Str) do
    if Str[i] in ['0'..'9', 'A'..'F'] then
      s := s + Str[i];
  n := Length(s);
  if (n and 1) > 0 then begin
    ShowMessage('The text must represent 2-digit hexadecimal numbers!');
    exit;
  end;

  n := n shr 1;
  SetLength(LZ, n);
  HexToBin(pChar(s), pchar(LZ), n);
end;


function  LZToStr(LZ: tLZStream): string;
begin
  SetLength(Result, 2*Length(LZ));
  BinToHex(pChar(LZ), pChar(Result), Length(LZ));
end;


procedure DecodeLZSS(const Src: tLZStream; var Dst: tLZStream; Header: boolean);
  var i, j, m: integer;
      Buffer: array[0..$7FF] of byte;
      BufPos, SrcPos, DstPos: integer;
      Map: byte;
      o, l: integer;
begin
  if Header and (Src[0] <> 2) then begin
    ShowMessage('Not valid LZSS compressed stream');
    exit;
  end;

  if Header then SrcPos := 1
            else SrcPos := 0;
  m := Src[SrcPos] + Src[SrcPos+1] shl 8;
  inc(SrcPos, 2);
  SetLength(Dst, m);

  // Decompress init
  FillChar(Buffer, $800, 0);
  //SrcPos := 3;
  DstPos := 0;
  BufPos := $07DE;

  while DstPos < m do begin
    Map := Src[SrcPos]; inc(SrcPos);
    for i := 1 to 8 do begin
      if (Map and $01) > 0 then begin
        Dst[DstPos] := Src[SrcPos]; inc(DstPos);
        Buffer[BufPos] := Src[SrcPos]; inc(BufPos);
        if BufPos = $800 then
          BufPos := 0;
        inc(SrcPos);
      end else begin
        o := Src[SrcPos] + (Src[SrcPos + 1] and $E0) shl 3;
        l := Src[SrcPos + 1] and $1F + 3;
        for j := 1 to l do begin
          Dst[DstPos] := Buffer[o]; inc(DstPos);
          Buffer[BufPos] := Buffer[o]; inc(BufPos);
          if BufPos = $800 then
            BufPos := 0;
          inc(o); if o = $800 then o := 0;
        end;
        inc(SrcPos, 2);
      end;
      if DstPos >=m then break;
      Map := Map shr 1;
    end;
  end;
end;


procedure DecodeLZ77(const Src: tLZStream; var Dst: tLZStream);
  var raw, pak, pak_len, raw_len, pos, len: cardinal;
      flags, Mask: byte;
begin
  if Src[0] <> $10 then
    ShowMessage('Not valid LZ77 stream');

  raw_len := pInteger(@Src[0])^ shr 8;
  SetLength(Dst, raw_len);

  raw := 0;
  pak_len := Length(Src);

  pak := 4;
  mask := 0;

  while (raw < raw_len) do begin
    Mask := Mask shr LZ_Shift;
    if Mask = 0 then begin
      if pak = pak_len then break;
      Flags := Src[pak];
      inc(pak);
      Mask := LZ_Mask;
    end;

    if (Flags and Mask) = 0 then begin
      if pak = pak_len then break;
      Dst[raw] := Src[pak];
      inc(raw);
      inc(pak);
    end else begin
      if (pak + 1) >= pak_len then break;
      len := Src[pak] shr 4 + LZ_Threshold + 1;
      pos := (Src[pak] and $0F) shl 8 + Src[pak+1] + 1;
      inc(pak, 2);
      if (raw + len) > raw_len then begin
        ShowMessage('Wrong decoding length!');
        len := raw_len - raw;
      end;
      while len > 0 do begin
        Dst[raw] := Dst[raw - pos];
        inc(raw);
        dec(len);
      end;
    end;
  end;

  if raw <> raw_len then
    ShowMessage('Unexpected end of encoded stream!');
end;


procedure DecodeLZ77InMem(const Src: tLZStream; var Dst: tLZStream; Size: cardinal);
  var raw, pak, pak_len, raw_len, pos, len: cardinal;
      flags, Mask: byte;
begin
  if Src[0] <> $10 then
    ShowMessage('Not valid LZ77 stream');

  raw_len := pInteger(@Src[0])^ shr 8;
  SetLength(Dst, raw_len);

  raw := 0;
  pak_len := Size;

  pak := 4;
  mask := 0;

  while (raw < raw_len) do begin
    Mask := Mask shr LZ_Shift;
    if Mask = 0 then begin
      if pak = pak_len then break;
      Flags := Src[pak];
      inc(pak);
      Mask := LZ_Mask;
    end;

    if (Flags and Mask) = 0 then begin
      if pak = pak_len then break;
      Dst[raw] := Src[pak];
      inc(raw);
      inc(pak);
    end else begin
      if (pak + 1) >= pak_len then break;
      len := Src[pak] shr 4 + LZ_Threshold + 1;
      pos := (Src[pak] and $0F) shl 8 + Src[pak+1] + 1;
      inc(pak, 2);
      if (raw + len) > raw_len then begin
        ShowMessage('Wrong decoding length!');
        len := raw_len - raw;
      end;
      while len > 0 do begin
        Dst[raw] := Dst[raw - pos];
        inc(raw);
        dec(len);
      end;
    end;
  end;

  if raw <> raw_len then
    ShowMessage('Unexpected end of encoded stream!');
end;



{ == definition from GBATEK/NDSTEK
    Data header (32bit)
      Bit 0-3   Reserved
      Bit 4-7   Compressed type (must be 1 for LZ77)
      Bit 8-31  Size of decompressed data
    Repeat below. Each Flag Byte followed by eight Blocks.
    Flag data (8bit)
      Bit 0-7   Type Flags for next 8 Blocks, MSB first
    Block Type 0 - Uncompressed - Copy 1 Byte from Source to Dest
      Bit 0-7   One data byte to be copied to dest
    Block Type 1 - Compressed - Copy N+3 Bytes from Dest-Disp-1 to Dest
      Bit 0-3   Disp MSBs
      Bit 4-7   Number of bytes to copy (minus 3)
      Bit 8-15  Disp LSBs
==}

function DecodeLZ77InMem(const Src: tLZStream; var Dst: tLZStream): cardinal;
  var raw, pak, {pak_len,} raw_len, pos, len: cardinal;
      flags, Mask: byte;
begin
  if Src[0] <> $10 then
    ShowMessage('Not valid LZ10 stream');

  raw_len := pInteger(@Src[0])^ shr 8;
  //SetLength(Dst, raw_len);

  raw := 0;

  pak := 4;
  mask := 0;

  while (raw < raw_len) do begin
    Mask := Mask shr LZ_Shift;
    if Mask = 0 then begin
      Flags := Src[pak];
      inc(pak);
      Mask := LZ_Mask;
    end;

    if (Flags and Mask) = 0 then begin
      Dst[raw] := Src[pak];
      inc(raw);
      inc(pak);
    end else begin
      len := Src[pak] shr 4 + LZ_Threshold + 1;
      pos := (Src[pak] and $0F) shl 8 + Src[pak+1] + 1;
      inc(pak, 2);
      while len > 0 do begin
        Dst[raw] := Dst[raw - pos];
        inc(raw);
        dec(len);
      end;
    end;
  end;

  Result := pak
end;


function DecodeLZSS_FF6(const Src: tLZStream; var Dst: tLZStream): cardinal;
  var i, j, m: integer;
      Buffer: array[0..$7FF] of byte;
      BufPos, SrcPos, DstPos: integer;
      Map: byte;
      o, l: integer;
begin
  SrcPos := 0;
  m := Src[SrcPos] + Src[SrcPos+1] shl 8;
  inc(SrcPos, 2);

  // Decompress init
  FillChar(Buffer, $800, 0);
  BufPos := $07DE;
  DstPos := 0;

  while SrcPos < m do begin
    Map := Src[SrcPos]; inc(SrcPos);
    for i := 1 to 8 do begin
      if (Map and $01) > 0 then begin
        Dst[DstPos] := Src[SrcPos]; inc(DstPos);
        Buffer[BufPos] := Src[SrcPos]; inc(BufPos);
        if BufPos = $800 then
          BufPos := 0;
        inc(SrcPos);
      end else begin
        o := Src[SrcPos] + (Src[SrcPos + 1] and $07) shl 8;
        l := Src[SrcPos + 1] shr 3 + 3;
        for j := 1 to l do begin
          Dst[DstPos] := Buffer[o]; inc(DstPos);
          Buffer[BufPos] := Buffer[o]; inc(BufPos);
          if BufPos = $800 then
            BufPos := 0;
          inc(o); if o = $800 then o := 0;
        end;
        inc(SrcPos, 2);
      end;
      if SrcPos >=m then break;
      Map := Map shr 1;
    end;
  end;

  Result := DstPos;
end;



function DecodeLZSS_FF5(const Src: tLZStream; var Dst: tLZStream): cardinal;
  var i, j, m: integer;
      Buffer: array[0..$7FF] of byte;
      BufPos, SrcPos, DstPos: integer;
      Map: byte;
      o, l: integer;
begin
  m := pWord(@Src[0])^;
  SrcPos := 2;

  // Decompress init
  FillChar(Buffer, $800, 0);
  DstPos := 0;
  BufPos := $07DE;

  while DstPos < m do begin
    Map := Src[SrcPos]; inc(SrcPos);
    for i := 1 to 8 do begin
      if (Map and $01) > 0 then begin
        Dst[DstPos] := Src[SrcPos]; inc(DstPos);
        Buffer[BufPos] := Src[SrcPos]; inc(BufPos);
        if BufPos = $800 then
          BufPos := 0;
        inc(SrcPos);
      end else begin
        o := Src[SrcPos] + (Src[SrcPos + 1] and $E0) shl 3;
        l := Src[SrcPos + 1] and $1F + 3;
        for j := 1 to l do begin
          Dst[DstPos] := Buffer[o]; inc(DstPos);
          Buffer[BufPos] := Buffer[o]; inc(BufPos);
          if BufPos = $800 then
            BufPos := 0;
          inc(o); if o = $800 then o := 0;
        end;
        inc(SrcPos, 2);
      end;
      if DstPos >=m then break;
      Map := Map shr 1;
    end;
  end;

  Result := SrcPos;
end;


function DecodeLZSS_CT(const Src: tLZStream; var Dst: tLZStream): cardinal;
  var i: integer;
      bCarryFlag, bSmallerBitWidth:boolean;
	    nCompressedSize: word;
	    nBytePos, nByteAfter, nWorkPos: cardinal;
	    nBitCtr, nCurByte, nMem0D: byte;

  procedure CTCopyBytes;
    var i: integer;
        nBytesCopyNum: byte;
	      nBytesCopyOff: word;
  begin
  	nBytesCopyNum := Src[nBytePos + 1];
	  if bSmallerBitWidth then nBytesCopyNum := nBytesCopyNum shr 3
                        else nBytesCopyNum := nBytesCopyNum shr 4;
	  inc(nBytesCopyNum, 2);
	  nBytesCopyOff := pWord(@Src[nBytePos])^;
  	if bSmallerBitWidth then nBytesCopyOff := nBytesCopyOff and $07FF
                        else nBytesCopyOff := nBytesCopyOff and $0FFF;
  	for i := 0 to nBytesCopyNum do
  		Dst[nWorkPos + i] := Dst[nWorkPos - nBytesCopyOff + i];
	  inc(nWorkPos, nBytesCopyNum + 1);
	  inc(nBytePos, 2);
  end;
begin
	bCarryFlag := false;
	nCompressedSize := pWord(@Src[0])^;
	nBytePos   := 2;
	nByteAfter := nBytePos + nCompressedSize;
	nWorkPos   := 0;
	bSmallerBitWidth := Src[nByteAfter] >= $C0;
  nBitCtr := 8;

	while True do begin
		if nBytePos = nByteAfter then begin
			nCurByte := Src[nBytePos] and $3F;
			if nCurByte = 0 then break;
			nBitCtr := nCurByte;
			bCarryFlag := false;
			nByteAfter := pWord(@Src[nBytePos + 1])^;
			inc(nBytePos, 3);
		end else begin
			nCurByte := Src[nBytePos];
			if nCurByte = 0 then begin
        for i := 0 to 7 do
				  Dst[nWorkPos + i] := Src[nBytePos + i + 1];
				nCurByte := Src[nBytePos + 8];
        inc(nWorkPos, 8);
				bCarryFlag := false;
				inc(nBytePos, 9);
			end else begin
				inc(nBytePos);
        bCarryFlag := (nCurByte and $01) = 1;
				nCurByte := nCurByte shr 1;
				nMem0D := nCurByte;
				if bCarryFlag then CTCopyBytes
				else begin
					nCurByte := Src[nBytePos];
					Dst[nWorkPos] := nCurByte;
          inc(nWorkPos);
					inc(nBytePos);
				end;
				while True do begin
					dec(nBitCtr);
					if nBitCtr = 0 then begin
						nBitCtr := 8;
						break;
					end
					else begin
            bCarryFlag := (nMem0D and $01) = 1;
						nMem0D := nMem0D shr 1;
						if bCarryFlag then CTCopyBytes
						else begin
							nCurByte := Src[nBytePos];
							Dst[nWorkPos] := nCurByte;
              inc(nWorkPos);
							inc(nBytePos);
						end;
					end;
				end;
			end;
		end;
	end;

  Result := nWorkPos;
end;

end.
