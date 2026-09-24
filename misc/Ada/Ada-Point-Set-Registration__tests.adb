--  Standalone test suite for Point_Set_Registration (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Text_IO;
with Point_Set_Registration; use Point_Set_Registration;

procedure Tests is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
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

   --  Non-static views (avoid -gnatwc constant-condition warnings).
   function R (X : Real) return Real is (X);
   function Pos (X : Positive) return Positive is (X);
   function P (X, Y : Real) return Point is ((X => X, Y => Y));

   Pi : constant Real := Real (Ada.Numerics.Pi);

   function Raised_Invalid_Centroid (Cloud : Point_Array) return Boolean is
      C : Point;
   begin
      C := Centroid (Cloud);
      pragma Unreferenced (C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Centroid;

   function Raised_Invalid_RMSE
     (A, B : Point_Array) return Boolean
   is
      E : Real;
   begin
      E := RMSE (A, B);
      pragma Unreferenced (E);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_RMSE;

   function Raised_Invalid_Register
     (A, B : Point_Array) return Boolean
   is
      Res : Registration_Result;
   begin
      Res := Register_Correspondences (A, B);
      pragma Unreferenced (Res);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Register;

   function Raised_Invalid_ICP
     (A, B : Point_Array; Steps : Positive) return Boolean
   is
      Res : Registration_Result;
   begin
      Res := Register_ICP (A, B, Max_Steps => Steps);
      pragma Unreferenced (Res);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_ICP;

   function Raised_Invalid_NN (Cloud : Point_Array) return Boolean is
      I : Point_Index;
   begin
      I := Nearest_Index (P (0.0, 0.0), Cloud);
      pragma Unreferenced (I);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_NN;

   function Raised_Invalid_Apply (Cloud : Point_Array) return Boolean is
      Out_C : Point_Array (Cloud'Range);
      T     : constant Rigid_Transform := Identity_Transform;
   begin
      Out_C := Apply_Transform (T, Cloud);
      pragma Unreferenced (Out_C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Apply;

begin
   Ada.Text_IO.Put_Line ("Point_Set_Registration tests");
   Ada.Text_IO.Put_Line ("============================");

   ------------------------------------------------------------------
   Section ("1. Near / Near_Point / Dist");
   ------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0)), "Near equal");
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near within eps");
   Check (not Near (R (0.0), R (1.0)), "not Near 0,1");
   Check (Near_Point (P (0.0, 0.0), P (0.0, 0.0)), "Near_Point identical");
   Check (not Near_Point (P (0.0, 0.0), P (1.0, 0.0)), "not Near_Point");
   Check (Near (R (2.0), R (2.0), R (0.0)), "Near exact Tol=0");
   Check (not Near (R (2.0), R (2.1), R (0.05)), "not Near outside Tol");
   Check (Near (Dist2 (P (0.0, 0.0), P (3.0, 4.0)), R (25.0)),
          "Dist2 3-4-5 = 25");
   Check (Near (Dist (P (0.0, 0.0), P (3.0, 4.0)), R (5.0)),
          "Dist 3-4-5 = 5");
   Check (Near (Dist2 (P (1.0, 1.0), P (1.0, 1.0)), R (0.0)),
          "Dist2 identical = 0");

   ------------------------------------------------------------------
   Section ("2. Centroid");
   ------------------------------------------------------------------
   declare
      Cloud : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 2.0), P (0.0, 2.0)];
      C     : Point;
      Empty : Point_Array (1 .. 0);
   begin
      C := Centroid (Cloud);
      Check (Near_Point (C, P (1.0, 1.0)), "square centroid (1,1)");
      Check (Near_Point (Centroid ([P (1.0, 2.0)]), P (1.0, 2.0)),
             "singleton centroid");
      Check (Near_Point
               (Centroid ([P (-1.0, 0.0), P (1.0, 0.0), P (0.0, 2.0)]),
                P (0.0, Real (2.0) / R (3.0)), R (1.0E-9)),
             "triangle centroid");
      Check (Raised_Invalid_Centroid (Empty), "empty Centroid raises");
   end;

   ------------------------------------------------------------------
   Section ("3. Identity / Make_Transform / Apply");
   ------------------------------------------------------------------
   declare
      Id  : constant Rigid_Transform := Identity_Transform;
      T90 : constant Rigid_Transform :=
        Make_Transform (Pi / R (2.0), P (1.0, 0.0));
      Q   : Point;
      Cloud : constant Point_Array := [P (1.0, 0.0), P (0.0, 1.0)];
      Out_C : Point_Array (Cloud'Range);
   begin
      Check (Near (Id.Angle, R (0.0)), "Identity angle 0");
      Check (Near_Point (Id.Translation, P (0.0, 0.0)), "Identity T=0");
      Check (Near (Id.Rotation (1, 1), R (1.0)), "Identity R11=1");
      Check (Near (Id.Rotation (1, 2), R (0.0)), "Identity R12=0");
      Q := Apply_Transform (Id, P (3.0, 4.0));
      Check (Near_Point (Q, P (3.0, 4.0)), "Identity leaves point");
      Q := Apply_Transform (T90, P (1.0, 0.0));
      --  R90*(1,0)=(0,1) then + (1,0) => (1,1)
      Check (Near_Point (Q, P (1.0, 1.0), R (1.0E-9)),
             "90°+trans maps (1,0)->(1,1)");
      Out_C := Apply_Transform (Id, Cloud);
      Check (Near_Point (Out_C (1), Cloud (1)), "Apply cloud Id[1]");
      Check (Near_Point (Out_C (2), Cloud (2)), "Apply cloud Id[2]");
      declare
         Empty : Point_Array (1 .. 0);
      begin
         Check (Raised_Invalid_Apply (Empty), "Apply empty raises");
      end;
   end;

   ------------------------------------------------------------------
   Section ("4. Rotation_Of / Mat2_Vec");
   ------------------------------------------------------------------
   declare
      R0  : constant Mat2 := Rotation_Of (R (0.0));
      R180 : constant Mat2 := Rotation_Of (Pi);
      V   : Point;
   begin
      Check (Near (R0 (1, 1), R (1.0)), "R(0) cos=1");
      Check (Near (R0 (2, 1), R (0.0)), "R(0) sin=0");
      V := Mat2_Vec (R180, P (1.0, 0.0));
      Check (Near_Point (V, P (-1.0, 0.0), R (1.0E-9)),
             "R(π)*(1,0)=(-1,0)");
      V := Mat2_Vec (Rotation_Of (Pi / R (2.0)), P (1.0, 0.0));
      Check (Near_Point (V, P (0.0, 1.0), R (1.0E-9)),
             "R(π/2)*(1,0)=(0,1)");
      V := Mat2_Vec (Rotation_Of (-Pi / R (2.0)), P (1.0, 0.0));
      Check (Near_Point (V, P (0.0, -1.0), R (1.0E-9)),
             "R(-π/2)*(1,0)=(0,-1)");
   end;

   ------------------------------------------------------------------
   Section ("5. RMSE / SSE identity pairing");
   ------------------------------------------------------------------
   declare
      A : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)];
      B : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)];
      C : constant Point_Array :=
        [P (1.0, 0.0), P (2.0, 0.0), P (1.0, 1.0)];
      Id : constant Rigid_Transform := Identity_Transform;
   begin
      Check (Near (Sum_Squared_Error (A, B), R (0.0)), "SSE identical=0");
      Check (Near (RMSE (A, B), R (0.0)), "RMSE identical=0");
      Check (Near (Sum_Squared_Error (A, C), R (3.0)),
             "SSE translate-by-1 = 3");
      Check (Near (RMSE (A, C), R (1.0)), "RMSE translate-by-1 = 1");
      Check (Near (Sum_Squared_Error (A, B, Id), R (0.0)),
             "SSE with Id = 0");
      Check (Near (RMSE (A, B, Id), R (0.0)), "RMSE with Id = 0");
      Check (Raised_Invalid_RMSE (A, [P (0.0, 0.0)]),
             "RMSE length mismatch raises");
      declare
         Empty : Point_Array (1 .. 0);
      begin
         Check (Raised_Invalid_RMSE (Empty, Empty),
                "RMSE empty raises");
      end;
   end;

   ------------------------------------------------------------------
   Section ("6. Register_Correspondences: pure translation");
   ------------------------------------------------------------------
   declare
      Src : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0), P (1.0, 1.0)];
      Tgt : Point_Array (Src'Range);
      Res : Registration_Result;
      Q   : Point;
   begin
      for I in Src'Range loop
         Tgt (I) := P (Src (I).X + R (3.0), Src (I).Y + R (4.0));
      end loop;
      Res := Register_Correspondences (Src, Tgt);
      Check (Near (Res.Transform.Angle, R (0.0), R (1.0E-8)),
             "pure translation angle≈0");
      Check (Near_Point (Res.Transform.Translation, P (3.0, 4.0), R (1.0E-8)),
             "pure translation T=(3,4)");
      Check (Near (Res.RMSE, R (0.0), R (1.0E-8)),
             "pure translation RMSE≈0");
      Check (Res.N = 4, "pure translation N=4");
      Q := Apply_Transform (Res.Transform, Src (1));
      Check (Near_Point (Q, Tgt (1), R (1.0E-8)),
             "pure translation maps Src1");
   end;

   ------------------------------------------------------------------
   Section ("7. Register_Correspondences: pure rotation");
   ------------------------------------------------------------------
   declare
      Src : constant Point_Array :=
        [P (1.0, 0.0), P (0.0, 1.0), P (-1.0, 0.0), P (0.0, -1.0)];
      Ang : constant Real := Pi / R (4.0);  --  45°
      T_Known : constant Rigid_Transform :=
        Make_Transform (Ang, P (0.0, 0.0));
      Tgt : Point_Array (Src'Range);
      Res : Registration_Result;
   begin
      for I in Src'Range loop
         Tgt (I) := Apply_Transform (T_Known, Src (I));
      end loop;
      Res := Register_Correspondences (Src, Tgt);
      Check (Near (Res.Transform.Angle, Ang, R (1.0E-7)),
             "pure rotation recovers π/4");
      Check (Near_Point (Res.Transform.Translation, P (0.0, 0.0), R (1.0E-7)),
             "pure rotation T≈0");
      Check (Near (Res.RMSE, R (0.0), R (1.0E-7)),
             "pure rotation RMSE≈0");
      Check (Near_Point
               (Apply_Transform (Res.Transform, Src (1)), Tgt (1), R (1.0E-7)),
             "pure rotation maps Src1");
   end;

   ------------------------------------------------------------------
   Section ("8. Register_Correspondences: rotation + translation");
   ------------------------------------------------------------------
   declare
      Src : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 1.0),
         P (0.0, 1.0), P (1.0, 0.5)];
      Ang : constant Real := Pi / R (6.0);  --  30°
      T_Known : constant Rigid_Transform :=
        Make_Transform (Ang, P (5.0, -2.0));
      Tgt : Point_Array (Src'Range);
      Res : Registration_Result;
      Ok_All : Boolean := True;
   begin
      for I in Src'Range loop
         Tgt (I) := Apply_Transform (T_Known, Src (I));
      end loop;
      Res := Register_Correspondences (Src, Tgt);
      Check (Near (Res.Transform.Angle, Ang, R (1.0E-7)),
             "rigid 30° recovers angle");
      Check (Near_Point
               (Res.Transform.Translation, P (5.0, -2.0), R (1.0E-6)),
             "rigid recovers translation");
      Check (Near (Res.RMSE, R (0.0), R (1.0E-7)),
             "rigid RMSE≈0");
      for I in Src'Range loop
         if not Near_Point
           (Apply_Transform (Res.Transform, Src (I)), Tgt (I), R (1.0E-6))
         then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "rigid maps every source point");
      Check (Res.N = 5, "rigid N=5");
   end;

   ------------------------------------------------------------------
   Section ("9. Register_Correspondences: 180° and negative angle");
   ------------------------------------------------------------------
   declare
      Src : constant Point_Array :=
        [P (1.0, 2.0), P (3.0, 4.0), P (-1.0, 0.5)];
      Tgt : Point_Array (Src'Range);
      Res : Registration_Result;
      Tk  : Rigid_Transform;
   begin
      Tk := Make_Transform (Pi, P (0.5, 0.5));
      for I in Src'Range loop
         Tgt (I) := Apply_Transform (Tk, Src (I));
      end loop;
      Res := Register_Correspondences (Src, Tgt);
      Check (Near (abs (Res.Transform.Angle), Pi, R (1.0E-6)),
             "180° |angle|≈π");
      Check (Near (Res.RMSE, R (0.0), R (1.0E-6)), "180° RMSE≈0");

      Tk := Make_Transform (-Pi / R (3.0), P (-1.0, 2.0));
      for I in Src'Range loop
         Tgt (I) := Apply_Transform (Tk, Src (I));
      end loop;
      Res := Register_Correspondences (Src, Tgt);
      Check (Near (Res.Transform.Angle, -Pi / R (3.0), R (1.0E-6)),
             "negative −π/3 recovered");
      Check (Near (Res.RMSE, R (0.0), R (1.0E-6)), "−π/3 RMSE≈0");
   end;

   ------------------------------------------------------------------
   Section ("10. Register_Correspondences: already aligned");
   ------------------------------------------------------------------
   declare
      Src : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 1.0), P (2.0, 0.0)];
      Res : Registration_Result;
   begin
      Res := Register_Correspondences (Src, Src);
      Check (Near (Res.Transform.Angle, R (0.0), R (1.0E-9)),
             "aligned angle≈0");
      Check (Near_Point
               (Res.Transform.Translation, P (0.0, 0.0), R (1.0E-9)),
             "aligned T≈0");
      Check (Near (Res.RMSE, R (0.0), R (1.0E-9)), "aligned RMSE≈0");
   end;

   ------------------------------------------------------------------
   Section ("11. Register_Correspondences: invalid args");
   ------------------------------------------------------------------
   declare
      A : constant Point_Array := [P (0.0, 0.0), P (1.0, 0.0)];
      B : constant Point_Array := [P (0.0, 0.0)];
      Empty : Point_Array (1 .. 0);
   begin
      Check (Raised_Invalid_Register (A, B), "length mismatch raises");
      Check (Raised_Invalid_Register (Empty, Empty), "empty register raises");
      Check (Raised_Invalid_Register (A, Empty), "src vs empty raises");
   end;

   ------------------------------------------------------------------
   Section ("12. Nearest_Index");
   ------------------------------------------------------------------
   declare
      Cloud : constant Point_Array :=
        [P (0.0, 0.0), P (5.0, 0.0), P (0.0, 5.0), P (5.0, 5.0)];
      Empty : Point_Array (1 .. 0);
   begin
      Check (Nearest_Index (P (0.1, 0.1), Cloud) = Cloud'First,
             "NN near origin -> 1");
      Check (Nearest_Index (P (4.9, 0.1), Cloud) = 2,
             "NN near (5,0) -> 2");
      Check (Nearest_Index (P (0.1, 4.9), Cloud) = 3,
             "NN near (0,5) -> 3");
      Check (Nearest_Index (P (4.8, 4.8), Cloud) = 4,
             "NN near (5,5) -> 4");
      Check (Nearest_Index (P (5.0, 0.0), Cloud) = 2,
             "NN exact (5,0) -> 2");
      Check (Raised_Invalid_NN (Empty), "NN empty raises");
   end;

   ------------------------------------------------------------------
   Section ("13. Register_ICP: identical clouds");
   ------------------------------------------------------------------
   declare
      Src : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      Res : Registration_Result;
   begin
      Res := Register_ICP (Src, Src, Max_Steps => 4);
      Check (Near (Res.RMSE, R (0.0), R (1.0E-6)),
             "ICP identical RMSE≈0");
      Check (Near (Res.Transform.Angle, R (0.0), R (1.0E-5)),
             "ICP identical angle≈0");
      Check (Res.Iters >= 1, "ICP identical ran ≥1 iter");
      Check (Res.N = 4, "ICP identical N=4");
   end;

   ------------------------------------------------------------------
   Section ("14. Register_ICP: small pose perturbation");
   ------------------------------------------------------------------
   declare
      Src : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 2.0),
         P (0.0, 2.0), P (1.0, 1.0)];
      --  Mild rotation + translation of a copy as scene.
      Perturb : constant Rigid_Transform :=
        Make_Transform (R (0.15), P (0.3, -0.2));
      Tgt : Point_Array (Src'Range);
      Res : Registration_Result;
      Mapped : Point;
      Ok : Boolean := True;
   begin
      for I in Src'Range loop
         Tgt (I) := Apply_Transform (Perturb, Src (I));
      end loop;
      --  Start ICP from identity: Source is the unperturbed model.
      Res := Register_ICP (Src, Tgt, Max_Steps => 10, Tol => R (1.0E-9));
      Check (Res.RMSE < R (0.05), "ICP small-perturb RMSE < 0.05");
      Check (Near (Res.Transform.Angle, R (0.15), R (0.05)),
             "ICP recovers angle ≈ 0.15");
      Check (Res.Iters >= 1, "ICP small-perturb ran");
      for I in Src'Range loop
         Mapped := Apply_Transform (Res.Transform, Src (I));
         if Dist (Mapped, Tgt (I)) > R (0.1) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "ICP maps sources near targets");
   end;

   ------------------------------------------------------------------
   Section ("15. Register_ICP: translation-only scene");
   ------------------------------------------------------------------
   declare
      Src : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.5, 1.0)];
      Tgt : Point_Array (Src'Range);
      Res : Registration_Result;
   begin
      for I in Src'Range loop
         Tgt (I) := P (Src (I).X + R (2.0), Src (I).Y + R (1.0));
      end loop;
      Res := Register_ICP (Src, Tgt, Max_Steps => 8);
      Check (Res.RMSE < R (1.0E-4), "ICP translate RMSE≈0");
      Check (Near_Point
               (Res.Transform.Translation, P (2.0, 1.0), R (1.0E-3)),
             "ICP translate T≈(2,1)");
      Check (Near (Res.Transform.Angle, R (0.0), R (1.0E-3)),
             "ICP translate angle≈0");
   end;

   ------------------------------------------------------------------
   Section ("16. Register_ICP: unequal lengths");
   ------------------------------------------------------------------
   declare
      --  Scene denser than model; ICP still assigns NN.
      Src : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)];
      Tgt : constant Point_Array :=
        [P (0.05, 0.0), P (1.05, 0.0), P (0.05, 1.0),
         P (0.5, 0.5), P (2.0, 2.0)];
      Res : Registration_Result;
   begin
      Res := Register_ICP (Src, Tgt, Max_Steps => 6);
      Check (Res.N = 3, "ICP unequal N=source length");
      Check (Res.RMSE < R (0.5), "ICP unequal RMSE finite/small");
      Check (Res.Iters >= 1, "ICP unequal ran");
   end;

   ------------------------------------------------------------------
   Section ("17. Register_ICP: invalid args");
   ------------------------------------------------------------------
   declare
      A : constant Point_Array := [P (0.0, 0.0), P (1.0, 0.0)];
      Empty : Point_Array (1 .. 0);
   begin
      Check (Raised_Invalid_ICP (Empty, A, 4), "ICP empty source raises");
      Check (Raised_Invalid_ICP (A, Empty, 4), "ICP empty target raises");
      Check (Raised_Invalid_ICP (A, A, Max_Iters + 1),
             "ICP Max_Steps>Max_Iters raises");
   end;

   ------------------------------------------------------------------
   Section ("18. Correspondence vs ICP agreement (exact pairs)");
   ------------------------------------------------------------------
   declare
      Src : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (3.0, 2.0), P (0.0, 2.0)];
      Tk  : constant Rigid_Transform :=
        Make_Transform (R (0.4), P (1.5, -0.7));
      Tgt : Point_Array (Src'Range);
      Rc  : Registration_Result;
      Ri  : Registration_Result;
   begin
      for I in Src'Range loop
         Tgt (I) := Apply_Transform (Tk, Src (I));
      end loop;
      Rc := Register_Correspondences (Src, Tgt);
      Ri := Register_ICP (Src, Tgt, Max_Steps => 12, Tol => R (1.0E-10));
      Check (Near (Rc.RMSE, R (0.0), R (1.0E-7)),
             "corr exact RMSE≈0");
      Check (Ri.RMSE < R (1.0E-3), "ICP on exact pairs RMSE small");
      Check (Near (Rc.Transform.Angle, Ri.Transform.Angle, R (0.05)),
             "corr vs ICP angle close");
      Check (Near_Point
               (Rc.Transform.Translation,
                Ri.Transform.Translation, R (0.1)),
             "corr vs ICP translation close");
   end;

   ------------------------------------------------------------------
   Section ("19. Residual helpers with recovered transform");
   ------------------------------------------------------------------
   declare
      Src : constant Point_Array :=
        [P (1.0, 1.0), P (2.0, 1.0), P (2.0, 3.0)];
      Tk  : constant Rigid_Transform :=
        Make_Transform (-Pi / R (2.0), P (0.0, 1.0));
      Tgt : Point_Array (Src'Range);
      Res : Registration_Result;
   begin
      for I in Src'Range loop
         Tgt (I) := Apply_Transform (Tk, Src (I));
      end loop;
      Res := Register_Correspondences (Src, Tgt);
      Check (Near (RMSE (Src, Tgt, Res.Transform), R (0.0), R (1.0E-7)),
             "RMSE(Src,Tgt,T)≈0");
      Check (Near
               (Sum_Squared_Error (Src, Tgt, Res.Transform),
                R (0.0), R (1.0E-7)),
             "SSE(Src,Tgt,T)≈0");
      Check (Near (Res.Residual, R (0.0), R (1.0E-7)),
             "Res.Residual≈0");
      Check (Near (Res.RMSE, Res.Residual, R (1.0E-9))
               or else Near (Res.RMSE,
                             Real (Math.Sqrt (Long_Float (Res.Residual
                               / Real (Src'Length)))),
                             R (1.0E-9)),
             "RMSE consistent with Residual/N");
   end;

   ------------------------------------------------------------------
   Section ("20. Capacity / Max_Points note");
   ------------------------------------------------------------------
   declare
      Cloud : Point_Array (1 .. 12);
      Ang   : Long_Float;
      Tgt   : Point_Array (1 .. 12);
      Res   : Registration_Result;
      Tk    : constant Rigid_Transform :=
        Make_Transform (R (0.25), P (0.1, 0.2));
   begin
      for I in Cloud'Range loop
         Ang := Long_Float (I - 1) * (2.0 * Ada.Numerics.Pi / 12.0);
         Cloud (I) := P (Real (Math.Cos (Ang)), Real (Math.Sin (Ang)));
         Tgt (I) := Apply_Transform (Tk, Cloud (I));
      end loop;
      Check (Cloud'Length <= Max_Points, "12-gon within Max_Points");
      Check (Pos (Max_Points) >= 12, "Max_Points >= 12");
      Check (Pos (Max_Iters) >= 8, "Max_Iters >= 8");
      Res := Register_Correspondences (Cloud, Tgt);
      Check (Near (Res.Transform.Angle, R (0.25), R (1.0E-6)),
             "12-gon corr recovers 0.25");
      Check (Near (Res.RMSE, R (0.0), R (1.0E-6)),
             "12-gon corr RMSE≈0");
      Res := Register_ICP (Cloud, Tgt, Max_Steps => 10);
      Check (Res.RMSE < R (0.01), "12-gon ICP RMSE < 0.01");
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result:" & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
