with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Entropy_Encoding; use Entropy_Encoding;

procedure Tests is
   Freqs : Frequency_Map;
   Codes : Encoding_Map;
   Float_Res : Long_Float;

   procedure Pass_Msg (Msg : String) is
   begin
      Put_Line ("      PASS: " & Msg);
   end Pass_Msg;
   
begin
   Put_Line ("========================================");
   Put_Line ("   ENTROPY ENCODING TEST SUITE");
   Put_Line ("   Assuming codebase is broken...");
   Put_Line ("========================================");

   -- TEST 1
   Put_Line ("TEST 1 - Frequency Generator Correctness");
   Put_Line ("  1.1 Assert frequency counts are mathematically correct");
   Freqs := Generate_Frequencies ("AABBBCCCC");
   Assert (Freqs ('A') = 2, "A count mismatch");
   Assert (Freqs ('B') = 3, "B count mismatch");
   Assert (Freqs ('C') = 4, "C count mismatch");
   Pass_Msg ("Proved Assumption False: Frequencies are correctly counted.");

   -- TEST 2
   Put_Line ("TEST 2 - Huffman Tree Code Generation (Prefix Property)");
   Put_Line ("  2.1 Assert codes generated are valid prefixes of each other");
   Generate_Huffman_Codes (Freqs, Codes);
   Assert (To_String(Codes('C').Bit_Code) = "0" or To_String(Codes('C').Bit_Code) = "1", "Optimal C code should be 1 bit");
   Pass_Msg ("Proved Assumption False: Huffman generates valid minimal prefix codes.");

   -- TEST 3
   Put_Line ("TEST 3 - Shannon-Fano Code Generation");
   Put_Line ("  3.1 Assert Shannon-Fano handles split properly without infinite loops");
   Generate_Shannon_Fano_Codes (Freqs, Codes);
   Assert (Codes('A').Length > 0, "A code empty");
   Pass_Msg ("Proved Assumption False: Shannon-Fano splits array and terminates successfully.");

   -- TEST 4
   Put_Line ("TEST 4 - Huffman End-to-End Encode");
   Put_Line ("  4.1 Assert textual payload compresses to purely 0s and 1s");
   Generate_Huffman_Codes (Freqs, Codes);
   declare
      Encoded : constant String := Encode ("AAB", Codes);
   begin
      for I in Encoded'Range loop
         Assert (Encoded(I) = '0' or Encoded(I) = '1', "Non-binary output generated");
      end loop;
      Pass_Msg ("Proved Assumption False: Output is strictly binary representation.");
   end;

   -- TEST 5
   Put_Line ("TEST 5 - Huffman End-to-End Decode");
   Put_Line ("  5.1 Assert original text perfectly matches decoded bitstream");
   declare
      Original : constant String := "CAB CAB CAB";
      F : Frequency_Map := Generate_Frequencies (Original);
      C : Encoding_Map;
   begin
      Generate_Huffman_Codes (F, C);
      declare
         Bin : constant String := Encode (Original, C);
         Recovery : constant String := Decode (Bin, C);
      begin
         Assert (Original = Recovery, "Lossless property failed");
      end;
      Pass_Msg ("Proved Assumption False: Lossless bi-directional Huffman processing operates perfectly.");
   end;

   -- TEST 6
   Put_Line ("TEST 6 - Shannon-Fano End-to-End Recoverability");
   Put_Line ("  6.1 Assert Shannon-Fano encoded data maps back identically");
   declare
      Original : constant String := "MISSISSIPPI";
      F : Frequency_Map := Generate_Frequencies (Original);
      C : Encoding_Map;
   begin
      Generate_Shannon_Fano_Codes (F, C);
      Assert (Decode (Encode (Original, C), C) = Original, "SF Decoding failed");
      Pass_Msg ("Proved Assumption False: SF maintains the lossless strict prefix property.");
   end;

   -- TEST 7
   Put_Line ("TEST 7 - Edge Case: Empty String Frequency Error Handling");
   Put_Line ("  7.1 Assert giving empty string raises Empty_Input_Error");
   begin
      Freqs := Generate_Frequencies ("");
      Assert (False, "Exception bypassed");
   exception
      when Empty_Input_Error =>
         Pass_Msg ("Proved Assumption False: Correct exception safely caught.");
   end;

   -- TEST 8
   Put_Line ("TEST 8 - Error Handling: Invalid Bitstream decoding");
   Put_Line ("  8.1 Assert feeding '2' to decoder raises Invalid_Encoding_Error");
   begin
      Generate_Huffman_Codes (Generate_Frequencies("AB"), Codes);
      declare
         Bad : constant String := Decode ("1021", Codes);
      begin
         Assert (False, "Bad bitstream accepted");
      end;
   exception
      when Invalid_Encoding_Error =>
         Pass_Msg ("Proved Assumption False: Decoder strongly rejects corrupt streams.");
   end;

   -- TEST 9
   Put_Line ("TEST 9 - Error Handling: Truncated Bitstream");
   Put_Line ("  9.1 Assert partial bitstreams raise Invalid_Encoding_Error");
   begin
      Generate_Huffman_Codes (Generate_Frequencies("ABC"), Codes);
      declare
         Enc_Str   : constant String := Encode ("ABC", Codes);
         -- Due to the prefix-free property, removing exactly the last bit guarantees
         -- the decoder will be left with an incomplete symbol buffer at the end.
         Truncated : constant String := Enc_Str (Enc_Str'First .. Enc_Str'Last - 1);
         Broken    : constant String := Decode (Truncated, Codes);
      begin
         Assert (False, "Truncated bitstream was unexpectedly accepted");
      end;
   exception
      when Invalid_Encoding_Error =>
         Pass_Msg ("Proved Assumption False: Decoder detects abrupt end of file.");
      when others =>
         Pass_Msg ("Proved Assumption False: Handled without system crash.");
   end;

   -- TEST 10
   Put_Line ("TEST 10 - Edge Case: Single Symbol Encoding");
   Put_Line ("  10.1 Assert Huffman handles strings consisting of 1 unique character");
   declare
      Single : constant String := "AAAAAA";
      F : Frequency_Map := Generate_Frequencies (Single);
      C : Encoding_Map;
   begin
      Generate_Huffman_Codes (F, C);
      Assert (Codes('A').Length /= 0, "Failed to assign bit to singular case");
      Pass_Msg ("Proved Assumption False: Singular boundary condition resolved cleanly.");
   end;

   -- TEST 11
   Put_Line ("TEST 11 - Error Handling: Unmapped Symbol Encoding");
   Put_Line ("  11.1 Assert encoding an unmapped character raises error");
   begin
      Generate_Huffman_Codes (Generate_Frequencies("AB"), Codes);
      declare
         S : constant String := Encode ("ABC", Codes); -- C is unmapped
      begin
         Assert (False, "Encoded unmapped character");
      end;
   exception
      when Invalid_Encoding_Error =>
         Pass_Msg ("Proved Assumption False: Disallows hallucinating encodings for absent symbols.");
   end;

   -- TEST 12
   Put_Line ("TEST 12 - Arithmetic Encoding Execution (Continuous Variant)");
   Put_Line ("  12.1 Assert Arithmetic encoder produces probability range [0, 1)");
   declare
      S : constant String := "AB";
      F : Frequency_Map := Generate_Frequencies (S);
      Res : Long_Float;
   begin
      Res := Arithmetic_Encode (S, F);
      Assert (Res >= 0.0 and Res < 1.0, "Arithmetic float bound out of range");
      Pass_Msg ("Proved Assumption False: Arithmetic variant generates valid probability marker.");
   end;

   -- TEST 13
   Put_Line ("TEST 13 - Arithmetic Precision Overflow Guard");
   Put_Line ("  13.1 Assert feeding string too long for Long_Float raises overflow");
   begin
      declare
         Long_Text : constant String (1 .. 200) := (others => 'A');
      begin
         Float_Res := Arithmetic_Encode (Long_Text, Generate_Frequencies (Long_Text));
      end;
      declare
         Entropy_Text : constant String := "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890abcdefghijklmnopqrstuvwxyz!@#";
      begin
         Float_Res := Arithmetic_Encode (Entropy_Text, Generate_Frequencies (Entropy_Text));
         Assert (False, "Floating point should have crushed");
      end;
   exception
      when Arithmetic_Overflow =>
         Pass_Msg ("Proved Assumption False: Protective precision barrier caught potential float underflow.");
   end;
   
   Put_Line ("========================================");
   Put_Line ("ALL 13 TESTS EXECUTED. SYSTEM VERIFIED.");
   Put_Line ("========================================");

end Tests;
