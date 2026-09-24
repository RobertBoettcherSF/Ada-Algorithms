--  Standalone test suite for Kabsch (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Ada.Numerics.Generic_Elementary_Functions;
with Kabsch; use Kabsch;

procedure Tests is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-8) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Rotation_Z (Angle : Real) return Mat3 is
      C : constant Real := Math.Cos (Angle);
      S : constant Real := Math.Sin (Angle);
      R : Mat3 := Identity_Mat3;
   begin
      R (1, 1) := C;
      R (1, 2) := -S;
      R (2, 1) := S;
      R (2, 2) := C;
      return R;
   end Rotation_Z;

   function Rotation_X (Angle : Real) return Mat3 is
      C : constant Real := Math.Cos (Angle);
      S : constant Real := Math.Sin (Angle);
      R : Mat3 := Identity_Mat3;
   begin
      R (2, 2) := C;
      R (2, 3) := -S;
      R (3, 2) := S;
      R (3, 3) := C;
      return R;
   end Rotation_X;

   function Rotation_Y (Angle : Real) return Mat3 is
      C : constant Real := Math.Cos (Angle);
      S : constant Real := Math.Sin (Angle);
      R : Mat3 := Identity_Mat3;
   begin
      R (1, 1) := C;
      R (1, 3) := S;
      R (3, 1) := -S;
      R (3, 3) := C;
      return R;
   end Rotation_Y;

   function Sample_Cloud return Point_Cloud is
   begin
      return
        [[0.0, 0.0, 0.0],
         [1.0, 0.0, 0.0],
         [0.0, 1.0, 0.0],
         [0.0, 0.0, 1.0],
         [1.0, 1.0, 0.0],
         [1.0, 0.0, 1.0],
         [0.0, 1.0, 1.0],
         [1.0, 1.0, 1.0]];
   end Sample_Cloud;

   function Rigid_Map
     (P : Point_Cloud; R : Mat3; T : Vec3) return Point_Cloud
   is
      Q : Point_Cloud (P'Range);
   begin
      for I in P'Range loop
         declare
            V : constant Vec3 := Mat3_Vec (R, P (I));
         begin
            Q (I) := [V (1) + T (1), V (2) + T (2), V (3) + T (3)];
         end;
      end loop;
      return Q;
   end Rigid_Map;

   type U32 is mod 2**32;
   Seed : U32 := 1_234_567;

   function Next_Unit return Real is
   begin
      Seed := Seed * 1_103_515_245 + 12_345;
      return Real (Seed rem 2**30) / Real (2**30);
   end Next_Unit;

   function Rand_Cloud (N : Positive) return Point_Cloud is
      P : Point_Cloud (1 .. N);
   begin
      for I in 1 .. N loop
         P (I) :=
           [10.0 * (Next_Unit - 0.5),
            10.0 * (Next_Unit - 0.5),
            10.0 * (Next_Unit - 0.5)];
      end loop;
      return P;
   end Rand_Cloud;

begin
   Put_Line ("Kabsch test suite");
   Put_Line ("=================");

   ---------------------------------------------------------------------
   Section ("1. Helpers: Near / Dot / Norm / Cross / Mat3");
   ---------------------------------------------------------------------
   declare
      A : constant Vec3 := [1.0, 2.0, 3.0];
      B : constant Vec3 := [4.0, 5.0, 6.0];
      I : constant Mat3 := Identity_Mat3;
      Z : constant Mat3 := Zero_Mat3;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (not Near (1.0, 2.0), "Near unequal");
      Check (Near_Vec3 (A, A), "Near_Vec3 same");
      Check (Approx (Dot (A, B), 32.0), "Dot product");
      Check (Approx (Real (Norm2 (A)), 14.0), "Norm2");
      Check (Approx (Real (Norm (A)), Math.Sqrt (14.0), 1.0E-12), "Norm");
      Check (Near_Vec3 (Cross (A, B), [-3.0, 6.0, -3.0]), "Cross product");
      Check (Near_Mat3 (I, I), "Near_Mat3 identity");
      Check (Approx (Mat3_Det (I), 1.0), "det(I)=1");
      Check (Approx (Mat3_Trace (I), 3.0), "tr(I)=3");
      Check (Approx (Real (Mat3_Frobenius (Z)), 0.0), "||0||_F=0");
      Check (Approx (Real (Mat3_Frobenius (I)), Math.Sqrt (3.0), 1.0E-12),
             "||I||_F=sqrt(3)");
      Check (Near_Mat3 (Mat3_Mul (I, I), I), "I*I=I");
      Check (Near_Vec3 (Mat3_Vec (I, A), A), "I*v=v");
      Check (Near_Mat3 (Mat3_Transpose (I), I), "I^T=I");
   end;

   declare
      A : constant Mat3 :=
        [[1.0, 2.0, 3.0],
         [0.0, 1.0, 4.0],
         [5.0, 6.0, 0.0]];
      A_T : constant Mat3 := Mat3_Transpose (A);
   begin
      Check (Approx (A_T (1, 2), 0.0) and then Approx (A_T (2, 1), 2.0),
             "Transpose swap");
      Check (Approx (Mat3_Det (A), 1.0 * (0.0 - 24.0)
                                    - 2.0 * (0.0 - 20.0)
                                    + 3.0 * (0.0 - 5.0), 1.0E-10),
             "det known 3x3");
   end;

   ---------------------------------------------------------------------
   Section ("2. Centroid / Translate / Covariance");
   ---------------------------------------------------------------------
   declare
      P : constant Point_Cloud (1 .. 3) :=
        [[1.0, 0.0, 0.0],
         [0.0, 1.0, 0.0],
         [0.0, 0.0, 1.0]];
      C : constant Vec3 := Centroid (P);
      Pc : constant Point_Cloud := Translate_To_Origin (P);
      Cc : constant Vec3 := Centroid (Pc);
   begin
      Check (Near_Vec3 (C, [1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0], 1.0E-12),
             "Centroid of basis points");
      Check (Near_Vec3 (Cc, [0.0, 0.0, 0.0], 1.0E-12),
             "Centered cloud centroid ~ 0");
      Check (Approx (Pc (1) (1) + Pc (2) (1) + Pc (3) (1), 0.0, 1.0E-12),
             "Centered X sum 0");
   end;

   declare
      P : constant Point_Cloud := Sample_Cloud;
      T : constant Vec3 := [3.0, -2.0, 5.0];
      Q : constant Point_Cloud := Translate_By (P, T);
      C1 : constant Vec3 := Centroid (P);
      C2 : constant Vec3 := Centroid (Q);
   begin
      Check (Near_Vec3 (C2,
                        [C1 (1) + T (1), C1 (2) + T (2), C1 (3) + T (3)],
                        1.0E-12),
             "Translate_By shifts centroid");
   end;

   declare
      P : constant Point_Cloud (1 .. 2) :=
        [[1.0, 0.0, 0.0],
         [-1.0, 0.0, 0.0]];
      Q : constant Point_Cloud (1 .. 2) :=
        [[0.0, 1.0, 0.0],
         [0.0, -1.0, 0.0]];
      H : constant Mat3 := Covariance_H (P, Q);
   begin
      Check (Approx (H (1, 2), 2.0), "Covariance H(1,2)=2");
      Check (Approx (H (1, 1), 0.0), "Covariance H(1,1)=0");
      Check (Approx (H (2, 2), 0.0), "Covariance H(2,2)=0");
   end;

   ---------------------------------------------------------------------
   Section ("3. SVD 3x3");
   ---------------------------------------------------------------------
   declare
      A : constant Mat3 := Identity_Mat3;
      U, Vt : Mat3;
      S : Singular_Values;
      Recon : Mat3;
   begin
      SVD_3x3 (A, U, S, Vt);
      Check (Approx (Real (S (1)), 1.0, 1.0E-10)
               and then Approx (Real (S (2)), 1.0, 1.0E-10)
               and then Approx (Real (S (3)), 1.0, 1.0E-10),
             "SVD(I) singular values = 1");
      Recon := Mat3_Mul
        (Mat3_Mul (U,
                   [[Real (S (1)), 0.0, 0.0],
                    [0.0, Real (S (2)), 0.0],
                    [0.0, 0.0, Real (S (3))]]),
         Vt);
      Check (Near_Mat3 (Recon, A, 1.0E-8), "SVD(I) reconstruction");
      Check (Approx (abs (Mat3_Det (U)), 1.0, 1.0E-8), "|det(U)|~1");
      Check (Approx (abs (Mat3_Det (Vt)), 1.0, 1.0E-8), "|det(Vt)|~1");
   end;

   declare
      A : constant Mat3 :=
        [[3.0, 0.0, 0.0],
         [0.0, 2.0, 0.0],
         [0.0, 0.0, 1.0]];
      U, Vt : Mat3;
      S : Singular_Values;
   begin
      SVD_3x3 (A, U, S, Vt);
      Check (Approx (Real (S (1)), 3.0, 1.0E-8), "SVD diag s1=3");
      Check (Approx (Real (S (2)), 2.0, 1.0E-8), "SVD diag s2=2");
      Check (Approx (Real (S (3)), 1.0, 1.0E-8), "SVD diag s3=1");
   end;

   declare
      A : constant Mat3 :=
        [[1.0, 2.0, 0.0],
         [2.0, 1.0, 0.0],
         [0.0, 0.0, 3.0]];
      U, Vt : Mat3;
      S : Singular_Values;
      Mid : Mat3 := Zero_Mat3;
      Recon : Mat3;
   begin
      SVD_3x3 (A, U, S, Vt);
      Mid (1, 1) := Real (S (1));
      Mid (2, 2) := Real (S (2));
      Mid (3, 3) := Real (S (3));
      Recon := Mat3_Mul (Mat3_Mul (U, Mid), Vt);
      Check (Near_Mat3 (Recon, A, 1.0E-6), "SVD general reconstruction");
      Check (Real (S (1)) >= Real (S (2))
               and then Real (S (2)) >= Real (S (3)),
             "Singular values sorted desc");
   end;

   ---------------------------------------------------------------------
   Section ("4. Identical clouds -> R~I, RMSD~0");
   ---------------------------------------------------------------------
   declare
      P : constant Point_Cloud := Sample_Cloud;
      R : constant Mat3 := Kabsch_Rotation (P, P);
      Res : constant Superimpose_Result := Superimpose (P, P);
   begin
      Check (Near_Mat3 (R, Identity_Mat3, 1.0E-8),
             "Identical: Kabsch_Rotation ~ I");
      Check (Approx (Real (Res.RMSD), 0.0, 1.0E-10),
             "Identical: Superimpose RMSD~0");
      Check (Approx (Mat3_Det (R), 1.0, 1.0E-8),
             "Identical: det(R)=+1");
      Check (Approx (Real (RMSD (P, P)), 0.0), "RMSD(P,P)=0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Pure translation");
   ---------------------------------------------------------------------
   declare
      P : constant Point_Cloud := Sample_Cloud;
      T : constant Vec3 := [10.0, -4.0, 7.5];
      Q : constant Point_Cloud := Translate_By (P, T);
      R : constant Mat3 := Kabsch_Rotation (P, Q);
      Res : constant Superimpose_Result := Superimpose (P, Q);
      Aligned : constant Point_Cloud := Transformed_Cloud (Q, Res);
   begin
      Check (Near_Mat3 (R, Identity_Mat3, 1.0E-8),
             "Pure translation: R ~ I");
      Check (Approx (Real (Res.RMSD), 0.0, 1.0E-9),
             "Pure translation: RMSD~0");
      Check (Approx (Real (RMSD (P, Aligned)), 0.0, 1.0E-9),
             "Pure translation: aligned RMSD~0");
      Check (Near_Vec3 (Res.Translation,
                        [Res.Centroid_P (1) - Res.Centroid_Q (1),
                         Res.Centroid_P (2) - Res.Centroid_Q (2),
                         Res.Centroid_P (3) - Res.Centroid_Q (3)],
                        1.0E-10),
             "Translation = cP - cQ when R=I");
   end;

   ---------------------------------------------------------------------
   Section ("6. Known 90° rotation about Z");
   ---------------------------------------------------------------------
   declare
      Pi_Over_2 : constant Real := 1.5707963267948966_192;
      Rz : constant Mat3 := Rotation_Z (Pi_Over_2);
      P : constant Point_Cloud := Sample_Cloud;
      Q : constant Point_Cloud := Apply_Rotation (Rz, P);
      R : constant Mat3 := Kabsch_Rotation (P, Q);
      R_Expect : constant Mat3 := Rotation_Z (-Pi_Over_2);
      Res : constant Superimpose_Result := Superimpose (P, Q);
   begin
      Check (Near_Mat3 (R, R_Expect, 1.0E-7),
             "90° Z: recovered inverse rotation");
      Check (Approx (Real (Res.RMSD), 0.0, 1.0E-9),
             "90° Z: RMSD~0");
      Check (Approx (Mat3_Det (R), 1.0, 1.0E-8),
             "90° Z: det(R)=+1");
      Check (Approx (R (3, 3), 1.0, 1.0E-8), "90° Z: R33=1");
      Check (Approx (R (1, 2), 1.0, 1.0E-7)
               and then Approx (R (2, 1), -1.0, 1.0E-7),
             "90° Z: off-diagonal pattern");
   end;

   ---------------------------------------------------------------------
   Section ("7. Reflection correction (det=+1)");
   ---------------------------------------------------------------------
   declare
      P : constant Point_Cloud := Sample_Cloud;
      Q : Point_Cloud (P'Range);
      R : Mat3;
      Res : Superimpose_Result;
   begin
      for I in P'Range loop
         Q (I) := [-P (I) (1), P (I) (2), P (I) (3)];
      end loop;
      R := Kabsch_Rotation (P, Q);
      Res := Superimpose (P, Q);
      Check (Approx (Mat3_Det (R), 1.0, 1.0E-7),
             "Reflection case: det(R)=+1 (no improper)");
      Check (Mat3_Det (R) > 0.0, "Reflection case: det positive");
      Check (Real (Res.RMSD) > 0.1, "Reflection case: RMSD > 0 (chirality)");
   end;

   declare
      P : constant Point_Cloud := Sample_Cloud;
      Q0 : Point_Cloud (P'Range);
      Q : Point_Cloud (P'Range);
      Rz : constant Mat3 := Rotation_Z (0.7);
      R : Mat3;
   begin
      for I in P'Range loop
         Q0 (I) := [-P (I) (1), P (I) (2), P (I) (3)];
      end loop;
      Q := Apply_Rotation (Rz, Q0);
      R := Kabsch_Rotation (P, Q);
      Check (Approx (Mat3_Det (R), 1.0, 1.0E-6),
             "Reflect+rotate: det(R)=+1");
   end;

   ---------------------------------------------------------------------
   Section ("8. Random rigid motions round-trip");
   ---------------------------------------------------------------------
   declare
      Angles : constant array (1 .. 6) of Real :=
        [0.3, -1.1, 2.0, 0.5, -0.8, 1.7];
      Shifts : constant array (1 .. 6) of Vec3 :=
        [[1.0, 2.0, 3.0],
         [-4.0, 0.5, 2.0],
         [0.0, 0.0, 0.0],
         [10.0, -10.0, 5.0],
         [0.1, 0.2, 0.3],
         [-1.5, 3.5, -2.5]];
   begin
      for K in Angles'Range loop
         declare
            P : constant Point_Cloud := Sample_Cloud;
            R_True : constant Mat3 :=
              Mat3_Mul
                (Mat3_Mul (Rotation_Z (Angles (K)),
                           Rotation_Y (0.4 * Angles (K))),
                 Rotation_X (-0.3 * Angles (K)));
            Q : constant Point_Cloud :=
              Rigid_Map (P, R_True, Shifts (K));
            Res : constant Superimpose_Result := Superimpose (P, Q);
            Aligned : constant Point_Cloud :=
              Transformed_Cloud (Q, Res);
         begin
            Check (Approx (Real (Res.RMSD), 0.0, 1.0E-7),
                   "Rigid#" & Integer'Image (K) & " RMSD~0");
            Check (Approx (Mat3_Det (Res.R), 1.0, 1.0E-6),
                   "Rigid#" & Integer'Image (K) & " det=+1");
            Check (Approx (Real (RMSD (P, Aligned)), 0.0, 1.0E-7),
                   "Rigid#" & Integer'Image (K) & " aligned match");
            Check
              (Near_Mat3
                 (Mat3_Mul (Res.R, R_True), Identity_Mat3, 1.0E-5),
               "Rigid#" & Integer'Image (K) & " R_hat R_true ~ I");
         end;
      end loop;
   end;

   for Trial in 1 .. 12 loop
      declare
         N : constant Positive := 5 + (Trial mod 7);
         P : constant Point_Cloud := Rand_Cloud (N);
         Angle : constant Real := 0.2 * Real (Trial);
         R_True : constant Mat3 :=
           Mat3_Mul (Rotation_Y (Angle), Rotation_Z (1.3 * Angle));
         T : constant Vec3 :=
           [Real (Trial), -0.5 * Real (Trial), 0.25 * Real (Trial)];
         Q : constant Point_Cloud := Rigid_Map (P, R_True, T);
         Res : constant Superimpose_Result := Superimpose (P, Q);
      begin
         Check (Approx (Real (Res.RMSD), 0.0, 1.0E-6),
                "RandRigid#" & Integer'Image (Trial) & " RMSD~0");
         Check (Approx (Mat3_Det (Res.R), 1.0, 1.0E-5),
                "RandRigid#" & Integer'Image (Trial) & " det=+1");
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("9. Noisy points — sensible RMSD");
   ---------------------------------------------------------------------
   declare
      P : constant Point_Cloud := Sample_Cloud;
      Rz : constant Mat3 := Rotation_Z (0.4);
      Q0 : constant Point_Cloud :=
        Rigid_Map (P, Rz, [1.0, 2.0, 3.0]);
      Q : Point_Cloud (Q0'Range);
      Noise : constant Real := 0.05;
      Res : Superimpose_Result;
   begin
      for I in Q0'Range loop
         Q (I) :=
           [Q0 (I) (1) + Noise * (Next_Unit - 0.5),
            Q0 (I) (2) + Noise * (Next_Unit - 0.5),
            Q0 (I) (3) + Noise * (Next_Unit - 0.5)];
      end loop;
      Res := Superimpose (P, Q);
      Check (Real (Res.RMSD) > 0.0, "Noisy: RMSD > 0");
      Check (Real (Res.RMSD) < 0.1, "Noisy: RMSD < noise scale");
      Check (Approx (Mat3_Det (Res.R), 1.0, 1.0E-5),
             "Noisy: det(R)=+1");
   end;

   for Trial in 1 .. 8 loop
      declare
         P : constant Point_Cloud := Rand_Cloud (10);
         Q : Point_Cloud (P'Range);
         Amp : constant Real := 0.01 * Real (Trial);
         Res : Superimpose_Result;
      begin
         for I in P'Range loop
            Q (I) :=
              [P (I) (1) + Amp * (Next_Unit - 0.5),
               P (I) (2) + Amp * (Next_Unit - 0.5),
               P (I) (3) + Amp * (Next_Unit - 0.5)];
         end loop;
         Res := Superimpose (P, Q);
         Check (Real (Res.RMSD) < Amp + 1.0E-6,
                "NoiseAmp#" & Integer'Image (Trial) & " RMSD bound");
         Check (Real (Res.RMSD) >= 0.0,
                "NoiseAmp#" & Integer'Image (Trial) & " RMSD>=0");
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("10. Edge cases: 2-point / 3-point");
   ---------------------------------------------------------------------
   declare
      P2 : constant Point_Cloud (1 .. 2) :=
        [[0.0, 0.0, 0.0],
         [1.0, 0.0, 0.0]];
      Q2 : constant Point_Cloud (1 .. 2) :=
        [[0.0, 0.0, 0.0],
         [0.0, 1.0, 0.0]];
      R2 : constant Mat3 := Kabsch_Rotation (P2, Q2);
      Res2 : constant Superimpose_Result := Superimpose (P2, Q2);
   begin
      Check (Approx (Mat3_Det (R2), 1.0, 1.0E-6),
             "2-point: det(R)=+1");
      Check (Approx (Real (Res2.RMSD), 0.0, 1.0E-7),
             "2-point: RMSD~0 after align");
   end;

   declare
      P3 : constant Point_Cloud (1 .. 3) :=
        [[0.0, 0.0, 0.0],
         [1.0, 0.0, 0.0],
         [0.0, 1.0, 0.0]];
      Rz : constant Mat3 := Rotation_Z (1.0);
      Q3 : constant Point_Cloud :=
        Rigid_Map (P3, Rz, [2.0, -1.0, 0.5]);
      Res3 : constant Superimpose_Result := Superimpose (P3, Q3);
   begin
      Check (Approx (Real (Res3.RMSD), 0.0, 1.0E-8),
             "3-point rigid: RMSD~0");
      Check (Approx (Mat3_Det (Res3.R), 1.0, 1.0E-7),
             "3-point: det=+1");
      Check
        (Near_Mat3 (Mat3_Mul (Res3.R, Rz), Identity_Mat3, 1.0E-6),
         "3-point: R_hat Rz ~ I");
   end;

   declare
      P : constant Point_Cloud (1 .. 3) :=
        [[0.0, 0.0, 0.0],
         [1.0, 0.0, 0.0],
         [2.0, 0.0, 0.0]];
      Q : constant Point_Cloud (1 .. 3) :=
        [[0.0, 0.0, 0.0],
         [0.0, 1.0, 0.0],
         [0.0, 2.0, 0.0]];
      Res : constant Superimpose_Result := Superimpose (P, Q);
   begin
      Check (Approx (Mat3_Det (Res.R), 1.0, 1.0E-5),
             "Collinear: det=+1");
      Check (Approx (Real (Res.RMSD), 0.0, 1.0E-6),
             "Collinear: alignable RMSD~0");
   end;

   ---------------------------------------------------------------------
   Section ("11. Apply_Rotation / Transformed_Cloud");
   ---------------------------------------------------------------------
   declare
      P : constant Point_Cloud (1 .. 1) := [[1.0, 0.0, 0.0]];
      Rz : constant Mat3 := Rotation_Z (1.5707963267948966_192);
      Q : constant Point_Cloud := Apply_Rotation (Rz, P);
   begin
      Check (Approx (Q (1) (1), 0.0, 1.0E-10)
               and then Approx (Q (1) (2), 1.0, 1.0E-10)
               and then Approx (Q (1) (3), 0.0, 1.0E-10),
             "Apply_Rotation 90° Z on e1");
      Check (Near_Vec3
               (Apply_Rotation_Vec (Rz, [0.0, 1.0, 0.0]),
                [-1.0, 0.0, 0.0], 1.0E-10),
             "Apply_Rotation_Vec 90° Z on e2");
   end;

   ---------------------------------------------------------------------
   Section ("12. 2-D Kabsch");
   ---------------------------------------------------------------------
   declare
      P : constant Point_Cloud_2D (1 .. 4) :=
        [[0.0, 0.0],
         [1.0, 0.0],
         [1.0, 1.0],
         [0.0, 1.0]];
      Q : Point_Cloud_2D (1 .. 4);
      R : Mat2;
      C : constant Vec2 := Centroid_2D (P);
      I2 : constant Mat2 := Identity_Mat2;
   begin
      for I in P'Range loop
         Q (I) := [-P (I) (2), P (I) (1)];
      end loop;
      Check (Near (C (1), 0.5, 1.0E-12) and then Near (C (2), 0.5, 1.0E-12),
             "2D centroid of unit square");
      R := Kabsch_Rotation_2D (P, Q);
      Check (Approx (Mat2_Det (R), 1.0, 1.0E-6), "2D: det(R)=+1");
      Check (Approx (R (1, 1), 0.0, 1.0E-6)
               and then Approx (R (1, 2), 1.0, 1.0E-6)
               and then Approx (R (2, 1), -1.0, 1.0E-6)
               and then Approx (R (2, 2), 0.0, 1.0E-6),
             "2D: recovered -90° rotation");
      Check (Approx (Real (RMSD_2D (P, P)), 0.0), "2D RMSD(P,P)=0");
      Check (Approx (I2 (1, 1), 1.0) and then Approx (I2 (2, 2), 1.0)
               and then Approx (I2 (1, 2), 0.0),
             "Identity_Mat2");
      Check (Approx (Mat2_Det (I2), 1.0), "det(I2)=1");
   end;

   declare
      V : constant Vec2 := Mat2_Mul_Vec (Identity_Mat2, [3.0, 4.0]);
   begin
      Check (Approx (V (1), 3.0) and then Approx (V (2), 4.0),
             "Mat2_Mul_Vec I");
   end;

   for K in 1 .. 10 loop
      declare
         N : constant Positive := 3 + K;
         P : Point_Cloud_2D (1 .. N);
         Q : Point_Cloud_2D (1 .. N);
         Ang : constant Real := 0.35 * Real (K);
         C : constant Real := Math.Cos (Ang);
         S : constant Real := Math.Sin (Ang);
         R : Mat2;
         Tx : constant Real := Real (K);
         Ty : constant Real := -0.5 * Real (K);
      begin
         for I in 1 .. N loop
            P (I) := [5.0 * (Next_Unit - 0.5), 5.0 * (Next_Unit - 0.5)];
            Q (I) :=
              [C * P (I) (1) - S * P (I) (2) + Tx,
               S * P (I) (1) + C * P (I) (2) + Ty];
         end loop;
         R := Kabsch_Rotation_2D (P, Q);
         Check (Approx (Mat2_Det (R), 1.0, 1.0E-5),
                "2D rigid#" & Integer'Image (K) & " det=+1");
         Check
           (Approx (R (1, 1), C, 1.0E-5)
              and then Approx (R (1, 2), S, 1.0E-5)
              and then Approx (R (2, 1), -S, 1.0E-5)
              and then Approx (R (2, 2), C, 1.0E-5),
            "2D rigid#" & Integer'Image (K) & " R ~ R(-ang)");
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("13. Extra matrix / RMSD / API coverage");
   ---------------------------------------------------------------------
   declare
      P : constant Point_Cloud := Sample_Cloud;
      Q : constant Point_Cloud :=
        Translate_By (P, [1.0, 1.0, 1.0]);
   begin
      Check (Real (RMSD (P, Q)) > 0.0, "RMSD translated > 0");
      Check (Approx (Real (RMSD (P, Q)), Math.Sqrt (3.0), 1.0E-10),
             "RMSD pure shift = sqrt(3)");
   end;

   for K in 1 .. 5 loop
      declare
         A : Mat3 := Zero_Mat3;
         U, Vt : Mat3;
         S : Singular_Values;
      begin
         A (1, 1) := Real (K);
         A (2, 2) := Real (K) * 0.5;
         A (3, 3) := Real (K) * 0.25;
         A (1, 2) := 0.1 * Real (K);
         A (2, 1) := 0.1 * Real (K);
         SVD_3x3 (A, U, S, Vt);
         Check (Real (S (1)) >= Real (S (2)),
                "Extra SVD#" & Integer'Image (K) & " sorted");
         Check (Approx (abs (Mat3_Det (Mat3_Mul (U, Mat3_Transpose (U)))),
                        1.0, 1.0E-5),
                "Extra SVD#" & Integer'Image (K) & " U orth det");
      end;
   end loop;

   declare
      Angs : constant array (1 .. 8) of Real :=
        [0.0, 0.1, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0];
   begin
      for K in Angs'Range loop
         declare
            P : constant Point_Cloud := Sample_Cloud;
            R0 : constant Mat3 := Rotation_X (Angs (K));
            Q : constant Point_Cloud := Apply_Rotation (R0, P);
            R : constant Mat3 := Kabsch_Rotation (P, Q);
         begin
            Check
              (Near_Mat3 (Mat3_Mul (R, R0), Identity_Mat3, 1.0E-6),
               "RotX#" & Integer'Image (K) & " inverse");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("=================================");
   Put_Line ("PASS: " & Natural'Image (Pass_Count));
   Put_Line ("FAIL: " & Natural'Image (Fail_Count));
   Put_Line ("Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
