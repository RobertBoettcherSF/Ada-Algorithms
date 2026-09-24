--  Standalone test suite for Cantor_Zassenhaus (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Cantor_Zassenhaus; use Cantor_Zassenhaus;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
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

   --  Non-static views (avoid -gnatwc constant-condition warnings).
   function N (X : Natural) return Natural is (X);
   function U (X : U64) return U64 is (X);

   function Poly_Of
     (Modulus : Natural;
      C0 : Natural;
      C1 : Natural := 0;
      C2 : Natural := 0;
      C3 : Natural := 0;
      C4 : Natural := 0;
      C5 : Natural := 0;
      C6 : Natural := 0) return Polynomial
   is
      C : Coeff_Array := [others => 0];
      Last : Degree_Index := 0;
   begin
      C (0) := C0;
      C (1) := C1;
      C (2) := C2;
      C (3) := C3;
      C (4) := C4;
      C (5) := C5;
      C (6) := C6;
      Last := 0;
      for I in reverse Degree_Index loop
         if C (I) rem Modulus /= 0 then
            Last := I;
            exit;
         end if;
      end loop;
      return From_Coeffs (C, Last, Modulus);
   end Poly_Of;

   function Product
     (Factors : Factor_Array;
      Count   : Natural;
      Modulus : Natural) return Polynomial
   is
      R : Polynomial := Constant_Poly (1, Modulus);
   begin
      for I in 1 .. Count loop
         R := Mul (R, Factors (I), Modulus);
      end loop;
      return R;
   end Product;

   function All_Monic
     (Factors : Factor_Array; Count, Modulus : Natural) return Boolean
   is
   begin
      for I in 1 .. Count loop
         if Leading_Coefficient (Factors (I), Modulus) /= 1 then
            return False;
         end if;
      end loop;
      return True;
   end All_Monic;

   procedure Expect_Invalid_Factor
     (Label : String; P : Natural; Poly : Polynomial)
   is
      Raised  : Boolean := False;
      Factors : Factor_Array;
      Count   : Natural;
      Seed    : U64 := U (1);
   begin
      begin
         Factor (P, Poly, Factors, Count, Seed);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Factor: " & Label);
   end Expect_Invalid_Factor;

   procedure Check_Factor_Product
     (Label   : String;
      P       : Natural;
      Input   : Polynomial;
      Seed0   : U64;
      Min_Cnt : Natural := 1)
   is
      Factors : Factor_Array;
      Count   : Natural;
      Seed    : U64 := Seed0;
      SF, Prod : Polynomial;
   begin
      Factor (P, Input, Factors, Count, Seed);
      SF   := Square_Free (Make_Monic (Normalize (Input, P), P), P);
      Prod := Product (Factors, Count, P);
      Check (Count >= Min_Cnt, Label & " count>=" & Min_Cnt'Image);
      Check (All_Monic (Factors, Count, P), Label & " all monic");
      Check (Equal (Prod, SF, P), Label & " product recovers square-free");
   end Check_Factor_Product;

begin
   ------------------------------------------------------------------
   Section ("Modular helpers");
   ------------------------------------------------------------------
   Check (Is_Prime_Trial (N (3)), "3 is prime");
   Check (Is_Prime_Trial (N (5)), "5 is prime");
   Check (Is_Prime_Trial (N (7)), "7 is prime");
   Check (Is_Prime_Trial (N (11)), "11 is prime");
   Check (not Is_Prime_Trial (N (1)), "1 not prime");
   Check (not Is_Prime_Trial (N (9)), "9 not prime");
   Check (not Is_Prime_Trial (N (15)), "15 not prime");
   Check (Mul_Mod (N (6), N (7), N (5)) = 2, "Mul_Mod 6*7 mod 5 = 2");
   Check (Mod_Pow (N (2), N (4), N (5)) = 1, "Mod_Pow 2^4 mod 5 = 1");
   Check (Mod_Inv (N (3), N (5)) = 2, "Mod_Inv 3 mod 5 = 2");
   Check (Mod_Inv (N (2), N (7)) = 4, "Mod_Inv 2 mod 7 = 4");

   ------------------------------------------------------------------
   Section ("Polynomial arithmetic F_5");
   ------------------------------------------------------------------
   declare
      P : constant Natural := 5;
      A : constant Polynomial := Poly_Of (P, 1, 2, 1);      -- 1+2x+x^2
      B : constant Polynomial := Poly_Of (P, 2, 1);         -- 2+x
      S, D, M, G : Polynomial;
      Q, R : Polynomial;
   begin
      Check (Degree (A, P) = 2, "deg(1+2x+x^2)=2");
      Check (Degree (Zero_Poly, P) = -1, "deg(0)=-1");
      Check (Is_Zero (Zero_Poly, P), "Is_Zero(0)");
      S := Add (A, B, P);
      Check (Equal (S, Poly_Of (P, 3, 3, 1), P), "Add in F_5");
      D := Sub (A, B, P);
      Check (Equal (D, Poly_Of (P, 4, 1, 1), P), "Sub in F_5");
      M := Mul (B, B, P);  -- (x+2)^2 = x^2+4x+4
      Check (Equal (M, Poly_Of (P, 4, 4, 1), P), "Mul (x+2)^2");
      Div_Mod (A, B, P, Q, R);
      Check
        (Equal (Add (Mul (Q, B, P), R, P), Normalize (A, P), P),
         "Div_Mod identity A=QB+R");
      G := GCD (A, B, P);
      Check (Leading_Coefficient (G, P) = 1, "GCD monic");
      Check (Degree (G, P) >= 0, "GCD non-empty");
   end;

   ------------------------------------------------------------------
   Section ("GCD / monic / square-free");
   ------------------------------------------------------------------
   declare
      P : constant Natural := 7;
      --  (x+1)(x+2) = x^2+3x+2
      F : constant Polynomial := Poly_Of (P, 2, 3, 1);
      --  (x+1)^2 = x^2+2x+1
      Sq : constant Polynomial := Poly_Of (P, 1, 2, 1);
      G, SF : Polynomial;
   begin
      G := GCD (F, Poly_Of (P, 1, 1), P);  -- gcd with (x+1)
      Check (Equal (G, Poly_Of (P, 1, 1), P), "GCD((x+1)(x+2),x+1)=x+1");
      Check
        (Equal (Make_Monic (Poly_Of (P, 2, 4, 2), P),
                Poly_Of (P, 1, 2, 1), P),
         "Make_Monic scales LC");
      SF := Square_Free (Sq, P);
      Check (Equal (SF, Poly_Of (P, 1, 1), P), "Square_Free (x+1)^2 -> x+1");
      SF := Square_Free (F, P);
      Check (Equal (SF, Make_Monic (F, P), P), "Square_Free already sf");
   end;

   ------------------------------------------------------------------
   Section ("Mod_Exp");
   ------------------------------------------------------------------
   declare
      P : constant Natural := 5;
      --  mod (x^2+1) over F_5; x^2 ≡ 4 = -1, so x^4 ≡ 1
      M : constant Polynomial := Poly_Of (P, 1, 0, 1);
      X : constant Polynomial := Monomial (1, 1, P);
      R : Polynomial;
   begin
      R := Mod_Exp (X, 4, M, P);
      Check (Equal (R, Constant_Poly (1, P), P), "x^4 ≡ 1 mod (x^2+1) in F_5");
      R := Mod_Exp (X, 2, M, P);
      Check (Equal (R, Constant_Poly (4, P), P), "x^2 ≡ 4 mod (x^2+1)");
   end;

   ------------------------------------------------------------------
   Section ("Factor linear / irreducible");
   ------------------------------------------------------------------
   declare
      P : constant Natural := 5;
      Factors : Factor_Array;
      Count   : Natural;
      Seed    : U64;
      Lin : constant Polynomial := Poly_Of (P, 2, 1);  -- x+2
      --  x^2+2 irreducible over F_5 (no root)
      Irr : constant Polynomial := Poly_Of (P, 2, 0, 1);
   begin
      Seed := U (42);
      Factor (P, Lin, Factors, Count, Seed);
      Check (Count = 1, "linear: one factor");
      Check (Equal (Factors (1), Make_Monic (Lin, P), P), "linear factor");

      Seed := U (7);
      Factor (P, Irr, Factors, Count, Seed);
      Check (Count = 1, "irreducible quadratic: one factor");
      Check (Equal (Factors (1), Irr, P), "irreducible unchanged");
   end;

   ------------------------------------------------------------------
   Section ("Factor products over F_3");
   ------------------------------------------------------------------
   declare
      P : constant Natural := 3;
      --  (x+1)(x+2) = x^2+0x+2
      F : constant Polynomial := Poly_Of (P, 2, 0, 1);
   begin
      Check_Factor_Product ("F3 (x+1)(x+2)", P, F, U (1), 2);
   end;

   declare
      P : constant Natural := 3;
      --  (x^2+1) irreducible over F_3; product with (x+1):
      --  (x^2+1)(x+1) = x^3+x^2+x+1
      F : constant Polynomial := Poly_Of (P, 1, 1, 1, 1);
   begin
      Check_Factor_Product ("F3 (x^2+1)(x+1)", P, F, U (99), 2);
   end;

   ------------------------------------------------------------------
   Section ("Factor products over F_5");
   ------------------------------------------------------------------
   declare
      P : constant Natural := 5;
      --  (x+1)(x+2) = x^2+3x+2
      F : constant Polynomial := Poly_Of (P, 2, 3, 1);
   begin
      Check_Factor_Product ("F5 (x+1)(x+2)", P, F, U (3), 2);
   end;

   declare
      P : constant Natural := 5;
      --  (x^2+2)(x^2+x+1): both irr over F_5
      --  x^4+x^3+3x^2+2x+2
      A : constant Polynomial := Poly_Of (P, 2, 0, 1);
      B : constant Polynomial := Poly_Of (P, 1, 1, 1);
      F : constant Polynomial := Mul (A, B, P);
   begin
      Check_Factor_Product ("F5 (x^2+2)(x^2+x+1)", P, F, U (11), 2);
   end;

   declare
      P : constant Natural := 5;
      --  three linears: (x)(x+1)(x+2) = x(x^2+3x+2)=x^3+3x^2+2x
      F : constant Polynomial := Poly_Of (P, 0, 2, 3, 1);
   begin
      Check_Factor_Product ("F5 x(x+1)(x+2)", P, F, U (5), 3);
   end;

   ------------------------------------------------------------------
   Section ("Factor products over F_7");
   ------------------------------------------------------------------
   declare
      P : constant Natural := 7;
      --  (x+1)(x+3)=x^2+4x+3
      F : constant Polynomial := Poly_Of (P, 3, 4, 1);
   begin
      Check_Factor_Product ("F7 (x+1)(x+3)", P, F, U (2), 2);
   end;

   declare
      P : constant Natural := 7;
      --  x^2+1 irr over F_7? roots: 0->1,1->2,2->5,3->10≡3,4->17≡3,5->26≡5,6->37≡2. Yes irr.
      --  (x^2+1)(x+1)=x^3+x^2+x+1
      F : constant Polynomial := Poly_Of (P, 1, 1, 1, 1);
   begin
      Check_Factor_Product ("F7 (x^2+1)(x+1)", P, F, U (17), 2);
   end;

   ------------------------------------------------------------------
   Section ("Factor products over F_11");
   ------------------------------------------------------------------
   declare
      P : constant Natural := 11;
      F : constant Polynomial := Poly_Of (P, 6, 5, 1);  -- (x+2)(x+3)=x^2+5x+6
   begin
      Check_Factor_Product ("F11 (x+2)(x+3)", P, F, U (8), 2);
   end;

   declare
      P : constant Natural := 11;
      --  (x+1)(x+2)(x+3)= (x^2+3x+2)(x+3)=x^3+6x^2+11x+6 ≡ x^3+6x^2+0x+6
      F : constant Polynomial := Poly_Of (P, 6, 0, 6, 1);
   begin
      Check_Factor_Product ("F11 (x+1)(x+2)(x+3)", P, F, U (21), 3);
   end;

   ------------------------------------------------------------------
   Section ("Square-free kernel of squared factor");
   ------------------------------------------------------------------
   declare
      P : constant Natural := 5;
      --  (x+1)^2 (x+2) = (x^2+2x+1)(x+2)=x^3+4x^2+5x+2 ≡ x^3+4x^2+0x+2
      F : constant Polynomial := Poly_Of (P, 2, 0, 4, 1);
      Factors : Factor_Array;
      Count   : Natural;
      Seed    : U64 := U (13);
      SF, Prod : Polynomial;
   begin
      SF := Square_Free (F, P);
      --  should be (x+1)(x+2)=x^2+3x+2
      Check (Equal (SF, Poly_Of (P, 2, 3, 1), P), "sf kernel (x+1)(x+2)");
      Factor (P, F, Factors, Count, Seed);
      Prod := Product (Factors, Count, P);
      Check (Equal (Prod, SF, P), "Factor uses square-free kernel");
      Check (Count = 2, "squared input -> 2 distinct irr factors");
   end;

   ------------------------------------------------------------------
   Section ("Bad parameters");
   ------------------------------------------------------------------
   Expect_Invalid_Factor ("P=2 even", 2, Poly_Of (3, 1, 1));
   Expect_Invalid_Factor ("P=1", 1, Poly_Of (3, 1, 1));
   Expect_Invalid_Factor ("P=0", 0, Poly_Of (3, 1, 1));
   Expect_Invalid_Factor ("P=9 composite", 9, Poly_Of (9, 1, 1));
   Expect_Invalid_Factor ("P=15 composite", 15, Poly_Of (15, 1, 1));
   Expect_Invalid_Factor ("zero poly", 5, Zero_Poly);

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Natural := Mod_Inv (0, 5);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Mod_Inv(0)");
   end;

   declare
      Raised : Boolean := False;
      Q, R : Polynomial;
   begin
      begin
         Div_Mod (Poly_Of (5, 1, 1), Zero_Poly, 5, Q, R);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Div_Mod by zero");
   end;

   ------------------------------------------------------------------
   Section ("Deterministic seed reproducibility");
   ------------------------------------------------------------------
   declare
      P : constant Natural := 5;
      F : constant Polynomial := Poly_Of (P, 2, 3, 1);
      F1, F2 : Factor_Array;
      C1, C2 : Natural;
      S1, S2 : U64;
   begin
      S1 := U (12345);
      S2 := U (12345);
      Factor (P, F, F1, C1, S1);
      Factor (P, F, F2, C2, S2);
      Check (C1 = C2, "same seed => same count");
      Check
        (Equal (Product (F1, C1, P), Product (F2, C2, P), P),
         "same seed => same product");
   end;

   ------------------------------------------------------------------
   Section ("From_Coeffs / Monomial / Equal");
   ------------------------------------------------------------------
   declare
      P : constant Natural := 5;
      C : Coeff_Array := [others => 0];
      A, B : Polynomial;
   begin
      C (0) := 3;
      C (2) := 1;
      A := From_Coeffs (C, 2, P);
      B := Add (Constant_Poly (3, P), Monomial (1, 2, P), P);
      Check (Equal (A, B, P), "From_Coeffs matches Monomial build");
      Check (not Equal (A, Constant_Poly (1, P), P), "Equal negative");
      Check (Degree (Monomial (2, 4, P), P) = 4, "deg monomial x^4");
   end;

   ------------------------------------------------------------------
   --  Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
