--  False_Position_Method body — classic regula falsi + optional Illinois.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body False_Position_Method
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

   -------------------------------------------------------------------------
   -- One classic false-position update
   -------------------------------------------------------------------------

   function Next_Point
     (A, B, FA, FB : Real) return Real
   is
      Den : constant Real := FB - FA;
   begin
      if Den = 0.0 then
         raise Invalid_Argument
           with "False position Next_Point: zero denominator";
      end if;
      --  Wikipedia / classical:
      --  c = (a f(b) − b f(a)) / (f(b) − f(a))
      return (A * FB - B * FA) / Den;
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
      Lo, Hi         : Real;
      F_Lo, F_Hi     : Real;
      --  Values used in the interpolation (may be Illinois-halved)
      Use_Lo, Use_Hi : Real;
      Cand           : Real;
      F_Cand         : Real;
      Out_R          : Result;
      Iters          : Natural := 0;
      --  Track which side was retained last: −1 = Lo, +1 = Hi, 0 = none
      Last_Side      : Integer := 0;
      Side           : Integer;
   begin
      if F = null then
         raise Invalid_Argument
           with "False position Find_Root: null objective";
      end if;

      Lo := A;
      Hi := B;
      if Lo > Hi then
         Lo := B;
         Hi := A;
      end if;

      F_Lo := F (Lo);
      F_Hi := F (Hi);
      Use_Lo := F_Lo;
      Use_Hi := F_Hi;

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

         if Use_Hi - Use_Lo = 0.0 then
            Out_R.Root       := Lo;
            Out_R.Iterations := Iters;
            Out_R.Success    := False;
            Out_R.Status     := Degenerate;
            Out_R.Final_F    := F_Lo;
            Out_R.Bracket_A  := Lo;
            Out_R.Bracket_B  := Hi;
            return Out_R;
         end if;

         Cand := Next_Point (Lo, Hi, Use_Lo, Use_Hi);

         --  Guard: candidate should lie in (Lo, Hi); if numerical drift
         --  pushes it outside, fall back to midpoint (rare).
         if Cand <= Lo or else Cand >= Hi then
            Cand := (Lo + Hi) / 2.0;
         end if;

         F_Cand := F (Cand);

         if abs (F_Cand) <= Cfg.Tol then
            Out_R.Root       := Cand;
            Out_R.Iterations := Iters;
            Out_R.Success    := True;
            Out_R.Status     := Ok;
            Out_R.Final_F    := F_Cand;
            Out_R.Bracket_A  := Lo;
            Out_R.Bracket_B  := Hi;
            return Out_R;
         end if;

         --  Replace endpoint to preserve the sign change.
         if F_Lo * F_Cand < 0.0 then
            --  Root in [Lo, Cand]; discard Hi.
            Hi     := Cand;
            F_Hi   := F_Cand;
            Use_Hi := F_Cand;
            Side   := -1;  -- Lo retained
         else
            --  Root in [Cand, Hi]; discard Lo.
            Lo     := Cand;
            F_Lo   := F_Cand;
            Use_Lo := F_Cand;
            Side   := +1;  -- Hi retained
         end if;

         --  Illinois: if the same endpoint is retained again, halve that
         --  endpoint's f value used in the next interpolation; otherwise
         --  restore the genuine f on the newly retained side.
         if Cfg.Illinois then
            if Side = Last_Side then
               if Side < 0 then
                  Use_Lo := Use_Lo / 2.0;
               else
                  Use_Hi := Use_Hi / 2.0;
               end if;
            else
               if Side < 0 then
                  Use_Lo := F_Lo;
               else
                  Use_Hi := F_Hi;
               end if;
            end if;
         end if;
         Last_Side := Side;

         Out_R.Bracket_A := Lo;
         Out_R.Bracket_B := Hi;

         if abs (Hi - Lo) <= Cfg.Tol then
            if abs (F_Lo) <= abs (F_Hi) then
               Out_R.Root    := Lo;
               Out_R.Final_F := F_Lo;
            else
               Out_R.Root    := Hi;
               Out_R.Final_F := F_Hi;
            end if;
            Out_R.Iterations := Iters;
            Out_R.Success    := True;
            Out_R.Status     := Ok;
            return Out_R;
         end if;
      end loop;

      if abs (F_Lo) <= abs (F_Hi) then
         Out_R.Root    := Lo;
         Out_R.Final_F := F_Lo;
      else
         Out_R.Root    := Hi;
         Out_R.Final_F := F_Hi;
      end if;
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
         Tol            => Tol,
         Illinois       => False);
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

   function Wiki_Cos_Cube (X : Real) return Real is
   begin
      return Cos (X) - X * X * X;
   end Wiki_Cos_Cube;

   function Stall_Cubic (X : Real) return Real is
   begin
      return ((2.0 * X - 4.0) * X + 3.0) * X;
   end Stall_Cubic;

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

end False_Position_Method;
