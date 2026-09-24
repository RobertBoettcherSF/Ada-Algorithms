with Ada.Assertions; use Ada.Assertions;
with Reversed_Bits; use Reversed_Bits;

procedure Tests is
begin
   Assert (Reversed (Byte (0)) = Byte (0));
   Assert (Reversed (Byte (1)) = Byte (128));
   Assert (Reversed (Byte (2)) = Byte (64));
   Assert (Reversed (Byte (16#96#)) = Byte (16#69#));
   Assert (Reversed (Byte (16#FF#)) = Byte (16#FF#));
end Tests;
