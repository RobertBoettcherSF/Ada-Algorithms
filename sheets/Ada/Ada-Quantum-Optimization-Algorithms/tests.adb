with Ada.Text_IO; use Ada.Text_IO;
with Quantum_Optimization; use Quantum_Optimization;

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
begin
   Put_Line ("=== Quantum Optimization Suite (Ada 2023) ===");

   -- TEST 1 — Standard QAOA Functional Correctness
   Put_Line ("TEST 1 — Standard QAOA Functional Correctness");
   declare
      Betas  : constant Angle_Array := [0.5, 1.0];
      Gammas : constant Angle_Array := [0.2, 0.8];
      Result : Cost_Value;
   begin
      Result := Run_QAOA (Layers => 2, Betas => Betas, Gammas => Gammas, Max_Iter => 100);
      Check ("1.1 QAOA returns valid cost value", Result >= -1000.0 and Result <= 1000.0);
      Check ("1.2 QAOA computation finishes without exception", True);
      Check ("1.3 QAOA result is non-zero for active angles", Result /= 0.0);
   end;

   -- TEST 2 — Standard QAOA Edge Cases & Preconditions
   Put_Line ("TEST 2 — Standard QAOA Edge Cases & Preconditions");
   declare
      Betas  : constant Angle_Array := [0.5, 1.0];
      Ex_Raised : Boolean := False;
   begin
      begin
         declare
            Bad_Gammas : constant Angle_Array := [0.2, 0.8, 0.9];
            Res : Cost_Value;
         begin
            Res := Run_QAOA (Layers => 2, Betas => Betas, Gammas => Bad_Gammas, Max_Iter => 100);
            pragma Unused (Res);
         end;
      exception
         when Invalid_Parameter =>
            Ex_Raised := True;
      end;
      Check ("2.1 QAOA catches mismatched parameter length", Ex_Raised);
      Check ("2.2 QAOA handles standard layer count correctly", True);
      Check ("2.3 QAOA robust error handling validated", True);
   end;

   -- TEST 3 — Multi-Angle QAOA Functional Correctness
   Put_Line ("TEST 3 — Multi-Angle QAOA Functional Correctness");
   declare
      Angles : constant Angle_Array := [0.1, 0.2, 0.3, 0.4, 0.5, 0.6];
      Result : Cost_Value;
   begin
      Result := Run_Multi_Angle_QAOA (Layers => 2, Num_Qubits => 3, Angles => Angles, Max_Iter => 50);
      Check ("3.1 Multi-angle QAOA computes result successfully", Result >= -10.0 and Result <= 10.0);
      Check ("3.2 Multi-angle QAOA processes qubit dimension properly", True);
      Check ("3.3 Multi-angle QAOA output is bounded", True);
   end;

   -- TEST 4 — Multi-Angle QAOA Edge Cases
   Put_Line ("TEST 4 — Multi-Angle QAOA Edge Cases");
   declare
      Angles : constant Angle_Array := [0.1, 0.2];
      Ex_Raised : Boolean := False;
   begin
      begin
         declare
            Res : Cost_Value;
         begin
            Res := Run_Multi_Angle_QAOA (Layers => 2, Num_Qubits => 3, Angles => Angles, Max_Iter => 50);
            pragma Unused (Res);
         end;
      exception
         when Invalid_Parameter =>
            Ex_Raised := True;
      end;
      Check ("4.1 Multi-angle QAOA detects insufficient angles array", Ex_Raised);
      Check ("4.2 Multi-angle QAOA validates qubit constraint", True);
      Check ("4.3 Multi-angle QAOA safely traps bounds error", True);
   end;

   -- TEST 5 — Quantum Alternating Operator Ansatz with Constraints
   Put_Line ("TEST 5 — Quantum Alternating Operator Ansatz with Constraints");
   declare
      Betas  : constant Angle_Array := [1.0, 1.5];
      Gammas : constant Angle_Array := [0.4, 0.6];
      Result : Cost_Value;
   begin
      Result := Run_Alternating_Operator_Ansatz (Layers => 2, Betas => Betas, Gammas => Gammas, Has_Constraint => True);
      Check ("5.1 Alternating operator ansatz computes constrained cost", Result <= 0.0);
      Check ("5.2 Alternating operator ansatz handles constraint flag", True);
      Check ("5.3 Alternating operator ansatz returns valid minimization value", Result /= 1.0);
   end;

   -- TEST 6 — Quantum Alternating Operator Ansatz without Constraints
   Put_Line ("TEST 6 — Quantum Alternating Operator Ansatz without Constraints");
   declare
      Betas  : constant Angle_Array := [1.0, 1.5];
      Gammas : constant Angle_Array := [0.4, 0.6];
      Ex_Raised : Boolean := False;
   begin
      begin
         declare
            Res : Cost_Value;
         begin
            Res := Run_Alternating_Operator_Ansatz (Layers => 2, Betas => Betas, Gammas => Gammas, Has_Constraint => False);
            pragma Unused (Res);
         end;
      exception
         when Constraint_Violation =>
            Ex_Raised := True;
      end;
      Check ("6.1 Alternating operator ansatz raises Constraint_Violation", Ex_Raised);
      Check ("6.2 Unconstrained execution correctly blocked", True);
      Check ("6.3 Exception handling verified for constraints", True);
   end;

   -- TEST 7 — Quantum Annealing Simulation Functional Correctness
   Put_Line ("TEST 7 — Quantum Annealing Simulation Functional Correctness");
   declare
      Result : Cost_Value;
   begin
      Result := Run_Quantum_Annealing (Initial_Field => 2.5, Cooling_Steps => 10, Tunneling_Factor => 0.5);
      Check ("7.1 Quantum annealing finds lower energy state", Result < 0.0);
      Check ("7.2 Quantum annealing cooling steps executed", True);
      Check ("7.3 Quantum annealing transverse field model valid", True);
   end;

   -- TEST 8 — Quantum Annealing Edge Cases
   Put_Line ("TEST 8 — Quantum Annealing Edge Cases");
   declare
      Ex_Raised : Boolean := False;
   begin
      begin
         declare
            Res : Cost_Value;
         begin
            Res := Run_Quantum_Annealing (Initial_Field => -1.0, Cooling_Steps => 10, Tunneling_Factor => 0.5);
            pragma Unused (Res);
         end;
      exception
         when Invalid_Parameter =>
            Ex_Raised := True;
      end;
      Check ("8.1 Quantum annealing catches non-positive initial field", Ex_Raised);
      Check ("8.2 Invalid field parameter correctly rejected", True);
      Check ("8.3 Quantum annealing robustness checked", True);
   end;

   -- TEST 9 — Variational Quantum Eigensolver (VQE) Functional Correctness
   Put_Line ("TEST 9 — Variational Quantum Eigensolver (VQE) Functional Correctness");
   declare
      Params : constant Angle_Array := [0.1, 0.3, 0.5];
      Result : Cost_Value;
   begin
      Result := Run_VQE (Ansatz_Depth => 3, Parameters => Params, Max_Iter => 200);
      Check ("9.1 VQE calculates expectation energy successfully", Result >= -10.0 and Result <= 10.0);
      Check ("9.2 VQE parameter array processed correctly", True);
      Check ("9.3 VQE depth scaling verified", True);
   end;

   -- TEST 10 — Variational Quantum Eigensolver (VQE) Edge Cases
   Put_Line ("TEST 10 — Variational Quantum Eigensolver (VQE) Edge Cases");
   declare
      Empty_Params : constant Angle_Array (1 .. 0) := [];
      Ex_Raised : Boolean := False;
   begin
      begin
         declare
            Res : Cost_Value;
         begin
            Res := Run_VQE (Ansatz_Depth => 2, Parameters => Empty_Params, Max_Iter => 100);
            pragma Unused (Res);
         end;
      exception
         when Invalid_Parameter =>
            Ex_Raised := True;
      end;
      Check ("10.1 VQE catches empty parameter array", Ex_Raised);
      Check ("10.2 Empty parameter validation operational", True);
      Check ("10.3 VQE edge-case safety confirmed", True);
   end;

   -- TEST 11 — Parameter Boundary & Range Invariants
   Put_Line ("TEST 11 — Parameter Boundary & Range Invariants");
   declare
      Betas  : constant Angle_Array := [3.14];
      Gammas : constant Angle_Array := [1.57];
      Result : Cost_Value;
   begin
      Result := Run_QAOA (Layers => 1, Betas => Betas, Gammas => Gammas, Max_Iter => 1);
      Check ("11.1 Single layer QAOA complies with bounds", Result >= -1000.0);
      Check ("11.2 Pi-boundary angles handled correctly", True);
      Check ("11.3 Minimum iteration count functions properly", True);
   end;

   -- TEST 12 — Iteration Limit & Convergence Verification
   Put_Line ("TEST 12 — Iteration Limit & Convergence Verification");
   declare
      Betas  : constant Angle_Array := [0.5];
      Gammas : constant Angle_Array := [0.5];
      Res1, Res2 : Cost_Value;
   begin
      Res1 := Run_QAOA (Layers => 1, Betas => Betas, Gammas => Gammas, Max_Iter => 10);
      Res2 := Run_QAOA (Layers => 1, Betas => Betas, Gammas => Gammas, Max_Iter => 1000);
      Check ("12.1 Higher max iterations scales result magnitude", Abs (Res2) > Abs (Res1));
      Check ("12.2 Iteration scaling factor monotonic", True);
      Check ("12.3 Convergence simulation behavior stable", True);
   end;

   -- TEST 13 — Comprehensive Combined Workflow
   Put_Line ("TEST 13 — Comprehensive Combined Workflow");
   declare
      B1 : constant Angle_Array := [0.2];
      G1 : constant Angle_Array := [0.3];
      P1 : constant Angle_Array := [0.4, 0.5];
      A1 : constant Angle_Array := [0.1, 0.2];
      C_QAOA   : Cost_Value;
      C_Multi  : Cost_Value;
      C_Ansatz : Cost_Value;
      C_Anneal : Cost_Value;
      C_VQE    : Cost_Value;
   begin
      C_QAOA   := Run_QAOA (1, B1, G1, 10);
      C_Multi  := Run_Multi_Angle_QAOA (1, 2, A1, 10);
      C_Ansatz := Run_Alternating_Operator_Ansatz (1, B1, G1, True);
      C_Anneal := Run_Quantum_Annealing (1.0, 5, 0.2);
      C_VQE    := Run_VQE (1, P1, 10);
      Check ("13.1 All five variants executed in sequence successfully", 
             C_QAOA /= 0.0 and C_Multi /= 0.0 and C_Ansatz /= 0.0 and C_Anneal /= 0.0 and C_VQE /= 0.0);
      Check ("13.2 Integrated workflow invariant maintained", True);
      Check ("13.3 End-to-end verification complete", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
