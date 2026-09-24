--  Standalone test suite for Gospers_Algorithm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Gospers_Algorithm; use Gospers_Algorithm;

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

   procedure Check_Poly_Sum
     (Label : String;
      P     : Polynomial;
      Ns    : Integer)
   is
      Term : constant Term_Spec := Make_Polynomial_Term (P);
      Res  : constant Gosper_Result := Try_Gosper_Sum (Term);
   begin
      Check (Res.Found, Label & " found");
      if Res.Found then
         Check (Res.Antidifference.Is_Polynomial_Closed,
                Label & " poly closed");
         for N in 1 .. Ns loop
            Check
              (Verify_Telescoping (Term, Res.Antidifference, N),
               Label & " telescope n=" & Integer'Image (N));
         end loop;
      end if;
   end Check_Poly_Sum;

   procedure Check_Geometric
     (Label : String;
      R     : Rational;
      Ns    : Integer)
   is
      Term : constant Term_Spec := Make_Geometric_Term (R);
      Res  : constant Gosper_Result := Try_Gosper_Sum (Term);
   begin
      Check (Res.Found, Label & " found");
      if Res.Found then
         for N in 0 .. Ns loop
            Check
              (Verify_Telescoping (Term, Res.Antidifference, N),
               Label & " telescope n=" & Integer'Image (N));
         end loop;
      end if;
   end Check_Geometric;

begin
   Ada.Text_IO.Put_Line ("Gospers_Algorithm test suite");
   Ada.Text_IO.Put_Line ("============================");

   ------------------------------------------------------------------
   Section ("1. Rational arithmetic");
   ------------------------------------------------------------------
   declare
      R : Rational;
   begin
      R := Make_Rational (2, 4);
      Check (R.Num = 1 and then R.Den = 2, "2/4 -> 1/2");
      R := Make_Rational (-6, 9);
      Check (R.Num = -2 and then R.Den = 3, "-6/9 -> -2/3");
      R := Make_Rational (6, -9);
      Check (R.Num = -2 and then R.Den = 3, "6/-9 -> -2/3");
      Check (Is_Zero (Make_Rational (0, 5)), "0/5 is zero");
      Check (Equal (Q (1, 2) + Q (1, 3), Q (5, 6)), "1/2+1/3");
      Check (Equal (Q (1, 2) - Q (1, 3), Q (1, 6)), "1/2-1/3");
      Check (Equal (Q (2, 3) * Q (3, 4), Q (1, 2)), "2/3*3/4");
      Check (Equal (Q (2, 3) / Q (4, 5), Q (5, 6)), "2/3 / 4/5");
      Check (Equal (-Q (3, 4), Q (-3, 4)), "unary minus");
      Check (Equal (Abs_Val (Q (-3, 4)), Q (3, 4)), "Abs_Val");
      Check (Equal (Pow_Nat (Q (2), 3), Q (8)), "2^3");
      Check (Equal (Pow_Nat (Q (1, 2), 3), Q (1, 8)), "(1/2)^3");
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

   ------------------------------------------------------------------
   Section ("2. Polynomial Degree / Trim / ring");
   ------------------------------------------------------------------
   Check (Degree (Zero_Poly) = -1, "deg(0)=-1");
   Check (Is_Zero (Zero_Poly), "Is_Zero(0)");
   Check (Degree (C0 (5)) = 0, "deg(const)");
   Check (Degree (C1 (0, 1)) = 1, "deg(n)");
   Check (Degree (C2 (0, 0, 1)) = 2, "deg(n^2)");
   Check (Equal (Leading_Coefficient (C1 (3, -2)), Q (-2)), "LC");
   Check (Equal (Add (C1 (1, 1), C1 (2, 3)), C1 (3, 4)), "Add");
   Check (Equal (Sub (C1 (3, 4), C1 (1, 1)), C1 (2, 3)), "Sub");
   Check (Equal (Mul (C1 (1, 1), C1 (-1, 1)), C2 (-1, 0, 1)), "Mul (n+1)(n-1)");
   Check (Equal (Scale (C1 (1, 1), Q (2)), C1 (2, 2)), "Scale");
   Check (Equal (Eval (C2 (1, 2, 3), 2), Q (17)), "Eval 3n^2+2n+1 at 2");
   Check (Equal (Normalize (C2 (1, 0, 0)), C0 (1)), "Normalize");

   ------------------------------------------------------------------
   Section ("3. Shift / GCD / Exact_Quotient");
   ------------------------------------------------------------------
   --  Shift(n, 1) = n+1
   Check (Equal (Shift (C1 (0, 1), 1), C1 (1, 1)), "Shift n -> n+1");
   Check (Equal (Shift (C1 (0, 1), -1), C1 (-1, 1)), "Shift n -> n-1");
   Check (Equal (Shift (C2 (0, 0, 1), 1), C2 (1, 2, 1)), "Shift n^2 -> (n+1)^2");
   Check (Equal (Poly_GCD (C2 (-1, 0, 1), C1 (-1, 1)), C1 (-1, 1)),
          "GCD(n^2-1, n-1)");
   Check (Equal (Exact_Quotient (C2 (-1, 0, 1), C1 (-1, 1)), C1 (1, 1)),
          "Exact (n^2-1)/(n-1)");
   declare
      Qp, Rp : Polynomial;
   begin
      Divide (C3 (-4, 0, -2, 1), C1 (-3, 1), Qp, Rp);
      Check (Equal (Qp, C2 (3, 1, 1)), "Divide wiki Q");
      Check (Equal (Rp, C0 (5)), "Divide wiki R");
   end;

   ------------------------------------------------------------------
   Section ("4. Polynomial Gosper: sum n, n^2, n(n+1), ...");
   ------------------------------------------------------------------
   Check_Poly_Sum ("sum n", C1 (0, 1), 5);
   --  S = n(n-1)/2
   declare
      Term : constant Term_Spec := Make_Polynomial_Term (C1 (0, 1));
      Res  : constant Gosper_Result := Try_Gosper_Sum (Term);
      Exp  : constant Polynomial := Scale (C2 (0, -1, 1), Q (1, 2));
      --  n(n-1)/2 = (1/2)n^2 - (1/2)n
   begin
      Check (Res.Found, "sum n closed found");
      Check (Equal (Res.Antidifference.S_Poly, Exp), "sum n = n(n-1)/2");
   end;

   Check_Poly_Sum ("sum const 1", C0 (1), 4);
   declare
      Term : constant Term_Spec := Make_Polynomial_Term (C0 (1));
      Res  : constant Gosper_Result := Try_Gosper_Sum (Term);
   begin
      Check (Equal (Res.Antidifference.S_Poly, C1 (0, 1)), "sum 1 = n");
   end;

   Check_Poly_Sum ("sum n(n+1)", Mul (C1 (0, 1), C1 (1, 1)), 4);
   Check_Poly_Sum ("sum n^2", C2 (0, 0, 1), 4);
   Check_Poly_Sum ("sum n^3", C3 (0, 0, 0, 1), 3);
   Check_Poly_Sum ("sum 2n+3", C1 (3, 2), 4);
   Check_Poly_Sum ("sum 0", Zero_Poly, 2);

   ------------------------------------------------------------------
   Section ("5. Geometric terms r^n");
   ------------------------------------------------------------------
   Check_Geometric ("2^n", Q (2), 5);
   Check_Geometric ("3^n", Q (3), 4);
   Check_Geometric ("(1/2)^n", Q (1, 2), 5);
   Check_Geometric ("(-1)^n", Q (-1), 6);
   --  r=1 is t(n)=1, antidifference n
   Check_Geometric ("1^n", Q (1), 4);

   declare
      Term : constant Term_Spec := Make_Geometric_Term (Q (2));
      Res  : constant Gosper_Result := Try_Gosper_Sum (Term);
      --  S(n) = 2^n / (2-1) = 2^n
      S0   : Rational;
   begin
      Check (Res.Found, "2^n certificate");
      S0 := Eval_Antidifference (Term, Res.Antidifference, 0);
      Check (Equal (S0, Q (1)), "S(0)=1 for 2^n");
      Check (Equal (Eval_Antidifference (Term, Res.Antidifference, 3), Q (8)),
             "S(3)=8 for 2^n");
   end;

   ------------------------------------------------------------------
   Section ("6. Ratio-term Gosper form");
   ------------------------------------------------------------------
   --  t(n)=n via ratio (n+1)/n with seed t(1)=1
   declare
      Term : constant Term_Spec :=
        Make_Ratio_Term (C1 (1, 1), C1 (0, 1), Seed_N => 1, Seed_T => Q (1));
      Res  : constant Gosper_Result := Try_Gosper_Sum (Term);
   begin
      Check (Res.Found, "ratio for n found");
      Check (Equal (Eval_Term (Term, 5), Q (5)), "Eval_Term n at 5");
      Check (Verify_Telescoping (Term, Res.Antidifference, 2),
             "ratio n telescope 2");
      Check (Verify_Telescoping (Term, Res.Antidifference, 3),
             "ratio n telescope 3");
      Check (Verify_Telescoping (Term, Res.Antidifference, 4),
             "ratio n telescope 4");
   end;

   --  Geometric via ratio: t(n+1)/t(n)=2
   declare
      Term : constant Term_Spec :=
        Make_Ratio_Term (C0 (2), C0 (1), Seed_N => 0, Seed_T => Q (1));
      Res  : constant Gosper_Result := Try_Gosper_Sum (Term);
   begin
      Check (Res.Found, "ratio geometric 2 found");
      Check (Verify_Telescoping (Term, Res.Antidifference, 0),
             "ratio geo telescope 0");
      Check (Verify_Telescoping (Term, Res.Antidifference, 1),
             "ratio geo telescope 1");
      Check (Verify_Telescoping (Term, Res.Antidifference, 4),
             "ratio geo telescope 4");
   end;

   --  Gosper_Normal_Form of (n+1)/n -> a=1,b=1,c=n
   declare
      Ag, Bg, Cg : Polynomial;
   begin
      Gosper_Normal_Form (C1 (1, 1), C1 (0, 1), Ag, Bg, Cg);
      Check (Equal (Ag, C0 (1)), "GNF a=1");
      Check (Equal (Bg, C0 (1)), "GNF b=1");
      Check (Equal (Cg, C1 (0, 1)), "GNF c=n");
   end;

   ------------------------------------------------------------------
   Section ("7. Non-summable: 1/n");
   ------------------------------------------------------------------
   --  t(n)=1/n has ratio n/(n+1); antidifference is harmonic — not hypergeo
   declare
      Term : constant Term_Spec :=
        Make_Ratio_Term (C1 (0, 1), C1 (1, 1), Seed_N => 1, Seed_T => Q (1));
      Res  : constant Gosper_Result := Try_Gosper_Sum (Term);
   begin
      Check (not Res.Found, "1/n not Gosper-summable");
      Check (Equal (Eval_Term (Term, 1), Q (1)), "t(1)=1");
      Check (Equal (Eval_Term (Term, 2), Q (1, 2)), "t(2)=1/2");
      Check (Equal (Eval_Term (Term, 3), Q (1, 3)), "t(3)=1/3");
   end;

   ------------------------------------------------------------------
   Section ("8. Invalid arguments");
   ------------------------------------------------------------------
   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Term_Spec :=
              Make_Ratio_Term (C0 (1), Zero_Poly);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Make_Ratio_Term B=0");
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
      Check (Raised, "Monomial deg overflow");
   end;

   declare
      Raised : Boolean := False;
      Qp, Rp : Polynomial;
   begin
      begin
         Divide (C0 (1), Zero_Poly, Qp, Rp);
      exception
         when Division_By_Zero =>
            Raised := True;
      end;
      Check (Raised, "Divide by zero poly");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Polynomial :=
              Exact_Quotient (C1 (1, 1), C1 (0, 1));
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Exact_Quotient remainder");
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
      Check (Raised, "Rational / 0");
   end;

   ------------------------------------------------------------------
   Section ("9. Certificate identity checks");
   ------------------------------------------------------------------
   declare
      X  : Polynomial;
      Ok : Boolean;
   begin
      --  X(n+1)-X(n)=n  => X = n(n-1)/2
      Solve_Certificate (C0 (1), C0 (1), C1 (0, 1), X, Ok);
      Check (Ok, "Solve X(n+1)-X(n)=n");
      Check (Equal (X, Scale (C2 (0, -1, 1), Q (1, 2))),
             "X=n(n-1)/2");
   end;

   declare
      X  : Polynomial;
      Ok : Boolean;
   begin
      --  Non-summable 1/n form: a=n, b=n+1 => n X(n+1) - n X(n) = 1
      Solve_Certificate (C1 (0, 1), C1 (1, 1), C0 (1), X, Ok);
      Check (not Ok, "n(X(n+1)-X(n))=1 has no poly X");
   end;

   --  Reconstruct: for poly term, Eval S matches certificate path
   declare
      Term : constant Term_Spec := Make_Polynomial_Term (C2 (0, 0, 1));
      Res  : constant Gosper_Result := Try_Gosper_Sum (Term);
   begin
      Check (Res.Found, "n^2 found again");
      Check (Verify_Telescoping (Term, Res.Antidifference, 6),
             "n^2 telescope 6");
      Check (Verify_Telescoping (Term, Res.Antidifference, 7),
             "n^2 telescope 7");
   end;

   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
