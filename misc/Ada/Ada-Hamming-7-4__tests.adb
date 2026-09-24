-- tests.adb
-- Contains 13+ terminal-executable tests for Hamming(7,4).
-- Philosophy: Code is assumed broken until assertions prove otherwise.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Hamming_7_4; use Hamming_7_4;

procedure Tests is
   Data_In   : Data_Word;
   Data_Out  : Data_Word;
   Code      : Code_Word;
   Err_Found : Boolean;
   Err_Pos   : Natural;
begin
   Put_Line ("Starting Hamming(7,4) Verification & Validation Suite...");
   Put_Line ("------------------------------------------------------");

   -- TEST 1: Systematic Zero Encoding
   Put_Line ("TEST 1 - Systematic Zero Encoding");
   Put_Line ("  1.1 Assert all zero data yields all zero code");
   Data_In := (0, 0, 0, 0);
   Code := Encode (Data_In, Systematic);
   Assert (Code = (0,0,0,0,0,0,0), "Zero encoding failed");
   Put_Line ("      PASS");

   -- TEST 2: Systematic Pattern Encoding
   Put_Line ("TEST 2 - Systematic Pattern Encoding");
   Put_Line ("  2.1 Assert pattern (1,0,1,0) yields expected code and parity");
   Data_In := (1, 0, 1, 0);
   Code := Encode (Data_In, Systematic);
   Assert (Code(1..4) = (1,0,1,0), "Data bits altered in Systematic mode");
   Assert (Code(5..7) = (1,0,1), "Parity generation failed for (1,0,1,0)");
   Put_Line ("      PASS");

   -- TEST 3: Interleaved One Encoding
   Put_Line ("TEST 3 - Interleaved All Ones Encoding");
   Put_Line ("  3.1 Assert (1,1,1,1) generates correct interleaved parity");
   Data_In := (1, 1, 1, 1);
   Code := Encode (Data_In, Interleaved);
   Assert (Code = (1,1,1, 1,1, 1,1), "Interleaved (1,1,1,1) encoding failed");
   Put_Line ("      PASS");

   -- TEST 4: Interleaved Data Mapping Validation
   Put_Line ("TEST 4 - Interleaved Data Mapping Validation");
   Put_Line ("  4.1 Assert data maps exactly to pos 3,5,6,7");
   Data_In := (0, 1, 0, 1);
   Code := Encode (Data_In, Interleaved);
   Assert (Code(3)=0 and Code(5)=1 and Code(6)=0 and Code(7)=1, "Data placement failed");
   Put_Line ("      PASS");

   -- TEST 5: Decoding No Error (Systematic)
   Put_Line ("TEST 5 - Systematic Decode (No Error)");
   Put_Line ("  5.1 Assert untouched code extracts correct data without error flags");
   Data_In := (1, 0, 0, 1);
   Code := Encode (Data_In, Systematic);
   Decode (Code, Data_Out, Err_Found, Err_Pos, Systematic);
   Assert (not Err_Found, "False positive error detected");
   Assert (Err_Pos = 0, "Error position should be 0");
   Assert (Data_In = Data_Out, "Data extraction failed");
   Put_Line ("      PASS");

   -- TEST 6: Single Data Bit Correction (Systematic)
   Put_Line ("TEST 6 - Single Data Bit Correction (Systematic)");
   Put_Line ("  6.1 Assert flipping pos 2 correctly identifies and fixes error");
   Code(2) := Code(2) xor 1; 
   Decode (Code, Data_Out, Err_Found, Err_Pos, Systematic);
   Assert (Err_Found, "Error not detected");
   Assert (Err_Pos = 2, "Wrong error position detected");
   Assert (Data_Out = Data_In, "Data correction failed");
   Put_Line ("      PASS");

   -- TEST 7: Single Parity Bit Correction (Systematic)
   Put_Line ("TEST 7 - Single Parity Bit Correction (Systematic)");
   Put_Line ("  7.1 Assert flipping pos 6 identifies parity error, data stays intact");
   Code := Encode ((1, 1, 0, 0), Systematic);
   Code(6) := Code(6) xor 1;
   Decode (Code, Data_Out, Err_Found, Err_Pos, Systematic);
   Assert (Err_Found, "Parity error not flagged");
   Assert (Err_Pos = 6, "Parity error position wrong");
   Assert (Data_Out = (1, 1, 0, 0), "Parity error affected data extraction");
   Put_Line ("      PASS");

   -- TEST 8: Decoding No Error (Interleaved)
   Put_Line ("TEST 8 - Interleaved Decode (No Error)");
   Put_Line ("  8.1 Assert clean interleaved code decodes cleanly");
   Data_In := (0, 1, 1, 0);
   Code := Encode (Data_In, Interleaved);
   Decode (Code, Data_Out, Err_Found, Err_Pos, Interleaved);
   Assert (not Err_Found and Err_Pos = 0, "False positive in interleaved");
   Put_Line ("      PASS");

   -- TEST 9: Interleaved Parity Bit Correction
   Put_Line ("TEST 9 - Interleaved Parity Bit Correction");
   Put_Line ("  9.1 Assert flipping pos 1 identifies correct syndrome");
   Code(1) := Code(1) xor 1;
   Decode (Code, Data_Out, Err_Found, Err_Pos, Interleaved);
   Assert (Err_Found, "Interleaved pos 1 error not found flag");
   Assert (Err_Pos = 1, "Interleaved pos 1 detection failed");
   Assert (Data_Out = Data_In, "Data corrupt after parity fix");
   Put_Line ("      PASS");

   -- TEST 10: Interleaved Data Bit Correction
   Put_Line ("TEST 10 - Interleaved Data Bit Correction");
   Put_Line ("  10.1 Assert flipping pos 7 identifies correct syndrome");
   Code := Encode (Data_In, Interleaved);
   Code(7) := Code(7) xor 1;
   Decode (Code, Data_Out, Err_Found, Err_Pos, Interleaved);
   Assert (Err_Found, "Interleaved pos 7 error not found flag");
   Assert (Err_Pos = 7, "Interleaved pos 7 detection failed");
   Assert (Data_Out = Data_In, "Pos 7 correction failed");
   Put_Line ("      PASS");

   -- TEST 11: Exhaustive Error Sweep (Systematic)
   Put_Line ("TEST 11 - Exhaustive 1-Bit Error Sweep (Systematic)");
   Put_Line ("  11.1 Assert algorithm corrects EVERY possible 1-bit failure");
   Data_In := (1, 1, 1, 1);
   for I in Code_Word'Range loop
      Code := Encode (Data_In, Systematic);
      Code(I) := Code(I) xor 1;
      Decode (Code, Data_Out, Err_Found, Err_Pos, Systematic);
      Assert (Err_Found, "Failed to flag error at index " & I'Image);
      Assert (Err_Pos = I, "Failed to detect error at index " & I'Image);
      Assert (Data_Out = Data_In, "Failed recovery at index " & I'Image);
   end loop;
   Put_Line ("      PASS");

   -- TEST 12: Exhaustive Error Sweep (Interleaved)
   Put_Line ("TEST 12 - Exhaustive 1-Bit Error Sweep (Interleaved)");
   Put_Line ("  12.1 Assert algorithm corrects EVERY possible 1-bit failure");
   Data_In := (1, 0, 0, 1);
   for I in Code_Word'Range loop
      Code := Encode (Data_In, Interleaved);
      Code(I) := Code(I) xor 1;
      Decode (Code, Data_Out, Err_Found, Err_Pos, Interleaved);
      Assert (Err_Found, "Failed to flag error at index " & I'Image);
      Assert (Err_Pos = I, "Failed to detect error at index " & I'Image);
      Assert (Data_Out = Data_In, "Failed recovery at index " & I'Image);
   end loop;
   Put_Line ("      PASS");

   -- TEST 13: Syndrome Zero Verification
   Put_Line ("TEST 13 - Syndrome Zero Verification");
   Put_Line ("  13.1 Assert Syndrome_To_Int handles (0,0,0) without throwing errors");
   Assert (Syndrome_To_Int ((0,0,0), Interleaved) = 0, "Non-zero for 0 syndrome");
   Assert (Syndrome_To_Int ((0,0,0), Systematic) = 0, "Non-zero for 0 syndrome");
   Put_Line ("      PASS");

   Put_Line ("------------------------------------------------------");
   Put_Line ("ALL 13 TESTS PASSED SUCCESSFULLY.");
end Tests;
