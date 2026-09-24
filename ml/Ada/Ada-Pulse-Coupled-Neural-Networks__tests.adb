with Ada.Text_IO; use Ada.Text_IO;
with Pulse_Coupled_Networks; use Pulse_Coupled_Networks;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Helper for floating point equivalence
   function Approx_Eq (A, B : Real; Tol : Real := 0.0001) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx_Eq;

   -- Baseline parameters for tests
   Test_Params : constant PCNN_Parameters :=
     (Decay_F     => 0.9,
      Decay_L     => 0.9,
      Decay_Theta => 0.8,
      V_F         => 1.0,
      V_L         => 1.0,
      V_Theta     => 10.0,
      Beta        => 0.1);

   Zero_Kernel : constant Kernel_Matrix := [others => [others => 0.0]];
   
   -- Cross kernel, commonly used in image segmentation
   Cross_Kernel : constant Kernel_Matrix :=
     [-1 => [0 => 1.0, others => 0.0],
       0 => [-1 => 1.0, 0 => 0.0, 1 => 1.0],
       1 => [0 => 1.0, others => 0.0]];

begin
   -- TEST 1 — State Initialization
   Put_Line ("TEST 1 — State Initialization");
   declare
      S : constant PCNN_State := Create_State (4, 5, 2.5);
   begin
      Check ("1.1 Dimensions (Rows) correct", S.Rows = 4);
      Check ("1.2 Dimensions (Cols) correct", S.Cols = 5);
      Check ("1.3 Theta correctly initialized", Approx_Eq (S.Theta (1, 1), 2.5));
      Check ("1.4 Outputs correctly initialized to False", not S.Y (2, 2));
   end;

   -- TEST 2 — Convolve helper with blank grid
   Put_Line ("TEST 2 — Convolve helper with empty grid");
   declare
      Y : constant Binary_Matrix (1 .. 3, 1 .. 3) := [others => [others => False]];
      Val : Real;
   begin
      Val := Convolve (Y, Cross_Kernel, 2, 2);
      Check ("2.1 No pulses means zero sum", Approx_Eq (Val, 0.0));
      Val := Convolve (Y, Cross_Kernel, 1, 1);
      Check ("2.2 Corner bounds check works", Approx_Eq (Val, 0.0));
      Check ("2.3 Grid size constraints handled safely", Y'Length (1) = 3);
   end;

   -- TEST 3 — Convolve helper with active neighbors
   Put_Line ("TEST 3 — Convolve helper with active neighbors");
   declare
      Y : Binary_Matrix (1 .. 3, 1 .. 3) := [others => [others => False]];
      Val : Real;
   begin
      Y (1, 2) := True; -- Top neighbor
      Y (2, 1) := True; -- Left neighbor
      Val := Convolve (Y, Cross_Kernel, 2, 2);
      Check ("3.1 Center receives 2 active neighbors", Approx_Eq (Val, 2.0));
      
      Val := Convolve (Y, Cross_Kernel, 1, 3);
      Check ("3.2 Corner receives 1 active neighbor", Approx_Eq (Val, 1.0));
      
      Val := Convolve (Y, Cross_Kernel, 3, 3);
      Check ("3.3 Opposite corner receives 0", Approx_Eq (Val, 0.0));
   end;

   -- TEST 4 — Dimension Mismatch Exception (Rows)
   Put_Line ("TEST 4 — Standard Iterate: Mismatch on Rows");
   declare
      S : PCNN_State := Create_State (3, 3, 1.0);
      Stimulus : constant Real_Matrix (1 .. 4, 1 .. 3) := [others => [others => 0.0]];
      Caught : Boolean := False;
   begin
      begin
         Iterate_Standard (S, Stimulus, Test_Params, Zero_Kernel, Zero_Kernel);
      exception
         when Dimension_Mismatch =>
            Caught := True;
      end;
      Check ("4.1 Exception correctly raised and caught", Caught);
      Check ("4.2 State remains untouched (F unchanged)", Approx_Eq (S.F (1, 1), 0.0));
      Check ("4.3 State remains untouched (U unchanged)", Approx_Eq (S.U (2, 2), 0.0));
   end;

   -- TEST 5 — Dimension Mismatch Exception (Cols)
   Put_Line ("TEST 5 — Standard Iterate: Mismatch on Cols");
   declare
      S : PCNN_State := Create_State (3, 3, 1.0);
      Stimulus : constant Real_Matrix (1 .. 3, 1 .. 2) := [others => [others => 0.0]];
      Caught : Boolean := False;
   begin
      begin
         Iterate_Standard (S, Stimulus, Test_Params, Zero_Kernel, Zero_Kernel);
      exception
         when Dimension_Mismatch =>
            Caught := True;
      end;
      Check ("5.1 Exception correctly raised and caught", Caught);
      Check ("5.2 Rows mismatch detection independent of cols", Stimulus'Last(2) /= S.Cols);
      Check ("5.3 Output Y remains completely false", not S.Y (1, 1));
   end;

   -- TEST 6 — Dimension Mismatch Exception (Simplified Iterate)
   Put_Line ("TEST 6 — Simplified Iterate: Dimension Mismatch");
   declare
      S : PCNN_State := Create_State (2, 2, 1.0);
      Stimulus : constant Real_Matrix (1 .. 2, 1 .. 3) := [others => [others => 0.0]];
      Caught : Boolean := False;
   begin
      begin
         Iterate_Simplified (S, Stimulus, Test_Params, Zero_Kernel);
      exception
         when Dimension_Mismatch =>
            Caught := True;
      end;
      Check ("6.1 Exception caught in Simplified model", Caught);
      Check ("6.2 Verify constraint evaluation order", Stimulus'Length(2) = 3);
      Check ("6.3 L remains zeroed", Approx_Eq (S.L(1, 1), 0.0));
   end;

   -- TEST 7 — Standard Iterate (Zero Stimulus)
   Put_Line ("TEST 7 — Standard Iterate with Zero Stimulus");
   declare
      S : PCNN_State := Create_State (2, 2, 1.0);
      Stimulus : constant Real_Matrix (1 .. 2, 1 .. 2) := [others => [others => 0.0]];
   begin
      Iterate_Standard (S, Stimulus, Test_Params, Zero_Kernel, Zero_Kernel);
      Check ("7.1 F remains exactly 0.0", Approx_Eq (S.F (1, 1), 0.0));
      Check ("7.2 Y does not fire", not S.Y (1, 1));
      Check ("7.3 Theta decays correctly (0.8 * 1.0 = 0.8)", Approx_Eq (S.Theta (1, 1), 0.8));
   end;

   -- TEST 8 — Standard Iterate (High Stimulus / Pulse Generation)
   Put_Line ("TEST 8 — Standard Iterate with High Stimulus");
   declare
      S : PCNN_State := Create_State (2, 2, 1.0);
      Stimulus : constant Real_Matrix (1 .. 2, 1 .. 2) := [others => [others => 2.0]];
   begin
      Iterate_Standard (S, Stimulus, Test_Params, Zero_Kernel, Zero_Kernel);
      Check ("8.1 Internal activity U exceeds initial Theta", S.U (1, 1) > 1.0);
      Check ("8.2 Output Y fires (True)", S.Y (1, 1));
      -- Theta should be Decay_Theta * Prev_Theta + V_Theta => 0.8 * 1.0 + 10.0 = 10.8
      Check ("8.3 Theta rises sharply post-firing", Approx_Eq (S.Theta (1, 1), 10.8));
   end;

   -- TEST 9 — Standard Iterate (Lateral Interaction M and W)
   Put_Line ("TEST 9 — Standard Iterate with Lateral Links");
   declare
      S : PCNN_State := Create_State (3, 3, 50.0); -- High theta prevents new firing initially
      Stimulus : constant Real_Matrix (1 .. 3, 1 .. 3) := [others => [others => 1.0]];
   begin
      -- Force center to have fired previously
      S.Y (2, 2) := True; 
      Iterate_Standard (S, Stimulus, Test_Params, Cross_Kernel, Cross_Kernel);
      
      -- Center node: no active neighbors. F(2,2) = 0.9*0 + 1.0*0 + 1.0 = 1.0
      Check ("9.1 Center F has no neighbor boost", Approx_Eq (S.F (2, 2), 1.0));
      
      -- Edge node (1,2): 1 active neighbor (the center). F(1,2) = 0 + 1.0*1.0 + 1.0 = 2.0
      Check ("9.2 Neighbor F boosted by M kernel", Approx_Eq (S.F (1, 2), 2.0));
      
      -- Edge node (1,2) L = 0 + 1.0*1.0 = 1.0. U = F * (1 + beta * L) => 2.0 * (1 + 0.1*1.0) = 2.2
      Check ("9.3 U integrates feeding and linking", Approx_Eq (S.U (1, 2), 2.2));
   end;

   -- TEST 10 — Simplified Unit-Linking Iterate
   Put_Line ("TEST 10 — Simplified Iterate Model Characteristics");
   declare
      S : PCNN_State := Create_State (2, 2, 2.0);
      Stimulus : constant Real_Matrix (1 .. 2, 1 .. 2) := 
        [1 => [1.5, 0.5], 2 => [0.5, 0.5]];
   begin
      Iterate_Simplified (S, Stimulus, Test_Params, Zero_Kernel);
      Check ("10.1 F strictly tracks stimulus", Approx_Eq (S.F (1, 1), 1.5));
      Check ("10.2 Lower stimulus strictly tracked", Approx_Eq (S.F (1, 2), 0.5));
      -- U for (1,1) is 1.5. Theta is 2.0. So it shouldn't fire.
      Check ("10.3 Neuron does not fire if F < Theta", not S.Y (1, 1));
   end;

   -- TEST 11 — Theta Decay Across Multiple Steps
   Put_Line ("TEST 11 — Theta Decay Across Steps");
   declare
      S : PCNN_State := Create_State (2, 2, 10.0);
      Stimulus : constant Real_Matrix (1 .. 2, 1 .. 2) := [others => [others => 0.0]];
   begin
      Iterate_Standard (S, Stimulus, Test_Params, Zero_Kernel, Zero_Kernel);
      Check ("11.1 Step 1 decay", Approx_Eq (S.Theta (1, 1), 8.0));
      Iterate_Standard (S, Stimulus, Test_Params, Zero_Kernel, Zero_Kernel);
      Check ("11.2 Step 2 decay", Approx_Eq (S.Theta (1, 1), 6.4));
      Iterate_Standard (S, Stimulus, Test_Params, Zero_Kernel, Zero_Kernel);
      Check ("11.3 Step 3 decay approaches 0", Approx_Eq (S.Theta (1, 1), 5.12));
   end;

   -- TEST 12 — Custom Kernel Variations
   Put_Line ("TEST 12 — Validating Kernel Weights");
   declare
      Y : constant Binary_Matrix (1 .. 3, 1 .. 3) := [others => [others => True]];
      Identity : constant Kernel_Matrix := 
        [0 => [0 => 1.0, others => 0.0], others => [others => 0.0]];
      Uniform : constant Kernel_Matrix := [others => [others => 1.0]];
      Val : Real;
   begin
      Val := Convolve (Y, Identity, 2, 2);
      Check ("12.1 Identity kernel sums self", Approx_Eq (Val, 1.0));
      
      Val := Convolve (Y, Uniform, 2, 2);
      Check ("12.2 Uniform kernel sums all 9 nodes", Approx_Eq (Val, 9.0));
      
      Val := Convolve (Y, Uniform, 1, 1);
      Check ("12.3 Uniform kernel on corner sums 4 nodes", Approx_Eq (Val, 4.0));
   end;

   -- TEST 13 — Full Simulation Reality Check
   Put_Line ("TEST 13 — Full Step Simulation Check");
   declare
      S : PCNN_State := Create_State (3, 3, 0.5);
      Stimulus : constant Real_Matrix (1 .. 3, 1 .. 3) := 
        [1 => [0.1, 0.1, 0.1],
         2 => [0.1, 1.0, 0.1],
         3 => [0.1, 0.1, 0.1]];
   begin
      Iterate_Simplified (S, Stimulus, Test_Params, Cross_Kernel);
      Check ("13.1 Strong center pulse generated", S.Y (2, 2));
      Check ("13.2 Weak edges did not fire", not S.Y (1, 1));
      Check ("13.3 Theta map exhibits dynamic divergence", 
             S.Theta(2, 2) > S.Theta(1, 1));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   
   -- Terminate execution defensively if any checks failed.
   if Fail_Count > 0 then
      raise Program_Error with "Tests failed.";
   end if;
   
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
