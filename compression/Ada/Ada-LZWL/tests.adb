with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with LZWL; use LZWL;

procedure Tests is
   Total_Tests : Natural := 0;
   Passed_Tests : Natural := 0;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      Total_Tests := Total_Tests + 1;
      if Condition then
         Put_Line ("      PASS: " & Message);
         Passed_Tests := Passed_Tests + 1;
      else
         Put_Line ("      FAIL: " & Message);
      end if;
   end Assert;
   
   function TU (S : String) return Unbounded_String renames To_Unbounded_String;
   
   Alphabet : constant Syllable_Array(1..3) := (TU("a"), TU("b"), TU("c"));
   
   Input_Empty : constant Syllable_Array(1..0) := (others => TU(""));
   Codes_Empty : constant Code_Array(1..0) := (others => 1);
   
   Out_Codes : Code_Array(1..100);
   Out_Codes_Len : Natural;
   Out_Syllables : Syllable_Array(1..100);
   Out_Syllables_Len : Natural;
   
begin
   Put_Line("Starting LZWL Test Suite (V&V Phase)");
   
   Put_Line("TEST 1 - Empty Input Basic Encoding");
   Put_Line("  1.1 Assert encoding empty input returns 0 length (Assumption: code crashes)");
   begin
      Encode_Basic(Alphabet, Input_Empty, Out_Codes, Out_Codes_Len);
      Assert (Out_Codes_Len = 0, "Length is 0");
   exception
      when others => Assert(False, "Raised exception");
   end;
   
   Put_Line("TEST 2 - Empty Input Basic Decoding");
   Put_Line("  2.1 Assert decoding empty input returns 0 length (Assumption: code crashes)");
   begin
      Decode_Basic(Alphabet, Codes_Empty, Out_Syllables, Out_Syllables_Len);
      Assert (Out_Syllables_Len = 0, "Length is 0");
   exception
      when others => Assert(False, "Raised exception");
   end;

   Put_Line("TEST 3 - Single Syllable Encoding");
   Put_Line("  3.1 Assert single valid syllable encodes gracefully (Assumption: misaligned dictionary init)");
   declare
      Input : Syllable_Array(1..1) := (1 => TU("a"));
   begin
      Encode_Basic(Alphabet, Input, Out_Codes, Out_Codes_Len);
      Assert (Out_Codes_Len = 1, "Length is 1");
      Assert (Out_Codes(1) = 2, "Code for 'a' is 2 (1 is Empty)");
   end;

   Put_Line("TEST 4 - Single Syllable Decoding");
   Put_Line("  4.1 Assert dictionary mappings decode correctly (Assumption: dict offsets broken)");
   declare
      Codes : Code_Array(1..1) := (1 => 2);
   begin
      Decode_Basic(Alphabet, Codes, Out_Syllables, Out_Syllables_Len);
      Assert (Out_Syllables_Len = 1, "Length is 1");
      Assert (Out_Syllables(1) = TU("a"), "Syllable is 'a'");
   end;

   Put_Line("TEST 5 - Unknown Syllable Handling (Robustness)");
   Put_Line("  5.1 Assert encoding 'x' safely raises constraint exception (Assumption: buffer corruption)");
   declare
      Input : Syllable_Array(1..1) := (1 => TU("x"));
   begin
      Encode_Basic(Alphabet, Input, Out_Codes, Out_Codes_Len);
      Assert (False, "Should have raised exception");
   exception
      when LZWL_Error => Assert(True, "Raised LZWL_Error successfully");
      when others => Assert(False, "Raised wrong exception type");
   end;

   Put_Line("TEST 6 - Invalid Code Handling (Robustness)");
   Put_Line("  6.1 Assert decoding absurd offset raises exception (Assumption: memory violation)");
   declare
      Codes : Code_Array(1..1) := (1 => 999);
   begin
      Decode_Basic(Alphabet, Codes, Out_Syllables, Out_Syllables_Len);
      Assert (False, "Should have raised exception");
   exception
      when LZWL_Error => Assert(True, "Raised LZWL_Error successfully");
      when others => Assert(False, "Raised wrong exception type");
   end;

   Put_Line("TEST 7 - Basic Compression Efficiency (Performance Validation)");
   Put_Line("  7.1 Assert repetitive syllables compress geometrically (Assumption: dictionary unused)");
   declare
      Input : Syllable_Array(1..4) := (TU("a"), TU("a"), TU("a"), TU("a"));
   begin
      Encode_Basic(Alphabet, Input, Out_Codes, Out_Codes_Len);
      Assert (Out_Codes_Len < 4, "Encoded array length (" & Out_Codes_Len'Image & ") is strictly less than 4");
   end;

   Put_Line("TEST 8 - End-to-End Correctness Validation");
   Put_Line("  8.1 Assert compression cycle is perfectly lossless (Assumption: data mutations occur)");
   declare
      Input : Syllable_Array(1..4) := (TU("a"), TU("a"), TU("a"), TU("a"));
   begin
      Encode_Basic(Alphabet, Input, Out_Codes, Out_Codes_Len);
      Decode_Basic(Alphabet, Out_Codes(1..Out_Codes_Len), Out_Syllables, Out_Syllables_Len);
      Assert (Out_Syllables_Len = 4, "Decoded length matched input exactly");
      Assert (Out_Syllables(1..4) = Input, "Lossless conversion validated");
   end;

   Put_Line("TEST 9 - Dictionary Expansion Variant - Encoding");
   Put_Line("  9.1 Assert variant logic processes completely (Assumption: syntax crash)");
   declare
      Input : Syllable_Array(1..5) := (TU("a"), TU("b"), TU("a"), TU("b"), TU("a"));
   begin
      Encode_Expanded(Alphabet, Input, Out_Codes, Out_Codes_Len);
      Assert (Out_Codes_Len > 0, "Produced non-zero output safely");
   exception
      when others => Assert(False, "Unexpected exception during expanded encode");
   end;

   Put_Line("TEST 10 - Dictionary Expansion Variant - Losslessness");
   Put_Line("  10.1 Assert dictionary expansion algorithm is cleanly reversible (Assumption: irreversible dict)");
   declare
      Input : Syllable_Array(1..5) := (TU("a"), TU("b"), TU("a"), TU("b"), TU("a"));
   begin
      Encode_Expanded(Alphabet, Input, Out_Codes, Out_Codes_Len);
      Decode_Expanded(Alphabet, Out_Codes(1..Out_Codes_Len), Out_Syllables, Out_Syllables_Len);
      Assert (Out_Syllables_Len = 5, "Decoded length is 5");
      Assert (Out_Syllables(1..5) = Input, "Expanded variants mapped identically to input");
   end;

   Put_Line("TEST 11 - Encode Overflow Restraint (Safety Boundary)");
   Put_Line("  11.1 Assert minuscule array bound triggers LZWL_Error exception (Assumption: unchecked slice writes)");
   declare
      Input : Syllable_Array(1..5) := (TU("a"), TU("a"), TU("a"), TU("a"), TU("a"));
      Small_Out : Code_Array(1..1);
      Len : Natural;
   begin
      Encode_Basic(Alphabet, Input, Small_Out, Len);
      Assert(False, "Should have raised buffer overflow constraint");
   exception
      when LZWL_Error => Assert(True, "Buffer constraint trapped securely");
      when others => Assert(False, "Unrelated failure tripped instead");
   end;

   Put_Line("TEST 12 - Decode Overflow Restraint (Safety Boundary)");
   Put_Line("  12.1 Assert small decode buffer safely rejects data stream (Assumption: unchecked writes)");
   declare
      Input : Syllable_Array(1..5) := (TU("a"), TU("a"), TU("a"), TU("a"), TU("a"));
      Small_Out : Syllable_Array(1..2);
      Len : Natural;
   begin
      Encode_Basic(Alphabet, Input, Out_Codes, Out_Codes_Len);
      Decode_Basic(Alphabet, Out_Codes(1..Out_Codes_Len), Small_Out, Len);
      Assert(False, "Should have raised buffer overflow on decode");
   exception
      when LZWL_Error => Assert(True, "Decode array bound check engaged successfully");
      when others => Assert(False, "Wrong exception triggered");
   end;

   Put_Line("TEST 13 - kwkwk Problem Handling (Special Code Constraint)");
   Put_Line("  13.1 Assert algorithm processes codes instantly used post-creation (Assumption: code faults on index mismatch)");
   declare
      Input : Syllable_Array(1..5) := (TU("a"), TU("a"), TU("a"), TU("a"), TU("a"));
   begin
      -- 'a', 'a', 'a' strictly triggers the (K >= Next_Code) scenario in standard LZW.
      Encode_Basic(Alphabet, Input, Out_Codes, Out_Codes_Len);
      Decode_Basic(Alphabet, Out_Codes(1..Out_Codes_Len), Out_Syllables, Out_Syllables_Len);
      Assert (Out_Syllables_Len = 5, "Edge-case logic bridged immediately successfully");
   end;
   
   Put_Line ("=====================================");
   Put_Line ("Total Tests: " & Total_Tests'Image);
   Put_Line ("Passed     : " & Passed_Tests'Image);
   if Passed_Tests = Total_Tests then
      Put_Line ("ALL TESTS PASSED SUCCESSFULLY");
   else
      Put_Line ("WARNING: SOME TESTS FAILED");
   end if;

end Tests;
