--  Difference_Map body — Elser difference map + toy projectors.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Difference_Map
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Elementary_Functions;

   function Sqrt_Real (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      end if;
      return Real (Math.Sqrt (Float (X)));
   end Sqrt_Real;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Default_Parameters
     (Beta     : Real        := 1.0;
      Max_Iter : Iter_Budget := 1_000;
      Tol      : Real        := 1.0E-8) return Parameters
   is
   begin
      if Beta = 0.0 then
         raise Invalid_Argument with "Beta must be nonzero";
      end if;
      if Tol < 0.0 then
         raise Invalid_Argument with "Tol must be nonnegative";
      end if;
      return (Beta => Beta, Max_Iter => Max_Iter, Tol => Tol);
   end Default_Parameters;

   function Copy_Into_Max (X : Vector) return Vector is
      R : Vector (1 .. Max_Dim) := [others => 0.0];
   begin
      for I in X'Range loop
         R (I - X'First + 1) := X (I);
      end loop;
      return R;
   end Copy_Into_Max;



   function Ensure_Aligned (X : Vector; Dim : Dimension) return Vector is
      R : Vector (1 .. Dim);
   begin
      if X'Length /= Natural (Dim) then
         raise Invalid_Argument with "vector dimension mismatch";
      end if;
      for I in 1 .. Dim loop
         R (I) := X (X'First + I - 1);
      end loop;
      return R;
   end Ensure_Aligned;

   ---------------------------------------------------------------------------
   -- Vector primitives
   ---------------------------------------------------------------------------

   function Norm2 (X : Vector) return Real is
      S : Real := 0.0;
   begin
      for V of X loop
         S := S + V * V;
      end loop;
      return Sqrt_Real (S);
   end Norm2;

   function Dot (X, Y : Vector) return Real is
      S : Real := 0.0;
      J : Positive := Y'First;
   begin
      if X'Length /= Y'Length then
         raise Invalid_Argument with "Dot: length mismatch";
      end if;
      for I in X'Range loop
         S := S + X (I) * Y (J);
         J := J + 1;
      end loop;
      return S;
   end Dot;

   function Add (X, Y : Vector) return Vector is
      R : Vector (X'Range);
      J : Positive := Y'First;
   begin
      if X'Length /= Y'Length then
         raise Invalid_Argument with "Add: length mismatch";
      end if;
      for I in X'Range loop
         R (I) := X (I) + Y (J);
         J := J + 1;
      end loop;
      return R;
   end Add;

   function Sub (X, Y : Vector) return Vector is
      R : Vector (X'Range);
      J : Positive := Y'First;
   begin
      if X'Length /= Y'Length then
         raise Invalid_Argument with "Sub: length mismatch";
      end if;
      for I in X'Range loop
         R (I) := X (I) - Y (J);
         J := J + 1;
      end loop;
      return R;
   end Sub;

   function Scale (Alpha : Real; X : Vector) return Vector is
      R : Vector (X'Range);
   begin
      for I in X'Range loop
         R (I) := Alpha * X (I);
      end loop;
      return R;
   end Scale;

   function Distance (X, Y : Vector) return Real is
   begin
      return Norm2 (Sub (X, Y));
   end Distance;

   ---------------------------------------------------------------------------
   -- Concrete projectors
   ---------------------------------------------------------------------------

   function Project_Box (X, Lo, Hi : Vector) return Vector is
      R : Vector (X'Range);
      J : Positive := Lo'First;
      K : Positive := Hi'First;
      V : Real;
   begin
      if X'Length /= Lo'Length or else X'Length /= Hi'Length then
         raise Invalid_Argument with "Project_Box: length mismatch";
      end if;
      for I in X'Range loop
         if Lo (J) > Hi (K) then
            raise Invalid_Argument with "Project_Box: Lo > Hi";
         end if;
         V := X (I);
         if V < Lo (J) then
            V := Lo (J);
         elsif V > Hi (K) then
            V := Hi (K);
         end if;
         R (I) := V;
         J := J + 1;
         K := K + 1;
      end loop;
      return R;
   end Project_Box;

   function Project_Ball
     (X : Vector; Radius : Real; Center : Vector) return Vector
   is
      Diff : Vector (X'Range);
      Dist : Real;
   begin
      if X'Length /= Center'Length then
         raise Invalid_Argument with "Project_Ball: length mismatch";
      end if;
      if Radius < 0.0 then
         raise Invalid_Argument with "Project_Ball: negative radius";
      end if;
      Diff := Sub (X, Center);
      Dist := Norm2 (Diff);
      if Dist <= Radius then
         return X;
      end if;
      --  Map to boundary: Center + (Radius / Dist) * (X − Center)
      return Add (Center, Scale (Radius / Dist, Diff));
   end Project_Ball;

   function Project_Sphere
     (X : Vector; Radius : Real; Center : Vector) return Vector
   is
      Diff : Vector (X'Range);
      Dist : Real;
      Unit : Vector (X'Range);
   begin
      if X'Length /= Center'Length then
         raise Invalid_Argument with "Project_Sphere: length mismatch";
      end if;
      if Radius <= 0.0 then
         raise Invalid_Argument with "Project_Sphere: radius must be > 0";
      end if;
      Diff := Sub (X, Center);
      Dist := Norm2 (Diff);
      if Dist = 0.0 then
         --  Arbitrary nearest point: Center + Radius * e_1
         Unit := [others => 0.0];
         Unit (Unit'First) := Radius;
         return Add (Center, Unit);
      end if;
      return Add (Center, Scale (Radius / Dist, Diff));
   end Project_Sphere;

   function Project_Orthant (X : Vector) return Vector is
      R : Vector (X'Range);
   begin
      for I in X'Range loop
         if X (I) < 0.0 then
            R (I) := 0.0;
         else
            R (I) := X (I);
         end if;
      end loop;
      return R;
   end Project_Orthant;

   function Project_Hyperplane
     (X : Vector; Normal : Vector; Offset : Real) return Vector
   is
      N2    : Real;
      Shift : Real;
   begin
      if X'Length /= Normal'Length then
         raise Invalid_Argument with "Project_Hyperplane: length mismatch";
      end if;
      N2 := Dot (Normal, Normal);
      if N2 = 0.0 then
         raise Invalid_Argument with "Project_Hyperplane: zero normal";
      end if;
      Shift := (Dot (Normal, X) - Offset) / N2;
      return Sub (X, Scale (Shift, Normal));
   end Project_Hyperplane;

   function Project (C : Constraint; X : Vector) return Vector is
      Xa : constant Vector := Ensure_Aligned (X, C.Dim);
      Lo, Hi, Cen, Nor : Vector (1 .. C.Dim);
   begin
      case C.Kind is
         when Box_Constraint =>
            for I in 1 .. C.Dim loop
               Lo (I) := C.Lo (I);
               Hi (I) := C.Hi (I);
            end loop;
            return Project_Box (Xa, Lo, Hi);
         when Ball_Constraint =>
            for I in 1 .. C.Dim loop
               Cen (I) := C.Center (I);
            end loop;
            return Project_Ball (Xa, C.Radius, Cen);
         when Sphere_Constraint =>
            for I in 1 .. C.Dim loop
               Cen (I) := C.Center (I);
            end loop;
            return Project_Sphere (Xa, C.Radius, Cen);
         when Orthant_Constraint =>
            return Project_Orthant (Xa);
         when Hyperplane_Constraint =>
            for I in 1 .. C.Dim loop
               Nor (I) := C.Normal (I);
            end loop;
            return Project_Hyperplane (Xa, Nor, C.Offset);
      end case;
   end Project;

   ---------------------------------------------------------------------------
   -- Elser difference map
   ---------------------------------------------------------------------------

   --  f_A(x) = P_A(x) − (1/β)(P_A(x) − x)
   --         = (1 − 1/β) P_A(x) + (1/β) x
   function F_A (X : Vector; A : Constraint; Beta : Real) return Vector is
      PA : constant Vector := Project (A, X);
   begin
      if Beta = 0.0 then
         raise Invalid_Argument with "F_A: Beta = 0";
      end if;
      return Sub (PA, Scale (1.0 / Beta, Sub (PA, X)));
   end F_A;

   --  f_B(x) = P_B(x) + (1/β)(P_B(x) − x)
   --         = (1 + 1/β) P_B(x) − (1/β) x
   function F_B (X : Vector; B : Constraint; Beta : Real) return Vector is
      PB : constant Vector := Project (B, X);
   begin
      if Beta = 0.0 then
         raise Invalid_Argument with "F_B: Beta = 0";
      end if;
      return Add (PB, Scale (1.0 / Beta, Sub (PB, X)));
   end F_B;

   function Difference_Map_Step
     (X : Vector; A, B : Constraint; Beta : Real) return Vector
   is
      FA, FB, PA_FB, PB_FA, Diff : Vector (X'Range);
   begin
      if A.Dim /= B.Dim or else X'Length /= Natural (A.Dim) then
         raise Invalid_Argument with "Difference_Map_Step: dim mismatch";
      end if;
      if Beta = 0.0 then
         raise Invalid_Argument with "Difference_Map_Step: Beta = 0";
      end if;

      --  Fast path β = 1: D(x) = x + P_A(2 P_B(x) − x) − P_B(x)
      if Near (Beta, 1.0, 0.0) then
         declare
            PB : constant Vector := Project (B, X);
            Y  : constant Vector := Sub (Scale (2.0, PB), X);
            PA : constant Vector := Project (A, Y);
         begin
            return Add (X, Sub (PA, PB));
         end;
      end if;

      FA := F_A (X, A, Beta);
      FB := F_B (X, B, Beta);
      PA_FB := Project (A, FB);
      PB_FA := Project (B, FA);
      Diff := Sub (PA_FB, PB_FA);
      return Add (X, Scale (Beta, Diff));
   end Difference_Map_Step;

   function Residual
     (X : Vector; A, B : Constraint; Beta : Real) return Real
   is
      FA, FB, PA_FB, PB_FA : Vector (X'Range);
   begin
      if Beta = 0.0 then
         raise Invalid_Argument with "Residual: Beta = 0";
      end if;
      FA := F_A (X, A, Beta);
      FB := F_B (X, B, Beta);
      PA_FB := Project (A, FB);
      PB_FA := Project (B, FA);
      return Distance (PA_FB, PB_FA);
   end Residual;

   function Is_Near_Feasible
     (X : Vector; A, B : Constraint; Beta : Real; Tol : Real) return Boolean
   is
   begin
      return Residual (X, A, B, Beta) <= Tol;
   end Is_Near_Feasible;

   function Feasible_Candidate
     (X : Vector; A, B : Constraint; Beta : Real) return Vector
   is
   begin
      return Project (A, F_B (X, B, Beta));
   end Feasible_Candidate;

   function Fill_Result
     (X_Cur : Vector;
      A, B  : Constraint;
      Beta  : Real;
      Tol   : Real;
      Iters : Natural) return Result
   is
      R   : Result;
      Res : constant Real := Residual (X_Cur, A, B, Beta);
      Fpt : constant Vector := Feasible_Candidate (X_Cur, A, B, Beta);
   begin
      R.Dim := A.Dim;
      R.Iterations := Iters;
      R.Residual := Res;
      R.Converged := Res <= Tol;
      R.Near_Feasible := R.Converged;
      R.X := Copy_Into_Max (X_Cur);
      R.Feasible := Copy_Into_Max (Fpt);
      return R;
   end Fill_Result;

   function Iterate_Difference_Map
     (X0 : Vector; A, B : Constraint; Params : Parameters) return Result
   is
      X : Vector (1 .. A.Dim) := Ensure_Aligned (X0, A.Dim);
   begin
      if A.Dim /= B.Dim then
         raise Invalid_Argument with "Iterate_Difference_Map: A/B dim";
      end if;
      if Params.Beta = 0.0 then
         raise Invalid_Argument with "Iterate_Difference_Map: Beta = 0";
      end if;

      if Params.Max_Iter = 0 then
         return Fill_Result (X, A, B, Params.Beta, Params.Tol, 0);
      end if;

      for K in 1 .. Params.Max_Iter loop
         if Residual (X, A, B, Params.Beta) <= Params.Tol then
            return Fill_Result (X, A, B, Params.Beta, Params.Tol, K - 1);
         end if;
         X := Difference_Map_Step (X, A, B, Params.Beta);
         if Residual (X, A, B, Params.Beta) <= Params.Tol then
            return Fill_Result (X, A, B, Params.Beta, Params.Tol, K);
         end if;
      end loop;
      return Fill_Result (X, A, B, Params.Beta, Params.Tol, Params.Max_Iter);
   end Iterate_Difference_Map;

   ---------------------------------------------------------------------------
   -- Related maps
   ---------------------------------------------------------------------------

   function Alternating_Projections_Step
     (X : Vector; A, B : Constraint) return Vector
   is
   begin
      return Project (A, Project (B, X));
   end Alternating_Projections_Step;

   function Gap_PA_PB (X : Vector; A, B : Constraint) return Real is
   begin
      return Distance (Project (A, X), Project (B, X));
   end Gap_PA_PB;

   function Alternating_Projections
     (X0 : Vector; A, B : Constraint; Params : Parameters) return Result
   is
      X : Vector (1 .. A.Dim) := Ensure_Aligned (X0, A.Dim);
      R : Result;
      G : Real;
   begin
      if A.Dim /= B.Dim then
         raise Invalid_Argument with "Alternating_Projections: A/B dim";
      end if;

      for K in 0 .. Params.Max_Iter loop
         G := Gap_PA_PB (X, A, B);
         if G <= Params.Tol then
            R.Dim := A.Dim;
            R.Iterations := K;
            R.Residual := G;
            R.Converged := True;
            R.Near_Feasible := True;
            R.X := Copy_Into_Max (X);
            R.Feasible := Copy_Into_Max (Project (A, X));
            return R;
         end if;
         exit when K = Params.Max_Iter;
         X := Alternating_Projections_Step (X, A, B);
      end loop;

      G := Gap_PA_PB (X, A, B);
      R.Dim := A.Dim;
      R.Iterations := Params.Max_Iter;
      R.Residual := G;
      R.Converged := G <= Params.Tol;
      R.Near_Feasible := R.Converged;
      R.X := Copy_Into_Max (X);
      R.Feasible := Copy_Into_Max (Project (A, X));
      return R;
   end Alternating_Projections;

   function Reflect (C : Constraint; X : Vector) return Vector is
      P : constant Vector := Project (C, X);
   begin
      return Sub (Scale (2.0, P), X);
   end Reflect;

   function Douglas_Rachford_Step
     (X : Vector; A, B : Constraint) return Vector
   is
      RB : constant Vector := Reflect (B, X);
      RA : constant Vector := Reflect (A, RB);
   begin
      return Scale (0.5, Add (X, RA));
   end Douglas_Rachford_Step;

   function Iterate_Douglas_Rachford
     (X0 : Vector; A, B : Constraint; Params : Parameters) return Result
   is
      X : Vector (1 .. A.Dim) := Ensure_Aligned (X0, A.Dim);
      R : Result;
      G : Real;
      --  Feasibility monitor: ||P_A(x) − P_B(x)|| (standard for DR shadow)
      Shadow : Vector (1 .. A.Dim);
   begin
      if A.Dim /= B.Dim then
         raise Invalid_Argument with "Iterate_Douglas_Rachford: A/B dim";
      end if;

      for K in 0 .. Params.Max_Iter loop
         Shadow := Project (B, X);
         G := Distance (Project (A, Shadow), Shadow);
         if G <= Params.Tol then
            R.Dim := A.Dim;
            R.Iterations := K;
            R.Residual := G;
            R.Converged := True;
            R.Near_Feasible := True;
            R.X := Copy_Into_Max (X);
            R.Feasible := Copy_Into_Max (Shadow);
            return R;
         end if;
         exit when K = Params.Max_Iter;
         X := Douglas_Rachford_Step (X, A, B);
      end loop;

      Shadow := Project (B, X);
      G := Distance (Project (A, Shadow), Shadow);
      R.Dim := A.Dim;
      R.Iterations := Params.Max_Iter;
      R.Residual := G;
      R.Converged := G <= Params.Tol;
      R.Near_Feasible := R.Converged;
      R.X := Copy_Into_Max (X);
      R.Feasible := Copy_Into_Max (Shadow);
      return R;
   end Iterate_Douglas_Rachford;

   function Averaged_Projections_Step
     (X : Vector; A, B : Constraint) return Vector
   is
   begin
      return Scale (0.5, Add (Project (A, X), Project (B, X)));
   end Averaged_Projections_Step;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Make_Box
     (Dim : Dimension; Lo_Val, Hi_Val : Real) return Constraint
   is
      C : Constraint;
   begin
      if Lo_Val > Hi_Val then
         raise Invalid_Argument with "Make_Box: Lo > Hi";
      end if;
      C.Kind := Box_Constraint;
      C.Dim := Dim;
      for I in 1 .. Dim loop
         C.Lo (I) := Lo_Val;
         C.Hi (I) := Hi_Val;
      end loop;
      return C;
   end Make_Box;

   function Make_Box_Vec (Lo, Hi : Vector) return Constraint is
      C : Constraint;
      D : constant Dimension := Dimension (Lo'Length);
   begin
      if Lo'Length /= Hi'Length then
         raise Invalid_Argument with "Make_Box_Vec: length mismatch";
      end if;
      C.Kind := Box_Constraint;
      C.Dim := D;
      for I in 1 .. D loop
         if Lo (Lo'First + I - 1) > Hi (Hi'First + I - 1) then
            raise Invalid_Argument with "Make_Box_Vec: Lo > Hi";
         end if;
         C.Lo (I) := Lo (Lo'First + I - 1);
         C.Hi (I) := Hi (Hi'First + I - 1);
      end loop;
      return C;
   end Make_Box_Vec;

   function Make_Ball
     (Dim : Dimension; Radius : Real; Center_Val : Real := 0.0)
      return Constraint
   is
      C : Constraint;
   begin
      if Radius < 0.0 then
         raise Invalid_Argument with "Make_Ball: negative radius";
      end if;
      C.Kind := Ball_Constraint;
      C.Dim := Dim;
      C.Radius := Radius;
      for I in 1 .. Dim loop
         C.Center (I) := Center_Val;
      end loop;
      return C;
   end Make_Ball;

   function Make_Sphere
     (Dim : Dimension; Radius : Real; Center_Val : Real := 0.0)
      return Constraint
   is
      C : Constraint;
   begin
      if Radius <= 0.0 then
         raise Invalid_Argument with "Make_Sphere: radius must be > 0";
      end if;
      C.Kind := Sphere_Constraint;
      C.Dim := Dim;
      C.Radius := Radius;
      for I in 1 .. Dim loop
         C.Center (I) := Center_Val;
      end loop;
      return C;
   end Make_Sphere;

   function Make_Orthant (Dim : Dimension) return Constraint is
      C : Constraint;
   begin
      C.Kind := Orthant_Constraint;
      C.Dim := Dim;
      return C;
   end Make_Orthant;

   function Make_Hyperplane
     (Normal : Vector; Offset : Real) return Constraint
   is
      C : Constraint;
      D : constant Dimension := Dimension (Normal'Length);
      N2 : Real := 0.0;
   begin
      for V of Normal loop
         N2 := N2 + V * V;
      end loop;
      if N2 = 0.0 then
         raise Invalid_Argument with "Make_Hyperplane: zero normal";
      end if;
      C.Kind := Hyperplane_Constraint;
      C.Dim := D;
      C.Offset := Offset;
      for I in 1 .. D loop
         C.Normal (I) := Normal (Normal'First + I - 1);
      end loop;
      return C;
   end Make_Hyperplane;

begin
   null;
end Difference_Map;
