-- tests.adb
-- Validation & Verification suite for Vector Quantization

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Vector_Quantization; use Vector_Quantization;

procedure Tests is
begin
   Put_Line("--- Running V&V Test Suite for Vector Quantization ---");

   -- TEST 1: Distance calculation functionality
   Put_Line("TEST 1 - Distance Squared");
   Put_Line("  1.1 Assert distance of identical vectors is 0.0");
   declare
      V1 : Vector := (1.0, 2.0, 3.0);
   begin
      Assert (abs(Distance_Squared(V1, V1)) < 0.0001, "Distance should be 0");
      Put_Line("     PASS");
   end;

   Put_Line("  1.2 Assert distance of known vectors (Pythagorean)");
   declare
      V1 : Vector := (0.0, 0.0);
      V2 : Vector := (3.0, 4.0);
   begin
      Assert (abs(Distance_Squared(V1, V2) - 25.0) < 0.0001, "Expected 25.0");
      Put_Line("     PASS");
   end;

   Put_Line("  1.3 Assert dimension mismatch throws Exception");
   begin
      declare
         V1 : Vector := (1.0, 2.0);
         V2 : Vector := (1.0, 2.0, 3.0);
         D : Float := Distance_Squared(V1, V2);
      begin
         Assert(False, "Failed to raise Dimension_Mismatch");
      end;
   exception
      when Dimension_Mismatch => Put_Line("     PASS");
   end;

   -- TEST 2: Static Encoding
   Put_Line("TEST 2 - Vector Encoding");
   Put_Line("  2.1 Assert exact match returns correct index");
   declare
      B : Matrix(1..2, 1..2) := ((1.0, 1.0), (5.0, 5.0));
      V : Vector := (5.0, 5.0);
   begin
      Assert(Encode(V, B) = 2, "Expected index 2");
      Put_Line("     PASS");
   end;

   Put_Line("  2.2 Assert nearest neighbor approximation works correctly");
   declare
      B : Matrix(1..2, 1..2) := ((1.0, 1.0), (10.0, 10.0));
      V : Vector := (3.0, 3.0); -- Closer to (1,1)
   begin
      Assert(Encode(V, B) = 1, "Expected index 1");
      Put_Line("     PASS");
   end;
   
   Put_Line("  2.3 Assert Encoding handles Dimension_Mismatch");
   declare
      B : Matrix(1..1, 1..3) := (1 => (1.0, 1.0, 1.0));
      V : Vector := (1.0, 1.0);
   begin
      declare
         Idx : Positive := Encode(V, B);
      begin
         Assert(False, "Failed to raise Dimension_Mismatch");
      end;
   exception
      when Dimension_Mismatch => Put_Line("     PASS");
   end;

   -- TEST 3: Static Decoding
   Put_Line("TEST 3 - Vector Decoding");
   Put_Line("  3.1 Assert decoding valid index returns correct vector");
   declare
      B : Matrix(1..2, 1..2) := ((7.0, 8.0), (9.0, 10.0));
      V : Vector := Decode(1, B);
   begin
      Assert(V(1) = 7.0 and V(2) = 8.0, "Decode mismatch");
      Put_Line("     PASS");
   end;

   Put_Line("  3.2 Assert decoding invalid index throws Constraint_Error");
   begin
      declare
         B : Matrix(1..1, 1..2) := (1 => (1.0, 2.0));
         V : Vector := Decode(2, B);
      begin
         Assert(False, "Failed to raise Exception");
      end;
   exception
      when Constraint_Error => Put_Line("     PASS");
   end;

   -- TEST 4: Performance / MSE Evaluation
   Put_Line("TEST 4 - Mean Squared Error (MSE)");
   Put_Line("  4.1 Assert MSE is 0.0 when dataset perfectly matches codebook");
   declare
      D : Matrix(1..2, 1..2) := ((1.0, 1.0), (2.0, 2.0));
   begin
      Assert(abs(Calculate_MSE(D, D)) < 0.0001, "Expected MSE 0.0");
      Put_Line("     PASS");
   end;

   Put_Line("  4.2 Assert expected MSE for noisy data");
   declare
      D : Matrix(1..1, 1..1) := (1 => (1 => 2.0));
      B : Matrix(1..1, 1..1) := (1 => (1 => 0.0));
   begin
      Assert(abs(Calculate_MSE(D, B) - 4.0) < 0.0001, "Expected MSE 4.0");
      Put_Line("     PASS");
   end;

   -- TEST 5: Edge Cases in Training Data
   Put_Line("TEST 5 - Training Robustness & Edge Cases");
   Put_Line("  5.1 Assert training empty dataset raises Empty_Dataset");
   declare
      -- Hack to make an empty matrix in Ada
      D : Matrix(1..0, 1..2);
   begin
      declare
         B : Matrix := Train_LBG(D, 1);
      begin
         Assert(False, "Expected Empty_Dataset exception");
      end;
   exception
      when Empty_Dataset => Put_Line("     PASS");
   end;
   
   Put_Line("  5.2 Assert Codebook_Size > Dataset raises Invalid_Codebook");
   declare
      D : Matrix(1..1, 1..2) := (1 => (1.0, 1.0));
   begin
      declare
         B : Matrix := Train_LBG(D, 2);
      begin
         Assert(False, "Expected Invalid_Codebook");
      end;
   exception
      when Invalid_Codebook => Put_Line("     PASS");
   end;

   -- TEST 6: Training Logic (LBG)
   Put_Line("TEST 6 - LBG Clustering Training");
   Put_Line("  6.1 Assert LBG minimizes MSE within max iterations");
   declare
      D : Matrix(1..4, 1..2) := ((0.0, 0.0), (0.1, 0.1), (10.0, 10.0), (10.1, 10.1));
      B : Matrix := Train_LBG(D, Codebook_Size => 2, Max_Iter => 10);
      MSE : Float := Calculate_MSE(D, B);
   begin
      -- It should cluster the 0s and 10s nicely, resulting in a very low MSE
      Assert(MSE < 1.0, "MSE failed to converge well");
      Put_Line("     PASS");
   end;

   Put_Line("  6.2 Assert Empty Cluster Handling functions without crashing");
   declare
      -- Four points essentially in the same spot, forced into 2 clusters
      -- Forces an empty cluster scenario which our logic catches and handles
      D : Matrix(1..4, 1..2) := ((1.0, 1.0), (1.0, 1.0), (1.0, 1.0), (1.0, 1.0));
      B : Matrix := Train_LBG(D, Codebook_Size => 2);
   begin
      Assert(B'Length(1) = 2, "Failed to build codebook successfully");
      Put_Line("     PASS");
   end;

   Put_Line("--- All Tests Completed Successfully ---");
end Tests;
