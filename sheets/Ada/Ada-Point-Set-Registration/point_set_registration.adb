--  Point_Set_Registration body — 2-D rigid Kabsch-style + ICP sketch.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Point_Set_Registration
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   procedure Require_Nonempty (N : Natural) is
   begin
      if N = 0 or else N > Max_Points then
         raise Invalid_Argument;
      end if;
   end Require_Nonempty;

   procedure Require_Paired (Ns, Nt : Natural) is
   begin
      Require_Nonempty (Ns);
      Require_Nonempty (Nt);
      if Ns /= Nt then
         raise Invalid_Argument;
      end if;
   end Require_Paired;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point (A, B : Point; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near_Point;

   function Dist2 (A, B : Point) return Real is
      Dx : constant Real := B.X - A.X;
      Dy : constant Real := B.Y - A.Y;
   begin
      return Dx * Dx + Dy * Dy;
   end Dist2;

   function Dist (A, B : Point) return Real is
   begin
      return Real (Math.Sqrt (Long_Float (Dist2 (A, B))));
   end Dist;

   ---------------------------------------------------------------------------
   -- Matrix / transform helpers
   ---------------------------------------------------------------------------

   function Rotation_Of (Angle : Real) return Mat2 is
      C : constant Real := Real (Math.Cos (Long_Float (Angle)));
      S : constant Real := Real (Math.Sin (Long_Float (Angle)));
   begin
      return [1 => [C, -S],
              2 => [S,  C]];
   end Rotation_Of;

   function Mat2_Vec (M : Mat2; P : Point) return Point is
   begin
      return (X => M (1, 1) * P.X + M (1, 2) * P.Y,
              Y => M (2, 1) * P.X + M (2, 2) * P.Y);
   end Mat2_Vec;

   function Identity_Transform return Rigid_Transform is
   begin
      return (Angle       => 0.0,
              Translation => (X => 0.0, Y => 0.0),
              Rotation    => [1 => [1.0, 0.0],
                              2 => [0.0, 1.0]]);
   end Identity_Transform;

   function Make_Transform (Angle : Real; Translation : Point)
     return Rigid_Transform
   is
      R : constant Mat2 := Rotation_Of (Angle);
   begin
      return (Angle => Angle, Translation => Translation, Rotation => R);
   end Make_Transform;

   function Apply_Transform
     (T : Rigid_Transform; P : Point) return Point
   is
      Q : constant Point := Mat2_Vec (T.Rotation, P);
   begin
      return (X => Q.X + T.Translation.X, Y => Q.Y + T.Translation.Y);
   end Apply_Transform;

   function Apply_Transform
     (T : Rigid_Transform; Cloud : Point_Array) return Point_Array
   is
      Result : Point_Array (Cloud'Range);
   begin
      Require_Nonempty (Cloud'Length);
      for I in Cloud'Range loop
         Result (I) := Apply_Transform (T, Cloud (I));
      end loop;
      return Result;
   end Apply_Transform;

   ---------------------------------------------------------------------------
   -- Centroid
   ---------------------------------------------------------------------------

   function Centroid (Cloud : Point_Array) return Point is
      Sx, Sy : Real := 0.0;
      N      : Real;
   begin
      Require_Nonempty (Cloud'Length);
      for I in Cloud'Range loop
         Sx := Sx + Cloud (I).X;
         Sy := Sy + Cloud (I).Y;
      end loop;
      N := Real (Cloud'Length);
      return (X => Sx / N, Y => Sy / N);
   end Centroid;

   ---------------------------------------------------------------------------
   -- Residuals
   ---------------------------------------------------------------------------

   function Sum_Squared_Error
     (Source, Target : Point_Array) return Real
   is
      SSE : Real := 0.0;
      J   : Point_Index;
   begin
      Require_Paired (Source'Length, Target'Length);
      J := Target'First;
      for I in Source'Range loop
         SSE := SSE + Dist2 (Source (I), Target (J));
         if J < Target'Last then
            J := J + 1;
         end if;
      end loop;
      return SSE;
   end Sum_Squared_Error;

   function RMSE (Source, Target : Point_Array) return Real is
      SSE : constant Real := Sum_Squared_Error (Source, Target);
      N   : constant Real := Real (Source'Length);
   begin
      return Real (Math.Sqrt (Long_Float (SSE / N)));
   end RMSE;

   function Sum_Squared_Error
     (Source, Target : Point_Array; T : Rigid_Transform) return Real
   is
      SSE : Real := 0.0;
      J   : Point_Index;
      Q   : Point;
   begin
      Require_Paired (Source'Length, Target'Length);
      J := Target'First;
      for I in Source'Range loop
         Q := Apply_Transform (T, Source (I));
         SSE := SSE + Dist2 (Q, Target (J));
         if J < Target'Last then
            J := J + 1;
         end if;
      end loop;
      return SSE;
   end Sum_Squared_Error;

   function RMSE
     (Source, Target : Point_Array; T : Rigid_Transform) return Real
   is
      SSE : constant Real := Sum_Squared_Error (Source, Target, T);
      N   : constant Real := Real (Source'Length);
   begin
      return Real (Math.Sqrt (Long_Float (SSE / N)));
   end RMSE;

   ---------------------------------------------------------------------------
   -- Known-correspondence Kabsch-style 2-D closed form
   ---------------------------------------------------------------------------

   function Register_Correspondences
     (Source, Target : Point_Array) return Registration_Result
   is
      Mu_S, Mu_T : Point;
      Dot_Sum    : Real := 0.0;
      Cross_Sum  : Real := 0.0;
      Theta      : Real;
      Trans      : Point;
      Rmat       : Mat2;
      Rotated_Mu : Point;
      Res        : Registration_Result;
      Js         : Point_Index;
      Jt         : Point_Index;
      Sx, Sy     : Real;
      Tx, Ty     : Real;
   begin
      Require_Paired (Source'Length, Target'Length);

      Mu_S := Centroid (Source);
      Mu_T := Centroid (Target);

      Js := Source'First;
      Jt := Target'First;
      for K in 1 .. Source'Length loop
         Sx := Source (Js).X - Mu_S.X;
         Sy := Source (Js).Y - Mu_S.Y;
         Tx := Target (Jt).X - Mu_T.X;
         Ty := Target (Jt).Y - Mu_T.Y;
         Dot_Sum   := Dot_Sum   + Sx * Tx + Sy * Ty;
         Cross_Sum := Cross_Sum + Sx * Ty - Sy * Tx;
         if Js < Source'Last then
            Js := Js + 1;
         end if;
         if Jt < Target'Last then
            Jt := Jt + 1;
         end if;
      end loop;

      --  Degenerate centered clouds (e.g. single repeated point): identity angle.
      if abs (Dot_Sum) <= Epsilon and then abs (Cross_Sum) <= Epsilon then
         Theta := 0.0;
      else
         Theta := Real (Math.Arctan (Long_Float (Cross_Sum),
                                     Long_Float (Dot_Sum)));
      end if;
      Rmat  := Rotation_Of (Theta);
      Rotated_Mu := Mat2_Vec (Rmat, Mu_S);
      Trans := (X => Mu_T.X - Rotated_Mu.X, Y => Mu_T.Y - Rotated_Mu.Y);

      Res.Transform :=
        (Angle => Theta, Translation => Trans, Rotation => Rmat);
      Res.N        := Source'Length;
      Res.Iters    := 0;
      Res.Residual := Sum_Squared_Error (Source, Target, Res.Transform);
      Res.RMSE     :=
        Real (Math.Sqrt (Long_Float (Res.Residual / Real (Source'Length))));
      return Res;
   end Register_Correspondences;

   ---------------------------------------------------------------------------
   -- Nearest neighbour
   ---------------------------------------------------------------------------

   function Nearest_Index
     (Query : Point; Cloud : Point_Array) return Point_Index
   is
      Best_I : Point_Index := Cloud'First;
      Best_D : Real;
      D      : Real;
   begin
      Require_Nonempty (Cloud'Length);
      Best_D := Dist2 (Query, Cloud (Cloud'First));
      for I in Cloud'Range loop
         D := Dist2 (Query, Cloud (I));
         if D < Best_D then
            Best_D := D;
            Best_I := I;
         end if;
      end loop;
      return Best_I;
   end Nearest_Index;

   ---------------------------------------------------------------------------
   -- Compose rigid transforms: T2 ∘ T1  (apply T1 first, then T2)
   ---------------------------------------------------------------------------

   function Compose (T2, T1 : Rigid_Transform) return Rigid_Transform is
      --  R = R2 R1;  t = R2 t1 + t2;  angle = θ2 + θ1 (mod not needed educ.)
      Angle : constant Real := T2.Angle + T1.Angle;
      R     : constant Mat2 := Rotation_Of (Angle);
      Rt1   : constant Point := Mat2_Vec (T2.Rotation, T1.Translation);
      Trans : constant Point :=
        (X => Rt1.X + T2.Translation.X, Y => Rt1.Y + T2.Translation.Y);
   begin
      return (Angle => Angle, Translation => Trans, Rotation => R);
   end Compose;

   ---------------------------------------------------------------------------
   -- ICP
   ---------------------------------------------------------------------------

   function Register_ICP
     (Source, Target : Point_Array;
      Max_Steps      : Positive := 8;
      Tol            : Real := 1.0E-6) return Registration_Result
   is
      --  Working buffers sized to Max_Points; use dense 1 .. N_Src.
      N_Src : constant Point_Count := Source'Length;
      N_Tgt : constant Point_Count := Target'Length;

      Src_Work : Point_Array (1 .. Max_Points);
      Tgt_Corr : Point_Array (1 .. Max_Points);
      Src_Pair : Point_Array (1 .. Max_Points);

      Total    : Rigid_Transform := Identity_Transform;
      Step     : Rigid_Transform;
      Fit      : Registration_Result;
      Prev_RMSE : Real := Real'Last;
      Cur_RMSE  : Real;
      Res       : Registration_Result;
      Nn        : Point_Index;
      Si        : Point_Index;
   begin
      Require_Nonempty (N_Src);
      Require_Nonempty (N_Tgt);
      if Max_Steps > Max_Iters then
         raise Invalid_Argument;
      end if;

      --  Dense copy of source (identity pose initially).
      Si := Source'First;
      for I in 1 .. N_Src loop
         Src_Work (I) := Source (Si);
         if Si < Source'Last then
            Si := Si + 1;
         end if;
      end loop;

      --  Educational ICP warm-start: translate so centroids coincide.
      --  Without this, large pure translations often get wrong nearest
      --  neighbours from the identity pose (classic ICP pitfall).
      declare
         Mu_S : constant Point := Centroid (Src_Work (1 .. N_Src));
         Mu_T : constant Point := Centroid (Target);
         Init : Rigid_Transform;
      begin
         Init := Make_Transform
           (0.0, (X => Mu_T.X - Mu_S.X, Y => Mu_T.Y - Mu_S.Y));
         for I in 1 .. N_Src loop
            Src_Work (I) := Apply_Transform (Init, Src_Work (I));
         end loop;
         Total := Init;
      end;

      Res.Iters := 0;
      for K in 1 .. Max_Steps loop
         --  Nearest-neighbour correspondences in Target for each Src_Work.
         for I in 1 .. N_Src loop
            Nn := Nearest_Index (Src_Work (I), Target);
            Src_Pair (I) := Src_Work (I);
            Tgt_Corr (I) := Target (Nn);
         end loop;

         Fit := Register_Correspondences
           (Src_Pair (1 .. N_Src), Tgt_Corr (1 .. N_Src));
         Step := Fit.Transform;

         --  Apply incremental transform to working source.
         for I in 1 .. N_Src loop
            Src_Work (I) := Apply_Transform (Step, Src_Work (I));
         end loop;

         Total := Compose (Step, Total);
         Res.Iters := K;

         --  RMSE of current working source vs its NN targets.
         Cur_RMSE := Fit.RMSE;
         if Prev_RMSE - Cur_RMSE < Tol then
            exit;
         end if;
         Prev_RMSE := Cur_RMSE;
      end loop;

      --  Final residuals: apply Total to original Source vs NN in Target.
      declare
         SSE : Real := 0.0;
         Q   : Point;
         Si2 : Point_Index := Source'First;
      begin
         for I in 1 .. N_Src loop
            Q := Apply_Transform (Total, Source (Si2));
            Nn := Nearest_Index (Q, Target);
            SSE := SSE + Dist2 (Q, Target (Nn));
            if Si2 < Source'Last then
               Si2 := Si2 + 1;
            end if;
         end loop;
         Res.Transform := Total;
         Res.N         := N_Src;
         Res.Residual  := SSE;
         Res.RMSE      :=
           Real (Math.Sqrt (Long_Float (SSE / Real (N_Src))));
      end;
      return Res;
   end Register_ICP;

end Point_Set_Registration;
