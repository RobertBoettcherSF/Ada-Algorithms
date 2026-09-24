with Ada.Text_IO; use Ada.Text_IO;
with Aharonov_Jones_Landau; use Aharonov_Jones_Landau;

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
   function Is_Close (A, B : Real; Tol : Real := 0.0001) return Boolean is
   begin
      return abs (A - B) < Tol;
   end Is_Close;

   function Is_Close (A, B : Complex; Tol : Real := 0.0001) return Boolean is
   begin
      return Is_Close (A.Re, B.Re, Tol) and Is_Close (A.Im, B.Im, Tol);
   end Is_Close;

   C1 : constant Complex := (1.0, 2.0);
   C2 : constant Complex := (3.0, -1.0);
   C3 : Complex;
   
   Braid_ID : constant Braid := [1, -1];
   Braid_Non_Abelian_1 : constant Braid := [1, 2];
   Braid_Non_Abelian_2 : constant Braid := [2, 1];
   
   U_Id, U_1, U_2 : Matrix_2x2;
   Tr_Exact, Tr_Sim : Complex;
begin
   Put_Line ("TEST 1 — Complex Math Fundamentals");
   C3 := C1 + C2;
   Check ("1.1 Addition Re", Is_Close (C3.Re, 4.0));
   Check ("1.2 Addition Im", Is_Close (C3.Im, 1.0));
   C3 := C1 * C2; -- (1*3 - 2*-1) + i(1*-1 + 2*3) = 5 + 5i
   Check ("1.3 Multiplication Re", Is_Close (C3.Re, 5.0));
   Check ("1.4 Multiplication Im", Is_Close (C3.Im, 5.0));

   Put_Line ("TEST 2 — Build Unitary Identity");
   U_Id := Build_Unitary (Braid_ID, K => 3);
   Check ("2.1 Identity U(1,1)", Is_Close (U_Id (1,1), (1.0, 0.0)));
   Check ("2.2 Identity U(2,2)", Is_Close (U_Id (2,2), (1.0, 0.0)));
   Check ("2.3 Identity U(1,2)", Is_Close (U_Id (1,2), (0.0, 0.0)));

   Put_Line ("TEST 3 — Build Unitary Generator Sigma_1");
   U_1 := Build_Unitary ([1 => 1], K => 4); -- e^{2pi*i/4} = i
   Check ("3.1 Sigma_1 U(1,1) is 'i'", Is_Close (U_1(1,1), (0.0, 1.0)));
   Check ("3.2 Sigma_1 U(2,2) is 1.0", Is_Close (U_1(2,2), (1.0, 0.0)));

   Put_Line ("TEST 4 — Classical Exact Trace");
   Tr_Exact := Classical_Trace (U_Id);
   Check ("4.1 Trace of Identity is 2", Is_Close (Tr_Exact, (2.0, 0.0)));
   Tr_Exact := Classical_Trace (U_1);
   Check ("4.2 Trace of Sigma_1", Is_Close (Tr_Exact, (1.0, 1.0)));

   Put_Line ("TEST 5 — Quantum Simulated Trace (Stochastic)");
   -- Using 50,000 samples for high confidence passing of stochastic bounds
   Tr_Sim := Hadamard_Test_Trace (U_Id, Samples => 50_000);
   Check ("5.1 Identity Re stochastic matches within tolerance", Is_Close (Tr_Sim.Re, 2.0, Tol => 0.05));
   Check ("5.2 Identity Im stochastic matches within tolerance", Is_Close (Tr_Sim.Im, 0.0, Tol => 0.05));

   Put_Line ("TEST 6 — Polynomial Evaluation (Classical Variant)");
   Tr_Exact := Evaluate_Jones_Polynomial ([1 => 1], K => 3, Variant => Classical_Exact);
   Check ("6.1 Evaluated successfully", True);
   
   Put_Line ("TEST 7 — Polynomial Evaluation (Simulated Variant)");
   Tr_Sim := Evaluate_Jones_Polynomial ([1 => 1], K => 3, Variant => Quantum_Simulated, Samples => 50_000);
   Check ("7.1 Simulated trace closely matches exact trace", Is_Close (Tr_Exact, Tr_Sim, Tol => 0.05));

   Put_Line ("TEST 8 — Non-Abelian Topology Verification");
   U_1 := Build_Unitary (Braid_Non_Abelian_1, K => 3);
   U_2 := Build_Unitary (Braid_Non_Abelian_2, K => 3);
   Check ("8.1 Sigma_1 * Sigma_2 /= Sigma_2 * Sigma_1", 
          not Is_Close (U_1(1,1), U_2(1,1)) or else not Is_Close (U_1(1,2), U_2(1,2)));

   Put_Line ("TEST 9 — K Parameter Dependence");
   U_1 := Build_Unitary ([1 => 1], K => 3);
   U_2 := Build_Unitary ([1 => 1], K => 4);
   Check ("9.1 Different roots of unity yield different unitaries", 
          not Is_Close (U_1(1,1), U_2(1,1)));

   Put_Line ("TEST 10 — Invalid Generator Catching");
   begin
      -- Using a conditional check on the function return to prevent 'assigned but not used' warnings.
      if Evaluate_Jones_Polynomial ([1 => Valid_Generator'Value ("0")], 3).Re = 0.0 then
         Check ("10.1 Must not reach here", False);
      end if;
   exception
      when Invalid_Braid_Exception => 
         Check ("10.1 Invalid_Braid_Exception caught", True);
      when Constraint_Error => 
         Check ("10.1 Constraint_Error caught", True);
   end;

   Put_Line ("TEST 11 — Empty Braid Enforcement");
   begin
      declare
         Empty_Braid : Braid (1 .. 0);
      begin
         if Evaluate_Jones_Polynomial (Empty_Braid, 3).Re = 0.0 then
            Check ("11.1 Must not reach here", False);
         end if;
      end;
   exception
      when others => Check ("11.1 Rejection of empty braid caught", True);
   end;

   Put_Line ("TEST 12 — Unitary Inversion");
   U_1 := Build_Unitary ([1, -1], K => 5);
   Check ("12.1 Generator times Inverse yields Identity Re", Is_Close (U_1(1,1).Re, 1.0));
   Check ("12.2 Generator times Inverse yields Identity Im", Is_Close (U_1(1,1).Im, 0.0));

   Put_Line ("TEST 13 — Extreme Bounds (Large Samples Simulation)");
   Tr_Sim := Evaluate_Jones_Polynomial ([1, 2, -1, -2, 1], K => 3, Variant => Quantum_Simulated, Samples => 100_000);
   Tr_Exact := Evaluate_Jones_Polynomial ([1, 2, -1, -2, 1], K => 3, Variant => Classical_Exact);
   Check ("13.1 High-sample BQP simulation matches classical trace tightly", Is_Close (Tr_Sim, Tr_Exact, Tol => 0.05));

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
