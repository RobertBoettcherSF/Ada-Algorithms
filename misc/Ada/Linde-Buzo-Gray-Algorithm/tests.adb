with Ada.Text_IO; use Ada.Text_IO;
with Lbg_Algorithm;

procedure Tests is
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

   -- Instantiations for different dimensionality tests
   package Lbg_2D is new Lbg_Algorithm (Dimension => 2);
   use Lbg_2D;

   package Lbg_3D is new Lbg_Algorithm (Dimension => 3);

begin
   -----------------------------------------------------------------------------
   -- TEST 1 -- Squared_Distance Correctness
   -----------------------------------------------------------------------------
   Put_Line ("TEST 1 -- Squared_Distance Correctness");
   declare
      V1 : constant Vector := [0.0, 0.0];
      V2 : constant Vector := [3.0, 4.0];
      V3 : constant Vector := [1.0, 1.0];
   begin
      Check ("1.1 Distance to Origin", Squared_Distance (V1, V2) = 25.0);
      Check ("1.2 Distance to Self is zero", Squared_Distance (V1, V1) = 0.0);
      Check ("1.3 Symmetry", Squared_Distance (V2, V3) = Squared_Distance (V3, V2));
   end;

   -----------------------------------------------------------------------------
   -- TEST 2 -- Average_Distortion Perfect Match
   -----------------------------------------------------------------------------
   Put_Line ("TEST 2 -- Average_Distortion Perfect Match");
   declare
      Data : constant Vector_Array := [[1.0, 1.0], [2.0, 2.0]];
   begin
      Check ("2.1 Exact match codebook", Average_Distortion (Data, Data) = 0.0);
      Check ("2.2 Single exact point", Average_Distortion (Data(1..1), Data(1..1)) = 0.0);
      Check ("2.3 Duplicated training data", Average_Distortion (Data & Data, Data) = 0.0);
   end;

   -----------------------------------------------------------------------------
   -- TEST 3 -- Average_Distortion with Offsets
   -----------------------------------------------------------------------------
   Put_Line ("TEST 3 -- Average_Distortion with Offsets");
   declare
      Data : constant Vector_Array := [[0.0, 0.0], [0.0, 0.0]];
      CB1  : constant Vector_Array := [1 => [1.0, 1.0]];
      CB2  : constant Vector_Array := [1 => [2.0, 0.0]];
      CB3  : constant Vector_Array := [[0.0, 0.0], [3.0, 4.0]];
   begin
      Check ("3.1 Offset 1,1 distortion=2.0", Average_Distortion (Data, CB1) = 2.0);
      Check ("3.2 Offset 2,0 distortion=4.0", Average_Distortion (Data, CB2) = 4.0);
      Check ("3.3 Nearest neighbor picks exact 0.0 match", Average_Distortion (Data, CB3) = 0.0);
   end;

   -----------------------------------------------------------------------------
   -- TEST 4 -- Lloyd Algorithm - Trivial Non-Update
   -----------------------------------------------------------------------------
   Put_Line ("TEST 4 -- Lloyd Algorithm - Trivial Non-Update");
   declare
      Data : constant Vector_Array := [[1.0, 1.0], [2.0, 2.0]];
      Result : constant Vector_Array := Optimize_Codebook_Lloyd (Data, Data);
   begin
      Check ("4.1 Length preserved", Result'Length = 2);
      Check ("4.2 First centroid unmodified", Result(1) = [1.0, 1.0]);
      Check ("4.3 Second centroid unmodified", Result(2) = [2.0, 2.0]);
   end;

   -----------------------------------------------------------------------------
   -- TEST 5 -- Lloyd Algorithm - Simple Convergence
   -----------------------------------------------------------------------------
   Put_Line ("TEST 5 -- Lloyd Algorithm - Simple Convergence");
   declare
      Data : constant Vector_Array := [[1.0, 1.0], [1.2, 1.0], [9.0, 9.0], [9.2, 9.0]];
      Init : constant Vector_Array := [[0.0, 0.0], [10.0, 10.0]];
      Result : constant Vector_Array := Optimize_Codebook_Lloyd (Data, Init);
   begin
      Check ("5.1 Result Size", Result'Length = 2);
      Check ("5.2 Cluster 1 converged (mean of 1.0 and 1.2)", Result(1)(1) = 1.1 and Result(1)(2) = 1.0);
      Check ("5.3 Cluster 2 converged (mean of 9.0 and 9.2)", Result(2)(1) = 9.1 and Result(2)(2) = 9.0);
   end;

   -----------------------------------------------------------------------------
   -- TEST 6 -- Lloyd Algorithm - Empty Cell Handling
   -----------------------------------------------------------------------------
   Put_Line ("TEST 6 -- Lloyd Algorithm - Empty Cell Handling");
   declare
      Data : constant Vector_Array := [[1.0, 1.0], [1.0, 1.0]];
      Init : constant Vector_Array := [[1.0, 1.0], [100.0, 100.0]];
      Result : constant Vector_Array := Optimize_Codebook_Lloyd (Data, Init);
   begin
      Check ("6.1 Survived empty cell allocation", Result'Length = 2);
      Check ("6.2 Valid centroid updated accurately", Result(1) = [1.0, 1.0]);
      Check ("6.3 Outlier empty centroid preserved", Result(2) = [100.0, 100.0]);
   end;

   -----------------------------------------------------------------------------
   -- TEST 7 -- LBG Codebook Generation - Size 1
   -----------------------------------------------------------------------------
   Put_Line ("TEST 7 -- LBG Codebook Generation - Size 1");
   declare
      Data : constant Vector_Array := [[0.0, 0.0], [2.0, 2.0], [4.0, 4.0]];
      Result : constant Vector_Array := Generate_Codebook_Lbg (Data, Target_Size => 1);
   begin
      Check ("7.1 Returned size 1", Result'Length = 1);
      Check ("7.2 Centroid X is mean", Result(Result'First)(1) = 2.0);
      Check ("7.3 Centroid Y is mean", Result(Result'First)(2) = 2.0);
   end;

   -----------------------------------------------------------------------------
   -- TEST 8 -- LBG Codebook Generation - Power of 2 (Size 2)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 8 -- LBG Codebook Generation - Power of 2");
   declare
      Data : constant Vector_Array := [[-10.0, 0.0], [-8.0, 0.0], [10.0, 0.0], [8.0, 0.0]];
      Result : constant Vector_Array := Generate_Codebook_Lbg (Data, Target_Size => 2);
      Has_Pos : constant Boolean := (Result(1)(1) = 9.0) or (Result(2)(1) = 9.0);
      Has_Neg : constant Boolean := (Result(1)(1) = -9.0) or (Result(2)(1) = -9.0);
   begin
      Check ("8.1 Returned requested size 2", Result'Length = 2);
      Check ("8.2 Found positive dataset cluster", Has_Pos);
      Check ("8.3 Found negative dataset cluster", Has_Neg);
   end;

   -----------------------------------------------------------------------------
   -- TEST 9 -- LBG Codebook Generation - Non-Power of 2 (Size 3)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 9 -- LBG Codebook Generation - Non-Power of 2");
   declare
      Data : constant Vector_Array := [[0.0, 0.0], [10.0, 0.0], [20.0, 0.0]];
      Result : constant Vector_Array := Generate_Codebook_Lbg (Data, Target_Size => 3);
   begin
      Check ("9.1 Returned exact requested size 3", Result'Length = 3);
      Check ("9.2 Total distortion aligns perfectly", Average_Distortion (Data, Result) = 0.0);
      Check ("9.3 All centroids are unique", Result(1) /= Result(2) and Result(2) /= Result(3));
   end;

   -----------------------------------------------------------------------------
   -- TEST 10 -- LBG Boundary Checks & Exceptions
   -----------------------------------------------------------------------------
   Put_Line ("TEST 10 -- Boundary Checks & Preconditions");
   declare
      Data : constant Vector_Array := [1 => [1.0, 1.0]];
      Caught : Boolean := False;
   begin
      begin
         declare
            Result : constant Vector_Array := Generate_Codebook_Lbg (Data, Target_Size => 2);
         begin
            Check ("Unreachable block 1", Result'Length > 0);
         end;
      exception
         when others => Caught := True;
      end;
      Check ("10.1 Blocked Target_Size > Data length", Caught);
      
      Caught := False;
      begin
         declare
            Init : constant Vector_Array := [[1.0, 1.0], [2.0, 2.0]];
            Result : constant Vector_Array := Optimize_Codebook_Lloyd (Data, Initial_Codebook => Init);
         begin
            Check ("Unreachable block 2", Result'Length > 0);
         end;
      exception
         when others => Caught := True;
      end;
      Check ("10.2 Blocked Lloyd Init > Data length", Caught);
   end;

   -----------------------------------------------------------------------------
   -- TEST 11 -- High-Dimensional Generics (3D)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 11 -- High-Dimensional Generics (3D)");
   declare
      use Lbg_3D;
      Data : constant Lbg_3D.Vector_Array := [[0.0, 0.0, 0.0], [1.0, 1.0, 1.0]];
      Result : constant Lbg_3D.Vector_Array := Generate_Codebook_Lbg (Data, Target_Size => 2);
   begin
      Check ("11.1 Returned size 2 codebook", Result'Length = 2);
      Check ("11.2 3D Distortion computes exactly to 0.0", Lbg_3D.Average_Distortion (Data, Result) = 0.0);
      Check ("11.3 Found distinct 3D vectors", Lbg_3D.Squared_Distance(Result(1), Result(2)) > 0.0);
   end;

   -----------------------------------------------------------------------------
   -- TEST 12 -- Zero Epsilon and Loop Behavior
   -----------------------------------------------------------------------------
   Put_Line ("TEST 12 -- Zero Epsilon and Loop Behavior");
   declare
      Data : constant Vector_Array := [[1.0, 1.0], [3.0, 3.0]];
      Init : constant Vector_Array := [1 => [0.0, 0.0]];
      -- Will converge immediately once it reaches the mean. Zero epsilon ensures
      -- it does not infinitely loop on fractional improvements.
      Result : constant Vector_Array := Optimize_Codebook_Lloyd (Data, Init, Epsilon => 0.0, Max_Iterations => 5);
   begin
      Check ("12.1 Exited without infinite looping", True);
      Check ("12.2 Length matches init", Result'Length = 1);
      Check ("12.3 Optimized precisely to mathematical mean", Result(1)(1) = 2.0);
   end;

   -----------------------------------------------------------------------------
   -- TEST 13 -- Split Factor Sensitivities
   -----------------------------------------------------------------------------
   Put_Line ("TEST 13 -- Split Factor Sensitivities");
   declare
      Data : constant Vector_Array := [[0.0, 0.0], [10.0, 0.0]];
      Result_Small : constant Vector_Array := Generate_Codebook_Lbg (Data, Target_Size => 2, Split_Factor => 0.01);
      Result_Large : constant Vector_Array := Generate_Codebook_Lbg (Data, Target_Size => 2, Split_Factor => 5.0);
   begin
      Check ("13.1 Standard minor splitting converges", Average_Distortion(Data, Result_Small) = 0.0);
      Check ("13.2 Severe large splitting recovers and converges", Average_Distortion(Data, Result_Large) = 0.0);
      Check ("13.3 Output codebook sizes maintained", Result_Small'Length = 2 and Result_Large'Length = 2);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
