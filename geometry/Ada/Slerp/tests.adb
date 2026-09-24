with Ada.Text_IO; use Ada.Text_IO;
with Slerp;       use Slerp;

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

   --  Helper tolerances
   Tol : constant Real := 1.0e-4;

   function Approx_Equal (A, B : Real; Delta_Val : Real := Tol) return Boolean is
   begin
      return abs (A - B) <= Delta_Val;
   end Approx_Equal;

   function Approx_Equal (U, V : Vector_3D; Delta_Val : Real := Tol) return Boolean is
   begin
      return Approx_Equal (U.X, V.X, Delta_Val) and then
             Approx_Equal (U.Y, V.Y, Delta_Val) and then
             Approx_Equal (U.Z, V.Z, Delta_Val);
   end Approx_Equal;

   function Approx_Equal (P, Q : Quaternion; Delta_Val : Real := Tol) return Boolean is
   begin
      --  Check standard identity or antipodal quaternion identity on SO(3)
      return (Approx_Equal (P.W, Q.W, Delta_Val) and then
              Approx_Equal (P.X, Q.X, Delta_Val) and then
              Approx_Equal (P.Y, Q.Y, Delta_Val) and then
              Approx_Equal (P.Z, Q.Z, Delta_Val))
             or else
             (Approx_Equal (P.W, -Q.W, Delta_Val) and then
              Approx_Equal (P.X, -Q.X, Delta_Val) and then
              Approx_Equal (P.Y, -Q.Y, Delta_Val) and then
              Approx_Equal (P.Z, -Q.Z, Delta_Val));
   end Approx_Equal;

   --  Common Test Data
   Vec_X : constant Vector_3D := (1.0, 0.0, 0.0);
   Vec_Y : constant Vector_3D := (0.0, 1.0, 0.0);

   --  Identity Quaternion (0 degree rotation)
   Q_Ident : constant Quaternion := (1.0, 0.0, 0.0, 0.0);

   --  90 degrees about Z-axis: [cos(45°), 0, 0, sin(45°)]
   SQRT2_OVER_2 : constant Real := 0.7071067811865475;
   Q_Rot_Z90 : constant Quaternion := (SQRT2_OVER_2, 0.0, 0.0, SQRT2_OVER_2);

   --  180 degrees about Z-axis: [cos(90°), 0, 0, sin(90°)] = [0, 0, 0, 1]
   Q_Rot_Z180 : constant Quaternion := (0.0, 0.0, 0.0, 1.0);

   --  90 degrees about X-axis: [cos(45°), sin(45°), 0, 0]
   Q_Rot_X90 : constant Quaternion := (SQRT2_OVER_2, SQRT2_OVER_2, 0.0, 0.0);

