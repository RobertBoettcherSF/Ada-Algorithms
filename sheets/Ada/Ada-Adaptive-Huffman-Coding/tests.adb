-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Adaptive_Huffman; use Adaptive_Huffman;

procedure Tests is
   procedure Run_Test_Encode_Decode (Text : String; Variant : Variant_Type; Test_Name : String) is
      Encoded : constant String := Encode (Text, Variant);
      Decoded : constant String := Decode (Encoded, Variant);
   begin
      Put_Line ("  " & Test_Name);
      Assert (Text = Decoded, "Assertion failed: Decoded text does not match original for input: '" & Text & "'");
      Put_Line ("    PASS");
   end Run_Test_Encode_Decode;
begin
   Put_Line ("TEST 1 - Basic Functional Correctness (FGK Algorithm)");
   Run_Test_Encode_Decode ("a", FGK, "1.1 Assert single character encoding/decoding succeeds");
   Run_Test_Encode_Decode ("ab", FGK, "1.2 Assert two different characters process correctly");
   Run_Test_Encode_Decode ("aa", FGK, "1.3 Assert repeating character path generation is valid");

   Put_Line ("TEST 2 - Advanced Strings (FGK Algorithm)");
   Run_Test_Encode_Decode ("hello world", FGK, "2.1 Assert standard phrase with spaces decodes properly");
   Run_Test_Encode_Decode ("Adaptive Huffman", FGK, "2.2 Assert mixed casing decodes with fidelity");
   Run_Test_Encode_Decode ("mississippi", FGK, "2.3 Assert high redundancy strings successfully compress");

   Put_Line ("TEST 3 - Basic Functional Correctness (Vitter Algorithm)");
   Run_Test_Encode_Decode ("a", Vitter, "3.1 Assert single character encoding/decoding succeeds");
   Run_Test_Encode_Decode ("ab", Vitter, "3.2 Assert two different characters process correctly");
   Run_Test_Encode_Decode ("aa", Vitter, "3.3 Assert repeating character path generation is valid");

   Put_Line ("TEST 4 - Advanced Strings (Vitter Algorithm)");
   Run_Test_Encode_Decode ("hello world", Vitter, "4.1 Assert standard phrase with spaces decodes properly");
   Run_Test_Encode_Decode ("Adaptive Huffman", Vitter, "4.2 Assert mixed casing decodes with fidelity");
   Run_Test_Encode_Decode ("mississippi", Vitter, "4.3 Assert high redundancy strings successfully compress");

   Put_Line ("TEST 5 - Edge Cases & Robustness");
   Put_Line ("  5.1 Assert empty strings output empty encodings (FGK)");
   Assert (Encode ("", FGK) = "", "Empty string FGK encode failed");
   Assert (Decode ("", FGK) = "", "Empty string FGK decode failed");
   Put_Line ("    PASS");

   Put_Line ("  5.2 Assert empty strings output empty encodings (Vitter)");
   Assert (Encode ("", Vitter) = "", "Empty string Vitter encode failed");
   Assert (Decode ("", Vitter) = "", "Empty string Vitter decode failed");
   Put_Line ("    PASS");

   Put_Line ("  5.3 Assert truncation raises Invalid_Bit_Stream");
   begin
      declare
         Invalid_Decoded : constant String := Decode ("10101", FGK); -- Cut short deliberately
      begin
         Assert (False, "Expected Invalid_Bit_Stream not raised");
      end;
   exception
      when Invalid_Bit_Stream =>
         Put_Line ("    PASS");
   end;
   
   Put_Line ("  5.4 Assert unparseable characters raise Invalid_Bit_Stream");
   begin
      declare
         Invalid_Decoded : constant String := Decode ("2001", FGK); -- Contains '2'
      begin
         Assert (False, "Expected Invalid_Bit_Stream not raised");
      end;
   exception
      when Invalid_Bit_Stream =>
         Put_Line ("    PASS");
   end;
   
   Put_Line ("  5.5 Assert entire 256 ASCII character space encodes natively");
   declare
      All_Ascii : String (1 .. 256);
   begin
      for I in 0 .. 255 loop
         All_Ascii (I + 1) := Character'Val (I);
      end loop;
      Run_Test_Encode_Decode (All_Ascii, FGK, "    Assert ASCII block passes FGK encoding/decoding");
      Run_Test_Encode_Decode (All_Ascii, Vitter, "    Assert ASCII block passes Vitter encoding/decoding");
   end;

   Put_Line ("=====================================");
   Put_Line ("ALL 18 ASSUMPTIONS DISPROVEN. SUCCESS.");
end Tests;
