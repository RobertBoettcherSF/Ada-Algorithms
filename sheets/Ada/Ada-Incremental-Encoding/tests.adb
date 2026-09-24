with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Exceptions; use Ada.Exceptions;
with Ada.Command_Line; use Ada.Command_Line;
with Incremental_Encoding; use Incremental_Encoding;

procedure Tests is

   -- Helper to create Unbounded_String easily
   function S(Str : String) return Unbounded_String is
   begin
      return To_Unbounded_String(Str);
   end S;

   Total_Tests : constant Integer := 14;
   Passed_Tests : Integer := 0;

   procedure Run_Test(Name : String; Logic : access procedure) is
   begin
      Put_Line("Running: " & Name);
      Logic.all;
      Put_Line("      PASS");
      Passed_Tests := Passed_Tests + 1;
   exception
      when E : Assertion_Error =>
         Put_Line("      FAIL (Assertion): " & Exception_Message(E));
      when E : others =>
         Put_Line("      FAIL (Exception): " & Exception_Name(E));
   end Run_Test;

   ---------------------------------------------------------
   -- Test Cases (Proving incorrectness assumptions false)
   ---------------------------------------------------------
   procedure Test_1_Basic_Encoding is
      Input : constant String_Array := (1 => S("word"), 2 => S("work"));
      Encoded : constant Encoded_Array := Encode(Input);
   begin
      Put_Line("  1.1 Assume common prefix is miscalculated (Expected: 3)");
      Assert(Encoded(2).Prefix_Length = 3, "Prefix length should be 3");
      Put_Line("  1.2 Assume suffix is extracted incorrectly (Expected: 'k')");
      Assert(Encoded(2).Suffix = S("k"), "Suffix should be 'k'");
   end;

   procedure Test_2_Basic_Decoding is
      Encoded : constant Encoded_Array := (1 => (0, S("word")), 2 => (3, S("k")));
      Decoded : constant String_Array := Decode(Encoded);
   begin
      Put_Line("  2.1 Assume decoded string does not match original");
      Assert(Decoded(1) = S("word"), "First string mismatch");
      Assert(Decoded(2) = S("work"), "Second string mismatch");
   end;

   procedure Test_3_Empty_Input_Encode is
      Empty_Arr : String_Array(1..0);
   begin
      Put_Line("  3.1 Assume empty input bypasses exception in Encode");
      declare
         Dummy : Encoded_Array := Encode(Empty_Arr);
      begin
         Assert(False, "Should have raised Empty_Input_Error");
      end;
   exception
      when Empty_Input_Error => null; -- PASS
   end;

   procedure Test_4_Empty_Input_Decode is
      Empty_Arr : Encoded_Array(1..0);
   begin
      Put_Line("  4.1 Assume empty input bypasses exception in Decode");
      declare
         Dummy : String_Array := Decode(Empty_Arr);
      begin
         Assert(False, "Should have raised Empty_Input_Error");
      end;
   exception
      when Empty_Input_Error => null; -- PASS
   end;

   procedure Test_5_Single_String_Array is
      Input : constant String_Array := (1 => S("alone"));
      Encoded : constant Encoded_Array := Encode(Input);
   begin
      Put_Line("  5.1 Assume single element array crashes or encodes wrongly");
      Assert(Encoded(1).Prefix_Length = 0, "Prefix must be 0");
      Assert(Encoded(1).Suffix = S("alone"), "Suffix must be full string");
   end;

   procedure Test_6_Completely_Different_Strings is
      Input : constant String_Array := (1 => S("apple"), 2 => S("banana"));
      Encoded : constant Encoded_Array := Encode(Input);
   begin
      Put_Line("  6.1 Assume completely different strings calculate prefix > 0");
      Assert(Encoded(2).Prefix_Length = 0, "Prefix must be 0");
      Assert(Encoded(2).Suffix = S("banana"), "Suffix must be full string");
   end;

   procedure Test_7_Identical_Strings is
      Input : constant String_Array := (1 => S("clone"), 2 => S("clone"));
      Encoded : constant Encoded_Array := Encode(Input);
   begin
      Put_Line("  7.1 Assume identical strings fail to yield empty suffix");
      Assert(Encoded(2).Prefix_Length = 5, "Prefix must be full length");
      Assert(Encoded(2).Suffix = S(""), "Suffix must be empty");
   end;

   procedure Test_8_Empty_String_Elements is
      Input : constant String_Array := (1 => S(""), 2 => S("hello"));
      Encoded : constant Encoded_Array := Encode(Input);
   begin
      Put_Line("  8.1 Assume empty string elements cause bounds errors");
      Assert(Encoded(1).Prefix_Length = 0, "First prefix 0");
      Assert(Encoded(2).Prefix_Length = 0, "Second prefix 0");
      Assert(Encoded(2).Suffix = S("hello"), "Suffix is hello");
   end;

   procedure Test_9_Invalid_First_Element_Decode is
      Encoded : constant Encoded_Array := (1 => (1, S("invalid")));
   begin
      Put_Line("  9.1 Assume decoder accepts non-zero prefix on first element");
      declare
         Dummy : String_Array := Decode(Encoded);
      begin
         Assert(False, "Should raise Invalid_Data_Error");
      end;
   exception
      when Invalid_Data_Error => null; -- PASS
   end;

   procedure Test_10_Invalid_Prefix_Length_Decode is
      Encoded : constant Encoded_Array := (1 => (0, S("a")), 2 => (5, S("b")));
   begin
      Put_Line("  10.1 Assume decoder ignores out-of-bounds prefix lengths");
      declare
         Dummy : String_Array := Decode(Encoded);
      begin
         Assert(False, "Should raise Invalid_Data_Error");
      end;
   exception
      when Invalid_Data_Error => null; -- PASS
   end;

   procedure Test_11_Decreasing_Prefix_Lengths is
      Input : constant String_Array := (1 => S("abcd"), 2 => S("abc"), 3 => S("ab"));
      Encoded : constant Encoded_Array := Encode(Input);
   begin
      Put_Line("  11.1 Assume substrings calculate incorrect lengths");
      Assert(Encoded(2).Prefix_Length = 3, "Should be 3");
      Assert(Encoded(3).Prefix_Length = 2, "Should be 2");
   end;

   procedure Test_12_Special_Characters_And_Spaces is
      Input : constant String_Array := (1 => S("foo bar"), 2 => S("foo baz"));
      Encoded : constant Encoded_Array := Encode(Input);
   begin
      Put_Line("  12.1 Assume spaces/special characters break prefix matcher");
      Assert(Encoded(2).Prefix_Length = 6, "Should match up to 'foo ba'");
      Assert(Encoded(2).Suffix = S("z"), "Suffix is 'z'");
   end;

   procedure Test_13_Case_Sensitivity is
      Input : constant String_Array := (1 => S("Ada"), 2 => S("ada"));
      Encoded : constant Encoded_Array := Encode(Input);
   begin
      Put_Line("  13.1 Assume algorithm is incorrectly case-insensitive");
      Assert(Encoded(2).Prefix_Length = 0, "Case matters, prefix should be 0");
   end;

   procedure Test_14_Symmetry_Property is
      Input : constant String_Array := (1 => S("incremental"), 2 => S("increment"), 3 => S("incognito"));
      Encoded : constant Encoded_Array := Encode(Input);
      Decoded : constant String_Array := Decode(Encoded);
   begin
      Put_Line("  14.1 Assume Encode(Decode(x)) != x (Symmetry broken)");
      Assert(Input(1) = Decoded(1), "Mismatch 1");
      Assert(Input(2) = Decoded(2), "Mismatch 2");
      Assert(Input(3) = Decoded(3), "Mismatch 3");
   end;

