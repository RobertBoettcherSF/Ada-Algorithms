--  Standalone test suite for Ridders_Method (main program).

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Text_IO; use Ada.Text_IO;
with Ridders_Method; use Ridders_Method;

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
   Sqrt5 : constant Real := Sqrt (5.0);
   Ln2   : constant Real := Log (2.0);
   Pi    : constant Real := Ada.Numerics.Pi;

begin
   Put_Line ("Ridders_Method test suite");
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

   ---------------------------------------------------------------------
   Section ("3. Next_Point (Wikipedia formula)");
   ---------------------------------------------------------------------
   declare
      X0 : constant Real := 0.0;
      X2 : constant Real := 2.0;
      F0 : constant Real := Poly_Quad (X0);  -- -2
      F1 : constant Real := Poly_Quad (1.0); -- -1
      F2 : constant Real := Poly_Quad (X2);  --  2
      D  : Real;
      Expected : constant Real := 1.0 + 1.0 / Sqrt5;
   begin
      D := Next_Point (X0, X2, F0, F1, F2);
      Check (Approx (D, Expected, 1.0E-12),
             "Next_Point x^2-2 on [0,2]");
      Check (D > X0 and then D < X2, "Next_Point interior");
      Check (Approx (Sign (F0), -1.0), "Next_Point setup sign f0");
   end;

   declare
      X0 : constant Real := 0.0;
      X2 : constant Real := 4.0;
      F0 : constant Real := Poly_Linear (X0);
      F1 : constant Real := Poly_Linear (2.0);
      F2 : constant Real := Poly_Linear (X2);
      D  : Real;
   begin
      D := Next_Point (X0, X2, F0, F1, F2);
      Check (Approx (D, 2.0, 1.0E-14), "Next_Point linear mid is root");
   end;

   declare
      X0 : constant Real := 2.0;
      X2 : constant Real := 0.0;
      F0 : constant Real := Poly_Quad (X0);
      F1 : constant Real := Poly_Quad (1.0);
      F2 : constant Real := Poly_Quad (X2);
      D  : Real;
   begin
      D := Next_Point (X0, X2, F0, F1, F2);
      Check (D > 0.0 and then D < 2.0, "Next_Point reverse bracket interior");
   end;

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
      Check (R.Status = Ok and then R.Success, "linear ok+success");

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
   Section ("5. Find_Root — trig / exp");
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
        (Poly_Quad'Access, 0.0, 3.0, Tol => 1.0E-12, Max_Iterations => 50);
      Check (R.Success, "overload Success");
      Check (Approx (R.Root, Sqrt2, 1.0E-11), "overload tight Tol");

      R := Find_Root
        (Exp_Linear'Access, 0.0, 1.0,
         Cfg => (Max_Iterations => 80, Tol => 1.0E-14));
      Check (R.Success, "tight config Success");
      Check (Approx (R.Root, Ln2, 1.0E-12), "tight config ln2");
   end;

   ---------------------------------------------------------------------
   Section ("9. Max iterations / tight budgets");
   ---------------------------------------------------------------------
   declare
      R    : Result;
      Tiny : constant Config := (Max_Iterations => 1, Tol => 1.0E-30);
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
      Check (abs (R.Final_F) <= 1.0E-12, "sin tight |f|");
   end;

   ---------------------------------------------------------------------
   Section ("10. Bracket shrink / Success invariants");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Find_Root (Poly_Quad'Access, 0.0, 5.0,
                      Cfg => (Max_Iterations => 100, Tol => 1.0E-10));
      Check (R.Success, "invariants Success");
      Check (R.Bracket_A <= R.Root and then R.Root <= R.Bracket_B,
             "root inside final bracket");
      Check (R.Bracket_B - R.Bracket_A <= 1.0E-9
             or else abs (R.Final_F) <= 1.0E-9,
             "bracket or f within tol-ish");
      Check (R.Iterations > 0, "nonzero iters for interior root");
      Check (R.Status = Ok, "Status Ok");
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
         (-5.0, -1.0, -3.0)];
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
         Poly_Shifted'Access];
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
