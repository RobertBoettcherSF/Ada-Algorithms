pragma Ada_2022;
with Interfaces;
with CRC32;
procedure Tests is
   use type Interfaces.Unsigned_32;
   Empty : constant CRC32.Byte_Array (1 .. 1) := [0];
   ABC : constant CRC32.Byte_Array (1 .. 3) := [97, 98, 99];
   ABC5 : constant CRC32.Byte_Array (5 .. 7) := [97, 98, 99];
   ABC200 : constant CRC32.Byte_Array (200 .. 202) := [97, 98, 99];
   ABC_Top : constant CRC32.Byte_Array (Positive'Last - 2 .. Positive'Last) :=
     [97, 98, 99];
   Empty_At_9 : constant CRC32.Byte_Array (9 .. 8) := [others => 0];
   Zero_At_1 : constant CRC32.Byte_Array (1 .. 0) := [others => 0];
begin
   pragma Assert (CRC32.Compute (Empty) = 16#D202_EF8D#);
   pragma Assert (CRC32.Compute (ABC) = 16#3524_41C2#);
   --  First-relative: the same bytes at any origin give the same value
   --  (origins 1, 5, 200 and storage ending at Positive'Last).
   pragma Assert (CRC32.Compute (ABC5) = 16#3524_41C2#);
   pragma Assert (CRC32.Compute (ABC200) = 16#3524_41C2#);
   pragma Assert (CRC32.Compute (ABC_Top) = 16#3524_41C2#);
   pragma Assert (CRC32.Compute (Empty_At_9) = CRC32.Compute (Zero_At_1));
end Tests;
