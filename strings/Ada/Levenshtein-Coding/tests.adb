with Ada.Text_IO; use Ada.Text_IO;
with Levenshtein_Coding; use Levenshtein_Coding;

procedure Tests is
   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("     FAIL: " & Message);
         raise Program_Error with Message;
      end if;
   end Assert;
begin
   Put_Line ("Starting Levenshtein Validation Suite...");
   Put_Line ("Philosophy: Assuming code is incorrect. Tests PASS if assumptions are disproven.");
   Put_Line ("-------------------------------------------------------------------------");

   Put_Line ("TEST 1 - Functional Correctness: Encode Base Cases");
   Put_Line ("  1.1 Assert Encode(0) = ""0""");
   Assert (To_String (Encode (0)) = "0", "Encode(0) failed");
   Put_Line ("     PASS");
   Put_Line ("  1.2 Assert Encode(1) = ""10""");
   Assert (To_String (Encode (1)) = "10", "Encode(1) failed");
   Put_Line ("     PASS");
   Put_Line ("  1.3 Assert Encode(2) = ""1100""");
   Assert (To_String (Encode (2)) = "1100", "Encode(2) failed");
   Put_Line ("     PASS");

   Put_Line ("TEST 2 - Functional Correctness: Encode Small Integers");
   Put_Line ("  2.1 Assert Encode(3) = ""1101""");
   Assert (To_String (Encode (3)) = "1101", "Encode(3) failed");
   Put_Line ("     PASS");
   Put_Line ("  2.2 Assert Encode(4) = ""1110000""");
   Assert (To_String (Encode (4)) = "1110000", "Encode(4) failed");
   Put_Line ("     PASS");
   Put_Line ("  2.3 Assert Encode(7) = ""1110011""");
   Assert (To_String (Encode (7)) = "1110011", "Encode(7) failed");
   Put_Line ("     PASS");

   Put_Line ("TEST 3 - Functional Correctness: Encode Larger Integers (Wikipedia match)");
   Put_Line ("  3.1 Assert Encode(16) = ""111100000000""");
   Assert (To_String (Encode (16)) = "111100000000", "Encode(16) failed");
   Put_Line ("     PASS");
   Put_Line ("  3.2 Assert Encode(17) = ""111100000001""");
   Assert (To_String (Encode (17)) = "111100000001", "Encode(17) failed");
   Put_Line ("     PASS");

   Put_Line ("TEST 4 - Functional Correctness: Decode Base Cases");
   Put_Line ("  4.1 Assert Decode(""0"") = 0");
   Assert (Decode (To_Bit_String ("0")) = 0, "Decode(0) failed");
   Put_Line ("     PASS");
   Put_Line ("  4.2 Assert Decode(""10"") = 1");
   Assert (Decode (To_Bit_String ("10")) = 1, "Decode(1) failed");
   Put_Line ("     PASS");

   Put_Line ("TEST 5 - Functional Correctness: Decode Small Integers");
   Put_Line ("  5.1 Assert Decode(""1101"") = 3");
   Assert (Decode (To_Bit_String ("1101")) = 3, "Decode(3) failed");
   Put_Line ("     PASS");
   Put_Line ("  5.2 Assert Decode(""1110000"") = 4");
   Assert (Decode (To_Bit_String ("1110000")) = 4, "Decode(4) failed");
   Put_Line ("     PASS");

   Put_Line ("TEST 6 - Robustness: Empty Input Handling");
   Put_Line ("  6.1 Assert Decode("""") raises Invalid_Encoding");
   begin
      declare Dummy : Value_Type := Decode (To_Bit_String (""));
      begin Assert (False, "Expected Invalid_Encoding missing"); end;
   exception
      when Invalid_Encoding => Put_Line ("     PASS");
   end;

   Put_Line ("TEST 7 - Robustness: Missing Terminating Identifier");
   Put_Line ("  7.1 Assert Decode(""111"") raises Invalid_Encoding");
   begin
      declare Dummy : Value_Type := Decode (To_Bit_String ("111"));
      begin Assert (False, "Expected Invalid_Encoding missing"); end;
   exception
      when Invalid_Encoding => Put_Line ("     PASS");
   end;

   Put_Line ("TEST 8 - Robustness: Extraneous Data Detection");
   Put_Line ("  8.1 Assert Decode(""01"") raises Invalid_Encoding");
   begin
      declare Dummy : Value_Type := Decode (To_Bit_String ("01"));
      begin Assert (False, "Expected Invalid_Encoding missing"); end;
   exception
      when Invalid_Encoding => Put_Line ("     PASS");
   end;

   Put_Line ("TEST 9 - Robustness: Extraneous Post-Payload Data");
   Put_Line ("  9.1 Assert Decode(""101"") raises Invalid_Encoding");
   begin
      declare Dummy : Value_Type := Decode (To_Bit_String ("101"));
      begin Assert (False, "Expected Invalid_Encoding missing"); end;
   exception
      when Invalid_Encoding => Put_Line ("     PASS");
   end;

   Put_Line ("TEST 10 - Robustness: Incomplete Payload Sequence");
   Put_Line ("  10.1 Assert Decode(""110"") raises Invalid_Encoding");
   begin
      declare Dummy : Value_Type := Decode (To_Bit_String ("110"));
      begin Assert (False, "Expected Invalid_Encoding missing"); end;
   exception
      when Invalid_Encoding => Put_Line ("     PASS");
   end;

   Put_Line ("TEST 11 - Robustness: Malformed Source Bits");
   Put_Line ("  11.1 Assert To_Bit_String(""102"") raises Constraint_Error");
   begin
      declare Dummy : Bit_String := To_Bit_String ("102");
      begin Assert (False, "Expected Constraint_Error missing"); end;
   exception
      when Constraint_Error => Put_Line ("     PASS");
   end;

   Put_Line ("TEST 12 - Performance & Boundary Check");
   Put_Line ("  12.1 Assert Decode(Encode(1024)) = 1024");
   Assert (Decode (Encode (1024)) = 1024, "Roundtrip 1024 failed");
   Put_Line ("     PASS");
   Put_Line ("  12.2 Assert Decode(Encode(65535)) = 65535");
   Assert (Decode (Encode (65535)) = 65535, "Roundtrip 65535 failed");
   Put_Line ("     PASS");

   Put_Line ("TEST 13 - Side Effects & Idempotence");
   Put_Line ("  13.1 Assert Encode(Decode(""1110010"")) = ""1110010""");
   Assert (To_String (Encode (Decode (To_Bit_String ("1110010")))) = "1110010", "Idempotence failed");
   Put_Line ("     PASS");

   Put_Line ("-------------------------------------------------------------------------");
   Put_Line ("All pessimistic assumptions disproven. Code behaves completely per specification.");
end Tests;
