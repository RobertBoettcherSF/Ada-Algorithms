--  Ridders_Method body — Wikipedia Ridders' method implementation.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Ridders_Method
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
   -- One Wikipedia update for x₃
   -------------------------------------------------------------------------

   function Next_Point
     (X0, X2     : Real;
      F0, F1, F2 : Real) return Real
   is
      X1   : constant Real := (X0 + X2) / 2.0;
      Disc : Real;
      Den  : Real;
   begin
      Disc := F1 * F1 - F0 * F2;
      if Disc <= 0.0 then
         raise Invalid_Argument
           with "Ridders Next_Point: non-positive discriminant";
      end if;
      Den := Sqrt (Disc);
      if Den = 0.0 then
         raise Invalid_Argument
           with "Ridders Next_Point: zero denominator";
      end if;
      --  Wikipedia:
      --  x₃ = x₁ + (x₁ − x₀) · sign(f(x₀)) · f(x₁) / √(f(x₁)² − f(x₀)f(x₂))
      return X1 + (X1 - X0) * (Sign (F0) * F1) / Den;
   end Next_Point;

   -------------------------------------------------------------------------
   -- Re-bracket after evaluating f at candidate D = x₃ and midpoint C
   -------------------------------------------------------------------------

   procedure Update_Bracket
     (A, B   : in out Real;
      FA, FB : in out Real;
      C, D   : Real;
      FC, FD : Real)
   is
   begin
      --  Prefer the well-behaved case: root between C and D.
      if FC * FD < 0.0 then
         A  := C;
         FA := FC;
         B  := D;
         FB := FD;
      elsif FA * FD < 0.0 then
         B  := D;
         FB := FD;
      else
         A  := D;
         FA := FD;
      end if;

      --  Keep A < B for a stable interval representation.
      if A > B then
         declare
            T  : constant Real := A;
            TF : constant Real := FA;
         begin
            A  := B;
            FA := FB;
            B  := T;
            FB := TF;
         end;
      end if;
   end Update_Bracket;

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
      Mid, Cand      : Real;
      F_Mid, F_Cand  : Real;
      Out_R          : Result;
      Iters          : Natural := 0;
   begin
      if F = null then
         raise Invalid_Argument with "Ridders Find_Root: null objective";
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

         Mid   := (Lo + Hi) / 2.0;
         F_Mid := F (Mid);

         if abs (F_Mid) <= Cfg.Tol
           or else abs (Hi - Lo) / 2.0 <= Cfg.Tol
         then
            Out_R.Root       := Mid;
            Out_R.Iterations := Iters;
            Out_R.Success    := True;
            Out_R.Status     := Ok;
            Out_R.Final_F    := F_Mid;
            Out_R.Bracket_A  := Lo;
            Out_R.Bracket_B  := Hi;
            return Out_R;
         end if;

         declare
            Disc : constant Real := F_Mid * F_Mid - F_Lo * F_Hi;
         begin
            if Disc <= 0.0 then
               Out_R.Root       := Mid;
               Out_R.Iterations := Iters;
               Out_R.Success    := False;
               Out_R.Status     := Degenerate;
               Out_R.Final_F    := F_Mid;
               Out_R.Bracket_A  := Lo;
               Out_R.Bracket_B  := Hi;
               return Out_R;
            end if;
         end;

         Cand   := Next_Point (Lo, Hi, F_Lo, F_Mid, F_Hi);
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

         Update_Bracket (Lo, Hi, F_Lo, F_Hi, Mid, Cand, F_Mid, F_Cand);

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
        (Max_Iterations => Max_Iterations, Tol => Tol);
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

end Ridders_Method;
