pragma Ada_2022;
with Interfaces;
with Checksum_Ones_Complement;
procedure Tests is
   use type Interfaces.Unsigned_16;
   Empty : constant Checksum_Ones_Complement.Byte_Array (1 .. 1) := [0];
   ABC : constant Checksum_Ones_Complement.Byte_Array (1 .. 3) := [97, 98, 99];
   ABC5 : constant Checksum_Ones_Complement.Byte_Array (5 .. 7) := [97, 98, 99];
   ABC200 : constant Checksum_Ones_Complement.Byte_Array (200 .. 202) := [97, 98, 99];
   ABC_Top : constant Checksum_Ones_Complement.Byte_Array (Positive'Last - 2 .. Positive'Last) :=
     [97, 98, 99];
   Empty_At_9 : constant Checksum_Ones_Complement.Byte_Array (9 .. 8) := [others => 0];
   Zero_At_1 : constant Checksum_Ones_Complement.Byte_Array (1 .. 0) := [others => 0];
begin
   pragma Assert (Checksum_Ones_Complement.Compute (Empty) = 16#FFFF#);
   pragma Assert (Checksum_Ones_Complement.Compute (ABC) = 16#FED9#);
   --  First-relative: the same bytes at any origin give the same value
   --  (origins 1, 5, 200 and storage ending at Positive'Last).
   pragma Assert (Checksum_Ones_Complement.Compute (ABC5) = 16#FED9#);
   pragma Assert (Checksum_Ones_Complement.Compute (ABC200) = 16#FED9#);
   pragma Assert (Checksum_Ones_Complement.Compute (ABC_Top) = 16#FED9#);
   pragma Assert (Checksum_Ones_Complement.Compute (Empty_At_9) = Checksum_Ones_Complement.Compute (Zero_At_1));
end Tests;
