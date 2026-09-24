--  Itp_Method body — Wikipedia Interpolate Truncate Project implementation.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Itp_Method
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

   function Bracket_Valid
     (A, B : Real;
      F    : Objective_Fn) return Boolean
   is
      FA, FB : Real;
   begin
      if F = null then
         return False;
      end if;
      if A = B then
         return False;
      end if;
      FA := F (A);
      FB := F (B);
      return FA * FB < 0.0;
   end Bracket_Valid;

   function N_Half (A, B, Eps : Real) return Natural is
      Width : constant Real := abs (B - A);
      Arg   : Real;
      L     : Real;
   begin
      if Width <= 2.0 * Eps then
         return 0;
      end if;
      Arg := Width / (2.0 * Eps);
      L   := Log (Arg) / Log (2.0);
      if L <= 0.0 then
         return 0;
      end if;
      declare
         Floor_L : constant Natural :=
           Natural (Real'Max (0.0, Real'Truncation (L)));
      begin
         if Real (Floor_L) < L then
            return Floor_L + 1;
         else
            return Floor_L;
         end if;
      end;
   end N_Half;

   -------------------------------------------------------------------------
   -- One Wikipedia Interpolate / Truncate / Project query
   -------------------------------------------------------------------------

   function Next_Point
     (A, B, YA, YB : Real;
      Kappa1       : Positive_Real;
      Kappa2       : Positive_Real;
      For_Rk       : Real) return Real
   is
      X_Half : constant Real := (A + B) / 2.0;
      Span   : constant Real := B - A;
      X_F    : Real;
      Sigma  : Real;
      Trunc_Del  : Real;
      X_T    : Real;
      Rk     : Real;
      Diff   : Real;
   begin
      if YA = YB then
         raise Invalid_Argument
           with "ITP Next_Point: YA = YB (degenerate interpolation)";
      end if;

      --  Interpolation (regula falsi / Wikipedia x_f):
      --    x_f = (y_b a − y_a b) / (y_b − y_a)
      X_F := (YB * A - YA * B) / (YB - YA);

      --  Truncation toward the center:
      --    σ = sign(x_{1/2} − x_f)
      --    δ = κ₁ |b−a|^{κ₂}
      --    if δ ≤ |x_{1/2}−x_f| then x_t = x_f + σ δ else x_t = x_{1/2}
      Diff  := X_Half - X_F;
      Sigma := Sign (Diff);
      Trunc_Del := Kappa1 * Exp (Kappa2 * Log (abs (Span)));

      if Trunc_Del <= abs (Diff) then
         X_T := X_F + Sigma * Trunc_Del;
      else
         X_T := X_Half;
      end if;

      --  Projection onto the minmax neighbourhood of the midpoint:
      --    r_k = For_Rk − (b−a)/2
      --    if |x_t − x_{1/2}| ≤ r_k then x_ITP = x_t
      --    else x_ITP = x_{1/2} − σ r_k
      Rk := For_Rk - Span / 2.0;
      if abs (X_T - X_Half) <= Rk then
         return X_T;
      else
         return X_Half - Sigma * Rk;
      end if;
   end Next_Point;

   -------------------------------------------------------------------------
   -- Main driver (Wikipedia while b−a > 2ε loop)
   -------------------------------------------------------------------------

   function Find_Root
     (F   : Objective_Fn;
      A   : Real;
      B   : Real;
      Cfg : Config := (others => <>)) return Result
   is
      Lo, Hi         : Real;
      Ya, Yb         : Real;
      Inc            : Real;
      X_Itp, Y_Itp   : Real;
      Out_R          : Result;
      Iters          : Natural := 0;
      NH             : Natural;
      N_Max          : Natural;
      For_Rk         : Real;
      Eps            : constant Real := Real (Cfg.Tol);
   begin
      if F = null then
         raise Invalid_Argument with "ITP Find_Root: null objective";
      end if;

      if Cfg.Kappa2 < 1.0
        or else Cfg.Kappa2 >= 1.0 + Golden_Phi
      then
         raise Invalid_Argument
           with "ITP Find_Root: Kappa2 must lie in [1, 1+φ)";
      end if;

      Lo := A;
      Hi := B;
      if Lo > Hi then
         Lo := B;
         Hi := A;
      end if;

      Ya := F (Lo);
      Yb := F (Hi);

      Out_R.Bracket_A := Lo;
      Out_R.Bracket_B := Hi;
      Out_R.Final_F   := Ya;

      --  Exact endpoint hits.
      if abs (Ya) <= Eps then
         Out_R.Root       := Lo;
         Out_R.Iterations := 0;
         Out_R.Success    := True;
         Out_R.Status     := Ok;
         Out_R.Final_F    := Ya;
         return Out_R;
      end if;
      if abs (Yb) <= Eps then
         Out_R.Root       := Hi;
         Out_R.Iterations := 0;
         Out_R.Success    := True;
         Out_R.Status     := Ok;
         Out_R.Final_F    := Yb;
         return Out_R;
      end if;

      if Ya * Yb >= 0.0 or else Lo = Hi then
         Out_R.Success := False;
         Out_R.Status  := Invalid_Bracket;
         return Out_R;
      end if;

      --  Already within tolerance.
      if Hi - Lo <= 2.0 * Eps then
         Out_R.Root       := (Lo + Hi) / 2.0;
         Out_R.Iterations := 0;
         Out_R.Success    := True;
         Out_R.Status     := Ok;
         Out_R.Final_F    := F (Out_R.Root);
         return Out_R;
      end if;

      --  Keep a < b; update with Inc = sign(f(b)) as in the R itp package
      --  (generalises Wikipedia's ya < 0 < yb orientation).
      Inc   := Sign (Yb);
      NH    := N_Half (Lo, Hi, Eps);
      N_Max := NH + Cfg.N0;
      --  for_rk = ε · 2^{n_max}; halved each iteration (≡ ε 2^{n_max−j}).
      For_Rk := Eps * Exp (Real (N_Max) * Log (2.0));

      while Hi - Lo > 2.0 * Eps loop
         if Iters >= Cfg.Max_Iterations then
            Out_R.Root       := (Lo + Hi) / 2.0;
            Out_R.Iterations := Iters;
            Out_R.Success    := False;
            Out_R.Status     := Max_Iterations_Reached;
            Out_R.Final_F    := F (Out_R.Root);
            Out_R.Bracket_A  := Lo;
            Out_R.Bracket_B  := Hi;
            return Out_R;
         end if;

         if Ya = Yb then
            Out_R.Root       := (Lo + Hi) / 2.0;
            Out_R.Iterations := Iters;
            Out_R.Success    := False;
            Out_R.Status     := Degenerate;
            Out_R.Final_F    := Ya;
            Out_R.Bracket_A  := Lo;
            Out_R.Bracket_B  := Hi;
            return Out_R;
         end if;

         X_Itp := Next_Point
           (Lo, Hi, Ya, Yb, Cfg.Kappa1, Cfg.Kappa2, For_Rk);
         Y_Itp := F (X_Itp);
         Iters := Iters + 1;

         --  Update bracket: same-sign as Yb → shrink Hi; else shrink Lo.
         if Y_Itp * Inc > 0.0 then
            Hi := X_Itp;
            Yb := Y_Itp;
         elsif Y_Itp * Inc < 0.0 then
            Lo := X_Itp;
            Ya := Y_Itp;
         else
            Lo := X_Itp;
            Hi := X_Itp;
            Ya := Y_Itp;
            Yb := Y_Itp;
         end if;

         For_Rk := For_Rk * 0.5;
         Out_R.Bracket_A := Lo;
         Out_R.Bracket_B := Hi;
      end loop;

      Out_R.Root       := (Lo + Hi) / 2.0;
      Out_R.Iterations := Iters;
      Out_R.Success    := True;
      Out_R.Status     := Ok;
      Out_R.Final_F    := F (Out_R.Root);
      Out_R.Bracket_A  := Lo;
      Out_R.Bracket_B  := Hi;
      return Out_R;
   end Find_Root;

   function Find_Root
     (F              : Objective_Fn;
      A              : Real;
      B              : Real;
      Tol            : Positive_Real;
      Max_Iterations : Positive := 100) return Result
   is
      Cfg : constant Config :=
        (Max_Iterations => Max_Iterations,
         Tol            => Tol,
         Kappa1         => 0.1,
         Kappa2         => 2.0,
         N0             => 1);
   begin
      return Find_Root (F, A, B, Cfg);
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
      return (X * X - 1.0) * X - 2.0;
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

   function Always_Positive (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return 1.0;
   end Always_Positive;

   function Always_Negative (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return -3.0;
   end Always_Negative;

   function Same_Sign_Ends (X : Real) return Real is
   begin
      return X * X + 1.0;
   end Same_Sign_Ends;

   function Flat_Zero (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return 0.0;
   end Flat_Zero;

end Itp_Method;
