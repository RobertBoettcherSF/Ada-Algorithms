--  Standalone test suite for Chien_Search (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Chien_Search; use Chien_Search;
with Interfaces;

procedure Tests is

   use type Interfaces.Unsigned_16;

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
   function E (X : Field_Element) return Field_Element is (X);

   function Sorted_Roots
     (R : Root_Array; Count : Natural) return Root_Array
   is
      A   : Root_Array := R;
      Tmp : Field_Element;
   begin
      for I in 1 .. Count loop
         for J in I + 1 .. Count loop
            if A (J) < A (I) then
               Tmp := A (I);
               A (I) := A (J);
               A (J) := Tmp;
            end if;
         end loop;
      end loop;
      return A;
   end Sorted_Roots;

   function Same_Root_Sets
     (A : Root_Array; CA : Natural;
      B : Root_Array; CB : Natural) return Boolean
   is
      SA : constant Root_Array := Sorted_Roots (A, CA);
      SB : constant Root_Array := Sorted_Roots (B, CB);
   begin
      if CA /= CB then
         return False;
      end if;
      for I in 1 .. CA loop
         if SA (I) /= SB (I) then
            return False;
         end if;
      end loop;
      return True;
   end Same_Root_Sets;

   function Contains
     (R : Root_Array; Count : Natural; X : Field_Element) return Boolean
   is
   begin
      for I in 1 .. Count loop
         if R (I) = X then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   function Poly_Of
     (Field : Field_Desc;
      C0 : Field_Element;
      C1 : Field_Element := 0;
      C2 : Field_Element := 0;
      C3 : Field_Element := 0;
      C4 : Field_Element := 0;
      C5 : Field_Element := 0;
      C6 : Field_Element := 0;
      C7 : Field_Element := 0) return Polynomial
   is
      C    : Coeff_Array := [others => 0];
      Last : Degree_Index := 0;
   begin
      C (0) := C0;
      C (1) := C1;
      C (2) := C2;
      C (3) := C3;
      C (4) := C4;
      C (5) := C5;
      C (6) := C6;
      C (7) := C7;
      for I in reverse Degree_Index loop
         if C (I) /= 0 then
            Last := I;
            exit;
         end if;
      end loop;
      return From_Coeffs (C, Last, Field);
   end Poly_Of;

   --  Linear factor (X - R) = X + R in char 2.
   function Linear (Field : Field_Desc; R : Field_Element) return Polynomial is
   begin
      return Poly_Of (Field, C0 => R, C1 => 1);
   end Linear;

   function Poly_Mul
     (A, B : Polynomial; Field : Field_Desc) return Polynomial
   is
      DA : constant Integer := Degree (A);
      DB : constant Integer := Degree (B);
      R  : Polynomial := Zero_Poly;
      K  : Natural;
   begin
      if DA < 0 or else DB < 0 then
         return Zero_Poly;
      end if;
      if DA + DB > Integer (Max_Degree) then
         raise Invalid_Argument;
      end if;
      for I in 0 .. DA loop
         for J in 0 .. DB loop
            K := Natural (I + J);
            R.Coeffs (Degree_Index (K)) :=
              Add
                (R.Coeffs (Degree_Index (K)),
                 Mul (A.Coeffs (Degree_Index (I)),
                      B.Coeffs (Degree_Index (J)), Field));
         end loop;
      end loop;
      return R;
   end Poly_Mul;

   procedure Expect_Invalid_Make (Label : String; M : Natural) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Field_Desc := Make_GF2 (M);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Make_GF2: " & Label);
   end Expect_Invalid_Make;

   procedure Expect_Invalid_Find
     (Label : String; Field : Field_Desc; P : Polynomial)
   is
      Raised : Boolean := False;
      Roots  : Root_Array;
      Count  : Natural;
   begin
      begin
         Find_Roots (Field, P, Roots, Count);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Find_Roots: " & Label);
   end Expect_Invalid_Find;

   procedure Expect_Invalid_Inv
     (Label : String; A : Field_Element; Field : Field_Desc)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Field_Element := Inv (A, Field);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Inv: " & Label);
   end Expect_Invalid_Inv;

   ------------------------------------------------------------------
   --  Field construction
   ------------------------------------------------------------------

   procedure Test_Make_Field is
      F3, F4, F8 : Field_Desc;
   begin
      Section ("Field construction");
      F3 := Make_GF2 (N (3));
      Check (F3.M = 3, "Make_GF2(3).M");
      Check (F3.Irreducible = 11, "Make_GF2(3) irr x^3+x+1");
      Check (F3.Primitive = 2, "Make_GF2(3) primitive = x");
      Check (Field_Order (F3) = 8, "Field_Order GF(8)");

      F4 := Make_GF2 (N (4));
      Check (F4.M = 4, "Make_GF2(4).M");
      Check (F4.Irreducible = 19, "Make_GF2(4) irr x^4+x+1");
      Check (Field_Order (F4) = 16, "Field_Order GF(16)");

      F8 := Make_GF2 (N (8));
      Check (F8.M = 8, "Make_GF2(8).M");
      Check (F8.Irreducible = 285, "Make_GF2(8) AES irr");
      Check (Field_Order (F8) = 256, "Field_Order GF(256)");

      Expect_Invalid_Make ("M=1", 1);
      Expect_Invalid_Make ("M=0", 0);
      Expect_Invalid_Make ("M=9", 9);
   end Test_Make_Field;

   ------------------------------------------------------------------
   --  Field arithmetic
   ------------------------------------------------------------------

   procedure Test_Arithmetic is
      F : constant Field_Desc := Make_GF2 (3);
      A, B, C : Field_Element;
   begin
      Section ("Field arithmetic GF(2^3)");
      Check (Add (E (1), E (1)) = 0, "Add 1+1=0 char 2");
      Check (Add (E (3), E (5)) = 6, "Add 3 xor 5");
      Check (Mul (E (2), E (2), F) = 4, "Mul x*x = x^2");
      Check (Mul (E (2), E (4), F) = 3, "Mul x*x^2 = x^3 = x+1");
      Check (Mul (E (3), E (3), F) = 5, "Mul (x+1)^2 = x^2+1");
      Check (Mul (E (0), E (7), F) = 0, "Mul by zero");
      Check (Mul (E (1), E (7), F) = 7, "Mul by one");

      --  Every non-zero element has inverse; a * inv(a) = 1.
      for V in Field_Element range 1 .. 7 loop
         Check
           (Mul (V, Inv (V, F), F) = 1,
            "Inv round-trip for element");
      end loop;

      Expect_Invalid_Inv ("zero", 0, F);

      Check (Pow (E (2), N (0), F) = 1, "Pow exp 0");
      Check (Pow (E (2), N (1), F) = 2, "Pow exp 1");
      Check (Pow (E (2), N (3), F) = 3, "Pow α^3 = α+1");
      Check (Pow (E (2), N (7), F) = 1, "Pow α^7 = 1 (order 7)");

      --  Distributivity spot check
      A := 6;
      B := 3;
      C := 5;
      Check
        (Mul (A, Add (B, C), F) = Add (Mul (A, B, F), Mul (A, C, F)),
         "Distributivity");
   end Test_Arithmetic;

   ------------------------------------------------------------------
   --  GF(2^4) arithmetic / primitive order
   ------------------------------------------------------------------

   procedure Test_GF16_Arithmetic is
      F : constant Field_Desc := Make_GF2 (4);
      X : Field_Element;
      Seen : array (0 .. 15) of Boolean := [others => False];
      All_Distinct : Boolean := True;
   begin
      Section ("GF(2^4) multiplicative order of α");
      X := 1;
      for I in 0 .. 14 loop
         if Seen (Natural (X)) then
            All_Distinct := False;
         end if;
         Seen (Natural (X)) := True;
         X := Mul (X, F.Primitive, F);
      end loop;
      Check (All_Distinct, "α^0 .. α^14 all distinct");
      Check (X = 1, "α^15 = 1");
      Check (Pow (F.Primitive, N (15), F) = 1, "Pow α^15");
   end Test_GF16_Arithmetic;

   ------------------------------------------------------------------
   --  Polynomial helpers
   ------------------------------------------------------------------

   procedure Test_Polynomials is
      F : constant Field_Desc := Make_GF2 (4);
      P : Polynomial;
   begin
      Section ("Polynomial helpers");
      Check (Degree (Zero_Poly) = -1, "Degree zero poly");
      Check (Is_Zero_Poly (Zero_Poly), "Is_Zero_Poly");

      P := Poly_Of (F, C0 => 1, C1 => 0, C2 => 1);  -- 1 + X^2
      Check (Degree (P) = 2, "Degree 1+X^2");
      Check (Eval (P, E (0), F) = 1, "Eval at 0");
      Check (Eval (P, E (1), F) = 0, "Eval 1+1^2 = 0");
      Check (Eval (Linear (F, 1), E (1), F) = 0, "Eval (X+1) at 1");
      Check (Eval (Linear (F, 1), E (0), F) = 1, "Eval (X+1) at 0");
   end Test_Polynomials;

   ------------------------------------------------------------------
   --  Chien vs brute on known roots
   ------------------------------------------------------------------

   procedure Compare_Chien_Brute
     (Label : String; Field : Field_Desc; P : Polynomial)
   is
      RC, RB : Root_Array;
      CC, CB : Natural;
   begin
      Find_Roots (Field, P, RC, CC);
      Find_Roots_Brute (Field, P, RB, CB);
      Check (Same_Root_Sets (RC, CC, RB, CB),
             "Chien=brute: " & Label);
      --  Every reported root evaluates to zero.
      for I in 1 .. CC loop
         Check
           (Eval (P, RC (I), Field) = 0,
            "Root evaluates to 0 (" & Label & ")");
      end loop;
   end Compare_Chien_Brute;

   procedure Test_Known_Roots is
      F3 : constant Field_Desc := Make_GF2 (3);
      F4 : constant Field_Desc := Make_GF2 (4);
      F5 : constant Field_Desc := Make_GF2 (5);
      P  : Polynomial;
      R  : Root_Array;
      C  : Natural;
      A  : Field_Element;
   begin
      Section ("Known roots (Chien vs brute)");

      --  (X + 1) over GF(8): root 1
      P := Linear (F3, 1);
      Find_Roots (F3, P, R, C);
      Check (C = 1 and then Contains (R, C, 1), "GF8: X+1 root {1}");
      Compare_Chien_Brute ("GF8 X+1", F3, P);

      --  (X + α) = X + 2: root α=2
      P := Linear (F3, 2);
      Find_Roots (F3, P, R, C);
      Check (C = 1 and then Contains (R, C, 2), "GF8: X+α root {α}");
      Compare_Chien_Brute ("GF8 X+α", F3, P);

      --  (X)(X+1) = X^2 + X : roots {0,1}
      P := Poly_Of (F3, C0 => 0, C1 => 1, C2 => 1);
      Find_Roots (F3, P, R, C);
      Check
        (C = 2
           and then Contains (R, C, 0)
           and then Contains (R, C, 1),
         "GF8: X^2+X roots {0,1}");
      Compare_Chien_Brute ("GF8 X(X+1)", F3, P);

      --  (X+1)(X+α) = X^2 + (1+α)X + α  over GF(8)
      P := Poly_Mul (Linear (F3, 1), Linear (F3, 2), F3);
      Find_Roots (F3, P, R, C);
      Check
        (C = 2
           and then Contains (R, C, 1)
           and then Contains (R, C, 2),
         "GF8: (X+1)(X+α)");
      Compare_Chien_Brute ("GF8 (X+1)(X+α)", F3, P);

      --  Triple product (X+1)(X+α)(X+α^2) over GF(8)
      P := Poly_Mul
        (Poly_Mul (Linear (F3, 1), Linear (F3, 2), F3),
         Linear (F3, 4), F3);
      Find_Roots (F3, P, R, C);
      Check (C = 3, "GF8: three linear factors count");
      Check
        (Contains (R, C, 1)
           and then Contains (R, C, 2)
           and then Contains (R, C, 4),
         "GF8: roots {1,α,α^2}");
      Compare_Chien_Brute ("GF8 three roots", F3, P);

      --  Irreducible X^2+X+1 over GF(4)? Over GF(8): eval
      --  X^2+X+1 has roots the order-3 elements. In GF(8), α^7=1 so
      --  elements of order 3: solve. Brute compare only.
      P := Poly_Of (F3, C0 => 1, C1 => 1, C2 => 1);
      Compare_Chien_Brute ("GF8 X^2+X+1", F3, P);

      --  GF(16): (X+α^3)(X+α^7)
      A := Pow (F4.Primitive, 3, F4);
      P := Poly_Mul
        (Linear (F4, A),
         Linear (F4, Pow (F4.Primitive, 7, F4)),
         F4);
      Find_Roots (F4, P, R, C);
      Check (C = 2, "GF16: two roots count");
      Check
        (Contains (R, C, A)
           and then Contains (R, C, Pow (F4.Primitive, 7, F4)),
         "GF16: roots α^3, α^7");
      Compare_Chien_Brute ("GF16 two roots", F4, P);

      --  Constant non-zero: no roots
      P := Poly_Of (F4, C0 => 1);
      Find_Roots (F4, P, R, C);
      Check (C = 0, "Constant 1 has no roots");
      Compare_Chien_Brute ("const 1", F4, P);

      --  GF(32) linear
      P := Linear (F5, Pow (F5.Primitive, 5, F5));
      Compare_Chien_Brute ("GF32 linear", F5, P);
   end Test_Known_Roots;

   ------------------------------------------------------------------
   --  BCH-style small error-locator examples
   ------------------------------------------------------------------

   procedure Test_BCH_Style is
      --  Tiny BCH-like locator over GF(16): Λ(x) = (1 + α^3 x)(1 + α^7 x)
      --  In coding texts roots of Λ are the error locators X_i = α^{j_i};
      --  Chien finds those X_i (here α^3 and α^7? Wait:
      --  Λ(x) = 1 + (α^3+α^7)x + α^{10} x^2, roots are α^{-3} and α^{-7}
      --  Educational shortcut: use Λ(x)=(x-β1)(x-β2) so roots are βi.
      F  : constant Field_Desc := Make_GF2 (4);
      B1 : constant Field_Element := Pow (F.Primitive, 3, F);
      B2 : constant Field_Element := Pow (F.Primitive, 5, F);
      Lam : Polynomial;
      R   : Root_Array;
      C   : Natural;
   begin
      Section ("BCH-style error locator (GF(16))");
      Lam := Poly_Mul (Linear (F, B1), Linear (F, B2), F);
      --  Alias API
      Chien_Search.Chien_Search (F, Lam, R, C);
      Check (C = 2, "Locator has 2 roots");
      Check
        (Contains (R, C, B1) and then Contains (R, C, B2),
         "Locator roots are error positions β1,β2");
      Compare_Chien_Brute ("BCH locator", F, Lam);

      --  Single-error locator Λ(x) = x + β
      Lam := Linear (F, B1);
      Find_Roots (F, Lam, R, C);
      Check (C = 1 and then R (1) = B1, "Single-error locator");
   end Test_BCH_Style;

   ------------------------------------------------------------------
   --  Chien recurrence identity spot check
   ------------------------------------------------------------------

   procedure Test_Recurrence_Identity is
      F : constant Field_Desc := Make_GF2 (4);
      --  Λ = 1 + 3x + 7x^2 + x^3  (arbitrary coeffs in GF(16))
      P : constant Polynomial :=
        Poly_Of (F, C0 => 1, C1 => 3, C2 => 7, C3 => 1);
      Alpha : constant Field_Element := F.Primitive;
      Gamma : array (0 .. 3) of Field_Element;
      Alpha_Pow : array (0 .. 3) of Field_Element;
      Sum : Field_Element;
      X   : Field_Element;
      Match : Boolean := True;
   begin
      Section ("Chien recurrence matches Horner");
      Alpha_Pow (0) := 1;
      Gamma (0) := P.Coeffs (0);
      for J in 1 .. 3 loop
         Alpha_Pow (J) := Mul (Alpha_Pow (J - 1), Alpha, F);
         Gamma (J) := P.Coeffs (J);
      end loop;
      X := 1;
      for I in 0 .. 14 loop
         Sum := 0;
         for J in 0 .. 3 loop
            Sum := Add (Sum, Gamma (J));
         end loop;
         if Sum /= Eval (P, X, F) then
            Match := False;
         end if;
         for J in 1 .. 3 loop
            Gamma (J) := Mul (Gamma (J), Alpha_Pow (J), F);
         end loop;
         X := Mul (X, Alpha, F);
      end loop;
      Check (Match, "γ-sum equals Horner at every α^i");
   end Test_Recurrence_Identity;

   ------------------------------------------------------------------
   --  Invalid arguments
   ------------------------------------------------------------------

   procedure Test_Invalid is
      F : constant Field_Desc := Make_GF2 (3);
      Bad : Field_Desc;
   begin
      Section ("Invalid_Argument");
      Expect_Invalid_Find ("zero poly", F, Zero_Poly);

      Bad := F;
      Bad.Irreducible := 0;
      Expect_Invalid_Find ("irr=0", Bad, Linear (F, 1));

      Bad := F;
      Bad.Primitive := 0;
      Expect_Invalid_Find ("primitive=0", Bad, Linear (F, 1));

      Bad := F;
      Bad.Irreducible := 3;  -- not degree 3
      Expect_Invalid_Find ("irr wrong degree", Bad, Linear (F, 1));
   end Test_Invalid;

   ------------------------------------------------------------------
   --  More GF sizes smoke
   ------------------------------------------------------------------

   procedure Test_All_Sizes is
      P : Polynomial;
   begin
      Section ("Smoke Chien on GF(2^m) m=2..8");
      for M in Extension_Degree loop
         declare
            F : constant Field_Desc := Make_GF2 (M);
            R : constant Field_Element := Pow (F.Primitive, M, F);
         begin
            P := Linear (F, R);
            Compare_Chien_Brute ("linear GF(2^" & M'Image & ")", F, P);
            P := Poly_Mul (Linear (F, 1), Linear (F, F.Primitive), F);
            Compare_Chien_Brute ("quad GF(2^" & M'Image & ")", F, P);
         end;
      end loop;
   end Test_All_Sizes;

begin
   Ada.Text_IO.Put_Line ("Chien_Search test suite");
   Ada.Text_IO.Put_Line ("========================");

   Test_Make_Field;
   Test_Arithmetic;
   Test_GF16_Arithmetic;
   Test_Polynomials;
   Test_Known_Roots;
   Test_BCH_Style;
   Test_Recurrence_Identity;
   Test_Invalid;
   Test_All_Sizes;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
