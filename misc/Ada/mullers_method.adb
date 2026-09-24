--  Mullers_Method body — Wikipedia Muller's method (real-valued path).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Mullers_Method
  with SPARK_Mode => Off
is

   package Elem is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Elem;

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

   function Starts_Distinct (X0, X1, X2 : Real) return Boolean is
   begin
      return X0 /= X1 and then X1 /= X2 and then X0 /= X2;
   end Starts_Distinct;

   -------------------------------------------------------------------------
   -- One Wikipedia real update for x₃
   -------------------------------------------------------------------------

   function Next_Point
     (X0, X1, X2 : Real;
      F0, F1, F2 : Real) return Real
   is
      H0, H1           : Real;
      Delta0, Delta1   : Real;
      A, B, C          : Real;
      Disc             : Real;
      Denom            : Real;
   begin
      H0 := X1 - X0;
      H1 := X2 - X1;
      if H0 = 0.0 or else H1 = 0.0 then
         raise Invalid_Argument
           with "Muller Next_Point: coincident abscissae";
      end if;

      Delta0 := (F1 - F0) / H0;
      Delta1 := (F2 - F1) / H1;
      A := (Delta1 - Delta0) / (H1 + H0);
      B := A * H1 + Delta1;
      C := F2;

      Disc := B * B - 4.0 * A * C;
      if Disc < 0.0 then
         raise Invalid_Argument
           with "Muller Next_Point: negative discriminant (complex root)";
      end if;

      --  Wikipedia: choose sign(b) so the next iterate is closest to x2.
      if B >= 0.0 then
         Denom := B + Sqrt (Disc);
      else
         Denom := B - Sqrt (Disc);
      end if;

      if Denom = 0.0 then
         raise Invalid_Argument
           with "Muller Next_Point: zero denominator";
      end if;

      return X2 - 2.0 * C / Denom;
   end Next_Point;

   -------------------------------------------------------------------------
   -- Main driver
   -------------------------------------------------------------------------

   function Find_Root
     (F   : Objective_Fn;
      X0  : Real;
      X1  : Real;
      X2  : Real;
      Cfg : Config := (others => <>)) return Result
   is
      Y0, Y1, Y2 : Real;
      F0, F1, F2 : Real;
      X_New      : Real;
      F_New      : Real;
      Out_R      : Result;
      Iters      : Natural := 0;
   begin
      if F = null then
         raise Invalid_Argument with "Muller Find_Root: null objective";
      end if;

      Y0 := X0;
      Y1 := X1;
      Y2 := X2;
      F0 := F (Y0);
      F1 := F (Y1);
      F2 := F (Y2);

      Out_R.Final_F := F2;

      --  Exact hits at the initial sample points.
      if abs (F0) <= Cfg.Tol then
         Out_R.Root       := Y0;
         Out_R.Iterations := 0;
         Out_R.Success    := True;
         Out_R.Status     := Ok;
         Out_R.Final_F    := F0;
         return Out_R;
      end if;
      if abs (F1) <= Cfg.Tol then
         Out_R.Root       := Y1;
         Out_R.Iterations := 0;
         Out_R.Success    := True;
         Out_R.Status     := Ok;
         Out_R.Final_F    := F1;
         return Out_R;
      end if;
      if abs (F2) <= Cfg.Tol then
         Out_R.Root       := Y2;
         Out_R.Iterations := 0;
         Out_R.Success    := True;
         Out_R.Status     := Ok;
         Out_R.Final_F    := F2;
         return Out_R;
      end if;

      if not Starts_Distinct (Y0, Y1, Y2) then
         Out_R.Root       := Y2;
         Out_R.Iterations := 0;
         Out_R.Success    := False;
         Out_R.Status     := Degenerate;
         Out_R.Final_F    := F2;
         return Out_R;
      end if;

      for Iter in 1 .. Cfg.Max_Iterations loop
         Iters := Iter;

         declare
            H0 : constant Real := Y1 - Y0;
            H1 : constant Real := Y2 - Y1;
            Disc : Real;
            A, B, C : Real;
            Delta0, Delta1 : Real;
         begin
            if H0 = 0.0 or else H1 = 0.0 then
               Out_R.Root       := Y2;
               Out_R.Iterations := Iters;
               Out_R.Success    := False;
               Out_R.Status     := Degenerate;
               Out_R.Final_F    := F2;
               return Out_R;
            end if;

            Delta0 := (F1 - F0) / H0;
            Delta1 := (F2 - F1) / H1;
            A := (Delta1 - Delta0) / (H1 + H0);
            B := A * H1 + Delta1;
            C := F2;
            Disc := B * B - 4.0 * A * C;

            if Disc < 0.0 then
               Out_R.Root       := Y2;
               Out_R.Iterations := Iters;
               Out_R.Success    := False;
               Out_R.Status     := Degenerate;
               Out_R.Final_F    := F2;
               return Out_R;
            end if;
         end;

         begin
            X_New := Next_Point (Y0, Y1, Y2, F0, F1, F2);
         exception
            when Invalid_Argument =>
               Out_R.Root       := Y2;
               Out_R.Iterations := Iters;
               Out_R.Success    := False;
               Out_R.Status     := Degenerate;
               Out_R.Final_F    := F2;
               return Out_R;
         end;

         F_New := F (X_New);

         if abs (F_New) <= Cfg.Tol
           or else abs (X_New - Y2) <= Cfg.Tol
         then
            Out_R.Root       := X_New;
            Out_R.Iterations := Iters;
            Out_R.Success    := True;
            Out_R.Status     := Ok;
            Out_R.Final_F    := F_New;
            return Out_R;
         end if;

         --  Shift the window: (x0,x1,x2) ← (x1,x2,x3)
         Y0 := Y1;
         F0 := F1;
         Y1 := Y2;
         F1 := F2;
         Y2 := X_New;
         F2 := F_New;
      end loop;

      Out_R.Root       := Y2;
      Out_R.Iterations := Iters;
      Out_R.Success    := False;
      Out_R.Status     := Max_Iterations_Reached;
      Out_R.Final_F    := F2;
      return Out_R;
   end Find_Root;

   function Find_Root
     (F              : Objective_Fn;
      X0             : Real;
      X1             : Real;
      X2             : Real;
      Tol            : Positive_Real;
      Max_Iterations : Positive := 100) return Result
   is
      Cfg : constant Config :=
        (Max_Iterations => Max_Iterations, Tol => Tol);
   begin
      return Find_Root (F, X0, X1, X2, Cfg);
   end Find_Root;

   -------------------------------------------------------------------------
   -- Sample objectives
   -------------------------------------------------------------------------

   function Poly_Linear (X : Real) return Real is
   begin
      return 2.0 * X - 4.0;
   end Poly_Linear;

   function Poly_Quad (X : Real) return Real is
   begin
      return X * X - 2.0;
   end Poly_Quad;

   function Poly_Cubic (X : Real) return Real is
   begin
      return ((X - 6.0) * X + 11.0) * X - 6.0;
   end Poly_Cubic;

   function Poly_Shifted (X : Real) return Real is
   begin
      return (X - 0.5) * (X + 3.0);
   end Poly_Shifted;

   function Cubic_One_Root (X : Real) return Real is
   begin
      return (X * X - 1.0) * X - 1.0;
   end Cubic_One_Root;

   function Wiki_Cubic (X : Real) return Real is
   begin
      return -X * X * X - X + 7.0;
   end Wiki_Cubic;

   function Sin_Fn (X : Real) return Real is
   begin
      return Sin (X);
   end Sin_Fn;

   function Cos_Fn (X : Real) return Real is
   begin
      return Cos (X);
   end Cos_Fn;

   function Exp_Linear (X : Real) return Real is
   begin
      return Exp (X) - 2.0;
   end Exp_Linear;

   function Atan_Shift (X : Real) return Real is
   begin
      return Arctan (X) - 0.5;
   end Atan_Shift;

   function Steep_Exp (X : Real) return Real is
   begin
      return Exp (X) - Exp (1.0);
   end Steep_Exp;

   function Cos_Minus_X3 (X : Real) return Real is
   begin
      return Cos (X) - X * X * X;
   end Cos_Minus_X3;

   function Always_Positive (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return 1.0;
   end Always_Positive;

   function Constant_Zero (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return 0.0;
   end Constant_Zero;

end Mullers_Method;
