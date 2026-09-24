--  Standalone test suite for Buchbergers_Algorithm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Buchbergers_Algorithm; use Buchbergers_Algorithm;

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

   function P1 (C, EX, EY : Integer) return Polynomial is
     (Monomial (Q (C), Natural (EX), Natural (EY)));

   function P2
     (C1, X1, Y1, C2, X2, Y2 : Integer) return Polynomial
   is
   begin
      return Add (P1 (C1, X1, Y1), P1 (C2, X2, Y2), Grevlex);
   end P2;

   function P3
     (C1, X1, Y1, C2, X2, Y2, C3, X3, Y3 : Integer) return Polynomial
   is
   begin
      return Add (P2 (C1, X1, Y1, C2, X2, Y2), P1 (C3, X3, Y3), Grevlex);
   end P3;

   function Has_LT
     (Basis  : Poly_Array;
      B_N    : Poly_Count;
      Order  : Monomial_Order;
      EX, EY : Natural) return Boolean
   is
      T : Term;
   begin
      for I in 1 .. B_N loop
         if not Is_Zero (Basis (I)) then
            T := LT (Basis (I), Order);
            if Natural (T.Exp_X) = EX and then Natural (T.Exp_Y) = EY then
               return True;
            end if;
         end if;
      end loop;
      return False;
   end Has_LT;

