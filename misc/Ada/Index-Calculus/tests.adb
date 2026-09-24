--  Standalone test suite for Index_Calculus (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Index_Calculus; use Index_Calculus;

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

   procedure Expect_Invalid_Smooth (Label : String; N : U64) is
      Raised : Boolean := False;
      Base   : constant Factor_Base := [2, 3, 5];
   begin
      begin
         declare
            Unused : constant Boolean := Is_B_Smooth (N, Base);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Is_B_Smooth: " & Label);
   end Expect_Invalid_Smooth;

   procedure Expect_Invalid_DL
     (Label                         : String;
      Alpha, Beta, Modulus, Order   : U64)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 :=
              Discrete_Log_Index_Calculus (Alpha, Beta, Modulus, Order);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Discrete_Log: " & Label);
   end Expect_Invalid_DL;

   function DL
     (Alpha, Beta, Modulus, Order : U64;
      Smoothness                  : U64 := 20;
      Seed                        : U64 := 1) return U64
   is
   begin
      return Discrete_Log_Index_Calculus
        (Alpha, Beta, Modulus, Order, Smoothness, Seed);
   end DL;

   G : U64;

begin
   Ada.Text_IO.Put_Line ("Index_Calculus — Ada 2023 test suite");

   ------------------------------------------------------------------
   Section ("1. Gcd / Mul_Mod / Sub_Mod / Floor_Sqrt");
   ------------------------------------------------------------------
   Check (Gcd (U (0), U (0)) = 0, "gcd(0,0)=0");
   Check (Gcd (U (12), U (18)) = 6, "gcd(12,18)=6");
   Check (Gcd (U (17), U (13)) = 1, "gcd(17,13)=1");
   Check (Gcd (U (100), U (0)) = 100, "gcd(100,0)=100");
   Check (Gcd (U (0), U (42)) = 42, "gcd(0,42)=42");
   Check (Gcd (U (40), U (25)) = 5, "gcd(40,25)=5");

   Check (Mul_Mod (U (7), U (6), U (10)) = 2, "7*6 mod 10 = 2");
   Check (Mul_Mod (U (0), U (5), U (9)) = 0, "0*5 mod 9 = 0");
   Check (Mul_Mod (U (2), U (3), U (1)) = 0, "any mod 1 = 0");
   Check (Mul_Mod (U (6), U (7), U (41)) = 1, "6*7 mod 41 = 1");
   Check (Mul_Mod (U (123456789), U (987654321), U (1_000_000_007)) =
            259_106_859,
          "big Mul_Mod");

   Check (Sub_Mod (U (3), U (5), U (10)) = 8, "3-5 mod 10 = 8");
   Check (Sub_Mod (U (5), U (3), U (10)) = 2, "5-3 mod 10 = 2");
   Check (Sub_Mod (U (0), U (1), U (7)) = 6, "0-1 mod 7 = 6");

   Check (Floor_Sqrt (U (0)) = 0, "sqrt(0)=0");
   Check (Floor_Sqrt (U (1)) = 1, "sqrt(1)=1");
   Check (Floor_Sqrt (U (15)) = 3, "sqrt(15)=3");
   Check (Floor_Sqrt (U (16)) = 4, "sqrt(16)=4");
   Check (Floor_Sqrt (U (100)) = 10, "sqrt(100)=10");

   ------------------------------------------------------------------
   Section ("2. Mod_Pow / Modular_Inverse / Verify");
   ------------------------------------------------------------------
   Check (Mod_Pow (U (2), U (10), U (1000)) = 24, "2^10 mod 1000");
   Check (Mod_Pow (U (6), U (3), U (41)) = 11, "6^3 mod 41 = 11");
   Check (Mod_Pow (U (5), U (6), U (23)) = 8, "5^6 mod 23 = 8");
   Check (Mod_Pow (U (2), U (0), U (19)) = 1, "2^0 mod 19 = 1");
   Check (Mod_Pow (U (7), U (1), U (13)) = 7, "7^1 mod 13 = 7");

   Check (Modular_Inverse (U (3), U (10)) = 7, "inv(3) mod 10 = 7");
   Check (Modular_Inverse (U (1), U (17)) = 1, "inv(1) mod 17 = 1");
   Check (Mul_Mod (U (5), Modular_Inverse (U (5), U (22)), U (22)) = 1,
          "5*inv(5) mod 22 = 1");

   Check (Verify_Discrete_Log (U (6), U (11), U (41), U (3)),
          "verify 6^3=11 mod 41");
   Check (not Verify_Discrete_Log (U (6), U (11), U (41), U (4)),
          "verify reject wrong log");
   Check (Verify_Discrete_Log (U (5), U (1), U (23), U (0)),
          "verify beta=1 log=0");
   Check (not Verify_Discrete_Log (U (2), U (3), U (1), U (0)),
          "verify rejects modulus 1");

   ------------------------------------------------------------------
   Section ("3. Is_Prime_Trial / Primes_Up_To");
   ------------------------------------------------------------------
   Check (not Is_Prime_Trial (U (0)), "0 not prime");
   Check (not Is_Prime_Trial (U (1)), "1 not prime");
   Check (Is_Prime_Trial (U (2)), "2 prime");
   Check (Is_Prime_Trial (U (3)), "3 prime");
   Check (not Is_Prime_Trial (U (4)), "4 not prime");
   Check (Is_Prime_Trial (U (41)), "41 prime");
   Check (not Is_Prime_Trial (U (91)), "91=7*13 not prime");
   Check (Is_Prime_Trial (U (97)), "97 prime");

   declare
      P5  : constant Factor_Base := Primes_Up_To (U (5));
      P1  : constant Factor_Base := Primes_Up_To (U (1));
      P20 : constant Factor_Base := Primes_Up_To (U (20));
   begin
      Check (P5'Length = 3, "primes <=5 : 3");
      Check (P5 (1) = 2 and then P5 (2) = 3 and then P5 (3) = 5,
             "primes <=5 = 2,3,5");
      Check (P1'Length = 0, "primes <=1 empty");
      Check (P20'Length = 8, "primes <=20 : 8");
      Check (P20 (P20'Last) = 19, "last prime <=20 is 19");
   end;

   ------------------------------------------------------------------
   Section ("4. Smoothness");
   ------------------------------------------------------------------
   declare
      FB : constant Factor_Base := [2, 3, 5, 7];
   begin
      Check (Is_B_Smooth (U (1), FB), "1 is smooth");
      Check (Is_B_Smooth (U (720), FB), "720=2^4*3^2*5 smooth");
      Check (Is_B_Smooth (U (14), FB), "14=2*7 smooth");
      Check (not Is_B_Smooth (U (11), FB), "11 not in base");
      Check (not Is_B_Smooth (U (22), FB), "22=2*11 not smooth");

      declare
         E : constant Exponent_Vector := Smooth_Exponents (U (720), FB);
      begin
         Check (E (1) = 4 and then E (2) = 2 and then E (3) = 1
                  and then E (4) = 0,
                "exponents of 720");
      end;

      declare
         E2 : constant Exponent_Vector := Smooth_Exponents (U (1), FB);
         All_Z : Boolean := True;
      begin
         for X of E2 loop
            if X /= 0 then
               All_Z := False;
            end if;
         end loop;
         Check (All_Z, "exponents of 1 all zero");
      end;
   end;

   Expect_Invalid_Smooth ("N=0", U (0));

   ------------------------------------------------------------------
   Section ("5. Collect_Relations / Solve_Factor_Base_Logs");
   ------------------------------------------------------------------
   --  Classic: g=6, q=41, order=40, base={2,3,5}
   declare
      FB   : constant Factor_Base := [2, 3, 5];
      Rels : constant Relation_List :=
        Collect_Relations
          (Generator => 6, Modulus => 41, Order => 40,
           Base => FB, Seed => 1, Max_Tries => 5_000);
      Logs : constant Log_Vector :=
        Solve_Factor_Base_Logs
          (Generator => 6, Modulus => 41, Order => 40,
           Base => FB, Relations => Rels);
   begin
      Check (Rels'Length >= FB'Length, "enough relations for {2,3,5} mod 41");
      Check (Logs'Length = FB'Length, "solved base logs mod 41");
      if Logs'Length = FB'Length then
         Check (Verify_Discrete_Log (U (6), U (2), U (41), Logs (1)),
                "log_6(2) verified");
         Check (Verify_Discrete_Log (U (6), U (3), U (41), Logs (2)),
                "log_6(3) verified");
         Check (Verify_Discrete_Log (U (6), U (5), U (41), Logs (3)),
                "log_6(5) verified");
      end if;
   end;

   ------------------------------------------------------------------
   Section ("6. Discrete_Log_Index_Calculus — known instances");
   ------------------------------------------------------------------
   G := DL (6, 11, 41, 40, Smoothness => 5);
   Check (G = 3 and then Verify_Discrete_Log (U (6), U (11), U (41), G),
          "6^x=11 mod 41 -> 3");

   G := DL (6, 36, 41, 40, Smoothness => 5);
   Check (G = 2 and then Verify_Discrete_Log (U (6), U (36), U (41), G),
          "6^x=36 mod 41 -> 2");

   G := DL (3, 27, 43, 42, Smoothness => 5);
   Check (G = 3 and then Verify_Discrete_Log (U (3), U (27), U (43), G),
          "3^x=27 mod 43 -> 3");

   G := DL (5, 31, 47, 46, Smoothness => 7);
   Check (G = 3 and then Verify_Discrete_Log (U (5), U (31), U (47), G),
          "5^x=31 mod 47 -> 3");

   G := DL (7, 59, 71, 70, Smoothness => 7);
   Check (G = 3 and then Verify_Discrete_Log (U (7), U (59), U (71), G),
          "7^x=59 mod 71 -> 3");

   G := DL (5, 52, 73, 72, Smoothness => 5);
   Check (G = 3 and then Verify_Discrete_Log (U (5), U (52), U (73), G),
          "5^x=52 mod 73 -> 3");

   G := DL (2, 5, 29, 28, Smoothness => 11);
   Check (G = 22 and then Verify_Discrete_Log (U (2), U (5), U (29), G),
          "2^x=5 mod 29 -> 22");

   G := DL (5, 8, 23, 22, Smoothness => 11);
   Check (G = 6 and then Verify_Discrete_Log (U (5), U (8), U (23), G),
          "5^x=8 mod 23 -> 6");

   G := DL (2, 13, 19, 18, Smoothness => 7);
   Check (G = 5 and then Verify_Discrete_Log (U (2), U (13), U (19), G),
          "2^x=13 mod 19 -> 5");

   G := DL (3, 13, 17, 16, Smoothness => 7);
   Check (G = 4 and then Verify_Discrete_Log (U (3), U (13), U (17), G),
          "3^x=13 mod 17 -> 4");

   ------------------------------------------------------------------
   Section ("7. Trivial / more classroom fields");
   ------------------------------------------------------------------
   G := DL (2, 1, 19, 18);
   Check (G = 0, "beta=1 -> log 0");

   G := DL (5, 5, 23, 22);
   Check (G = 1, "beta=alpha -> log 1");

   G := DL (6, Mod_Pow (6, 7, 41), 41, 40, Smoothness => 7);
   Check (G = 7 and then Verify_Discrete_Log (U (6), Mod_Pow (6, 7, 41), U (41), G),
          "6^7 recovered mod 41");

   G := DL (6, Mod_Pow (6, 15, 41), 41, 40, Smoothness => 7);
   Check (G = 15 and then
            Verify_Discrete_Log (U (6), Mod_Pow (6, 15, 41), U (41), G),
          "6^15 recovered mod 41");

   G := DL (3, Mod_Pow (3, 11, 43), 43, 42, Smoothness => 7);
   Check (G = 11 and then
            Verify_Discrete_Log (U (3), Mod_Pow (3, 11, 43), U (43), G),
          "3^11 recovered mod 43");

   G := DL (5, Mod_Pow (5, 9, 47), 47, 46, Smoothness => 11);
   Check (G = 9 and then
            Verify_Discrete_Log (U (5), Mod_Pow (5, 9, 47), U (47), G),
          "5^9 recovered mod 47");

   G := DL (19, Mod_Pow (19, 3, 191), 191, 190, Smoothness => 11);
   Check (G = 3 and then
            Verify_Discrete_Log (U (19), Mod_Pow (19, 3, 191), U (191), G),
          "19^3 recovered mod 191");

   G := DL (6, Mod_Pow (6, 17, 151), 151, 150, Smoothness => 11);
   Check (G = 17 and then
            Verify_Discrete_Log (U (6), Mod_Pow (6, 17, 151), U (151), G),
          "6^17 recovered mod 151");

   ------------------------------------------------------------------
   Section ("8. Failure sentinel / Invalid_Argument");
   ------------------------------------------------------------------
   --  Empty-ish base via Smoothness < 2 after filter → sentinel Order
   --  (Smoothness 0 → Primes_Up_To empty → Order). Bound escalation may
   --  still succeed; use a modulus where Alpha is not a generator of a
   --  subgroup containing Beta.
   G := DL (2, 3, 17, 8, Smoothness => 5);
   --  Order 8 is wrong for <2> in F_17 (true order is 8 actually...
   --  2 is not prim root; ord(2)=8. 3 may not be in <2>.
   Check (G = 8 or else Verify_Discrete_Log (U (2), U (3), U (17), G),
          "non-member or lucky hit: sentinel or verified");

   --  If Beta not in <Alpha>, expect sentinel.
   --  In F_41, <6> is full group; use Alpha with small order.
   --  16 has order 5 in F_41? 16^2=10, 16^4=18, 16^5=1? Let's use
   --  Alpha=16, Order=5, Beta=3 (likely outside).
   G := DL (16, 3, 41, 5, Smoothness => 5);
   Check (G = 5 or else Verify_Discrete_Log (U (16), U (3), U (41), G),
          "outside subgroup -> sentinel (or verified if inside)");

   Expect_Invalid_Mul_Mod ("M=0", U (1), U (2), U (0));
   Expect_Invalid_Mod_Pow ("M=0", U (2), U (3), U (0));
   Expect_Invalid_Inverse ("M=1", U (1), U (1));
   Expect_Invalid_Inverse ("gcd>1", U (2), U (4));
   Expect_Invalid_DL ("modulus 0", U (2), U (3), U (0), U (1));
   Expect_Invalid_DL ("modulus 1", U (2), U (3), U (1), U (1));
   Expect_Invalid_DL ("order 0", U (2), U (3), U (17), U (0));
   Expect_Invalid_DL ("alpha 0", U (17), U (3), U (17), U (16));
   Expect_Invalid_DL ("beta 0", U (2), U (17), U (17), U (16));
   Expect_Invalid_DL ("modulus too large",
                      U (2), U (3), Max_Educational_Modulus + 1, U (10));

   ------------------------------------------------------------------
   Section ("9. Seed reproducibility / helpers edge");
   ------------------------------------------------------------------
   declare
      G1 : constant U64 := DL (6, 11, 41, 40, 5, Seed => 1);
      G2 : constant U64 := DL (6, 11, 41, 40, 5, Seed => 1);
      G3 : constant U64 := DL (6, 11, 41, 40, 5, Seed => 99);
   begin
      Check (G1 = G2, "same seed -> same result");
      Check (G1 = 3, "seed 1 recovers 3");
      Check (G3 = 3 or else G3 = 40,
             "other seed recovers or sentinel");
      if G3 < 40 then
         Check (Verify_Discrete_Log (U (6), U (11), U (41), G3),
                "seed 99 verified");
      else
         Check (G3 = U (40), "seed 99 sentinel tolerated");
      end if;
   end;

   Check (Nat (Max_Factor_Base) = 32, "Max_Factor_Base=32");
   Check (Nat (Max_Relations) = 96, "Max_Relations=96");
   Check (Max_Educational_Modulus = U (50_000), "Max_Educational_Modulus");

   declare
      P20 : constant Factor_Base := Primes_Up_To (U (20));
   begin
      Check (P20'Length >= 8, "primes<=20 length");
   end;

   ------------------------------------------------------------------
   Section ("10. Extra recoveries");
   ------------------------------------------------------------------
   for Exp in U64 range 1 .. 12 loop
      declare
         H : constant U64 := Mod_Pow (6, Exp, 41);
         X : constant U64 := DL (6, H, 41, 40, Smoothness => 7);
      begin
         Check (X = Exp and then Verify_Discrete_Log (U (6), H, U (41), X),
                "mod 41 recover exp");
      end;
   end loop;

   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line (
     "Result:" & Natural'Image (Pass_Count) & " PASS,"
     & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
