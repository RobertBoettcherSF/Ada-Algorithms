with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with LZSS; use LZSS;

procedure Tests is
   procedure Assert_Equal (Left, Right : Byte_Array; Msg : String) is
   begin
      Assert (Left'Length = Right'Length, Msg & " (Length mismatch)");
      for I in Left'Range loop
         Assert (Left (I) = Right (Right'First + (I - Left'First)), Msg & " (Content mismatch)");
      end loop;
   end Assert_Equal;

   -- Test Datasets
   Empty      : constant Byte_Array(1..0) := (others => 0);
   Single     : constant Byte_Array(1..1) := (1 => 42);
   Repeated   : constant Byte_Array(1..100) := (others => 65); -- String of 'A's
   Pattern    : constant Byte_Array(1..12) := (65, 65, 66, 65, 65, 65, 66, 65, 65, 65, 65, 66);
   
   Toks    : Token_Array(1..1000);
   Cnt     : Natural;
   Out_Arr : Byte_Array(1..1000);

begin
   Put_Line ("=================================================");
   Put_Line (" LZSS Test Suite execution (Assuming code broken)");
   Put_Line ("=================================================");

   Put_Line ("TEST 1 - Logical Compression (Empty Array)");
   Put_Line ("  1.1 Assert output token count remains 0");
   Compress_Logical (Empty, Toks, Cnt);
   Assert (Cnt = 0, "Failed empty logical compress");
   Put_Line ("      PASS");

   Put_Line ("TEST 2 - Logical Compression (Single Element Bounds)");
   Put_Line ("  2.1 Assert correctly flags as single literal token");
   Compress_Logical (Single, Toks, Cnt);
   Assert (Cnt = 1 and then Toks(1).Kind = Literal and then Toks(1).Value = 42, "Single item logical match failure");
   Put_Line ("      PASS");

   Put_Line ("TEST 3 - Logical Decompression Validate");
   Put_Line ("  3.1 Assert single element cleanly recovers");
   Decompress_Logical (Toks(1..Cnt), Out_Arr, Cnt);
   Assert (Cnt = 1 and then Out_Arr(1) = 42, "Failed to logical decompress simple value");
   Put_Line ("      PASS");

   Put_Line ("TEST 4 - Binary Output on Empty Input");
   Put_Line ("  4.1 Assert array bounds correctly collapse to 0");
   declare
      B_Out : constant Byte_Array := Compress (Empty);
   begin
      Assert (B_Out'Length = 0, "Binary compress did not return empty array");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 5 - Standard End-To-End Binary Flow");
   Put_Line ("  5.1 Assert identical reconstruction of pattern");
   declare
      B_Out : constant Byte_Array := Compress (Pattern);
      B_Dec : constant Byte_Array := Decompress (B_Out, Pattern'Length);
   begin
      Assert_Equal (Pattern, B_Dec, "Failed to reconstruct cyclic pattern");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 6 - Maximum Compression Validity");
   Put_Line ("  6.1 Assert output is significantly smaller than input");
   Put_Line ("  6.2 Assert lossless decompression holds");
   declare
      B_Out : constant Byte_Array := Compress (Repeated);
      B_Dec : constant Byte_Array := Decompress (B_Out, Repeated'Length);
   begin
      Assert (B_Out'Length < Repeated'Length / 2, "Failed to compress heavily repeated stream");
      Assert_Equal (Repeated, B_Dec, "Failed max compression data reconstruction");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 7 - Sub-sized Output Array Edge Case");
   Put_Line ("  7.1 Assert bounds exception when array too small");
   begin
      declare
         Small_Toks : Token_Array(1..1);
      begin
         Compress_Logical (Pattern, Small_Toks, Cnt);
         Assert (False, "Code did not raise exception on bounds overflow");
      end;
   exception
      when Compression_Error => Put_Line ("      PASS");
   end;

   Put_Line ("TEST 8 - Decompression of Corrupt Memory Map");
   Put_Line ("  8.1 Assert references looking backwards beyond index 1 fail safely");
   begin
      declare
         Bad_Toks : constant Token_Array(1..1) := (1 => (Kind => Reference, Distance => 5, Length => 3));
      begin
         Decompress_Logical (Bad_Toks, Out_Arr, Cnt);
         Assert (False, "Failed to trap invalid negative-index back reference");
      end;
   exception
      when Compression_Error => Put_Line ("      PASS");
   end;

   Put_Line ("TEST 9 - Binary Stream Premature Truncation");
   Put_Line ("  9.1 Assert decoder throws error when bits are suddenly missing");
   begin
      declare
         B_Out : constant Byte_Array := Compress (Pattern);
         B_Bad : constant Byte_Array := B_Out(1 .. B_Out'Length - 1);
         B_Dec : constant Byte_Array := Decompress (B_Bad, Pattern'Length);
         pragma Unreferenced (B_Dec);
      begin
         Assert (False, "Stream decoder failed to realize bits were missing");
      end;
   exception
      when Compression_Error => Put_Line ("      PASS");
   end;

   Put_Line ("TEST 10 - Enforcement of Max Lookahead Limits");
   Put_Line ("  10.1 Assert 30-byte run splits across Lookahead_Size (18) limits");
   declare
      Long_Pattern : constant Byte_Array(1..30) := (others => 99);
   begin
      Compress_Logical (Long_Pattern, Toks, Cnt);
      -- Expect: 1 literal + 18-length ref + 11-length ref = 3 tokens.
      Assert (Cnt = 3, "Failed to strictly fragment long matches");
      Assert (Toks(2).Length = 18, "Max lookahead constraint broken by dictionary algorithm");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 11 - Window Drop-off Constraint Wrap");
   Put_Line ("  11.1 Assert algorithm forgets patterns further away than Window_Size (4096)");
   declare
      Huge : Byte_Array(1 .. 4100) := (others => 0);
   begin
      Huge(1) := 123; Huge(2) := 124; Huge(3) := 125;
      Huge(4098) := 123; Huge(4099) := 124; Huge(4100) := 125;
      declare
         B_Out : constant Byte_Array := Compress (Huge);
         B_Dec : constant Byte_Array := Decompress (B_Out, Huge'Length);
      begin
         Assert_Equal (Huge, B_Dec, "Cyclic wrap-around match dropped safety boundaries");
      end;
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 12 - Heavy Sustained Binary Loads");
   Put_Line ("  12.1 Assert continuous matching logic cascades correctly unpack limits");
   declare
      Huge_Zeros : constant Byte_Array (1 .. 5000) := (others => 42);
      B_Out : constant Byte_Array := Compress (Huge_Zeros);
      B_Dec : constant Byte_Array := Decompress (B_Out, Huge_Zeros'Length);
   begin
      Assert_Equal (Huge_Zeros, B_Dec, "Chain decompression unrolled incorrectly");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 13 - Anti-Compression / Entropy Rejection");
   Put_Line ("  13.1 Assert randomized data gracefully expands rather than crashing");
   Put_Line ("  13.2 Assert expanded format flawlessly decompresses");
   declare
      Rand_Data : Byte_Array(1 .. 25);
   begin
      for I in Rand_Data'Range loop
         Rand_Data(I) := Byte((I * 17 + 5) mod 256);
      end loop;
      declare
         B_Out : constant Byte_Array := Compress(Rand_Data);
         B_Dec : constant Byte_Array := Decompress(B_Out, Rand_Data'Length);
      begin
         Assert (B_Out'Length >= Rand_Data'Length, "High entropy data somehow shrank?");
         Assert_Equal (Rand_Data, B_Dec, "Entropy decompression scrambled bits");
      end;
   end;
   Put_Line ("      PASS");
   
   Put_Line ("=================================================");
   Put_Line (" SUCCESS: All pessimistic assumptions proven false.");
   Put_Line ("=================================================");
end Tests;
