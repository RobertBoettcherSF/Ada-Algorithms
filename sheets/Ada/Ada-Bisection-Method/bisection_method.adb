--  Bisection_Method body — classic interval-halving root finder.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Bisection_Method
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

   function Iterations_Needed
     (A, B : Real;
      Tol  : Positive_Real) return Natural
   is
      Width : constant Real := abs (B - A);
      Arg   : Real;
      L     : Real;
   begin
      --  Already within half-width Tol: (b−a)/2 < Tol ⇔ b−a < 2 Tol.
      --  The classic estimate uses ⌈log₂((b−a)/Tol)⌉ for absolute width
      --  shrinking to Tol; return 0 when Width ≤ Tol.
      if Width <= Tol then
         return 0;
      end if;
      Arg := Width / Tol;
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
   end Iterations_Needed;

   -------------------------------------------------------------------------
   -- One classic midpoint
   -------------------------------------------------------------------------

   function Next_Point (A, B : Real) return Real is
   begin
      return (A + B) / 2.0;
   end Next_Point;

   -------------------------------------------------------------------------
   -- Main driver
   -------------------------------------------------------------------------

   function Find_Root
     (F   : Objective_Fn;
      A   : Real;
      B   : Real;
      Cfg : Config := (others => <>)) return Result
   is
      Lo, Hi     : Real;
      F_Lo, F_Hi : Real;
      Cand       : Real;
      F_Cand     : Real;
      Out_R      : Result;
      Iters      : Natural := 0;
   begin
      if F = null then
         raise Invalid_Argument
           with "Bisection Find_Root: null objective";
      end if;

      Lo := A;
      Hi := B;
      if Lo > Hi then
         Lo := B;
         Hi := A;
      end if;

      F_Lo := F (Lo);
      F_Hi := F (Hi);

      Out_R.Bracket_A := Lo;
      Out_R.Bracket_B := Hi;
      Out_R.Final_F   := F_Lo;

      --  Exact endpoint hits.
      if abs (F_Lo) <= Cfg.Tol then
         Out_R.Root       := Lo;
         Out_R.Iterations := 0;
         Out_R.Success    := True;
         Out_R.Status     := Ok;
         Out_R.Final_F    := F_Lo;
         return Out_R;
      end if;
      if abs (F_Hi) <= Cfg.Tol then
         Out_R.Root       := Hi;
         Out_R.Iterations := 0;
         Out_R.Success    := True;
         Out_R.Status     := Ok;
         Out_R.Final_F    := F_Hi;
         return Out_R;
      end if;

      if F_Lo * F_Hi >= 0.0 or else Lo = Hi then
         Out_R.Success := False;
         Out_R.Status  := Invalid_Bracket;
         return Out_R;
      end if;

      for Iter in 1 .. Cfg.Max_Iterations loop
         Iters := Iter;

         if Hi = Lo then
            Out_R.Root       := Lo;
            Out_R.Iterations := Iters;
            Out_R.Success    := False;
            Out_R.Status     := Degenerate;
            Out_R.Final_F    := F_Lo;
            Out_R.Bracket_A  := Lo;
            Out_R.Bracket_B  := Hi;
            return Out_R;
         end if;

         Cand   := Next_Point (Lo, Hi);
         F_Cand := F (Cand);

         if abs (F_Cand) < Cfg.Tol then
            Out_R.Root       := Cand;
            Out_R.Iterations := Iters;
            Out_R.Success    := True;
            Out_R.Status     := Ok;
            Out_R.Final_F    := F_Cand;
            Out_R.Bracket_A  := Lo;
            Out_R.Bracket_B  := Hi;
            return Out_R;
         end if;

         --  Keep the half that still has a sign change.
         if F_Lo * F_Cand < 0.0 then
            Hi   := Cand;
            F_Hi := F_Cand;
         else
            Lo   := Cand;
            F_Lo := F_Cand;
         end if;

         Out_R.Bracket_A := Lo;
         Out_R.Bracket_B := Hi;

         --  Classic half-width stop: (b − a)/2 < Tol.
         if (Hi - Lo) / 2.0 < Cfg.Tol then
            Out_R.Root       := Next_Point (Lo, Hi);
            Out_R.Final_F    := F (Out_R.Root);
            Out_R.Iterations := Iters;
            Out_R.Success    := True;
            Out_R.Status     := Ok;
            return Out_R;
         end if;
      end loop;

      Out_R.Root       := Next_Point (Lo, Hi);
      Out_R.Final_F    := F (Out_R.Root);
      Out_R.Iterations := Iters;
      Out_R.Success    := False;
      Out_R.Status     := Max_Iterations_Reached;
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
         Tol            => Tol);
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

end Bisection_Method;
