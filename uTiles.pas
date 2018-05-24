unit uTiles;

interface
uses Windows, Graphics;


type
  tPalSNES = ^Word;
  tPal4bpp = array[0..15] of cardinal;
  pPal4bpp = ^tPal4bpp;

  tPalBack = array[0..5, 0..15] of cardinal;
  pPalBack = ^tPalBack;
  tBackMap = ^Word;

  tTile    = array[0..7, 0..7] of byte;
  pTile    = ^tTile;
  tTileset = array[0..1, 0..7, 0..7] of byte;
  pTileset = ^tTileset;

  tTileSNES = array[0..31] of byte;
  pTileSnes = ^tTileSNES;

  tMapMap = array[0..1] of word;
  pMapMap = ^tMapMap;

  pByteArray = ^tByteArray;
  tByteArray = array[word] of Byte;


procedure ConvertPal(Address: tPalSNES; Pal: pPal4bpp; Num: cardinal = 16);
procedure ConvertTileGBA(Buffer: pByte; Tiles: pTileset; Num: cardinal);
procedure ConvertTileSNES1Bpp(Buffer: pTileSnes; Tiles: pTileset; Num: cardinal);
procedure ConvertTileSNES2Bpp(Buffer: pTileSnes; Tiles: pTileset; Num: cardinal);
procedure ConvertTileSNES3Bpp(Buffer: pTileSnes; Tiles: pTileset; Num: cardinal);
procedure ConvertTileSNES4Bpp(Buffer: pTileSnes; Tiles: pTileset; Num: cardinal);
procedure ConvertTileSNES8Bpp(Buffer: pTileSnes; Tiles: pTileset; Num: cardinal);

procedure DrawBackgroundGBA(Win: HWND; X, Y, Zoom: integer; Transparent: boolean; Tiles: pTileset; Pal: pPalBack; Map: tBackMap);
procedure DrawBackgroundGBA2(DC: HDC; X, Y, Zoom: integer; Transparent: boolean; Tiles: pTileset; Pal: pPalBack; Map: tBackMap);

procedure DrawMobSpriteGBA(Win: HWND; X,Y,W,H, Zoom: integer; Transparent: boolean; Sprite: pTileset; Pal: pPal4bpp);
procedure DrawSprite(Win: HWND; X,Y,W,H, Zoom: integer; Transparent: boolean; Sprite: pTileset; Pal: pPal4bpp; tW, tH: integer);

procedure DrawMobSprite   (Win: HWND; X,Y, Zoom: integer; Transparent: boolean; Sprite: pTileset; Pal: pPal4bpp; Map: pByte);
procedure DrawMobSpriteBig(Win: HWND; X,Y, Zoom: integer; Transparent: boolean; Sprite: pTileset; Pal: pPal4bpp; Map: pWord);

procedure DrawPal(Win: HWND; X,Y,W,H,M,N: integer; Pal: pPal4bpp);
procedure DrawTile(Win: HWND; X,Y, Zoom: integer; Transparent: boolean; Tile: pTile; Pal: pPal4bpp);

procedure DrawMapBlock(Win: HWND; X,Y, Zoom, Block: integer; Transparent: boolean; Tiles: pTileset; Pal: pPalBack; Map: pMapMap);

procedure Convert_4BppGBA(bmp: tBitmap; Src: pByte; W,H: integer);
procedure Convert_4BppSNES(bmp: tBitmap; Src: pByteArray; W,H: integer);
procedure Convert_3BppSNES(bmp: tBitmap; Src: pByteArray; W,H: integer);
procedure Convert_2BppSNES(bmp: tBitmap; Src: pByteArray; W,H: integer);
procedure Convert_8BppPC(var bmp: tBitmap; Src: pByte; W,H: integer);
procedure Convert_8BppMode7(var bmp: tBitmap; Src: pByteArray; W,H: integer);
procedure Convert_8BppMode7b(var bmp: tBitmap; Src: pByteArray; W,H: integer);
procedure Convert_8BppMode3(var bmp: tBitmap; Src: pByteArray; W,H: integer);
procedure Convert_4BppFX(var bmp: tBitmap; Src: pByte; W,H: integer);
procedure Convert_2BppNES(bmp: tBitmap; Src: pByteArray; W,H: integer);
procedure Convert_2BppNGP(bmp: tBitmap; Src: pByteArray; W,H: integer);
procedure Convert_4BppPC(var bmp: tBitmap; Src: pByte; W,H: integer);

