--  Standalone test suite for Pohlig_Hellman (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Pohlig_Hellman; use Pohlig_Hellman;

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

   procedure Expect_Invalid_Mul_Mod (Label : String; A, B, M : U64) is
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
   end Expect_Invalid_Mul_Mod;

   procedure Expect_Invalid_Mod_Pow (Label : String; B, E, M : U64) is
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
   end Expect_Invalid_Mod_Pow;

   procedure Expect_Invalid_Inverse (Label : String; A, M : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Modular_Inverse (A, M);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Modular_Inverse: " & Label);
   end Expect_Invalid_Inverse;

   procedure Expect_Invalid_Factorize (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Factor_Array := Factorize_Trial (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Factorize_Trial: " & Label);
   end Expect_Invalid_Factorize;

   procedure Expect_Invalid_DL
     (Label : String; Alpha, Beta, Modulus, Order : U64)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 :=
              Discrete_Log_Pohlig_Hellman (Alpha, Beta, Modulus, Order);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Discrete_Log_PH: " & Label);
   end Expect_Invalid_DL;

   procedure Expect_Invalid_DL_Factors
     (Label   : String;
      Alpha, Beta, Modulus, Order : U64;
      Factors : Factor_Array)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 :=
              Discrete_Log_Pohlig_Hellman
                (Alpha, Beta, Modulus, Order, Factors);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Discrete_Log_PH factors: " & Label);
   end Expect_Invalid_DL_Factors;

   G   : U64;
   Fac : Factor_Array (1 .. 8);

begin
   Ada.Text_IO.Put_Line ("Pohlig_Hellman — Ada 2023 test suite");

   ------------------------------------------------------------------
   Section ("1. Gcd / Mul_Mod / Sub_Mod");
   ------------------------------------------------------------------
   Check (Gcd (U (0), U (0)) = 0, "gcd(0,0)=0");
   Check (Gcd (U (12), U (18)) = 6, "gcd(12,18)=6");
   Check (Gcd (U (17), U (13)) = 1, "gcd(17,13)=1");
   Check (Gcd (U (100), U (0)) = 100, "gcd(100,0)=100");
   Check (Gcd (U (0), U (42)) = 42, "gcd(0,42)=42");
   Check (Gcd (U (28), U (7)) = 7, "gcd(28,7)=7");
   Check (Gcd (U (180), U (12)) = 12, "gcd(180,12)=12");

   Check (Mul_Mod (U (7), U (6), U (10)) = 2, "7*6 mod 10 = 2");
   Check (Mul_Mod (U (0), U (5), U (9)) = 0, "0*5 mod 9 = 0");
   Check (Mul_Mod (U (2), U (3), U (1)) = 0, "any mod 1 = 0");
   Check (Mul_Mod (U (2), U (22), U (29)) = 15, "2*22 mod 29");
   Check (Mul_Mod (U (123456789), U (987654321), U (1_000_000_007)) =
            259_106_859,
          "large Mul_Mod");
   Expect_Invalid_Mul_Mod ("M=0", U (1), U (1), U (0));

   Check (Sub_Mod (U (5), U (3), U (10)) = 2, "5-3 mod 10");
   Check (Sub_Mod (U (3), U (5), U (10)) = 8, "3-5 mod 10");
   Check (Sub_Mod (U (0), U (1), U (28)) = 27, "0-1 mod 28");
   Check (Sub_Mod (U (22), U (5), U (28)) = 17, "22-5 mod 28");

   ------------------------------------------------------------------
   Section ("2. Mod_Pow");
   ------------------------------------------------------------------
   Check (Mod_Pow (U (2), U (22), U (29)) = 5, "2^22 mod 29 = 5");
   Check (Mod_Pow (U (2), U (0), U (29)) = 1, "2^0 = 1");
   Check (Mod_Pow (U (5), U (6), U (23)) = 8, "5^6 mod 23 = 8");
   Check (Mod_Pow (U (2), U (5), U (19)) = 13, "2^5 mod 19 = 13");
   Check (Mod_Pow (U (2), U (123), U (181)) = 151, "2^123 mod 181 = 151");
   Check (Mod_Pow (U (3), U (5), U (13)) = 9, "3^5 mod 13 = 9");
   Check (Mod_Pow (U (7), U (1), U (11)) = 7, "7^1 mod 11");
   Check (Mod_Pow (U (2), U (100), U (101)) = 1, "2^100 mod 101 (Fermat)");
   Expect_Invalid_Mod_Pow ("M=0", U (2), U (3), U (0));
   Check (Mod_Pow (U (9), U (0), U (1)) = 0, "any^e mod 1 = 0");

   ------------------------------------------------------------------
   Section ("3. Modular_Inverse");
   ------------------------------------------------------------------
   Check (Modular_Inverse (U (3), U (10)) = 7, "3^{-1} mod 10 = 7");
   Check (Modular_Inverse (U (7), U (10)) = 3, "7^{-1} mod 10 = 3");
   Check (Mul_Mod (U (5), Modular_Inverse (U (5), U (28)), U (28)) = 1,
          "5*inv ≡ 1 mod 28");
   Check (Mul_Mod (U (5), Modular_Inverse (U (5), U (22)), U (22)) = 1,
          "5*inv ≡ 1 mod 22");
   Check (Modular_Inverse (U (1), U (180)) = 1, "1^{-1} = 1");
   Expect_Invalid_Inverse ("M=1", U (1), U (1));
   Expect_Invalid_Inverse ("M=0", U (1), U (0));
   Expect_Invalid_Inverse ("gcd>1", U (4), U (10));
   Expect_Invalid_Inverse ("gcd>1 (6,28)", U (6), U (28));

   ------------------------------------------------------------------
   Section ("4. Factorize_Trial / Product / Smooth");
   ------------------------------------------------------------------
   declare
      F28  : constant Factor_Array := Factorize_Trial (U (28));
      F180 : constant Factor_Array := Factorize_Trial (U (180));
      F22  : constant Factor_Array := Factorize_Trial (U (22));
      F18  : constant Factor_Array := Factorize_Trial (U (18));
      F1   : constant Factor_Array := Factorize_Trial (U (1));
      F7   : constant Factor_Array := Factorize_Trial (U (7));
      F16  : constant Factor_Array := Factorize_Trial (U (16));
   begin
      Check (F28'Length = 2, "28 → 2 factors");
      Check (F28 (1).Prime = 2 and then F28 (1).Exp = 2, "28: 2^2");
      Check (F28 (2).Prime = 7 and then F28 (2).Exp = 1, "28: 7^1");
      Check (Product_Of_Factors (F28) = 28, "product(28 factors)=28");

      Check (F180'Length = 3, "180 → 3 factors");
      Check (F180 (1).Prime = 2 and then F180 (1).Exp = 2, "180: 2^2");
      Check (F180 (2).Prime = 3 and then F180 (2).Exp = 2, "180: 3^2");
      Check (F180 (3).Prime = 5 and then F180 (3).Exp = 1, "180: 5^1");
      Check (Product_Of_Factors (F180) = 180, "product(180)=180");

      Check (F22 (1).Prime = 2 and then F22 (2).Prime = 11, "22=2*11");
      Check (F18 (1).Prime = 2 and then F18 (2).Prime = 3
               and then F18 (2).Exp = 2,
             "18=2*3^2");
      Check (F1'Length = 0, "1 → empty factors");
      Check (F7'Length = 1 and then F7 (1).Prime = 7, "7 → 7^1");
      Check (F16'Length = 1 and then F16 (1).Exp = 4, "16=2^4");

      Check (Is_Smooth_Enough (F28), "28 is smooth enough");
      Check (Is_Smooth_Enough (F180), "180 is smooth enough");
   end;
   Expect_Invalid_Factorize ("N=0", U (0));

   --  Large prime factor → not smooth enough for educational solver
   declare
      Big : constant Factor_Array :=
        [1 => (Prime => Max_Prime_Factor + 1, Exp => 1)];
   begin
      Check (not Is_Smooth_Enough (Big),
             "prime > Max_Prime_Factor → not smooth");
   end;

   ------------------------------------------------------------------
   Section ("5. Verify_Discrete_Log");
   ------------------------------------------------------------------
   Check (Verify_Discrete_Log (U (2), U (5), U (29), U (22)),
          "verify 2^22≡5 mod 29");
   Check (Verify_Discrete_Log (U (2), U (151), U (181), U (123)),
          "verify 2^123≡151 mod 181");
   Check (Verify_Discrete_Log (U (5), U (8), U (23), U (6)),
          "verify 5^6≡8 mod 23");
   Check (Verify_Discrete_Log (U (2), U (1), U (29), U (0)),
          "verify γ=0 → β=1");
   Check (not Verify_Discrete_Log (U (2), U (5), U (29), U (21)),
          "wrong γ rejected");
   Check (not Verify_Discrete_Log (U (2), U (5), U (1), U (22)),
          "modulus 1 → False");

   ------------------------------------------------------------------
   Section ("6. Invalid_Argument Discrete_Log_PH");
   ------------------------------------------------------------------
   Expect_Invalid_DL ("Modulus=0", U (2), U (5), U (0), U (10));
   Expect_Invalid_DL ("Modulus=1", U (2), U (5), U (1), U (10));
   Expect_Invalid_DL ("Order=0", U (2), U (5), U (29), U (0));
   Expect_Invalid_DL ("Order too big", U (2), U (5), U (29),
                      Max_Educational_Order + 1);
   Expect_Invalid_DL ("Alpha=0", U (0), U (5), U (29), U (28));
   Expect_Invalid_DL ("Beta=0", U (2), U (0), U (29), U (28));
   Expect_Invalid_DL ("Alpha≡0", U (29), U (5), U (29), U (28));

   Fac (1) := (Prime => 2, Exp => 2);
   Fac (2) := (Prime => 7, Exp => 1);
   Expect_Invalid_DL_Factors
     ("wrong product", U (2), U (5), U (29), U (28), Fac (1 .. 1));
   Expect_Invalid_DL_Factors
     ("empty factors Order>1", U (2), U (5), U (29), U (28),
      Factor_Array'(1 .. 0 => <>));
   Fac (1) := (Prime => 2, Exp => 0);
   Expect_Invalid_DL_Factors
     ("Exp=0", U (2), U (5), U (29), U (4), Fac (1 .. 1));

   ------------------------------------------------------------------
   Section ("7. Classic: 2^γ ≡ 5 (mod 29), n=28=2^2·7");
   ------------------------------------------------------------------
   G := Discrete_Log_Pohlig_Hellman (U (2), U (5), U (29), U (28));
   Check (G = 22, "2^γ≡5 mod 29 → γ=22");
   Check (Verify_Discrete_Log (U (2), U (5), U (29), G), "29 result verifies");
   Check (G < U (28), "29 result < Order");

   G := Discrete_Log_Pohlig_Hellman (U (2), U (3), U (29), U (28));
   Check (G = 5, "2^γ≡3 mod 29 → γ=5");

   G := Discrete_Log_Pohlig_Hellman (U (2), U (12), U (29), U (28));
   Check (G = 7, "2^γ≡12 mod 29 → γ=7");

   G := Discrete_Log_Pohlig_Hellman (U (2), U (9), U (29), U (28));
   Check (G = 10, "2^γ≡9 mod 29 → γ=10");

   G := Discrete_Log_Pohlig_Hellman (U (2), U (1), U (29), U (28));
   Check (G = 0, "2^γ≡1 → γ=0");

   G := Discrete_Log_Pohlig_Hellman (U (2), U (2), U (29), U (28));
   Check (G = 1, "2^γ≡2 → γ=1");

   ------------------------------------------------------------------
   Section ("8. Precomputed factors overload");
   ------------------------------------------------------------------
   declare
      F28 : constant Factor_Array :=
        [(Prime => 2, Exp => 2), (Prime => 7, Exp => 1)];
   begin
      G := Discrete_Log_Pohlig_Hellman
        (U (2), U (5), U (29), U (28), F28);
      Check (G = 22, "precomputed factors → γ=22");
      G := Discrete_Log_Pohlig_Hellman
        (U (2), U (14), U (29), U (28), F28);
      Check (G = 13, "precomputed 2^13≡14 mod 29");
   end;

   ------------------------------------------------------------------
   Section ("9. Smooth order 180: 2^γ ≡ 151 (mod 181)");
   ------------------------------------------------------------------
   G := Discrete_Log_Pohlig_Hellman (U (2), U (151), U (181), U (180));
   Check (G = 123, "2^γ≡151 mod 181 → γ=123");
   Check (Verify_Discrete_Log (U (2), U (151), U (181), G),
          "181 result verifies");

   G := Discrete_Log_Pohlig_Hellman (U (2), U (4), U (181), U (180));
   Check (G = 2, "2^γ≡4 mod 181 → γ=2");

   G := Discrete_Log_Pohlig_Hellman (U (2), U (8), U (181), U (180));
   Check (G = 3, "2^γ≡8 mod 181 → γ=3");

   ------------------------------------------------------------------
   Section ("10. Tiny fields (smooth orders)");
   ------------------------------------------------------------------
   --  (Z/19)*; α=2 order 18=2·3²; 2^5≡13
   G := Discrete_Log_Pohlig_Hellman (U (2), U (13), U (19), U (18));
   Check (G = 5, "2^γ≡13 mod 19 → γ=5");

   G := Discrete_Log_Pohlig_Hellman (U (2), U (14), U (19), U (18));
   Check (G = 7, "2^γ≡14 mod 19 → γ=7");

   G := Discrete_Log_Pohlig_Hellman (U (2), U (17), U (19), U (18));
   Check (G = 10, "2^γ≡17 mod 19 → γ=10");

   --  (Z/23)*; α=5 order 22=2·11; 5^6≡8
   G := Discrete_Log_Pohlig_Hellman (U (5), U (8), U (23), U (22));
   Check (G = 6, "5^γ≡8 mod 23 → γ=6");

   G := Discrete_Log_Pohlig_Hellman (U (5), U (5), U (23), U (22));
   Check (G = 1, "5^γ≡5 mod 23 → γ=1");

   G := Discrete_Log_Pohlig_Hellman (U (5), U (20), U (23), U (22));
   Check (G = 5, "5^γ≡20 mod 23 → γ=5");

   --  (Z/41)*; α=6 is a primitive root? check order 40=2^3·5
   --  Use α=6: verify a few known powers
   Check (Mod_Pow (U (6), U (40), U (41)) = 1, "6^40≡1 mod 41");
   G := Discrete_Log_Pohlig_Hellman (U (6), U (36), U (41), U (40));
   --  6^2=36
   Check (G = 2, "6^γ≡36 mod 41 → γ=2");

   G := Discrete_Log_Pohlig_Hellman (U (6), U (11), U (41), U (40));
   --  compute expected
   declare
      Expected : U64 := U64'Last;
   begin
      for X in U64 range 0 .. 39 loop
         if Mod_Pow (U (6), X, U (41)) = 11 then
            Expected := X;
            exit;
         end if;
      end loop;
      Check (G = Expected and then Expected < 40,
             "6^γ≡11 mod 41 recovered");
   end;

   --  (Z/53)* order 52=2^2·13; α=2
   Check (Mod_Pow (U (2), U (52), U (53)) = 1, "2^52≡1 mod 53");
   G := Discrete_Log_Pohlig_Hellman (U (2), U (16), U (53), U (52));
   Check (G = 4, "2^γ≡16 mod 53 → γ=4");

   G := Discrete_Log_Pohlig_Hellman (U (2), U (30), U (53), U (52));
   declare
      Expected : U64 := U64'Last;
   begin
      for X in U64 range 0 .. 51 loop
         if Mod_Pow (U (2), X, U (53)) = 30 then
            Expected := X;
            exit;
         end if;
      end loop;
      Check (G = Expected and then Expected < 52,
             "2^γ≡30 mod 53 recovered");
   end;

   ------------------------------------------------------------------
   Section ("11. More smooth demos / edge cases");
   ------------------------------------------------------------------
   --  Subgroup of order 8=2^3 in (Z/17)*; α=2 has order 8 (2^8≡1, 2^4≡−1).
   Check (Mod_Pow (U (2), U (8), U (17)) = 1, "2^8≡1 mod 17");
   G := Discrete_Log_Pohlig_Hellman (U (2), U (13), U (17), U (8));
   --  2^6=64≡13 mod 17
   Check (G = 6, "2^γ≡13 mod 17 (ord 8) → γ=6");

   G := Discrete_Log_Pohlig_Hellman (U (2), U (4), U (17), U (8));
   Check (G = 2, "2^γ≡4 mod 17 → γ=2");

   --  Order 1 edge via factors empty handled inside when Order=1
   --  Modulus 2, Alpha=1, Beta=1, Order=1
   G := Discrete_Log_Pohlig_Hellman (U (1), U (1), U (2), U (1));
   Check (G = 0, "trivial Order=1 → γ=0");

   --  β not in ⟨α⟩: α=4 mod 29 has order 7 (4^7=16384…); use order 7,
   --  β=2 not a power of 4 in the order-7 subgroup
   --  4 generates subgroup {1,4,16,6,24,9,7} mod 29
   G := Discrete_Log_Pohlig_Hellman (U (4), U (2), U (29), U (7));
   Check (G = 7, "β∉⟨α⟩ → failure sentinel Order");

   --  Not smooth enough: fabricate order with huge prime (but keep
   --  educational Order ≤ Max). Use Factors overload with huge prime.
   declare
      Huge : constant Factor_Array :=
        [1 => (Prime => Max_Prime_Factor + 17, Exp => 1)];
      Ord  : constant U64 := Max_Prime_Factor + 17;
   begin
      --  Max_Prime_Factor+17 is well below Max_Educational_Order.
      G := Discrete_Log_Pohlig_Hellman
        (U (2), U (3), U (Ord + 1), Ord, Huge);
      Check (G = Ord, "not smooth enough → sentinel Order");
   end;

   ------------------------------------------------------------------
   Section ("12. Batch known exponents (mod 29)");
   ------------------------------------------------------------------
   declare
      Betas : constant array (Positive range <>) of U64 :=
        [1, 2, 4, 8, 16, 3, 6, 12, 24, 19, 9, 18, 7, 14];
      --  γ = 0 .. 13
   begin
      for I in Betas'Range loop
         G := Discrete_Log_Pohlig_Hellman
           (U (2), Betas (I), U (29), U (28));
         Check (G = U64 (I - 1),
                "batch mod 29 γ=" & Natural'Image (I - 1));
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("13. Batch known exponents (mod 19)");
   ------------------------------------------------------------------
   declare
      --  2^γ mod 19 for γ=0..9
      Betas : constant array (Positive range <>) of U64 :=
        [1, 2, 4, 8, 16, 13, 7, 14, 9, 18];
   begin
      for I in Betas'Range loop
         G := Discrete_Log_Pohlig_Hellman
           (U (2), Betas (I), U (19), U (18));
         Check (G = U64 (I - 1),
                "batch mod 19 γ=" & Natural'Image (I - 1));
      end loop;
   end;

   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results:" & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
