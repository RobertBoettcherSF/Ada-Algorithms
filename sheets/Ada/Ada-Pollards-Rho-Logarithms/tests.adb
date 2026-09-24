--  Standalone test suite for Pollards_Rho_Logarithms (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Pollards_Rho_Logarithms; use Pollards_Rho_Logarithms;

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
   function Nat (X : Natural) return Natural is (X);

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

   procedure Expect_Invalid_DL
     (Label : String; Alpha, Beta, Modulus, Order : U64)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 :=
              Discrete_Log_Rho (Alpha, Beta, Modulus, Order);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Discrete_Log_Rho: " & Label);
   end Expect_Invalid_DL;

   --  Try several seeds until a verified log appears (classroom helper).
   function Discrete_Log_With_Retries
     (Alpha, Beta, Modulus, Order : U64;
      Max_Tries                   : Natural := 16) return U64
   is
      G : U64;
      S : U64 := 0;
   begin
      for I in 1 .. Max_Tries loop
         G := Discrete_Log_Rho (Alpha, Beta, Modulus, Order, Seed => S);
         if G < Order
           and then Verify_Discrete_Log (Alpha, Beta, Modulus, G)
         then
            return G;
         end if;
         S := S + 1;
      end loop;
      return Order;
   end Discrete_Log_With_Retries;

   G : U64;

begin
   Ada.Text_IO.Put_Line ("Pollards_Rho_Logarithms — Ada 2023 test suite");

   ------------------------------------------------------------------
   Section ("1. Gcd / Mul_Mod / Sub_Mod");
   ------------------------------------------------------------------
   Check (Gcd (U (0), U (0)) = 0, "gcd(0,0)=0");
   Check (Gcd (U (12), U (18)) = 6, "gcd(12,18)=6");
   Check (Gcd (U (17), U (13)) = 1, "gcd(17,13)=1");
   Check (Gcd (U (100), U (0)) = 100, "gcd(100,0)=100");
   Check (Gcd (U (0), U (42)) = 42, "gcd(0,42)=42");
   Check (Gcd (U (1018), U (38)) = 2, "gcd(1018,38)=2");
   Check (Gcd (U (1019), U (2)) = 1, "gcd(1019,2)=1");

   Check (Mul_Mod (U (7), U (6), U (10)) = 2, "7*6 mod 10 = 2");
   Check (Mul_Mod (U (0), U (5), U (9)) = 0, "0*5 mod 9 = 0");
   Check (Mul_Mod (U (2), U (3), U (1)) = 0, "any mod 1 = 0");
   Check (Mul_Mod (U (2), U (5), U (1019)) = 10, "2*5 mod 1019");
   Check (Mul_Mod (U (123456789), U (987654321), U (1_000_000_007)) =
            259_106_859,
          "large Mul_Mod");
   Expect_Invalid_Mul_Mod ("M=0", U (1), U (1), U (0));

   Check (Sub_Mod (U (5), U (3), U (10)) = 2, "5-3 mod 10");
   Check (Sub_Mod (U (3), U (5), U (10)) = 8, "3-5 mod 10");
   Check (Sub_Mod (U (0), U (1), U (1018)) = 1017, "0-1 mod 1018");
   Check (Sub_Mod (U (416), U (378), U (1018)) = 38, "416-378 mod 1018");
   Check (Sub_Mod (U (681), U (301), U (1018)) = 380, "681-301 mod 1018");

   ------------------------------------------------------------------
   Section ("2. Mod_Pow");
   ------------------------------------------------------------------
   Check (Mod_Pow (U (2), U (10), U (1019)) = 5, "2^10 mod 1019 = 5 (wiki)");
   Check (Mod_Pow (U (2), U (0), U (1019)) = 1, "2^0 = 1");
   Check (Mod_Pow (U (5), U (0), U (23)) = 1, "5^0 mod 23 = 1");
   Check (Mod_Pow (U (5), U (6), U (23)) = 8, "5^6 mod 23 = 8");
   Check (Mod_Pow (U (2), U (8), U (100)) = 56, "2^8 mod 100");
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
   Check (Mul_Mod (U (19), Modular_Inverse (U (19), U (509)), U (509)) = 1,
          "19*inv ≡ 1 mod 509");
   Check (Modular_Inverse (U (1), U (1018)) = 1, "1^{-1} = 1");
   Check (Mul_Mod (U (5), Modular_Inverse (U (5), U (22)), U (22)) = 1,
          "5*inv ≡ 1 mod 22");
   Expect_Invalid_Inverse ("M=1", U (1), U (1));
   Expect_Invalid_Inverse ("M=0", U (1), U (0));
   Expect_Invalid_Inverse ("gcd>1", U (4), U (10));
   Expect_Invalid_Inverse ("gcd>1 (38,1018)", U (38), U (1018));

   ------------------------------------------------------------------
   Section ("4. Verify_Discrete_Log");
   ------------------------------------------------------------------
   Check (Verify_Discrete_Log (U (2), U (5), U (1019), U (10)),
          "verify wiki γ=10");
   Check (not Verify_Discrete_Log (U (2), U (5), U (1019), U (519)),
          "γ=519 is congruence twin, not DLP");
   Check (Verify_Discrete_Log (U (5), U (8), U (23), U (6)),
          "verify 5^6≡8 mod 23");
   Check (Verify_Discrete_Log (U (2), U (1), U (1019), U (0)),
          "verify γ=0 → β=1");
   Check (not Verify_Discrete_Log (U (2), U (5), U (1019), U (11)),
          "wrong γ rejected");
   Check (not Verify_Discrete_Log (U (2), U (5), U (1), U (10)),
          "modulus 1 → False");

   ------------------------------------------------------------------
   Section ("5. Invalid_Argument Discrete_Log_Rho");
   ------------------------------------------------------------------
   Expect_Invalid_DL ("Modulus=0", U (2), U (5), U (0), U (10));
   Expect_Invalid_DL ("Modulus=1", U (2), U (5), U (1), U (10));
   Expect_Invalid_DL ("Order=0", U (2), U (5), U (1019), U (0));
   Expect_Invalid_DL ("Order too big", U (2), U (5), U (1019),
                      Max_Educational_Order + 1);
   Expect_Invalid_DL ("Alpha=0", U (0), U (5), U (1019), U (1018));
   Expect_Invalid_DL ("Beta=0", U (2), U (0), U (1019), U (1018));
   Expect_Invalid_DL ("Alpha≡0", U (1019), U (5), U (1019), U (1018));

   ------------------------------------------------------------------
   Section ("6. Wikipedia example: 2^γ ≡ 5 (mod 1019), n=1018");
   ------------------------------------------------------------------
   G := Discrete_Log_Rho (U (2), U (5), U (1019), U (1018), Seed => 0);
   Check (G = 10, "wiki Discrete_Log_Rho → 10");
   Check (Verify_Discrete_Log (U (2), U (5), U (1019), G),
          "wiki result verifies");
   Check (G < U (1018), "wiki result < Order");

   ------------------------------------------------------------------
   Section ("7. Tiny prime fields / known exponents");
   ------------------------------------------------------------------
   --  (Z/23)*; α=5 has order 22; 5^6 ≡ 8
   G := Discrete_Log_With_Retries (U (5), U (8), U (23), U (22));
   Check (G = 6, "5^γ≡8 mod 23 → γ=6");

   --  5^1 ≡ 5
   G := Discrete_Log_With_Retries (U (5), U (5), U (23), U (22));
   Check (G = 1, "5^γ≡5 mod 23 → γ=1");

   --  5^0 ≡ 1
   G := Discrete_Log_Rho (U (5), U (1), U (23), U (22));
   Check (G = 0, "5^γ≡1 → γ=0");

   --  (Z/101)*; α=2 order 100; 2^8=256≡54
   Check (Mod_Pow (U (2), U (8), U (101)) = 54, "2^8 mod 101 = 54");
   G := Discrete_Log_With_Retries (U (2), U (54), U (101), U (100));
   Check (G = 8, "2^γ≡54 mod 101 → γ=8");

   --  2^10 mod 101 = 14? 1024 rem 101 = 1024-10*101=1024-1010=14
   Check (Mod_Pow (U (2), U (10), U (101)) = 14, "2^10 mod 101 = 14");
   G := Discrete_Log_With_Retries (U (2), U (14), U (101), U (100));
   Check (G = 10, "2^γ≡14 mod 101 → γ=10");

   --  p=47, α=5; order of 5 mod 47: check 5^23?
   --  Use known: 5^4 = 625 ≡ 625-13*47 = 625-611 = 14 mod 47
   Check (Mod_Pow (U (5), U (4), U (47)) = 14, "5^4 mod 47 = 14");
   G := Discrete_Log_With_Retries (U (5), U (14), U (47), U (46));
   Check (G = 4, "5^γ≡14 mod 47 → γ=4");

   --  p=53, α=2, order 52; 2^6=64≡11
   Check (Mod_Pow (U (2), U (6), U (53)) = 11, "2^6 mod 53 = 11");
   G := Discrete_Log_With_Retries (U (2), U (11), U (53), U (52));
   Check (G = 6, "2^γ≡11 mod 53 → γ=6");

   --  p=59, α=2, order 58; 2^5=32
   G := Discrete_Log_With_Retries (U (2), U (32), U (59), U (58));
   Check (G = 5, "2^γ≡32 mod 59 → γ=5");

   --  p=83, α=2, order 82; 2^7=128≡45
   Check (Mod_Pow (U (2), U (7), U (83)) = 45, "2^7 mod 83 = 45");
   G := Discrete_Log_With_Retries (U (2), U (45), U (83), U (82));
   Check (G = 7, "2^γ≡45 mod 83 → γ=7");

   ------------------------------------------------------------------
   Section ("8. Safe-prime style / small subgroup demos");
   ------------------------------------------------------------------
   --  p=23 = 2·11+1; subgroup order 11 generated by g=2^2=4?
   --  Simpler: full group order 22 already covered.
   --  p=47=2·23+1; α=2 may have order 46
   declare
      P : constant U64 := 47;
      A : constant U64 := 3;
      Exp : constant U64 := 9;
      B : constant U64 := Mod_Pow (A, Exp, P);
   begin
      G := Discrete_Log_With_Retries (A, B, P, U (46));
      Check (G = Exp, "3^9 mod 47 recovered");
   end;

   declare
      P : constant U64 := 71;
      A : constant U64 := 7;
      Exp : constant U64 := 12;
      B : constant U64 := Mod_Pow (A, Exp, P);
   begin
      --  order of (Z/71)* is 70
      G := Discrete_Log_With_Retries (A, B, P, U (70));
      Check (G = Exp, "7^12 mod 71 recovered");
   end;

   declare
      P : constant U64 := 107;
      A : constant U64 := 2;
      Exp : constant U64 := 15;
      B : constant U64 := Mod_Pow (A, Exp, P);
   begin
      G := Discrete_Log_With_Retries (A, B, P, U (106));
      Check (G = Exp, "2^15 mod 107 recovered");
   end;

   declare
      P : constant U64 := 167;
      A : constant U64 := 5;
      Exp : constant U64 := 20;
      B : constant U64 := Mod_Pow (A, Exp, P);
   begin
      G := Discrete_Log_With_Retries (A, B, P, U (166));
      Check (G = Exp, "5^20 mod 167 recovered");
   end;

   ------------------------------------------------------------------
   Section ("9. Seed variants / reproducibility");
   ------------------------------------------------------------------
   declare
      G0 : constant U64 :=
        Discrete_Log_Rho (U (2), U (5), U (1019), U (1018), Seed => 0);
      G0b : constant U64 :=
        Discrete_Log_Rho (U (2), U (5), U (1019), U (1018), Seed => 0);
   begin
      Check (G0 = G0b, "same seed → same result");
      Check (G0 = 10, "seed 0 → 10");
   end;

   --  Alternate seeds should still verify when they succeed
   declare
      Ok : Natural := 0;
      Gi : U64;
   begin
      for S in U64 range 0 .. 7 loop
         Gi := Discrete_Log_Rho
           (U (2), U (5), U (1019), U (1018), Seed => S);
         if Gi < U (1018)
           and then Verify_Discrete_Log (U (2), U (5), U (1019), Gi)
         then
            Ok := Ok + 1;
            Check (Gi = 10, "seed" & S'Image & " → verified 10");
         end if;
      end loop;
      Check (Ok >= 1, "at least one of seeds 0..7 succeeds");
   end;

   ------------------------------------------------------------------
   Section ("10. Failure sentinel / Max_Steps");
   ------------------------------------------------------------------
   --  Tiny Max_Steps may return Order (failure) on a nontrivial instance
   G := Discrete_Log_Rho
     (U (2), U (5), U (1019), U (1018), Seed => 0, Max_Steps => 1);
   Check
     (G = U (1018) or else Verify_Discrete_Log (U (2), U (5), U (1019), G),
      "Max_Steps=1 → sentinel or lucky hit");

   --  β not a power of α in a tiny subgroup: α=4 order 11 in (Z/23)*
   --  4^k cycles {1,4,16,18,3,12,2,8,9,13,6}; 5 is not in the list.
   G := Discrete_Log_With_Retries (U (4), U (5), U (23), U (11), 8);
   Check (G = 11, "β outside <α> → failure sentinel Order");

   ------------------------------------------------------------------
   Section ("11. More known discrete logs");
   ------------------------------------------------------------------
   declare
      type Case_Rec is record
         Alpha, Beta, Modulus, Order, Expect : U64;
      end record;
      Cases : constant array (Positive range <>) of Case_Rec :=
        [(3,  13, 17,  8,  4),   -- 3^4=81≡13 mod 17; ord(3)=8 in (Z/17)*
         (3,   3, 17,  8,  1),
         (3,   1, 17,  8,  0),
         (2,   8, 17,  8,  3),   -- 2^3=8; ord(2)=8
         (6,  10, 13, 12,  9),   -- check below
         (2,  16, 19, 18,  4),   -- 2^4=16
         (2,   9, 19, 18,  8),   -- 2^8=256≡9 mod 19 (256-13*19=256-247=9)
         (3,  12, 19, 18,  11)]; -- filled after verify
      Ci : Case_Rec;
      Got : U64;
   begin
      --  Fix / verify a few before asserting
      Check (Mod_Pow (U (3), U (4), U (17)) = 13, "3^4≡13 mod 17");
      Check (Mod_Pow (U (2), U (3), U (17)) = 8, "2^3≡8 mod 17");
      Check (Mod_Pow (U (2), U (4), U (19)) = 16, "2^4≡16 mod 19");
      Check (Mod_Pow (U (2), U (8), U (19)) = 9, "2^8≡9 mod 19");

      --  6^? ≡ 10 mod 13: try find
      declare
         Found : Boolean := False;
      begin
         for E in U64 range 0 .. 11 loop
            if Mod_Pow (U (6), E, U (13)) = 10 then
               Check (True, "6^e≡10 mod 13 exists e=" & E'Image);
               Got := Discrete_Log_With_Retries
                 (U (6), U (10), U (13), U (12));
               Check (Got = E, "rho recovers 6^e≡10 mod 13");
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            Check (False, "6^e≡10 mod 13 exists");
         end if;
      end;

      for I in Cases'Range loop
         Ci := Cases (I);
         --  Skip the 6/10/13 and 3/12/19 placeholders handled specially
         if Ci.Alpha = 6 or else (Ci.Alpha = 3 and then Ci.Modulus = 19) then
            null;
         else
            Got := Discrete_Log_With_Retries
              (Ci.Alpha, Ci.Beta, Ci.Modulus, Ci.Order);
            Check
              (Got = Ci.Expect,
               "case" & I'Image & " expect" & Ci.Expect'Image &
               " got" & Got'Image);
         end if;
      end loop;

      --  3^e ≡ 12 mod 19
      declare
         Found_E : U64 := 18;
      begin
         for E in U64 range 0 .. 17 loop
            if Mod_Pow (U (3), E, U (19)) = 12 then
               Found_E := E;
               exit;
            end if;
         end loop;
         Check (Found_E < 18, "3^e≡12 mod 19 exists");
         Got := Discrete_Log_With_Retries
           (U (3), U (12), U (19), U (18));
         Check (Got = Found_E, "rho recovers 3^e≡12 mod 19");
      end;
   end;

   ------------------------------------------------------------------
   Section ("12. Bounds / constants");
   ------------------------------------------------------------------
   Check (Max_Educational_Order = U (2_000_000), "Max_Educational_Order");
   Check (Nat (Default_Max_Steps) = Nat (200_000), "Default_Max_Steps");
   Check (U64'Last = U (2 ** 64 - 1), "U64 full range");

   --  Quick identity: Alpha^Order ≡ 1 when Order = p−1 (Fermat) for prime p
   Check (Mod_Pow (U (2), U (1018), U (1019)) = 1, "2^{1018}≡1 mod 1019");
   Check (Mod_Pow (U (5), U (22), U (23)) = 1, "5^{22}≡1 mod 23");
   Check (Mod_Pow (U (2), U (100), U (101)) = 1, "2^{100}≡1 mod 101");

   ------------------------------------------------------------------
   Section ("13. Additional random-ish classroom pairs");
   ------------------------------------------------------------------
   declare
      type Pair is record
         P, Alpha, Exp : U64;
      end record;
      Ps : constant array (Positive range <>) of Pair :=
        [(29, 2, 7),
         (31, 3, 5),
         (37, 2, 11),
         (41, 6, 8),
         (43, 3, 10),
         (61, 10, 7),
         (67, 2, 13),
         (73, 5, 9),
         (79, 3, 14),
         (89, 3, 6),
         (97, 5, 11)];
      Beta, Ord, Got : U64;
   begin
      for I in Ps'Range loop
         Ord  := Ps (I).P - 1;
         Beta := Mod_Pow (Ps (I).Alpha, Ps (I).Exp, Ps (I).P);
         Got  := Discrete_Log_With_Retries
           (Ps (I).Alpha, Beta, Ps (I).P, Ord);
         Check
           (Got = Ps (I).Exp,
            "p=" & Ps (I).P'Image & " α^" & Ps (I).Exp'Image & " recovered");
      end loop;
   end;

   ------------------------------------------------------------------
   --  Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");
   if Fail_Count > 0 or else Pass_Count < 80 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