procedure DrawTile16(DstBmp: tBitmap; Xd, Yd: integer; SrcBmp: tBitmap; Xs, Ys: integer; Flip: byte);


implementation

var
  TransColor: cardinal;

procedure ConvertPal(Address: tPalSNES; Pal: pPal4bpp; Num: cardinal);
  var i, c: integer;
      R, G, B: integer;
begin
  for i := 0 to Num-1 do begin
    c := Address^;

    R := (c and $001F) shl 3;
    G := (c and $03E0) shr 2;
    B := (c and $7C00) shr 7;

    Pal[i] := B shl 16 + G shl 8 + R;
    inc(Address);
  end;
end;


procedure ConvertTileGBA(Buffer: pByte; Tiles: pTileset; Num: cardinal);
  var i, j, t: integer;
begin
  for t := 0 to Num -1 do
    for i := 0 to 7 do
      for j := 0 to 3 do begin
        Tiles[t, i, j*2]   := Buffer^ and $0F;
        Tiles[t, i, 2*j+1] := Buffer^ shr 4;
        inc(Buffer);
      end;
end;


procedure DrawBackgroundGBA(Win: HWND; X, Y, Zoom: integer; Transparent: boolean; Tiles: pTileset; Pal: pPalBack; Map: tBackMap);
  var i, j, Si, Sj, Tile, c, p: integer;
      dc: HDC;
      pen: HPEN;
      brush: HBRUSH;
      LogBrush:TLogBrush;
begin
  dc := GetDC(Win);
  pen := SelectObject(dc, GetStockObject(NULL_PEN) );
  LogBrush.lbStyle := BS_SOLID;
  LogBrush.lbColor := $FFFFFF;
  brush := SelectObject(dc, CreateBrushIndirect(LogBrush));

  for Si := 0 to 17-1 do
    for Sj := 0 to 32-1 do begin
        Tile := Map^ and $0FFF;
        p := Map^ shr 12;
        inc(Map);
        for i := 0 to 7 do
          for j := 0 to 7 do begin
            c := Tiles[Tile , i, j];
            if Transparent and ( c = 0) then LogBrush.lbColor := TransColor
              else LogBrush.lbColor := Pal[p][c];
            DeleteObject( SelectObject(dc, CreateBrushIndirect(LogBrush) ) );
            Rectangle( dc, X + Zoom*(Sj*8 + j) , Y + Zoom*(Si*8 + i),
                           X + Zoom*(Sj*8 + j +1) +1, Y + Zoom*(Si*8 + i +1) +1 );
          end;
    end;

  SelectObject(dc, pen);
  DeleteObject(SelectObject(dc, brush));
  ReleaseDC(Win, dc);
end;


procedure DrawBackgroundGBA2(DC: HDC; X, Y, Zoom: integer; Transparent: boolean; Tiles: pTileset; Pal: pPalBack; Map: tBackMap);
  var i, j, Si, Sj, Tile, c, p: integer;
      hMirror: boolean;
      pen: HPEN;
      brush: HBRUSH;
      LogBrush:TLogBrush;
begin
  pen := SelectObject(dc, GetStockObject(NULL_PEN) );
  LogBrush.lbStyle := BS_SOLID;
  LogBrush.lbColor := $FFFFFF;
  brush := SelectObject(dc, CreateBrushIndirect(LogBrush));

  for Si := 0 to 17-1 do
    for Sj := 0 to 32-1 do begin
        Tile := Map^ and $03FF;
        p := Map^ shr 12;
        hMirror := (Map^ and $0400) <> 0;
        inc(Map);
        for i := 0 to 7 do
          for j := 0 to 7 do begin
            if hMirror then c := Tiles[Tile , i, 7-j]
                       else c := Tiles[Tile , i, j];
            if Transparent and ( c = 0) then LogBrush.lbColor := TransColor
              else LogBrush.lbColor := Pal[p][c];
            DeleteObject( SelectObject(dc, CreateBrushIndirect(LogBrush) ) );
            Rectangle( dc, X + Zoom*(Sj*8 + j) , Y + Zoom*(Si*8 + i),
                           X + Zoom*(Sj*8 + j +1) +1, Y + Zoom*(Si*8 + i +1) +1 );
          end;
    end;

  SelectObject(dc, pen);
  DeleteObject(SelectObject(dc, brush));
end;


procedure ConvertTileSNES1Bpp(Buffer: pTileSnes; Tiles: pTileset; Num: cardinal);
  var i, j, m, t: cardinal;
      b0: byte;
