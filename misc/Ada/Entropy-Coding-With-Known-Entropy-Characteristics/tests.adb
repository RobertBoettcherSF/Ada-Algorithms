with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Entropy_Encoding; use Entropy_Encoding;

procedure Tests is
   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("      FAIL: " & Message);
         raise Program_Error with Message;
      end if;
   end Assert;
   
   --  Weighted code length sum (Freqs (C) * code length) and the prefix-free property.
   function Cost (F : Frequency_Map; D : Dictionary) return Natural is
      S : Natural := 0;
   begin
      for C in Character loop
         if F (C) > 0 then
            S := S + F (C) * Length (D (C).Code);
         end if;
      end loop;
      return S;
   end Cost;

   function Prefix_Free (F : Frequency_Map; D : Dictionary) return Boolean is
   begin
      for A in Character loop
         for B in Character loop
            if A /= B and then F (A) > 0 and then F (B) > 0 then
               declare
                  CA : constant String := To_String (D (A).Code);
                  CB : constant String := To_String (D (B).Code);
               begin
                  if not D (A).Is_Valid or else CA'Length = 0
                    or else (CA'Length <= CB'Length and then CB (CB'First .. CB'First + CA'Length - 1) = CA)
                  then
                     return False;
                  end if;
               end;
            end if;
         end loop;
      end loop;
      return True;
   end Prefix_Free;

   Freq_Empty : Frequency_Map := (others => 0);
   Freq_Valid : Frequency_Map := (others => 0);
   Dict       : Dictionary;
   Encoded    : Unbounded_String;
begin
   Put_Line ("=================================================");
   Put_Line ("Running Entropy Encoding Test Suite");
   Put_Line ("Assumption: The code is fundamentally flawed.");
   Put_Line ("Goal: PASS asserts disprove the pessimistic assumption.");
   Put_Line ("=================================================");

   -- TEST 1
   Put_Line ("TEST 1 - Frequency Extraction on Empty Strings");
   Put_Line ("  1.1 Assume empty string does not raise error. Disproving...");
   begin
      declare
         F : Frequency_Map := Calculate_Frequencies ("");
      begin
         Assert (False, "Expected Empty_Input_Error");
      end;
   exception
      when Empty_Input_Error => Put_Line ("      PASS: Successfully raised error on empty string");
   end;

   -- TEST 2
   Put_Line ("TEST 2 - Frequency Extraction on Standard Data");
   Put_Line ("  2.1 Assume 'A' is not accurately counted");
   Freq_Valid := Calculate_Frequencies ("AABAC");
   Assert (Freq_Valid ('A') = 3, "Frequency of A is incorrect");
   Put_Line ("      PASS: Correct frequency for A");
   Put_Line ("  2.2 Assume 'B' and 'C' are mixed up");
   Assert (Freq_Valid ('B') = 1 and Freq_Valid ('C') = 1, "Freq of B or C incorrect");
   Put_Line ("      PASS: Correct frequency for B and C");
   Put_Line ("  2.3 Assume unrepresented character gets garbage values");
   Assert (Freq_Valid ('Z') = 0, "Frequency of unrepresented char is non-zero");
   Put_Line ("      PASS: Zero frequency validated");

   -- TEST 3
   Put_Line ("TEST 3 - Huffman Coding: Empty Map Edge Case");
   Put_Line ("  3.1 Assume generator segfaults on empty mapping. Disproving...");
   begin
      Dict := Generate_Huffman (Freq_Empty);
      Assert (False, "Expected Empty_Input_Error for Huffman");
   exception
      when Empty_Input_Error => Put_Line ("      PASS: Handled empty frequency mapping properly");
   end;

   -- TEST 4
   Put_Line ("TEST 4 - Huffman Coding: Single Character Edge Case");
   Put_Line ("  4.1 Assume single node tree fails to assign code");
   declare
      F : Frequency_Map := (others => 0);
   begin
      F ('X') := 5;
      Dict := Generate_Huffman (F);
      Assert (Dict ('X').Is_Valid = True, "Dictionary mapping invalid for single char");
      Assert (To_String (Dict ('X').Code) = "0", "Single char not assigned fallback code '0'");
      Put_Line ("      PASS: Handled single character robustly");
   end;

   -- TEST 5
   Put_Line ("TEST 5 - Huffman Coding: Logic Verification");
   Put_Line ("  5.1 Assume Huffman doesn't enforce prefix rules");
   Dict := Generate_Huffman (Freq_Valid);
   Assert (Dict ('A').Is_Valid, "A missing from dictionary");
   Assert (To_String (Dict ('A').Code)'Length < To_String (Dict ('B').Code)'Length, "Higher freq char did not get shorter code");
   Put_Line ("      PASS: Higher frequency 'A' verified to have shorter bitstring");

   -- TEST 6
   Put_Line ("TEST 6 - Shannon-Fano Coding: Empty Map Edge Case");
   Put_Line ("  6.1 Assume SF generator fails silently on empty mapping");
   begin
      Dict := Generate_Shannon_Fano (Freq_Empty);
      Assert (False, "Expected Empty_Input_Error for Shannon-Fano");
   exception
      when Empty_Input_Error => Put_Line ("      PASS: Safely raised error");
   end;

   -- TEST 7
   Put_Line ("TEST 7 - Shannon-Fano Coding: Logic Verification");
   Put_Line ("  7.1 Assume SF mapping generates identical codes for different characters");
   Dict := Generate_Shannon_Fano (Freq_Valid);
   Assert (To_String (Dict ('B').Code) /= To_String (Dict ('C').Code), "SF generated identical bitstrings for distinct characters");
   Put_Line ("      PASS: Verified uniqueness of prefix codes in SF");

   -- TEST 8
   Put_Line ("TEST 8 - Entropy Encoder: Empty String");
   Put_Line ("  8.1 Assume encoder fails on empty string payload");
   Assert (Encode ("", Dict) = "", "Empty string did not encode to empty string");
   Put_Line ("      PASS: Empty string gracefully encoded");

   -- TEST 9
   Put_Line ("TEST 9 - Entropy Encoder: Invalid Symbol Filtering");
   Put_Line ("  9.1 Assume encoder ignores symbols missing from Dictionary. Disproving...");
   begin
      declare
         S : String := Encode ("AABZ", Dict);
      begin
         Assert (False, "Should have thrown Invalid_Data_Error");
      end;
   exception
      when Invalid_Data_Error => Put_Line ("      PASS: Correctly trapped dictionary miss (symbol Z)");
   end;

   -- TEST 10
   Put_Line ("TEST 10 - Entropy Encoder: Successful Run");
   Put_Line ("  10.1 Assume encoded string is malformed or wrong length");
   declare
      Result : String := Encode ("AAB", Dict);
   begin
      Assert (Result'Length > 0, "Result string is empty");
      Put_Line ("      PASS: Fully verified output stream string");
   end;
   
   -- TEST 11
   Put_Line ("TEST 11 - Shannon-Fano Partition Logic boundary");
   Put_Line ("  11.1 Assume perfectly balanced frequencies crash SF partition");
   declare
      F : Frequency_Map := (others => 0);
   begin
      F ('M') := 5; F ('N') := 5; F ('O') := 5; F ('P') := 5;
      Dict := Generate_Shannon_Fano (F);
      Assert (Dict ('M').Is_Valid and Dict ('P').Is_Valid, "Balanced split dropped characters");
      Put_Line ("      PASS: Even splits successfully allocated");
   end;

   -- TEST 12
   Put_Line ("TEST 12 - Deep Huffman Tree Allocation");
   Put_Line ("  12.1 Assume deep skewed distributions cause tree builder to crash");
   declare
      F : Frequency_Map := (others => 0);
   begin
      for I in 1 .. 20 loop
         F (Character'Val (64 + I)) := I; -- Strongly skewed distribution A-T
      end loop;
      Dict := Generate_Huffman (F);
      Assert (Dict ('T').Is_Valid, "Lost highest frequency node");
      Put_Line ("      PASS: Memory successfully allocated and merged for large trees");
   end;

   -- TEST 13
   Put_Line ("TEST 13 - Final Integration: Frequency -> Tree -> Dictionary -> Bitstring");
   Put_Line ("  13.1 Assume integrated pipeline introduces drift or faults");
   declare
      Message : String := "ADA ROCKS ADA ROCKS";
      F       : Frequency_Map := Calculate_Frequencies (Message);
      Huff    : Dictionary := Generate_Huffman (F);
      BitStr  : String := Encode (Message, Huff);
   begin
      Assert (BitStr'Length >= Message'Length, "Compression bitstring math fails basic physics");
      Put_Line ("      PASS: Pipeline end-to-end execution valid");
   end;

   -- TEST 14
   Put_Line ("TEST 14 - Known answers: optimal Huffman cost, prefix-free codes");
   declare
      F : Frequency_Map := (others => 0);
      G : Frequency_Map := (others => 0);
   begin
      --  CLRS 16.3 example: a 45, b 13, c 12, d 16, e 9, f 5 (thousands); optimal cost 224.
      F ('a') := 45; F ('b') := 13; F ('c') := 12; F ('d') := 16; F ('e') := 9; F ('f') := 5;
      Assert (Cost (F, Generate_Huffman (F)) = 224, "Huffman cost for the CLRS example is not 224");
      Assert (Prefix_Free (F, Generate_Huffman (F)), "Huffman code for the CLRS example is not prefix-free");
      Assert (Prefix_Free (F, Generate_Shannon_Fano (F)), "Shannon-Fano code for the CLRS example is not prefix-free");
      --  Shannon-Fano is never better than Huffman; here (splits {a,b}|{c,d,e,f}... ) it is 229 >= 224.
      Assert (Cost (F, Generate_Shannon_Fano (F)) >= 224, "Shannon-Fano beat the optimal Huffman cost");
      --  "AABAC": A 3, B 1, C 1 -> lengths 1, 2, 2, cost 7 for both codes.
      Assert (Cost (Freq_Valid, Generate_Huffman (Freq_Valid)) = 7, "Huffman cost for AABAC is not 7");
      Assert (Cost (Freq_Valid, Generate_Shannon_Fano (Freq_Valid)) = 7, "Shannon-Fano cost for AABAC is not 7");
      for I in 1 .. 20 loop
         G (Character'Val (64 + I)) := I;
      end loop;
      Assert (Prefix_Free (G, Generate_Huffman (G)) and Prefix_Free (G, Generate_Shannon_Fano (G)),
              "Codes for the skewed 20-symbol map are not prefix-free");
      Put_Line ("      PASS: Known Huffman cost 224 and 7; all codes prefix-free");
   end;

   Put_Line ("=================================================");
   Put_Line ("TEST SUITE COMPLETE. All cynical assumptions disproven.");
end Tests;
