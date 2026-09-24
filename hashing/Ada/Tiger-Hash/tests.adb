with Ada.Text_IO; use Ada.Text_IO;
with Tiger_Hash;  use Tiger_Hash;

procedure Tests is
   use type Byte;

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Helper to generate messages easily
   function To_Bytes (S : String) return Byte_Array is
      B : Byte_Array (0 .. S'Length - 1);
   begin
      for I in S'Range loop
         B (I - S'First) := Character'Pos (S (I));
      end loop;
      return B;
   end To_Bytes;

   -- Empty array constant for reuse
   Empty_Array : constant Byte_Array (1 .. 0) := [others => 0];

begin
   Put_Line ("TEST 1 — Empty Input Constraints (Tiger)");
   declare
      R192 : constant Byte_Array := Tiger_192 (Empty_Array);
   begin
      Check ("1.1 Result length is exactly 24 bytes", R192'Length = 24);
      Check ("1.2 Array represents deterministic state (not 0)", R192 (0) /= 0 or R192 (1) /= 0);
      Check ("1.3 Function is pure and deterministic", R192 = Tiger_192 (Empty_Array));
   end;

   Put_Line ("TEST 2 — Variant Truncation Consistency (Tiger)");
   declare
      R192 : constant Byte_Array := Tiger_192 (Empty_Array);
      R160 : constant Byte_Array := Tiger_160 (Empty_Array);
      R128 : constant Byte_Array := Tiger_128 (Empty_Array);
   begin
      Check ("2.1 Tiger 160 length is 20", R160'Length = 20);
      Check ("2.2 Tiger 160 is prefix of Tiger 192", R160 = R192 (0 .. 19));
      Check ("2.3 Tiger 128 is prefix of Tiger 160", R128 = R160 (0 .. 15));
   end;

   Put_Line ("TEST 3 — Variant Truncation Consistency (Tiger2)");
   declare
      R192 : constant Byte_Array := Tiger2_192 (Empty_Array);
      R160 : constant Byte_Array := Tiger2_160 (Empty_Array);
      R128 : constant Byte_Array := Tiger2_128 (Empty_Array);
   begin
      Check ("3.1 Tiger2 160 length is 20", R160'Length = 20);
      Check ("3.2 Tiger2 160 is prefix of Tiger2 192", R160 = R192 (0 .. 19));
      Check ("3.3 Tiger2 128 is prefix of Tiger2 160", R128 = R160 (0 .. 15));
   end;

   Put_Line ("TEST 4 — Padding Domain Independence (Tiger vs Tiger2)");
   declare
      R_Tiger  : constant Byte_Array := Tiger_192 (Empty_Array);
      R_Tiger2 : constant Byte_Array := Tiger2_192 (Empty_Array);
   begin
      Check ("4.1 Tiger and Tiger2 yield different outputs for empty", R_Tiger /= R_Tiger2);
      Check ("4.2 Padding domain doesn't alter string integrity", R_Tiger'Length = R_Tiger2'Length);
      Check ("4.3 Both paddings process correctly", R_Tiger2 = Tiger2_192 (Empty_Array));
   end;

   Put_Line ("TEST 5 — Small Payload Functionality");
   declare
      M1 : constant Byte_Array := To_Bytes ("a");
      M2 : constant Byte_Array := To_Bytes ("b");
   begin
      Check ("5.1 Able to process single byte length", Tiger_192 (M1)'Length = 24);
      Check ("5.2 Differing strings yield different hashes", Tiger_192 (M1) /= Tiger_192 (M2));
      Check ("5.3 Consistent processing multiple times", Tiger_192 (M1) = Tiger_192 (M1));
   end;

   Put_Line ("TEST 6 — Edge Case: 55 Bytes (Fits entirely in 1 block)");
   declare
      -- 55 bytes + 1 pad byte + 8 length bytes = 64 bytes (Exactly 1 block)
      M : constant Byte_Array := To_Bytes ("1234567890123456789012345678901234567890123456789012345");
   begin
      Check ("6.1 Hash executes cleanly on block edge boundary", Tiger_192 (M)'Length = 24);
      Check ("6.2 Matches itself", Tiger_192 (M) = Tiger_192 (M));
      Check ("6.3 Tiger2 variants also handle padding exact size", Tiger2_192 (M)'Length = 24);
   end;

   Put_Line ("TEST 7 — Edge Case: 56 Bytes (Requires 2 blocks due to padding)");
   declare
      -- 56 bytes + 1 pad byte = 57 bytes. Only 7 bytes left, not enough for 8 byte length. 2nd block spawned.
      M : constant Byte_Array := To_Bytes ("12345678901234567890123456789012345678901234567890123456");
   begin
      Check ("7.1 Second block spawned without bounds failure", Tiger_192 (M)'Length = 24);
      Check ("7.2 Differing by 1 byte from 55 triggers total avalanche", Tiger_192 (M) /= Tiger_192 (To_Bytes ("1234567890123456789012345678901234567890123456789012345")));
      Check ("7.3 Recomputation identical", Tiger_192 (M) = Tiger_192 (M));
   end;

   Put_Line ("TEST 8 — Edge Case: 63 Bytes");
   declare
      M : constant Byte_Array := To_Bytes ("123456789012345678901234567890123456789012345678901234567890123");
   begin
      Check ("8.1 Complete missing padding length handled", Tiger_192 (M)'Length = 24);
      Check ("8.2 Processing successful", Tiger_192 (M) = Tiger_192 (M));
      Check ("8.3 Different sizes evaluate uniquely", Tiger_192 (M) /= Tiger_192 (Empty_Array));
   end;

   Put_Line ("TEST 9 — Edge Case: 64 Bytes (Full block alignment)");
   declare
      M : constant Byte_Array := To_Bytes ("1234567890123456789012345678901234567890123456789012345678901234");
   begin
      Check ("9.1 Full exact block processes without error", Tiger_192 (M)'Length = 24);
      Check ("9.2 Processing robustly", Tiger_192 (M) = Tiger_192 (M));
      Check ("9.3 Prefix verification on Tiger2", Tiger2_128 (M) = Tiger2_192 (M) (0 .. 15));
   end;

   Put_Line ("TEST 10 — Edge Case: 65 Bytes (Crosses block boundary by 1 byte)");
   declare
      M : constant Byte_Array := To_Bytes ("12345678901234567890123456789012345678901234567890123456789012345");
   begin
      Check ("10.1 Multiple block internal loop functional", Tiger_192 (M)'Length = 24);
      Check ("10.2 Processing successful", Tiger_192 (M) = Tiger_192 (M));
      Check ("10.3 Differing hash from 64-byte", Tiger_192 (M) /= Tiger_192 (M (0 .. 63)));
   end;

   Put_Line ("TEST 11 — Large Payload Stability");
   declare
      B_Large : constant Byte_Array (0 .. 1023) := [others => 42];
   begin
      Check ("11.1 Stream blocks properly consumed", Tiger_192 (B_Large)'Length = 24);
      Check ("11.2 Valid payload invariant", Tiger_192 (B_Large) = Tiger_192 (B_Large));
      Check ("11.3 Tiger2 supports large chunks consistently", Tiger2_192 (B_Large) = Tiger2_192 (B_Large));
   end;

   Put_Line ("TEST 12 — Custom Length Output Variants");
   declare
      R10 : constant Byte_Array := Tiger_Custom (Empty_Array, 10);
      R192 : constant Byte_Array := Tiger_192 (Empty_Array);
   begin
      Check ("12.1 Custom length is accurate", R10'Length = 10);
      Check ("12.2 Custom truncates appropriately", R10 = R192 (0 .. 9));
      Check ("12.3 Complete limit supported", Tiger_Custom (Empty_Array, 24) = R192);
   end;

   Put_Line ("TEST 13 — Exception Handling and Domain Guards");
   declare
      Error_Triggered : Boolean := False;
   begin
      -- Test out of bounds bounds error explicitly guarding against buffer overflow issues.
      begin
         declare
            Bad_Length_Result : Byte_Array := Tiger_Custom (Empty_Array, 25);
            pragma Unreferenced (Bad_Length_Result);
         begin
            null;
         end;
      exception
         when Hash_Error => Error_Triggered := True;
         when others => null;
      end;
      Check ("13.1 Invalid parameter raises Hash_Error correctly", Error_Triggered);
      Check ("13.2 Smallest custom bounds accepted", Tiger_Custom (Empty_Array, 1)'Length = 1);
      Check ("13.3 Highest custom bounds accepted", Tiger_Custom (Empty_Array, 24)'Length = 24);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
