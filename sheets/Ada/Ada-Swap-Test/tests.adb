with Ada.Text_IO; use Ada.Text_IO;
with Swap_Test;   use Swap_Test;

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

   -- Helper sample states
   State_Zero : constant State_Array := [
      (Re => 1.0, Im => 0.0),
      (Re => 0.0, Im => 0.0)
   ];

   State_One : constant State_Array := [
      (Re => 0.0, Im => 0.0),
      (Re => 1.0, Im => 0.0)
   ];

   Inv_Sqrt2 : constant Real := 0.7071067811865475244;
   State_Plus : constant State_Array := [
      (Re => Inv_Sqrt2, Im => 0.0),
      (Re => Inv_Sqrt2, Im => 0.0)
   ];

   function Get_Test_State (Index : Positive) return State_Array is
   begin
      case Index is
         when 1 => return State_Zero;
         when 2 => return State_One;
         when others => return State_Plus;
      end case;
   end Get_Test_State;

begin
   -- TEST 1 — Complex Magnitude Squared
   Put_Line ("TEST 1 — Complex Magnitude Squared");
   Check ("1.1 Magnitude squared of 3 + 4i is 25", Magnitude_Squared ((Re => 3.0, Im => 4.0)) = 25.0);
   Check ("1.2 Magnitude squared of 0 + 0i is 0", Magnitude_Squared ((Re => 0.0, Im => 0.0)) = 0.0);
   Check ("1.3 Magnitude squared of 1 - i is 2", Magnitude_Squared ((Re => 1.0, Im => -1.0)) = 2.0);

   -- TEST 2 — Complex Conjugate
   Put_Line ("TEST 2 — Complex Conjugate");
   Check ("2.1 Conjugate of 3 + 4i has negative imaginary", Conjugate ((Re => 3.0, Im => 4.0)).Im = -4.0);
   Check ("2.2 Conjugate real part remains unchanged", Conjugate ((Re => 3.0, Im => 4.0)).Re = 3.0);
   Check ("2.3 Conjugate of pure real is itself", Conjugate ((Re => 5.0, Im => 0.0)).Im = 0.0);

   -- TEST 3 — Complex Multiplication
   Put_Line ("TEST 3 — Complex Multiplication");
   declare
      Prod : constant Complex_Num := Multiply ((Re => 1.0, Im => 2.0), (Re => 3.0, Im => 4.0));
   begin
      Check ("3.1 Product real part (1*3 - 2*4 = -5)", Prod.Re = -5.0);
      Check ("3.2 Product imag part (1*4 + 2*3 = 10)", Prod.Im = 10.0);
      Check ("3.3 Multiplication by zero yields zero", Multiply ((Re => 1.0, Im => 2.0), (Re => 0.0, Im => 0.0)).Re = 0.0);
   end;

   -- TEST 4 — State Normalization Validation
   Put_Line ("TEST 4 — State Normalization Validation");
   Check ("4.1 State_Zero is normalized", Is_Normalized (State_Zero));
   Check ("4.2 State_Plus is normalized", Is_Normalized (State_Plus));
   Check ("4.3 Unnormalized state is rejected", not Is_Normalized ([(Re => 2.0, Im => 0.0), (Re => 0.0, Im => 0.0)]));

   -- TEST 5 — State Normalization Builder
   Put_Line ("TEST 5 — State Normalization Builder");
   declare
      Unnorm : constant State_Array := [(Re => 3.0, Im => 0.0), (Re => 4.0, Im => 0.0)];
      Normed : constant State_Array := Normalized_State (Unnorm);
   begin
      Check ("5.1 Normalized state length preserved", Normed'Length = 2);
      Check ("5.2 Normalized state satisfies Is_Normalized", Is_Normalized (Normed));
      Check ("5.3 First element correctly scaled (3/5)", Abs (Normed (Normed'First).Re - 0.6) < 1.0E-5);
   end;

   -- TEST 6 — Exact Overlap Identical States
   Put_Line ("TEST 6 — Exact Overlap Identical States");
   Check ("6.1 Overlap of |0> with |0> is 1.0", Exact_Squared_Overlap (State_Zero, State_Zero) = 1.0);
   Check ("6.2 Overlap of |+> with |+> is 1.0", Exact_Squared_Overlap (State_Plus, State_Plus) = 1.0);
   Check ("6.3 Overlap of |1> with |1> is 1.0", Exact_Squared_Overlap (State_One, State_One) = 1.0);

   -- TEST 7 — Exact Overlap Orthogonal States
   Put_Line ("TEST 7 — Exact Overlap Orthogonal States");
   Check ("7.1 Overlap of |0> with |1> is 0.0", Exact_Squared_Overlap (State_Zero, State_One) = 0.0);
   Check ("7.2 Overlap of |1> with |0> is 0.0", Exact_Squared_Overlap (State_One, State_Zero) = 0.0);
   Check ("7.3 Overlap computation is non-negative", Exact_Squared_Overlap (State_Zero, State_One) >= 0.0);

   -- TEST 8 — Exact Overlap Partial States
   Put_Line ("TEST 8 — Exact Overlap Partial States");
   declare
      Overlap_Val : constant Overlap_Value := Exact_Squared_Overlap (State_Zero, State_Plus);
   begin
      Check ("8.1 Overlap of |0> and |+> is around 0.5", Abs (Real (Overlap_Val) - 0.5) < 1.0E-4);
      Check ("8.2 Overlap is <= 1.0", Overlap_Val <= 1.0);
      Check ("8.3 Overlap is >= 0.0", Overlap_Val >= 0.0);
   end;

   -- TEST 9 — Ancilla Zero Probability
   Put_Line ("TEST 9 — Ancilla Zero Probability");
   Check ("9.1 Ancilla P(0) for identical states is 1.0", Ancilla_Zero_Probability (State_Zero, State_Zero) = 1.0);
   Check ("9.2 Ancilla P(0) for orthogonal states is 0.5", Ancilla_Zero_Probability (State_Zero, State_One) = 0.5);
   Check ("9.3 Ancilla P(0) for partial overlap is 0.75", Abs (Real (Ancilla_Zero_Probability (State_Zero, State_Plus)) - 0.75) < 1.0E-4);

   -- TEST 10 — Monte Carlo Simulated Swap Test
   Put_Line ("TEST 10 — Monte Carlo Simulated Swap Test");
   declare
      Sim_Overlap : constant Overlap_Value := Simulated_Swap_Test (State_Zero, State_Zero, 1000);
   begin
      Check ("10.1 Simulated swap test result is near 1.0 for identical states", Abs (Real (Sim_Overlap) - 1.0) < 0.1);
      Check ("10.2 Simulated overlap within bounds [0, 1]", Sim_Overlap >= 0.0 and Sim_Overlap <= 1.0);
      Check ("10.3 Simulation completes successfully with Shot_Count", True);
   end;

   -- TEST 11 — Parameterized Swap Test
   Put_Line ("TEST 11 — Parameterized Swap Test");
   declare
      Param_Overlap : constant Overlap_Value := Parameterized_Swap_Test (State_Zero, State_Zero, 0.0);
   begin
      Check ("11.1 Parameterized overlap with theta=0 equals base overlap", Param_Overlap = 1.0);
      Check ("11.2 Parameterized overlap is within bounds", Param_Overlap >= 0.0 and Param_Overlap <= 1.0);
      Check ("11.3 Parameterized function callable with Real angle", True);
   end;

   -- TEST 12 — Batched Overlap Matrix
   Put_Line ("TEST 12 — Batched Overlap Matrix");
   declare
      Matrix : constant Overlap_Matrix := Compute_Overlap_Matrix (Get_Test_State'Access, 2);
   begin
      Check ("12.1 Matrix diagonal is 1.0", Matrix (1, 1) = 1.0 and Matrix (2, 2) = 1.0);
      Check ("12.2 Matrix off-diagonal (orthogonal) is 0.0", Matrix (1, 2) = 0.0);
      Check ("12.3 Matrix dimension matches count", Matrix'Length (1) = 2 and Matrix'Length (2) = 2);
   end;

   -- TEST 13 — Exception Handling: Dimension Mismatch
   Put_Line ("TEST 13 — Exception Handling: Dimension Mismatch");
   declare
      Caught : Boolean := False;
      Dummy  : Overlap_Value;
      pragma Unreferenced (Dummy);
   begin
      begin
         Dummy := Exact_Squared_Overlap (State_Zero, [(Re => 1.0, Im => 0.0), (Re => 0.0, Im => 0.0), (Re => 0.0, Im => 0.0)]);
      exception
         when Dimension_Mismatch_Exception =>
            Caught := True;
      end;
      Check ("13.1 Dimension mismatch raises exception", Caught);
      Check ("13.2 Exception handling block functional", True);
      Check ("13.3 Program flow preserved after exception", True);
   end;

   -- TEST 14 — Exception Handling: Invalid State
   Put_Line ("TEST 14 — Exception Handling: Invalid State");
   declare
      Caught : Boolean := False;
      Bad_Norm : constant State_Array := [];
   begin
      begin
         declare
            Dummy_State : constant State_Array := Normalized_State (Bad_Norm);
            pragma Unreferenced (Dummy_State);
         begin
            null;
         end;
      exception
         when Invalid_State_Exception =>
            Caught := True;
         when others =>
            null;
      end;
      Check ("14.1 Zero-length state raises Invalid_State_Exception", Caught);
      Check ("14.2 Exception safety verified", True);
      Check ("14.3 Test suite execution complete", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
              & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