begin
  m := 0;
  for t := 0 to Num-1 do begin
    for i := 0 to 7 do
      for j := 0 to 7 do begin
        b0 := ( Buffer[m + i] shr (7-j) ) and $01;
        Tiles[t, i, j] := b0;
      end;
    inc(m, 8);
  end
end;


procedure ConvertTileSNES2Bpp(Buffer: pTileSnes; Tiles: pTileset; Num: cardinal);
  var i, j, m, t: cardinal;
      b0, b1: byte;
begin
  m := 0;
  for t := 0 to Num-1 do begin
    for i := 0 to 7 do
      for j := 0 to 7 do begin
        b0 := ( Buffer[m + 2*i] shr (7-j) ) and $01;
        b1 := ( Buffer[m + 2*i + 1] shr (7-j) ) and $01;
        Tiles[t, i, j] := b0 + b1 shl 1;
      end;
    inc(m, 16);
  end
end;


procedure ConvertTileSNES3Bpp(Buffer: pTileSnes; Tiles: pTileset; Num: cardinal);
  var i, j, m, t: cardinal;
      b0, b1, b2: byte;
begin
  m := 0;
  for t := 0 to Num-1 do begin
    for i := 0 to 7 do
      for j := 0 to 7 do begin
        b0 := ( Buffer[m + 2*i] shr (7-j) ) and $01;
        b1 := ( Buffer[m + 2*i + 1] shr (7-j) ) and $01;
        b2 := ( Buffer[m + i + 16] shr (7-j) ) and $01;
        Tiles[t, i, j] := b0 + b1 shl 1 + b2 shl 2;
      end;
    inc(m, 24);
  end
end;


procedure ConvertTileSNES4Bpp(Buffer: pTileSnes; Tiles: pTileset; Num: cardinal);
  var i, j, m, t: cardinal;
      b0, b1, b2, b3: byte;
begin
  m := 0;
  for t := 0 to Num-1 do begin
    for i := 0 to 7 do
      for j := 0 to 7 do begin
        b0 := ( Buffer[m + 2*i] shr (7-j) ) and $01;
        b1 := ( Buffer[m + 2*i + 1] shr (7-j) ) and $01;
        b2 := ( Buffer[m + 2*i + 16] shr (7-j) ) and $01;
        b3 := ( Buffer[m + 2*i + 17] shr (7-j) ) and $01;
        Tiles[t, i, j] := b0 + b1 shl 1 + b2 shl 2 + b3 shl 3;
      end;
    inc(m, 32);
  end;
end;


procedure ConvertTileSNES8Bpp(Buffer: pTileSnes; Tiles: pTileset; Num: cardinal);
  var i, j, m, t: cardinal;
begin
  m := 0;
  for t := 0 to Num-1 do
    for i := 0 to 7 do
      for j := 0 to 7 do begin
        Tiles[t, i, j] := Buffer[m];
        inc(m);
      end;
end;


procedure DrawMobSpriteGBA(Win: HWND; X,Y,W,H, Zoom: integer; Transparent: boolean; Sprite: pTileset; Pal: pPal4bpp);
  var i, j, Si, Sj, Tile, n, c: integer;
      dc: HDC;
      pen: HPEN;
      brush: HBRUSH;
      LogBrush:TLogBrush;
begin
  dc := GetDC(Win);
  pen := SelectObject(dc, GetStockObject(NULL_PEN) );
  LogBrush.lbStyle := BS_SOLID;
  LogBrush.lbColor := $FFFFFF;
  brush := SelectObject(dc, CreateBrushIndirect(LogBrush));

  n := 0;
  for Si := 0 to H-1 do
    for Sj := 0 to W-1 do begin
        Tile := n;
        inc(n);
        for i := 0 to 7 do
          for j := 0 to 7 do begin
            c := Sprite[Tile , i, j];
            if Transparent and ( c = 0) then LogBrush.lbColor := TransColor
              else LogBrush.lbColor := Pal[ c ];
            DeleteObject( SelectObject(dc, CreateBrushIndirect(LogBrush) ) );
            Rectangle( dc, X + Zoom*(Sj*8 + j) , Y + Zoom*(Si*8 + i),
                           X + Zoom*(Sj*8 + j +1) +1, Y + Zoom*(Si*8 + i +1) +1 );
          end;
    end;

  SelectObject(dc, pen);
  DeleteObject(SelectObject(dc, brush));
  ReleaseDC(Win, dc);
