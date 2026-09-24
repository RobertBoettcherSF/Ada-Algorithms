--  Standalone test suite for Mullers_Method (main program).

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Text_IO; use Ada.Text_IO;
with Mullers_Method; use Mullers_Method;

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


   Sqrt2 : constant Real := Sqrt (2.0);
   Ln2   : constant Real := Log (2.0);
   Pi    : constant Real := Ada.Numerics.Pi;

   Wiki_Root : constant Real := 1.739_203_861_220_096_8;

begin
   Put_Line ("Mullers_Method test suite");
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
   Section ("2. Starts_Distinct");
   ---------------------------------------------------------------------
   Check (Starts_Distinct (0.0, 1.0, 2.0), "Starts_Distinct 0,1,2");
   Check (Starts_Distinct (-1.0, 0.0, 1.0), "Starts_Distinct -1,0,1");
   Check (not Starts_Distinct (1.0, 1.0, 2.0), "rejects X0=X1");
   Check (not Starts_Distinct (0.0, 2.0, 2.0), "rejects X1=X2");
   Check (not Starts_Distinct (3.0, 1.0, 3.0), "rejects X0=X2");
   Check (not Starts_Distinct (5.0, 5.0, 5.0), "rejects all equal");
   Check (Starts_Distinct (1.0, 2.0, 1.000_000_1), "near-distinct ok");

   ---------------------------------------------------------------------
   Section ("3. Next_Point (Wikipedia formula)");
   ---------------------------------------------------------------------
   declare
      X0 : constant Real := 0.0;
      X1 : constant Real := 1.0;
      X2 : constant Real := 2.0;
      F0 : constant Real := Poly_Quad (X0);
      F1 : constant Real := Poly_Quad (X1);
      F2 : constant Real := Poly_Quad (X2);
      X3 : Real;
   begin
      X3 := Next_Point (X0, X1, X2, F0, F1, F2);
      Check (Approx (X3, Sqrt2, 1.0E-12), "Next_Point x^2-2 exact parabola");
      Check (Approx (Poly_Quad (X3), 0.0, 1.0E-12), "Next_Point f(x3)=0");
   end;

   declare
      X0 : constant Real := 0.0;
      X1 : constant Real := 1.0;
      X2 : constant Real := 3.0;
      F0 : constant Real := Poly_Linear (X0);
      F1 : constant Real := Poly_Linear (X1);
      F2 : constant Real := Poly_Linear (X2);
      X3 : Real;
   begin
      X3 := Next_Point (X0, X1, X2, F0, F1, F2);
      Check (Approx (X3, 2.0, 1.0E-12), "Next_Point linear finds root");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : Real;
         begin
            Unused := Next_Point (1.0, 1.0, 2.0, 0.0, 1.0, 2.0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Next_Point raises on coincident");
   end;

   ---------------------------------------------------------------------
   Section ("4. Find_Root — polynomials");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Find_Root (Poly_Linear'Access, 0.0, 1.0, 3.0);
      Check (R.Success, "linear Success");
      Check (R.Status = Ok, "linear Status Ok");
      Check (Approx (R.Root, 2.0, 1.0E-9), "linear root=2");
      Check (abs (R.Final_F) <= 1.0E-9, "linear |f|");

      R := Find_Root (Poly_Quad'Access, 0.0, 1.0, 2.0);
      Check (R.Success, "quad + Success");
      Check (Approx (R.Root, Sqrt2, 1.0E-8), "quad + root");

      R := Find_Root (Poly_Quad'Access, 0.0, -1.0, -2.0);
      Check (R.Success, "quad - Success");
      Check (Approx (R.Root, -Sqrt2, 1.0E-8), "quad - root");

      R := Find_Root (Poly_Cubic'Access, 0.5, 0.8, 1.2);
      Check (R.Success, "cubic root1 Success");
      Check (Approx (R.Root, 1.0, 1.0E-7), "cubic root1");

      R := Find_Root (Poly_Cubic'Access, 1.5, 1.8, 2.2);
      Check (R.Success, "cubic root2 Success");
      Check (Approx (R.Root, 2.0, 1.0E-7), "cubic root2");

      R := Find_Root (Poly_Cubic'Access, 2.5, 2.8, 3.5);
      Check (R.Success, "cubic root3 Success");
      Check (Approx (R.Root, 3.0, 1.0E-7), "cubic root3");

      R := Find_Root (Poly_Shifted'Access, 0.0, 0.3, 1.0);
      Check (R.Success, "shifted 0.5 Success");
      Check (Approx (R.Root, 0.5, 1.0E-8), "shifted 0.5");

      R := Find_Root (Poly_Shifted'Access, -4.0, -3.5, -2.0);
      Check (R.Success, "shifted -3 Success");
      Check (Approx (R.Root, -3.0, 1.0E-8), "shifted -3");

      R := Find_Root (Cubic_One_Root'Access, 0.0, 1.0, 2.0);
      Check (R.Success, "x^3-x-1 Success");
      Check (Approx (R.Root, 1.324_717_957, 1.0E-7), "x^3-x-1 root");
   end;

   ---------------------------------------------------------------------
   Section ("5. Wikipedia example Wiki_Cubic");
   ---------------------------------------------------------------------
   declare
      R : Result;
      Cfg : constant Config :=
        (Max_Iterations => 100, Tol => 1.0E-9);
   begin
      R := Find_Root (Wiki_Cubic'Access, 1.0, 2.0, 3.0, Cfg);
      Check (R.Success, "wiki Success");
      Check (R.Status = Ok, "wiki Status Ok");
      Check (Approx (R.Root, Wiki_Root, 1.0E-8), "wiki root value");
      Check (abs (R.Final_F) <= 1.0E-8, "wiki |f|");
      Check (R.Iterations > 0, "wiki iters > 0");
   end;

   ---------------------------------------------------------------------
   Section ("6. Transcendental objectives");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Find_Root (Sin_Fn'Access, 2.5, 3.0, 3.5);
      Check (R.Success, "sin Success");
      Check (Approx (R.Root, Pi, 1.0E-7), "sin root Pi");

      R := Find_Root (Sin_Fn'Access, -0.5, 0.2, 0.5);
      Check (R.Success, "sin zero Success");
      Check (Approx (R.Root, 0.0, 1.0E-8), "sin root 0");

      R := Find_Root (Cos_Fn'Access, 0.5, 1.0, 2.0);
      Check (R.Success, "cos Success");
      Check (Approx (R.Root, Pi / 2.0, 1.0E-7), "cos root Pi/2");

      R := Find_Root (Exp_Linear'Access, 0.0, 0.5, 1.0);
      Check (R.Success, "exp Success");
      Check (Approx (R.Root, Ln2, 1.0E-8), "exp root ln2");

      R := Find_Root (Atan_Shift'Access, 0.0, 0.5, 1.0);
      Check (R.Success, "atan Success");
      Check (Approx (R.Root, Tan (0.5), 1.0E-7), "atan root");

      R := Find_Root (Steep_Exp'Access, 0.0, 0.5, 1.5);
      Check (R.Success, "steep Success");
      Check (Approx (R.Root, 1.0, 1.0E-8), "steep root 1");

      R := Find_Root (Cos_Minus_X3'Access, 0.0, 0.5, 1.0);
      Check (R.Success, "cos-x3 Success");
      Check (Approx (R.Root, 0.865_474_033, 1.0E-6), "cos-x3 root");
   end;

   ---------------------------------------------------------------------
   Section ("7. Three distinct starts (same root)");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Find_Root (Poly_Quad'Access, 0.5, 1.0, 1.5);
      Check (R.Success and then Approx (R.Root, Sqrt2, 1.0E-7),
             "starts A -> +sqrt2");
      R := Find_Root (Poly_Quad'Access, 1.0, 1.5, 3.0);
      Check (R.Success and then Approx (R.Root, Sqrt2, 1.0E-7),
             "starts B -> +sqrt2");
      R := Find_Root (Poly_Quad'Access, 0.0, 2.0, 4.0);
      Check (R.Success and then Approx (R.Root, Sqrt2, 1.0E-7),
             "starts C -> +sqrt2");

      R := Find_Root (Wiki_Cubic'Access, 0.5, 1.5, 2.5);
      Check (R.Success and then Approx (R.Root, Wiki_Root, 1.0E-6),
             "wiki starts A");
      R := Find_Root (Wiki_Cubic'Access, 1.0, 1.5, 2.0);
      Check (R.Success and then Approx (R.Root, Wiki_Root, 1.0E-6),
             "wiki starts B");
      R := Find_Root (Wiki_Cubic'Access, 1.2, 2.0, 2.8);
      Check (R.Success and then Approx (R.Root, Wiki_Root, 1.0E-6),
             "wiki starts C");
   end;

   ---------------------------------------------------------------------
   Section ("8. Exact initial hits / Constant_Zero");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Find_Root (Poly_Linear'Access, 2.0, 3.0, 4.0);
      Check (R.Success, "exact X0 hit Success");
      Check (R.Iterations = 0, "exact X0 iters=0");
      Check (Approx (R.Root, 2.0), "exact X0 root");

      R := Find_Root (Poly_Linear'Access, 0.0, 2.0, 4.0);
      Check (R.Success and then R.Iterations = 0, "exact X1 hit");
      Check (Approx (R.Root, 2.0), "exact X1 root");

      R := Find_Root (Poly_Linear'Access, 0.0, 1.0, 2.0);
      Check (R.Success and then R.Iterations = 0, "exact X2 hit");
      Check (Approx (R.Root, 2.0), "exact X2 root");

      R := Find_Root (Constant_Zero'Access, 1.0, 2.0, 3.0);
      Check (R.Success, "Constant_Zero Success");
      Check (R.Status = Ok, "Constant_Zero Ok");
      Check (R.Iterations = 0, "Constant_Zero iters=0");
   end;

   ---------------------------------------------------------------------
   Section ("9. Degenerate / Max_Iterations");
   ---------------------------------------------------------------------
   declare
      R : Result;
      Tiny : constant Config :=
        (Max_Iterations => 1, Tol => 1.0E-30);
   begin
      R := Find_Root (Poly_Quad'Access, 1.0, 1.0, 2.0);
      Check (not R.Success, "coincident not Success");
      Check (R.Status = Degenerate, "coincident Degenerate");

      R := Find_Root (Poly_Quad'Access, 1.0, 2.0, 1.0);
      Check (R.Status = Degenerate, "X0=X2 Degenerate");

      R := Find_Root (Always_Positive'Access, 0.0, 1.0, 2.0, Tiny);
      Check (not R.Success, "always-pos not Success");
      Check (R.Status = Max_Iterations_Reached
               or else R.Status = Degenerate,
             "always-pos Max_Iterations or Degenerate");

      R := Find_Root
        (Poly_Quad'Access, 0.0, 1.0, 2.0,
         Tol => 1.0E-10, Max_Iterations => 1);
      --  May succeed in one step for exact parabola, or Max_Iterations
      Check (R.Status = Ok or else R.Status = Max_Iterations_Reached,
             "overload short budget status");
   end;

   ---------------------------------------------------------------------
   Section ("10. Config / Tol sensitivity");
   ---------------------------------------------------------------------
   declare
      R : Result;
      Loose : constant Config :=
        (Max_Iterations => 50, Tol => 1.0E-4);
      Tight : constant Config :=
        (Max_Iterations => 100, Tol => 1.0E-12);
   begin
      R := Find_Root (Exp_Linear'Access, 0.0, 0.5, 1.0, Loose);
      Check (R.Success, "loose Tol Success");
      Check (Approx (R.Root, Ln2, 1.0E-3), "loose Tol root");

      R := Find_Root (Exp_Linear'Access, 0.0, 0.5, 1.0, Tight);
      Check (R.Success, "tight Tol Success");
      Check (Approx (R.Root, Ln2, 1.0E-10), "tight Tol root");
      Check (abs (R.Final_F) <= 1.0E-10, "tight |f|");
   end;

   ---------------------------------------------------------------------
   Section ("11. Batch known roots");
   ---------------------------------------------------------------------
   declare
      type Case_Rec is record
         X0, X1, X2, Expected : Real;
      end record;
      Cases : constant array (Positive range <>) of Case_Rec :=
        [(0.0, 1.0, 2.0, Sqrt2),
         (0.0, -1.0, -2.0, -Sqrt2),
         (0.0, 1.0, 3.0, 2.0),
         (0.5, 0.8, 1.2, 1.0),
         (1.5, 1.8, 2.2, 2.0),
         (2.5, 2.8, 3.5, 3.0),
         (0.0, 1.0, 2.0, 1.324_717_957),
         (0.0, 0.5, 1.0, Ln2),
         (2.5, 3.0, 3.5, Pi),
         (0.5, 1.0, 2.0, Pi / 2.0),
         (0.0, 0.5, 1.5, 1.0),
         (0.0, 0.3, 1.0, 0.5),
         (-4.0, -3.5, -2.0, -3.0),
         (1.0, 2.0, 3.0, Wiki_Root),
         (0.0, 0.5, 1.0, 0.865_474_033)];
      Fns : constant array (Cases'Range) of Objective_Fn :=
        [Poly_Quad'Access,
         Poly_Quad'Access,
         Poly_Linear'Access,
         Poly_Cubic'Access,
         Poly_Cubic'Access,
         Poly_Cubic'Access,
         Cubic_One_Root'Access,
         Exp_Linear'Access,
         Sin_Fn'Access,
         Cos_Fn'Access,
         Steep_Exp'Access,
         Poly_Shifted'Access,
         Poly_Shifted'Access,
         Wiki_Cubic'Access,
         Cos_Minus_X3'Access];
      R : Result;
   begin
      for I in Cases'Range loop
         R := Find_Root
           (Fns (I), Cases (I).X0, Cases (I).X1, Cases (I).X2);
         Check (R.Success,
                "batch" & Integer'Image (I) & " Success");
         Check (Approx (R.Root, Cases (I).Expected, 1.0E-6),
                "batch" & Integer'Image (I) & " root");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("12. Status / Success invariants");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Find_Root (Poly_Quad'Access, 0.0, 1.0, 2.0);
      Check (R.Success, "invariants Success");
      Check (R.Status = Ok, "invariants Status Ok");
      Check (R.Success = (R.Status = Ok), "Success iff Ok");
      Check (abs (R.Final_F) <= 1.0E-9, "invariants |f|");
      Check (R.Iterations > 0, "invariants nonzero iters");

      R := Find_Root (Poly_Linear'Access, 1.0, 1.0, 1.0);
      Check (not R.Success, "fail invariants not Success");
      Check (R.Status = Degenerate, "fail invariants Degenerate");
      Check (R.Success = False, "fail Success False");
   end;

   ---------------------------------------------------------------------
   Section ("13. Sample objective sanity");
   ---------------------------------------------------------------------
   Check (Approx (Poly_Linear (2.0), 0.0), "Poly_Linear(2)=0");
   Check (Approx (Poly_Quad (Sqrt2), 0.0, 1.0E-12), "Poly_Quad(+sqrt2)=0");
   Check (Approx (Poly_Cubic (1.0), 0.0), "Poly_Cubic(1)=0");
   Check (Approx (Poly_Cubic (2.0), 0.0), "Poly_Cubic(2)=0");
   Check (Approx (Poly_Cubic (3.0), 0.0), "Poly_Cubic(3)=0");
   Check (Approx (Poly_Shifted (0.5), 0.0), "Poly_Shifted(0.5)=0");
   Check (Approx (Wiki_Cubic (Wiki_Root), 0.0, 1.0E-8), "Wiki_Cubic(root)=0");
   Check (Approx (Exp_Linear (Ln2), 0.0, 1.0E-12), "Exp_Linear(ln2)=0");
   Check (Approx (Steep_Exp (1.0), 0.0, 1.0E-12), "Steep_Exp(1)=0");
   Check (Approx (Sin_Fn (0.0), 0.0), "Sin(0)=0");
   Check (Approx (Cos_Fn (Pi / 2.0), 0.0, 1.0E-12), "Cos(Pi/2)=0");
   Check (Always_Positive (99.0) > 0.0, "Always_Positive");
   Check (Constant_Zero (-7.0) = 0.0, "Constant_Zero");

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
