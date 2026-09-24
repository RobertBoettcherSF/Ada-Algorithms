with Ada.Text_IO; use Ada.Text_IO;
with Financial_Risk_Modeling; use Financial_Risk_Modeling;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   procedure Check_Float (Label : String; Actual, Expected, Tolerance : Rate) is
      Diff : constant Rate := abs (Actual - Expected);
   begin
      Check (Label & " (Act: " & Actual'Image & " Exp: " & Expected'Image & ")", Diff <= Tolerance);
   end Check_Float;

   --  Test Datasets
   Data_A    : constant Return_Array := [0.05, -0.02, 0.01, 0.04, -0.05, -0.01, 0.03, 0.02, -0.03, 0.01];
   Data_Flat : constant Return_Array := [0.05, 0.05, 0.05, 0.05, 0.05];
   Data_Sym  : constant Return_Array := [-0.1, -0.05, 0.0, 0.05, 0.1];
   Single    : constant Return_Array := [-0.04];
   
   --  Helper dataset for linear predictable VaR (100 items from -0.50 to 0.49)
   Data_100  : Return_Array (1 .. 100);
begin
   --  Initialize Data_100 sequence
   for I in 1 .. 100 loop
      Data_100 (I) := Rate (I) * 0.01 - 0.51; 
      --  Values: -0.50, -0.49, ..., 0.49
   end loop;

   Put_Line ("TEST 1 -- Mathematical Helpers (Normal PDF)");
   Check_Float ("1.1 PDF at 0.0 is approx 0.3989", Normal_PDF (0.0), 0.3989, 0.001);
   Check_Float ("1.2 PDF at 1.0 is approx 0.2419", Normal_PDF (1.0), 0.2419, 0.001);
   Check_Float ("1.3 PDF at -1.0 is approx 0.2419", Normal_PDF (-1.0), 0.2419, 0.001);

   Put_Line ("TEST 2 -- Mathematical Helpers (Normal Inverse CDF)");
   Check_Float ("2.1 Z-score for 95% confidence is approx 1.645", Normal_Inverse_CDF (0.95), 1.645, 0.005);
   Check_Float ("2.2 Z-score for 97.5% confidence is approx 1.96", Normal_Inverse_CDF (0.975), 1.960, 0.005);
   Check_Float ("2.3 Z-score for 99% confidence is approx 2.326", Normal_Inverse_CDF (0.99), 2.326, 0.005);

   Put_Line ("TEST 3 -- Descriptive Statistics (Mean)");
   Check_Float ("3.1 Mean of Data_A", Mean (Data_A), 0.005, 0.001);
   Check_Float ("3.2 Mean of Flat Data", Mean (Data_Flat), 0.05, 0.0001);
   Check_Float ("3.3 Mean of Symmetrical Data", Mean (Data_Sym), 0.0, 0.0001);

   Put_Line ("TEST 4 -- Descriptive Statistics (Standard Deviation)");
   Check_Float ("4.1 StdDev of Data_A", Standard_Deviation (Data_A), 0.03206, 0.001);
   Check_Float ("4.2 StdDev of Flat Data is 0", Standard_Deviation (Data_Flat), 0.0, 0.0001);
   Check_Float ("4.3 StdDev of Symmetrical Data", Standard_Deviation (Data_Sym), 0.079, 0.005);

   Put_Line ("TEST 5 -- Historical VaR (Basic and Interpolation)");
   --  For 10 elements, 90% confidence -> Tail is 10%, Position is 1.0 (Worst element)
   Check_Float ("5.1 VaR 90% of Data_A", Historical_VaR (Data_A, 0.90), -0.05, 0.0001);
   --  For 10 elements, 85% confidence -> Position is 1.5, Interpolates between 1st and 2nd worst (-0.05 and -0.03)
   Check_Float ("5.2 VaR 85% of Data_A", Historical_VaR (Data_A, 0.85), -0.04, 0.0001);
   --  For Flat array, VaR is flat
   Check_Float ("5.3 VaR 95% of Flat Data", Historical_VaR (Data_Flat, 0.95), 0.05, 0.0001);

   Put_Line ("TEST 6 -- Historical VaR (Large Array Validation)");
   --  Position for 95% is 5.0 (the 5th worst item). Values are -0.50, -0.49, -0.48, -0.47, -0.46
   Check_Float ("6.1 VaR 95% of Data_100", Historical_VaR (Data_100, 0.95), -0.46, 0.001);
   --  Position for 99% is 1.0 (the 1st worst item).
   Check_Float ("6.2 VaR 99% of Data_100", Historical_VaR (Data_100, 0.99), -0.50, 0.001);
   --  Position for 90% is 10.0 (the 10th worst item).
   Check_Float ("6.3 VaR 90% of Data_100", Historical_VaR (Data_100, 0.90), -0.41, 0.001);

   Put_Line ("TEST 7 -- Historical Expected Shortfall (Basic)");
   --  Tail for 80% on 10 items is 2 items (-0.05, -0.03). Avg = -0.04
   Check_Float ("7.1 ES 80% of Data_A", Historical_ES (Data_A, 0.80), -0.04, 0.0001);
   --  Tail for 90% on 10 items is 1 item (-0.05)
   Check_Float ("7.2 ES 90% of Data_A", Historical_ES (Data_A, 0.90), -0.05, 0.0001);
   --  Flat data ES is the constant
   Check_Float ("7.3 ES 95% of Flat Data", Historical_ES (Data_Flat, 0.95), 0.05, 0.0001);

   Put_Line ("TEST 8 -- Historical Expected Shortfall (Large Array)");
   --  For 95% confidence on 100 items, avg of bottom 5 (-0.50, -0.49, -0.48, -0.47, -0.46) = -0.48
   Check_Float ("8.1 ES 95% of Data_100", Historical_ES (Data_100, 0.95), -0.48, 0.001);
   --  For 90% confidence on 100 items, avg of bottom 10 = -0.455
   Check_Float ("8.2 ES 90% of Data_100", Historical_ES (Data_100, 0.90), -0.455, 0.001);
   --  For 99% confidence, tail count is 1. Should match the 99% VaR.
   Check_Float ("8.3 ES 99% of Data_100", Historical_ES (Data_100, 0.99), -0.50, 0.001);

   Put_Line ("TEST 9 -- Parametric Value at Risk");
   --  Mu = 0.0, Sigma = 0.079. VaR 95% = 0 - 1.645 * 0.079 = -0.13
   Check_Float ("9.1 Parametric VaR 95% of Sym", Parametric_VaR (Data_Sym, 0.95), -0.13, 0.01);
   --  VaR 99% = 0 - 2.326 * 0.079 = -0.183
   Check_Float ("9.2 Parametric VaR 99% of Sym", Parametric_VaR (Data_Sym, 0.99), -0.183, 0.01);
   --  VaR for flat data (Sigma 0) is the mean itself
   Check_Float ("9.3 Parametric VaR 95% Flat", Parametric_VaR (Data_Flat, 0.95), 0.05, 0.001);

   Put_Line ("TEST 10 -- Parametric Expected Shortfall");
   --  Mu = 0.0, Sigma = 0.079. 
   Check_Float ("10.1 Parametric ES 95% of Sym", Parametric_ES (Data_Sym, 0.95), -0.163, 0.01);
   Check_Float ("10.2 Parametric ES 99% of Sym", Parametric_ES (Data_Sym, 0.99), -0.21, 0.01);
   --  ES for flat data is the mean
   Check_Float ("10.3 Parametric ES 95% Flat", Parametric_ES (Data_Flat, 0.95), 0.05, 0.001);

   Put_Line ("TEST 11 -- Edge Cases (Single Element Array)");
   --  Historical methods should fall back to the single element.
   Check_Float ("11.1 Historical VaR Single", Historical_VaR (Single, 0.95), -0.04, 0.0001);
   Check_Float ("11.2 Historical VaR Single (High Conf)", Historical_VaR (Single, 0.99), -0.04, 0.0001);
   Check_Float ("11.3 Historical ES Single", Historical_ES (Single, 0.99), -0.04, 0.0001);

   Put_Line ("TEST 12 -- Edge Cases (High Confidence Extreme Data)");
   --  Extreme confidences map position to < 1.0, triggering fallback logic.
   Check_Float ("12.1 Historical VaR 99.99% of Data_A", Historical_VaR (Data_A, 0.9999), -0.05, 0.0001);
   Check_Float ("12.2 Historical ES 99.99% of Data_A", Historical_ES (Data_A, 0.9999), -0.05, 0.0001);
   --  Interpolation limits
   Check_Float ("12.3 Parametric VaR 99.99% flat", Parametric_VaR (Data_Flat, 0.9999), 0.05, 0.001);

   Put_Line ("TEST 13 -- Exception Handling (Insufficient Data)");
   declare
      Caught : Boolean := False;
      Dummy  : Rate;
   begin
      begin
         Dummy := Parametric_VaR (Single, 0.95);
      exception
         when Insufficient_Data => Caught := True;
      end;
      Check ("13.1 Parametric_VaR raises Insufficient_Data on Single", Caught);
      
      Caught := False;
      begin
         Dummy := Standard_Deviation (Single);
      exception
         when Insufficient_Data => Caught := True;
      end;
      Check ("13.2 Standard_Deviation raises Insufficient_Data on Single", Caught);

      Caught := False;
      begin
         Dummy := Parametric_ES (Single, 0.99);
      exception
         when Insufficient_Data => Caught := True;
      end;
      Check ("13.3 Parametric_ES raises Insufficient_Data on Single", Caught);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
