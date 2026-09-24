pragma Ada_2022;
with Interfaces;
with Adler32;
procedure Tests is
   use type Interfaces.Unsigned_32;
   Empty : constant Adler32.Byte_Array (1 .. 1) := [0];
   ABC : constant Adler32.Byte_Array (1 .. 3) := [97, 98, 99];
begin
   pragma Assert (Adler32.Compute (Empty) = 16#0001_0001#);
   pragma Assert (Adler32.Compute (ABC) = 16#024D_0127#);
end Tests;
