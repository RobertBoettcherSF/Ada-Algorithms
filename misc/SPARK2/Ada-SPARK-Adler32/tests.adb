pragma Ada_2022;
with Interfaces;
with Adler32;
with Own_Checks;
procedure Tests is
   use type Interfaces.Unsigned_32;
   Empty : constant Adler32.Byte_Array (1 .. 1) := [0];
   ABC : constant Adler32.Byte_Array (1 .. 3) := [97, 98, 99];
   ABC5 : constant Adler32.Byte_Array (5 .. 7) := [97, 98, 99];
   ABC200 : constant Adler32.Byte_Array (200 .. 202) := [97, 98, 99];
   ABC_Top : constant Adler32.Byte_Array (Positive'Last - 2 .. Positive'Last) :=
     [97, 98, 99];
   Empty_At_9 : constant Adler32.Byte_Array (9 .. 8) := [others => 0];
   Zero_At_1 : constant Adler32.Byte_Array (1 .. 0) := [others => 0];
begin
   pragma Assert (Adler32.Compute (Empty) = 16#0001_0001#);
   pragma Assert (Adler32.Compute (ABC) = 16#024D_0127#);
   --  First-relative: the same bytes at any origin give the same value
   --  (origins 1, 5, 200 and storage ending at Positive'Last).
   pragma Assert (Adler32.Compute (ABC5) = 16#024D_0127#);
   pragma Assert (Adler32.Compute (ABC200) = 16#024D_0127#);
   pragma Assert (Adler32.Compute (ABC_Top) = 16#024D_0127#);
   pragma Assert (Adler32.Compute (Empty_At_9) = Adler32.Compute (Zero_At_1));
   Own_Checks;
end Tests;
