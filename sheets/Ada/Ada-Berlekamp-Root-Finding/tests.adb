--  Standalone test suite for Berlekamp_Root_Finding (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Berlekamp_Root_Finding; use Berlekamp_Root_Finding;

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

   --  Non-static views (avoid -gnatwc constant-condition warnings).
   function U (X : U64) return U64 is (X);

   function Sorted_Copy (R : Root_List) return Root_List is
      A : Root_List := R;
      Tmp : U64;
   begin
      for I in A'Range loop
         for J in I + 1 .. A'Last loop
            if A (J) < A (I) then
               Tmp := A (I);
               A (I) := A (J);
               A (J) := Tmp;
            end if;
         end loop;
      end loop;
      return A;
   end Sorted_Copy;

   function Same_Roots (A, B : Root_List) return Boolean is
      SA : constant Root_List := Sorted_Copy (A);
      SB : constant Root_List := Sorted_Copy (B);
   begin
      if SA'Length /= SB'Length then
         return False;
      end if;
      for I in SA'Range loop
         if SA (I) /= SB (I - SA'First + SB'First) then
            return False;
         end if;
      end loop;
      return True;
   end Same_Roots;

   function Contains (R : Root_List; X : U64) return Boolean is
   begin
      for I in R'Range loop
         if R (I) = X then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   procedure Expect_Invalid_Find
     (Label : String; F : Poly; P : U64)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Root_List := Find_Roots (F, P);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Find_Roots: " & Label);
   end Expect_Invalid_Find;

   procedure Expect_Invalid_Brute
     (Label : String; F : Poly; P : U64)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Root_List :=
              Find_Roots_Deterministic_Small (F, P);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument brute: " & Label);
   end Expect_Invalid_Brute;

   procedure Expect_Invalid_Mul (Label : String; A, B, M : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Mul_Mod (A, B, M);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Mul_Mod: " & Label);
   end Expect_Invalid_Mul;

   ------------------------------------------------------------------
   --  Modular arithmetic
   ------------------------------------------------------------------

   procedure Test_Modular is
   begin
      Section ("Modular arithmetic");
      Check (Mul_Mod (U (6), U (7), U (5)) = 2, "Mul_Mod 6*7 mod 5");
      Check (Mul_Mod (U (0), U (9), U (11)) = 0, "Mul_Mod 0");
      Check (Mul_Mod (U (3), U (4), U (1)) = 0, "Mul_Mod mod 1");
      Check (Mod_Pow (U (2), U (10), U (17)) = 4, "Mod_Pow 2^10 mod 17");
      Check (Mod_Pow (U (5), U (0), U (7)) = 1, "Mod_Pow exp 0");
      Check (Mod_Pow (U (3), U (1), U (11)) = 3, "Mod_Pow exp 1");
      Check (Gcd (U (54), U (24)) = 6, "Gcd 54,24");
      Check (Gcd (U (0), U (5)) = 5, "Gcd 0,5");
      Check (Gcd (U (0), U (0)) = 0, "Gcd 0,0");
      Check (Mod_Inv (U (3), U (7)) = 5, "Mod_Inv 3 mod 7");
      Check (Mul_Mod (Mod_Inv (U (5), U (11)), U (5), U (11)) = 1,
             "Mod_Inv * a = 1");
      Expect_Invalid_Mul ("M=0", U (1), U (2), U (0));
      Check (Is_Prime_Trial (U (2)), "Is_Prime 2");
      Check (Is_Prime_Trial (U (97)), "Is_Prime 97");
      Check (not Is_Prime_Trial (U (1)), "not Is_Prime 1");
      Check (not Is_Prime_Trial (U (91)), "not Is_Prime 91");
      Check (not Is_Prime_Trial (U (100)), "not Is_Prime 100");
   end Test_Modular;

   ------------------------------------------------------------------
   --  Polynomial helpers
   ------------------------------------------------------------------

   procedure Test_Poly_Basics is
      P : constant U64 := 5;
      F : constant Poly := [2, 2, 1];       -- x^2 + 2x + 2
      G : constant Poly := [3, 1];          -- x + 3
      Z : constant Poly := [0, 0, 0];
   begin
      Section ("Polynomial basics");
      Check (Poly_Degree (F, P) = 2, "deg F = 2");
      Check (Poly_Degree (G, P) = 1, "deg G = 1");
      Check (Poly_Degree (Z, P) = -1, "deg zero = -1");
      --  1+2+1=4 mod 5
      Check (Poly_Eval (F, U (1), P) = 0, "F(1)=0 mod 5");
      Check (Poly_Eval (G, U (2), P) = 0, "G(2)=0 mod 5");

      declare
         S : constant Poly := Poly_Add (F, G, P);
         D : constant Poly := Poly_Sub (F, G, P);
         M : constant Poly := Poly_Mul (G, G, P);  -- (x+3)^2 = x^2+6x+9
      begin
         Check (Poly_Degree (S, P) = 2, "deg(F+G)=2");
         Check (S (0) = 0, "(F+G)(0) const");  -- 2+3=5≡0
         Check (Poly_Degree (D, P) = 2, "deg(F-G)=2");
         Check (M (0) = 4, "(x+3)^2 const 9≡4");  -- 9 mod 5 = 4
         Check (M (1) = 1, "(x+3)^2 x-coeff 6≡1");
         Check (M (2) = 1, "(x+3)^2 leading");
      end;

      declare
         --  (x^2+2x+2) mod (x+3): evaluate at -3≡2 → F(2)=4+4+2=10≡0
         R : constant Poly := Poly_Mod (F, G, P);
      begin
         Check (Poly_Eval (F, U (2), P) = 0, "F(2)=0 mod 5");
         --  F(2)=4+4+2=10≡0; G=x+3≡x-2 mod 5 divides F.
         Check (Poly_Degree (R, P) < 0, "F mod G = 0");
      end;

      declare
         Q : constant Poly := Poly_Quotient (F, G, P);
      begin
         Check (Poly_Degree (Q, P) = 1, "quot deg 1");
         Check (Poly_Degree
                  (Poly_Sub (F, Poly_Mul (Q, G, P), P), P) < 0,
                "F = Q*G exact");
      end;
   end Test_Poly_Basics;

   procedure Test_Poly_Gcd_Pow is
      P : constant U64 := 7;
      --  (x-1)(x-2)=x^2-3x+2
      F : constant Poly := [2, 4, 1];  -- 2 - 3x + x^2 with -3≡4 mod 7
      --  (x-1)=x+6
      L : constant Poly := [6, 1];
   begin
      Section ("Poly GCD / Mod_Pow / Square_Free");
      declare
         H : constant Poly := Poly_Gcd (F, L, P);
      begin
         Check (Poly_Degree (H, P) = 1, "gcd((x-1)(x-2),x-1) deg 1");
         Check (H (1) = 1, "gcd monic");
         Check (H (0) = 6, "gcd is x-1");
      end;

      declare
         X : constant Poly := [0, 1];
         Xp : constant Poly := Poly_Mod_Pow (X, U (3), F, P);
         --  x^3 mod F: F=x^2+4x+2 ⇒ x^2 ≡ -4x-2 ≡ 3x+5
         --  x^3 ≡ x*(3x+5)=3x^2+5x ≡ 3(3x+5)+5x = 9x+15+5x = 14x+15 ≡ 0x+1
      begin
         Check (Poly_Degree (Xp, P) <= 1, "x^3 mod F deg<=1");
         Check (Poly_Eval (Xp, U (0), P) = 1, "x^3 mod F const term");
      end;

      declare
         --  (x-1)^2 (x-2) = (x^2-2x+1)(x-2)
         Sq : constant Poly := [4, 5, 4, 1];
         --  expand: (x-1)^2=x^2-2x+1; * (x-2)=x^3-2x^2 -2x^2+4x +x-2
         --  = x^3-4x^2+5x-2 → mod 7: -2≡5, 5, -4≡3, 1 → wait recalc
         --  (x^2 + 5x + 1)(x + 5) since -2≡5, -1≡6... let me use product
         A : constant Poly := Poly_Mul
           (Poly_Mul ([6, 1], [6, 1], P), [5, 1], P);  -- (x-1)^2(x-2)
         Sf : constant Poly := Poly_Square_Free (A, P);
      begin
         Check (Poly_Degree (A, P) = 3, "squared poly deg 3");
         Check (Poly_Degree (Sf, P) = 2, "square-free deg 2");
         declare
            R : constant Root_List := Find_Roots_Deterministic_Small (A, P);
         begin
            Check (R'Length = 2, "brute finds 2 distinct roots");
            Check (Contains (R, 1) and then Contains (R, 2),
                   "roots 1 and 2");
         end;
         pragma Unreferenced (Sq);
      end;

      declare
         Sh : constant Poly := Poly_Shift ([2, 4, 1], U (1), P);
         --  F(x-1) for F=x^2+4x+2
      begin
         Check (Poly_Degree (Sh, P) = 2, "shift preserves deg");
         Check (Poly_Eval (Sh, U (0), P) = Poly_Eval (F, U (6), P),
                "shift eval at 0 = F(-1)");
      end;
   end Test_Poly_Gcd_Pow;

   ------------------------------------------------------------------
   --  Known examples
   ------------------------------------------------------------------

   procedure Test_Known is
   begin
      Section ("Known polynomials");

      --  (x-1)(x-2)=x^2-3x+2 mod 5 → (2, 2, 1) because -3≡2
      declare
         F : constant Poly := [2, 2, 1];
         P : constant U64 := 5;
         R : constant Root_List := Find_Roots (F, P, 32, 7);
         B : constant Root_List := Find_Roots_Deterministic_Small (F, P);
      begin
         Check (B'Length = 2, "brute (x-1)(x-2) mod 5 len");
         Check (Contains (B, 1) and then Contains (B, 2),
                "brute roots 1,2");
         Check (Same_Roots (R, B), "Berlekamp matches brute mod 5");
      end;

      --  Wikipedia modular sqrt: x^2 - 5 mod 11 → roots 4,7
      declare
         F : constant Poly := [6, 0, 1];  -- -5≡6 mod 11
         P : constant U64 := 11;
         R : constant Root_List := Find_Roots (F, P, 64, 3);
         B : constant Root_List := Find_Roots_Deterministic_Small (F, P);
      begin
         Check (Contains (B, 4) and then Contains (B, 7),
                "brute x^2=5 mod 11 → 4,7");
         Check (Same_Roots (R, B), "Berlekamp x^2-5 mod 11");
      end;

      --  Linear
      declare
         F : constant Poly := [3, 1];  -- x+3 ≡ 0 ⇒ x= -3 ≡ 4 mod 7
         P : constant U64 := 7;
         R : constant Root_List := Find_Roots (F, P);
      begin
         Check (R'Length = 1 and then R (R'First) = 4,
                "linear root mod 7");
      end;

      --  Constant non-zero: no roots
      declare
         F : constant Poly := [0 => 3];
         P : constant U64 := 5;
         R : constant Root_List := Find_Roots (F, P);
      begin
         Check (R'Length = 0, "constant: no roots");
      end;

      --  Root at 0: x(x-1)=x^2-x mod 5
      declare
         F : constant Poly := [0, 4, 1];  -- -1≡4
         P : constant U64 := 5;
         R : constant Root_List := Find_Roots (F, P);
      begin
         Check (Contains (R, 0) and then Contains (R, 1),
                "roots 0 and 1");
         Check (R'Length = 2, "two roots with zero");
      end;

      --  Irreducible quadratic mod 5: x^2+2 (no root in F_5)
      declare
         F : constant Poly := [2, 0, 1];
         P : constant U64 := 5;
         R : constant Root_List := Find_Roots (F, P, 32, 1);
         B : constant Root_List := Find_Roots_Deterministic_Small (F, P);
      begin
         Check (B'Length = 0, "brute: x^2+2 irr mod 5");
         Check (R'Length = 0, "Berlekamp: no roots irr");
      end;

      --  Cipolla classic: x^2-10 mod 13 → roots 6,7
      declare
         F : constant Poly := [3, 0, 1];  -- -10≡3 mod 13
         P : constant U64 := 13;
         R : constant Root_List := Find_Roots (F, P, 64, 5);
         B : constant Root_List := Find_Roots_Deterministic_Small (F, P);
      begin
         Check (Contains (B, 6) and then Contains (B, 7),
                "brute x^2=10 mod 13");
         Check (Same_Roots (R, B), "Berlekamp matches Cipolla example");
      end;
   end Test_Known;

   ------------------------------------------------------------------
   --  p = 2
   ------------------------------------------------------------------

   procedure Test_P2 is
   begin
      Section ("Characteristic 2");
      declare
         F : constant Poly := [0, 1];  -- x
         R : constant Root_List := Find_Roots (F, 2);
      begin
         Check (R'Length = 1 and then Contains (R, 0), "x root 0 mod 2");
      end;
      declare
         F : constant Poly := [1, 1];  -- x+1
         R : constant Root_List := Find_Roots (F, 2);
      begin
         Check (R'Length = 1 and then Contains (R, 1), "x+1 root 1");
      end;
      declare
         F : constant Poly := [1, 0, 1];  -- x^2+1=(x+1)^2 mod 2
         R : constant Root_List := Find_Roots (F, 2);
         B : constant Root_List := Find_Roots_Deterministic_Small (F, 2);
      begin
         Check (Same_Roots (R, B), "x^2+1 mod 2 matches brute");
         Check (Contains (R, 1), "square-free kernel root 1");
      end;
      declare
         F : constant Poly := [0, 1, 1];  -- x^2+x = x(x+1)
         R : constant Root_List := Find_Roots (F, 2);
      begin
         Check (R'Length = 2, "both roots mod 2");
         Check (Contains (R, 0) and then Contains (R, 1), "0 and 1");
      end;
   end Test_P2;

   ------------------------------------------------------------------
   --  Multiple roots / square factors
   ------------------------------------------------------------------

   procedure Test_Multiple is
      P : constant U64 := 11;
   begin
      Section ("Multiple roots / square-free");
      declare
         --  (x-3)^2 = x^2 - 6x + 9 ≡ x^2 + 5x + 9 mod 11
         F : constant Poly := [9, 5, 1];
         R : constant Root_List := Find_Roots (F, P);
         B : constant Root_List := Find_Roots_Deterministic_Small (F, P);
      begin
         Check (B'Length = 1 and then Contains (B, 3),
                "brute: single distinct root 3");
         Check (Same_Roots (R, B), "Berlekamp square factor → one root");
      end;
      declare
         --  (x-1)^2 (x-4) over F_11
         L1 : constant Poly := [10, 1];
         L4 : constant Poly := [7, 1];
         F  : constant Poly :=
           Poly_Mul (Poly_Mul (L1, L1, P), L4, P);
         R  : constant Root_List := Find_Roots (F, P, 64, 9);
         B  : constant Root_List := Find_Roots_Deterministic_Small (F, P);
      begin
         Check (B'Length = 2, "brute two distinct");
         Check (Contains (B, 1) and then Contains (B, 4), "roots 1,4");
         Check (Same_Roots (R, B), "Berlekamp after square-free");
      end;
   end Test_Multiple;

   ------------------------------------------------------------------
   --  Domain errors
   ------------------------------------------------------------------

   procedure Test_Domain is
      F : constant Poly := [1, 0, 1];
   begin
      Section ("Domain errors");
      Expect_Invalid_Find ("P=0", F, U (0));
      Expect_Invalid_Find ("P=1", F, U (1));
      Expect_Invalid_Find ("P=4", F, U (4));
      Expect_Invalid_Find ("P=9", F, U (9));
      Expect_Invalid_Find ("P=91", F, U (91));
      Expect_Invalid_Find ("empty", [1 .. 0 => 0], U (5));
      Expect_Invalid_Find ("zero poly", [0, 0, 0], U (5));
      Expect_Invalid_Brute ("P too big", F, U (10_007));
      Expect_Invalid_Brute ("composite", F, U (15));
   end Test_Domain;

   ------------------------------------------------------------------
   --  Random monic products vs brute (p≤97, deg≤4)
   ------------------------------------------------------------------

   procedure Test_Random_Vs_Brute is
      type Seed_Rec is record
         S : U64;
      end record;

      procedure Next (St : in out Seed_Rec) is
      begin
         St.S := St.S * 6364136223846793005 + 1;
      end Next;

      function Rand (St : in out Seed_Rec; M : U64) return U64 is
      begin
         Next (St);
         return St.S rem M;
      end Rand;

      Primes : constant array (Positive range <>) of U64 :=
        [3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47,
         53, 59, 61, 67, 71, 73, 79, 83, 89, 97];

      St : Seed_Rec := (S => 42);
      Cases : Natural := 0;
   begin
      Section ("Random products vs brute (p≤97, deg≤4)");

      for Pi in Primes'Range loop
         declare
            P : constant U64 := Primes (Pi);
         begin
            for Deg in 1 .. 4 loop
               --  Build product of Deg distinct linear factors
               declare
                  Used : array (0 .. 96) of Boolean := [others => False];
                  Roots_Chosen : array (1 .. 4) of U64 := [others => 0];
                  N_Chosen : Natural := 0;
                  Ok   : Boolean := True;

                  function Product_Of_Linears
                    (Chosen : Natural) return Poly
                  is
                  begin
                     if Chosen = 0 then
                        return [0 => 1];
                     end if;
                     declare
                        R : constant U64 := Roots_Chosen (Chosen);
                     begin
                        return Poly_Mul
                          (Product_Of_Linears (Chosen - 1),
                           [0 => (P - R) rem P, 1 => 1],
                           P);
                     end;
                  end Product_Of_Linears;
               begin
                  for K in 1 .. Deg loop
                     declare
                        Tries : Natural := 0;
                        R : U64;
                     begin
                        loop
                           R := Rand (St, P);
                           Tries := Tries + 1;
                           exit when not Used (Natural (R))
                             or else Tries > 64;
                        end loop;
                        if Used (Natural (R)) then
                           Ok := False;
                           exit;
                        end if;
                        Used (Natural (R)) := True;
                        N_Chosen := N_Chosen + 1;
                        Roots_Chosen (N_Chosen) := R;
                     end;
                  end loop;

                  if Ok then
                     declare
                        Acc : constant Poly :=
                          Product_Of_Linears (N_Chosen);
                        Br : constant Root_List :=
                          Find_Roots_Deterministic_Small (Acc, P);
                        Fr : constant Root_List :=
                          Find_Roots (Acc, P, 96, St.S);
                     begin
                        Cases := Cases + 1;
                        Check
                          (Br'Length = Deg,
                           "brute len deg=" & Natural'Image (Deg)
                           & " p=" & U64'Image (P));
                        Check
                          (Same_Roots (Fr, Br),
                           "match deg=" & Natural'Image (Deg)
                           & " p=" & U64'Image (P));
                     end;
                  end if;
               end;
            end loop;
         end;
      end loop;

      --  Also a few irreducible-ish / mixed cases: random dense polys
      for Pi in 1 .. 8 loop
         declare
            P : constant U64 := Primes (Pi);
            C0 : constant U64 := Rand (St, P);
            C1 : constant U64 := Rand (St, P);
            C2 : constant U64 := 1 + Rand (St, P - 1);  -- ensure deg 2
            F  : constant Poly := [C0, C1, C2];
            Br : constant Root_List :=
              Find_Roots_Deterministic_Small (F, P);
            Fr : constant Root_List := Find_Roots (F, P, 96, St.S);
         begin
            Check (Same_Roots (Fr, Br),
                   "random quad match p=" & U64'Image (P));
         end;
      end loop;

      Check (Cases >= 20, "generated enough product cases");
   end Test_Random_Vs_Brute;

   ------------------------------------------------------------------
   --  Extra poly / eval checks
   ------------------------------------------------------------------

   procedure Test_Extra is
      P : constant U64 := 17;
   begin
      Section ("Extra poly / roots");
      --  All residues as roots would be x^p - x; too big. Instead:
      --  product (x-0)(x-1)(x-2)(x-3) mod 17
      declare
         function Prod (R : U64) return Poly is
         begin
            if R = 0 then
               return [0 => (P - 0) rem P, 1 => 1];
            end if;
            return Poly_Mul
              (Prod (R - 1), [0 => (P - R) rem P, 1 => 1], P);
         end Prod;
         F : constant Poly := Prod (3);
         Br : constant Root_List :=
           Find_Roots_Deterministic_Small (F, P);
         Fr : constant Root_List := Find_Roots (F, P, 64, 11);
      begin
         Check (Br'Length = 4, "deg4 product brute len");
         Check (Same_Roots (Fr, Br), "deg4 product Berlekamp");
      end;

      --  No roots: (x^2+1)(x^2+2) over F_7?
      --  Check x^2+1 mod 7: residues 0,1,4,2 — 1 is QR so roots exist.
      --  x^2+3 mod 7: need Legendre(-3/7)... use brute
      declare
         F : constant Poly := [3, 0, 1];  -- x^2+3 mod 7
         Br : constant Root_List :=
           Find_Roots_Deterministic_Small (F, 7);
         Fr : constant Root_List := Find_Roots (F, 7, 32, 2);
      begin
         Check (Same_Roots (Fr, Br), "x^2+3 mod 7 match");
      end;

      --  Derivative of x^3+ax+b
      declare
         F : constant Poly := [5, 3, 0, 1];
         D : constant Poly := Poly_Derivative (F, P);
      begin
         Check (Poly_Degree (D, P) = 2, "deriv deg");
         Check (D (2) = 3, "deriv leading 3");
         Check (D (0) = 3, "deriv const");
      end;

      --  Normalize strips
      declare
         F : constant Poly := [1, 2, 0, 0];
         N : constant Poly := Poly_Normalize (F, P);
      begin
         Check (N'Last = 1, "normalize strips leading zeros");
      end;

      --  Seed stability: same seed ⇒ same roots (set equality)
      declare
         F : constant Poly := [2, 2, 1];
         R1 : constant Root_List := Find_Roots (F, 5, 32, 99);
         R2 : constant Root_List := Find_Roots (F, 5, 32, 99);
      begin
         Check (Same_Roots (R1, R2), "same seed reproducible");
      end;
   end Test_Extra;

begin
   Ada.Text_IO.Put_Line
     ("Berlekamp_Root_Finding — Ada 2023 test suite");

   Test_Modular;
   Test_Poly_Basics;
   Test_Poly_Gcd_Pow;
   Test_Known;
   Test_P2;
   Test_Multiple;
   Test_Domain;
   Test_Random_Vs_Brute;
   Test_Extra;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result:"
      & Natural'Image (Pass_Count)
      & " PASS,"
      & Natural'Image (Fail_Count)
      & " FAIL");

   if Fail_Count > 0 or else Pass_Count < 80 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
