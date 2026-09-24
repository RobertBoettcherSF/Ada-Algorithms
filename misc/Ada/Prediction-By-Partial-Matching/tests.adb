with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with PPM_Algorithm; use PPM_Algorithm;

procedure Tests is
   M    : Context_Model;
   R    : Model_Result;
   Pred : PPM_Predictor;
   Dist : Distribution;
   Sum  : Probability := 0.0;

   function Is_Close (A, B : Probability) return Boolean is
   begin
      return abs (A - B) < 0.0001;
   end Is_Close;
begin
   Put_Line ("========================================");
   Put_Line ("Starting PPM V&V Test Suite");
   Put_Line ("Assumption: Implementation is defective.");
   Put_Line ("========================================");

   -- TEST 1
   Put_Line ("TEST 1 - Model State Integrity");
   Put_Line ("  1.1 Assert initial state is clean");
   Assert (M.Total_Count = 0 and M.Unique_Symbols = 0, "Model dirty on init");
   Put_Line ("     PASS: Assumption disproven.");

   Put_Line ("  1.2 Assert state transitions correctly on first symbol");
   Update_Model (M, 'X');
   Assert (M.Total_Count = 1 and M.Unique_Symbols = 1, "Failed counting unique");
   Put_Line ("     PASS: Assumption disproven.");

   Put_Line ("  1.3 Assert state transitions correctly on duplicate symbol");
   Update_Model (M, 'X');
   Assert (M.Total_Count = 2 and M.Unique_Symbols = 1, "Failed duplicate tracking");
   Put_Line ("     PASS: Assumption disproven.");

   -- TEST 2
   Put_Line ("TEST 2 - Mathematical Estimators (Laplace / PPM-A)");
   Put_Line ("  2.1 Assert Laplace escape probability matches 1 / (N+1)");
   Estimate_Laplace (M, R);
   Assert (Is_Close (R.Escape_Prob, 1.0 / 3.0), "Laplace escape formula wrong");
   Put_Line ("     PASS: Assumption disproven.");

   Put_Line ("  2.2 Assert Laplace symbol probability matches C / (N+1)");
   Assert (Is_Close (R.Probs('X'), 2.0 / 3.0), "Laplace symbol formula wrong");
   Put_Line ("     PASS: Assumption disproven.");

   -- TEST 3
   Put_Line ("TEST 3 - Empty Model Handling");
   declare
      Empty_M : Context_Model;
   begin
      Put_Line ("  3.1 Assert PPMd gracefully handles empty context (div-by-zero check)");
      Estimate_PPMd (Empty_M, R);
      Assert (R.Escape_Prob = 1.0, "Empty model should escape with P=1.0");
      Put_Line ("     PASS: Assumption disproven.");
   end;

   -- TEST 4
   Put_Line ("TEST 4 - PPM-B Estimator Logic");
   Update_Model (M, 'Y'); -- M now has X:2, Y:1. Total:3, Unique:2.
   Put_Line ("  4.1 Assert PPM-B excludes singleton (count-1) from probability");
   Estimate_PPM_B (M, R);
   Assert (R.Probs('Y') = 0.0, "Singleton Y should have 0 prob in PPM-B");
   Put_Line ("     PASS: Assumption disproven.");

   Put_Line ("  4.2 Assert PPM-B escape uses correct ratio (q/n)");
   Assert (Is_Close (R.Escape_Prob, 2.0 / 3.0), "PPM-B escape formula wrong");
   Put_Line ("     PASS: Assumption disproven.");

   Put_Line ("  4.3 Assert PPM-C probabilies dynamically adjust via q/(n+q)");
   Estimate_PPM_C (M, R);
   Assert (Is_Close (R.Escape_Prob, 2.0 / 5.0), "PPM-C formulation error");
   Put_Line ("     PASS: Assumption disproven.");

   -- TEST 5
   Put_Line ("TEST 5 - Context Trie Construction");
   Put_Line ("  5.1 Assert PPM Predictor initializes safely");
   Initialize_Predictor (Pred, 2, Laplace_Estimator);
   Assert (Pred.Root /= null, "Root node allocation failed");
   Put_Line ("     PASS: Assumption disproven.");

   Put_Line ("  5.2 Assert Update_Predictor handles zero-length history safely");
   Update_Predictor (Pred, To_Symbol_String(""), 'A');
   Assert (Pred.Root.Model.Total_Count = 1, "Order 0 update failed");
   Put_Line ("     PASS: Assumption disproven.");

   Put_Line ("  5.3 Assert Update_Predictor populates higher orders");
   Update_Predictor (Pred, To_Symbol_String("A"), 'B');
   Assert (Pred.Root.Children('A') /= null, "Order 1 node not created");
   Assert (Pred.Root.Children('A').Model.Total_Count = 1, "Order 1 model empty");
   Put_Line ("     PASS: Assumption disproven.");

   -- TEST 6
   Put_Line ("TEST 6 - Probability Blending Integrity");
   Put_Line ("  6.1 Assert blended probability strictly bounds between 0.0 and 1.0");
   Dist := Calculate_Blended_Distribution (Pred, To_Symbol_String("A"));
   Sum := 0.0;
   for S in Symbol loop
      Assert (Dist(S) >= 0.0 and Dist(S) <= 1.0, "Probability out of bounds");
      Sum := Sum + Dist(S);
   end loop;
   Put_Line ("     PASS: Assumption disproven.");

   Put_Line ("  6.2 Assert total blended probability mass exactly equals 1.0");
   -- A critical test: Math error here completely breaks arithmetic coder mapping
   Assert (Is_Close(Sum, 1.0), "Total Probability mass violated (" & Float'Image(Float(Sum)) & ")");
   Put_Line ("     PASS: Assumption disproven.");

   -- TEST 7
   Put_Line ("TEST 7 - Memory Management");
   Put_Line ("  7.1 Assert memory deallocates without constraint errors");
   Free_Predictor (Pred);
   Assert (Pred.Root = null, "Dangling root pointer after free");
   Put_Line ("     PASS: Assumption disproven.");

   Put_Line ("========================================");
   Put_Line ("All 15 assertions passed. System is verified.");
end Tests;
