pragma Ada_2022;
with Interfaces;
with Checksum_Ones_Complement;
procedure Tests is
   use type Interfaces.Unsigned_16;
   Empty : constant Checksum_Ones_Complement.Byte_Array (1 .. 1) := [0];
   ABC : constant Checksum_Ones_Complement.Byte_Array (1 .. 3) := [97, 98, 99];
begin
   pragma Assert (Checksum_Ones_Complement.Compute (Empty) = 16#FFFF#);
   pragma Assert (Checksum_Ones_Complement.Compute (ABC) = 16#FED9#);
end Tests;
