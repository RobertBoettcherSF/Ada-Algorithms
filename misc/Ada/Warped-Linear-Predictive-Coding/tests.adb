with Ada.Text_IO; use Ada.Text_IO;
with Warped_LPC; use Warped_LPC;

procedure Tests is

   Test_Count   : Integer := 0;
   Pass_Count   : Integer := 0;

   -- Custom assertion printer that assumes failure initially and celebrates when proven right
   procedure Assert (Condition : Boolean; Description : String) is
   begin
      Test_Count := Test_Count + 1;
      Put ("    " & Integer'Image(Test_Count) & ". " & Description & " ... ");
      if Condition then
         Put_Line ("PASS");
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("FAIL");
      end if;
   end Assert;

   procedure Run_Tests is
      Input_Sig : Real_Array(1..5) := (1.0, 0.5, 0.25, 0.125, 0.0625);
      Zero_Sig  : Real_Array(1..5) := (others => 0.0);
      Empty_Sig : Real_Array(1..0);
      
      Auto_C    : Real_Array(0..2);
      Coeffs    : Real_Array(1..2);
      Err_Var   : Real;
   begin
      Put_Line ("TEST 1 - Standard Autocorrelation Accuracy");
      Standard_Autocorrelation(Input_Sig, 2, Auto_C);
      Assert (Auto_C(0) > 1.0, "Assert Energy R(0) > 1.0 (Disproves null calculation)");
      Assert (Auto_C(1) < Auto_C(0), "Assert R(1) < R(0) (Disproves static propagation)");
      Assert (Auto_C(2) < Auto_C(1), "Assert R(2) < R(1) (Disproves divergent signals)");

      Put_Line ("TEST 2 - Zero Signal Edge Case");
      Standard_Autocorrelation(Zero_Sig, 2, Auto_C);
      Assert (Auto_C(0) = 0.0, "Assert R(0) == 0.0 (Disproves noise injection)");
      Assert (Auto_C(1) = 0.0, "Assert R(1) == 0.0 (Disproves NaN handling bug)");
      
      Put_Line ("TEST 3 - Empty Input Vulnerability (Standard)");
      begin
         Standard_Autocorrelation(Empty_Sig, 2, Auto_C);
         Assert (False, "Assert Invalid_Input exception raised (Disproves memory access violation)");
      exception
         when Invalid_Input => Assert (True, "Assert Invalid_Input exception raised (Safely Caught)");
         when others => Assert (False, "Wrong exception raised");
      end;
      
      Put_Line ("TEST 4 - Misaligned Output Buffer Protection");
      begin
         declare Bad_Auto : Real_Array(0..3); begin
            Standard_Autocorrelation(Input_Sig, 2, Bad_Auto);
            Assert (False, "Assert Invalid_Order exception raised");
         end;
      exception
         when Invalid_Order => Assert (True, "Assert Invalid_Order exception raised (Safely Caught)");
      end;

      Put_Line ("TEST 5 - Warped Baseline Parity (Lambda = 0.0)");
      declare
         Auto_Std, Auto_Wrp : Real_Array(0..2);
      begin
         Standard_Autocorrelation(Input_Sig, 2, Auto_Std);
         Warped_Autocorrelation(Input_Sig, 2, 0.0, Auto_Wrp);
         Assert (abs(Auto_Std(0) - Auto_Wrp(0)) < 0.0001, "Assert R(0) matches standard LPC");
         Assert (abs(Auto_Std(1) - Auto_Wrp(1)) < 0.0001, "Assert R(1) matches standard LPC");
      end;
      
      Put_Line ("TEST 6 - Warped Autocorrelation Shifting Effect");
      declare Auto_Std : Real_Array(0..2); begin
         Warped_Autocorrelation(Input_Sig, 2, 0.5, Auto_C);
         Standard_Autocorrelation(Input_Sig, 2, Auto_Std);
         Assert (Auto_C(0) > 0.0, "Assert Warped Energy R(0) > 0");
         Assert (abs(Auto_C(1) - Auto_Std(1)) > 0.01, "Assert R(1) diverges appropriately due to spectral warping");
      end;

      Put_Line ("TEST 7 - Empty Input Vulnerability (Warped)");
      begin
         Warped_Autocorrelation(Empty_Sig, 2, 0.5, Auto_C);
         Assert (False, "Assert Invalid_Input raised");
      exception
         when Invalid_Input => Assert (True, "Assert Invalid_Input safely raised for warped paths");
      end;

      Put_Line ("TEST 8 - Levinson-Durbin Zero Divisor Vulnerability");
      Levinson_Durbin((0.0, 0.0, 0.0), 2, Coeffs, Err_Var);
      Assert (Coeffs(1) = 0.0, "Assert Coeff(1) gracefully resolves to 0.0 (No Divide-By-Zero Crash)");
      Assert (Err_Var = 0.0, "Assert Error Variance = 0.0");

      Put_Line ("TEST 9 - Levinson-Durbin Perfect DC Predictability");
      Levinson_Durbin((1.0, 1.0, 1.0), 2, Coeffs, Err_Var);
      Assert (Err_Var >= 0.0, "Assert Error Variance is strictly non-negative (Disproves variance collapse)");
      Assert (Coeffs(1) = 1.0, "Assert Coeff perfectly captures correlation");
      
      Put_Line ("TEST 10 - Levinson-Durbin Malformed Coeff Array Guard");
      begin
         declare Bad_Coeffs : Real_Array(1..3); begin
            Levinson_Durbin(Auto_C, 2, Bad_Coeffs, Err_Var);
            Assert (False, "Assert Array dimension mismatch caught");
         end;
      exception
         when Invalid_Order => Assert (True, "Assert Invalid_Order exception safely raised");
      end;
      
      Put_Line ("TEST 11 - Levinson-Durbin Malformed Auto Array Guard");
      begin
         declare Bad_Auto : Real_Array(0..1); begin
            Levinson_Durbin(Bad_Auto, 2, Coeffs, Err_Var);
            Assert (False, "Assert Array dimension mismatch caught");
         end;
      exception
         when Invalid_Order => Assert (True, "Assert Invalid_Order exception safely raised");
      end;
      
      Put_Line ("TEST 12 - Warped Autocorrelation with Negative Lambda");
      Warped_Autocorrelation(Input_Sig, 2, -0.5, Auto_C);
      Assert (Auto_C(0) > 0.0, "Assert logic handles negative warping factors safely (Disproves NaN collapse)");
      Assert (Auto_C(0) /= Auto_C(1), "Assert produces non-trivial signal delay");

      Put_Line ("TEST 13 - Standard LPC End-to-End Synthesis");
      Standard_Autocorrelation(Input_Sig, 2, Auto_C);
      Levinson_Durbin(Auto_C, 2, Coeffs, Err_Var);
      Assert (Err_Var > 0.0, "Assert synthesis Error > 0 for non-perfect signals");
      Assert (Err_Var <= Auto_C(0), "Assert synthesis Error logically <= Original Energy");
      
      Put_Line ("TEST 14 - Warped LPC End-to-End Synthesis");
      Warped_Autocorrelation(Input_Sig, 2, 0.45, Auto_C);
      Levinson_Durbin(Auto_C, 2, Coeffs, Err_Var);
      Assert (Err_Var > 0.0, "Assert WLPC synthesis Error > 0");
      Assert (Err_Var <= Auto_C(0), "Assert WLPC Error sensibly bounded <= Warped Energy");
   end Run_Tests;

begin
   Run_Tests;
   Put_Line ("");
   Put_Line ("Summary: " & Integer'Image(Pass_Count) & " / " & Integer'Image(Test_Count) & " Assumptions Proven False (Tests Passed).");
end Tests;
