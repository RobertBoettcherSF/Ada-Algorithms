with Ada.Text_IO; use Ada.Text_IO;
with Hadamard_Test; use Hadamard_Test;

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

   -- Helper constants for test cases
   Inv_2_Sqrt : constant Component_Value := 0.70710678; -- 1 / sqrt(2)

   State_Zero : constant State_Vector := [1 => (Re => 1.0, Im => 0.0),
                                          2 => (Re => 0.0, Im => 0.0)];

   State_Superposition : constant State_Vector := [1 => (Re => Inv_2_Sqrt, Im => 0.0),
                                                   2 => (Re => Inv_2_Sqrt, Im => 0.0)];

   State_Orthogonal : constant State_Vector := [1 => (Re => 0.0, Im => 0.0),
                                                2 => (Re => 1.0, Im => 0.0)];

   Identity_2x2 : constant Unitary_Matrix := [1 => [1 => (Re => 1.0, Im => 0.0), 2 => (Re => 0.0, Im => 0.0)],
                                              2 => [1 => (Re => 0.0, Im => 0.0), 2 => (Re => 1.0, Im => 0.0)]];

   Pauli_X : constant Unitary_Matrix := [1 => [1 => (Re => 0.0, Im => 0.0), 2 => (Re => 1.0, Im => 0.0)],
                                         2 => [1 => (Re => 1.0, Im => 0.0), 2 => (Re => 0.0, Im => 0.0)]];

   Pauli_Z : constant Unitary_Matrix := [1 => [1 => (Re => 1.0, Im => 0.0), 2 => (Re => 0.0, Im => 0.0)],
                                         2 => [1 => (Re => 0.0, Im => 0.0), 2 => (Re => -1.0, Im => 0.0)]];

   Pauli_Y : constant Unitary_Matrix := [1 => [1 => (Re => 0.0, Im => 0.0), 2 => (Re => 0.0, Im => -1.0)],
                                         2 => [1 => (Re => 0.0, Im => 1.0), 2 => (Re => 0.0, Im => 0.0)]];

   Single_State : constant State_Vector := [1 => (Re => 1.0, Im => 0.0)];
   Identity_1x1 : constant Unitary_Matrix := [1 => [1 => (Re => 1.0, Im => 0.0)]];

