pragma Ada_2022;
with Interfaces;
with XOR_Operation_In_An_Array;
procedure Tests is
   use type Interfaces.Unsigned_32;
   use XOR_Operation_In_An_Array;
begin
   pragma Assert (Compute (0, 0) = 0);
   pragma Assert (Compute (0, 5) = 8);
   pragma Assert (Compute (10, 4) = 24);
end Tests;
