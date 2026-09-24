--  Standalone test suite for Multivariate_Division_Algorithm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Multivariate_Division_Algorithm; use Multivariate_Division_Algorithm;

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

   function T (C, EX, EY : Integer) return Term is
     (Make_Term (Q (C), Natural (EX), Natural (EY)));

   function P1 (C, EX, EY : Integer) return Polynomial is
     (Monomial (Q (C), Natural (EX), Natural (EY)));

   function P2
     (C1, X1, Y1, C2, X2, Y2 : Integer) return Polynomial
   is
   begin
      return Add (P1 (C1, X1, Y1), P1 (C2, X2, Y2), Lex);
   end P2;

   function P3
     (C1, X1, Y1, C2, X2, Y2, C3, X3, Y3 : Integer) return Polynomial
   is
   begin
      return Add (P2 (C1, X1, Y1, C2, X2, Y2), P1 (C3, X3, Y3), Lex);
   end P3;

   function P4
     (C1, X1, Y1, C2, X2, Y2, C3, X3, Y3, C4, X4, Y4 : Integer)
      return Polynomial
   is
   begin
      return Add
        (P3 (C1, X1, Y1, C2, X2, Y2, C3, X3, Y3),
         P1 (C4, X4, Y4), Lex);
   end P4;

   function Reconstruct
     (Divisors  : Poly_Array;
      Quotients : Poly_Array;
      N         : Divisor_Index;
      Remainder : Polynomial;
      Order     : Monomial_Order) return Polynomial
   is
      Acc : Polynomial := Remainder;
   begin
      for I in 1 .. N loop
         Acc := Add (Acc, Mul (Quotients (I), Divisors (I), Order), Order);
      end loop;
      return Normalize (Acc, Order);
   end Reconstruct;

   function Rem_Clean
     (R        : Polynomial;
      Divisors : Poly_Array;
      N        : Divisor_Index;
      Order    : Monomial_Order) return Boolean
   is
      NR  : constant Polynomial := Normalize (R, Order);
      LTG : Term;
   begin
      for I in 1 .. NR.Count loop
         for J in 1 .. N loop
            LTG := LT (Divisors (J), Order);
            if Monomial_Divides
                 (LTG.Exp_X, LTG.Exp_Y,
                  NR.Terms (I).Exp_X, NR.Terms (I).Exp_Y)
            then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Rem_Clean;

   procedure Check_Divide
     (Label    : String;
      F        : Polynomial;
      Divisors : Poly_Array;
      N        : Divisor_Index;
      Order    : Monomial_Order;
      Exp_R    : Polynomial := Zero_Poly;
      Check_R  : Boolean := False)
   is
      Quo : Poly_Array;
      Rem_P : Polynomial;
      Rec : Polynomial;
   begin
      Divide (F, Divisors, N, Order, Quo, Rem_P);
      Rec := Reconstruct (Divisors, Quo, N, Rem_P, Order);
      Check (Equal (Rec, F, Order), Label & " reconstruct");
      Check (Rem_Clean (Rem_P, Divisors, N, Order), Label & " rem clean");
      if Check_R then
         Check (Equal (Rem_P, Exp_R, Order), Label & " remainder");
      end if;
   end Check_Divide;

