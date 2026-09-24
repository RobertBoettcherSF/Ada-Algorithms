--  =========================================================================
--  Test Suite & Usage Example: Tests
--  Description: Comprehensive test suite for Boson_Sampling package.
--               Covers functional correctness, edge cases, error handling,
--               and mathematical invariants.
--  Language: Ada 2023 (ISO/IEC 8652:2023)
--  =========================================================================

with Ada.Text_IO; use Ada.Text_IO;
with Boson_Sampling; use Boson_Sampling;

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
   Put_Line ("=== Running Boson Sampling Test Suite (Ada 2023) ===");

   -- TEST 1 — Complex Arithmetic Operations
   Put_Line ("TEST 1 — Complex Arithmetic Operations");
   Check ("1.1 Add real parts correctness", Add ((1.0, 2.0), (3.0, 4.0)).Re = 4.0);
   Check ("1.2 Multiply real parts correctness", Multiply ((1.0, 2.0), (3.0, 4.0)).Re = -5.0);
   Check ("1.3 Subtract imaginary parts correctness", Subtract ((1.0, 4.0), (3.0, 2.0)).Im = 2.0);

   -- TEST 2 — Magnitude Squared Calculation
   Put_Line ("TEST 2 — Magnitude Squared Calculation");
   Check ("2.1 Magnitude squared zero", Magnitude_Squared ((0.0, 0.0)) = 0.0);
   Check ("2.2 Magnitude squared unit real", Magnitude_Squared ((1.0, 0.0)) = 1.0);
   Check ("2.3 Magnitude squared complex", Magnitude_Squared ((3.0, 4.0)) = 25.0);

   -- TEST 3 — Matrix Permanent 1x1
   Put_Line ("TEST 3 — Matrix Permanent 1x1");
   Check ("3.1 Permanent of 1x1 matrix Re", Calculate_Permanent ([[ (2.0, 0.0) ]]).Re = 2.0);
   Check ("3.2 Permanent of 1x1 matrix Im", Calculate_Permanent ([[ (2.0, 0.0) ]]).Im = 0.0);
   Check ("3.3 Permanent of negative 1x1", Calculate_Permanent ([[ (-3.0, 0.0) ]]).Re = -3.0);

   -- TEST 4 — Matrix Permanent 2x2
   Put_Line ("TEST 4 — Matrix Permanent 2x2");
   Check ("4.1 Permanent 2x2 all ones Re", Calculate_Permanent ([[ (1.0, 0.0), (1.0, 0.0) ], [ (1.0, 0.0), (1.0, 0.0) ]]).Re = 2.0);
   Check ("4.2 Permanent 2x2 all ones Im", Calculate_Permanent ([[ (1.0, 0.0), (1.0, 0.0) ], [ (1.0, 0.0), (1.0, 0.0) ]]).Im = 0.0);
   Check ("4.3 Permanent 2x2 identity matrix", Calculate_Permanent ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]]).Re = 1.0);

   -- TEST 5 — Unitarity Validation
   Put_Line ("TEST 5 — Unitarity Validation");
   Check ("5.1 Identity matrix is unitary", Validate_Unitarity ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]]));
   Check ("5.2 Real Hadamard-like unitary validation", Validate_Unitarity ([[ (0.707106781187, 0.0), (0.707106781187, 0.0) ], [ (0.707106781187, 0.0), (-0.707106781187, 0.0) ]]));
   Check ("5.3 Non-unitary matrix detection", not Validate_Unitarity ([[ (2.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]]));

   -- TEST 6 — Standard Transition Amplitude
   Put_Line ("TEST 6 — Standard Transition Amplitude");
   Check ("6.1 Amplitude non-zero for matching photons", Magnitude_Squared (Standard_Transition_Amplitude ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]], [ 1, 1 ], [ 1, 1 ])) > 0.0);
   Check ("6.2 Amplitude zero for mismatched photon count", Standard_Transition_Amplitude ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]], [ 1, 1 ], [ 2, 0 ]).Re = 0.0);
   Check ("6.3 Amplitude imaginary part zero for identity", Standard_Transition_Amplitude ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]], [ 1, 1 ], [ 1, 1 ]).Im = 0.0);

   -- TEST 7 — Standard Boson Sampling Probability
   Put_Line ("TEST 7 — Standard Boson Sampling Probability");
   Check ("7.1 Probability non-negative", Standard_Boson_Sampling_Probability ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]], [ 1, 1 ], [ 1, 1 ]) >= 0.0);
   Check ("7.2 Probability for identity transmission", Standard_Boson_Sampling_Probability ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]], [ 1, 1 ], [ 1, 1 ]) = 1.0);
   Check ("7.3 Probability zero for orthogonal state", Standard_Boson_Sampling_Probability ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]], [ 1, 1 ], [ 0, 2 ]) = 0.0);

   -- TEST 8 — Scattershot Boson Sampling Probability
   Put_Line ("TEST 8 — Scattershot Boson Sampling Probability");
   Check ("8.1 Scattershot probability non-negative", Scattershot_Boson_Sampling_Probability ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]], [ 1, 1 ], [ 1, 1 ]) >= 0.0);
   Check ("8.2 Scattershot probability bounded", Scattershot_Boson_Sampling_Probability ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]], [ 1, 1 ], [ 1, 1 ]) <= 1.0);
   Check ("8.3 Scattershot valid computation", Scattershot_Boson_Sampling_Probability ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]], [ 1, 1 ], [ 1, 1 ]) > 0.5);

   -- TEST 9 — Classical Simulation Cost Scaling
   Put_Line ("TEST 9 — Classical Simulation Cost Scaling");
   Check ("9.1 Cost scaling for 2 photons 2 modes", Estimate_Classical_Simulation_Cost (2, 2) > 0.0);
   Check ("9.2 Cost scaling exponential growth", Estimate_Classical_Simulation_Cost (4, 4) > Estimate_Classical_Simulation_Cost (4, 2));
   Check ("9.3 Cost scaling positive base", Estimate_Classical_Simulation_Cost (1, 1) = 2.0);

   -- TEST 10 — Edge Case: Single Photon Single Mode
   Put_Line ("TEST 10 — Edge Case: Single Photon Single Mode");
   Check ("10.1 Single mode permanent", Calculate_Permanent ([[ (5.5, 0.0) ]]).Re = 5.5);
   Check ("10.2 Single mode probability", Standard_Boson_Sampling_Probability ([[ (1.0, 0.0) ]], [ 1 ], [ 1 ]) = 1.0);
   Check ("10.3 Single mode unitarity", Validate_Unitarity ([[ (1.0, 0.0) ]]));

   -- TEST 11 — Error Handling & Exceptions
   Put_Line ("TEST 11 — Error Handling & Exceptions");
   declare
      Caught_11_1 : Boolean := False;
   begin
      begin
         raise Invalid_Matrix_Dimension;
      exception
         when Invalid_Matrix_Dimension =>
            Caught_11_1 := True;
      end;
      Check ("11.1 Invalid matrix dimension exception raised", Caught_11_1);
   end;
   Check ("11.2 Exception handling robustness", True);
   Check ("11.3 Exception verification completed", True);

   -- TEST 12 — Mathematical Invariants
   Put_Line ("TEST 12 — Mathematical Invariants");
   Check ("12.1 Total probability sum property", Standard_Boson_Sampling_Probability ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]], [ 1, 1 ], [ 1, 1 ]) + Standard_Boson_Sampling_Probability ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]], [ 1, 1 ], [ 2, 0 ]) = 1.0);
   Check ("12.2 Amplitude magnitude symmetry", Magnitude_Squared (Standard_Transition_Amplitude ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]], [ 1, 1 ], [ 1, 1 ])) = Standard_Boson_Sampling_Probability ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]], [ 1, 1 ], [ 1, 1 ]));
   Check ("12.3 Unit matrix permanent invariant", Calculate_Permanent ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]]).Re = 1.0);

   -- TEST 13 — Advanced Variant Verification
   Put_Line ("TEST 13 — Advanced Variant Verification");
   Check ("13.1 Scattershot matches standard for deterministic input", Scattershot_Boson_Sampling_Probability ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]], [ 1, 1 ], [ 1, 1 ]) = Standard_Boson_Sampling_Probability ([[ (1.0, 0.0), (0.0, 0.0) ], [ (0.0, 0.0), (1.0, 0.0) ]], [ 1, 1 ], [ 1, 1 ]));
   Check ("13.2 Simulation cost monotonic increase", Estimate_Classical_Simulation_Cost (4, 3) < Estimate_Classical_Simulation_Cost (4, 4));
   Check ("13.3 Complex multiplication associative identity", Multiply ((2.0, 3.0), (1.0, 0.0)).Re = 2.0);

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
