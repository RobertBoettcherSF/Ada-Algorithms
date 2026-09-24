--  Halleys_Method body — Wikipedia classic (rational) Halley implementation.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Halleys_Method
  with SPARK_Mode => Off
is

   package Elem is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Elem;

   --  Fixed a for the educational square-root objective (Wikipedia-style 612).
   Sqrt_A : constant Real := 612.0;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Sign (X : Real) return Real is
   begin
      if X > 0.0 then
         return 1.0;
      elsif X < 0.0 then
         return -1.0;
      else
         return 0.0;
      end if;
   end Sign;

   function Next_Point
     (X        : Real;
      F_Val    : Real;
      F_Deriv  : Real;
      F_Second : Real) return Real
   is
      Denom : constant Real :=
        2.0 * F_Deriv * F_Deriv - F_Val * F_Second;
   begin
      if Denom = 0.0 then
         raise Invalid_Argument
           with "Halley Next_Point: zero denominator";
      end if;
      --  Wikipedia rational form:
      --  x − (2 f f') / (2 (f')² − f f'')
      return X - (2.0 * F_Val * F_Deriv) / Denom;
   end Next_Point;

   -------------------------------------------------------------------------
   -- Main driver
   -------------------------------------------------------------------------

   function Find_Root
     (F         : Objective_Fn;
      F_Prime   : Derivative_Fn;
      F_Second  : Second_Derivative_Fn;
      X0        : Real;
      Cfg       : Config := (others => <>)) return Result
   is
      X, X_New           : Real;
      FX, FXp, DF, D2F   : Real;
      Numer, Denom, Step : Real;
      Out_R              : Result;
      Iters              : Natural := 0;
   begin
      if F = null or else F_Prime = null or else F_Second = null then
         raise Invalid_Argument
           with "Halley Find_Root: null objective or derivative";
      end if;

      X  := X0;
      FX := F (X);
      Out_R.Root    := X;
      Out_R.Final_F := FX;

      --  Already at a root.
      if abs (FX) <= Cfg.Tol then
         Out_R.Iterations := 0;
         Out_R.Success    := True;
         Out_R.Status     := Ok;
         return Out_R;
      end if;

      for Iter in 1 .. Cfg.Max_Iterations loop
         Iters := Iter;
         DF    := F_Prime (X);
         D2F   := F_Second (X);
         Numer := 2.0 * FX * DF;
         Denom := 2.0 * DF * DF - FX * D2F;

         if abs (Denom) < Cfg.Min_Denominator then
            Out_R.Root       := X;
            Out_R.Iterations := Iters;
            Out_R.Success    := False;
            Out_R.Status     := Degenerate;
            Out_R.Final_F    := FX;
            return Out_R;
         end if;

         --  Vanishing numerator with nonzero residual → no progress
         --  (e.g. f' = 0 while f ≠ 0). Treat as Degenerate.
         if abs (Numer) < Cfg.Min_Denominator then
            Out_R.Root       := X;
            Out_R.Iterations := Iters;
            Out_R.Success    := False;
            Out_R.Status     := Degenerate;
            Out_R.Final_F    := FX;
            return Out_R;
         end if;

         X_New := X - Numer / Denom;
         Step  := X_New - X;
         FXp   := F (X_New);

         X  := X_New;
         FX := FXp;

         Out_R.Root    := X;
         Out_R.Final_F := FX;

         if abs (FX) <= Cfg.Tol or else abs (Step) <= Cfg.Tol then
            Out_R.Iterations := Iters;
            Out_R.Success    := True;
            Out_R.Status     := Ok;
            return Out_R;
         end if;
      end loop;

      Out_R.Root       := X;
      Out_R.Iterations := Iters;
      Out_R.Success    := False;
      Out_R.Status     := Max_Iterations_Reached;
      Out_R.Final_F    := FX;
      return Out_R;
   end Find_Root;

   function Find_Root
     (F              : Objective_Fn;
      F_Prime        : Derivative_Fn;
      F_Second       : Second_Derivative_Fn;
      X0             : Real;
      Tol            : Positive_Real;
      Max_Iterations : Positive := 100) return Result
   is
      Cfg : constant Config :=
        (Max_Iterations  => Max_Iterations,
         Tol             => Tol,
         Min_Denominator => 1.0E-14);
   begin
      return Find_Root (F, F_Prime, F_Second, X0, Cfg);
   end Find_Root;

   -------------------------------------------------------------------------
   -- Sample objectives + first / second derivatives
   -------------------------------------------------------------------------

   function Poly_Linear (X : Real) return Real is
   begin
      return 2.0 * X - 4.0;
   end Poly_Linear;

   function Poly_Linear_Prime (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return 2.0;
   end Poly_Linear_Prime;

   function Poly_Linear_Second (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return 0.0;
   end Poly_Linear_Second;

   function Poly_Quad (X : Real) return Real is
   begin
      return X * X - 2.0;
   end Poly_Quad;

   function Poly_Quad_Prime (X : Real) return Real is
   begin
      return 2.0 * X;
   end Poly_Quad_Prime;

   function Poly_Quad_Second (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return 2.0;
   end Poly_Quad_Second;

   function Sqrt_Target_A return Real is
   begin
      return Sqrt_A;
   end Sqrt_Target_A;

   function Sqrt_Obj (X : Real) return Real is
   begin
      return X * X - Sqrt_A;
   end Sqrt_Obj;

   function Sqrt_Obj_Prime (X : Real) return Real is
   begin
      return 2.0 * X;
   end Sqrt_Obj_Prime;

   function Sqrt_Obj_Second (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return 2.0;
   end Sqrt_Obj_Second;

   function Poly_Cubic (X : Real) return Real is
   begin
      return ((X - 6.0) * X + 11.0) * X - 6.0;
   end Poly_Cubic;

   function Poly_Cubic_Prime (X : Real) return Real is
   begin
      return (3.0 * X - 12.0) * X + 11.0;
   end Poly_Cubic_Prime;

   function Poly_Cubic_Second (X : Real) return Real is
   begin
      return 6.0 * X - 12.0;
   end Poly_Cubic_Second;

   function Poly_Shifted (X : Real) return Real is
   begin
      return (X - 0.5) * (X + 3.0);
   end Poly_Shifted;

   function Poly_Shifted_Prime (X : Real) return Real is
   begin
      return 2.0 * X + 2.5;
   end Poly_Shifted_Prime;

   function Poly_Shifted_Second (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return 2.0;
   end Poly_Shifted_Second;

   function Cubic_One_Root (X : Real) return Real is
   begin
      return (X * X - 1.0) * X - 1.0;
   end Cubic_One_Root;

   function Cubic_One_Root_Prime (X : Real) return Real is
   begin
      return 3.0 * X * X - 1.0;
   end Cubic_One_Root_Prime;

   function Cubic_One_Root_Second (X : Real) return Real is
   begin
      return 6.0 * X;
   end Cubic_One_Root_Second;

   function Sin_Fn (X : Real) return Real is
   begin
      return Sin (X);
   end Sin_Fn;

   function Sin_Fn_Prime (X : Real) return Real is
   begin
      return Cos (X);
   end Sin_Fn_Prime;

   function Sin_Fn_Second (X : Real) return Real is
   begin
      return -Sin (X);
   end Sin_Fn_Second;

   function Cos_Fn (X : Real) return Real is
   begin
      return Cos (X);
   end Cos_Fn;

   function Cos_Fn_Prime (X : Real) return Real is
   begin
      return -Sin (X);
   end Cos_Fn_Prime;

   function Cos_Fn_Second (X : Real) return Real is
   begin
      return -Cos (X);
   end Cos_Fn_Second;

   function Exp_Linear (X : Real) return Real is
   begin
      return Exp (X) - 2.0;
   end Exp_Linear;

   function Exp_Linear_Prime (X : Real) return Real is
   begin
      return Exp (X);
   end Exp_Linear_Prime;

   function Exp_Linear_Second (X : Real) return Real is
   begin
      return Exp (X);
   end Exp_Linear_Second;

   function Atan_Shift (X : Real) return Real is
   begin
      return Arctan (X) - 0.5;
   end Atan_Shift;

   function Atan_Shift_Prime (X : Real) return Real is
   begin
      return 1.0 / (1.0 + X * X);
   end Atan_Shift_Prime;

   function Atan_Shift_Second (X : Real) return Real is
      D : constant Real := 1.0 + X * X;
   begin
      return -2.0 * X / (D * D);
   end Atan_Shift_Second;

   function Steep_Exp (X : Real) return Real is
   begin
      return Exp (X) - Exp (1.0);
   end Steep_Exp;

   function Steep_Exp_Prime (X : Real) return Real is
   begin
      return Exp (X);
   end Steep_Exp_Prime;

   function Steep_Exp_Second (X : Real) return Real is
   begin
      return Exp (X);
   end Steep_Exp_Second;

   function Cos_Minus_X3 (X : Real) return Real is
   begin
      return Cos (X) - X * X * X;
   end Cos_Minus_X3;

   function Cos_Minus_X3_Prime (X : Real) return Real is
   begin
      return -Sin (X) - 3.0 * X * X;
   end Cos_Minus_X3_Prime;

   function Cos_Minus_X3_Second (X : Real) return Real is
   begin
      return -Cos (X) - 6.0 * X;
   end Cos_Minus_X3_Second;

   function Flat_Derivative (X : Real) return Real is
   begin
      return X * X - 1.0;
   end Flat_Derivative;

   function Flat_Derivative_Prime (X : Real) return Real is
   begin
      return 2.0 * X;
   end Flat_Derivative_Prime;

   function Flat_Derivative_Second (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return 2.0;
   end Flat_Derivative_Second;

   function Constant_One (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return 1.0;
   end Constant_One;

   function Constant_One_Prime (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return 0.0;
   end Constant_One_Prime;

   function Constant_One_Second (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return 0.0;
   end Constant_One_Second;

end Halleys_Method;
