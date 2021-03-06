{ Copyright Enrique Fuentes aka Turric4n :) http://www.turric4n.com
Youtube video of the practice : https://youtu.be/2DkRkONESuo in spanish, sorry
Coments of this code are only in english, sorry, see the Practice video. }

{$asmmode intel}

program VGAInit;

uses
 CRT, SysUtils;

{ Important things!!! FPC is a 32 bit compiler and default Integer type
is 32 bits. We will use 16 bit registers to program VGA (AX -> AH,AL)
So, we need to pass 2 bytes Integer Types (smallint) to registers }

{ Things to know about VGA }
{ VGA memory is 64KB = 64000 Bytes }
{ IBM/AT VGA base memory address is $a000 }
{ VGA Mode 13h is 320x200 256 colors RGB "chunky graphics" can access video memory directly }
{ 320 * 200 is 64000 bytes. So EVERY Byte is a pixel on the screen }
{ Pixel is a Byte (0..254) }
{ VGA BIOS Mode 13h (16 bit) address is $0013 load in AX and call int $10 }
{ VGA BIOS Text mode 10h (16 bit) address s is $0010 load in AX and call int $10 }
{ INT 10h handles screen directly }

{
FIRST VGA COLORS
Value	Color
0	Black
1	Blue
2	Green
3	Cyan
4	Red
5	Magenta
6	Brown
7	Light Gray
8	Dark Gray
9	Light Blue
10	Light Green
11	Light Cyan
12	Light Red
13	Light Magenta
14	Yellow
15	White
}

const

VGAMODE13H = $0013;
VGAMODE03H = $0003;
VGABASEADDRESS = $a000;
VGABYTES = 64000;

type

TVGA = class
   //Init VGA 13h chunked array of 320*200 64kb memory
   class procedure SetMCGAMode; static;
   //Init VGA 03h dos text mode
   class procedure SetTextMode; static;
   //Fills VGA memory with a RGB byte color
   class procedure ClearingScreen(Color : Byte); static;
   //Slow routine to put color pixel in VGA with at coordinates
   class procedure PutPixel(X,Y : SmallInt; Color : Byte) static;
   //Fast routine to put color pixel in VGA to direct memory access
   class procedure PutPixelMemory(X,Y : SmallInt; Color : Byte; Where : Word) static;
   //Wait for VRetrace this will wait for the electron's V-Scan ends
   class procedure WaitForVRetrace; assembler; static;
end;

class procedure TVGA.SetMCGAMode; static;
begin
 asm
   mov ax, VGAMODE13H
   int 10h
 end;
end;

class procedure TVGA.SetTextMode; static;
begin
 asm
   mov ax, VGAMODE03H //Move 0003h to AX register
   int 10h //Call interrupt 10
 end;
end;

class procedure TVGA.ClearingScreen(Color : Byte); static;
var
 x : Integer;
 VGAPointer : Pointer;
begin
 for x := 0 to VGABYTES do Mem[VGABASEADDRESS:0 + x] := color;
 //FPC doen't support returns of far pointers with mem command.
 //FillChar(Mem[VGABASEADDRESS],VGABYTES,Color);
end;

class procedure TVGA.PutPixel(x,y : SmallInt; Color : Byte); static;
begin
 asm
  mov ah, 0Ch // AH (High bits of a 16 bit register = 0Ch Draws Pixel
  mov al, [Color] // AL (Low bits of a 16 bit register = Specified color
  mov cx, [x] // CX all bytes of 16 bit register = X coord
  mov dx, [y] // DX all bytes of 16 bit register = Y coord
  //mov bx, [1] // BX all bytes of 16 bit register = ? not supported on emulator
  int 10h // Call to INT10h
 end;
end;

class procedure TVGA.PutPixelMemory(X,Y : SmallInt; Color : Byte; Where : Word); static;
begin
 Mem[Where:X+(Y*320)] := Color; //Memory access to Address + X(Byte Pos) + (Y*320)
end;

class procedure TVGA.WaitForVRetrace; assembler; // For pure asm routines
 label
  l1, l2;
 asm
  mov dx, 3DAh //Put 3DAh port of VGA retrace on dx register
  l1 :
   //Wait
   in al, dx //Retrieve input of 3DAh port on AL 8 bits
   and al, 08h //Is 08h ??
   jnz l1
  l2 :
   //Wait again
   in al, dx //Retrieve input of 3DAh port on AL 8 Bits
   and al, 08h //Is 08h ??
   jz l2
end;

var
 x : Integer;
 cont : Boolean;

BEGIN
  randomize;
  TVGA.SetMCGAMode;
  cont := true;
  while cont do
  begin
   TVGA.WaitForVRetrace;
   TVGA.ClearingScreen(0);
   for x := 0 to 512 do
   begin
    TVGA.PutPixelMemory(random(320), random(200), random(255), VGABASEADDRESS);
   end;
   TVGA.WaitForVRetrace;
   if keypressed then
    begin
     case readkey of #27 : cont := false;
    end;
   end;
  end;
  ReadLN;
  TVGA.SetTextMode;
END.