end;


procedure DrawSprite(Win: HWND; X,Y,W,H, Zoom: integer; Transparent: boolean; Sprite: pTileset; Pal: pPal4bpp; tW, tH: integer);
  var i, j, Si, Sj, Tile, n, c: integer;
      dc: HDC;
      pen: HPEN;
      brush: HBRUSH;
      LogBrush:TLogBrush;
begin
  dc := GetDC(Win);
  pen := SelectObject(dc, GetStockObject(NULL_PEN) );
  LogBrush.lbStyle := BS_SOLID;
  LogBrush.lbColor := $FFFFFF;
  brush := SelectObject(dc, CreateBrushIndirect(LogBrush));

  n := 0;
  for Si := 0 to H-1 do
    for Sj := 0 to W-1 do begin
        Tile := n;
        inc(n);
        for i := 0 to tH-1 do
          for j := 0 to tW-1 do begin
            c := Sprite[Tile , i, j];
            if Transparent and ( c = 0) then LogBrush.lbColor := TransColor
              else LogBrush.lbColor := Pal[ c ];
            DeleteObject( SelectObject(dc, CreateBrushIndirect(LogBrush) ) );
            Rectangle( dc, X + Zoom*(Sj*tW + j) , Y + Zoom*(Si*tH + i),
                           X + Zoom*(Sj*tW + j +1) +1, Y + Zoom*(Si*tH + i +1) +1 );
          end;
    end;

  SelectObject(dc, pen);
  DeleteObject(SelectObject(dc, brush));
  ReleaseDC(Win, dc);
end;


procedure DrawMobSprite(Win: HWND; X,Y, Zoom: integer; Transparent: boolean; Sprite: pTileset; Pal: pPal4bpp; Map: pByte);
  const Mask: array[0..7] of byte = ($80, $40, $20, $10, $08, $04, $02, $01);
  var i, j, Si, Sj, Tile, c: integer;
      dc: HDC;
      pen: HPEN;
      brush: HBRUSH;
      LogBrush:TLogBrush;
begin
  dc := GetDC(Win);
  pen := SelectObject(dc, GetStockObject(NULL_PEN) );
  LogBrush.lbStyle := BS_SOLID;
  LogBrush.lbColor := $FFFFFF;
  brush := SelectObject(dc, CreateBrushIndirect(LogBrush));

  Tile := 0;
  for Si := 0 to 7 do begin
    for Sj := 0 to 7 do
      if ( Map^ and Mask[Sj] ) <> 0 then begin
        for i := 0 to 7 do
          for j := 0 to 7 do begin
            c := Sprite[Tile , i, j];
            //if MobSprite[Mob].Compress = 1
            //  then c := c and $07;
            if Transparent and ( c = 0) then LogBrush.lbColor := TransColor
              else LogBrush.lbColor := Pal[ c ];
            DeleteObject( SelectObject(dc, CreateBrushIndirect(LogBrush) ) );
            Rectangle( dc, X + Zoom*(Sj*8 + j) , Y + Zoom*(Si*8 + i),
                           X + Zoom*(Sj*8 + j +1) +1, Y + Zoom*(Si*8 + i +1) +1 );
          end;
        inc(Tile);
      end;
    inc(Map);
  end;

  SelectObject(dc, pen);
  DeleteObject(SelectObject(dc, brush));
  ReleaseDC(Win, dc);
end;


procedure DrawMobSpriteBig(Win: HWND; X,Y, Zoom: integer; Transparent: boolean; Sprite: pTileset; Pal: pPal4bpp; Map: pWord);
  const MaskBig: array[0..15] of word = (
    $8000, $4000, $2000, $1000, $0800, $0400, $0200, $0100,
    $0080, $0040, $0020, $0010, $0008, $0004, $0002, $0001);
  var i, j, Si, Sj, Tile, c: integer;
      dc: HDC;
      pen: HPEN;
      brush: HBRUSH;
      LogBrush:TLogBrush;
