with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with LZJB; use LZJB;

procedure Tests is
   procedure Put_Pass is
   begin
      Put_Line ("      PASS");
   end Put_Pass;

   -- Test Datasets
   Empty_Array : constant Byte_Array(1..0) := (others => 0);
   Small_Array : constant Byte_Array := (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
   Repeating_Array : Byte_Array(1..150) := (others => 42);
   
   -- Helper to create cyclic patterns (e.g. 0,1,2...14,0,1,2)
   function Create_Pattern return Byte_Array is
      Res : Byte_Array(1..300);
   begin
      for I in Res'Range loop
         Res(I) := Byte(I mod 15);
      end loop;
      return Res;
   end Create_Pattern;
   Pattern_Array : constant Byte_Array := Create_Pattern;

begin
   Put_Line ("Starting LZJB V&V Test Suite...");

   -- TEST 1 - Empty Input Handling
   Put_Line ("TEST 1 - Empty Input Handling");
   Put_Line ("  1.1 Assert compressing empty array returns empty array");
   Assert (Compress(Empty_Array)'Length = 0, "Compression of empty array failed");
   Put_Pass;

   Put_Line ("  1.2 Assert decompressing empty array with size 0 returns empty array");
   Assert (Decompress(Empty_Array, 0)'Length = 0, "Decompression of empty array failed");
   Put_Pass;

   Put_Line ("  1.3 Assert decompressing empty array with size > 0 raises LZJB_Error");
   begin
      declare
         Res : Byte_Array := Decompress(Empty_Array, 10);
      begin
         Assert (False, "Expected LZJB_Error for empty input with positive expected size");
      end;
   exception
      when LZJB_Error => Put_Pass;
   end;

   -- TEST 2 - Small Uncompressible Data (Literals)
   Put_Line ("TEST 2 - Small Uncompressible Data (Literals)");
   Put_Line ("  2.1 Assert small non-repeating data compresses successfully");
   declare
      Comp : constant Byte_Array := Compress(Small_Array);
   begin
      Assert (Comp'Length > 0, "Compressed small data is empty");
      Put_Pass;

      Put_Line ("  2.2 Assert decompressed small data matches original");
      declare
         Decomp : constant Byte_Array := Decompress(Comp, Small_Array'Length);
      begin
         Assert (Decomp = Small_Array, "Decompressed data doesn't match original");
         Put_Pass;
      end;
      
      Put_Line ("  2.3 Assert compressed size matches expectations (payload + 2 control bytes)");
      Assert (Comp'Length = 12, "Compressed size for literals-only is incorrect");
      Put_Pass;
   end;

   -- TEST 3 - Highly Compressible Data (RLE Behavior)
   Put_Line ("TEST 3 - Highly Compressible Data (Repeating Bytes)");
   declare
      Comp : constant Byte_Array := Compress(Repeating_Array);
   begin
      Put_Line ("  3.1 Assert compression significantly reduces size of repeating bytes");
      Assert (Comp'Length < Repeating_Array'Length / 2, "Compression ratio too low for repeating bytes");
      Put_Pass;

      Put_Line ("  3.2 Assert decompression restores repeating data exactly");
      declare
         Decomp : constant Byte_Array := Decompress(Comp, Repeating_Array'Length);
      begin
         Assert (Decomp = Repeating_Array, "Decompressed repeating data corrupt");
         Put_Pass;
      end;
   end;

   -- TEST 4 - Pattern Data
   Put_Line ("TEST 4 - Pattern Data (Repeated Sequences)");
   declare
      Comp : constant Byte_Array := Compress(Pattern_Array);
   begin
      Put_Line ("  4.1 Assert compressed size is reduced for sequence patterns");
      Assert (Comp'Length < Pattern_Array'Length, "Compression failed to reduce pattern data");
      Put_Pass;

      Put_Line ("  4.2 Assert decompression restores patterns identically");
      declare
         Decomp : constant Byte_Array := Decompress(Comp, Pattern_Array'Length);
      begin
         Assert (Decomp = Pattern_Array, "Decompressed pattern data corrupt");
         Put_Pass;
      end;
   end;

   -- TEST 5 - Error Handling & Boundary Limits
   Put_Line ("TEST 5 - Error Handling & Boundary Limits");
   declare
      Comp : Byte_Array := Compress(Repeating_Array);
   begin
      Put_Line ("  5.1 Assert undersized Expected_Size raises LZJB_Error");
      begin
         declare
            Decomp : Byte_Array := Decompress(Comp, Repeating_Array'Length - 5);
         begin
            Assert (False, "Expected LZJB_Error when expected size is too small");
         end;
      exception
         when LZJB_Error => Put_Pass;
      end;

      Put_Line ("  5.2 Assert oversized Expected_Size raises LZJB_Error");
      begin
         declare
            Decomp : Byte_Array := Decompress(Comp, Repeating_Array'Length + 5);
         begin
            Assert (False, "Expected LZJB_Error when expected size is too large");
         end;
      exception
         when LZJB_Error => Put_Pass;
      end;

      Put_Line ("  5.3 Assert truncated compressed stream raises LZJB_Error");
      begin
         declare
            Truncated : constant Byte_Array := Comp(Comp'First .. Comp'Last - 1);
            Decomp : Byte_Array := Decompress(Truncated, Repeating_Array'Length);
         begin
            Assert (False, "Expected LZJB_Error for truncated stream");
         end;
      exception
         when LZJB_Error => Put_Pass;
      end;
   end;

   -- TEST 6 - State Independence
   Put_Line ("TEST 6 - State and Memory Independence");
   Put_Line ("  6.1 Assert multiple sequential compressions do not leak state");
   declare
      C1 : constant Byte_Array := Compress(Small_Array);
      C2 : constant Byte_Array := Compress(Small_Array);
   begin
      Assert (C1 = C2, "Sequential compressions of same data yield different results");
      Put_Pass;
   end;

   Put_Line ("All 14 assertions verified. LZJB implementation proven functional.");
end Tests;
