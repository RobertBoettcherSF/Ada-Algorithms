--  Standalone test suite for Newtons_Method (main program).

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Text_IO; use Ada.Text_IO;
with Newtons_Method; use Newtons_Method;

procedure Tests is

   package Elem is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Elem;

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-8) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   Default_Cfg : constant Config := (others => <>);

   Sqrt2 : constant Real := Sqrt (2.0);
   Ln2   : constant Real := Log (2.0);
   Pi    : constant Real := Ada.Numerics.Pi;

begin
   Put_Line ("Newtons_Method test suite");
   Put_Line ("=========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Sign helpers");
   ---------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
   Check (not Near (1.0, 2.0), "Near rejects large delta");
   Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
   Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
   Check (Near (-5.0, -5.0), "Near negatives");
   Check (Near (100.0, 100.0 + 5.0E-11), "Near large magnitude");
   Check (Sign (5.0) = 1.0, "Sign positive");
   Check (Sign (-3.0) = -1.0, "Sign negative");
   Check (Sign (0.0) = 0.0, "Sign zero");
   Check (Sign (Real'Model_Small) = 1.0, "Sign tiny positive");
   Check (Sign (-Real'Model_Small) = -1.0, "Sign tiny negative");
   Check (Sign (1.0E20) = 1.0, "Sign large positive");
   Check (Sign (-1.0E20) = -1.0, "Sign large negative");

   ---------------------------------------------------------------------
   Section ("2. Next_Point (Wikipedia formula)");
   ---------------------------------------------------------------------
   declare
      --  f(x)=x^2-2, x=1, f=−1, f'=2 → x_next = 1 − (−1)/2 = 1.5
      Xn : Real;
   begin
      Xn := Next_Point (1.0, Poly_Quad (1.0), Poly_Quad_Prime (1.0));
      Check (Approx (Xn, 1.5, 1.0E-14), "Next_Point x^2-2 from 1 → 1.5");
   end;

   declare
      --  Linear: from 0, f=−4, f'=2 → 0 − (−4)/2 = 2 (exact root)
      Xn : Real;
   begin
      Xn := Next_Point (0.0, Poly_Linear (0.0), Poly_Linear_Prime (0.0));
      Check (Approx (Xn, 2.0, 1.0E-14), "Next_Point linear exact in 1 step");
   end;

   declare
      --  Damped λ=0.5: from 0 on linear → 0 − 0.5*(−4)/2 = 1
      Xn : Real;
   begin
      Xn := Next_Point
        (0.0, Poly_Linear (0.0), Poly_Linear_Prime (0.0), Damping => 0.5);
      Check (Approx (Xn, 1.0, 1.0E-14), "Next_Point damped λ=0.5");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : Real;
         begin
            Unused := Next_Point (0.0, 1.0, 0.0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Next_Point raises on zero derivative");
   end;

   ---------------------------------------------------------------------
   Section ("3. Find_Root — sqrt via x^2 − a (Heron)");
   ---------------------------------------------------------------------
   declare
      R : Result;
      A : constant Real := Sqrt_Target_A;
   begin
      Check (Approx (A, 612.0, 1.0E-12), "Sqrt_Target_A is 612");

      R := Find_Root
        (Sqrt_Obj'Access, Sqrt_Obj_Prime'Access, 10.0, Default_Cfg);
      Check (R.Success, "sqrt(612) from 10 Success");
      Check (R.Status = Ok, "sqrt(612) Status Ok");
      Check (Approx (R.Root, Sqrt (A), 1.0E-9), "sqrt(612) root");
      Check (Approx (R.Final_F, 0.0, 1.0E-8), "sqrt(612) |f| small");
      Check (R.Iterations > 0, "sqrt(612) nonzero iters");

      R := Find_Root
        (Sqrt_Obj'Access, Sqrt_Obj_Prime'Access, 1.0);
      Check (R.Success, "sqrt(612) from 1 Success");
      Check (Approx (R.Root, Sqrt (A), 1.0E-8), "sqrt(612) from 1 root");

      R := Find_Root
        (Sqrt_Obj'Access, Sqrt_Obj_Prime'Access, -20.0);
      Check (R.Success, "sqrt(612) from −20 Success (neg branch)");
      Check (Approx (R.Root, -Sqrt (A), 1.0E-8), "sqrt(612) neg root");

      R := Find_Root
        (Poly_Quad'Access, Poly_Quad_Prime'Access, 1.0);
      Check (R.Success, "x^2-2 from 1 Success");
      Check (Approx (R.Root, Sqrt2, 1.0E-10), "x^2-2 root ≈ √2");

      R := Find_Root
        (Poly_Quad'Access, Poly_Quad_Prime'Access, -1.0);
      Check (R.Success, "x^2-2 from −1 Success");
      Check (Approx (R.Root, -Sqrt2, 1.0E-10), "x^2-2 root ≈ −√2");
   end;

   ---------------------------------------------------------------------
   Section ("4. Find_Root — polynomials");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Find_Root
        (Poly_Linear'Access, Poly_Linear_Prime'Access, 0.0);
      Check (R.Success, "linear Success");
      Check (R.Status = Ok, "linear Status Ok");
      Check (Approx (R.Root, 2.0, 1.0E-12), "linear root ≈ 2");
      Check (Approx (R.Final_F, 0.0, 1.0E-12), "linear |f| tiny");
      Check (R.Iterations = 1, "linear one Newton step");

      R := Find_Root
        (Poly_Cubic'Access, Poly_Cubic_Prime'Access, 0.5);
      Check (R.Success, "cubic → root 1 Success");
      Check (Approx (R.Root, 1.0, 1.0E-8), "cubic root ≈ 1");

      R := Find_Root
        (Poly_Cubic'Access, Poly_Cubic_Prime'Access, 1.8);
      Check (R.Success, "cubic → root 2 Success");
      Check (Approx (R.Root, 2.0, 1.0E-8), "cubic root ≈ 2");

      R := Find_Root
        (Poly_Cubic'Access, Poly_Cubic_Prime'Access, 3.5);
      Check (R.Success, "cubic → root 3 Success");
      Check (Approx (R.Root, 3.0, 1.0E-8), "cubic root ≈ 3");

      R := Find_Root
        (Cubic_One_Root'Access, Cubic_One_Root_Prime'Access, 1.0);
      Check (R.Success, "x^3-x-1 Success");
      Check (Approx (R.Root, 1.324717957244746, 1.0E-9),
             "x^3-x-1 root ≈ 1.3247");

      R := Find_Root
        (Poly_Shifted'Access, Poly_Shifted_Prime'Access, 1.0);
      Check (R.Success, "shifted → 0.5 Success");
      Check (Approx (R.Root, 0.5, 1.0E-10), "shifted root ≈ 0.5");

      R := Find_Root
        (Poly_Shifted'Access, Poly_Shifted_Prime'Access, -2.0);
      Check (R.Success, "shifted → −3 Success");
      Check (Approx (R.Root, -3.0, 1.0E-10), "shifted root ≈ −3");
   end;

   ---------------------------------------------------------------------
   Section ("5. Find_Root — trig / exp / Wikipedia cos−x³");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Find_Root
        (Sin_Fn'Access, Sin_Fn_Prime'Access, 3.0);
      Check (R.Success, "sin from 3 Success");
      Check (Approx (R.Root, Pi, 1.0E-9), "sin root ≈ π");

      R := Find_Root
        (Sin_Fn'Access, Sin_Fn_Prime'Access, 0.1);
      Check (R.Success, "sin from 0.1 Success");
      Check (Approx (R.Root, 0.0, 1.0E-10), "sin root ≈ 0");

      R := Find_Root
        (Cos_Fn'Access, Cos_Fn_Prime'Access, 1.0);
      Check (R.Success, "cos Success");
      Check (Approx (R.Root, Pi / 2.0, 1.0E-9), "cos root ≈ π/2");

      R := Find_Root
        (Exp_Linear'Access, Exp_Linear_Prime'Access, 1.0);
      Check (R.Success, "exp−2 Success");
      Check (Approx (R.Root, Ln2, 1.0E-10), "exp−2 root ≈ ln 2");

      R := Find_Root
        (Atan_Shift'Access, Atan_Shift_Prime'Access, 1.0);
      Check (R.Success, "atan−0.5 Success");
      Check (Approx (R.Final_F, 0.0, 1.0E-9), "atan−0.5 |f| small");
      Check (R.Root > 0.0 and then R.Root < 1.0, "atan−0.5 root in (0,1)");

      R := Find_Root
        (Steep_Exp'Access, Steep_Exp_Prime'Access, 0.5);
      Check (R.Success, "exp(x)−e Success");
      Check (Approx (R.Root, 1.0, 1.0E-10), "exp(x)−e root ≈ 1");

      R := Find_Root
        (Cos_Minus_X3'Access, Cos_Minus_X3_Prime'Access, 0.5);
      Check (R.Success, "cos−x³ Success");
      Check (Approx (R.Root, 0.865474033101614, 1.0E-8),
             "cos−x³ root ≈ 0.865474");
      Check (Approx (R.Final_F, 0.0, 1.0E-9), "cos−x³ |f| small");
   end;

   ---------------------------------------------------------------------
   Section ("6. Derivative-zero / Degenerate rejection");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      --  f(x)=x²−1, start at x=0 where f'=0.
      R := Find_Root
        (Flat_Derivative'Access, Flat_Derivative_Prime'Access, 0.0);
      Check (not R.Success, "flat deriv at 0 not Success");
      Check (R.Status = Degenerate, "flat deriv Degenerate");
      Check (Approx (R.Root, 0.0, 1.0E-14), "flat deriv stays at 0");

      R := Find_Root
        (Constant_One'Access, Constant_One_Prime'Access, 5.0);
      Check (not R.Success, "constant+zero-deriv not Success");
      Check (R.Status = Degenerate, "constant Degenerate");

      --  Same f but good start → converges to ±1.
      R := Find_Root
        (Flat_Derivative'Access, Flat_Derivative_Prime'Access, 0.5);
      Check (R.Success, "x²−1 from 0.5 Success");
      Check (Approx (R.Root, 1.0, 1.0E-10), "x²−1 root ≈ 1");

      R := Find_Root
        (Flat_Derivative'Access, Flat_Derivative_Prime'Access, -0.5);
      Check (R.Success, "x²−1 from −0.5 Success");
      Check (Approx (R.Root, -1.0, 1.0E-10), "x²−1 root ≈ −1");

      --  Poly_Quad at x=0 also has f'=0.
      R := Find_Root
        (Poly_Quad'Access, Poly_Quad_Prime'Access, 0.0);
      Check (not R.Success, "x²−2 at 0 not Success");
      Check (R.Status = Degenerate, "x²−2 at 0 Degenerate");
   end;

   ---------------------------------------------------------------------
   Section ("7. Exact start / already at root");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Find_Root
        (Poly_Linear'Access, Poly_Linear_Prime'Access, 2.0);
      Check (R.Success, "start at root Success");
      Check (Approx (R.Root, 2.0, 1.0E-14), "start at root value");
      Check (R.Iterations = 0, "start at root zero iters");
      Check (R.Status = Ok, "start at root Ok");

      R := Find_Root
        (Sin_Fn'Access, Sin_Fn_Prime'Access, 0.0);
      Check (R.Success, "sin(0) already root");
      Check (R.Iterations = 0, "sin(0) zero iters");
   end;

   ---------------------------------------------------------------------
   Section ("8. Config overload / damping / safeguard");
   ---------------------------------------------------------------------
   declare
      R   : Result;
      Cfg : Config;
   begin
      R := Find_Root
        (Poly_Quad'Access, Poly_Quad_Prime'Access, 1.5,
         Tol => 1.0E-12, Max_Iterations => 50);
      Check (R.Success, "overload Success");
      Check (Approx (R.Root, Sqrt2, 1.0E-11), "overload tight Tol");

      Cfg :=
        (Max_Iterations => 80,
         Tol            => 1.0E-14,
         Min_Derivative => 1.0E-14,
         Damping        => 1.0,
         Use_Safeguard  => False);
      R := Find_Root
        (Exp_Linear'Access, Exp_Linear_Prime'Access, 0.0, Cfg);
      Check (R.Success, "tight config Success");
      Check (Approx (R.Root, Ln2, 1.0E-12), "tight config ln2");

      Cfg.Damping := 0.5;
      R := Find_Root
        (Poly_Linear'Access, Poly_Linear_Prime'Access, 0.0, Cfg);
      Check (R.Success, "damped λ=0.5 linear Success");
      Check (Approx (R.Root, 2.0, 1.0E-9), "damped linear root");
      Check (R.Iterations >= 2, "damped needs ≥2 steps vs 1 undamped");

      Cfg := Default_Cfg;
      Cfg.Use_Safeguard := True;
      R := Find_Root
        (Poly_Quad'Access, Poly_Quad_Prime'Access, 2.0, Cfg);
      Check (R.Success, "safeguard Success");
      Check (Approx (R.Root, Sqrt2, 1.0E-9), "safeguard root √2");

      Cfg.Damping := 0.75;
      Cfg.Use_Safeguard := True;
      R := Find_Root
        (Cubic_One_Root'Access, Cubic_One_Root_Prime'Access, 1.5, Cfg);
      Check (R.Success, "damped+safeguard cubic Success");
      Check (Approx (R.Root, 1.324717957244746, 1.0E-7),
             "damped+safeguard cubic root");
   end;

   ---------------------------------------------------------------------
   Section ("9. Max iterations / tiny budgets");
   ---------------------------------------------------------------------
   declare
      R    : Result;
      Tiny : constant Config :=
        (Max_Iterations => 1,
         Tol            => 1.0E-30,
         Min_Derivative => 1.0E-14,
         Damping        => 1.0,
         Use_Safeguard  => False);
   begin
      R := Find_Root
        (Cubic_One_Root'Access, Cubic_One_Root_Prime'Access, 0.5, Tiny);
      Check (R.Status = Ok
             or else R.Status = Max_Iterations_Reached
             or else R.Status = Degenerate,
             "tiny budget status is terminal");
      Check (R.Iterations <= 1, "tiny budget iters ≤ 1");

      R := Find_Root
        (Sin_Fn'Access, Sin_Fn_Prime'Access, 3.0,
         Cfg => (Max_Iterations => 100,
                 Tol            => 1.0E-14,
                 Min_Derivative => 1.0E-14,
                 Damping        => 1.0,
                 Use_Safeguard  => False));
      Check (R.Success, "sin tight Success");
      Check (abs (R.Final_F) <= 1.0E-12, "sin tight |f|");
   end;

   ---------------------------------------------------------------------
   Section ("10. Sample objective sanity");
   ---------------------------------------------------------------------
   Check (Approx (Poly_Linear (2.0), 0.0, 1.0E-14), "Poly_Linear(2)=0");
   Check (Approx (Poly_Linear_Prime (99.0), 2.0, 1.0E-14),
          "Poly_Linear_Prime=2");
   Check (Approx (Poly_Quad (Sqrt2), 0.0, 1.0E-12), "Poly_Quad(√2)=0");
   Check (Approx (Poly_Cubic (1.0), 0.0, 1.0E-14), "Poly_Cubic(1)=0");
   Check (Approx (Poly_Cubic (2.0), 0.0, 1.0E-14), "Poly_Cubic(2)=0");
   Check (Approx (Poly_Cubic (3.0), 0.0, 1.0E-14), "Poly_Cubic(3)=0");
   Check (Approx (Poly_Shifted (0.5), 0.0, 1.0E-14), "Poly_Shifted(0.5)=0");
   Check (Approx (Sin_Fn (0.0), 0.0, 1.0E-14), "Sin(0)=0");
   Check (Approx (Sin_Fn_Prime (0.0), 1.0, 1.0E-14), "Sin'(0)=1");
   Check (Approx (Cos_Fn_Prime (0.0), 0.0, 1.0E-14), "Cos'(0)=0");
   Check (Approx (Exp_Linear (Ln2), 0.0, 1.0E-12), "Exp_Linear(ln2)=0");
   Check (Approx (Steep_Exp (1.0), 0.0, 1.0E-12), "Steep_Exp(1)=0");
   Check (Approx (Flat_Derivative (1.0), 0.0, 1.0E-14),
          "Flat_Derivative(1)=0");
   Check (Approx (Flat_Derivative_Prime (0.0), 0.0, 1.0E-14),
          "Flat_Derivative_Prime(0)=0");
   Check (Approx (Constant_One (7.0), 1.0, 1.0E-14), "Constant_One=1");
   Check (Approx (Constant_One_Prime (7.0), 0.0, 1.0E-14),
          "Constant_One_Prime=0");

   ---------------------------------------------------------------------
   Section ("11. Many known roots (batch)");
   ---------------------------------------------------------------------
   declare
      type Case_Rec is record
         X0, Expected : Real;
      end record;
      Cases : constant array (Positive range <>) of Case_Rec :=
        [(1.0, Sqrt2),
         (-1.0, -Sqrt2),
         (0.0, 2.0),
         (0.5, 1.0),
         (1.7, 2.0),
         (3.2, 3.0),
         (1.0, 1.324717957244746),
         (0.8, 0.5),
         (-2.5, -3.0),
         (0.2, 0.0),
         (2.8, Pi),
         (1.2, Pi / 2.0),
         (0.8, Ln2),
         (0.0, 1.0),
         (0.6, 0.865474033101614),
         (10.0, Sqrt (Sqrt_Target_A)),
         (0.8, 1.0),
         (-0.8, -1.0)];
      Fns : constant array (Cases'Range) of Objective_Fn :=
        [Poly_Quad'Access,
         Poly_Quad'Access,
         Poly_Linear'Access,
         Poly_Cubic'Access,
         Poly_Cubic'Access,
         Poly_Cubic'Access,
         Cubic_One_Root'Access,
         Poly_Shifted'Access,
         Poly_Shifted'Access,
         Sin_Fn'Access,
         Sin_Fn'Access,
         Cos_Fn'Access,
         Exp_Linear'Access,
         Steep_Exp'Access,
         Cos_Minus_X3'Access,
         Sqrt_Obj'Access,
         Flat_Derivative'Access,
         Flat_Derivative'Access];
      DFns : constant array (Cases'Range) of Derivative_Fn :=
        [Poly_Quad_Prime'Access,
         Poly_Quad_Prime'Access,
         Poly_Linear_Prime'Access,
         Poly_Cubic_Prime'Access,
         Poly_Cubic_Prime'Access,
         Poly_Cubic_Prime'Access,
         Cubic_One_Root_Prime'Access,
         Poly_Shifted_Prime'Access,
         Poly_Shifted_Prime'Access,
         Sin_Fn_Prime'Access,
         Sin_Fn_Prime'Access,
         Cos_Fn_Prime'Access,
         Exp_Linear_Prime'Access,
         Steep_Exp_Prime'Access,
         Cos_Minus_X3_Prime'Access,
         Sqrt_Obj_Prime'Access,
         Flat_Derivative_Prime'Access,
         Flat_Derivative_Prime'Access];
      R : Result;
   begin
      for I in Cases'Range loop
         R := Find_Root (Fns (I), DFns (I), Cases (I).X0);
         Check (R.Success,
                "batch" & Integer'Image (I) & " Success");
         Check (Approx (R.Root, Cases (I).Expected, 1.0E-7),
                "batch" & Integer'Image (I) & " root");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("12. Status / Success invariants");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Find_Root
        (Poly_Quad'Access, Poly_Quad_Prime'Access, 3.0);
      Check (R.Success, "invariants Success");
      Check (R.Status = Ok, "invariants Status Ok");
      Check (R.Success = (R.Status = Ok), "Success iff Ok");
      Check (abs (R.Final_F) <= 1.0E-9, "invariants |f|");
      Check (R.Iterations > 0, "invariants nonzero iters");

      R := Find_Root
        (Constant_One'Access, Constant_One_Prime'Access, 0.0);
      Check (not R.Success, "fail invariants not Success");
      Check (R.Status = Degenerate, "fail invariants Degenerate");
      Check (R.Success = False, "fail Success False");
   end;

   New_Line;
   Put_Line ("================================");
   Put_Line ("Pass_Count =" & Natural'Image (Pass_Count));
   Put_Line ("Fail_Count =" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;
end Tests;