begin
  dc := GetDC(Win);
  pen := SelectObject(dc, GetStockObject(NULL_PEN) );
  LogBrush.lbStyle := BS_SOLID;
  LogBrush.lbColor := $FFFFFF;
  brush := SelectObject(dc, CreateBrushIndirect(LogBrush));

  Tile := 0;
  for Si := 0 to 15 do begin
    for Sj := 0 to 15 do
      if ( Map^ and MaskBig[Sj] ) <> 0 then begin
        for i := 0 to 7 do
          for j := 0 to 7 do begin
            c := Sprite[Tile , i, j];
            //if MobSprite[Mob].Compress = 1
            //  then c := c and $07;
            if Transparent and ( c = 0) then LogBrush.lbColor := TransColor
              else LogBrush.lbColor := Pal[ c ];
            DeleteObject( SelectObject(dc, CreateBrushIndirect(LogBrush) ) );
            Rectangle( dc, X + Zoom*(Sj*8 + j) , Y + Zoom*(Si*8 + i),
                           X + Zoom*(Sj*8 + j +1) +1, Y + Zoom*(Si*8 + i +1) +1 );
          end;
        inc(Tile);
      end;
    inc(Map);
  end;

  SelectObject(dc, pen);
  DeleteObject(SelectObject(dc, brush));
  ReleaseDC(Win, dc);
end;


procedure DrawPal(Win: HWND; X,Y,W,H,M,N: integer; Pal: pPal4bpp);
  var i, j, c: integer;
      dc: HDC;
      pen: HPEN;
      brush: HBRUSH;
      LogBrush:TLogBrush;
begin
  dc := GetDC(Win);
  pen := SelectObject(dc, GetStockObject(NULL_PEN) );
  LogBrush.lbStyle := BS_SOLID;
  LogBrush.lbColor := $FFFFFF;
  brush := SelectObject(dc, CreateBrushIndirect(LogBrush));

  c := 0;
  for i := 0 to N-1 do
    for j := 0 to M-1 do begin
      LogBrush.lbColor := Pal[ c ];
      DeleteObject( SelectObject(dc, CreateBrushIndirect(LogBrush) ) );
      Rectangle(dc, X + j*W, Y + i*H, X + j*W + W, Y + i*H + H);
      inc(c);
    end;

  SelectObject(dc, pen);
  DeleteObject(SelectObject(dc, brush));
  ReleaseDC(Win, dc);
end;


procedure DrawTile(Win: HWND; X,Y, Zoom: integer; Transparent: boolean; Tile: pTile; Pal: pPal4bpp);
  var i, j, c: integer;
      dc: HDC;
      pen: HPEN;
      brush: HBRUSH;
      LogBrush:TLogBrush;
begin
  dc := GetDC(Win);
  pen := SelectObject(dc, GetStockObject(NULL_PEN) );
  LogBrush.lbStyle := BS_SOLID;
  LogBrush.lbColor := $FFFFFF;
  brush := SelectObject(dc, CreateBrushIndirect(LogBrush));

  for i := 0 to 7 do
    for j := 0 to 7 do begin
      c := Tile[i, j];
      if Transparent and ( c = 0) then LogBrush.lbColor := TransColor
        else LogBrush.lbColor := Pal[ c ];
      DeleteObject( SelectObject(dc, CreateBrushIndirect(LogBrush) ) );
      Rectangle( dc, X + Zoom*j , Y + Zoom*i,
                     X + Zoom*(j +1) +1, Y + Zoom*(i +1) +1 );
    end;

  SelectObject(dc, pen);
  DeleteObject(SelectObject(dc, brush));
  ReleaseDC(Win, dc);
end;


procedure DrawMapBlock(Win: HWND; X,Y, Zoom, Block: integer; Transparent: boolean; Tiles: pTileset; Pal: pPalBack; Map: pMapMap);
  var i, j, c, Tile, p, dX, dY: integer;
      hMirror, vMirror: boolean;
      dc: HDC;
      pen: HPEN;
      brush: HBRUSH;
      LogBrush:TLogBrush;
