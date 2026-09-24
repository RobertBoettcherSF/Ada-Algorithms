with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Radial_Basis_Function_Network; use Radial_Basis_Function_Network;

procedure Tests is
   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

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

   function Is_Close (A, B : Real; Tol : Real := 1.0e-9) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Is_Close;

   --  Reusable variables for testing
   V1, V2, V3 : Feature_Vector (1 .. 2);
   Act        : Real;
   Net_Valid  : constant RBF_Network := Create_Network
     (Centers => [[1 => 0.0, 2 => 0.0], [1 => 2.0, 2 => 2.0]],
      Weights => [1 => 1.0, 2 => -1.0],
      Bias    => 0.0,
      Shape   => 1.0,
      Function_Type => Gaussian,
      Is_Normalized => False);

begin
   --  TEST 1: Euclidean Distance Functionality
   Put_Line ("TEST 1 -- Euclidean Distance Valid");
   V1 := [0.0, 0.0];
   V2 := [3.0, 4.0];
   V3 := [-1.0, 1.0];
   Check ("1.1 Zeros to zeros gives 0.0", Is_Close (Real (Euclidean_Distance (V1, V1)), 0.0));
   Check ("1.2 3-4-5 Triangle gives 5.0", Is_Close (Real (Euclidean_Distance (V1, V2)), 5.0));
   Check ("1.3 Distance between V2 and V3", Is_Close (Real (Euclidean_Distance (V2, V3)), 5.0));

   --  TEST 2: Euclidean Distance Dimension Errors
   Put_Line ("TEST 2 -- Euclidean Distance Error Handling");
   declare
      V_Short : constant Feature_Vector (1 .. 1) := [1 => 0.0];
      V_Long  : constant Feature_Vector (1 .. 3) := [1 => 0.0, 2 => 0.0, 3 => 0.0];
   begin
      begin
         declare
            Dummy_Dist : constant Distance := Euclidean_Distance (V1, V_Short);
            pragma Unreferenced (Dummy_Dist);
         begin
            Check ("2.1 Length 2 vs Length 1 (expected failure)", False);
         end;
      exception
         when Dimension_Mismatch_Error => Check ("2.1 Caught Length 2 vs 1 correctly", True);
         when others => Check ("2.1 Wrong exception caught", False);
      end;
      
      begin
         declare
            Dummy_Dist : constant Distance := Euclidean_Distance (V_Short, V1);
            pragma Unreferenced (Dummy_Dist);
         begin
            Check ("2.2 Length 1 vs Length 2 (expected failure)", False);
         end;
      exception
         when Dimension_Mismatch_Error => Check ("2.2 Caught Length 1 vs 2 correctly", True);
         when others => Check ("2.2 Wrong exception caught", False);
      end;
      
      begin
         declare
            Dummy_Dist : constant Distance := Euclidean_Distance (V_Long, V1);
            pragma Unreferenced (Dummy_Dist);
         begin
            Check ("2.3 Length 3 vs Length 2 (expected failure)", False);
         end;
      exception
         when Dimension_Mismatch_Error => Check ("2.3 Caught Length 3 vs 2 correctly", True);
         when others => Check ("2.3 Wrong exception caught", False);
      end;
   end;

   --  TEST 3: Activation - Gaussian
   Put_Line ("TEST 3 -- Activation (Gaussian)");
   Act := Calculate_Activation (0.0, 1.0, Gaussian);
   Check ("3.1 Dist 0.0 gives Exp(0) = 1.0", Is_Close (Act, 1.0));
   Act := Calculate_Activation (1.0, 1.0, Gaussian);
   Check ("3.2 Dist 1.0, Shape 1.0 gives Exp(-1)", Is_Close (Act, Exp (-1.0)));
   Act := Calculate_Activation (2.0, 0.5, Gaussian);
   Check ("3.3 Dist 2.0, Shape 0.5 gives Exp(-1)", Is_Close (Act, Exp (-1.0)));

   --  TEST 4: Activation - Multiquadric
   Put_Line ("TEST 4 -- Activation (Multiquadric)");
   Act := Calculate_Activation (0.0, 1.0, Multiquadric);
   Check ("4.1 Dist 0.0 gives Sqrt(1) = 1.0", Is_Close (Act, 1.0));
   Act := Calculate_Activation (1.0, 1.0, Multiquadric);
   Check ("4.2 Dist 1.0 gives Sqrt(2)", Is_Close (Act, Sqrt (2.0)));
   Act := Calculate_Activation (2.0, 0.5, Multiquadric);
   Check ("4.3 Dist 2.0, Shape 0.5 gives Sqrt(2)", Is_Close (Act, Sqrt (2.0)));

   --  TEST 5: Activation - Inverse Quadratic
   Put_Line ("TEST 5 -- Activation (Inverse Quadratic)");
   Act := Calculate_Activation (0.0, 1.0, Inverse_Quadratic);
   Check ("5.1 Dist 0.0 gives 1/(1+0) = 1.0", Is_Close (Act, 1.0));
   Act := Calculate_Activation (1.0, 1.0, Inverse_Quadratic);
   Check ("5.2 Dist 1.0 gives 1/(1+1) = 0.5", Is_Close (Act, 0.5));
   Act := Calculate_Activation (3.0, 1.0, Inverse_Quadratic);
   Check ("5.3 Dist 3.0 gives 1/(1+9) = 0.1", Is_Close (Act, 0.1));

   --  TEST 6: Activation - Inverse Multiquadric
   Put_Line ("TEST 6 -- Activation (Inverse Multiquadric)");
   Act := Calculate_Activation (0.0, 1.0, Inverse_Multiquadric);
   Check ("6.1 Dist 0.0 gives 1/Sqrt(1) = 1.0", Is_Close (Act, 1.0));
   Act := Calculate_Activation (1.0, 1.0, Inverse_Multiquadric);
   Check ("6.2 Dist 1.0 gives 1/Sqrt(2)", Is_Close (Act, 1.0 / Sqrt (2.0)));
   Act := Calculate_Activation (3.0, 1.0, Inverse_Multiquadric);
   Check ("6.3 Dist 3.0 gives 1/Sqrt(10)", Is_Close (Act, 1.0 / Sqrt (10.0)));

   --  TEST 7: Network Creation Validation
   Put_Line ("TEST 7 -- Create_Network Invariants");
   Check ("7.1 Extracted correct Num_Centers", Net_Valid.Num_Centers = 2);
   Check ("7.2 Extracted correct Num_Features", Net_Valid.Num_Features = 2);
   Check ("7.3 Network evaluates successfully at origin", Is_Close (Evaluate (Net_Valid, V1), 1.0 - Exp (-8.0)));

   --  TEST 8: Network Creation Errors
   Put_Line ("TEST 8 -- Create_Network Preconditions / Error Handling");
   declare
      Centers_A : constant Center_Matrix (1 .. 2, 1 .. 2) := [others => [others => 0.0]];
      Centers_B : constant Center_Matrix (1 .. 1, 1 .. 2) := [others => [others => 0.0]];
      Weights_A : constant Weight_Vector (1 .. 1) := [others => 0.0];
      Weights_B : constant Weight_Vector (1 .. 2) := [others => 0.0];
      Weights_C : constant Weight_Vector (1 .. 3) := [others => 0.0];
   begin
      begin
         declare
             Net_Err : constant RBF_Network := Create_Network (Centers_A, Weights_A, 0.0, 1.0, Gaussian, False);
             pragma Unreferenced (Net_Err);
         begin
             Check ("8.1 Center>Weight mismatch (expected failure)", False);
         end;
      exception
         when Dimension_Mismatch_Error => Check ("8.1 Caught Center>Weight mismatch", True);
         when others => Check ("8.1 Wrong exception", False);
      end;
      
      begin
         declare
             Net_Err : constant RBF_Network := Create_Network (Centers_B, Weights_B, 0.0, 1.0, Gaussian, False);
             pragma Unreferenced (Net_Err);
         begin
             Check ("8.2 Center<Weight mismatch (expected failure)", False);
         end;
      exception
         when Dimension_Mismatch_Error => Check ("8.2 Caught Center<Weight mismatch", True);
         when others => Check ("8.2 Wrong exception", False);
      end;

      begin
         declare
             Net_Err : constant RBF_Network := Create_Network (Centers_A, Weights_C, 0.0, 1.0, Gaussian, False);
             pragma Unreferenced (Net_Err);
         begin
             Check ("8.3 Center vs Large Weight mismatch (expected failure)", False);
         end;
      exception
         when Dimension_Mismatch_Error => Check ("8.3 Caught Center vs Large Weight mismatch", True);
         when others => Check ("8.3 Wrong exception", False);
      end;
   end;

   --  TEST 9: Evaluate Dimension Mismatch Error
   Put_Line ("TEST 9 -- Evaluate Input Mismatch Handling");
   declare
      V_Short : constant Feature_Vector (1 .. 1) := [1 => 0.0];
      V_Long  : constant Feature_Vector (1 .. 3) := [others => 0.0];
   begin
      begin
         Act := Evaluate (Net_Valid, V_Short);
         Check ("9.1 Input length 1 vs Net length 2", False);
      exception
         when Dimension_Mismatch_Error => Check ("9.1 Caught length 1 vs 2", True);
      end;

      begin
         Act := Evaluate (Net_Valid, V_Long);
         Check ("9.2 Input length 3 vs Net length 2", False);
      exception
         when Dimension_Mismatch_Error => Check ("9.2 Caught length 3 vs 2", True);
      end;

      --  A valid evaluation should not raise exception
      Act := Evaluate (Net_Valid, [0.0, 0.0]);
      Check ("9.3 Valid input evaluates cleanly", True);
   end;

   --  TEST 10: Normalization Error
   Put_Line ("TEST 10 -- Normalization Error on Extreme Distances");
   declare
      --  Gaussian drops extremely fast. Shape 1000 and Dist > 1000 causes sum to underflow to 0.0
      Net_Norm : constant RBF_Network := Create_Network
        (Centers => [[1 => 0.0, 2 => 0.0], [1 => 1.0, 2 => 1.0]],
         Weights => [1 => 1.0, 2 => 1.0],
         Bias    => 0.0,
         Shape   => 1000.0,
         Function_Type => Gaussian,
         Is_Normalized => True);
      Far1 : constant Feature_Vector (1 .. 2) := [1000.0, 1000.0];
      Far2 : constant Feature_Vector (1 .. 2) := [5000.0, -5000.0];
      Far3 : constant Feature_Vector (1 .. 2) := [-9999.0, -9999.0];
   begin
      begin
         Act := Evaluate (Net_Norm, Far1);
         Check ("10.1 Normalized underflow 1", False);
      exception
         when Normalization_Error => Check ("10.1 Caught Normalization_Error 1", True);
      end;

      begin
         Act := Evaluate (Net_Norm, Far2);
         Check ("10.2 Normalized underflow 2", False);
      exception
         when Normalization_Error => Check ("10.2 Caught Normalization_Error 2", True);
      end;

      begin
         Act := Evaluate (Net_Norm, Far3);
         Check ("10.3 Normalized underflow 3", False);
      exception
         when Normalization_Error => Check ("10.3 Caught Normalization_Error 3", True);
      end;
   end;

   --  TEST 11: Evaluate Standard Gaussian
   Put_Line ("TEST 11 -- Evaluate Standard Gaussian Network");
   declare
      Net_SG : constant RBF_Network := Create_Network
        (Centers => [[1 => 0.0, 2 => 0.0]],
         Weights => [1 => 2.0],
         Bias    => 0.5,
         Shape   => 1.0,
         Function_Type => Gaussian,
         Is_Normalized => False);
   begin
      Act := Evaluate (Net_SG, [0.0, 0.0]);
      Check ("11.1 At center -> 2.0 * Exp(0) + 0.5 = 2.5", Is_Close (Act, 2.5));
      Act := Evaluate (Net_SG, [1.0, 0.0]);
      Check ("11.2 Dist 1.0 -> 2.0 * Exp(-1) + 0.5", Is_Close (Act, 2.0 * Exp (-1.0) + 0.5));
      Act := Evaluate (Net_SG, [0.0, 2.0]);
      Check ("11.3 Dist 2.0 -> 2.0 * Exp(-4) + 0.5", Is_Close (Act, 2.0 * Exp (-4.0) + 0.5));
   end;

   --  TEST 12: Evaluate Normalized Multiquadric
   Put_Line ("TEST 12 -- Evaluate Normalized Multiquadric Network");
   declare
      Net_NM : constant RBF_Network := Create_Network
        (Centers => [[1 => 0.0, 2 => 0.0], [1 => 2.0, 2 => 0.0]],
         Weights => [1 => 1.0, 2 => -1.0],
         Bias    => 0.5,
         Shape   => 1.0,
         Function_Type => Multiquadric,
         Is_Normalized => True);
   begin
      --  Input at (1.0, 0.0) is exactly halfway between centers.
      --  Dist to both is 1.0. Shape = 1.0.
      --  Act1 = Sqrt(1+1) = Sqrt(2). Act2 = Sqrt(2).
      --  Total_Sum = 1.0*Sqrt(2) - 1.0*Sqrt(2) = 0.0.
      --  Output = 0.0 / (2*Sqrt(2)) + 0.5 = 0.5
      Act := Evaluate (Net_NM, [1.0, 0.0]);
      Check ("12.1 Equidistant inputs cancel out to bias", Is_Close (Act, 0.5));

      --  Input at (0.0, 0.0)
      --  Dist to C1 = 0 -> Act1 = 1.0
      --  Dist to C2 = 2 -> Act2 = Sqrt(5)
      --  Total = (1.0 - Sqrt(5)) / (1.0 + Sqrt(5)) + 0.5
      declare
         Expected : constant Real := ((1.0 - Sqrt (5.0)) / (1.0 + Sqrt (5.0))) + 0.5;
      begin
         Act := Evaluate (Net_NM, [0.0, 0.0]);
         Check ("12.2 Output heavily weighted by nearest center", Is_Close (Act, Expected));
      end;
      
      --  Input at (2.0, 0.0)
      --  Dist to C1 = 2 -> Act1 = Sqrt(5)
      --  Dist to C2 = 0 -> Act2 = 1.0
      --  Total = (Sqrt(5) - 1.0) / (1.0 + Sqrt(5)) + 0.5
      declare
         Expected : constant Real := ((Sqrt (5.0) - 1.0) / (1.0 + Sqrt (5.0))) + 0.5;
      begin
         Act := Evaluate (Net_NM, [2.0, 0.0]);
         Check ("12.3 Opposite weighting on inverse side", Is_Close (Act, Expected));
      end;
   end;

   --  TEST 13: Edge Case (Single Feature, Single Center)
   Put_Line ("TEST 13 -- Edge Case (1 Center, 1 Feature)");
   declare
      Net_Edge_Std : constant RBF_Network := Create_Network
        (Centers => [[1 => 10.0]],
         Weights => [1 => -3.0],
         Bias    => 1.0,
         Shape   => 2.0,
         Function_Type => Inverse_Quadratic,
         Is_Normalized => False);
         
      Net_Edge_Norm : constant RBF_Network := Create_Network
        (Centers => [[1 => 10.0]],
         Weights => [1 => -3.0],
         Bias    => 1.0,
         Shape   => 2.0,
         Function_Type => Inverse_Quadratic,
         Is_Normalized => True);
         
      Inp : constant Feature_Vector (1 .. 1) := [1 => 11.0];
   begin
      --  Dist = 1.0. Shape = 2.0. Epsilon = 2.0.
      --  Act = 1 / (1 + 4) = 0.2.
      --  Std = -3.0 * 0.2 + 1.0 = 0.4
      Act := Evaluate (Net_Edge_Std, Inp);
      Check ("13.1 Evaluates 1x1 standard properly", Is_Close (Act, 0.4));
      
      --  Norm: Weight_Sum = 0.2. Total_Sum = -0.6.
      --  Norm = -0.6 / 0.2 + 1.0 = -3.0 + 1.0 = -2.0. 
      --  Note: In 1-center normalized, weight / 1 + bias = weight + bias = -3.0 + 1.0 = -2.0.
      Act := Evaluate (Net_Edge_Norm, Inp);
      Check ("13.2 Evaluates 1x1 normalized (always weight + bias)", Is_Close (Act, -2.0));
      
      --  Check at center (dist = 0.0) -> Standard should be -3.0 * 1.0 + 1.0 = -2.0
      Act := Evaluate (Net_Edge_Std, [1 => 10.0]);
      Check ("13.3 Standard exactly on center", Is_Close (Act, -2.0));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
