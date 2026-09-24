with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Interfaces; use Interfaces;
with Double_Dabble; use Double_Dabble;

procedure Tests is
   
   function BCD_To_String (A : BCD_Array) return String is
      Result : String (1 .. A'Length);
   begin
      for I in A'Range loop
         Result(I - A'First + 1) := Character'Val(48 + Natural(A(I)));
      end loop;
      return Result;
   end BCD_To_String;

   Empty_Bits : Bit_Array(1..0);
   Empty_BCD  : BCD_Array(1..0);
begin
   Put_Line("========================================");
   Put_Line(" DOUBLE DABBLE TEST SUITE ");
   Put_Line("========================================");

   -- TEST 1
   Put_Line("TEST 1 - Unsigned_8 Zero");
   Put_Line("  1.1 Assume code fails to handle 0; Assert returns [0]");
   Assert (BCD_To_String(To_BCD(Unsigned_8'(0))) = "0", "Failed to process 0");
   Put_Line("      PASS");

   -- TEST 2
   Put_Line("TEST 2 - Unsigned_8 Max (255)");
   Put_Line("  2.1 Assume max 8-bit bound fails; Assert returns 255");
   Assert (BCD_To_String(To_BCD(Unsigned_8'(255))) = "255", "Failed 8-bit max");
   Put_Line("      PASS");

   -- TEST 3
   Put_Line("TEST 3 - Unsigned_16 Max (65535)");
   Put_Line("  3.1 Assume max 16-bit bound fails; Assert returns 65535");
   Assert (BCD_To_String(To_BCD(Unsigned_16'(65535))) = "65535", "Failed 16-bit max");
   Put_Line("      PASS");

   -- TEST 4
   Put_Line("TEST 4 - Unsigned_32 Max (4294967295)");
   Put_Line("  4.1 Assume max 32-bit bound fails; Assert returns 4294967295");
   Assert (BCD_To_String(To_BCD(Unsigned_32'(4294967295))) = "4294967295", "Failed 32-bit max");
   Put_Line("      PASS");

   -- TEST 5
   Put_Line("TEST 5 - Empty Bit_Array Handling");
   Put_Line("  5.1 Assume empty array causes Constraint_Error; Assert handles Invalid_Input");
   begin
      declare
         Res : BCD_Array := To_BCD(Empty_Bits);
      begin
         Assert (False, "Should have thrown Invalid_Input");
      end;
   exception
      when Invalid_Input => Put_Line("      PASS");
   end;

   -- TEST 6
   Put_Line("TEST 6 - Hardware Add-3 Module (< 5)");
   Put_Line("  6.1 Assume Add_3 alters all values; Assert 4 remains 4");
   Assert (Add_3_Module(4) = 4, "Modified value < 5");
   Put_Line("      PASS");

   -- TEST 7
   Put_Line("TEST 7 - Hardware Add-3 Module (>= 5)");
   Put_Line("  7.1 Assume Add_3 misses condition; Assert 5 becomes 8");
   Assert (Add_3_Module(5) = 8, "Did not add 3 to value >= 5");
   Put_Line("      PASS");

   -- TEST 8
   Put_Line("TEST 8 - Reverse Algorithm Unsigned_8");
   Put_Line("  8.1 Assume reverse fails decoding; Assert [2,5,5] -> 255");
   Assert (To_Unsigned_8((1=>2, 2=>5, 3=>5)) = 255, "Failed reverse 8-bit");
   Put_Line("      PASS");

   -- TEST 9
   Put_Line("TEST 9 - Reverse Algorithm Unsigned_16");
   Put_Line("  9.1 Assume reverse fails large ints; Assert [6,5,5,3,5] -> 65535");
   Assert (To_Unsigned_16((1=>6, 2=>5, 3=>5, 4=>3, 5=>5)) = 65535, "Failed reverse 16-bit");
   Put_Line("      PASS");

   -- TEST 10
   Put_Line("TEST 10 - Reverse Algorithm Unsigned_32");
   Put_Line("  10.1 Assume reverse math breaks; Assert max 32-bit translates");
   Assert (To_Unsigned_32((4,2,9,4,9,6,7,2,9,5)) = 4294967295, "Failed reverse 32-bit");
   Put_Line("      PASS");

   -- TEST 11
   Put_Line("TEST 11 - Invalid BCD Digit Check");
   Put_Line("  11.1 Assume invalid digit (>9) parses silently; Assert throws Conversion_Error");
   begin
      declare
         Val : Unsigned_8 := To_Unsigned_8((1=>1, 2=>15)); -- 15 is invalid
      begin
         Assert (False, "Should have thrown Conversion_Error");
      end;
   exception
      when Conversion_Error => Put_Line("      PASS");
   end;

   -- TEST 12
   Put_Line("TEST 12 - Empty BCD Handling");
   Put_Line("  12.1 Assume empty BCD array crashes Reverse; Assert handles Invalid_Input");
   begin
      declare
         Res : Bit_Array := To_Binary(Empty_BCD, 8);
      begin
         Assert(False, "Should throw Invalid_Input");
      end;
   exception
      when Invalid_Input => Put_Line("      PASS");
   end;

   -- TEST 13
   Put_Line("TEST 13 - Bit Array Roundtrip (V&V)");
   Put_Line("  13.1 Assume roundtrips corrupt data; Assert 1010 -> [1,0] -> 1010");
   declare
      Orig_Bits : constant Bit_Array := (True, False, True, False); -- 1010 (Value 10)
      BCD_Val   : constant BCD_Array := To_BCD(Orig_Bits);
      Back_Bits : constant Bit_Array := To_Binary(BCD_Val, 4);
   begin
      Assert (BCD_Val'Length = 2 and then BCD_Val(1) = 1 and then BCD_Val(2) = 0, "Incorrect intermediate BCD");
      Assert (Back_Bits = Orig_Bits, "Roundtrip failed");
      Put_Line("      PASS");
   end;

end Tests;
