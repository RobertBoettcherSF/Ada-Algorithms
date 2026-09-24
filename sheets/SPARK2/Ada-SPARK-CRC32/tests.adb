pragma Ada_2022;
with Interfaces;
with CRC32;
procedure Tests is
   use type Interfaces.Unsigned_32;
   Empty : constant CRC32.Byte_Array (1 .. 1) := [0];
   ABC : constant CRC32.Byte_Array (1 .. 3) := [97, 98, 99];
begin
   pragma Assert (CRC32.Compute (Empty) = 16#D202_EF8D#);
   pragma Assert (CRC32.Compute (ABC) = 16#3524_41C2#);
end Tests;