begin
   Put_Line("============================================");
   Put_Line(" INCREMENTAL ENCODING - V&V TEST SUITE");
   Put_Line("============================================");
   Run_Test("TEST 1 - Basic Encoding", Test_1_Basic_Encoding'Access);
   Run_Test("TEST 2 - Basic Decoding", Test_2_Basic_Decoding'Access);
   Run_Test("TEST 3 - Empty Input Encode (Edge)", Test_3_Empty_Input_Encode'Access);
   Run_Test("TEST 4 - Empty Input Decode (Edge)", Test_4_Empty_Input_Decode'Access);
   Run_Test("TEST 5 - Single String Array (Edge)", Test_5_Single_String_Array'Access);
   Run_Test("TEST 6 - Completely Different Strings", Test_6_Completely_Different_Strings'Access);
   Run_Test("TEST 7 - Identical Strings", Test_7_Identical_Strings'Access);
   Run_Test("TEST 8 - Empty String Elements", Test_8_Empty_String_Elements'Access);
   Run_Test("TEST 9 - Invalid First Element (Safety)", Test_9_Invalid_First_Element_Decode'Access);
   Run_Test("TEST 10 - Invalid Prefix Length (Safety)", Test_10_Invalid_Prefix_Length_Decode'Access);
   Run_Test("TEST 11 - Decreasing Prefix Lengths", Test_11_Decreasing_Prefix_Lengths'Access);
   Run_Test("TEST 12 - Special Chars & Spaces", Test_12_Special_Characters_And_Spaces'Access);
   Run_Test("TEST 13 - Case Sensitivity", Test_13_Case_Sensitivity'Access);
   Run_Test("TEST 14 - Symmetry Property", Test_14_Symmetry_Property'Access);
   
   Put_Line("============================================");
   Put_Line("Total Passed: " & Integer'Image(Passed_Tests) & " /" & Integer'Image(Total_Tests));
   if Passed_Tests /= Total_Tests then
      Set_Exit_Status (Failure);
   end if;
end Tests;
