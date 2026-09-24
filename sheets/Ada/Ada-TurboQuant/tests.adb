-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Turbo_Quant; use Turbo_Quant;

procedure Tests is
   -- Mock Environment Data
   V1 : Vector (1 .. 3) := (1.0, 2.0, 3.0);
   V2 : Vector (1 .. 3) := (4.0, 5.0, 6.0);
   V_Zero : Vector (1 .. 3) := (0.0, 0.0, 0.0);
   
   Ident_Matrix : Matrix (1 .. 3, 1 .. 3) :=
     ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0));
      
   Bad_Matrix : Matrix (1 .. 2, 1 .. 3) :=
     ((1.0, 1.0, 1.0), (1.0, 1.0, 1.0));
      
   Centroids : Vector (1 .. 2) := (0.0, 5.0);
begin
   Put_Line ("Starting TurboQuant Test Suite...");
   
   -- FUNCTIONAL TESTS
   Put_Line ("TEST 1 - Norm Calculation (Normal Vector)");
   Put_Line ("  1.1 Assert Norm(1,2,2) = 3.0");
   declare
      V_Test : Vector (1 .. 3) := (1.0, 2.0, 2.0);
   begin
      Assert (abs(Norm (V_Test) - 3.0) < 0.001, "Norm failed");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 2 - Norm Calculation (Zero Vector)");
   Put_Line ("  2.1 Assert Norm(0,0,0) = 0.0");
   Assert (Norm (V_Zero) = 0.0, "Zero norm failed");
   Put_Line ("      PASS");
   
   Put_Line ("TEST 3 - Inner Product");
   Put_Line ("  3.1 Assert IP((1,2,3), (4,5,6)) = 32.0");
   Assert (abs(Inner_Product (V1, V2) - 32.0) < 0.001, "Inner product failed");
   Put_Line ("      PASS");

   Put_Line ("TEST 4 - Matrix Vector Multiplication");
   Put_Line ("  4.1 Assert Identity * V = V");
   declare
      Res : Vector := Multiply (Ident_Matrix, V1);
   begin
      Assert (Res (1) = 1.0 and Res (2) = 2.0 and Res (3) = 3.0, "Mat-Vec mult failed");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 5 - Transpose Matrix Vector Multiplication");
   Put_Line ("  5.1 Assert Transpose(Identity) * V = V");
   declare
      Res : Vector := Transpose_Multiply (Ident_Matrix, V1);
   begin
      Assert (Res (1) = 1.0 and Res (2) = 2.0 and Res (3) = 3.0, "Transpose mult failed");
      Put_Line ("      PASS");
   end;

   -- ROBUSTNESS & ERROR HANDLING
   Put_Line ("TEST 6 - Validation: Multiply Dimension Mismatch");
   Put_Line ("  6.1 Assert Matrix (2x3) * Vector (2) raises Exception");
   begin
      declare
         Bad_V : Vector (1 .. 2) := (1.0, 2.0);
         Res : Vector := Multiply (Bad_Matrix, Bad_V);
      begin
         Assert (False, "Assumption proved false: Expected Dimension_Mismatch");
      end;
   exception
      when Dimension_Mismatch =>
         Put_Line ("      PASS");
   end;

   Put_Line ("TEST 7 - Validation: Inner Product Dimension Mismatch");
   Put_Line ("  7.1 Assert IP(V(3), V(2)) raises Exception");
   begin
      declare
         Bad_V : Vector (1 .. 2) := (1.0, 2.0);
         Res : Real := Inner_Product (V1, Bad_V);
      begin
         Assert (False, "Assumption proved false: Expected Dimension_Mismatch");
      end;
   exception
      when Dimension_Mismatch =>
         Put_Line ("      PASS");
   end;

   -- LOGIC & CORRECTNESS
   Put_Line ("TEST 8 - Logic: Quantize_MSE correct centroid selection");
   Put_Line ("  8.1 Assert 1.0 maps to 0.0, 4.0 maps to 5.0");
   declare
      Test_V : Vector (1 .. 2) := (1.0, 4.0);
      Test_Mat : Matrix (1 .. 2, 1 .. 2) := ((1.0, 0.0), (0.0, 1.0));
      Res : TurboQuant_MSE_Data := Quantize_MSE (Test_V, Test_Mat, Centroids);
   begin
      Assert (Res.Quantized_Coordinates(1) = 1, "Index 1 should map to Centroid 1 (0.0)");
      Assert (Res.Quantized_Coordinates(2) = 2, "Index 2 should map to Centroid 2 (5.0)");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 9 - Logic: Dequantize_MSE reconstruction");
   Put_Line ("  9.1 Assert indices reconstruct to centroid values");
   declare
      Test_V : Vector (1 .. 2) := (1.0, 4.0);
      Test_Mat : Matrix (1 .. 2, 1 .. 2) := ((1.0, 0.0), (0.0, 1.0));
      Res : TurboQuant_MSE_Data := Quantize_MSE (Test_V, Test_Mat, Centroids);
      Recon : Vector := Dequantize_MSE (Res, Test_Mat, Centroids);
   begin
      Assert (Recon(1) = 0.0 and Recon(2) = 5.0, "Dequantization failed");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 10 - Logic: Quantize_Prod computes residual norm");
   Put_Line ("  10.1 Assert residual norm is non-negative");
   declare
      Res : TurboQuant_Prod_Data := Quantize_Prod (V1, Ident_Matrix, Centroids, Ident_Matrix);
   begin
      Assert (Res.Residual_Norm >= 0.0, "Residual norm must be >= 0");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 11 - Logic: Dequantize_Prod matches input shape");
   Put_Line ("  11.1 Assert output vector has same dimension as input");
   declare
      Res : TurboQuant_Prod_Data := Quantize_Prod (V1, Ident_Matrix, Centroids, Ident_Matrix);
      Recon : Vector := Dequantize_Prod (Res, Ident_Matrix, Centroids, Ident_Matrix);
   begin
      Assert (Recon'Length = V1'Length, "Dequantize_Prod length mismatch");
      Put_Line ("      PASS");
   end;

   -- EDGE CASES
   Put_Line ("TEST 12 - Edge Case: Exact Match (Zero Residual)");
   Put_Line ("  12.1 Assert if input is exactly a centroid, residual norm is 0");
   declare
      Exact_V : Vector (1 .. 1) := (1 => 5.0);
      Exact_Mat : Matrix (1 .. 1, 1 .. 1) := (1 => (1 => 1.0));
      Res : TurboQuant_Prod_Data := Quantize_Prod (Exact_V, Exact_Mat, Centroids, Exact_Mat);
   begin
      Assert (Res.Residual_Norm = 0.0, "Exact match should yield 0 residual");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 13 - Edge Case: 1x1 Vector and Matrix full pipeline");
   Put_Line ("  13.1 Assert 1D quantization reconstructs deterministically");
   declare
      Small_V : Vector (1 .. 1) := (1 => -10.0);
      Small_Mat : Matrix (1 .. 1, 1 .. 1) := (1 => (1 => 1.0));
      Res : TurboQuant_Prod_Data := Quantize_Prod (Small_V, Small_Mat, Centroids, Small_Mat);
      Recon : Vector := Dequantize_Prod (Res, Small_Mat, Centroids, Small_Mat);
   begin
      Assert (abs(Recon(1) - (-10.0)) < 0.001, "1D pipeline reconstruction failed");
      Put_Line ("      PASS");
   end;
   
   Put_Line ("---------------------------------");
   Put_Line ("ALL TESTS PASSED SUCCESSFULLY");
end Tests;
