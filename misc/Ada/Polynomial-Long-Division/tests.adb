--  Standalone test suite for Polynomial_Long_Division (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Polynomial_Long_Division; use Polynomial_Long_Division;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   function Q (N : Integer; D : Integer := 1) return Rational is
     (Make_Rational (N, D));

   function C0 (A0 : Integer) return Polynomial is
     (Integer_Poly (A0));

   function C1 (A0, A1 : Integer) return Polynomial is
      P : Polynomial := Zero_Poly;
   begin
      P.Coeffs (0) := Q (A0);
      P.Coeffs (1) := Q (A1);
      return Trim (P);
   end C1;

   function C2 (A0, A1, A2 : Integer) return Polynomial is
      P : Polynomial := Zero_Poly;
   begin
      P.Coeffs (0) := Q (A0);
      P.Coeffs (1) := Q (A1);
      P.Coeffs (2) := Q (A2);
      return Trim (P);
   end C2;

   function C3 (A0, A1, A2, A3 : Integer) return Polynomial is
      P : Polynomial := Zero_Poly;
   begin
      P.Coeffs (0) := Q (A0);
      P.Coeffs (1) := Q (A1);
      P.Coeffs (2) := Q (A2);
      P.Coeffs (3) := Q (A3);
      return Trim (P);
   end C3;

   procedure Expect_Div_Zero (Label : String; Divisor : Polynomial) is
      Raised     : Boolean := False;
      Quo, Rem_P : Polynomial;
   begin
      begin
         Divide (C0 (1), Divisor, Quo, Rem_P);
      exception
         when Division_By_Zero =>
            Raised := True;
      end;
      Check (Raised, "Division_By_Zero: " & Label);
   end Expect_Div_Zero;

   procedure Check_Divide
     (Label    : String;
      Dividend : Polynomial;
      Divisor  : Polynomial;
      Exp_Q    : Polynomial;
      Exp_R    : Polynomial)
   is
      Quo, Rem_P, Recon : Polynomial;
   begin
      Divide (Dividend, Divisor, Quo, Rem_P);
      Check (Equal (Quo, Exp_Q), Label & " quotient");
      Check (Equal (Rem_P, Exp_R), Label & " remainder");
      if Is_Zero (Rem_P) then
         Check (True, Label & " rem zero ok");
      else
         Check
           (Degree (Rem_P) < Degree (Divisor), Label & " deg(r)<deg(g)");
      end if;
      Recon := Add (Mul (Quo, Divisor), Rem_P);
      Check (Equal (Recon, Trim (Dividend)), Label & " reconstruct");
   end Check_Divide;

   procedure Check_Identity
     (Label : String; Dividend, Divisor : Polynomial)
   is
      Quo, Rem_P, Recon : Polynomial;
   begin
      Divide (Dividend, Divisor, Quo, Rem_P);
      if Is_Zero (Rem_P) then
         Check (True, Label & " rem zero-or-deg");
      else
         Check
           (Degree (Rem_P) < Degree (Divisor), Label & " deg(r)<deg(g)");
      end if;
      Recon := Add (Mul (Quo, Divisor), Rem_P);
      Check (Equal (Recon, Trim (Dividend)), Label & " f=qg+r");
   end Check_Identity;

begin
   Ada.Text_IO.Put_Line ("Polynomial_Long_Division test suite");
   Ada.Text_IO.Put_Line ("===================================");

   Section ("1. Rational reduce / arithmetic");
   declare
      R : Rational;
   begin
      R := Make_Rational (2, 4);
      Check (R.Num = 1 and then R.Den = 2, "2/4 -> 1/2");
      R := Make_Rational (-6, 9);
      Check (R.Num = -2 and then R.Den = 3, "-6/9 -> -2/3");
      R := Make_Rational (6, -9);
      Check (R.Num = -2 and then R.Den = 3, "6/-9 -> -2/3");
      R := Make_Rational (0, 5);
      Check (Is_Zero (R), "0/5 is zero");
      Check (Equal (Q (1, 2) + Q (1, 3), Q (5, 6)), "1/2+1/3");
      Check (Equal (Q (1, 2) - Q (1, 3), Q (1, 6)), "1/2-1/3");
      Check (Equal (Q (2, 3) * Q (3, 4), Q (1, 2)), "2/3*3/4");
      Check (Equal (Q (2, 3) / Q (4, 5), Q (5, 6)), "2/3 / 4/5");
      Check (Equal (-Q (3, 4), Q (-3, 4)), "unary minus");
      Check (Equal (Abs_Val (Q (-3, 4)), Q (3, 4)), "Abs_Val");
      Check (Equal (Q (3, 6), Q (1, 2)), "Equal after reduce");
      Check (not Equal (Q (1, 2), Q (2, 3)), "not Equal");
      Check (Equal (Q (10, 15), Q (2, 3)), "10/15=2/3");
      Check (Equal (Q (-10, -15), Q (2, 3)), "(-10)/(-15)=2/3");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Rational := Make_Rational (1, 0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Division_By_Zero =>
            Raised := True;
      end;
      Check (Raised, "Make_Rational den0");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Rational := Q (1) / Zero_Q;
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Division_By_Zero =>
            Raised := True;
      end;
      Check (Raised, "Rational div zero");
   end;

   Section ("2. Degree / Trim / Is_Zero / LC");
   Check (Degree (Zero_Poly) = -1, "deg(0)=-1");
   Check (Is_Zero (Zero_Poly), "Is_Zero(0)");
   Check (Degree (C0 (5)) = 0, "deg(const)");
   Check (Degree (C1 (-1, 1)) = 1, "deg(x-1)");
   Check (Degree (C2 (-1, 0, 1)) = 2, "deg(x^2-1)");
   Check (Degree (C3 (-4, 0, -2, 1)) = 3, "deg wiki");
   declare
      P : constant Polynomial := C2 (1, 2, 0);
   begin
      Check (Degree (P) = 1, "Trim leading zero");
      Check (Equal (Leading_Coefficient (C2 (-1, 0, 1)), Q (1)), "LC");
      Check (Equal (Leading_Coefficient (Zero_Poly), Zero_Q), "LC zero");
      Check (Equal (Leading_Coefficient (C1 (3, -2)), Q (-2)), "LC -2");
   end;
   Check (Equal (Normalize (C2 (1, 0, 0)), C0 (1)), "Normalize");
   Check (not Is_Zero (C0 (1)), "not Is_Zero(1)");
   Check (Degree (Monomial (Q (1), Max_Degree)) = Max_Degree,
          "Max_Degree monomial");

   Section ("3. Add / Sub / Mul / Scale");
   Check (Equal (Add (C1 (1, 1), C1 (1, -1)), C0 (2)), "add cancel");
   Check (Equal (Sub (C2 (-1, 0, 1), C0 (1)), C2 (-2, 0, 1)), "sub");
   Check (Equal (Mul (C1 (-1, 1), C1 (1, 1)), C2 (-1, 0, 1)),
          "(x-1)(x+1)");
   Check (Equal (Mul (C1 (1, 1), C1 (1, 1)), C2 (1, 2, 1)), "(x+1)^2");
   Check (Equal (Scale (C1 (1, 1), Q (2)), C1 (2, 2)), "Scale 2");
   Check (Equal (Scale (C1 (1, 1), Zero_Q), Zero_Poly), "Scale 0");
   Check (Equal (Mul (Zero_Poly, C1 (1, 1)), Zero_Poly), "0*p");
   Check (Equal (Add (Zero_Poly, C0 (7)), C0 (7)), "0+7");
   Check (Equal (Sub (C0 (7), C0 (7)), Zero_Poly), "7-7");
   Check (Equal (Mul (C0 (3), C0 (4)), C0 (12)), "3*4");
   Check (Equal (Monomial (Q (5), 3), C3 (0, 0, 0, 5)), "5x^3");
   Check (Equal (Constant_Poly (Q (1, 2)), Monomial (Q (1, 2), 0)),
          "Constant_Poly");
   Check (Equal (Integer_Poly (0), Zero_Poly), "Integer_Poly 0");

   Section ("4. Division_By_Zero");
   Expect_Div_Zero ("zero poly", Zero_Poly);
   Expect_Div_Zero ("all-zero coeffs", C2 (0, 0, 0));

   Section ("5. (x^2-1)/(x-1) = x+1 rem 0");
   Check_Divide
     ("(x^2-1)/(x-1)",
      C2 (-1, 0, 1), C1 (-1, 1),
      C1 (1, 1), Zero_Poly);

   Section ("6. Wikipedia textbook example");
   Check_Divide
     ("wiki",
      C3 (-4, 0, -2, 1), C1 (-3, 1),
      C2 (3, 1, 1), C0 (5));

   Section ("7. Remainder nonzero");
   Check_Divide
     ("(x^2+1)/(x+1)",
      C2 (1, 0, 1), C1 (1, 1),
      C1 (-1, 1), C0 (2));
   Check_Divide
     ("(x^3+1)/(x+1)",
      C3 (1, 0, 0, 1), C1 (1, 1),
      C2 (1, -1, 1), Zero_Poly);
   Check_Divide
     ("(2x+3)/(x+1)",
      C1 (3, 2), C1 (1, 1),
      C0 (2), C0 (1));

   Section ("8. Constant divisor");
   declare
      Exp_Q : Polynomial := Zero_Poly;
   begin
      Exp_Q.Coeffs (0) := Q (1, 2);
      Exp_Q.Coeffs (1) := Q (1);
      Exp_Q.Coeffs (2) := Q (1, 2);
      Check_Divide
        ("(x^2+2x+1)/2",
         C2 (1, 2, 1), C0 (2),
         Trim (Exp_Q), Zero_Poly);
   end;
   Check_Divide
     ("(6x+3)/3",
      C1 (3, 6), C0 (3),
      C1 (1, 2), Zero_Poly);

   Section ("9. Deg dividend < deg divisor");
   Check_Divide
     ("const / linear",
      C0 (5), C1 (-1, 1),
      Zero_Poly, C0 (5));
   Check_Divide
     ("linear / quadratic",
      C1 (1, 1), C2 (1, 0, 1),
      Zero_Poly, C1 (1, 1));
   Check_Divide
     ("zero / (x+1)",
      Zero_Poly, C1 (1, 1),
      Zero_Poly, Zero_Poly);

   Section ("10. More textbook identities");
   Check_Divide
     ("(x^2-x-6)/(x-3)",
      C2 (-6, -1, 1), C1 (-3, 1),
      C1 (2, 1), Zero_Poly);  -- x+2
   Check_Divide
     ("(x^3-1)/(x-1)",
      C3 (-1, 0, 0, 1), C1 (-1, 1),
      C2 (1, 1, 1), Zero_Poly);
   declare
      F : Polynomial := Zero_Poly;
   begin
      F.Coeffs (0) := Q (-1);
      F.Coeffs (4) := Q (1);
      Check_Divide
        ("(x^4-1)/(x-1)",
         Trim (F), C1 (-1, 1),
         C3 (1, 1, 1, 1), Zero_Poly);
   end;

   Check_Divide
     ("(x^3-6x^2+11x-6)/(x-1)",
      C3 (-6, 11, -6, 1), C1 (-1, 1),
      C2 (6, -5, 1), Zero_Poly);  -- (x-2)(x-3)=x^2-5x+6

   Section ("11. Rational coefficients in division");
   declare
      F, G, Exp_Q : Polynomial := Zero_Poly;
   begin
      --  (1/2 x^2 + 1/3) / (1/4 x) = 2 x  rem  1/3
      F.Coeffs (0) := Q (1, 3);
      F.Coeffs (2) := Q (1, 2);
      G.Coeffs (1) := Q (1, 4);
      Exp_Q.Coeffs (1) := Q (2);  -- (1/2)/(1/4) = 2, power 1
      Check_Divide
        ("rational coeffs",
         Trim (F), Trim (G),
         Trim (Exp_Q), Constant_Poly (Q (1, 3)));
   end;

   Section ("12. Batch reconstruct identities");
   declare
      type Pair is record
         F, G : Polynomial;
      end record;
      Cases : constant array (Positive range <>) of Pair :=
        [(C2 (1, 2, 3), C1 (1, 1)),
         (C3 (4, 0, -1, 2), C1 (2, 1)),
         (C2 (0, 0, 1), C1 (0, 1)),
         (C3 (1, 1, 1, 1), C2 (1, 1, 1)),
         (C1 (5, -3), C0 (-1)),
         (C2 (7, -2, 1), C1 (1, -1)),
         (C3 (0, 0, 0, 1), C1 (1, 1)),
         (C2 (9, 0, 1), C0 (1)),
         (C1 (0, 1), C1 (1, 1)),
         (C3 (-1, 2, -3, 1), C2 (1, 0, 1))];
   begin
      for I in Cases'Range loop
         Check_Identity
           ("batch" & Integer'Image (I), Cases (I).F, Cases (I).G);
      end loop;
   end;

   Section ("13. Equal / From_Coeffs / Monomial edge");
   Check (Equal (C1 (1, 2), C1 (1, 2)), "Equal same");
   Check (not Equal (C1 (1, 2), C1 (2, 1)), "not equal");
   declare
      C : Coeff_Array := [others => Zero_Q];
      P : Polynomial;
   begin
      C (0) := Q (3);
      C (2) := Q (1);
      P := From_Coeffs (C, 0, 2);
      Check (Equal (P, C2 (3, 0, 1)), "From_Coeffs");
   end;
   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Polynomial := Monomial (Q (1), Max_Degree + 1);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Monomial over Max_Degree");
   end;

   Section ("14. Self-divide and units");
   Check_Divide
     ("p/p",
      C2 (1, 2, 1), C2 (1, 2, 1),
      C0 (1), Zero_Poly);
   Check_Divide
     ("p/1",
      C2 (4, 5, 6), C0 (1),
      C2 (4, 5, 6), Zero_Poly);
   Check_Divide
     ("(-x)/(x)",
      C1 (0, -1), C1 (0, 1),
      C0 (-1), Zero_Poly);

   Section ("15. Extra reconstruct stress");
   for A0 in -3 .. 3 loop
      for A1 in -2 .. 2 loop
         if A1 /= 0 or else A0 /= 0 then
            Check_Identity
              ("stress lin",
               C2 (A0, A1, 1),
               C1 (1, 1));
            Check_Identity
              ("stress x-2",
               C2 (A0, A1, 1),
               C1 (-2, 1));
         end if;
      end loop;
   end loop;

   --  Cubic dividends vs linear / quadratic divisors (identity only).
   for B0 in -2 .. 2 loop
      for B1 in -2 .. 2 loop
         for B2 in -1 .. 1 loop
            if B2 /= 0 or else B1 /= 0 or else B0 /= 0 then
               Check_Identity
                 ("stress cub/lin",
                  C3 (B0, B1, B2, 1),
                  C1 (1, 1));
            end if;
         end loop;
      end loop;
   end loop;

   for D0 in -2 .. 2 loop
      for D1 in -1 .. 1 loop
         if D1 /= 0 or else D0 /= 0 then
            Check_Identity
              ("stress cub/quad",
               C3 (1, -1, 2, 1),
               C2 (D0, D1, 1));
         end if;
      end loop;
   end loop;

   Section ("16. Reduce / Equal rational sweep");
   for N in -6 .. 6 loop
      for D in 1 .. 6 loop
         declare
            R : constant Rational := Make_Rational (N, D);
            S : constant Rational := Reduce (R);
         begin
            Check (Equal (R, S), "Reduce idempotent");
            Check (Equal (R, Make_Rational (S.Num, Integer (S.Den))),
                   "round-trip Make");
            if N = 0 then
               Check (Is_Zero (R), "zero num");
            else
               Check (not Is_Zero (R), "nonzero num");
            end if;
         end;
      end loop;
   end loop;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("===================================");
   Ada.Text_IO.Put_Line
     ("Results:"
      & Natural'Image (Pass_Count)
      & " PASS,"
      & Natural'Image (Fail_Count)
      & " FAIL");
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