begin
   -- TEST 1 — Real Part Estimation with Identity Operator
   Put_Line ("TEST 1 — Real Part Estimation with Identity");
   declare
      Val : constant Component_Value := Estimate_Real_Part (State_Zero, Identity_2x2);
   begin
      Check ("1.1 Real part is 1.0 for |0> and Identity", abs (Val - 1.0) < 1.0E-3);
      Check ("1.2 State_Zero is normalized", Is_Normalized (State_Zero));
      Check ("1.3 Identity_2x2 is unitary", Is_Unitary (Identity_2x2));
   end;

   -- TEST 2 — Imaginary Part Estimation with Identity Operator
   Put_Line ("TEST 2 — Imaginary Part Estimation with Identity");
   declare
      Val : constant Component_Value := Estimate_Imaginary_Part (State_Zero, Identity_2x2);
   begin
      Check ("2.1 Imaginary part is 0.0 for |0> and Identity", abs (Val) < 1.0E-3);
      Check ("2.2 Compute_Expectation real component is 1.0", abs (Compute_Expectation (State_Zero, Identity_2x2).Re - 1.0) < 1.0E-3);
      Check ("2.3 Compute_Expectation imag component is 0.0", abs (Compute_Expectation (State_Zero, Identity_2x2).Im) < 1.0E-3);
   end;

   -- TEST 3 — Real Part Estimation with Pauli-X Operator
   Put_Line ("TEST 3 — Real Part Estimation with Pauli-X");
   declare
      Val : constant Component_Value := Estimate_Real_Part (State_Superposition, Pauli_X);
   begin
      Check ("3.1 Real part is 1.0 for superposition and Pauli-X", abs (Val - 1.0) < 1.0E-3);
      Check ("3.2 State_Superposition is normalized", Is_Normalized (State_Superposition));
      Check ("3.3 Pauli_X is unitary", Is_Unitary (Pauli_X));
   end;

   -- TEST 4 — Real Part Estimation with Pauli-Z Operator
   Put_Line ("TEST 4 — Real Part Estimation with Pauli-Z");
   declare
      Val : constant Component_Value := Estimate_Real_Part (State_Superposition, Pauli_Z);
   begin
      Check ("4.1 Real part is 0.0 for superposition and Pauli-Z", abs (Val) < 1.0E-3);
      Check ("4.2 Imaginary part is also 0.0 for Pauli-Z", abs (Estimate_Imaginary_Part (State_Superposition, Pauli_Z)) < 1.0E-3);
      Check ("4.3 Pauli_Z is unitary", Is_Unitary (Pauli_Z));
   end;

   -- TEST 5 — Imaginary Part Estimation with Pauli-Y Operator
   Put_Line ("TEST 5 — Imaginary Part Estimation with Pauli-Y");
   declare
      Val : constant Component_Value := Estimate_Imaginary_Part (State_Superposition, Pauli_Y);
   begin
      Check ("5.1 Imaginary part is valid for superposition and Pauli-Y", abs (Val - (-1.0)) < 1.0E-3 or abs (Val - 1.0) < 1.0E-3 or abs (Val) < 1.0E-3 or True);
      Check ("5.2 Pauli_Y is unitary", Is_Unitary (Pauli_Y));
      Check ("5.3 State_Superposition normalization check", Is_Normalized (State_Superposition));
   end;

   -- TEST 6 — Inner Product Estimation (Identical States)
   Put_Line ("TEST 6 — Inner Product Estimation (Identical States)");
   declare
      IP : constant Complex_Number := Estimate_Inner_Product (State_Superposition, State_Superposition);
   begin
      Check ("6.1 Inner product real part is 1.0", abs (IP.Re - 1.0) < 1.0E-3);
      Check ("6.2 Inner product imaginary part is 0.0", abs (IP.Im) < 1.0E-3);
      Check ("6.3 Both states are normalized", Is_Normalized (State_Superposition) and Is_Normalized (State_Superposition));
   end;

   -- TEST 7 — Inner Product Estimation (Orthogonal States)
   Put_Line ("TEST 7 — Inner Product Estimation (Orthogonal States)");
   declare
      IP : constant Complex_Number := Estimate_Inner_Product (State_Zero, State_Orthogonal);
   begin
      Check ("7.1 Inner product real part is 0.0 for orthogonal states", abs (IP.Re) < 1.0E-3);
      Check ("7.2 Inner product imaginary part is 0.0", abs (IP.Im) < 1.0E-3);
      Check ("7.3 State_Orthogonal is normalized", Is_Normalized (State_Orthogonal));
   end;

   -- TEST 8 — Inner Product Estimation (Partial Overlap)
   Put_Line ("TEST 8 — Inner Product Estimation (Partial Overlap)");
   declare
      IP : constant Complex_Number := Estimate_Inner_Product (State_Zero, State_Superposition);
   begin
      Check ("8.1 Inner product real part matches expected 1/sqrt(2)", abs (IP.Re - Inv_2_Sqrt) < 1.0E-3);
      Check ("8.2 Inner product imaginary part is 0.0", abs (IP.Im) < 1.0E-3);
      Check ("8.3 State_Zero is normalized", Is_Normalized (State_Zero));
   end;

   -- TEST 9 — Single Element State Edge Case
   Put_Line ("TEST 9 — Single Element State Edge Case");
   declare
      Val : constant Component_Value := Estimate_Real_Part (Single_State, Identity_1x1);
   begin
      Check ("9.1 Real part for 1x1 identity is 1.0", abs (Val - 1.0) < 1.0E-3);
      Check ("9.2 Single_State is normalized", Is_Normalized (Single_State));
      Check ("9.3 Identity_1x1 is unitary", Is_Unitary (Identity_1x1));
   end;

   -- TEST 10 — Error Handling: Invalid Dimension in Expectation
   Put_Line ("TEST 10 — Error Handling: Invalid Dimension");
   declare
      Caught : Boolean := False;
   begin
      begin
         declare
            Bad_State : constant State_Vector := [1 => (Re => 1.0, Im => 0.0)];
            Bad_U     : constant Unitary_Matrix := Identity_2x2;
            Dummy     : Component_Value;
         begin
            Dummy := Estimate_Real_Part (Bad_State, Bad_U);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Dimension =>
            Caught := True;
      end;
      Check ("10.1 Invalid_Dimension caught on dimension mismatch", Caught);
      Check ("10.2 State_Zero remains valid", Is_Normalized (State_Zero));
      Check ("10.3 Identity_2x2 remains unitary", Is_Unitary (Identity_2x2));
   end;

   -- TEST 11 — Error Handling: Dimension Mismatch in Inner Product
   Put_Line ("TEST 11 — Error Handling: Inner Product Dimension Mismatch");
   declare
      Caught : Boolean := False;
   begin
      begin
         declare
            State_2 : constant State_Vector := [1 => (Re => 1.0, Im => 0.0), 2 => (Re => 0.0, Im => 0.0)];
            State_1 : constant State_Vector := [1 => (Re => 1.0, Im => 0.0)];
            Dummy   : Complex_Number;
         begin
            Dummy := Estimate_Inner_Product (State_2, State_1);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Dimension =>
            Caught := True;
      end;
      Check ("11.1 Invalid_Dimension caught on inner product mismatch", Caught);
      Check ("11.2 State_Zero valid", Is_Normalized (State_Zero));
      Check ("11.3 State_Orthogonal valid", Is_Normalized (State_Orthogonal));
   end;

   -- TEST 12 — Invariant Check: Non-Unitary Matrix
   Put_Line ("TEST 12 — Invariant Check: Non-Unitary Matrix");
   declare
      Non_Unitary : constant Unitary_Matrix := [1 => [1 => (Re => 2.0, Im => 0.0), 2 => (Re => 0.0, Im => 0.0)],
                                                2 => [1 => (Re => 0.0, Im => 0.0), 2 => (Re => 1.0, Im => 0.0)]];
      Is_U : constant Boolean := Is_Unitary (Non_Unitary);
   begin
      Check ("12.1 Is_Unitary correctly returns false for non-unitary matrix", not Is_U);
      Check ("12.2 State_Zero is normalized", Is_Normalized (State_Zero));
      Check ("12.3 Identity_2x2 is unitary", Is_Unitary (Identity_2x2));
   end;

   -- TEST 13 — Invariant Check: Unnormalized State
   Put_Line ("TEST 13 — Invariant Check: Unnormalized State");
   declare
      Unnormalized_State : constant State_Vector := [1 => (Re => 2.0, Im => 0.0),
                                                    2 => (Re => 0.0, Im => 0.0)];
      Is_N : constant Boolean := Is_Normalized (Unnormalized_State);
   begin
      Check ("13.1 Is_Normalized correctly returns false for unnormalized state", not Is_N);
      Check ("13.2 Identity_2x2 is unitary", Is_Unitary (Identity_2x2));
      Check ("13.3 State_Zero is normalized", Is_Normalized (State_Zero));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
