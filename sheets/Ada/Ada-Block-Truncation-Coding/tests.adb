with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Block_Truncation_Coding; use Block_Truncation_Coding;

procedure Tests is
   
   -- Helper Data Setup
   Uniform_Block   : constant Block_4x4 := (others => (others => 100));
   Two_Tone_Block  : constant Block_4x4 := (1..2 => (others => 50), 3..4 => (others => 150));
   Outlier_Block   : Block_4x4 := (others => (others => 10));
   Max_Var_Block   : constant Block_4x4 := (1..2 => (others => 0), 3..4 => (others => 255));
   
   Encoded_Result  : BTC_Encoded_Block;
   Decoded_Result  : Block_4x4;

begin
   Outlier_Block(4,4) := 170; -- 15 pixels at 10, 1 pixel at 170. Mean = 20.
   
   Put_Line ("Starting V&V Test Suite for Block_Truncation_Coding...");
   Put_Line ("------------------------------------------------------");

   -- TEST 1
   Put_Line ("TEST 1 - Mean Value Calculation");
   Put_Line ("  1.1 Assert uniform block mean matches pixel value");
   Assert (Calculate_Mean(Uniform_Block) = 100.0, "Mean computation failed on uniform data.");
   Put_Line ("  1.2 Assert two-tone block calculates exact center mean");
   Assert (Calculate_Mean(Two_Tone_Block) = 100.0, "Mean computation failed on variance data.");
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Standard Deviation Calculation");
   Put_Line ("  2.1 Assert std-dev of uniform block is 0.0");
   Assert (Calculate_Std_Dev(Uniform_Block, 100.0) = 0.0, "StdDev should be 0 on uniform block.");
   Put_Line ("  2.2 Assert std-dev of two-tone block is 50.0");
   Assert (Calculate_Std_Dev(Two_Tone_Block, 100.0) = 50.0, "StdDev failed on variance data.");
   Put_Line ("      PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Standard BTC Uniform Block Edge Case");
   Put_Line ("  3.1 Assert Encode handles Q=16 edge case without Division By Zero");
   Encode_Block (Uniform_Block, Encoded_Result, Standard_BTC);
   Put_Line ("  3.2 Assert lower (A) and upper (B) quantization bounds equal the uniform value");
   Assert (Encoded_Result.A = 100 and Encoded_Result.B = 100, "Uniform bounds extraction failed.");
   Put_Line ("      PASS");

   -- TEST 4
   Put_Line ("TEST 4 - AMBTC Uniform Block Edge Case");
   Put_Line ("  4.1 Assert AMBTC avoids Q=0 or Q=16 bounds errors");
   Encode_Block (Uniform_Block, Encoded_Result, AMBTC);
   Put_Line ("  4.2 Assert AMBTC yields perfect matching bounds");
   Assert (Encoded_Result.A = 100 and Encoded_Result.B = 100, "AMBTC uniform bounds failed.");
   Put_Line ("      PASS");

   -- TEST 5
   Put_Line ("TEST 5 - Standard BTC Quantization Bounds (Symmetric)");
   Encode_Block (Two_Tone_Block, Encoded_Result, Standard_BTC);
   Put_Line ("  5.1 Assert Lower Bound exactly equals lower pixel set (50)");
   Assert (Encoded_Result.A = 50, "Lower bound math incorrect.");
   Put_Line ("  5.2 Assert Upper Bound exactly equals upper pixel set (150)");
   Assert (Encoded_Result.B = 150, "Upper bound math incorrect.");
   Put_Line ("      PASS");

   -- TEST 6
   Put_Line ("TEST 6 - Lossless Reconstruction on Symmetric Blocks");
   Decode_Block (Encoded_Result, Decoded_Result);
   Put_Line ("  6.1 Assert Block matches strictly after Encode-Decode cycle");
   Assert (Decoded_Result = Two_Tone_Block, "Reconstruction failed to match.");
   Put_Line ("      PASS");

   -- TEST 7
   Put_Line ("TEST 7 - AMBTC Variant Correctness on Symmetric Data");
   Encode_Block (Two_Tone_Block, Encoded_Result, AMBTC);
   Put_Line ("  7.1 Assert AMBTC calculates identical limits to Standard BTC for symmetric data");
   Assert (Encoded_Result.A = 50 and Encoded_Result.B = 150, "AMBTC math diverged.");
   Put_Line ("      PASS");

   -- TEST 8
   Put_Line ("TEST 8 - Standard BTC Single Outlier Handling");
   Encode_Block (Outlier_Block, Encoded_Result, Standard_BTC);
   Put_Line ("  8.1 Assert single high outlier limits are calculated correctly (A=10, B=170)");
   Assert (Encoded_Result.A = 10, "Standard BTC Outlier Lower limit incorrect.");
   Assert (Encoded_Result.B = 170, "Standard BTC Outlier Upper limit incorrect.");
   Put_Line ("      PASS");

   -- TEST 9
   Put_Line ("TEST 9 - AMBTC Single Outlier Handling");
   Encode_Block (Outlier_Block, Encoded_Result, AMBTC);
   Put_Line ("  9.1 Assert AMBTC calculates identical means for outlier (A=10, B=170)");
   Assert (Encoded_Result.A = 10, "AMBTC Outlier Lower limit incorrect.");
   Assert (Encoded_Result.B = 170, "AMBTC Outlier Upper limit incorrect.");
   Put_Line ("      PASS");

   -- TEST 10
   Put_Line ("TEST 10 - AMBTC Mean Preservation Constraint");
   Put_Line ("  10.1 Assert (Q*B + (16-Q)*A)/16 perfectly equals original mean");
   declare
      Q : Integer := 0;
      Preserved_Mean : Float;
   begin
      for I in 1..4 loop
         for J in 1..4 loop
            if Encoded_Result.Bitmap(I, J) then Q := Q + 1; end if;
         end loop;
      end loop;
      Preserved_Mean := (Float(Q) * Float(Encoded_Result.B) + Float(16-Q) * Float(Encoded_Result.A)) / 16.0;
      Assert (Preserved_Mean = 20.0, "Mean Preservation violated.");
      Put_Line ("      PASS");
   end;

   -- TEST 11
   Put_Line ("TEST 11 - Bitmap Generation Validation");
   Put_Line ("  11.1 Assert Outlier pixel triggers exactly one True bit in the Bitmap mask");
   declare
      True_Count : Integer := 0;
   begin
      for I in 1..4 loop
         for J in 1..4 loop
            if Encoded_Result.Bitmap(I, J) then True_Count := True_Count + 1; end if;
         end loop;
      end loop;
      Assert (True_Count = 1, "Bitmap threshold mask is malformed.");
      Assert (Encoded_Result.Bitmap(4,4) = True, "Bitmap placed high threshold on wrong index.");
      Put_Line ("      PASS");
   end;

   -- TEST 12
   Put_Line ("TEST 12 - Maximum Contrast Edge Case (Clamp testing)");
   Encode_Block (Max_Var_Block, Encoded_Result, Standard_BTC);
   Put_Line ("  12.1 Assert limits do not overflow bounds of 0-255");
   Assert (Encoded_Result.A = 0, "Lower clamp failed");
   Assert (Encoded_Result.B = 255, "Upper clamp failed");
   Put_Line ("      PASS");

   -- TEST 13
   Put_Line ("TEST 13 - Decoding Resiliency Constraint");
   Put_Line ("  13.1 Assert Decoding an A=B block ignores Bitmap variations completely");
   Encoded_Result.A := 42;
   Encoded_Result.B := 42;
   Encoded_Result.Bitmap := (others => (others => True));
   Encoded_Result.Bitmap(1,1) := False; -- Force variation
   Decode_Block (Encoded_Result, Decoded_Result);
   Assert (Calculate_Mean(Decoded_Result) = 42.0, "Decode variation failed resiliency check.");
   Put_Line ("      PASS");

   Put_Line ("------------------------------------------------------");
   Put_Line ("ALL 13 TESTS COMPLETED AND PASSED.");
end Tests;
