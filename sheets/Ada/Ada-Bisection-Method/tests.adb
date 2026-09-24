--  Standalone test suite for Bisection_Method (main program).

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Text_IO; use Ada.Text_IO;
with Bisection_Method; use Bisection_Method;

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

   Default_Cfg : constant Config :=
     (Max_Iterations => 100, Tol => 1.0E-10);

   Sqrt2 : constant Real := Sqrt (2.0);
   Ln2   : constant Real := Log (2.0);
   Pi    : constant Real := Ada.Numerics.Pi;

   --  Wikipedia bisection example: x³ − x − 2 = 0 on [1,2]
   Wiki_Root : constant Real := 1.5213797068045676;

begin
   Put_Line ("Bisection_Method test suite");
   Put_Line ("===========================");

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
   Section ("2. Bracket_Valid");
   ---------------------------------------------------------------------
   Check (Bracket_Valid (0.5, 1.5, Poly_Cubic'Access),
          "Bracket_Valid cubic [0.5,1.5]");
   Check (Bracket_Valid (0.0, 4.0, Poly_Linear'Access),
          "Bracket_Valid linear [0,4]");
   Check (Bracket_Valid (0.0, 2.0, Poly_Quad'Access),
          "Bracket_Valid x^2-2 [0,2]");
   Check (Bracket_Valid (-2.0, 0.0, Poly_Quad'Access),
          "Bracket_Valid x^2-2 [-2,0]");
   Check (not Bracket_Valid (0.0, 0.5, Poly_Quad'Access),
          "Bracket_Valid rejects same-sign [0,0.5]");
   Check (not Bracket_Valid (1.0, 1.0, Poly_Linear'Access),
          "Bracket_Valid rejects A=B");
   Check (not Bracket_Valid (-1.0, 1.0, Always_Positive'Access),
          "Bracket_Valid rejects always-positive");
   Check (not Bracket_Valid (-1.0, 1.0, Always_Negative'Access),
          "Bracket_Valid rejects always-negative");
   Check (not Bracket_Valid (0.0, 1.0, Same_Sign_Ends'Access),
          "Bracket_Valid rejects x^2+1");
   Check (Bracket_Valid (2.0, 0.0, Poly_Quad'Access),
          "Bracket_Valid unordered endpoints");
   Check (not Bracket_Valid (0.0, Pi, Sin_Fn'Access),
          "Bracket_Valid sin endpoints zeros (product not < 0)");
   Check (Bracket_Valid (2.0, 4.0, Sin_Fn'Access),
          "Bracket_Valid sin [2,4]");
   Check (Bracket_Valid (0.0, 2.0, Cos_Fn'Access),
          "Bracket_Valid cos [0,2]");
   Check (Bracket_Valid (0.0, 1.0, Poly_Shifted'Access),
          "Bracket_Valid shifted [0,1]");
   Check (Bracket_Valid (1.0, 2.0, Wiki_Cubic'Access),
          "Bracket_Valid wiki cubic [1,2]");

   ---------------------------------------------------------------------
   Section ("3. Next_Point / Iterations_Needed");
   ---------------------------------------------------------------------
   declare
      C : Real;
   begin
      C := Next_Point (0.0, 4.0);
      Check (Approx (C, 2.0, 1.0E-14), "Next_Point mid [0,4]");
      C := Next_Point (-2.0, 2.0);
      Check (Approx (C, 0.0, 1.0E-14), "Next_Point mid [-2,2]");
      C := Next_Point (1.0, 2.0);
      Check (Approx (C, 1.5, 1.0E-14), "Next_Point mid [1,2]");
      Check (Next_Point (3.0, 0.0) = Next_Point (0.0, 3.0),
             "Next_Point commutative");
   end;

   Check (Iterations_Needed (0.0, 1.0, 1.0) = 0,
          "Iterations_Needed width <= Tol => 0");
   Check (Iterations_Needed (0.0, 1.0, 0.5) = 1,
          "Iterations_Needed [0,1]/0.5 = 1");
   Check (Iterations_Needed (0.0, 1.0, 0.25) = 2,
          "Iterations_Needed [0,1]/0.25 = 2");
   Check (Iterations_Needed (0.0, 8.0, 1.0) = 3,
          "Iterations_Needed [0,8]/1 = 3");
   Check (Iterations_Needed (1.0, 2.0, 1.0E-3) >= 10,
          "Iterations_Needed wiki-scale >= 10");
   Check (Iterations_Needed (-1.0, 1.0, 1.0E-10) > 30,
          "Iterations_Needed wide/tight large");
   Check (Iterations_Needed (0.0, 1.0E-12, 1.0E-10) = 0,
          "Iterations_Needed already tight");

   ---------------------------------------------------------------------
   Section ("4. Find_Root — polynomials");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Find_Root (Poly_Linear'Access, 0.0, 5.0, Default_Cfg);
      Check (R.Success, "linear Success");
      Check (R.Status = Ok, "linear Status Ok");
      Check (Approx (R.Root, 2.0, 1.0E-9), "linear root ≈ 2");
      Check (Approx (R.Final_F, 0.0, 1.0E-9), "linear |f| small");

      R := Find_Root (Poly_Quad'Access, 0.0, 3.0);
      Check (R.Success, "quad+ Success");
      Check (Approx (R.Root, Sqrt2, 1.0E-9), "quad+ root ≈ √2");

      R := Find_Root (Poly_Quad'Access, -3.0, 0.0);
      Check (R.Success, "quad- Success");
      Check (Approx (R.Root, -Sqrt2, 1.0E-9), "quad- root ≈ −√2");

      R := Find_Root (Poly_Cubic'Access, 0.0, 1.5);
      Check (R.Success, "cubic root 1 Success");
      Check (Approx (R.Root, 1.0, 1.0E-8), "cubic root ≈ 1");

      R := Find_Root (Poly_Cubic'Access, 1.5, 2.5);
      Check (R.Success, "cubic root 2 Success");
      Check (Approx (R.Root, 2.0, 1.0E-8), "cubic root ≈ 2");

      R := Find_Root (Poly_Cubic'Access, 2.5, 4.0);
      Check (R.Success, "cubic root 3 Success");
      Check (Approx (R.Root, 3.0, 1.0E-8), "cubic root ≈ 3");

      R := Find_Root (Cubic_One_Root'Access, 1.0, 2.0);
      Check (R.Success, "x^3-x-1 Success");
      Check (Approx (R.Root, 1.324717957244746, 1.0E-8),
             "x^3-x-1 root ≈ 1.3247");

      R := Find_Root (Poly_Shifted'Access, 0.0, 1.0);
      Check (R.Success, "shifted Success");
      Check (Approx (R.Root, 0.5, 1.0E-9), "shifted root ≈ 0.5");

      R := Find_Root (Poly_Shifted'Access, -4.0, 0.0);
      Check (R.Success, "shifted neg Success");
      Check (Approx (R.Root, -3.0, 1.0E-9), "shifted root ≈ −3");
   end;

   ---------------------------------------------------------------------
   Section ("5. Find_Root — trig / exp / wiki");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Find_Root (Sin_Fn'Access, 2.0, 4.0);
      Check (R.Success, "sin [2,4] Success");
      Check (Approx (R.Root, Pi, 1.0E-9), "sin root ≈ π");

      R := Find_Root (Cos_Fn'Access, 0.0, 2.0);
      Check (R.Success, "cos Success");
      Check (Approx (R.Root, Pi / 2.0, 1.0E-9), "cos root ≈ π/2");

      R := Find_Root (Exp_Linear'Access, 0.0, 2.0);
      Check (R.Success, "exp-2 Success");
      Check (Approx (R.Root, Ln2, 1.0E-9), "exp-2 root ≈ ln 2");

      R := Find_Root (Atan_Shift'Access, 0.0, 2.0);
      Check (R.Success, "atan-0.5 Success");
      Check (Approx (R.Final_F, 0.0, 1.0E-8), "atan-0.5 |f| small");
      Check (R.Root > 0.0 and then R.Root < 1.0, "atan-0.5 root in (0,1)");

      R := Find_Root (Steep_Exp'Access, 0.0, 3.0);
      Check (R.Success, "exp(x)-e Success");
      Check (Approx (R.Root, 1.0, 1.0E-9), "exp(x)-e root ≈ 1");

      R := Find_Root (Sin_Fn'Access, -0.5, 0.5);
      Check (R.Success, "sin near 0 Success");
      Check (Approx (R.Root, 0.0, 1.0E-9), "sin root ≈ 0");

      R := Find_Root (Wiki_Cubic'Access, 1.0, 2.0);
      Check (R.Success, "wiki cubic Success");
      Check (Approx (R.Root, Wiki_Root, 1.0E-8),
             "wiki cubic root ≈ 1.52138");
   end;

   ---------------------------------------------------------------------
   Section ("6. Invalid brackets rejected");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Find_Root (Always_Positive'Access, -1.0, 1.0);
      Check (not R.Success, "always+ not Success");
      Check (R.Status = Invalid_Bracket, "always+ Invalid_Bracket");

      R := Find_Root (Always_Negative'Access, -5.0, 5.0);
      Check (not R.Success, "always- not Success");
      Check (R.Status = Invalid_Bracket, "always- Invalid_Bracket");

      R := Find_Root (Same_Sign_Ends'Access, -2.0, 2.0);
      Check (not R.Success, "x^2+1 not Success");
      Check (R.Status = Invalid_Bracket, "x^2+1 Invalid_Bracket");

      R := Find_Root (Poly_Quad'Access, 0.0, 1.0);
      Check (not R.Success, "quad [0,1] same sign rejected");
      Check (R.Status = Invalid_Bracket, "quad [0,1] Invalid_Bracket");

      R := Find_Root (Poly_Linear'Access, 3.0, 3.0);
      Check (not R.Success, "A=B rejected");
      Check (R.Status = Invalid_Bracket, "A=B Invalid_Bracket");

      R := Find_Root (Poly_Cubic'Access, 1.1, 1.9);
      Check (not R.Success, "cubic between roots no sign change");
      Check (R.Status = Invalid_Bracket, "cubic gap Invalid_Bracket");
   end;

   ---------------------------------------------------------------------
   Section ("7. Endpoint / exact hits");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Find_Root (Poly_Linear'Access, 2.0, 5.0);
      Check (R.Success, "endpoint A is root");
      Check (Approx (R.Root, 2.0, 1.0E-12), "endpoint A value");
      Check (R.Iterations = 0, "endpoint A zero iters");

      R := Find_Root (Poly_Linear'Access, 0.0, 2.0);
      Check (R.Success, "endpoint B is root");
      Check (Approx (R.Root, 2.0, 1.0E-12), "endpoint B value");

      R := Find_Root (Flat_Zero'Access, -1.0, 1.0);
      Check (R.Success, "flat zero Success (endpoint)");
      Check (Approx (R.Final_F, 0.0, 1.0E-14), "flat zero f=0");
   end;

   ---------------------------------------------------------------------
   Section ("8. Unordered brackets / config overload");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Find_Root (Poly_Quad'Access, 3.0, 0.0);
      Check (R.Success, "unordered [3,0] Success");
      Check (Approx (R.Root, Sqrt2, 1.0E-9), "unordered root √2");

      R := Find_Root
        (Poly_Quad'Access, 0.0, 3.0, Tol => 1.0E-12, Max_Iterations => 80);
      Check (R.Success, "overload Success");
      Check (Approx (R.Root, Sqrt2, 1.0E-11), "overload tight Tol");

      R := Find_Root
        (Exp_Linear'Access, 0.0, 1.0,
         Cfg => (Max_Iterations => 80, Tol => 1.0E-14));
      Check (R.Success, "tight config Success");
      Check (Approx (R.Root, Ln2, 1.0E-12), "tight config ln2");
   end;

   ---------------------------------------------------------------------
   Section ("9. Bracket shrink guarantee");
   ---------------------------------------------------------------------
   declare
      R          : Result;
      Init_Width : constant Real := 5.0;
      Cfg        : constant Config :=
        (Max_Iterations => 100, Tol => 1.0E-10);
   begin
      R := Find_Root (Poly_Quad'Access, 0.0, Init_Width, Cfg);
      Check (R.Success, "shrink Success");
      Check (R.Bracket_B - R.Bracket_A < Init_Width,
             "final bracket narrower than initial");
      Check ((R.Bracket_B - R.Bracket_A) / 2.0 < Cfg.Tol
             or else abs (R.Final_F) < Cfg.Tol,
             "half-width or |f| within Tol");
      Check (R.Bracket_A <= R.Root and then R.Root <= R.Bracket_B,
             "root inside final bracket");
      Check (R.Iterations > 0, "nonzero iters for interior root");
      Check (R.Iterations <= Iterations_Needed (0.0, Init_Width, Cfg.Tol) + 2,
             "iters near Iterations_Needed estimate");
      Check (R.Status = Ok, "shrink Status Ok");
   end;

   ---------------------------------------------------------------------
   Section ("10. Max iterations / tight budgets");
   ---------------------------------------------------------------------
   declare
      R    : Result;
      Tiny : constant Config :=
        (Max_Iterations => 1, Tol => 1.0E-30);
   begin
      R := Find_Root (Poly_Cubic'Access, 0.5, 1.5, Tiny);
      Check (R.Status = Ok or else R.Status = Max_Iterations_Reached
             or else R.Status = Degenerate,
             "tiny budget status is terminal");
      Check (R.Iterations <= 1, "tiny budget iters ≤ 1");

      R := Find_Root
        (Sin_Fn'Access, 2.0, 4.0,
         Cfg => (Max_Iterations => 100, Tol => 1.0E-14));
      Check (R.Success, "sin tight Success");
      Check (abs (R.Final_F) <= 1.0E-12
             or else (R.Bracket_B - R.Bracket_A) / 2.0 < 1.0E-14,
             "sin tight |f| or half-width");
   end;

   ---------------------------------------------------------------------
   Section ("11. Many known roots (batch)");
   ---------------------------------------------------------------------
   declare
      type Case_Rec is record
         Lo, Hi, Expected : Real;
      end record;
      Cases : constant array (Positive range <>) of Case_Rec :=
        [(0.0, 3.0, Sqrt2),
         (-3.0, 0.0, -Sqrt2),
         (0.5, 1.5, 1.0),
         (1.5, 2.5, 2.0),
         (2.5, 3.5, 3.0),
         (0.0, 2.0, Ln2),
         (0.0, 2.0, Pi / 2.0),
         (2.5, 3.5, Pi),
         (0.5, 2.0, 1.0),
         (-1.0, 3.0, 2.0),
         (0.0, 1.0, 0.5),
         (-5.0, -1.0, -3.0),
         (1.0, 2.0, Wiki_Root)];
      Fns : constant array (Cases'Range) of Objective_Fn :=
        [Poly_Quad'Access,
         Poly_Quad'Access,
         Poly_Cubic'Access,
         Poly_Cubic'Access,
         Poly_Cubic'Access,
         Exp_Linear'Access,
         Cos_Fn'Access,
         Sin_Fn'Access,
         Steep_Exp'Access,
         Poly_Linear'Access,
         Poly_Shifted'Access,
         Poly_Shifted'Access,
         Wiki_Cubic'Access];
      R : Result;
   begin
      for I in Cases'Range loop
         R := Find_Root (Fns (I), Cases (I).Lo, Cases (I).Hi);
         Check (R.Success,
                "batch" & Integer'Image (I) & " Success");
         Check (Approx (R.Root, Cases (I).Expected, 1.0E-7),
                "batch" & Integer'Image (I) & " root");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("12. Sign / Bracket_Valid edge matrix");
   ---------------------------------------------------------------------
   Check (Sign (Poly_Linear (0.0)) = -1.0, "Sign f(0) linear");
   Check (Sign (Poly_Linear (2.0)) = 0.0, "Sign f(2) linear");
   Check (Sign (Poly_Linear (3.0)) = 1.0, "Sign f(3) linear");
   Check (Bracket_Valid (-10.0, 10.0, Poly_Linear'Access),
          "wide linear bracket");
   Check (Bracket_Valid (1.9, 2.1, Poly_Linear'Access),
          "narrow linear bracket");
   Check (not Bracket_Valid (2.1, 3.0, Poly_Linear'Access),
          "right of root no bracket");
   Check (not Bracket_Valid (0.0, 1.9, Poly_Linear'Access),
          "left of root no bracket");
   Check (Bracket_Valid (-0.5, 0.5, Sin_Fn'Access),
          "sin brackets zero");
   Check (Sign (0.0) = 0.0, "Sign zero again");
   Check (Bracket_Valid (1.0, 2.0, Cubic_One_Root'Access),
          "cubic-one bracket");
   Check (Bracket_Valid (0.0, 3.0, Steep_Exp'Access),
          "steep-exp bracket");
   Check (not Bracket_Valid (2.0, 4.0, Steep_Exp'Access),
          "steep-exp same-sign rejected");

   ---------------------------------------------------------------------
   Section ("13. Half-width monotonicity sample");
   ---------------------------------------------------------------------
   declare
      R1, R2 : Result;
      Cfg1 : constant Config := (Max_Iterations => 20, Tol => 1.0E-3);
      Cfg2 : constant Config := (Max_Iterations => 60, Tol => 1.0E-8);
   begin
      R1 := Find_Root (Wiki_Cubic'Access, 1.0, 2.0, Cfg1);
      R2 := Find_Root (Wiki_Cubic'Access, 1.0, 2.0, Cfg2);
      Check (R1.Success, "coarse wiki Success");
      Check (R2.Success, "fine wiki Success");
      Check (R2.Bracket_B - R2.Bracket_A
             <= R1.Bracket_B - R1.Bracket_A + 1.0E-12,
             "tighter Tol => not wider bracket");
      Check (Approx (R2.Root, Wiki_Root, 1.0E-7), "fine wiki root");
      Check (R2.Iterations >= R1.Iterations
             or else abs (R2.Final_F) < abs (R1.Final_F) + 1.0E-12,
             "fine run uses more work or smaller |f|");
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
