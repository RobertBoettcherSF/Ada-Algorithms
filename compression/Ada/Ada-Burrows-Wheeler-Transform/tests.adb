with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with BWT; use BWT;

procedure Tests is
   Res : BWT_Result;
begin
   Put_Line ("Starting V&V Test Suite for BWT...");
   Put_Line ("Assumption: The code is broken. Proving false via Assertions.");
   Put_Line ("-------------------------------------------------------------");

   -- TEST 1
   Put_Line ("TEST 1 - Index Transform Basic (BANANA)");
   Put_Line ("  1.1 Assert Transform yields correct BWT string (NNBAAA)");
   Res := Transform ("BANANA");
   Assert (To_String(Res.Transformed_String) = "NNBAAA", "Transform string failed");
   Put_Line ("  1.2 Assert Transform yields correct Index (4)");
   Assert (Res.Primary_Index = 4, "Primary index calculation failed");
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Index Inverse Transform Basic");
   Put_Line ("  2.1 Assert Inverse Transform rebuilds original string");
   Assert (Inverse_Transform ("NNBAAA", 4) = "BANANA", "Inverse Transform failed");
   Put_Line ("      PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Index Transform Uniform String (AAAA)");
   Put_Line ("  3.1 Assert handling identical characters without infinite loops");
   Res := Transform ("AAAA");
   Assert (To_String(Res.Transformed_String) = "AAAA", "Uniform string BWT failed");
   Put_Line ("      PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Index Inverse Transform Uniform String");
   Put_Line ("  4.1 Assert uniform string rebuilds correctly");
   Assert (Inverse_Transform ("AAAA", 1) = "AAAA", "Uniform string Inverse failed");
   Put_Line ("      PASS");

   -- TEST 5
   Put_Line ("TEST 5 - Index Transform Empty String");
   Put_Line ("  5.1 Assert empty string safely returns empty result");
   Res := Transform ("");
   Assert (Length(Res.Transformed_String) = 0 and Res.Primary_Index = 0, "Empty handling failed");
   Put_Line ("      PASS");

   -- TEST 6
   Put_Line ("TEST 6 - Index Inverse Transform Empty String");
   Put_Line ("  6.1 Assert empty string rebuilds safely");
   Assert (Inverse_Transform ("", 0) = "", "Empty inverse handling failed");
   Put_Line ("      PASS");

   -- TEST 7
   Put_Line ("TEST 7 - Marker Transform Basic (BANANA, $)");
   Put_Line ("  7.1 Assert marker BWT produces ANNB$AA");
   Assert (Transform_Marker ("BANANA", '$') = "ANNB$AA", "Marker Transform failed");
   Put_Line ("      PASS");

   -- TEST 8
   Put_Line ("TEST 8 - Marker Inverse Transform Basic");
   Put_Line ("  8.1 Assert marker is located and string rebuilt");
   Assert (Inverse_Transform_Marker ("ANNB$AA", '$') = "BANANA", "Marker Inverse failed");
   Put_Line ("      PASS");

   -- TEST 9
   Put_Line ("TEST 9 - Error Handling: Pre-existing Marker");
   Put_Line ("  9.1 Assert Invalid_Marker is raised if input contains marker");
   begin
      declare
         S : constant String := Transform_Marker ("PRICE$10", '$');
         pragma Unreferenced (S);
      begin
         Assert (False, "Expected Invalid_Marker not raised");
      end;
   exception
      when Invalid_Marker => Put_Line ("      PASS");
   end;

   -- TEST 10
   Put_Line ("TEST 10 - Error Handling: Missing Marker in Inverse");
   Put_Line ("  10.1 Assert Marker_Not_Found is raised if missing");
   begin
      declare
         S : constant String := Inverse_Transform_Marker ("BNNNAA", '$');
         pragma Unreferenced (S);
      begin
         Assert (False, "Expected Marker_Not_Found not raised");
      end;
   exception
      when Marker_Not_Found => Put_Line ("      PASS");
   end;

   -- TEST 11
   Put_Line ("TEST 11 - Error Handling: Multiple Markers in Inverse");
   Put_Line ("  11.1 Assert Invalid_Input is raised on multiple markers");
   begin
      declare
         S : constant String := Inverse_Transform_Marker ("A$B$C", '$');
         pragma Unreferenced (S);
      begin
         Assert (False, "Expected Invalid_Input not raised");
      end;
   exception
      when Invalid_Input => Put_Line ("      PASS");
   end;

   -- TEST 12
   Put_Line ("TEST 12 - Error Handling: Out of Bounds Index");
   Put_Line ("  12.1 Assert Invalid_Input raised if Primary_Index > Length");
   begin
      declare
         S : constant String := Inverse_Transform ("BANANA", 999);
         pragma Unreferenced (S);
      begin
         Assert (False, "Expected Invalid_Input not raised");
      end;
   exception
      when Invalid_Input => Put_Line ("      PASS");
   end;

   -- TEST 13
   Put_Line ("TEST 13 - Custom Marker Bound Checks");
   Put_Line ("  13.1 Assert custom marker '#' functions identically");
   Assert (Transform_Marker ("BANANA", '#') = "ANNB#AA", "Custom Marker Transform failed");
   Assert (Inverse_Transform_Marker ("ANNB#AA", '#') = "BANANA", "Custom Marker Inverse failed");
   Put_Line ("      PASS");

   -- TEST 14
   Put_Line ("TEST 14 - Long / Special Character String Payload");
   Put_Line ("  14.1 Assert algorithm scales and preserves whitespace/symbols losslessly");
   declare
      Payload : constant String := "The quick brown fox jumps over 13 lazy dogs! @123";
      Result_Str : constant String := Transform_Marker (Payload, ASCII.ETX);
      Restored   : constant String := Inverse_Transform_Marker (Result_Str, ASCII.ETX);
   begin
      Assert (Payload = Restored, "Long string compression/decompression failed");
   end;
   Put_Line ("      PASS");

   Put_Line ("-------------------------------------------------------------");
   Put_Line ("ALL 14 ASSUMPTIONS OF FAILURE DISPROVED. TESTS PASSED.");
end Tests;