begin
   ------------------------------------------------------------------
   Section ("Rational arithmetic");
   ------------------------------------------------------------------
   Check (Equal (Q (2, 4), Q (1, 2)), "reduce 2/4 = 1/2");
   Check (Equal (Q (-3, 6), Q (-1, 2)), "reduce -3/6");
   Check (Equal (Q (3, -6), Q (-1, 2)), "sign moves to num");
   Check (Equal (Q (1, 2) + Q (1, 3), Q (5, 6)), "1/2+1/3");
   Check (Equal (Q (1, 2) - Q (1, 3), Q (1, 6)), "1/2-1/3");
   Check (equal (Q (2, 3) * Q (3, 4), Q (1, 2)), "2/3*3/4");
   Check (equal (Q (2, 3) / Q (4, 5), Q (5, 6)), "2/3 / 4/5");
   Check (Is_Zero (Q (0, 7)), "0/7 is zero");
   Check (not Is_Zero (Q (1, 7)), "1/7 not zero");
   Check (equal (-Q (2, 5), Q (-2, 5)), "unary minus");

   ------------------------------------------------------------------
   Section ("Monomial compare / LCM / divides");
   ------------------------------------------------------------------
   Check (Compare_Monomials (2, 0, 1, 5, Lex) > 0, "lex x^2 > x y^5");
   Check (Compare_Monomials (1, 0, 0, 5, Lex) > 0, "lex x > y^5");
   Check (Compare_Monomials (2, 0, 1, 1, Grevlex) > 0, "grevlex x^2 > xy");
   Check (Compare_Monomials (1, 1, 0, 2, Grevlex) > 0, "grevlex xy > y^2");
   Check (Compare_Monomials (1, 1, 1, 1, Grevlex) = 0, "grevlex equal");
   Check (Monomial_Divides (1, 0, 2, 3), "x divides x^2 y^3");
   Check (not Monomial_Divides (2, 0, 1, 5), "x^2 does not divide x y^5");
   declare
      LX, LY : Exp_Type;
   begin
      Monomial_LCM (2, 1, 1, 3, LX, LY);
      Check (LX = 2 and then LY = 3, "LCM(x^2 y, x y^3)=x^2 y^3");
   end;

   ------------------------------------------------------------------
   Section ("Polynomial arithmetic");
   ------------------------------------------------------------------
   declare
      A : constant Polynomial := P2 (1, 2, 0, 1, 0, 1);  -- x^2 + y
      B : constant Polynomial := P2 (1, 1, 1, -1, 0, 0); -- xy - 1
      C : Polynomial;
   begin
      Check (not Is_Zero (A), "x^2+y nonzero");
      Check (equal (Add (A, Scale (A, Q (-1), Grevlex), Grevlex),
                    Zero_Poly, Grevlex),
             "A + (-A) = 0");
      C := Mul (P1 (1, 1, 0), B, Grevlex);  -- x*(xy-1) = x^2 y - x
      Check (Equal (C, P2 (1, 2, 1, -1, 1, 0), Grevlex), "x*(xy-1)");
      Check (Natural (LT (A, Grevlex).Exp_X) = 2
               and then Natural (LT (A, Grevlex).Exp_Y) = 0,
             "LT_grevlex(x^2+y)=x^2");
      Check (Natural (LT (A, Lex).Exp_X) = 2, "LT_lex(x^2+y)=x^2");
      Check (equal (Add (P1 (1, 1, 0), P1 (2, 1, 0), Grevlex),
                    P1 (3, 1, 0), Grevlex),
             "like terms 1x+2x=3x");
      Check (Is_Zero (Add (P1 (1, 1, 0), P1 (-1, 1, 0), Grevlex)),
             "x + (-x) = 0");
      Check (equal (Integer_Poly (5), Constant_Poly (Q (5)), Grevlex),
             "Integer_Poly");
      Check (equal (Uni_X (Q (2), 3), P1 (2, 3, 0), Grevlex), "Uni_X");
      Check (equal (Uni_Y (Q (2), 3), P1 (2, 0, 3), Grevlex), "Uni_Y");
   end;

   ------------------------------------------------------------------
   Section ("S-polynomial and normal form");
   ------------------------------------------------------------------
   declare
      F1 : constant Polynomial := P2 (1, 2, 0, -1, 0, 1); -- x^2 - y
      F2 : constant Polynomial := P2 (1, 1, 1, -1, 0, 0); -- xy - 1
      S  : Polynomial;
      G  : Poly_Array := [others => Zero_Poly];
      NF : Polynomial;
   begin
      S := S_Polynomial (F1, F2, Grevlex);
      --  LCM(x^2,xy)=x^2 y; S = y(x^2-y) - x(xy-1) = x - y^2
      Check (equal (S, P2 (1, 1, 0, -1, 0, 2), Grevlex)
               or else Equal (S, P2 (-1, 0, 2, 1, 1, 0), Grevlex),
             "S(x^2-y, xy-1) = x - y^2");

      G (1) := F1;
      G (2) := F2;
      NF := Normal_Form (S, G, 2, Grevlex);
      Check (not Is_Zero (NF), "NF of S not zero before GB");
      Check (Is_Zero (Normal_Form (F1, G, 2, Grevlex)),
             "generator F1 reduces to 0");
      Check (Is_Zero (Normal_Form (F2, G, 2, Grevlex)),
             "generator F2 reduces to 0");
   end;

   ------------------------------------------------------------------
   Section ("Buchberger: I = <x^2 - y, xy - 1> grevlex");
   ------------------------------------------------------------------
   declare
      Gens : Poly_Array := [others => Zero_Poly];
      Bas  : Poly_Array;
      B_N  : Poly_Count;
      Done : Boolean;
      Comb : Polynomial;
   begin
      Gens (1) := P2 (1, 2, 0, -1, 0, 1);  -- x^2 - y
      Gens (2) := P2 (1, 1, 1, -1, 0, 0);  -- xy - 1
      Groebner_Basis (Gens, 2, Grevlex, Bas, B_N, Done);
      Check (Done, "Buchberger completes on <x^2-y, xy-1>");
      Check (B_N >= 2, "GB has at least 2 polys");
      Check (Is_Groebner (Bas, B_N, Grevlex),
             "Is_Groebner true on output (grevlex)");
      Check (Has_LT (Bas, B_N, Grevlex, 0, 2)
               or else Has_LT (Bas, B_N, Grevlex, 1, 0),
             "GB has LT y^2 or x (from x - y^2)");
      Check (Has_LT (Bas, B_N, Grevlex, 2, 0)
               or else Has_LT (Bas, B_N, Grevlex, 1, 1)
               or else Has_LT (Bas, B_N, Grevlex, 1, 0),
             "GB has LT involving x");

      Comb := Sub
        (Mul_Term (Make_Term (Q (1), 0, 1), Gens (1), Grevlex),
         Mul_Term (Make_Term (Q (1), 1, 0), Gens (2), Grevlex),
         Grevlex);
      Check (Is_Zero (Normal_Form (Comb, Bas, B_N, Grevlex)),
             "combination x-y^2 in ideal reduces to 0");

      Comb := P2 (1, 0, 3, -1, 0, 0);  -- y^3 - 1
      Check (Is_Zero (Normal_Form (Comb, Bas, B_N, Grevlex)),
             "y^3-1 reduces to 0 w.r.t. GB");

      Check (Is_Zero (Normal_Form (Gens (1), Bas, B_N, Grevlex)),
             "x^2-y in ideal");
      Check (Is_Zero (Normal_Form (Gens (2), Bas, B_N, Grevlex)),
             "xy-1 in ideal");
      Check (not Is_Zero (Normal_Form (Integer_Poly (1), Bas, B_N, Grevlex)),
             "1 not in ideal");
   end;

   ------------------------------------------------------------------
   Section ("Buchberger: I = <x^2 + y, xy - 1> grevlex");
   ------------------------------------------------------------------
   declare
      Gens : Poly_Array := [others => Zero_Poly];
      Bas  : Poly_Array;
      B_N  : Poly_Count;
      Done : Boolean;
      Comb : Polynomial;
   begin
      Gens (1) := P2 (1, 2, 0, 1, 0, 1);   -- x^2 + y
      Gens (2) := P2 (1, 1, 1, -1, 0, 0);  -- xy - 1
      Groebner_Basis (Gens, 2, Grevlex, Bas, B_N, Done);
      Check (Done, "Buchberger completes on <x^2+y, xy-1>");
      Check (B_N >= 2, "GB nonempty (>=2)");
      Check (Is_Groebner (Bas, B_N, Grevlex),
             "Is_Groebner for <x^2+y,xy-1>");
      Check (Is_Zero (Normal_Form (Gens (1), Bas, B_N, Grevlex)),
             "x^2+y reduces to 0");
      Check (Is_Zero (Normal_Form (Gens (2), Bas, B_N, Grevlex)),
             "xy-1 reduces to 0");
      Comb := S_Polynomial (Gens (1), Gens (2), Grevlex);
      Check (Is_Zero (Normal_Form (Comb, Bas, B_N, Grevlex)),
             "S(gens) reduces to 0 w.r.t. GB");
   end;

   ------------------------------------------------------------------
   Section ("Buchberger: I = <x + y, xy> lex");
   ------------------------------------------------------------------
   declare
      Gens : Poly_Array := [others => Zero_Poly];
      Bas  : Poly_Array;
      B_N  : Poly_Count;
      Done : Boolean;
   begin
      Gens (1) := P2 (1, 1, 0, 1, 0, 1);  -- x + y
      Gens (2) := P1 (1, 1, 1);           -- xy
      Groebner_Basis (Gens, 2, Lex, Bas, B_N, Done);
      Check (Done, "Buchberger completes on <x+y, xy> lex");
      Check (Is_Groebner (Bas, B_N, Lex), "Is_Groebner lex");
      Check (Is_Zero (Normal_Form (P1 (1, 0, 2), Bas, B_N, Lex))
               or else Has_LT (Bas, B_N, Lex, 0, 2)
               or else Has_LT (Bas, B_N, Lex, 0, 1),
             "y^2 or y in LT ideal");
      Check (Is_Zero (Normal_Form (Gens (1), Bas, B_N, Lex)),
             "x+y in ideal lex");
      Check (Is_Zero (Normal_Form (Gens (2), Bas, B_N, Lex)),
             "xy in ideal lex");
   end;

   ------------------------------------------------------------------
   Section ("Buchberger: I = <x^2 - 1, y^2 - 1> grevlex (coprime LTs)");
   ------------------------------------------------------------------
   declare
      Gens : Poly_Array := [others => Zero_Poly];
      Bas  : Poly_Array;
      B_N  : Poly_Count;
      Done : Boolean;
   begin
      Gens (1) := P2 (1, 2, 0, -1, 0, 0); -- x^2 - 1
      Gens (2) := P2 (1, 0, 2, -1, 0, 0); -- y^2 - 1
      Groebner_Basis (Gens, 2, Grevlex, Bas, B_N, Done);
      Check (Done, "Buchberger completes on <x^2-1, y^2-1>");
      Check (Is_Groebner (Bas, B_N, Grevlex),
             "Is_Groebner for coprime LTs");
      Check (Has_LT (Bas, B_N, Grevlex, 2, 0), "LT x^2 present");
      Check (Has_LT (Bas, B_N, Grevlex, 0, 2), "LT y^2 present");
      Check (Is_Zero (Normal_Form (P2 (1, 2, 0, -1, 0, 0), Bas, B_N, Grevlex)),
             "x^2-1 reduces to 0");
      Check (not Is_Zero (Normal_Form (P1 (1, 1, 0), Bas, B_N, Grevlex)),
             "x not in ideal");
   end;

   ------------------------------------------------------------------
   Section ("Buchberger: three generators");
   ------------------------------------------------------------------
   declare
      Gens : Poly_Array := [others => Zero_Poly];
      Bas  : Poly_Array;
      B_N  : Poly_Count;
      Done : Boolean;
      Comb : Polynomial;
   begin
      Gens (1) := P2 (1, 2, 0, 1, 0, 1);   -- x^2 + y
      Gens (2) := P2 (1, 1, 1, -1, 0, 0);  -- xy - 1
      Gens (3) := P2 (1, 0, 2, 1, 1, 0);   -- y^2 + x
      Groebner_Basis (Gens, 3, Grevlex, Bas, B_N, Done);
      Check (Done, "Buchberger completes with 3 generators");
      Check (Is_Groebner (Bas, B_N, Grevlex), "Is_Groebner 3-gen");
      Comb := Add
        (Mul (Integer_Poly (2), Gens (1), Grevlex),
         Mul (P1 (1, 0, 1), Gens (2), Grevlex), Grevlex);
      Check (Is_Zero (Normal_Form (Comb, Bas, B_N, Grevlex)),
             "linear combination in ideal");
      Check (Is_Zero (Normal_Form (Gens (1), Bas, B_N, Grevlex)),
             "gen1 reduces to 0");
      Check (Is_Zero (Normal_Form (Gens (2), Bas, B_N, Grevlex)),
             "gen2 reduces to 0");
      Check (Is_Zero (Normal_Form (Gens (3), Bas, B_N, Grevlex)),
             "gen3 reduces to 0");
   end;

   ------------------------------------------------------------------
   Section ("Univariate GCD-like special case");
   ------------------------------------------------------------------
   --  In one variable Buchberger degenerates toward Euclidean GCD.
   --  <x^2 - 1, x - 1>  →  GB containing x - 1 (and possibly constants 0).
   declare
      Gens : Poly_Array := [others => Zero_Poly];
      Bas  : Poly_Array;
      B_N  : Poly_Count;
      Done : Boolean;
   begin
      Gens (1) := P2 (1, 2, 0, -1, 0, 0); -- x^2 - 1
      Gens (2) := P2 (1, 1, 0, -1, 0, 0); -- x - 1
      Groebner_Basis (Gens, 2, Lex, Bas, B_N, Done);
      Check (Done, "univariate-like completes");
      Check (Is_Groebner (Bas, B_N, Lex), "Is_Groebner univariate-like");
      Check (Has_LT (Bas, B_N, Lex, 1, 0)
               or else Has_LT (Bas, B_N, Lex, 0, 0),
             "LT is x or constant (GCD-like)");
      Check (Is_Zero (Normal_Form (Gens (1), Bas, B_N, Lex)),
             "x^2-1 in <x-1>");
      Check (Is_Zero (Normal_Form (Gens (2), Bas, B_N, Lex)),
             "x-1 reduces to 0");
      Check (not Is_Zero (Normal_Form (Integer_Poly (1), Bas, B_N, Lex))
               or else Has_LT (Bas, B_N, Lex, 0, 0),
             "1 not in proper ideal (or GB has constant)");
   end;

   ------------------------------------------------------------------
   Section ("Leading-term ideals on known examples");
   ------------------------------------------------------------------
   declare
      Gens : Poly_Array := [others => Zero_Poly];
      Bas  : Poly_Array;
      B_N  : Poly_Count;
      Done : Boolean;
      F    : Polynomial;
   begin
      --  <xy - 1, x^2 - y> grevlex: expect LT ideal containing y^2 and x
      --  (or equivalent generators)
      Gens (1) := P2 (1, 1, 1, -1, 0, 0);  -- xy - 1
      Gens (2) := P2 (1, 2, 0, -1, 0, 1);  -- x^2 - y
      Groebner_Basis (Gens, 2, Grevlex, Bas, B_N, Done);
      Check (Done, "LT-ideal example completes");
      Check (Is_Groebner (Bas, B_N, Grevlex), "LT-ideal Is_Groebner");
      F := P1 (1, 0, 4);  -- y^4 should be in <LT(GB)> if y^2 in LT
      Check (LT_In_Ideal (F, Bas, B_N, Grevlex)
               or else Is_Zero (Normal_Form (P2 (1, 0, 3, -1, 0, 0),
                                            Bas, B_N, Grevlex)),
             "y-power in LT ideal or y^3-1 in ideal");
      F := P1 (1, 3, 0);
      Check (LT_In_Ideal (F, Bas, B_N, Grevlex)
               or else Has_LT (Bas, B_N, Grevlex, 1, 0)
               or else Has_LT (Bas, B_N, Grevlex, 2, 0),
             "x-power covered by LT ideal");
   end;

   ------------------------------------------------------------------
   Section ("Single generator is already a GB");
   ------------------------------------------------------------------
   declare
      Gens : Poly_Array := [others => Zero_Poly];
      Bas  : Poly_Array;
      B_N  : Poly_Count;
      Done : Boolean;
   begin
      Gens (1) := P3 (1, 2, 1, -3, 1, 0, 2, 0, 0); -- x^2 y - 3x + 2
      Groebner_Basis (Gens, 1, Grevlex, Bas, B_N, Done);
      Check (Done, "single generator completes");
      Check (B_N = 1, "single generator stays size 1");
      Check (Is_Groebner (Bas, B_N, Grevlex), "single gen Is_Groebner");
   end;

   ------------------------------------------------------------------
   Section ("Bad input / bounds");
   ------------------------------------------------------------------
   declare
      Gens : Poly_Array := [others => Zero_Poly];
      Bas  : Poly_Array;
      B_N  : Poly_Count;
      Done : Boolean;
      Raised : Boolean;
   begin
      Raised := False;
      begin
         Groebner_Basis (Gens, 0, Grevlex, Bas, B_N, Done);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "N=0 raises Invalid_Argument");

      Raised := False;
      Gens (1) := Zero_Poly;
      Gens (2) := P1 (1, 1, 0);
      begin
         Groebner_Basis (Gens, 2, Grevlex, Bas, B_N, Done);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "zero generator raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Unused : Rational;
         begin
            Unused := Q (1, 0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Division_By_Zero =>
            Raised := True;
      end;
      Check (Raised, "1/0 raises Division_By_Zero");

      Raised := False;
      begin
         declare
            Unused : Polynomial;
         begin
            Unused := S_Polynomial (Zero_Poly, P1 (1, 1, 0), Grevlex);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "S_Polynomial(0,x) raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Unused : Polynomial;
            D : constant Poly_Array := [others => Zero_Poly];
         begin
            Unused := Normal_Form (P1 (1, 1, 0), D, 0, Grevlex);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Normal_Form N=0 raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Unused : Boolean;
            D : constant Poly_Array := [others => Zero_Poly];
         begin
            Unused := Is_Groebner (D, 0, Grevlex);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Is_Groebner N=0 raises Invalid_Argument");

      --  Max_Steps=0: incomplete
      Gens (1) := P2 (1, 2, 0, -1, 0, 1);
      Gens (2) := P2 (1, 1, 1, -1, 0, 0);
      Groebner_Basis (Gens, 2, Grevlex, Bas, B_N, Done, Max_Steps => 0);
      Check (not Done, "Max_Steps=0 yields incomplete");

      Raised := False;
      begin
         declare
            Unused : Term;
         begin
            Unused := Make_Term (Q (1), Max_Degree + 1, 0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "exp > Max_Degree raises Invalid_Argument");
   end;

   ------------------------------------------------------------------
   Section ("LT_In_Ideal helper");
   ------------------------------------------------------------------
   declare
      Bas : Poly_Array := [others => Zero_Poly];
      F   : Polynomial;
   begin
      Bas (1) := P2 (1, 2, 0, -1, 0, 0); -- x^2 - 1
      Bas (2) := P2 (1, 0, 2, -1, 0, 0); -- y^2 - 1
      F := P1 (1, 3, 0); -- x^3
      Check (LT_In_Ideal (F, Bas, 2, Grevlex), "x^3 in <x^2,y^2>");
      F := P1 (1, 0, 1); -- y
      Check (not LT_In_Ideal (F, Bas, 2, Grevlex), "y not in <x^2,y^2>");
      Check (LT_In_Ideal (Zero_Poly, Bas, 2, Grevlex), "0 in LT ideal");
   end;

   ------------------------------------------------------------------
   Section ("Lex GB for <x^2 - y, y - 1>");
   ------------------------------------------------------------------
   declare
      Gens : Poly_Array := [others => Zero_Poly];
      Bas  : Poly_Array;
      B_N  : Poly_Count;
      Done : Boolean;
   begin
      Gens (1) := P2 (1, 2, 0, -1, 0, 1); -- x^2 - y
      Gens (2) := P2 (1, 0, 1, -1, 0, 0); -- y - 1
      Groebner_Basis (Gens, 2, Lex, Bas, B_N, Done);
      Check (Done, "lex <x^2-y, y-1> completes");
      Check (Is_Groebner (Bas, B_N, Lex), "Is_Groebner lex textbook");
      --  Expect x^2 - 1 and y - 1 essentially
      Check (Is_Zero (Normal_Form (P2 (1, 2, 0, -1, 0, 0), Bas, B_N, Lex)),
             "x^2-1 in ideal lex");
      Check (Is_Zero (Normal_Form (Gens (2), Bas, B_N, Lex)),
             "y-1 reduces to 0");
   end;

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
