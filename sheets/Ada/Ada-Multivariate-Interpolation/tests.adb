--  Standalone test suite for Multivariate_Interpolation educational survey.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Multivariate_Interpolation;

procedure Tests is
   package MI renames Multivariate_Interpolation;
   use MI;

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Float; Tol : Float := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Ada.Text_IO.Put_Line
     ("Multivariate Interpolation educational survey test suite");
   Ada.Text_IO.Put_Line
     ("========================================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Lerp / Cubic_1D / Round_Index");
   ---------------------------------------------------------------------
   declare
      C : Float;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny");
      Check (not Near (1.0, 2.0), "Near rejects");
      Check (Approx (Lerp (0.0, 10.0, 0.0), 0.0), "Lerp t=0");
      Check (Approx (Lerp (0.0, 10.0, 1.0), 10.0), "Lerp t=1");
      Check (Approx (Lerp (0.0, 10.0, 0.5), 5.0), "Lerp t=0.5");
      --  Catmull-Rom of a line through P1,P2 with consistent neighbors
      C := Cubic_1D (0.0, 1.0, 2.0, 3.0, 0.0);
      Check (Approx (C, 1.0), "Cubic_1D at t=0 is P1");
      C := Cubic_1D (0.0, 1.0, 2.0, 3.0, 1.0);
      Check (Approx (C, 2.0), "Cubic_1D at t=1 is P2");
      C := Cubic_1D (0.0, 1.0, 2.0, 3.0, 0.5);
      Check (Approx (C, 1.5), "Cubic_1D midpoint of affine");
      Check (Round_Index (0.0, 5) = 0, "Round 0");
      Check (Round_Index (5.0, 5) = 5, "Round last");
      Check (Round_Index (2.4, 5) = 2, "Round floorish");
      Check (Round_Index (2.6, 5) = 3, "Round ceilish");
      Check (Round_Index (2.5, 5) = 2, "Round tie → lower");
      Check (Round_Index (0.5, 0) = 0, "Round Last=0");
   end;

   ---------------------------------------------------------------------
   Section ("2. Builders / validation / domain");
   ---------------------------------------------------------------------
   declare
      C  : constant Grid_2D := Make_Constant_2D (4, 5, 3.0);
      A  : constant Grid_2D := Make_Affine_2D (5, 5, 1.0, 2.0, 0.0);
      Ch : constant Grid_2D := Make_Checkerboard_2D (4, 4, 0.0, 1.0);
      E  : constant Grid_2D := Make_Example (Constant_Field);
      U  : Grid_2D;
      G3 : constant Grid_3D := Make_Affine_3D (3, 3, 3, 1.0, 2.0, 3.0, 0.0);
   begin
      Check (Is_Valid_Grid (C), "Constant valid");
      Check (C.Nx = 4 and then C.Ny = 5, "Constant sizes");
      Check (Approx (Get (C, 0, 0), 3.0), "Constant corner");
      Check (Approx (Get (C, 3, 4), 3.0), "Constant far");
      Check (Approx (Get (A, 2, 3), 2.0 + 6.0), "Affine 2+6");
      Check (Approx (Get (Ch, 0, 0), 1.0), "Checker Hi even");
      Check (Approx (Get (Ch, 0, 1), 0.0), "Checker Lo odd");
      Check (Is_Valid_Grid (E) and then Approx (Get (E, 1, 1), 7.0),
             "Example constant");
      Check (In_Domain (A, 0.0, 0.0), "In domain origin");
      Check (In_Domain (A, 4.0, 4.0), "In domain corner");
      Check (not In_Domain (A, -0.1, 0.0), "OOD negative");
      Check (not In_Domain (A, 4.1, 0.0), "OOD past");
      Check (Large_Enough_Bilinear (A), "Affine large enough bilinear");
      Check (Large_Enough_Bicubic (A), "Affine large enough bicubic");
      Check (Large_Enough_Bicubic (C), "4x5 is bicubic-capable");
      declare
         Tiny2 : constant Grid_2D := Make_Constant_2D (2, 2, 0.0);
      begin
         Check (Large_Enough_Bilinear (Tiny2), "2x2 bilinear OK");
         Check (not Large_Enough_Bicubic (Tiny2), "2x2 not bicubic");
      end;
      U.Valid := False;
      Check (not Is_Valid_Grid (U), "Unset invalid");
      Check (Is_Valid_Grid (G3), "3D affine valid");
      Check (Approx (Get (G3, 1, 1, 1), 1.0 + 2.0 + 3.0), "3D affine mid");
      Check (Large_Enough_Trilinear (G3), "3D large enough trilinear");
      Check (In_Domain (G3, 1.5, 1.0, 0.5), "3D in domain");
      Check (not In_Domain (G3, 3.0, 0.0, 0.0), "3D OOD");
   end;

   ---------------------------------------------------------------------
   Section ("3. Taxonomy / Recommend_Method");
   ---------------------------------------------------------------------
   declare
      Info : Method_Info;
   begin
      Check (Method_Count = 12, "Method_Count = 12");
      Check (Supports_Runnable (Nearest_Neighbor), "NN runnable");
      Check (Supports_Runnable (Bilinear), "Bilinear runnable");
      Check (Supports_Runnable (Bicubic), "Bicubic runnable");
      Check (Supports_Runnable (Trilinear), "Trilinear runnable");
      Check (Supports_Runnable (Inverse_Distance), "IDW runnable");
      Check (not Supports_Runnable (Tricubic), "Tricubic catalogue");
      Check (not Supports_Runnable (Lanczos), "Lanczos catalogue");
      Check (not Supports_Runnable (Kriging), "Kriging catalogue");
      Check (not Supports_Runnable (Natural_Neighbor), "NatNeigh catalogue");
      Check (not Supports_Runnable (Radial_Basis), "RBF catalogue");
      Check (not Supports_Runnable (Spline_Tensor), "Spline catalogue");
      Check (not Supports_Runnable (Barnes), "Barnes catalogue");
      Check (Method_Name (Bilinear)'Length > 0, "Name non-empty");
      Check (Describe (Bicubic)'Length > 0, "Describe non-empty");
      Info := Classify_Method (Bilinear);
      Check (Info.Runnable_Sketch and then Info.For_Regular
             and then not Info.For_Scattered
             and then Info.Dim_Min = 2 and then Info.Dim_Max = 2,
             "Classify Bilinear");
      Info := Classify_Method (Inverse_Distance);
      Check (Info.For_Scattered and then Info.Runnable_Sketch,
             "Classify IDW");
      Check (Recommend_Method (Regular_Grid, 2, Piecewise_Constant) =
             Nearest_Neighbor,
             "Rec 2D PC → NN");
      Check (Recommend_Method (Regular_Grid, 2, C0_Continuous) = Bilinear,
             "Rec 2D C0 → Bilinear");
      Check (Recommend_Method (Regular_Grid, 2, C1_Smooth) = Bicubic,
             "Rec 2D C1 → Bicubic");
      Check (Recommend_Method (Regular_Grid, 3, C0_Continuous) = Trilinear,
             "Rec 3D C0 → Trilinear");
      Check (Recommend_Method (Regular_Grid, 3, C1_Smooth) = Tricubic,
             "Rec 3D C1 → Tricubic");
      Check (Recommend_Method (Scattered, 2, Piecewise_Constant) =
             Nearest_Neighbor,
             "Rec scat PC → NN");
      Check (Recommend_Method (Scattered, 2, C0_Continuous) =
             Inverse_Distance,
             "Rec scat C0 → IDW");
      Check (Recommend_Method (Scattered, 3, C1_Smooth) = Inverse_Distance,
             "Rec scat C1 → IDW");
   end;

   ---------------------------------------------------------------------
   Section ("4. Evaluate_Nearest_2D");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Affine_2D (5, 5, 1.0, 2.0, 0.0);
      R : Eval_Result;
      U : Grid_2D;
   begin
      R := Evaluate_Nearest_2D (G, 0.0, 0.0);
      Check (R.Success and then Approx (R.Value, 0.0), "NN origin");
      R := Evaluate_Nearest_2D (G, 2.0, 3.0);
      Check (R.Success and then Approx (R.Value, 2.0 + 6.0), "NN node");
      R := Evaluate_Nearest_2D (G, 2.4, 1.4);
      Check (R.Success and then Approx (R.Value, 2.0 + 2.0), "NN round down");
      R := Evaluate_Nearest_2D (G, 2.6, 1.6);
      Check (R.Success and then Approx (R.Value, 3.0 + 4.0), "NN round up");
      R := Evaluate_Nearest_2D (G, 2.5, 1.5);
      Check (R.Success and then Approx (R.Value, 2.0 + 2.0),
             "NN tie → lower");
      R := Evaluate_Nearest_2D (G, -0.1, 0.0);
      Check (not R.Success and then R.Stat = Out_Of_Domain, "NN OOD");
      U.Valid := False;
      R := Evaluate_Nearest_2D (U, 0.0, 0.0);
      Check (not R.Success and then R.Stat = Ill_Started, "NN ill");
      R := Evaluate (Nearest_Neighbor, G, 1.0, 1.0);
      Check (R.Success and then Approx (R.Value, 1.0 + 2.0), "Dispatch NN");
   end;

   ---------------------------------------------------------------------
   Section ("5. Evaluate_Bilinear");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Affine_2D (6, 6, 1.0, 2.0, 1.0);
      C : constant Grid_2D := Make_Constant_2D (4, 4, 7.0);
      S : constant Grid_2D := Make_Empty_2D (1, 4);
      R : Eval_Result;
   begin
      R := Evaluate_Bilinear (G, 0.0, 0.0);
      Check (R.Success and then Approx (R.Value, 1.0), "Bi origin");
      R := Evaluate_Bilinear (G, 2.0, 3.0);
      Check (R.Success and then Approx (R.Value, 2.0 + 6.0 + 1.0),
             "Bi node");
      R := Evaluate_Bilinear (G, 1.5, 2.5);
      Check (R.Success
             and then Approx (R.Value, 1.0 * 1.5 + 2.0 * 2.5 + 1.0),
             "Bi affine mid-cell");
      R := Evaluate_Bilinear (G, 5.0, 5.0);
      Check (R.Success and then Approx (R.Value, 5.0 + 10.0 + 1.0),
             "Bi right endpoint");
      R := Evaluate_Bilinear (C, 1.25, 2.75);
      Check (R.Success and then Approx (R.Value, 7.0), "Bi constant");
      R := Evaluate_Bilinear (G, -1.0, 0.0);
      Check (not R.Success and then R.Stat = Out_Of_Domain, "Bi OOD");
      R := Evaluate_Bilinear (S, 0.0, 1.0);
      Check (not R.Success and then R.Stat = Too_Small_Grid, "Bi too small");
      R := Evaluate (Bilinear, G, 0.5, 0.5);
      Check (R.Success
             and then Approx (R.Value, 0.5 + 1.0 + 1.0),
             "Dispatch Bilinear");
   end;

   ---------------------------------------------------------------------
   Section ("6. Evaluate_Bicubic");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Affine_2D (8, 8, 1.0, 2.0, 0.0);
      C : constant Grid_2D := Make_Constant_2D (5, 5, 4.0);
      Tiny : constant Grid_2D := Make_Constant_2D (3, 3, 1.0);
      R : Eval_Result;
   begin
      R := Evaluate_Bicubic (G, 0.0, 0.0);
      Check (R.Success and then Approx (R.Value, 0.0), "Bc origin");
      R := Evaluate_Bicubic (G, 3.0, 4.0);
      Check (R.Success and then Approx (R.Value, 3.0 + 8.0), "Bc node");
      R := Evaluate_Bicubic (G, 2.5, 1.5);
      Check (R.Success
             and then Approx (R.Value, 2.5 + 3.0, 1.0E-4),
             "Bc affine mid (exact under odd reflection)");
      R := Evaluate_Bicubic (G, 7.0, 7.0);
      Check (R.Success and then Approx (R.Value, 7.0 + 14.0),
             "Bc far corner");
      R := Evaluate_Bicubic (C, 2.3, 1.7);
      Check (R.Success and then Approx (R.Value, 4.0, 1.0E-4),
             "Bc constant");
      R := Evaluate_Bicubic (Tiny, 1.0, 1.0);
      Check (not R.Success and then R.Stat = Too_Small_Grid, "Bc too small");
      R := Evaluate_Bicubic (G, 8.0, 0.0);
      Check (not R.Success and then R.Stat = Out_Of_Domain, "Bc OOD");
      R := Evaluate (Bicubic, G, 1.25, 2.75);
      Check (R.Success
             and then Approx (R.Value, 1.25 + 5.5, 1.0E-4),
             "Dispatch Bicubic");
   end;

   ---------------------------------------------------------------------
   Section ("7. Evaluate_Trilinear");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_3D :=
        Make_Affine_3D (4, 4, 4, 1.0, 2.0, 3.0, 0.0);
      C : constant Grid_3D := Make_Constant_3D (3, 3, 3, 9.0);
      Tiny : constant Grid_3D := Make_Constant_3D (1, 2, 2, 0.0);
      R : Eval_Result;
   begin
      R := Evaluate_Trilinear (G, 0.0, 0.0, 0.0);
      Check (R.Success and then Approx (R.Value, 0.0), "Tri origin");
      R := Evaluate_Trilinear (G, 1.0, 2.0, 3.0);
      Check (R.Success and then Approx (R.Value, 1.0 + 4.0 + 9.0),
             "Tri node");
      R := Evaluate_Trilinear (G, 0.5, 1.5, 2.5);
      Check (R.Success
             and then Approx
               (R.Value, 0.5 + 2.0 * 1.5 + 3.0 * 2.5),
             "Tri affine mid-cell");
      R := Evaluate_Trilinear (C, 1.25, 0.5, 1.75);
      Check (R.Success and then Approx (R.Value, 9.0), "Tri constant");
      R := Evaluate_Trilinear (G, -0.1, 0.0, 0.0);
      Check (not R.Success and then R.Stat = Out_Of_Domain, "Tri OOD");
      R := Evaluate_Trilinear (Tiny, 0.0, 0.5, 0.5);
      Check (not R.Success and then R.Stat = Too_Small_Grid,
             "Tri too small");
   end;

   ---------------------------------------------------------------------
   Section ("8. Evaluate_IDW (scattered)");
   ---------------------------------------------------------------------
   declare
      Sq : constant Scattered_2D :=
        Make_Unit_Square_Cloud (0.0, 1.0, 2.0, 3.0);
      Aff : constant Grid_2D := Make_Affine_2D (3, 3, 1.0, 2.0, 0.0);
      Cloud : constant Scattered_2D := Make_Scattered_From_Grid (Aff);
      R : Eval_Result;
      Empty_S : Scattered_2D;
   begin
      Check (Is_Valid_Scattered (Sq) and then Sq.Count = 4, "Unit cloud");
      R := Evaluate_IDW (Sq, 0.0, 0.0);
      Check (R.Success and then Approx (R.Value, 0.0), "IDW exact hit");
      R := Evaluate_IDW (Sq, 1.0, 1.0);
      Check (R.Success and then Approx (R.Value, 3.0), "IDW hit F11");
      R := Evaluate_IDW (Sq, 0.5, 0.5);
      Check (R.Success
             and then Approx (R.Value, (0.0 + 1.0 + 2.0 + 3.0) / 4.0),
             "IDW center equal weights");
      R := Evaluate_IDW (Cloud, 1.0, 1.0);
      Check (R.Success and then Approx (R.Value, 1.0 + 2.0),
             "IDW from grid hit");
      R := Evaluate_IDW (Cloud, 0.5, 0.5, 2.0);
      Check (R.Success, "IDW off-node succeeds");
      Empty_S.Valid := True;
      Empty_S.Count := 0;
      R := Evaluate_IDW (Empty_S, 0.0, 0.0);
      Check (not R.Success and then R.Stat = Empty, "IDW empty");
      Empty_S.Valid := False;
      R := Evaluate_IDW (Empty_S, 0.0, 0.0);
      Check (not R.Success and then R.Stat = Ill_Started, "IDW ill");
   end;

   ---------------------------------------------------------------------
   Section ("9. Cross-checks / dispatch rejects");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Affine_2D (6, 6, 1.0, 2.0, 0.0);
      RN, RB, RC : Eval_Result;
      R : Eval_Result;
      X : constant Float := 2.25;
      Y : constant Float := 3.75;
      Expect : constant Float := X + 2.0 * Y;
   begin
      RN := Evaluate_Nearest_2D (G, 2.0, 3.0);
      RB := Evaluate_Bilinear (G, X, Y);
      RC := Evaluate_Bicubic (G, X, Y);
      Check (RN.Success and then Approx (RN.Value, 2.0 + 6.0),
             "Cross NN on node");
      Check (RB.Success and then Approx (RB.Value, Expect),
             "Cross Bi affine");
      Check (RC.Success and then Approx (RC.Value, Expect, 1.0E-4),
             "Cross Bc affine");
      Check (Near (RB.Value, RC.Value, 1.0E-4), "Bi ≈ Bc on affine");
      R := Evaluate (Trilinear, G, 1.0, 1.0);
      Check (not R.Success and then R.Stat = Not_Implemented,
             "Dispatch Trilinear reject on 2D API");
      R := Evaluate (Lanczos, G, 1.0, 1.0);
      Check (not R.Success and then R.Stat = Not_Implemented,
             "Dispatch Lanczos reject");
      R := Evaluate (Kriging, G, 1.0, 1.0);
      Check (not R.Success and then R.Stat = Not_Implemented,
             "Dispatch Kriging reject");
      R := Evaluate (Tricubic, G, 1.0, 1.0);
      Check (not R.Success and then R.Stat = Not_Implemented,
             "Dispatch Tricubic reject");
   end;

   ---------------------------------------------------------------------
   Section ("10. Caps / examples / Get-Set");
   ---------------------------------------------------------------------
   declare
      Big : constant Grid_2D := Make_Constant_2D (Max_N, Max_N, 1.0);
      ExA : constant Grid_2D := Make_Example (Affine_Field);
      ExC : constant Grid_2D := Make_Example (Checkerboard);
      Mut : Grid_2D := Make_Empty_2D (3, 3);
      G3  : constant Grid_3D := Make_Empty_3D (2, 2, 2);
   begin
      Check (Big.Nx = Max_N and then Big.Ny = Max_N, "Max_N grid");
      Check (Approx (Get (ExA, 1, 1), 1.0 + 2.0 + 1.0), "Ex affine");
      Check (Approx (Get (ExC, 1, 0), 0.0), "Ex checker");
      Set (Mut, 1, 2, 42.0);
      Check (Approx (Get (Mut, 1, 2), 42.0), "Get/Set 2D");
      Check (Is_Valid_Grid (G3) and then G3.Nz = 2, "Empty 3D");
      Check (Big.Nx = Big.Ny and then Approx (Get (Big, 0, 0), 1.0),
             "Max-sized constant grid");
      declare
         Sc : constant Scattered_2D := Make_Empty_Scattered (8);
      begin
         Check (Is_Valid_Scattered (Sc) and then Sc.Count = 8,
                "Empty scattered cloud");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Checkerboard / nearest vs bilinear contrast");
   ---------------------------------------------------------------------
   declare
      Ch : constant Grid_2D := Make_Checkerboard_2D (4, 4, 0.0, 1.0);
      RN, RB : Eval_Result;
   begin
      RN := Evaluate_Nearest_2D (Ch, 0.4, 0.4);
      RB := Evaluate_Bilinear (Ch, 0.5, 0.5);
      Check (RN.Success and then Approx (RN.Value, 1.0),
             "NN stays at Hi near (0,0)");
      Check (RB.Success and then Approx (RB.Value, 0.5),
             "Bi averages checker cell");
      RN := Evaluate_Nearest_2D (Ch, 0.6, 0.4);
      Check (RN.Success and then Approx (RN.Value, 0.0),
             "NN crosses to Lo at x=0.6");
   end;

   ---------------------------------------------------------------------
   Section ("12. More Recommend / Classify coverage");
   ---------------------------------------------------------------------
   declare
      Info : Method_Info;
      M    : Method_Kind;
   begin
      for K in Method_Kind loop
         Info := Classify_Method (K);
         Check (Info.Kind = K, "Classify kind " & Method_Name (K));
         Check (Method_Name (K)'Length > 3, "Name len " & Method_Name (K));
         Check (Describe (K)'Length > 10, "Desc len " & Method_Name (K));
      end loop;
      M := Recommend_Method (Regular_Grid, 3, Piecewise_Constant);
      Check (M = Nearest_Neighbor, "Rec 3D PC → NN");
      Info := Classify_Method (Lanczos);
      Check (not Info.Runnable_Sketch and then Info.Smooth = C1_Smooth,
             "Lanczos catalogue C1");
      Info := Classify_Method (Barnes);
      Check (Info.For_Scattered and then not Info.Runnable_Sketch,
             "Barnes scattered catalogue");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