begin
   ------------------------------------------------------------------
   Section ("Rational arithmetic");
   ------------------------------------------------------------------
   Check (Equal (Q (2, 4), Q (1, 2)), "reduce 2/4 = 1/2");
   Check (Equal (Q (-3, 6), Q (-1, 2)), "reduce -3/6");
   Check (Equal (Q (3, -6), Q (-1, 2)), "sign moves to num");
   Check (Equal (Q (1, 2) + Q (1, 3), Q (5, 6)), "1/2+1/3");
   Check (Equal (Q (1, 2) - Q (1, 3), Q (1, 6)), "1/2-1/3");
   Check (Equal (Q (2, 3) * Q (3, 4), Q (1, 2)), "2/3*3/4");
   Check (Equal (Q (2, 3) / Q (4, 5), Q (5, 6)), "2/3 / 4/5");
   Check (Is_Zero (Q (0, 7)), "0/7 is zero");
   Check (not Is_Zero (Q (1, 7)), "1/7 not zero");
   Check (Equal (-Q (2, 5), Q (-2, 5)), "unary minus");

   ------------------------------------------------------------------
   Section ("Monomial compare Lex / Grevlex");
   ------------------------------------------------------------------
   Check (Compare_Monomials (2, 0, 1, 5, Lex) > 0, "lex x^2 > x y^5");
   Check (Compare_Monomials (1, 2, 1, 1, Lex) > 0, "lex xy^2 > xy");
   Check (Compare_Monomials (0, 3, 0, 2, Lex) > 0, "lex y^3 > y^2");
   Check (Compare_Monomials (1, 1, 1, 1, Lex) = 0, "lex equal");
   Check (Compare_Monomials (1, 0, 0, 5, Lex) > 0, "lex x > y^5");

   Check (Compare_Monomials (2, 0, 1, 1, Grevlex) > 0, "grevlex x^2 > xy");
   Check (Compare_Monomials (1, 1, 0, 2, Grevlex) > 0, "grevlex xy > y^2");
   Check (Compare_Monomials (3, 0, 1, 1, Grevlex) > 0, "grevlex deg wins");
   Check (Compare_Monomials (1, 1, 2, 0, Grevlex) < 0, "grevlex xy < x^2");
   Check (Compare_Monomials (0, 2, 1, 1, Grevlex) < 0, "grevlex y^2 < xy");
   Check (Compare_Monomials (2, 1, 2, 1, Grevlex) = 0, "grevlex equal");

   Check (Monomial_Divides (1, 1, 2, 3), "xy | x^2 y^3");
   Check (not Monomial_Divides (2, 0, 1, 5), "x^2 does not divide x y^5");
   Check (Monomial_Divides (0, 0, 3, 4), "1 divides anything");
   Check (Monomial_Divides (0, 2, 1, 2), "y^2 | x y^2");
   Check (not Monomial_Divides (0, 2, 2, 1), "y^2 does not divide x^2 y");

   ------------------------------------------------------------------
   Section ("Polynomial normalize / LT / LC");
   ------------------------------------------------------------------
   declare
      A : constant Polynomial := Add (P1 (2, 1, 0), P1 (3, 1, 0), Lex);
      B : constant Polynomial := Add (P1 (1, 2, 0), P1 (0, 0, 1), Lex);
      C : constant Polynomial :=
        Add (P1 (1, 0, 2), Add (P1 (1, 1, 1), P1 (1, 2, 0), Lex), Lex);
      L : Term;
   begin
      Check (Equal (A, P1 (5, 1, 0), Lex), "combine like terms");
      Check (Is_Zero (Scale (P1 (1, 1, 1), Q (0), Lex)), "scale by 0");
      Check (Equal (B, P1 (1, 2, 0), Lex), "drop zero term");
      L := LT (C, Lex);
      Check (L.Exp_X = 2 and then L.Exp_Y = 0, "LT lex of x^2+xy+y^2");
      Check (Equal (LC (C, Lex), One_Q), "LC lex");
      L := LT (C, Grevlex);
      Check (L.Exp_X = 2 and then L.Exp_Y = 0, "LT grevlex x^2 largest");
      Check (Equal (Integer_Poly (0), Zero_Poly, Lex), "Integer 0");
      Check (Equal (Constant_Poly (Q (7)), P1 (7, 0, 0), Lex), "const 7");
      Check (Equal (Uni_X (Q (1), 3), P1 (1, 3, 0), Lex), "uni_x x^3");
      Check (Equal (Uni_Y (Q (2), 2), P1 (2, 0, 2), Lex), "uni_y 2y^2");
   end;

   ------------------------------------------------------------------
   Section ("Add / Sub / Mul");
   ------------------------------------------------------------------
   declare
      X  : constant Polynomial := P1 (1, 1, 0);
      Y  : constant Polynomial := P1 (1, 0, 1);
      XY : constant Polynomial := P1 (1, 1, 1);
      S  : Polynomial;
      D  : Polynomial;
      M  : Polynomial;
   begin
      S := Add (X, Y, Lex);
      Check (Equal (S, P2 (1, 1, 0, 1, 0, 1), Lex), "x+y");
      D := Sub (X, X, Lex);
      Check (Is_Zero (D), "x-x = 0");
      M := Mul (X, Y, Lex);
      Check (Equal (M, XY, Lex), "x*y = xy");
      M := Mul (P2 (1, 1, 0, 1, 0, 0), P2 (1, 1, 0, -1, 0, 0), Lex);
      Check (Equal (M, P2 (1, 2, 0, -1, 0, 0), Lex), "(x+1)(x-1)=x^2-1");
      M := Mul_Term (T (2, 1, 0), P2 (1, 0, 1, 1, 0, 0), Lex);
      Check (Equal (M, P2 (2, 1, 1, 2, 1, 0), Lex), "2x*(y+1)");
      Check
        (Equal
           (Add (P1 (1, 2, 0), P1 (-1, 2, 0), Lex), Zero_Poly, Lex),
         "cancel x^2");
   end;

   ------------------------------------------------------------------
   Section ("Univariate-like division in one variable");
   ------------------------------------------------------------------
   declare
      --  (x^3 - 2 x^2 - 4) / (x - 3)  →  Q = x^2+x+3, R = 5
      F   : constant Polynomial :=
        P3 (-4, 0, 0, -2, 2, 0, 1, 3, 0);
      G   : constant Polynomial := P2 (-3, 0, 0, 1, 1, 0);
      Ds  : Poly_Array := [others => Zero_Poly];
      Quo : Poly_Array;
      Rem_P : Polynomial;
      Exp_Q : constant Polynomial :=
        P3 (3, 0, 0, 1, 1, 0, 1, 2, 0);
      Exp_R : constant Polynomial := Integer_Poly (5);
   begin
      Ds (1) := G;
      Divide (F, Ds, 1, Lex, Quo, Rem_P);
      Check (Equal (Quo (1), Exp_Q, Lex), "uni wiki quotient");
      Check (Equal (Rem_P, Exp_R, Lex), "uni wiki remainder");
      Check
        (Equal (Reconstruct (Ds, Quo, 1, Rem_P, Lex), F, Lex),
         "uni wiki reconstruct");
      Check (Rem_Clean (Rem_P, Ds, 1, Lex), "uni wiki rem clean");
   end;

   declare
      --  (y^2 - 1) / (y - 1) → Q = y+1, R = 0
      F   : constant Polynomial := P2 (-1, 0, 0, 1, 0, 2);
      G   : constant Polynomial := P2 (-1, 0, 0, 1, 0, 1);
      Ds  : Poly_Array := [others => Zero_Poly];
      Quo : Poly_Array;
      Rem_P : Polynomial;
   begin
      Ds (1) := G;
      Divide (F, Ds, 1, Lex, Quo, Rem_P);
      Check (Equal (Quo (1), P2 (1, 0, 0, 1, 0, 1), Lex), "y^2-1 quot");
      Check (Is_Zero (Rem_P), "y^2-1 rem 0");
      Check
        (Equal (Reconstruct (Ds, Quo, 1, Rem_P, Lex), F, Lex),
         "y^2-1 reconstruct");
   end;

   declare
      --  x^2 / x → Q = x, R = 0
      F   : constant Polynomial := P1 (1, 2, 0);
      G   : constant Polynomial := P1 (1, 1, 0);
      Ds  : Poly_Array := [others => Zero_Poly];
      Quo : Poly_Array;
      Rem_P : Polynomial;
   begin
      Ds (1) := G;
      Divide (F, Ds, 1, Lex, Quo, Rem_P);
      Check (Equal (Quo (1), P1 (1, 1, 0), Lex), "x^2/x quot");
      Check (Is_Zero (Rem_P), "x^2/x rem 0");
   end;

   declare
      --  (2x + 3) / (x + 1) → Q = 2, R = 1  over Q?  2(x+1)=2x+2, rem=1
      F   : constant Polynomial := P2 (3, 0, 0, 2, 1, 0);
      G   : constant Polynomial := P2 (1, 0, 0, 1, 1, 0);
      Ds  : Poly_Array := [others => Zero_Poly];
      Quo : Poly_Array;
      Rem_P : Polynomial;
   begin
      Ds (1) := G;
      Divide (F, Ds, 1, Lex, Quo, Rem_P);
      Check (Equal (Quo (1), Integer_Poly (2), Lex), "linear quot 2");
      Check (Equal (Rem_P, Integer_Poly (1), Lex), "linear rem 1");
   end;

   declare
      --  Constant dividend smaller: 5 / (x+1) → Q=0, R=5
      F   : constant Polynomial := Integer_Poly (5);
      G   : constant Polynomial := P2 (1, 0, 0, 1, 1, 0);
      Ds  : Poly_Array := [others => Zero_Poly];
      Quo : Poly_Array;
      Rem_P : Polynomial;
   begin
      Ds (1) := G;
      Divide (F, Ds, 1, Lex, Quo, Rem_P);
      Check (Is_Zero (Quo (1)), "const/linear quot 0");
      Check (Equal (Rem_P, Integer_Poly (5), Lex), "const/linear rem 5");
   end;

   ------------------------------------------------------------------
   Section ("Classic CLO textbook example (lex)");
   ------------------------------------------------------------------
   --  f = x^2 y + x y^2 + y^2
   --  f1 = x y - 1,  f2 = y^2 - 1
   --  Order (f1,f2): q1=x+y, q2=1, r=x+y+1
   --  Order (f2,f1): q1=x, q2=x+1, r=2x+1
   declare
      F  : constant Polynomial :=
        P3 (1, 2, 1, 1, 1, 2, 1, 0, 2);
      F1 : constant Polynomial := P2 (-1, 0, 0, 1, 1, 1);
      F2 : constant Polynomial := P2 (-1, 0, 0, 1, 0, 2);
      Ds : Poly_Array := [others => Zero_Poly];
      Quo : Poly_Array;
      Rem_P : Polynomial;
      Exp_Q1 : constant Polynomial := P2 (1, 1, 0, 1, 0, 1);
      Exp_R1 : constant Polynomial := P3 (1, 0, 0, 1, 1, 0, 1, 0, 1);
      Exp_R2 : constant Polynomial := P2 (1, 0, 0, 2, 1, 0);
   begin
      Ds (1) := F1;
      Ds (2) := F2;
      Divide (F, Ds, 2, Lex, Quo, Rem_P);
      Check (Equal (Quo (1), Exp_Q1, Lex), "CLO (f1,f2) q1");
      Check (Equal (Quo (2), Integer_Poly (1), Lex), "CLO (f1,f2) q2");
      Check (Equal (Rem_P, Exp_R1, Lex), "CLO (f1,f2) r = x+y+1");
      Check
        (Equal (Reconstruct (Ds, Quo, 2, Rem_P, Lex), F, Lex),
         "CLO (f1,f2) reconstruct");
      Check (Rem_Clean (Rem_P, Ds, 2, Lex), "CLO (f1,f2) rem clean");

      Ds (1) := F2;
      Ds (2) := F1;
      Divide (F, Ds, 2, Lex, Quo, Rem_P);
      --  With (f2,f1): quotients slot1 is for f2, slot2 for f1
      Check (Equal (Rem_P, Exp_R2, Lex), "CLO (f2,f1) r = 2x+1");
      Check
        (equal (Reconstruct (Ds, Quo, 2, Rem_P, Lex), F, Lex),
         "CLO (f2,f1) reconstruct");
      Check (Rem_Clean (Rem_P, Ds, 2, Lex), "CLO (f2,f1) rem clean");
      Check
        (not Equal (Exp_R1, Exp_R2, Lex),
         "order dependence: remainders differ");
   end;

   ------------------------------------------------------------------
   Section ("Another order-dependence / xy example");
   ------------------------------------------------------------------
   declare
      --  f = x y^2 + 1;  g1 = x y + 1;  g2 = y + 1
      F  : constant Polynomial := P2 (1, 0, 0, 1, 1, 2);
      G1 : constant Polynomial := P2 (1, 0, 0, 1, 1, 1);
      G2 : constant Polynomial := P2 (1, 0, 0, 1, 0, 1);
      Ds : Poly_Array := [others => Zero_Poly];
      Quo : Poly_Array;
      Rem_P : Polynomial;
   begin
      Ds (1) := G1;
      Ds (2) := G2;
      Divide (F, Ds, 2, Lex, Quo, Rem_P);
      Check (Equal (Rem_P, Integer_Poly (2), Lex), "xy^2+1 rem 2 (g1,g2)");
      Check (Equal (Quo (1), Uni_Y (One_Q, 1), Lex), "q1 = y");
      Check (Equal (Quo (2), Integer_Poly (-1), Lex), "q2 = -1");
      Check
        (Equal (Reconstruct (Ds, Quo, 2, Rem_P, Lex), F, Lex),
         "xy^2+1 reconstruct");
      Check (Rem_Clean (Rem_P, Ds, 2, Lex), "xy^2+1 rem clean");

      Ds (1) := G2;
      Ds (2) := G1;
      Divide (F, Ds, 2, Lex, Quo, Rem_P);
      --  Different divisor order → different remainder (x+1, not 2).
      Check
        (Equal (Rem_P, P2 (1, 0, 0, 1, 1, 0), Lex),
         "xy^2+1 rem x+1 (g2,g1)");
      Check
        (not Equal (Rem_P, Integer_Poly (2), Lex),
         "xy^2+1 order changes rem");
      Check
        (Equal (Reconstruct (Ds, Quo, 2, Rem_P, Lex), F, Lex),
         "xy^2+1 (g2,g1) reconstruct");
      Check (Rem_Clean (Rem_P, Ds, 2, Lex), "xy^2+1 (g2,g1) rem clean");
   end;

   ------------------------------------------------------------------
   Section ("Grevlex division");
   ------------------------------------------------------------------
   declare
      F  : constant Polynomial :=
        P3 (1, 2, 1, 1, 1, 2, 1, 0, 2);
      F1 : constant Polynomial := P2 (-1, 0, 0, 1, 1, 1);
      F2 : constant Polynomial := P2 (-1, 0, 0, 1, 0, 2);
      Ds : Poly_Array := [others => Zero_Poly];
   begin
      Ds (1) := F1;
      Ds (2) := F2;
      Check_Divide ("grevlex CLO", F, Ds, 2, Grevlex);
   end;

   declare
      F  : constant Polynomial := P2 (1, 2, 0, 1, 0, 2);  -- x^2 + y^2
      G  : constant Polynomial := P1 (1, 1, 0);           -- x
      Ds : Poly_Array := [others => Zero_Poly];
      Quo : Poly_Array;
      Rem_P : Polynomial;
   begin
      Ds (1) := G;
      Divide (F, Ds, 1, Grevlex, Quo, Rem_P);
      Check (Equal (Quo (1), P1 (1, 1, 0), Grevlex), "grevlex x^2+y^2 / x q");
      Check (Equal (Rem_P, P1 (1, 0, 2), Grevlex), "grevlex rem y^2");
      Check
        (Equal (Reconstruct (Ds, Quo, 1, Rem_P, Grevlex), F, Grevlex),
         "grevlex reconstruct");
   end;

   ------------------------------------------------------------------
   Section ("More reconstruct / rem-clean cases");
   ------------------------------------------------------------------
   declare
      Ds  : Poly_Array := [others => Zero_Poly];
      Quo : Poly_Array;
      Rem_P : Polynomial;
      F   : Polynomial;
   begin
      --  Divide x^2 y by xy → Q = x, R = 0
      F := P1 (1, 2, 1);
      Ds (1) := P1 (1, 1, 1);
      Divide (F, Ds, 1, Lex, Quo, Rem_P);
      Check (Equal (Quo (1), P1 (1, 1, 0), Lex), "x^2y / xy quot");
      Check (Is_Zero (Rem_P), "x^2y / xy rem 0");

      --  Divide x^2 + y by y → Q = 0? LT(x^2+y)=x^2 under lex, y doesn't divide
      --  then y: y divides y. So rem = x^2, q = 1
      F := P2 (1, 2, 0, 1, 0, 1);
      Ds (1) := P1 (1, 0, 1);
      Divide (F, Ds, 1, Lex, Quo, Rem_P);
      Check (Equal (Quo (1), Integer_Poly (1), Lex), "(x^2+y)/y quot");
      Check (Equal (Rem_P, P1 (1, 2, 0), Lex), "(x^2+y)/y rem x^2");
      Check (Rem_Clean (Rem_P, Ds, 1, Lex), "(x^2+y)/y rem clean");

      --  Three divisors: f = x^2 + y^2 + 1; g1=x, g2=y, g3=1? skip g3=1 trivial
      F := P3 (1, 0, 0, 1, 2, 0, 1, 0, 2);
      Ds (1) := P1 (1, 1, 0);
      Ds (2) := P1 (1, 0, 1);
      Divide (F, Ds, 2, Lex, Quo, Rem_P);
      Check
        (Equal (Reconstruct (Ds, Quo, 2, Rem_P, Lex), F, Lex),
         "x^2+y^2+1 reconstruct");
      Check (Rem_Clean (Rem_P, Ds, 2, Lex), "x^2+y^2+1 rem clean");
      Check (Equal (Rem_P, Integer_Poly (1), Lex), "x^2+y^2+1 rem 1");

      --  Exact division: (xy+1)(x+y) = x^2 y + x y^2 + x + y
      F := P4 (1, 2, 1, 1, 1, 2, 1, 1, 0, 1, 0, 1);
      Ds (1) := P2 (1, 0, 0, 1, 1, 1);
      Divide (F, Ds, 1, Lex, Quo, Rem_P);
      Check (Is_Zero (Rem_P), "exact (xy+1)(x+y) rem 0");
      Check (Equal (Quo (1), P2 (1, 1, 0, 1, 0, 1), Lex), "exact quot x+y");

      --  Fractional coeffs: (1/2 x^2) / (1/3 x) = (3/2) x
      F := Monomial (Q (1, 2), 2, 0);
      Ds (1) := Monomial (Q (1, 3), 1, 0);
      Divide (F, Ds, 1, Lex, Quo, Rem_P);
      Check (equal (Quo (1), Monomial (Q (3, 2), 1, 0), Lex), "frac quot");
      Check (Is_Zero (Rem_P), "frac rem 0");
   end;

   ------------------------------------------------------------------
   Section ("Zero dividend / identity checks");
   ------------------------------------------------------------------
   declare
      Ds  : Poly_Array := [others => Zero_Poly];
      Quo : Poly_Array;
      Rem_P : Polynomial;
   begin
      Ds (1) := P1 (1, 1, 0);
      Divide (Zero_Poly, Ds, 1, Lex, Quo, Rem_P);
      Check (Is_Zero (Quo (1)), "0/x quot 0");
      Check (Is_Zero (Rem_P), "0/x rem 0");

      Ds (1) := Integer_Poly (5);
      Divide (Integer_Poly (12), Ds, 1, Lex, Quo, Rem_P);
      --  LT both constants: t = 12/5, rem 0
      Check (Equal (Quo (1), Constant_Poly (Q (12, 5)), Lex), "12/5 quot");
      Check (Is_Zero (Rem_P), "12/5 rem 0");
   end;

   ------------------------------------------------------------------
   Section ("Bad inputs → exceptions");
   ------------------------------------------------------------------
   declare
      Ds  : Poly_Array := [others => Zero_Poly];
      Quo : Poly_Array;
      Rem_P : Polynomial;
      Raised : Boolean;
   begin
      Raised := False;
      begin
         Ds (1) := Zero_Poly;
         Divide (P1 (1, 1, 0), Ds, 1, Lex, Quo, Rem_P);
      exception
         when Division_By_Zero =>
            Raised := True;
      end;
      Check (Raised, "Division_By_Zero: zero divisor");

      Raised := False;
      begin
         Ds (1) := P1 (1, 1, 0);
         Ds (2) := Zero_Poly;
         Divide (P1 (1, 2, 0), Ds, 2, Lex, Quo, Rem_P);
      exception
         when Division_By_Zero =>
            Raised := True;
      end;
      Check (Raised, "Division_By_Zero: second divisor zero");

      Raised := False;
      begin
         declare
            Unused : Rational;
         begin
            Unused := Make_Rational (1, 0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Division_By_Zero =>
            Raised := True;
      end;
      Check (Raised, "Division_By_Zero: Make_Rational den 0");

      Raised := False;
      begin
         declare
            Unused : Term;
         begin
            Unused := Make_Term (One_Q, Max_Degree + 1, 0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument: exp overflow Make_Term");

      Raised := False;
      begin
         declare
            Unused : Polynomial;
         begin
            Unused := Monomial (One_Q, 0, Max_Degree + 1);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument: exp overflow Monomial");

      Raised := False;
      begin
         declare
            Unused : Rational;
         begin
            Unused := One_Q / Zero_Q;
            pragma Unreferenced (Unused);
         end;
      exception
         when Division_By_Zero =>
            Raised := True;
      end;
      Check (Raised, "Division_By_Zero: rational / 0");
   end;

   declare
      Ds     : constant Poly_Array := [others => Zero_Poly];
      Quo    : Poly_Array;
      Rem_P  : Polynomial;
      Raised : Boolean := False;
   begin
      begin
         Divide (P1 (1, 0, 0), Ds, 0, Lex, Quo, Rem_P);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument: empty divisor list");
   end;

   ------------------------------------------------------------------
   Section ("Extra PASS padding: compare / arithmetic grid");
   ------------------------------------------------------------------
   Check (Compare_Monomials (0, 0, 0, 0, Lex) = 0, "1 vs 1 lex");
   Check (Compare_Monomials (0, 0, 0, 0, Grevlex) = 0, "1 vs 1 grevlex");
   Check (Compare_Monomials (0, 1, 1, 0, Lex) < 0, "y < x lex");
   Check (Compare_Monomials (0, 1, 1, 0, Grevlex) < 0, "y < x grevlex deg1");
   Check (Compare_Monomials (3, 0, 0, 3, Lex) > 0, "x^3 > y^3 lex");
   Check (Compare_Monomials (3, 0, 0, 3, Grevlex) > 0, "x^3 > y^3 grevlex");
   Check (Equal (Q (6, 9), Q (2, 3)), "6/9=2/3");
   Check (Equal (Q (-4, -6), Q (2, 3)), "(-4)/(-6)=2/3");
   Check (Equal (Add (Zero_Poly, P1 (1, 0, 0), Lex), Integer_Poly (1), Lex),
          "0+1");
   Check (equal (Sub (P1 (1, 0, 0), Zero_Poly, Lex), Integer_Poly (1), Lex),
          "1-0");
   Check (Equal (Mul (Zero_Poly, P1 (1, 1, 1), Lex), Zero_Poly, Lex), "0*xy");
   Check (Equal (Mul (P1 (1, 0, 0), P1 (1, 0, 0), Lex), Integer_Poly (1), Lex),
          "1*1");
   Check (Is_Zero (LT (Zero_Poly, Lex).Coeff), "LT(0) coeff 0");
   Check (Equal (LC (P1 (4, 2, 3), Lex), Q (4)), "LC 4 x^2 y^3");

   declare
      EX, EY : Exp_Type;
      Ok     : Boolean;
   begin
      Ok := LM (P1 (1, 2, 3), Lex, EX, EY);
      Check (Ok and then EX = 2 and then EY = 3, "LM of x^2 y^3");
      Ok := LM (Zero_Poly, Lex, EX, EY);
      Check (not Ok, "LM of zero is False");
   end;

   declare
      Ds  : Poly_Array := [others => Zero_Poly];
      F   : constant Polynomial :=
        Add (P1 (1, 3, 0), P1 (1, 0, 3), Lex);  -- x^3 + y^3
   begin
      Ds (1) := P2 (1, 1, 0, 1, 0, 1);  -- x+y
      --  x^3+y^3 = (x+y)(x^2 - xy + y^2)
      Check_Divide ("x^3+y^3 by x+y", F, Ds, 1, Lex, Zero_Poly, True);
   end;

   declare
      Ds : Poly_Array := [others => Zero_Poly];
      F  : constant Polynomial := P1 (1, 2, 2);  -- x^2 y^2
   begin
      Ds (1) := P1 (1, 1, 0);
      Ds (2) := P1 (1, 0, 1);
      Check_Divide ("x^2 y^2 by x,y", F, Ds, 2, Lex);
      Check_Divide ("x^2 y^2 by x,y grevlex", F, Ds, 2, Grevlex);
   end;

   declare
      Ds : Poly_Array := [others => Zero_Poly];
      F  : constant Polynomial :=
        P3 (1, 1, 1, 2, 0, 0, -1, 2, 0);  -- -x^2 + xy + 2
   begin
      Ds (1) := P1 (1, 1, 0);
      Check_Divide ("-x^2+xy+2 by x", F, Ds, 1, Lex);
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Pass_Count'Image & " PASS, " & Fail_Count'Image & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
