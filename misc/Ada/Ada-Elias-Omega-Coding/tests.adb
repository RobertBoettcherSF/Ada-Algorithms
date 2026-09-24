-- tests.adb
-- Standalone test suite with 14 comprehensive tests for Elias Omega Coding.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Exceptions;
with Elias_Omega; use Elias_Omega;

procedure Tests is

   procedure Start_Test (Test_Num : Positive; Name : String) is
   begin
      Put_Line ("TEST " & Positive'Image (Test_Num) & " - " & Name);
   end Start_Test;

   procedure End_Test is
   begin
      Put_Line ("     PASS");
   end End_Test;

   procedure Fail_Test (E : Ada.Exceptions.Exception_Occurrence) is
   begin
      Put_Line ("     FAIL: " & Ada.Exceptions.Exception_Message (E));
      -- Re-raise exception to halt execution if a test fails
      Ada.Exceptions.Reraise_Occurrence (E);
   end Fail_Test;

begin
   Put_Line ("=== Elias Omega Coding Test Suite (14 Tests) ===");

   -- TEST 1
   Start_Test (1, "Encoding Value 1 (Base Case)");
   begin
      Put_Line ("   1.1 Assert Encode(1) produces '0'");
      Assert (To_String (Encode (1)) = "0", "Encode(1) failed");
      Put_Line ("   1.2 Assert Decode('0') returns 1");
      declare
         Idx : Positive := 1;
      begin
         Assert (Decode (Encode (1), Idx) = 1, "Decode('0') failed");
      end;
      End_Test;
   exception
      when E : others => Fail_Test (E);
   end;

   -- TEST 2
   Start_Test (2, "Encoding Value 2");
   begin
      Put_Line ("   2.1 Assert Encode(2) produces '100'");
      Assert (To_String (Encode (2)) = "100", "Encode(2) failed");
      Put_Line ("   2.2 Assert Decode('100') returns 2");
      declare
         Idx : Positive := 1;
         Res : constant Bit_Array := Encode (2);
      begin
         Assert (Decode (Res, Idx) = 2, "Decode('100') failed");
      end;
      End_Test;
   exception
      when E : others => Fail_Test (E);
   end;

   -- TEST 3
   Start_Test (3, "Encoding Value 3");
   begin
      Put_Line ("   3.1 Assert Encode(3) produces '110'");
      Assert (To_String (Encode (3)) = "110", "Encode(3) failed");
      Put_Line ("   3.2 Assert round-trip for 3 succeeds");
      declare
         Idx : Positive := 1;
         Res : constant Bit_Array := Encode (3);
      begin
         Assert (Decode (Res, Idx) = 3, "Round-trip for 3 failed");
      end;
      End_Test;
   exception
      when E : others => Fail_Test (E);
   end;

   -- TEST 4
   Start_Test (4, "Encoding Value 4");
   begin
      Put_Line ("   4.1 Assert Encode(4) produces '101000'");
      Assert (To_String (Encode (4)) = "101000", "Encode(4) failed");
      Put_Line ("   4.2 Assert round-trip for 4 succeeds");
      declare
         Idx : Positive := 1;
         Res : constant Bit_Array := Encode (4);
      begin
         Assert (Decode (Res, Idx) = 4, "Round-trip for 4 failed");
      end;
      End_Test;
   exception
      when E : others => Fail_Test (E);
   end;

   -- TEST 5
   Start_Test (5, "Encoding Value 8");
   begin
      Put_Line ("   5.1 Assert Encode(8) produces '1110000'");
      Assert (To_String (Encode (8)) = "1110000", "Encode(8) failed");
      Put_Line ("   5.2 Assert round-trip for 8 succeeds");
      declare
         Idx : Positive := 1;
         Res : constant Bit_Array := Encode (8);
      begin
         Assert (Decode (Res, Idx) = 8, "Round-trip for 8 failed");
      end;
      End_Test;
   exception
      when E : others => Fail_Test (E);
   end;

   -- TEST 6
   Start_Test (6, "Decoding Round-Trip for Small Integers (1 to 10)");
   begin
      for I in 1 .. 10 loop
         declare
            Enc : constant Bit_Array := Encode (I);
            Idx : Positive := Enc'First;
            Dec : constant Positive := Decode (Enc, Idx);
         begin
            Put_Line ("   6." & Positive'Image (I) & " Round-trip for " & Positive'Image (I));
            Assert (Dec = I, "Round-trip failed for integer " & Positive'Image (I));
         end;
      end loop;
      End_Test;
   exception
      when E : others => Fail_Test (E);
   end;

   -- TEST 7
   Start_Test (7, "Decoding Round-Trip for Larger Integers");
   begin
      declare
         type Int_Array is array (Positive range <>) of Positive;
         Vals : constant Int_Array := (15, 100, 1000, 10000);
      begin
         for V of Vals loop
            declare
               Enc : constant Bit_Array := Encode (V);
               Idx : Positive := Enc'First;
               Dec : constant Positive := Decode (Enc, Idx);
            begin
               Put_Line ("   7.x Round-trip for " & Positive'Image (V));
               Assert (Dec = V, "Large integer round-trip failed");
            end;
         end loop;
      end;
      End_Test;
   exception
      when E : others => Fail_Test (E);
   end;

   -- TEST 8
   Start_Test (8, "Non-Negative Integer Variant (0 .. 5)");
   begin
      for N in 0 .. 5 loop
         declare
            Enc : constant Bit_Array := Encode_Non_Negative (N);
            Idx : Positive := Enc'First;
            Dec : constant Natural := Decode_Non_Negative (Enc, Idx);
         begin
            Put_Line ("   8." & Integer'Image (N) & " Non-negative round-trip for " & Natural'Image (N));
            Assert (Dec = N, "Non-negative round-trip failed");
         end;
      end loop;
      End_Test;
   exception
      when E : others => Fail_Test (E);
   end;

   -- TEST 9
   Start_Test (9, "Signed Integer Variant (Positive Numbers)");
   begin
      for S in 0 .. 5 loop
         declare
            Enc : constant Bit_Array := Encode_Signed (S);
            Idx : Positive := Enc'First;
            Dec : constant Integer := Decode_Signed (Enc, Idx);
         begin
            Put_Line ("   9.x Signed positive round-trip for " & Integer'Image (S));
            Assert (Dec = S, "Signed positive round-trip failed");
         end;
      end loop;
      End_Test;
   exception
      when E : others => Fail_Test (E);
   end;

   -- TEST 10
   Start_Test (10, "Signed Integer Variant (Negative Numbers)");
   begin
      for S in -5 .. -1 loop
         declare
            Enc : constant Bit_Array := Encode_Signed (S);
            Idx : Positive := Enc'First;
            Dec : constant Integer := Decode_Signed (Enc, Idx);
         begin
            Put_Line ("   10.x Signed negative round-trip for " & Integer'Image (S));
            Assert (Dec = S, "Signed negative round-trip failed");
         end;
      end loop;
      End_Test;
   exception
      when E : others => Fail_Test (E);
   end;

   -- TEST 11
   Start_Test (11, "Bit Stream String Conversion Helper");
   begin
      declare
         Sample : constant Bit_Array (1 .. 4) := (One, Zero, One, Zero);
      begin
         Put_Line ("   11.1 Assert To_String converts correctly");
         Assert (To_String (Sample) = "1010", "To_String failed");
      end;
      End_Test;
   exception
      when E : others => Fail_Test (E);
   end;

   -- TEST 12
   Start_Test (12, "Error Handling: Malformed / Truncated Bit Stream");
   begin
      Put_Line ("   12.1 Assert Decoding_Error raised on truncated stream");
      declare
         Bad_Stream : constant Bit_Array (1 .. 1) := (1 => One);
         Idx        : Positive := 1;
         Raised     : Boolean := False;
      begin
         begin
            declare
               Dummy : Positive := Decode (Bad_Stream, Idx);
            begin
               null;
            end;
         exception
            when Decoding_Error =>
               Raised := True;
         end;
         Assert (Raised, "Expected Decoding_Error not raised");
      end;
      End_Test;
   exception
      when E : others => Fail_Test (E);
   end;

   -- TEST 13
   Start_Test (13, "Multiple Sequential Values Decoding");
   begin
      declare
         Enc1     : constant Bit_Array := Encode (2);
         Enc2     : constant Bit_Array := Encode (3);
         Combined : Bit_Array (1 .. Enc1'Length + Enc2'Length);
         Idx      : Positive;
      begin
         Combined (1 .. Enc1'Length) := Enc1;
         Combined (Enc1'Length + 1 .. Combined'Last) := Enc2;
         Idx := Combined'First;

         Put_Line ("   13.1 Decode first value (2)");
         Assert (Decode (Combined, Idx) = 2, "First sequential decode failed");
         Put_Line ("   13.2 Decode second value (3)");
         Assert (Decode (Combined, Idx) = 3, "Second sequential decode failed");
      end;
      End_Test;
   exception
      when E : others => Fail_Test (E);
   end;

   -- TEST 14
   Start_Test (14, "Edge Case: Zero Value Handling in Non-Negative Variant");
   begin
      Put_Line ("   14.1 Assert Encode_Non_Negative(0) encodes correctly");
      declare
         Enc : constant Bit_Array := Encode_Non_Negative (0);
         Idx : Positive := Enc'First;
      begin
         Assert (Decode_Non_Negative (Enc, Idx) = 0, "Zero round-trip failed");
      end;
      End_Test;
   exception
      when E : others => Fail_Test (E);
   end;

   Put_Line ("=== All 14 Tests Passed Successfully! ===");
end Tests;