begin
  dc := GetDC(Win);
  pen := SelectObject(dc, GetStockObject(NULL_PEN) );
  LogBrush.lbStyle := BS_SOLID;
  LogBrush.lbColor := $FFFFFF;
  brush := SelectObject(dc, CreateBrushIndirect(LogBrush));

  Tile := Map[Block] and $3FF;
  p    := (Map[Block] and $1C00) shr 10;
  hMirror := (Map[Block] and $4000) > 0;
  vMirror := (Map[Block] and $8000) > 0;
  for i := 0 to 7 do
    for j := 0 to 7 do begin
      if hMirror then dY := 7-j
                 else dY := j;
      if vMirror then dX := 7-i
                 else dX := i;
      c := Tiles[Tile , dX, dY];
      if Transparent and ( c = 0) then continue;
      LogBrush.lbColor := Pal[p][c];
      DeleteObject( SelectObject(dc, CreateBrushIndirect(LogBrush) ) );
      Rectangle( dc, X + Zoom*j , Y + Zoom*i,
                     X + Zoom*(j +1) +1, Y + Zoom*(i +1) +1 );
    end;

  Tile := Map[Block + $100] and $3FF;
  p    := (Map[Block + $100] and $1C00) shr 10;
  hMirror := (Map[Block + $100] and $4000) > 0;
  vMirror := (Map[Block + $100] and $8000) > 0;
  for i := 0 to 7 do
    for j := 0 to 7 do begin
      if hMirror then dY := 7-j
                 else dY := j;
      if vMirror then dX := 7-i
                 else dX := i;
      c := Tiles[Tile , dX, dY];
      if Transparent and ( c = 0) then continue;
      LogBrush.lbColor := Pal[p][c];
      DeleteObject( SelectObject(dc, CreateBrushIndirect(LogBrush) ) );
      Rectangle( dc, X + Zoom*j + Zoom*8, Y + Zoom*i,
                     X + Zoom*(j +1) +1+ Zoom*8, Y + Zoom*(i +1) +1 );
    end;

  Tile := Map[Block + $200] and $3FF;
  p    := (Map[Block + $200] and $1C00) shr 10;
  hMirror := (Map[Block + $200] and $4000) > 0;
  vMirror := (Map[Block + $200] and $8000) > 0;
  for i := 0 to 7 do
    for j := 0 to 7 do begin
      if hMirror then dY := 7-j
                 else dY := j;
      if vMirror then dX := 7-i
                 else dX := i;
      c := Tiles[Tile , dX, dY];
      if Transparent and ( c = 0) then continue;
      LogBrush.lbColor := Pal[p][c];
      DeleteObject( SelectObject(dc, CreateBrushIndirect(LogBrush) ) );
      Rectangle( dc, X + Zoom*j, Y + Zoom*i + Zoom*8,
                     X + Zoom*(j +1) +1, Y + Zoom*(i +1) +1 + Zoom*8);
    end;

  Tile := Map[Block + $300] and $3FF;
  p    := (Map[Block + $300] and $1C00) shr 10;
  hMirror := (Map[Block + $300] and $4000) > 0;
  vMirror := (Map[Block + $300] and $8000) > 0;
  for i := 0 to 7 do
    for j := 0 to 7 do begin
      if hMirror then dY := 7-j
                 else dY := j;
      if vMirror then dX := 7-i
                 else dX := i;
      c := Tiles[Tile , dX, dY];
      if Transparent and ( c = 0) then continue;
      LogBrush.lbColor := Pal[p][c];
      DeleteObject( SelectObject(dc, CreateBrushIndirect(LogBrush) ) );
      Rectangle( dc, X + Zoom*j + Zoom*8, Y + Zoom*i + Zoom*8,
                     X + Zoom*(j +1) +1 + Zoom*8, Y + Zoom*(i +1) +1 + Zoom*8);
    end;

  SelectObject(dc, pen);
  DeleteObject(SelectObject(dc, brush));
  ReleaseDC(Win, dc);
end;




procedure Convert_4BppGBA(bmp: tBitmap; Src: pByte; W,H: integer);
  var i, j, ty: integer;
      p: PByteArray;
begin
  for i := 0 to H -1 do
    for j := 0 to W -1 do
      for ty := 0 to 7 do begin
        p := bmp.ScanLine[i*8 + ty];
        p[j*8]     := Src^ and $0F;
        p[j*8 + 1] := Src^ shr 4;
        inc(Src);
        p[j*8 + 2] := Src^ and $0F;
        p[j*8 + 3] := Src^ shr 4;
        inc(Src);
        p[j*8 + 4] := Src^ and $0F;
        p[j*8 + 5] := Src^ shr 4;
        inc(Src);
        p[j*8 + 6] := Src^ and $0F;
        p[j*8 + 7] := Src^ shr 4;
        inc(Src);
      end;
end;


procedure Convert_4BppSNES(bmp: tBitmap; Src: pByteArray; W,H: integer);
  var i, j, tx, ty, m: integer;
      b0, b1, b2, b3: byte;
      p: pByteArray;
