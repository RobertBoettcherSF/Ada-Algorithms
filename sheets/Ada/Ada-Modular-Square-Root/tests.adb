--  Standalone test suite for Modular_Square_Root (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Modular_Square_Root; use Modular_Square_Root;

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

   function U (X : U64) return U64 is (X);

   function Img (X : U64) return String is
   begin
      return U64'Image (X);
   end Img;

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

   procedure Expect_Invalid_Pow (Label : String; B, E, M : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Mod_Pow (B, E, M);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Mod_Pow: " & Label);
   end Expect_Invalid_Pow;

   procedure Expect_Invalid_Sqrt_Proc (Label : String; N, P : U64) is
      Raised : Boolean := False;
      Root   : U64;
      Found  : Boolean;
   begin
      begin
         Sqrt_Mod_Prime (N, P, Root, Found);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Sqrt_Mod_Prime proc: " & Label);
   end Expect_Invalid_Sqrt_Proc;

   procedure Expect_Invalid_Sqrt_Fun (Label : String; N, P : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Sqrt_Mod_Prime (N, P);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Sqrt_Mod_Prime fun: " & Label);
   end Expect_Invalid_Sqrt_Fun;

   procedure Expect_Invalid_Legendre (Label : String; N, P : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Integer := Legendre (N, P);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Legendre: " & Label);
   end Expect_Invalid_Legendre;

   procedure Check_Root (N, P, Root : U64; Label : String) is
   begin
      Check (Mul_Mod (Root, Root, P) = (N rem P),
             "Root^2 ≡ N: " & Label);
   end Check_Root;

   procedure Check_Sqrt_Known
     (N, P : U64;
      A, B : U64;
      Label : String)
   is
      Root  : U64;
      Found : Boolean;
   begin
      Sqrt_Mod_Prime (N, P, Root, Found);
      Check (Found, "Found: " & Label);
      if Found then
         Check (Root = A or else Root = B,
                "Root in {a,b}: " & Label & " got" & Img (Root));
         Check_Root (N, P, Root, Label);
      end if;
   end Check_Sqrt_Known;

   procedure Check_No_Root (N, P : U64; Label : String) is
      Root  : U64;
      Found : Boolean;
   begin
      Sqrt_Mod_Prime (N, P, Root, Found);
      Check (not Found, "No root: " & Label);
      Check (Legendre (N, P) = -1, "Legendre=-1: " & Label);
   end Check_No_Root;

begin
   Ada.Text_IO.Put_Line ("Modular_Square_Root survey test suite");
   Ada.Text_IO.Put_Line ("=====================================");

   ------------------------------------------------------------------
   Section ("1. Taxonomy / Method_Kind");
   ------------------------------------------------------------------
   Check (Is_Implemented (Tonelli_Shanks), "Tonelli implemented");
   Check (not Is_Implemented (Cipolla), "Cipolla catalogue only");
   Check (Is_Implemented (P_Congruent_3_Mod_4), "p≡3 mod 4 implemented");
   Check (Is_Implemented (Brute_Force), "Brute force implemented");
   Check (not Is_Implemented (Catalogue_Composite_CRT),
          "Composite CRT catalogue only");
   Check (Method_Name (Tonelli_Shanks) = "Tonelli–Shanks",
          "Method_Name Tonelli");
   Check (Method_Name (Cipolla) =
            "Cipolla (catalogue / sibling)",
          "Method_Name Cipolla");
   Check (Method_Name (P_Congruent_3_Mod_4) =
            "p ≡ 3 (mod 4) fast path",
          "Method_Name p≡3");
   Check (Method_Name (Brute_Force) =
            "Brute force (tiny modulus)",
          "Method_Name Brute");
   Check (Method_Name (Catalogue_Composite_CRT) =
            "Composite CRT / Hensel (catalogue)",
          "Method_Name Composite CRT");

   ------------------------------------------------------------------
   Section ("2. Mul_Mod / Mod_Pow / Gcd");
   ------------------------------------------------------------------
   Check (Mul_Mod (U (3), U (4), U (5)) = 2, "Mul_Mod 3*4 mod 5 = 2");
   Check (Mul_Mod (U (7), U (8), U (9)) = 2, "Mul_Mod 7*8 mod 9 = 2");
   Check (Mul_Mod (U (0), U (99), U (17)) = 0, "Mul_Mod 0");
   Check (Mul_Mod (U (1), U (1), U (1)) = 0, "Mul_Mod mod 1");
   Check
     (Mul_Mod (U (2**32), U (2**32), U (1_000_000_007)) = 582_344_008,
      "Mul_Mod large 2^32*2^32");
   Check (Mod_Pow (U (2), U (10), U (1000)) = 24, "Mod_Pow 2^10 mod 1000");
   Check (Mod_Pow (U (3), U (5), U (13)) = 9, "Mod_Pow 3^5 mod 13");
   Check (Mod_Pow (U (2), U (0), U (5)) = 1, "Mod_Pow exp 0");
   Check (Mod_Pow (U (5), U (1), U (7)) = 5, "Mod_Pow exp 1");
   Check (Mod_Pow (U (10), U (9), U (1)) = 0, "Mod_Pow mod 1");
   Expect_Invalid_Mul ("modulus 0", U (1), U (1), U (0));
   Expect_Invalid_Pow ("modulus 0", U (2), U (3), U (0));
   Check (Gcd (U (0), U (0)) = 0, "Gcd(0,0)=0");
   Check (Gcd (U (12), U (18)) = 6, "Gcd(12,18)=6");
   Check (Gcd (U (17), U (13)) = 1, "Gcd(17,13)=1");
   Check (Gcd (U (100), U (0)) = 100, "Gcd(100,0)=100");
   Check (Gcd (U (0), U (42)) = 42, "Gcd(0,42)=42");

   ------------------------------------------------------------------
   Section ("3. Is_Prime_Trial");
   ------------------------------------------------------------------
   Check (not Is_Prime_Trial (U (0)), "0 not prime");
   Check (not Is_Prime_Trial (U (1)), "1 not prime");
   Check (Is_Prime_Trial (U (2)), "2 prime");
   Check (Is_Prime_Trial (U (3)), "3 prime");
   Check (not Is_Prime_Trial (U (4)), "4 not prime");
   Check (Is_Prime_Trial (U (5)), "5 prime");
   Check (not Is_Prime_Trial (U (9)), "9 not prime");
   Check (Is_Prime_Trial (U (17)), "17 prime");
   Check (not Is_Prime_Trial (U (91)), "91=7*13 not prime");
   Check (Is_Prime_Trial (U (97)), "97 prime");

   ------------------------------------------------------------------
   Section ("4. p = 2");
   ------------------------------------------------------------------
   declare
      Root  : U64;
      Found : Boolean;
   begin
      Sqrt_Mod_Prime (U (0), U (2), Root, Found);
      Check (Found and then Root = 0, "sqrt(0) mod 2 = 0");
      Sqrt_Mod_Prime (U (1), U (2), Root, Found);
      Check (Found and then Root = 1, "sqrt(1) mod 2 = 1");
      Sqrt_Mod_Prime (U (4), U (2), Root, Found);
      Check (Found and then Root = 0, "sqrt(4) mod 2 = 0");
      Check (Is_Quadratic_Residue_Prime (U (0), U (2)), "QR 0 mod 2");
      Check (Is_Quadratic_Residue_Prime (U (1), U (2)), "QR 1 mod 2");
   end;

   ------------------------------------------------------------------
   Section ("5. p ≡ 3 (mod 4): 7, 11, 19");
   ------------------------------------------------------------------
   Check_Sqrt_Known (U (1), U (7), U (1), U (6), "sqrt(1) mod 7");
   Check_Sqrt_Known (U (2), U (7), U (3), U (4), "sqrt(2) mod 7");
   Check_Sqrt_Known (U (4), U (7), U (2), U (5), "sqrt(4) mod 7");
   Check_No_Root (U (3), U (7), "3 nonres mod 7");
   Check_No_Root (U (5), U (7), "5 nonres mod 7");
   Check_No_Root (U (6), U (7), "6 nonres mod 7");

   Check_Sqrt_Known (U (1), U (11), U (1), U (10), "sqrt(1) mod 11");
   Check_Sqrt_Known (U (3), U (11), U (5), U (6), "sqrt(3) mod 11");
   Check_Sqrt_Known (U (4), U (11), U (2), U (9), "sqrt(4) mod 11");
   Check_Sqrt_Known (U (5), U (11), U (4), U (7), "sqrt(5) mod 11");
   Check_Sqrt_Known (U (9), U (11), U (3), U (8), "sqrt(9) mod 11");
   Check_No_Root (U (2), U (11), "2 nonres mod 11");
   Check_No_Root (U (6), U (11), "6 nonres mod 11");
   Check_No_Root (U (7), U (11), "7 nonres mod 11");

   Check_Sqrt_Known (U (1), U (19), U (1), U (18), "sqrt(1) mod 19");
   Check_Sqrt_Known (U (4), U (19), U (2), U (17), "sqrt(4) mod 19");
   Check_Sqrt_Known (U (5), U (19), U (9), U (10), "sqrt(5) mod 19");
   Check_Sqrt_Known (U (7), U (19), U (8), U (11), "sqrt(7) mod 19");
   Check_No_Root (U (2), U (19), "2 nonres mod 19");
   Check_No_Root (U (3), U (19), "3 nonres mod 19");

   --  Explicit fast-path API
   declare
      Root  : U64;
      Found : Boolean;
   begin
      Sqrt_P_Congruent_3_Mod_4 (U (2), U (7), Root, Found);
      Check (Found and then (Root = 3 or else Root = 4),
             "Sqrt_P_Congruent_3_Mod_4 2 mod 7");
      Check_Root (U (2), U (7), Root, "fast path 2 mod 7");
   end;

   ------------------------------------------------------------------
   Section ("6. Full Tonelli: p ≡ 1 (mod 8), e.g. 17");
   ------------------------------------------------------------------
   Check_Sqrt_Known (U (2), U (17), U (6), U (11), "sqrt(2) mod 17");
   Check_Sqrt_Known (U (1), U (17), U (1), U (16), "sqrt(1) mod 17");
   Check_Sqrt_Known (U (8), U (17), U (5), U (12), "sqrt(8) mod 17");
   Check_Sqrt_Known (U (13), U (17), U (8), U (9), "sqrt(13) mod 17");
   Check_No_Root (U (3), U (17), "3 nonres mod 17");
   Check_No_Root (U (5), U (17), "5 nonres mod 17");
   Check_Sqrt_Known (U (2), U (41), U (17), U (24), "sqrt(2) mod 41");
   Check_No_Root (U (3), U (41), "3 nonres mod 41");

   declare
      Root  : U64;
      Found : Boolean;
   begin
      Sqrt_Tonelli_Shanks (U (2), U (17), Root, Found);
      Check (Found and then (Root = 6 or else Root = 11),
             "Sqrt_Tonelli_Shanks 2 mod 17");
   end;

   ------------------------------------------------------------------
   Section ("7. Legendre / Is_Quadratic_Residue_Prime");
   ------------------------------------------------------------------
   Check (Legendre (U (0), U (7)) = 0, "Legendre(0,7)=0");
   Check (Legendre (U (1), U (7)) = 1, "Legendre(1,7)=1");
   Check (Legendre (U (2), U (7)) = 1, "Legendre(2,7)=1");
   Check (Legendre (U (3), U (7)) = -1, "Legendre(3,7)=-1");
   Check (Legendre (U (2), U (17)) = 1, "Legendre(2,17)=1");
   Check (Legendre (U (3), U (17)) = -1, "Legendre(3,17)=-1");
   Expect_Invalid_Legendre ("P=2", U (1), U (2));
   Expect_Invalid_Legendre ("P=9 composite", U (2), U (9));
   Check (Is_Quadratic_Residue_Prime (U (2), U (7)), "QR 2 mod 7");
   Check (not Is_Quadratic_Residue_Prime (U (3), U (7)), "not QR 3 mod 7");
   Check (Is_Quadratic_Residue_Prime (U (0), U (11)), "QR 0 mod 11");
   Check (Find_Quadratic_Non_Residue (U (7)) = 3, "NR mod 7 = 3");
   Check (Find_Quadratic_Non_Residue (U (17)) = 3, "NR mod 17 = 3");

   ------------------------------------------------------------------
   Section ("8. Function form / ±r / zero");
   ------------------------------------------------------------------
   declare
      R : U64;
   begin
      R := Sqrt_Mod_Prime (U (2), U (17));
      Check (R = 6 or else R = 11, "fun sqrt(2) mod 17");
      Check (Mul_Mod (R, R, U (17)) = 2, "fun verify");
      Check (Mul_Mod (U (17) - R, U (17) - R, U (17)) = 2,
             "other root -r");
      R := Sqrt_Mod_Prime (U (0), U (19));
      Check (R = 0, "fun sqrt(0)=0");
      R := Sqrt_Mod_Prime (U (2), U (7));
      Check (R = 3 or else R = 4, "fun sqrt(2) mod 7");
   end;
   Expect_Invalid_Sqrt_Fun ("no root 3 mod 7", U (3), U (7));
   Expect_Invalid_Sqrt_Fun ("no root 3 mod 17", U (3), U (17));

   ------------------------------------------------------------------
   Section ("9. Invalid_Argument edges");
   ------------------------------------------------------------------
   Expect_Invalid_Sqrt_Proc ("P=0", U (1), U (0));
   Expect_Invalid_Sqrt_Proc ("P=1", U (1), U (1));
   Expect_Invalid_Sqrt_Proc ("P=4 even", U (1), U (4));
   Expect_Invalid_Sqrt_Proc ("P=9 composite", U (1), U (9));
   Expect_Invalid_Sqrt_Proc ("P=15 composite", U (4), U (15));
   Expect_Invalid_Sqrt_Fun ("P=0 fun", U (1), U (0));
   Expect_Invalid_Sqrt_Fun ("P=8 fun", U (1), U (8));

   declare
      Raised : Boolean := False;
      Root   : U64;
      Found  : Boolean;
   begin
      begin
         Sqrt_P_Congruent_3_Mod_4 (U (2), U (17), Root, Found);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "fast path rejects p≡1 mod 4");
   end;

   ------------------------------------------------------------------
   Section ("10. Brute_Force_Sqrt tiny moduli");
   ------------------------------------------------------------------
   declare
      Root  : U64;
      Found : Boolean;
   begin
      Brute_Force_Sqrt (U (4), U (15), Root, Found);
      Check (Found, "brute sqrt(4) mod 15 found");
      Check (Mul_Mod (Root, Root, U (15)) = 4, "brute 4 mod 15 verify");

      Brute_Force_Sqrt (U (2), U (7), Root, Found);
      Check (Found and then (Root = 3 or else Root = 4),
             "brute sqrt(2) mod 7");

      Brute_Force_Sqrt (U (3), U (7), Root, Found);
      Check (not Found, "brute no root 3 mod 7");

      Brute_Force_Sqrt (U (0), U (10), Root, Found);
      Check (Found and then Root = 0, "brute sqrt(0) mod 10");

      Brute_Force_Sqrt (U (1), U (8), Root, Found);
      Check (Found and then Mul_Mod (Root, Root, U (8)) = 1,
             "brute sqrt(1) mod 8");
   end;

   declare
      Raised : Boolean := False;
      Root   : U64;
      Found  : Boolean;
   begin
      begin
         Brute_Force_Sqrt (U (1), U (0), Root, Found);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "brute M=0 raises");
   end;

   declare
      Raised : Boolean := False;
      Root   : U64;
      Found  : Boolean;
   begin
      begin
         Brute_Force_Sqrt (U (1), Max_Brute_Modulus + 1, Root, Found);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "brute M too large raises");
   end;

   ------------------------------------------------------------------
   Section ("11. Combine_Roots_CRT mod pq");
   ------------------------------------------------------------------
   declare
      --  N=16: sqrt mod 5 → 1 or 4; mod 7 → 3 or 4; mod 35
      Rp, Rq, R : U64;
      Found_P, Found_Q : Boolean;
   begin
      Sqrt_Mod_Prime (U (16), U (5), Rp, Found_P);
      Sqrt_Mod_Prime (U (16), U (7), Rq, Found_Q);
      Check (Found_P and Found_Q, "roots of 16 mod 5 and 7");
      R := Combine_Roots_CRT (Rp, U (5), Rq, U (7));
      Check (Mul_Mod (R, R, U (35)) = 16, "CRT combine 16 mod 35");
      Check (R rem 5 = Rp rem 5, "CRT R ≡ Rp mod 5");
      Check (R rem 7 = Rq rem 7, "CRT R ≡ Rq mod 7");

      --  Another sign choice
      R := Combine_Roots_CRT (U (5) - Rp, U (5), Rq, U (7));
      Check (Mul_Mod (R, R, U (35)) = 16, "CRT ±Rp combine 16 mod 35");
   end;

   Check (Mod_Inv (U (3), U (7)) = 5, "Mod_Inv 3 mod 7 = 5");
   Check (Mod_Inv (U (5), U (7)) = 3, "Mod_Inv 5*3=15≡1 mod 7");

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Combine_Roots_CRT
              (U (1), U (15), U (1), U (21));  -- gcd=3
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "CRT rejects non-coprime");
   end;

   ------------------------------------------------------------------
   Section ("12. Exhaustive residues for primes ≤ 50");
   ------------------------------------------------------------------
   declare
      Primes : constant array (Positive range <>) of U64 :=
        [3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47];
      All_Ok : Boolean := True;
   begin
      for P of Primes loop
         for N in U64 range 0 .. P - 1 loop
            declare
               Root  : U64;
               Found : Boolean;
               L     : constant Integer := Legendre (N, P);
            begin
               Sqrt_Mod_Prime (N, P, Root, Found);
               if L = -1 then
                  if Found then
                     All_Ok := False;
                  end if;
               else
                  if not Found then
                     All_Ok := False;
                  elsif Mul_Mod (Root, Root, P) /= N then
                     All_Ok := False;
                  end if;
               end if;
            end;
         end loop;
      end loop;
      Check (All_Ok, "exhaustive Legendre/sqrt for primes ≤ 47");
   end;

   ------------------------------------------------------------------
   Section ("13. Many primes ≤ 200 (random-ish + squares)");
   ------------------------------------------------------------------
   declare
      Primes : constant array (Positive range <>) of U64 :=
        [53, 59, 61, 67, 71, 73, 79, 83, 89, 97,
         101, 103, 107, 109, 113, 127, 131, 137, 139, 149,
         151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199];
      Failures : Natural := 0;
      Checks   : Natural := 0;
   begin
      for P of Primes loop
         for K in U64 range 0 .. 5 loop
            declare
               N     : constant U64 := (P * K + 17 * K * K + 3) rem P;
               Root  : U64;
               Found : Boolean;
               L     : constant Integer := Legendre (N, P);
            begin
               Sqrt_Mod_Prime (N, P, Root, Found);
               Checks := Checks + 1;
               if L = -1 then
                  if Found then
                     Failures := Failures + 1;
                  end if;
               else
                  if (not Found)
                    or else Mul_Mod (Root, Root, P) /= N
                  then
                     Failures := Failures + 1;
                  end if;
               end if;
            end;
         end loop;
         for A in U64 range 1 .. 4 loop
            declare
               N     : constant U64 := Mul_Mod (A, A, P);
               Root  : U64;
               Found : Boolean;
            begin
               Sqrt_Mod_Prime (N, P, Root, Found);
               Checks := Checks + 1;
               if (not Found)
                 or else Mul_Mod (Root, Root, P) /= N
               then
                  Failures := Failures + 1;
               end if;
            end;
         end loop;
      end loop;
      Check (Failures = 0,
             "primes≤200:" & Natural'Image (Checks)
             & " checks, 0 failures");
      Check (Checks >= 200, "enough primes≤200 checks");
   end;

   ------------------------------------------------------------------
   Section ("14. Brute vs Sqrt_Mod_Prime agreement (small primes)");
   ------------------------------------------------------------------
   declare
      Ok : Boolean := True;
      Ps : constant array (Positive range <>) of U64 :=
        [3, 5, 7, 11, 13, 17, 19, 23];
   begin
      for P of Ps loop
         for N in U64 range 0 .. P - 1 loop
            declare
               R1, R2 : U64;
               F1, F2 : Boolean;
            begin
               Sqrt_Mod_Prime (N, P, R1, F1);
               Brute_Force_Sqrt (N, P, R2, F2);
               if F1 /= F2 then
                  Ok := False;
               elsif F1 and then Mul_Mod (R1, R1, P) /= N then
                  Ok := False;
               elsif F2 and then Mul_Mod (R2, R2, P) /= N then
                  Ok := False;
               end if;
            end;
         end loop;
      end loop;
      Check (Ok, "brute agrees with Sqrt_Mod_Prime on small primes");
   end;

   ------------------------------------------------------------------
   Section ("15. Is_QR / Legendre consistency");
   ------------------------------------------------------------------
   declare
      Ps : constant array (Positive range <>) of U64 :=
        [7, 11, 13, 17, 19, 23, 29, 31];
      Ok : Boolean := True;
   begin
      for P of Ps loop
         for N in U64 range 0 .. P - 1 loop
            declare
               L  : constant Integer := Legendre (N, P);
               QR : constant Boolean :=
                 Is_Quadratic_Residue_Prime (N, P);
            begin
               if L = -1 and then QR then
                  Ok := False;
               elsif L >= 0 and then not QR then
                  Ok := False;
               end if;
            end;
         end loop;
      end loop;
      Check (Ok, "Is_QR matches Legendre for small primes");
   end;

   ------------------------------------------------------------------
   --  Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result:" & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count > 0 or else Pass_Count < 80 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