begin

   ----------------------------------------------------------------------
   -- TEST 1 -- Vector Algebra and Normalization
   ----------------------------------------------------------------------
   Put_Line ("TEST 1 -- Vector Algebra & Normalization");
   declare
      V1  : constant Vector_3D := (3.0, 0.0, 4.0);
      V1N : constant Vector_3D := Normalize (V1);
   begin
      Check ("1.1 Vector norm calculation", Approx_Equal (Norm (V1), 5.0));
      Check ("1.2 Normalized vector has unit norm", Is_Normalized (V1N));
      Check ("1.3 Normalized components match ratio",
             Approx_Equal (V1N.X, 0.6) and then Approx_Equal (V1N.Z, 0.8));
   end;

   ----------------------------------------------------------------------
   -- TEST 2 -- Vector Exception Handling on Zero Length
   ----------------------------------------------------------------------
   Put_Line ("TEST 2 -- Vector Error Handling");
   declare
      Zero_Vec : constant Vector_3D := (0.0, 0.0, 0.0);
      Caught : Boolean := False;
   begin
      begin
         declare
            Unused_V : constant Vector_3D := Normalize (Zero_Vec);
            pragma Unreferenced (Unused_V);
         begin
            null;
         end;
      exception
         when Degenerate_Vector_Error =>
            Caught := True;
         when others =>
            Caught := False;
      end;
      Check ("2.1 Zero-vector normalize raises Degenerate_Vector_Error", Caught);
      Check ("2.2 Is_Normalized rejects zero-vector", not Is_Normalized (Zero_Vec));
      Check ("2.3 Dot product of orthogonal vectors is zero",
             Approx_Equal (Dot (Vec_X, Vec_Y), 0.0));
   end;

   ----------------------------------------------------------------------
   -- TEST 3 -- Geometric Slerp Cardinal Points
   ----------------------------------------------------------------------
   Put_Line ("TEST 3 -- Geometric Slerp Endpoints & Midpoint");
   declare
      Start_Vec : constant Vector_3D := Geometric_Slerp (Vec_X, Vec_Y, 0.0);
      End_Vec   : constant Vector_3D := Geometric_Slerp (Vec_X, Vec_Y, 1.0);
      Mid_Vec   : constant Vector_3D := Geometric_Slerp (Vec_X, Vec_Y, 0.5);
      Expected_Mid : constant Vector_3D := (SQRT2_OVER_2, SQRT2_OVER_2, 0.0);
   begin
      Check ("3.1 Slerp at t=0 returns P0", Approx_Equal (Start_Vec, Vec_X));
      Check ("3.2 Slerp at t=1 returns P1", Approx_Equal (End_Vec, Vec_Y));
      Check ("3.3 Slerp at t=0.5 bisects 90-degree arc", Approx_Equal (Mid_Vec, Expected_Mid));
   end;

   ----------------------------------------------------------------------
   -- TEST 4 -- Geometric Slerp Identical and Collinear Cases
   ----------------------------------------------------------------------
   Put_Line ("TEST 4 -- Geometric Slerp Identical & Collinear Vectors");
   declare
      Same_Vec : constant Vector_3D := Geometric_Slerp (Vec_X, Vec_X, 0.42);
      Opposite : constant Vector_3D := (-1.0, 0.0, 0.0);
      Antipodal_Raised : Boolean := False;
   begin
      Check ("4.1 Slerp identical vectors returns same vector", Approx_Equal (Same_Vec, Vec_X));
      Check ("4.2 Slerp identical result is normalized", Is_Normalized (Same_Vec));
      begin
         declare
            Unused_V : constant Vector_3D := Geometric_Slerp (Vec_X, Opposite, 0.5);
            pragma Unreferenced (Unused_V);
         begin
            null;
         end;
      exception
         when Invalid_Argument_Error =>
            Antipodal_Raised := True;
         when others =>
            Antipodal_Raised := False;
      end;
      Check ("4.3 Antipodal vector Slerp raises Invalid_Argument_Error", Antipodal_Raised);
   end;

   ----------------------------------------------------------------------
   -- TEST 5 -- Quaternion Arithmetic (Norm, Inverse, Multiplication)
   ----------------------------------------------------------------------
   Put_Line ("TEST 5 -- Quaternion Fundamental Arithmetic");
   declare
      Q_Inv : constant Quaternion := Inverse (Q_Rot_Z90);
      Prod  : constant Quaternion := Multiply (Q_Rot_Z90, Q_Inv);
      Zero_Q : constant Quaternion := (0.0, 0.0, 0.0, 0.0);
      Caught_Inv : Boolean := False;
   begin
      Check ("5.1 Conjugate/Inverse product is Identity", Approx_Equal (Prod, Q_Ident));
      Check ("5.2 Rot_Z90 is normalized", Is_Normalized (Q_Rot_Z90));
      begin
         declare
            Unused_Q : constant Quaternion := Inverse (Zero_Q);
            pragma Unreferenced (Unused_Q);
         begin
            null;
         end;
      exception
         when Degenerate_Quaternion_Error =>
            Caught_Inv := True;
         when others =>
            Caught_Inv := False;
      end;
      Check ("5.3 Zero quaternion inversion raises exception", Caught_Inv);
   end;

   ----------------------------------------------------------------------
   -- TEST 6 -- Raw Quaternion Slerp (No Inversion)
   ----------------------------------------------------------------------
   Put_Line ("TEST 6 -- Raw Quaternion Slerp");
   declare
      --  Halfway between 0 and 90 degrees around Z should be 45 degrees around Z:
      --  cos(22.5°) = 0.9238795325, sin(22.5°) = 0.3826834323
      Expected_Z45 : constant Quaternion := (0.92387953, 0.0, 0.0, 0.38268343);
      S_Half : constant Quaternion := Raw_Quaternion_Slerp (Q_Ident, Q_Rot_Z90, 0.5);
      S_Zero : constant Quaternion := Raw_Quaternion_Slerp (Q_Ident, Q_Rot_Z90, 0.0);
      S_One  : constant Quaternion := Raw_Quaternion_Slerp (Q_Ident, Q_Rot_Z90, 1.0);
   begin
      Check ("6.1 Raw Slerp t=0 matches Q0", Approx_Equal (S_Zero, Q_Ident));
      Check ("6.2 Raw Slerp t=1 matches Q1", Approx_Equal (S_One, Q_Rot_Z90));
      Check ("6.3 Raw Slerp t=0.5 produces expected 45-deg rotation", Approx_Equal (S_Half, Expected_Z45));
   end;

   ----------------------------------------------------------------------
   -- TEST 7 -- Shortest Path Slerp with Negative Antipodal Quaternion
   ----------------------------------------------------------------------
   Put_Line ("TEST 7 -- Shortest Path Slerp (Hemisphere Flipping)");
   declare
      --  -Q_Rot_Z90 represents the identical rotation as Q_Rot_Z90
      Q_Neg : constant Quaternion :=
        (W => -Q_Rot_Z90.W, X => -Q_Rot_Z90.X, Y => -Q_Rot_Z90.Y, Z => -Q_Rot_Z90.Z);
      S_Short : constant Quaternion := Shortest_Path_Slerp (Q_Ident, Q_Neg, 0.5);
      Expected_Z45 : constant Quaternion := (0.92387953, 0.0, 0.0, 0.38268343);
   begin
      Check ("7.1 Dot product is negative", Dot (Q_Ident, Q_Neg) < 0.0);
      Check ("7.2 Shortest path Slerp stays on acute arc", Approx_Equal (S_Short, Expected_Z45));
      Check ("7.3 Resulting quaternion is normalized", Is_Normalized (S_Short));
   end;

   ----------------------------------------------------------------------
   -- TEST 8 -- Nlerp Approximation Accuracy and Invariants
   ----------------------------------------------------------------------
   Put_Line ("TEST 8 -- Nlerp Approximation Properties");
   declare
      N_Zero : constant Quaternion := Nlerp (Q_Ident, Q_Rot_Z90, 0.0);
      N_One  : constant Quaternion := Nlerp (Q_Ident, Q_Rot_Z90, 1.0);
      N_Half : constant Quaternion := Nlerp (Q_Ident, Q_Rot_Z90, 0.5);
      S_Half : constant Quaternion := Shortest_Path_Slerp (Q_Ident, Q_Rot_Z90, 0.5);
   begin
      Check ("8.1 Nlerp t=0 matches start", Approx_Equal (N_Zero, Q_Ident));
      Check ("8.2 Nlerp t=1 matches end", Approx_Equal (N_One, Q_Rot_Z90));
      Check ("8.3 Nlerp at midpoint closely tracks exact Slerp",
             Approx_Equal (N_Half, S_Half, 0.05));
   end;

   ----------------------------------------------------------------------
   -- TEST 9 -- Quaternion Exponential, Logarithm and Power
   ----------------------------------------------------------------------
   Put_Line ("TEST 9 -- Lie Algebra Mappings (Log / Exp / Power)");
   declare
      Log_Z90  : constant Quaternion := Log (Q_Rot_Z90);
      Exp_Back : constant Quaternion := Exp (Log_Z90);
      Pow_Half : constant Quaternion := Power (Q_Rot_Z90, 0.5);
      Expected_Z45 : constant Quaternion := (0.92387953, 0.0, 0.0, 0.38268343);
   begin
      Check ("9.1 Log pure vector part w=0", Approx_Equal (Log_Z90.W, 0.0));
      Check ("9.2 Exp(Log(Q)) restores Q", Approx_Equal (Exp_Back, Q_Rot_Z90));
      Check ("9.3 Q^0.5 produces half-angle rotation", Approx_Equal (Pow_Half, Expected_Z45));
   end;

   ----------------------------------------------------------------------
   -- TEST 10 -- Squad Intermediate Control Points
   ----------------------------------------------------------------------
   Put_Line ("TEST 10 -- Squad Intermediate Point Construction");
   declare
      --  Equally spaced rotation sequence: Ident, Z90, Z180
      Ctrl_Pt : constant Quaternion :=
        Compute_Squad_Intermediate (Q_Ident, Q_Rot_Z90, Q_Rot_Z180);
   begin
      Check ("10.1 Squad control point is normalized", Is_Normalized (Ctrl_Pt));
      Check ("10.2 Control point W component is positive", Ctrl_Pt.W >= 0.0);
      Check ("10.3 Control point rotation axis is along Z",
             Approx_Equal (Ctrl_Pt.X, 0.0) and then Approx_Equal (Ctrl_Pt.Y, 0.0));
   end;

   ----------------------------------------------------------------------
   -- TEST 11 -- Squad Spline Interpolation Endpoints and C1 Continuity
   ----------------------------------------------------------------------
   Put_Line ("TEST 11 -- Squad Spline Interpolation");
   declare
      Ctrl_A : constant Quaternion :=
        Compute_Squad_Intermediate (Q_Ident, Q_Ident, Q_Rot_Z90);
      Ctrl_B : constant Quaternion :=
        Compute_Squad_Intermediate (Q_Ident, Q_Rot_Z90, Q_Rot_Z180);

      Sq_Start : constant Quaternion :=
        Squad (Q_Ident, Ctrl_A, Ctrl_B, Q_Rot_Z90, 0.0);
      Sq_End   : constant Quaternion :=
        Squad (Q_Ident, Ctrl_A, Ctrl_B, Q_Rot_Z90, 1.0);
      Sq_Mid   : constant Quaternion :=
        Squad (Q_Ident, Ctrl_A, Ctrl_B, Q_Rot_Z90, 0.5);
   begin
      Check ("11.1 Squad at t=0 hits starting quaternion", Approx_Equal (Sq_Start, Q_Ident));
      Check ("11.2 Squad at t=1 hits ending quaternion", Approx_Equal (Sq_End, Q_Rot_Z90));
      Check ("11.3 Squad intermediate point is normalized", Is_Normalized (Sq_Mid));
   end;

   ----------------------------------------------------------------------
   -- TEST 12 -- Monotonic Angle Invariance Under Constant Slerp Steps
   ----------------------------------------------------------------------
   Put_Line ("TEST 12 -- Constant Angular Velocity Invariant");
   declare
      S1 : constant Quaternion := Shortest_Path_Slerp (Q_Ident, Q_Rot_Z180, 0.25);
      S2 : constant Quaternion := Shortest_Path_Slerp (Q_Ident, Q_Rot_Z180, 0.50);
      S3 : constant Quaternion := Shortest_Path_Slerp (Q_Ident, Q_Rot_Z180, 0.75);

      --  Step distances along the sphere should be uniform
      Dot01 : constant Real := abs (Dot (Q_Ident, S1));
      Dot12 : constant Real := abs (Dot (S1, S2));
      Dot23 : constant Real := abs (Dot (S2, S3));
   begin
      Check ("12.1 Equal arc step 0->1 equals 1->2", Approx_Equal (Dot01, Dot12));
      Check ("12.2 Equal arc step 1->2 equals 2->3", Approx_Equal (Dot12, Dot23));
      Check ("12.3 All interpolated quaternions remain normalized",
             Is_Normalized (S1) and then Is_Normalized (S2) and then Is_Normalized (S3));
   end;

   ----------------------------------------------------------------------
   -- TEST 13 -- Cross-Axis Quaternion Slerp
   ----------------------------------------------------------------------
   Put_Line ("TEST 13 -- Multi-Axis Orientation Interpolation");
   declare
      --  Interpolating from Z-90 rotation to X-90 rotation
      Cross_Slerp : constant Quaternion := Shortest_Path_Slerp (Q_Rot_Z90, Q_Rot_X90, 0.5);
      Cross_Nlerp : constant Quaternion := Nlerp (Q_Rot_Z90, Q_Rot_X90, 0.5);
   begin
      Check ("13.1 Multi-axis Slerp result is normalized", Is_Normalized (Cross_Slerp));
      Check ("13.2 Multi-axis Nlerp result is normalized", Is_Normalized (Cross_Nlerp));
      Check ("13.3 Slerp and Nlerp maintain positive real component",
             Cross_Slerp.W > 0.0 and then Cross_Nlerp.W > 0.0);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