begin
  for i := 0 to H-1 do
    for ty := 0 to 7 do begin
      p := bmp.ScanLine[i*8 + ty];
      m := ty*2 + i*w*32;
      for j := 0 to W-1 do begin
        b0 := Src[m];
        b1 := Src[m + 1];
        b2 := Src[m + 16];
        b3 := Src[m + 17];
        for tx := 7 downto 0 do
          p[j*8 + 7-tx] :=
             (b0 shr tx) and $01 +
            ((b1 shr tx) and $01) shl 1 +
            ((b2 shr tx) and $01) shl 2 +
            ((b3 shr tx) and $01) shl 3;
        inc(m, 32);
      end;
    end;

{  for i := 0 to H-1 do
    for ty := 0 to 7 do begin
      p := bmp.ScanLine[i*8 + ty];
      m := ty*2 + i*w*32;
      for j := 0 to W-1 do begin
        for tx := 7 downto 0 do begin
          b0 := ( Src[m] shr tx ) and $01;
          b1 := ( Src[m + 1] shr tx ) and $01;
          b2 := ( Src[m + 16] shr tx ) and $01;
          b3 := ( Src[m + 17] shr tx ) and $01;
          p[j*8 + 7-tx] := b0 + b1 shl 1 + b2 shl 2 + b3 shl 3;
        end;
        inc(m, 32);
      end;
    end;  }
end;


procedure Convert_3BppSNES(bmp: tBitmap; Src: pByteArray; W,H: integer);
  var i, j, tx, ty, m, n: integer;
      b0, b1, b2: byte;
      p: pByteArray;
begin
  for i := 0 to H-1 do
    for ty := 0 to 7 do begin
      p := bmp.ScanLine[i*8 + ty];
      m := ty*2 + i*w*24;
      n := ty + i*w*24;
      for j := 0 to W-1 do begin
        b0 := Src[m];
        b1 := Src[m + 1];
        b2 := Src[n + 16];
        for tx := 7 downto 0 do
          p[j*8 + 7-tx] :=
             (b0 shr tx) and $01 +
            ((b1 shr tx) and $01) shl 1 +
            ((b2 shr tx) and $01) shl 2;
        inc(m, 24);
        inc(n, 24);
      end;
    end;
end;

procedure Convert_2BppSNES(bmp: tBitmap; Src: pByteArray; W,H: integer);
  var i, j, tx, ty, m: integer;
      b0, b1: byte;
      p: pByteArray;
begin
  for i := 0 to H-1 do
    for ty := 0 to 7 do begin
      p := bmp.ScanLine[i*8 + ty];
      m := ty*2 + i*w*16;
      for j := 0 to W-1 do begin
        b0 := Src[m];
        b1 := Src[m + 1];
        for tx := 7 downto 0 do
          p[j*8 + 7-tx] :=
             (b0 shr tx) and $01 +
            ((b1 shr tx) and $01) shl 1;
        inc(m, 16);
      end;
    end;
end;


procedure Convert_8BppPC(var bmp: tBitmap; Src: pByte; W,H: integer);
  var i: integer;
      p: Pointer;
begin
  for i := 0 to H -1 do begin
    p := bmp.ScanLine[i];
    Move(Src^, p^, W);
    inc(Src, W);
  end;
end;


procedure Convert_8BppMode7(var bmp: tBitmap; Src: pByteArray; W,H: integer);
  var i, j, ty, tx, m, n: integer;
      p: pByteArray;
begin
  n := 0;
  for i := 0 to H -1 do begin
    for ty := 0 to 7 do begin
      p := bmp.ScanLine[i*8 + ty];
      m := n + 1 + ty * 16;
      for j := 0 to W -1 do begin
        for tx := 0 to 7 do
          p[8*j + tx] := Src[m + 2*tx];
        inc(m, $80);
      end;
    end;
    inc(n, w*$80);
  end;
end;


procedure Convert_8BppMode7b(var bmp: tBitmap; Src: pByteArray; W,H: integer);
  var i, j, ty, tx, m, n: integer;
      p: pByteArray;
begin
  n := 0;
  for i := 0 to H -1 do begin
    for ty := 0 to 7 do begin
      p := bmp.ScanLine[i*8 + ty];
      m := n + ty * 8;
      for j := 0 to W -1 do begin
        for tx := 0 to 7 do
          p[8*j + tx] := Src[m + tx];
        inc(m, 64);
      end;
    end;
    inc(n, w*64);
  end;
end;


procedure Convert_8BppMode3(var bmp: tBitmap; Src: pByteArray; W,H: integer);
  var i, j, tx, ty, m: integer;
      b0, b1, b2, b3, b4, b5, b6, b7: byte;
      p: pByteArray;
