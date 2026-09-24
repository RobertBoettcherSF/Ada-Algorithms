--  Newtons_Method body — Wikipedia Newton–Raphson implementation.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Newtons_Method
  with SPARK_Mode => Off
is

   package Elem is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Elem;

   --  Fixed a for the educational square-root objective (Wikipedia 612).
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
     (X       : Real;
      F_Val   : Real;
      F_Deriv : Real;
      Damping : Positive_Real := 1.0) return Real
   is
   begin
      if F_Deriv = 0.0 then
         raise Invalid_Argument
           with "Newton Next_Point: zero derivative";
      end if;
      --  Wikipedia: x_{n+1} = x_n − f(x_n)/f'(x_n)
      --  Optional damping: x_{n+1} = x_n − λ f(x_n)/f'(x_n), λ ∈ (0,1].
      return X - Damping * (F_Val / F_Deriv);
   end Next_Point;

   -------------------------------------------------------------------------
   -- Main driver
   -------------------------------------------------------------------------

   function Find_Root
     (F       : Objective_Fn;
      F_Prime : Derivative_Fn;
      X0      : Real;
      Cfg     : Config := (others => <>)) return Result
   is
      X, X_New     : Real;
      FX, FXp, DF  : Real;
      Step         : Real;
      Lam          : Real;
      Out_R        : Result;
      Iters        : Natural := 0;
   begin
      if F = null or else F_Prime = null then
         raise Invalid_Argument
           with "Newton Find_Root: null objective or derivative";
      end if;

      if Cfg.Damping > 1.0 then
         raise Invalid_Argument
           with "Newton Find_Root: Damping must be in (0,1]";
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

         if abs (DF) < Cfg.Min_Derivative then
            Out_R.Root       := X;
            Out_R.Iterations := Iters;
            Out_R.Success    := False;
            Out_R.Status     := Degenerate;
            Out_R.Final_F    := FX;
            return Out_R;
         end if;

         Lam := Cfg.Damping;
         --  Classical (or user-damped) Newton step.
         X_New := Next_Point (X, FX, DF, Lam);
         Step  := X_New - X;

         if Cfg.Use_Safeguard then
            --  Light backtracking: shrink λ while |f| grows (cap 8 tries).
            --  Keep last trial if no accept; outer loop may still hit Tol.
            for Attempt in 1 .. 8 loop
               X_New := X - Lam * (FX / DF);
               FXp   := F (X_New);
               if abs (FXp) <= abs (FX) or else abs (FXp) <= Cfg.Tol then
                  exit;
               end if;
               Lam := Lam * 0.5;
               if Lam < Cfg.Min_Derivative then
                  exit;
               end if;
            end loop;
            Step := X_New - X;
         else
            FXp := F (X_New);
         end if;

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
      X0             : Real;
      Tol            : Positive_Real;
      Max_Iterations : Positive := 100) return Result
   is
      Cfg : constant Config :=
        (Max_Iterations => Max_Iterations,
         Tol            => Tol,
         Min_Derivative => 1.0E-14,
         Damping        => 1.0,
         Use_Safeguard  => False);
   begin
      return Find_Root (F, F_Prime, X0, Cfg);
   end Find_Root;

   -------------------------------------------------------------------------
   -- Sample objectives + derivatives
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

   function Poly_Quad (X : Real) return Real is
   begin
      return X * X - 2.0;
   end Poly_Quad;

   function Poly_Quad_Prime (X : Real) return Real is
   begin
      return 2.0 * X;
   end Poly_Quad_Prime;

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

   function Poly_Cubic (X : Real) return Real is
   begin
      return ((X - 6.0) * X + 11.0) * X - 6.0;
   end Poly_Cubic;

   function Poly_Cubic_Prime (X : Real) return Real is
   begin
      return (3.0 * X - 12.0) * X + 11.0;
   end Poly_Cubic_Prime;

   function Poly_Shifted (X : Real) return Real is
   begin
      return (X - 0.5) * (X + 3.0);
   end Poly_Shifted;

   function Poly_Shifted_Prime (X : Real) return Real is
   begin
      return 2.0 * X + 2.5;
   end Poly_Shifted_Prime;

   function Cubic_One_Root (X : Real) return Real is
   begin
      return (X * X - 1.0) * X - 1.0;
   end Cubic_One_Root;

   function Cubic_One_Root_Prime (X : Real) return Real is
   begin
      return 3.0 * X * X - 1.0;
   end Cubic_One_Root_Prime;

   function Sin_Fn (X : Real) return Real is
   begin
      return Sin (X);
   end Sin_Fn;

   function Sin_Fn_Prime (X : Real) return Real is
   begin
      return Cos (X);
   end Sin_Fn_Prime;

   function Cos_Fn (X : Real) return Real is
   begin
      return Cos (X);
   end Cos_Fn;

   function Cos_Fn_Prime (X : Real) return Real is
   begin
      return -Sin (X);
   end Cos_Fn_Prime;

   function Exp_Linear (X : Real) return Real is
   begin
      return Exp (X) - 2.0;
   end Exp_Linear;

   function Exp_Linear_Prime (X : Real) return Real is
   begin
      return Exp (X);
   end Exp_Linear_Prime;

   function Atan_Shift (X : Real) return Real is
   begin
      return Arctan (X) - 0.5;
   end Atan_Shift;

   function Atan_Shift_Prime (X : Real) return Real is
   begin
      return 1.0 / (1.0 + X * X);
   end Atan_Shift_Prime;

   function Steep_Exp (X : Real) return Real is
   begin
      return Exp (X) - Exp (1.0);
   end Steep_Exp;

   function Steep_Exp_Prime (X : Real) return Real is
   begin
      return Exp (X);
   end Steep_Exp_Prime;

   function Cos_Minus_X3 (X : Real) return Real is
   begin
      return Cos (X) - X * X * X;
   end Cos_Minus_X3;

   function Cos_Minus_X3_Prime (X : Real) return Real is
   begin
      return -Sin (X) - 3.0 * X * X;
   end Cos_Minus_X3_Prime;

   function Flat_Derivative (X : Real) return Real is
   begin
      return X * X - 1.0;
   end Flat_Derivative;

   function Flat_Derivative_Prime (X : Real) return Real is
   begin
      return 2.0 * X;
   end Flat_Derivative_Prime;

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

end Newtons_Method;
