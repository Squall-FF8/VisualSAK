unit uTiles;

interface
uses Windows;


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


initialization
  TransColor := GetSysColor(COLOR_BTNFACE);

end.