begin
  for i := 0 to H-1 do
    for ty := 0 to 7 do begin
      p := bmp.ScanLine[i*8 + ty];
      m := ty*2 + i*w*64;
      for j := 0 to W-1 do begin
        b0 := Src[m];
        b1 := Src[m + 1];
        b2 := Src[m + $10];
        b3 := Src[m + $11];
        b4 := Src[m + $20];
        b5 := Src[m + $21];
        b6 := Src[m + $30];
        b7 := Src[m + $31];
        for tx := 7 downto 0 do
          p[j*8 + 7-tx] :=
             (b0 shr tx) and $01 +
            ((b1 shr tx) and $01) shl 1 +
            ((b2 shr tx) and $01) shl 2 +
            ((b3 shr tx) and $01) shl 3 +
            ((b4 shr tx) and $01) shl 4 +
            ((b5 shr tx) and $01) shl 5 +
            ((b6 shr tx) and $01) shl 6 +
            ((b7 shr tx) and $01) shl 7;
        inc(m, 64);
      end;
    end;
end;


procedure Convert_4BppFX(var bmp: tBitmap; Src: pByte; W,H: integer);
  var i, m, r, y, y2: integer;
      p, p2: pByteArray;
      c1, c2: byte;
      DrawDown: boolean;
begin
  y := 0;
  m := 1;
  while (y < H) and (m < 33) do begin
    p  := bmp.ScanLine[y];
    y2 := y + $20;
    DrawDown := y2 < H;
    if DrawDown then
      p2 := bmp.ScanLine[y2];
    if W < 256 then r := W
               else r := 256;

    for i := 0 to r-1 do begin
      c1 := Src^ and $0F;
      p[i] := c1;
      if DrawDown then begin
        c2 := Src^ shr 4;
        p2[i] := c2;
      end;
      inc(Src);
    end;
    if r < 256 then inc(Src, 256-r);

    inc(m);
    inc(y);
  end;
end;


procedure Convert_2BppNES(bmp: tBitmap; Src: pByteArray; W,H: integer);
  var i, j, tx, ty, m: integer;
      b0, b1: byte;
      p: pByteArray;
begin
  for i := 0 to H-1 do
    for ty := 0 to 7 do begin
      p := bmp.ScanLine[i*8 + ty];
      m := ty + i*w*16;
      for j := 0 to W-1 do begin
        b0 := Src[m];
        b1 := Src[m + 8];
        for tx := 7 downto 0 do
          p[j*8 + 7-tx] :=
             (b0 shr tx) and $01 +
            ((b1 shr tx) and $01) shl 1;
        inc(m, 16);
      end;
    end;
end;


procedure Convert_2BppNGP(bmp: tBitmap; Src: pByteArray; W,H: integer);
  var i, j, tx, ty, m: integer;
      b: word;
      p: pByteArray;
begin
  for i := 0 to H-1 do
    for ty := 0 to 7 do begin
      p := bmp.ScanLine[i*8 + ty];
      m := ty*2 + i*w*16;
      for j := 0 to W-1 do begin
        b := Src[m] + Src[m + 1] shl 8;
        for tx := 7 downto 0 do
          p[j*8 + 7-tx] :=
            (b shr (2*tx)) and $03;
        inc(m, 16);
      end;
    end;
end;


procedure Convert_4BppPC(var bmp: tBitmap; Src: pByte; W,H: integer);
  var i, j: integer;
      p: pByteArray;
begin
  for i := 0 to H -1 do begin
    p := bmp.ScanLine[i];
    for j := 0 to W shr 1 -1 do begin
      p[2*j]     := Src^ and $0F;
      p[2*j + 1] := Src^ shr 4;
      inc(Src);
    end;
  end;
end;


procedure DrawTile16(DstBmp: tBitmap; Xd, Yd: integer; SrcBmp: tBitmap; Xs, Ys: integer; Flip: byte);
  var i, j: integer;
      s, d: pByteArray;
      c: byte;
begin
  for i := 0 to 15 do begin
    s := SrcBmp.ScanLine[Ys + i];
    if (Flip and $02) > 0 then d := DstBmp.ScanLine[Yd + 16-i]
                          else d := DstBmp.ScanLine[Yd + i];
    for j := 0 to 15 do begin
      c := s[Xs+j];
      if c = 0 then continue;
      if (Flip and $01) > 0 then d[Xd + 16-j] := c
                            else d[Xd + j] := c;
    end;
  end;
end;



initialization
  TransColor := GetSysColor(COLOR_BTNFACE);

end.
