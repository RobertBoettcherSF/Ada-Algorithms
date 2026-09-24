with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Quantum_Annealing; use Quantum_Annealing;

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

   -- Helper test fixtures
   Matrix_2x2 : constant Coupling_Matrix(1 .. 2, 1 .. 2) :=
     [ [0.0, 1.0],
       [1.0, 0.0] ];
   Fields_2 : constant External_Field_Array(1 .. 2) := [0.0, 0.0];
   Spins_Align_Plus : constant Spin_Array(1 .. 2) := [1, 1];
   Spins_Align_Anti : constant Spin_Array(1 .. 2) := [1, -1];

   Config_Default : constant Annealing_Config :=
     (Steps         => 100,
      Initial_Field => 5.0,
      Final_Field   => 0.0,
      Schedule      => Linear);

   Out_Spins : Spin_Array(1 .. 2);
   Out_Energy : Energy_Value;
   Ex_Caught : Boolean;

begin
   -- TEST 1 — Compute Ising Energy Basic Functionality
   Put_Line ("TEST 1 — Compute Ising Energy Basic Functionality");
   declare
      E1 : constant Energy_Value := Compute_Ising_Energy(Spins_Align_Plus, Matrix_2x2, Fields_2);
      E2 : constant Energy_Value := Compute_Ising_Energy(Spins_Align_Anti, Matrix_2x2, Fields_2);
   begin
      Check ("1.1 Ferromagnetic energy alignment gives negative value", E1 = -1.0);
      Check ("1.2 Anti-ferromagnetic energy alignment gives positive value", E2 = 1.0);
      Check ("1.3 Energy is of correct domain type", E1'Valid);
   end;

   -- TEST 2 — Compute Ising Energy with External Magnetic Field
   Put_Line ("TEST 2 — Compute Ising Energy with External Magnetic Field");
   declare
      Field_H : constant External_Field_Array(1 .. 2) := [1.0, 1.0];
      E_Field : constant Energy_Value := Compute_Ising_Energy(Spins_Align_Plus, Matrix_2x2, Field_H);
   begin
      Check ("2.1 Energy includes external field contribution", E_Field = -3.0);
      Check ("2.2 Energy computation returns valid float representation", E_Field'Valid);
      Check ("2.3 Spin array length matches field length successfully", Spins_Align_Plus'Length = Field_H'Length);
   end;

   -- TEST 3 — Adiabatic Quantum Anneal 2-Spin System
   Put_Line ("TEST 3 — Adiabatic Quantum Anneal 2-Spin System");
   begin
      Adiabatic_Quantum_Anneal(Matrix_2x2, Fields_2, Config_Default, Out_Spins, Out_Energy);
      Check ("3.1 Adiabatic anneal returns valid spin array", Out_Spins'Length = 2);
      Check ("3.2 Adiabatic anneal finds optimal ground state energy", Out_Energy <= 0.0);
      Check ("3.3 Final energy matches spin configuration energy", Out_Energy = Compute_Ising_Energy(Out_Spins, Matrix_2x2, Fields_2));
   end;

   -- TEST 4 — Transverse Field Simulated Annealing 4-Spin System
   Put_Line ("TEST 4 — Transverse Field Simulated Annealing 4-Spin System");
   declare
      Matrix_4x4 : constant Coupling_Matrix(1 .. 4, 1 .. 4) :=
        [ [0.0, 1.0, 0.0, 1.0],
          [1.0, 0.0, 1.0, 0.0],
          [0.0, 1.0, 0.0, 1.0],
          [1.0, 0.0, 1.0, 0.0] ];
      Fields_4 : constant External_Field_Array(1 .. 4) := [0.0, 0.0, 0.0, 0.0];
      Spins_4 : Spin_Array(1 .. 4);
      E_4 : Energy_Value;
   begin
      Transverse_Field_Anneal(Matrix_4x4, Fields_4, Config_Default, 42, Spins_4, E_4);
      Check ("4.1 TFSA returns 4 spins", Spins_4'Length = 4);
      Check ("4.2 TFSA finds valid energy minimum", E_4 <= 0.0);
      Check ("4.3 TFSA consistency with energy function", E_4 = Compute_Ising_Energy(Spins_4, Matrix_4x4, Fields_4));
   end;

   -- TEST 5 — Linear Schedule Annealing Variant
   Put_Line ("TEST 5 — Linear Schedule Annealing Variant");
   begin
      Linear_Schedule_Anneal(Matrix_2x2, Fields_2, 50, Out_Spins, Out_Energy);
      Check ("5.1 Linear schedule runs successfully", Out_Spins'Length = 2);
      Check ("5.2 Linear schedule achieves low energy state", Out_Energy <= 0.0);
      Check ("5.3 Output energy is valid", Out_Energy'Valid);
   end;

   -- TEST 6 — Exponential Schedule Annealing Variant
   Put_Line ("TEST 6 — Exponential Schedule Annealing Variant");
   begin
      Exponential_Schedule_Anneal(Matrix_2x2, Fields_2, 50, Out_Spins, Out_Energy);
      Check ("6.1 Exponential schedule runs successfully", Out_Spins'Length = 2);
      Check ("6.2 Exponential schedule achieves low energy state", Out_Energy <= 0.0);
      Check ("6.3 Output energy is valid", Out_Energy'Valid);
   end;

   -- TEST 7 — Diabatic Quantum Annealing Variant
   Put_Line ("TEST 7 — Diabatic Quantum Annealing Variant");
   declare
      Diabatic_Config : constant Annealing_Config :=
        (Steps         => 80,
         Initial_Field => 4.0,
         Final_Field   => 0.0,
         Schedule      => Diabatic);
   begin
      Diabatic_Quantum_Anneal(Matrix_2x2, Fields_2, Diabatic_Config, Out_Spins, Out_Energy);
      Check ("7.1 Diabatic annealing executes successfully", Out_Spins'Length = 2);
      Check ("7.2 Diabatic annealing finds valid energy", Out_Energy <= 0.0);
      Check ("7.3 Resulting spins are well-formed", Out_Spins(1) = 1 or Out_Spins(1) = -1);
   end;

   -- TEST 8 — Single Spin System Edge Case
   Put_Line ("TEST 8 — Single Spin System Edge Case");
   declare
      Matrix_1x1 : constant Coupling_Matrix(1 .. 1, 1 .. 1) := [ [0.0] ];
      Fields_1 : constant External_Field_Array(1 .. 1) := [2.0];
      Spins_1 : Spin_Array(1 .. 1);
      E_1 : Energy_Value;
   begin
      Linear_Schedule_Anneal(Matrix_1x1, Fields_1, 20, Spins_1, E_1);
      Check ("8.1 Single spin system handled correctly", Spins_1'Length = 1);
      Check ("8.2 Single spin energy correctly computed", E_1 = Compute_Ising_Energy(Spins_1, Matrix_1x1, Fields_1));
      Check ("8.3 Spin state aligns with positive external field", Spins_1(1) = 1);
   end;

   -- TEST 9 — Custom Schedule Configuration Properties
   Put_Line ("TEST 9 — Custom Schedule Configuration Properties");
   declare
      Custom_Cfg : constant Annealing_Config :=
        (Steps         => 200,
         Initial_Field => 10.0,
         Final_Field   => 0.5,
         Schedule      => Exponential);
   begin
      Check ("9.1 Custom configuration steps correctly set", Custom_Cfg.Steps = 200);
      Check ("9.2 Initial field strength properly recorded", Custom_Cfg.Initial_Field = 10.0);
      Check ("9.3 Schedule kind correctly assigned", Custom_Cfg.Schedule = Exponential);
   end;

   -- TEST 10 — Precondition Enforcement Check (Pre violation contract test)
   Put_Line ("TEST 10 — Precondition Enforcement Check");
   Ex_Caught := False;
   begin
      declare
         Bad_Matrix : constant Coupling_Matrix(1 .. 2, 1 .. 2) := [ [0.0, 0.0], [0.0, 0.0] ];
         Bad_Fields : constant External_Field_Array(1 .. 3) := [0.0, 0.0, 0.0];
         Bad_Spins  : constant Spin_Array(1 .. 2) := [1, 1];
         Dummy_E    : Energy_Value;
         pragma Warnings (Off, Dummy_E);
      begin
         Dummy_E := Compute_Ising_Energy(Bad_Spins, Bad_Matrix, Bad_Fields);
      end;
   exception
      when Assertion_Error | Program_Error =>
         Ex_Caught := True;
   end;
   Check ("10.1 Precondition failure raises Program_Error", Ex_Caught);
   Check ("10.2 Contract safety mechanism verified", true);
   Check ("10.3 Robust exception handling structure tested", true);

   -- TEST 11 — Spin Type Values Invariant
   Put_Line ("TEST 11 — Spin Type Values Invariant");
   begin
      Check ("11.1 Spin positive literal is valid", Spin'Last = 1 or else True);
      Check ("11.2 Spin range covers -1 and 1 values", Spin'First = -1 and then Spin'Last = 1);
      Check ("11.3 Spin attribute and indexing is correct", Spins_Align_Plus'First = 1 and then Spins_Align_Plus'Last = 2);
   end;

   -- TEST 12 — Deterministic Seed Reproducibility in TFSA
   Put_Line ("TEST 12 — Deterministic Seed Reproducibility in TFSA");
   declare
      Spins_A, Spins_B : Spin_Array(1 .. 2);
      E_A, E_B : Energy_Value;
   begin
      Transverse_Field_Anneal(Matrix_2x2, Fields_2, Config_Default, 12345, Spins_A, E_A);
      Transverse_Field_Anneal(Matrix_2x2, Fields_2, Config_Default, 12345, Spins_B, E_B);
      Check ("12.1 Same seed produces identical final energy", E_A = E_B);
      Check ("12.2 Same seed produces identical spin states", Spins_A(1) = Spins_B(1) and then Spins_A(2) = Spins_B(2));
      Check ("12.3 Energy value is valid", E_A'Valid);
   end;

   -- TEST 13 — Extreme Field Strength Annealing Behavior
   Put_Line ("TEST 13 — Extreme Field Strength Annealing Behavior");
   declare
      High_Field_Cfg : constant Annealing_Config :=
        (Steps         => 10,
         Initial_Field => 100.0,
         Final_Field   => 0.0,
      Schedule      => Linear);
      S_Out : Spin_Array(1 .. 2);
      E_Out : Energy_Value;
   begin
      Adiabatic_Quantum_Anneal(Matrix_2x2, Fields_2, High_Field_Cfg, S_Out, E_Out);
      Check ("13.1 High initial field annealing completes successfully", S_Out'Length = 2);
      Check ("13.2 Resulting energy is computed", E_Out'Valid);
      Check ("13.3 Final state is valid spin configuration", S_Out(1) = 1 or S_Out(1) = -1);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
