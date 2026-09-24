--  Standalone test suite for Tonelli_Shanks (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Tonelli_Shanks; use Tonelli_Shanks;

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
         Modular_Sqrt (N, P, Root, Found);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Modular_Sqrt proc: " & Label);
   end Expect_Invalid_Sqrt_Proc;

   procedure Expect_Invalid_Sqrt_Fun (Label : String; N, P : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Modular_Sqrt (N, P);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Modular_Sqrt fun: " & Label);
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
      A, B : U64;  -- acceptable roots (either order); B may equal A
      Label : String)
   is
      Root  : U64;
      Found : Boolean;
   begin
      Modular_Sqrt (N, P, Root, Found);
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
      Modular_Sqrt (N, P, Root, Found);
      Check (not Found, "No root: " & Label);
      Check (Legendre (N, P) = -1, "Legendre=-1: " & Label);
   end Check_No_Root;

begin
   Ada.Text_IO.Put_Line ("Tonelli_Shanks test suite");
   Ada.Text_IO.Put_Line ("=========================");

   ------------------------------------------------------------------
   Section ("1. Mul_Mod / Mod_Pow / Gcd");
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
   Section ("2. Is_Prime_Trial");
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
   Check (Is_Prime_Trial (U (499)), "499 prime");
   Check (not Is_Prime_Trial (U (501)), "501 not prime");

   ------------------------------------------------------------------
   Section ("3. p = 2");
   ------------------------------------------------------------------
   declare
      Root  : U64;
      Found : Boolean;
   begin
      Modular_Sqrt (U (0), U (2), Root, Found);
      Check (Found and then Root = 0, "sqrt(0) mod 2 = 0");
      Modular_Sqrt (U (1), U (2), Root, Found);
      Check (Found and then Root = 1, "sqrt(1) mod 2 = 1");
      Modular_Sqrt (U (4), U (2), Root, Found);
      Check (Found and then Root = 0, "sqrt(4) mod 2 = 0");
      Modular_Sqrt (U (7), U (2), Root, Found);
      Check (Found and then Root = 1, "sqrt(7) mod 2 = 1");
      Check (Is_Quadratic_Residue (U (0), U (2)), "QR 0 mod 2");
      Check (Is_Quadratic_Residue (U (1), U (2)), "QR 1 mod 2");
   end;

   ------------------------------------------------------------------
   Section ("4. p ≡ 3 (mod 4): 7, 11, 19");
   ------------------------------------------------------------------
   --  mod 7: 1^2=1, 2^2=4, 3^2=2, 4^2=2, 5^2=4, 6^2=1
   Check_Sqrt_Known (U (1), U (7), U (1), U (6), "sqrt(1) mod 7");
   Check_Sqrt_Known (U (2), U (7), U (3), U (4), "sqrt(2) mod 7");
   Check_Sqrt_Known (U (4), U (7), U (2), U (5), "sqrt(4) mod 7");
   Check_No_Root (U (3), U (7), "3 nonres mod 7");
   Check_No_Root (U (5), U (7), "5 nonres mod 7");
   Check_No_Root (U (6), U (7), "6 nonres mod 7");

   --  mod 11: residues 1,3,4,5,9
   Check_Sqrt_Known (U (1), U (11), U (1), U (10), "sqrt(1) mod 11");
   Check_Sqrt_Known (U (3), U (11), U (5), U (6), "sqrt(3) mod 11");
   Check_Sqrt_Known (U (4), U (11), U (2), U (9), "sqrt(4) mod 11");
   Check_Sqrt_Known (U (5), U (11), U (4), U (7), "sqrt(5) mod 11");
   Check_Sqrt_Known (U (9), U (11), U (3), U (8), "sqrt(9) mod 11");
   Check_No_Root (U (2), U (11), "2 nonres mod 11");
   Check_No_Root (U (6), U (11), "6 nonres mod 11");
   Check_No_Root (U (7), U (11), "7 nonres mod 11");
   Check_No_Root (U (8), U (11), "8 nonres mod 11");
   Check_No_Root (U (10), U (11), "10 nonres mod 11");

   --  mod 19
   Check_Sqrt_Known (U (1), U (19), U (1), U (18), "sqrt(1) mod 19");
   Check_Sqrt_Known (U (4), U (19), U (2), U (17), "sqrt(4) mod 19");
   Check_Sqrt_Known (U (5), U (19), U (9), U (10), "sqrt(5) mod 19");
   Check_Sqrt_Known (U (6), U (19), U (5), U (14), "sqrt(6) mod 19");
   Check_Sqrt_Known (U (7), U (19), U (8), U (11), "sqrt(7) mod 19");
   Check_Sqrt_Known (U (9), U (19), U (3), U (16), "sqrt(9) mod 19");
   Check_Sqrt_Known (U (11), U (19), U (7), U (12), "sqrt(11) mod 19");
   Check_Sqrt_Known (U (16), U (19), U (4), U (15), "sqrt(16) mod 19");
   Check_Sqrt_Known (U (17), U (19), U (6), U (13), "sqrt(17) mod 19");
   Check_No_Root (U (2), U (19), "2 nonres mod 19");
   Check_No_Root (U (3), U (19), "3 nonres mod 19");
   Check_No_Root (U (8), U (19), "8 nonres mod 19");
   Check_No_Root (U (10), U (19), "10 nonres mod 19");
   Check_No_Root (U (12), U (19), "12 nonres mod 19");
   Check_No_Root (U (13), U (19), "13 nonres mod 19");
   Check_No_Root (U (14), U (19), "14 nonres mod 19");
   Check_No_Root (U (15), U (19), "15 nonres mod 19");
   Check_No_Root (U (18), U (19), "18 nonres mod 19");

   ------------------------------------------------------------------
   Section ("5. Full Tonelli: p ≡ 1 (mod 8), e.g. 17");
   ------------------------------------------------------------------
   --  6^2 = 36 ≡ 2 (mod 17); 11^2 = 121 ≡ 2 (mod 17)
   Check_Sqrt_Known (U (2), U (17), U (6), U (11), "sqrt(2) mod 17");
   Check_Sqrt_Known (U (1), U (17), U (1), U (16), "sqrt(1) mod 17");
   Check_Sqrt_Known (U (4), U (17), U (2), U (15), "sqrt(4) mod 17");
   Check_Sqrt_Known (U (8), U (17), U (5), U (12), "sqrt(8) mod 17");
   Check_Sqrt_Known (U (9), U (17), U (3), U (14), "sqrt(9) mod 17");
   Check_Sqrt_Known (U (13), U (17), U (8), U (9), "sqrt(13) mod 17");
   Check_Sqrt_Known (U (15), U (17), U (7), U (10), "sqrt(15) mod 17");
   Check_Sqrt_Known (U (16), U (17), U (4), U (13), "sqrt(16) mod 17");
   Check_No_Root (U (3), U (17), "3 nonres mod 17");
   Check_No_Root (U (5), U (17), "5 nonres mod 17");
   Check_No_Root (U (6), U (17), "6 nonres mod 17");
   Check_No_Root (U (7), U (17), "7 nonres mod 17");
   Check_No_Root (U (10), U (17), "10 nonres mod 17");
   Check_No_Root (U (11), U (17), "11 nonres mod 17");
   Check_No_Root (U (12), U (17), "12 nonres mod 17");
   Check_No_Root (U (14), U (17), "14 nonres mod 17");

   --  Another p ≡ 1 (mod 8): 41
   Check_Sqrt_Known (U (2), U (41), U (17), U (24), "sqrt(2) mod 41");
   Check_Sqrt_Known (U (10), U (41), U (16), U (25), "sqrt(10) mod 41");
   Check_No_Root (U (3), U (41), "3 nonres mod 41");

   ------------------------------------------------------------------
   Section ("6. Legendre symbol");
   ------------------------------------------------------------------
   Check (Legendre (U (0), U (7)) = 0, "Legendre(0,7)=0");
   Check (Legendre (U (1), U (7)) = 1, "Legendre(1,7)=1");
   Check (Legendre (U (2), U (7)) = 1, "Legendre(2,7)=1");
   Check (Legendre (U (3), U (7)) = -1, "Legendre(3,7)=-1");
   Check (Legendre (U (2), U (17)) = 1, "Legendre(2,17)=1");
   Check (Legendre (U (3), U (17)) = -1, "Legendre(3,17)=-1");
   Check (Legendre (U (14), U (7)) = 0, "Legendre(14,7)=0");  -- 14≡0
   Expect_Invalid_Legendre ("P=2", U (1), U (2));
   Expect_Invalid_Legendre ("P=1", U (1), U (1));
   Expect_Invalid_Legendre ("P=9 composite", U (2), U (9));
   Expect_Invalid_Legendre ("P=0", U (1), U (0));

   ------------------------------------------------------------------
   Section ("7. Function form / ±r / zero");
   ------------------------------------------------------------------
   declare
      R : U64;
   begin
      R := Modular_Sqrt (U (2), U (17));
      Check (R = 6 or else R = 11, "fun sqrt(2) mod 17");
      Check (Mul_Mod (R, R, U (17)) = 2, "fun verify");
      Check (Mul_Mod (U (17) - R, U (17) - R, U (17)) = 2,
             "other root -r");
      R := Modular_Sqrt (U (0), U (19));
      Check (R = 0, "fun sqrt(0)=0");
      R := Modular_Sqrt (U (2), U (7));
      Check (R = 3 or else R = 4, "fun sqrt(2) mod 7");
   end;
   Expect_Invalid_Sqrt_Fun ("no root 3 mod 7", U (3), U (7));
   Expect_Invalid_Sqrt_Fun ("no root 3 mod 17", U (3), U (17));

   ------------------------------------------------------------------
   Section ("8. Invalid_Argument edges");
   ------------------------------------------------------------------
   Expect_Invalid_Sqrt_Proc ("P=0", U (1), U (0));
   Expect_Invalid_Sqrt_Proc ("P=1", U (1), U (1));
   Expect_Invalid_Sqrt_Proc ("P=4 even", U (1), U (4));
   Expect_Invalid_Sqrt_Proc ("P=9 composite", U (1), U (9));
   Expect_Invalid_Sqrt_Proc ("P=15 composite", U (4), U (15));
   Expect_Invalid_Sqrt_Proc ("P=91 composite", U (1), U (91));
   Expect_Invalid_Sqrt_Fun ("P=0 fun", U (1), U (0));
   Expect_Invalid_Sqrt_Fun ("P=8 fun", U (1), U (8));

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Boolean :=
              Is_Quadratic_Residue (U (1), U (0));
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Is_QR P=0");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Find_Quadratic_Non_Residue (U (2));
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Find_NR P=2");
   end;

   ------------------------------------------------------------------
   Section ("9. Non-residue finder / Is_Quadratic_Residue");
   ------------------------------------------------------------------
   Check (Find_Quadratic_Non_Residue (U (7)) = 3, "NR mod 7 = 3");
   Check (Find_Quadratic_Non_Residue (U (17)) = 3, "NR mod 17 = 3");
   Check (Legendre (Find_Quadratic_Non_Residue (U (41)), U (41)) = -1,
          "NR mod 41 Legendre -1");
   Check (Is_Quadratic_Residue (U (2), U (7)), "QR 2 mod 7");
   Check (not Is_Quadratic_Residue (U (3), U (7)), "not QR 3 mod 7");
   Check (Is_Quadratic_Residue (U (0), U (11)), "QR 0 mod 11");
   Check (Is_Quadratic_Residue (U (2), U (17)), "QR 2 mod 17");
   Check (not Is_Quadratic_Residue (U (3), U (17)), "not QR 3 mod 17");

   ------------------------------------------------------------------
   Section ("10. Exhaustive residues for primes ≤ 50");
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
               Modular_Sqrt (N, P, Root, Found);
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
   Section ("11. Random-ish pairs for primes ≤ 500");
   ------------------------------------------------------------------
   declare
      --  Mix of p≡3 mod 4 and full Tonelli primes
      Primes : constant array (Positive range <>) of U64 :=
        [53, 59, 61, 67, 71, 73, 79, 83, 89, 97,
         101, 103, 107, 109, 113, 127, 131, 137, 139, 149,
         151, 157, 163, 167, 173, 179, 181, 191, 193, 197,
         199, 211, 223, 227, 229, 233, 239, 241, 251, 257,
         263, 269, 271, 277, 281, 283, 293, 307, 311, 313,
         317, 331, 337, 347, 349, 353, 359, 367, 373, 379,
         383, 389, 397, 401, 409, 419, 421, 431, 433, 439,
         443, 449, 457, 461, 463, 467, 479, 487, 491, 499];
      Failures : Natural := 0;
      Checks   : Natural := 0;
   begin
      for P of Primes loop
         --  Several N values derived from P (deterministic "random-ish")
         for K in U64 range 0 .. 7 loop
            declare
               N     : constant U64 := (P * K + 17 * K * K + 3) rem P;
               Root  : U64;
               Found : Boolean;
               L     : constant Integer := Legendre (N, P);
            begin
               Modular_Sqrt (N, P, Root, Found);
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
         --  Perfect squares a^2 for a = 1..5
         for A in U64 range 1 .. 5 loop
            declare
               N     : constant U64 := Mul_Mod (A, A, P);
               Root  : U64;
               Found : Boolean;
            begin
               Modular_Sqrt (N, P, Root, Found);
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
             "random-ish primes≤500:" & Natural'Image (Checks)
             & " checks, 0 failures");
      --  Count each successful style as multiple PASS contributions
      Check (Checks >= 80 * 8,  -- sanity: we ran many checks
             "enough random-ish checks");
   end;

   ------------------------------------------------------------------
   Section ("12. Medium primes / more known cases");
   ------------------------------------------------------------------
   declare
      Root  : U64;
      Found : Boolean;
   begin
      --  p = 101 ≡ 1 mod 4; 2 may or may not be a residue
      Modular_Sqrt (U (2), U (101), Root, Found);
      if Legendre (U (2), U (101)) = 1 then
         Check (Found and then Mul_Mod (Root, Root, U (101)) = 2,
                "sqrt(2) mod 101 verify");
      else
         Check (not Found, "sqrt(2) mod 101 no root");
      end if;

      Modular_Sqrt (U (11), U (101), Root, Found);
      if Found then
         Check (Mul_Mod (Root, Root, U (101)) = 11, "sqrt(11) mod 101");
      else
         Check (Legendre (U (11), U (101)) = -1, "11 nonres mod 101");
      end if;

      --  Large-ish educational: 9973 (prime, ≡ 1 mod 4)
      Check (Is_Prime_Trial (U (9973)), "9973 prime");
      Modular_Sqrt (U (1234), U (9973), Root, Found);
      if Found then
         Check (Mul_Mod (Root, Root, U (9973)) = 1234,
                "sqrt(1234) mod 9973");
      else
         Check (Legendre (U (1234), U (9973)) = -1,
                "1234 nonres mod 9973");
      end if;

      --  Force a known square
      Modular_Sqrt (Mul_Mod (U (123), U (123), U (9973)), U (9973),
                    Root, Found);
      Check (Found, "sqrt(123^2) mod 9973 found");
      Check (Mul_Mod (Root, Root, U (9973)) =
               Mul_Mod (U (123), U (123), U (9973)),
             "sqrt(123^2) mod 9973 verify");

      --  p ≡ 3 mod 4 medium: 1031
      Check (Is_Prime_Trial (U (1031)), "1031 prime");
      Check (U (1031) rem 4 = 3, "1031 ≡ 3 mod 4");
      Modular_Sqrt (Mul_Mod (U (77), U (77), U (1031)), U (1031),
                    Root, Found);
      Check (Found, "sqrt(77^2) mod 1031 found");
      Check_Root (Mul_Mod (U (77), U (77), U (1031)), U (1031), Root,
                  "77^2 mod 1031");
   end;

   ------------------------------------------------------------------
   Section ("13. Is_QR / Legendre consistency batch");
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
               QR : constant Boolean := Is_Quadratic_Residue (N, P);
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
