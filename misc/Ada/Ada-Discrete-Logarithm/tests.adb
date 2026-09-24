--  Standalone test suite for Discrete_Logarithm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Discrete_Logarithm; use Discrete_Logarithm;

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

   procedure Expect_Invalid_DL
     (Label : String; Alpha, Beta, Modulus, Order : U64)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 :=
              Discrete_Log (Alpha, Beta, Modulus, Order);
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

   procedure Expect_Invalid_Trial
     (Label : String; Alpha, Beta, Modulus, Order : U64)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 :=
              Discrete_Log_Trial (Alpha, Beta, Modulus, Order);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Trial: " & Label);
   end Expect_Invalid_Trial;

   procedure Expect_DL_Trial
     (Label : String; Alpha, Beta, Modulus, Order, Expected : U64)
   is
      G : constant U64 :=
        Discrete_Log_Trial (Alpha, Beta, Modulus, Order);
   begin
      Check
        (G = Expected
           and then Verify_Discrete_Log (Alpha, Beta, Modulus, G),
         Label);
   end Expect_DL_Trial;

   procedure Expect_DL_BSGS
     (Label : String; Alpha, Beta, Modulus, Order, Expected : U64)
   is
      G : constant U64 :=
        Discrete_Log_BSGS (Alpha, Beta, Modulus, Order);
   begin
      Check
        (G = Expected
           and then Verify_Discrete_Log (Alpha, Beta, Modulus, G),
         Label);
   end Expect_DL_BSGS;

   procedure Expect_DL_PH
     (Label : String; Alpha, Beta, Modulus, Order, Expected : U64)
   is
      G : constant U64 :=
        Discrete_Log_Pohlig_Hellman (Alpha, Beta, Modulus, Order);
   begin
      Check
        (G = Expected
           and then Verify_Discrete_Log (Alpha, Beta, Modulus, G),
         Label);
   end Expect_DL_PH;

   procedure Expect_DL_Driver
     (Label : String; Alpha, Beta, Modulus, Order, Expected : U64)
   is
      G : constant U64 := Discrete_Log (Alpha, Beta, Modulus, Order);
   begin
      Check
        (G = Expected
           and then Verify_Discrete_Log (Alpha, Beta, Modulus, G),
         Label);
   end Expect_DL_Driver;

   procedure Expect_Failure_Trial
     (Label : String; Alpha, Beta, Modulus, Order : U64)
   is
      G : constant U64 :=
        Discrete_Log_Trial (Alpha, Beta, Modulus, Order);
   begin
      Check (G = Order, Label);
   end Expect_Failure_Trial;

   procedure Expect_Failure_BSGS
     (Label : String; Alpha, Beta, Modulus, Order : U64)
   is
      G : constant U64 :=
        Discrete_Log_BSGS (Alpha, Beta, Modulus, Order);
   begin
      Check (G = Order, Label);
   end Expect_Failure_BSGS;

begin
   Ada.Text_IO.Put_Line ("Discrete_Logarithm — Ada 2023 test suite");

   ------------------------------------------------------------------
   Section ("1. Mul_Mod");
   ------------------------------------------------------------------
   Check (Mul_Mod (U (7), U (6), U (10)) = 2, "7*6 mod 10 = 2");
   Check (Mul_Mod (U (0), U (5), U (9)) = 0, "0*5 mod 9 = 0");
   Check (Mul_Mod (U (2), U (3), U (1)) = 0, "any mod 1 = 0");
   Check (Mul_Mod (U (2), U (5), U (1019)) = 10, "2*5 mod 1019");
   Check (Mul_Mod (U (123456789), U (987654321), U (1_000_000_007)) =
            259_106_859,
          "large Mul_Mod");
   Check (Mul_Mod (U (3), U (5), U (11)) = 4, "3*5 mod 11 = 4");
   Check (Mul_Mod (U (10), U (10), U (7)) = 2, "10*10 mod 7 = 2");
   Expect_Invalid_Mul_Mod ("M=0", U (1), U (1), U (0));

   ------------------------------------------------------------------
   Section ("2. Mod_Pow");
   ------------------------------------------------------------------
   Check (Mod_Pow (U (2), U (10), U (1019)) = 5, "2^10 mod 1019 = 5");
   Check (Mod_Pow (U (2), U (0), U (1019)) = 1, "2^0 = 1");
   Check (Mod_Pow (U (5), U (0), U (23)) = 1, "5^0 mod 23 = 1");
   Check (Mod_Pow (U (5), U (6), U (23)) = 8, "5^6 mod 23 = 8");
   Check (Mod_Pow (U (2), U (8), U (101)) = 54, "2^8 mod 101 = 54");
   Check (Mod_Pow (U (3), U (5), U (13)) = 9, "3^5 mod 13 = 9");
   Check (Mod_Pow (U (7), U (1), U (11)) = 7, "7^1 mod 11");
   Check (Mod_Pow (U (2), U (100), U (101)) = 1, "2^100 mod 101 (Fermat)");
   Check (Mod_Pow (U (3), U (4), U (13)) = 3, "3^4 mod 13 = 3");
   Check (Mod_Pow (U (2), U (16), U (19)) = 5, "2^16 mod 19 = 5");
   Expect_Invalid_Mod_Pow ("M=0", U (2), U (3), U (0));
   Check (Mod_Pow (U (9), U (0), U (1)) = 0, "any^e mod 1 = 0");

   ------------------------------------------------------------------
   Section ("3. Gcd / Modular_Inverse");
   ------------------------------------------------------------------
   Check (Gcd (U (0), U (0)) = 0, "gcd(0,0)=0");
   Check (Gcd (U (12), U (8)) = 4, "gcd(12,8)=4");
   Check (Gcd (U (17), U (13)) = 1, "gcd(17,13)=1");
   Check (Gcd (U (100), U (0)) = 100, "gcd(100,0)=100");
   Check (Gcd (U (0), U (42)) = 42, "gcd(0,42)=42");
   Check (Modular_Inverse (U (3), U (10)) = 7, "3^{-1} mod 10 = 7");
   Check (Modular_Inverse (U (7), U (10)) = 3, "7^{-1} mod 10 = 3");
   Check (Mul_Mod (U (19), Modular_Inverse (U (19), U (509)), U (509)) = 1,
          "19*inv ≡ 1 mod 509");
   Check (Modular_Inverse (U (1), U (1018)) = 1, "1^{-1} = 1");
   Check (Mul_Mod (U (5), Modular_Inverse (U (5), U (22)), U (22)) = 1,
          "5*inv ≡ 1 mod 22");
   Check (Mul_Mod (U (2), Modular_Inverse (U (2), U (101)), U (101)) = 1,
          "2*inv ≡ 1 mod 101");
   Expect_Invalid_Inverse ("M=1", U (1), U (1));
   Expect_Invalid_Inverse ("M=0", U (1), U (0));
   Expect_Invalid_Inverse ("gcd>1", U (4), U (10));
   Expect_Invalid_Inverse ("gcd>1 (6,9)", U (6), U (9));

   ------------------------------------------------------------------
   Section ("4. Floor_Sqrt / Ceil_Sqrt");
   ------------------------------------------------------------------
   Check (Floor_Sqrt (U (0)) = 0, "floor_sqrt(0)=0");
   Check (Floor_Sqrt (U (1)) = 1, "floor_sqrt(1)=1");
   Check (Floor_Sqrt (U (2)) = 1, "floor_sqrt(2)=1");
   Check (Floor_Sqrt (U (3)) = 1, "floor_sqrt(3)=1");
   Check (Floor_Sqrt (U (4)) = 2, "floor_sqrt(4)=2");
   Check (Floor_Sqrt (U (8)) = 2, "floor_sqrt(8)=2");
   Check (Floor_Sqrt (U (9)) = 3, "floor_sqrt(9)=3");
   Check (Floor_Sqrt (U (15)) = 3, "floor_sqrt(15)=3");
   Check (Floor_Sqrt (U (16)) = 4, "floor_sqrt(16)=4");
   Check (Floor_Sqrt (U (100)) = 10, "floor_sqrt(100)=10");
   Check (Floor_Sqrt (U (1018)) = 31, "floor_sqrt(1018)=31");
   Check (Floor_Sqrt (U (2_000_000)) = 1414, "floor_sqrt(2e6)=1414");

   Check (Ceil_Sqrt (U (0)) = 0, "ceil_sqrt(0)=0");
   Check (Ceil_Sqrt (U (1)) = 1, "ceil_sqrt(1)=1");
   Check (Ceil_Sqrt (U (2)) = 2, "ceil_sqrt(2)=2");
   Check (Ceil_Sqrt (U (3)) = 2, "ceil_sqrt(3)=2");
   Check (Ceil_Sqrt (U (4)) = 2, "ceil_sqrt(4)=2");
   Check (Ceil_Sqrt (U (5)) = 3, "ceil_sqrt(5)=3");
   Check (Ceil_Sqrt (U (9)) = 3, "ceil_sqrt(9)=3");
   Check (Ceil_Sqrt (U (10)) = 4, "ceil_sqrt(10)=4");
   Check (Ceil_Sqrt (U (22)) = 5, "ceil_sqrt(22)=5");
   Check (Ceil_Sqrt (U (100)) = 10, "ceil_sqrt(100)=10");
   Check (Ceil_Sqrt (U (1018)) = 32, "ceil_sqrt(1018)=32");
   Check (Ceil_Sqrt (U (2_000_000)) = 1415, "ceil_sqrt(2e6)=1415");

   ------------------------------------------------------------------
   Section ("5. Verify_Discrete_Log");
   ------------------------------------------------------------------
   Check (Verify_Discrete_Log (U (2), U (5), U (1019), U (10)),
          "verify 2^10≡5 mod 1019");
   Check (not Verify_Discrete_Log (U (2), U (5), U (1019), U (11)),
          "2^11 ≢ 5 mod 1019");
   Check (Verify_Discrete_Log (U (5), U (8), U (23), U (6)),
          "verify 5^6≡8 mod 23");
   Check (Verify_Discrete_Log (U (2), U (1), U (1019), U (0)),
          "verify γ=0 → β=1");
   Check (Verify_Discrete_Log (U (2), U (54), U (101), U (8)),
          "verify 2^8≡54 mod 101");
   Check (not Verify_Discrete_Log (U (2), U (5), U (1), U (10)),
          "modulus≤1 → False");
   Check (not Verify_Discrete_Log (U (3), U (9), U (13), U (1)),
          "3^1 ≢ 9 mod 13");

   ------------------------------------------------------------------
   Section ("6. Factorize_Trial");
   ------------------------------------------------------------------
   declare
      F : constant Factor_Array := Factorize_Trial (U (12));
   begin
      Check (F'Length = 2
               and then F (F'First).Prime = 2
               and then F (F'First).Exp = 2
               and then F (F'First + 1).Prime = 3
               and then F (F'First + 1).Exp = 1,
             "12 = 2^2 * 3");
   end;
   declare
      F : constant Factor_Array := Factorize_Trial (U (1));
   begin
      Check (F'Length = 0, "1 → empty factors");
   end;
   declare
      F : constant Factor_Array := Factorize_Trial (U (17));
   begin
      Check (F'Length = 1
               and then F (F'First).Prime = 17
               and then F (F'First).Exp = 1,
             "17 = 17^1");
   end;
   declare
      F : constant Factor_Array := Factorize_Trial (U (60));
   begin
      Check (F'Length = 3
               and then F (F'First).Prime = 2
               and then F (F'First).Exp = 2
               and then F (F'First + 1).Prime = 3
               and then F (F'First + 2).Prime = 5,
             "60 = 2^2 * 3 * 5");
   end;

   ------------------------------------------------------------------
   Section ("7. Discrete_Log_Trial");
   ------------------------------------------------------------------
   Expect_DL_Trial ("trial 5^γ≡8 mod 23 → 6",
                    U (5), U (8), U (23), U (22), U (6));
   Expect_DL_Trial ("trial 2^γ≡8 mod 13 → 3",
                    U (2), U (8), U (13), U (12), U (3));
   Expect_DL_Trial ("trial 3^γ≡9 mod 13 → 2",
                    U (3), U (9), U (13), U (12), U (2));
   Expect_DL_Trial ("trial 2^γ≡3 mod 11 → 8",
                    U (2), U (3), U (11), U (10), U (8));
   Expect_DL_Trial ("trial 3^γ≡6 mod 7 → 3",
                    U (3), U (6), U (7), U (6), U (3));
   Expect_DL_Trial ("trial β=1 → γ=0",
                    U (5), U (1), U (23), U (22), U (0));
   Expect_DL_Trial ("trial α=β → γ=1",
                    U (5), U (5), U (23), U (22), U (1));
   Expect_DL_Trial ("trial 2^γ≡4 mod 5 → 2",
                    U (2), U (4), U (5), U (4), U (2));
   Expect_DL_Trial ("trial 5^γ≡9 mod 17 → 10",
                    U (5), U (9), U (17), U (16), U (10));
   Expect_DL_Trial ("trial 2^γ≡5 mod 19 → 16",
                    U (2), U (5), U (19), U (18), U (16));
   Expect_Failure_Trial ("trial 4^γ≢2 mod 11 (ord 5)",
                         U (4), U (2), U (11), U (5));
   Expect_Invalid_Trial ("trial Modulus=1",
                         U (2), U (3), U (1), U (1));
   Expect_Invalid_Trial ("trial Order=0",
                         U (2), U (3), U (11), U (0));

   ------------------------------------------------------------------
   Section ("8. Discrete_Log_BSGS — verified instances");
   ------------------------------------------------------------------
   Expect_DL_BSGS ("BSGS 2^γ≡5 mod 1019 → 10",
                   U (2), U (5), U (1019), U (1018), U (10));
   Expect_DL_BSGS ("BSGS 5^γ≡8 mod 23 → 6",
                   U (5), U (8), U (23), U (22), U (6));
   Expect_DL_BSGS ("BSGS 2^γ≡54 mod 101 → 8",
                   U (2), U (54), U (101), U (100), U (8));
   Expect_DL_BSGS ("BSGS 3^γ≡9 mod 13 → 2",
                   U (3), U (9), U (13), U (12), U (2));
   Expect_DL_BSGS ("BSGS 2^γ≡8 mod 13 → 3",
                   U (2), U (8), U (13), U (12), U (3));
   Expect_DL_BSGS ("BSGS 11^γ≡510 mod 1009 → 123",
                   U (11), U (510), U (1009), U (1008), U (123));
   Expect_DL_BSGS ("BSGS 5^γ≡356 mod 503 → 77",
                   U (5), U (356), U (503), U (502), U (77));
   Expect_DL_BSGS ("BSGS 2^γ≡553 mod 1019 → 77",
                   U (2), U (553), U (1019), U (1018), U (77));
   Expect_DL_BSGS ("BSGS 2^γ≡16 mod 31 → 4",
                   U (2), U (16), U (31), U (30), U (4));
   Expect_DL_BSGS ("BSGS 2^γ≡9 mod 29 → 10",
                   U (2), U (9), U (29), U (28), U (10));
   Expect_DL_BSGS ("BSGS 5^γ≡24 mod 43 → 10",
                   U (5), U (24), U (43), U (42), U (10));
   Expect_DL_BSGS ("BSGS 5^γ≡17 mod 47 → 16",
                   U (5), U (17), U (47), U (46), U (16));
   Expect_DL_BSGS ("BSGS 2^γ≡25 mod 37 → 10",
                   U (2), U (25), U (37), U (36), U (10));
   Expect_DL_BSGS ("BSGS 6^γ≡32 mod 41 → 10",
                   U (6), U (32), U (41), U (40), U (10));
   Expect_DL_BSGS ("BSGS β=1 → 0",
                   U (2), U (1), U (1019), U (1018), U (0));
   Expect_DL_BSGS ("BSGS α=β → 1",
                   U (2), U (2), U (101), U (100), U (1));
   Expect_DL_BSGS ("BSGS 2^γ≡17 mod 53 → 10",
                   U (2), U (17), U (53), U (52), U (10));
   Expect_DL_BSGS ("BSGS 2^γ≡21 mod 59 → 10",
                   U (2), U (21), U (59), U (58), U (10));
   Expect_DL_BSGS ("BSGS 10^γ≡14 mod 61 → 10",
                   U (10), U (14), U (61), U (60), U (10));
   Expect_DL_BSGS ("BSGS 2^γ≡19 mod 67 → 10",
                   U (2), U (19), U (67), U (66), U (10));
   Expect_DL_BSGS ("BSGS 7^γ≡45 mod 71 → 10",
                   U (7), U (45), U (71), U (70), U (10));
   Expect_DL_BSGS ("BSGS 5^γ≡50 mod 73 → 10",
                   U (5), U (50), U (73), U (72), U (10));
   Expect_DL_BSGS ("BSGS 3^γ≡36 mod 79 → 10",
                   U (3), U (36), U (79), U (78), U (10));
   Expect_DL_BSGS ("BSGS 2^γ≡28 mod 83 → 10",
                   U (2), U (28), U (83), U (82), U (10));
   Expect_DL_BSGS ("BSGS 3^γ≡42 mod 89 → 10",
                   U (3), U (42), U (89), U (88), U (10));
   Expect_DL_BSGS ("BSGS 5^γ≡53 mod 97 → 10",
                   U (5), U (53), U (97), U (96), U (10));
   Expect_Failure_BSGS ("BSGS 4^γ≢2 mod 11 (ord 5)",
                        U (4), U (2), U (11), U (5));
   Expect_Failure_BSGS ("BSGS 9^γ≢2 mod 13 (ord 3)",
                        U (9), U (2), U (13), U (3));

   ------------------------------------------------------------------
   Section ("9. Discrete_Log_Pohlig_Hellman (smooth order)");
   ------------------------------------------------------------------
   --  Order 22 = 2*11, smooth
   Expect_DL_PH ("PH 5^γ≡8 mod 23, n=22 → 6",
                 U (5), U (8), U (23), U (22), U (6));
   Expect_DL_PH ("PH 5^γ≡1 mod 23 → 0",
                 U (5), U (1), U (23), U (22), U (0));
   Expect_DL_PH ("PH 5^γ≡5 mod 23 → 1",
                 U (5), U (5), U (23), U (22), U (1));
   --  Order 12 = 2^2*3
   Expect_DL_PH ("PH 2^γ≡8 mod 13, n=12 → 3",
                 U (2), U (8), U (13), U (12), U (3));
   Expect_DL_PH ("PH 3^γ≡9 mod 13, n=12 → 2",
                 U (3), U (9), U (13), U (12), U (2));
   Expect_DL_PH ("PH 2^γ≡3 mod 13, n=12 → 4",
                 U (2), U (3), U (13), U (12), U (4));
   --  Order 16 = 2^4
   Expect_DL_PH ("PH 5^γ≡9 mod 17, n=16 → 10",
                 U (5), U (9), U (17), U (16), U (10));
   Expect_DL_PH ("PH 3^γ≡8 mod 17, n=16 → 10",
                 U (3), U (8), U (17), U (16), U (10));
   --  Order 18 = 2*3^2
   Expect_DL_PH ("PH 2^γ≡5 mod 19, n=18 → 16",
                 U (2), U (5), U (19), U (18), U (16));
   Expect_DL_PH ("PH 3^γ≡16 mod 19, n=18 → 10",
                 U (3), U (16), U (19), U (18), U (10));
   --  Order 30 = 2*3*5
   Expect_DL_PH ("PH 2^γ≡16 mod 31, n=30 → 4",
                 U (2), U (16), U (31), U (30), U (4));
   Expect_DL_PH ("PH 3^γ≡25 mod 31, n=30 → 10",
                 U (3), U (25), U (31), U (30), U (10));
   --  Order 28 = 2^2*7
   Expect_DL_PH ("PH 2^γ≡9 mod 29, n=28 → 10",
                 U (2), U (9), U (29), U (28), U (10));
   --  Order 36 = 2^2*3^2
   Expect_DL_PH ("PH 2^γ≡25 mod 37, n=36 → 10",
                 U (2), U (25), U (37), U (36), U (10));
   --  Order 40 = 2^3*5
   Expect_DL_PH ("PH 6^γ≡32 mod 41, n=40 → 10",
                 U (6), U (32), U (41), U (40), U (10));
   --  Order 10 = 2*5
   Expect_DL_PH ("PH 2^γ≡3 mod 11, n=10 → 8",
                 U (2), U (3), U (11), U (10), U (8));
   Expect_DL_PH ("PH 2^γ≡10 mod 11, n=10 → 5",
                 U (2), U (10), U (11), U (10), U (5));
   --  Order 6 = 2*3
   Expect_DL_PH ("PH 3^γ≡6 mod 7, n=6 → 3",
                 U (3), U (6), U (7), U (6), U (3));
   Expect_DL_PH ("PH 3^γ≡2 mod 7, n=6 → 2",
                 U (3), U (2), U (7), U (6), U (2));
   Expect_DL_PH ("PH 5^γ≡3 mod 7, n=6 → 5",
                 U (5), U (3), U (7), U (6), U (5));

   ------------------------------------------------------------------
   Section ("10. Driver Discrete_Log");
   ------------------------------------------------------------------
   Expect_DL_Driver ("driver trial path 5^γ≡8 mod 23",
                     U (5), U (8), U (23), U (22), U (6));
   Expect_DL_Driver ("driver trial path 2^γ≡3 mod 11",
                     U (2), U (3), U (11), U (10), U (8));
   Expect_DL_Driver ("driver BSGS path 2^γ≡5 mod 1019",
                     U (2), U (5), U (1019), U (1018), U (10));
   Expect_DL_Driver ("driver BSGS path 11^γ≡510 mod 1009",
                     U (11), U (510), U (1009), U (1008), U (123));
   Expect_DL_Driver ("driver BSGS path 5^γ≡356 mod 503",
                     U (5), U (356), U (503), U (502), U (77));
   Expect_DL_Driver ("driver β=1",
                     U (2), U (1), U (101), U (100), U (0));
   Expect_DL_Driver ("driver α=β",
                     U (7), U (7), U (71), U (70), U (1));
   Expect_DL_Driver ("driver 2^γ≡54 mod 101",
                     U (2), U (54), U (101), U (100), U (8));
   --  Boundary: Order = Max_Trial_Order uses trial
   declare
      --  Use a small known instance with Order well below boundary
      G : constant U64 := Discrete_Log (U (2), U (8), U (13), U (12));
   begin
      Check (G = 3, "driver Order=12 ≤ Max_Trial_Order → trial");
   end;
   --  Order > Max_Trial_Order uses BSGS
   declare
      Ord : constant U64 := U (1018);
      G   : constant U64 :=
        Discrete_Log (U (2), U (5), U (1019), Ord);
   begin
      Check (G = 10 and then Ord > Max_Trial_Order,
             "driver Order=1018 > Max_Trial_Order → BSGS");
   end;

   ------------------------------------------------------------------
   Section ("11. Invalid_Argument domain errors");
   ------------------------------------------------------------------
   Expect_Invalid_DL ("Modulus=0", U (2), U (3), U (0), U (1));
   Expect_Invalid_DL ("Modulus=1", U (2), U (3), U (1), U (1));
   Expect_Invalid_DL ("Order=0", U (2), U (3), U (11), U (0));
   Expect_Invalid_DL ("Order too large",
                      U (2), U (3), U (11), U (Max_Educational_Order + 1));
   Expect_Invalid_DL ("Alpha≡0", U (11), U (3), U (11), U (10));
   Expect_Invalid_DL ("Beta≡0", U (2), U (22), U (11), U (10));
   Expect_Invalid_DL ("Alpha=0", U (0), U (3), U (11), U (10));

   ------------------------------------------------------------------
   Section ("12. Exhaustive tiny fields (trial + BSGS + driver)");
   ------------------------------------------------------------------
   declare
      Ok : Boolean := True;
      Got : U64;
      Target : U64;
   begin
      for Exp in U64 range 0 .. 21 loop
         Target := Mod_Pow (U (5), Exp, U (23));
         Got := Discrete_Log_Trial (U (5), Target, U (23), U (22));
         if Got /= Exp
           or else not Verify_Discrete_Log (U (5), Target, U (23), Got)
         then
            Ok := False;
         end if;
         Got := Discrete_Log_BSGS (U (5), Target, U (23), U (22));
         if Got /= Exp then
            Ok := False;
         end if;
         Got := Discrete_Log (U (5), Target, U (23), U (22));
         if Got /= Exp then
            Ok := False;
         end if;
         Got := Discrete_Log_Pohlig_Hellman
           (U (5), Target, U (23), U (22));
         if Got /= Exp then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "exhaustive 5^γ mod 23 (trial/BSGS/driver/PH)");
   end;

   declare
      Ok : Boolean := True;
      Got : U64;
      Target : U64;
   begin
      for Exp in U64 range 0 .. 11 loop
         Target := Mod_Pow (U (2), Exp, U (13));
         Got := Discrete_Log_Trial (U (2), Target, U (13), U (12));
         if Got /= Exp then
            Ok := False;
         end if;
         Got := Discrete_Log_BSGS (U (2), Target, U (13), U (12));
         if Got /= Exp then
            Ok := False;
         end if;
         Got := Discrete_Log_Pohlig_Hellman
           (U (2), Target, U (13), U (12));
         if Got /= Exp then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "exhaustive 2^γ mod 13 (trial/BSGS/PH)");
   end;

   declare
      Ok : Boolean := True;
      Got : U64;
      Target : U64;
   begin
      for Exp in U64 range 0 .. 9 loop
         Target := Mod_Pow (U (2), Exp, U (11));
         Got := Discrete_Log (U (2), Target, U (11), U (10));
         if Got /= Exp
           or else not Verify_Discrete_Log (U (2), Target, U (11), Got)
         then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "exhaustive driver 2^γ mod 11");
   end;

   declare
      Ok : Boolean := True;
      Got : U64;
      Target : U64;
   begin
      for Exp in U64 range 0 .. 15 loop
         Target := Mod_Pow (U (5), Exp, U (17));
         Got := Discrete_Log_Pohlig_Hellman
           (U (5), Target, U (17), U (16));
         if Got /= Exp then
            Ok := False;
         end if;
         Got := Discrete_Log_BSGS (U (5), Target, U (17), U (16));
         if Got /= Exp then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "exhaustive 5^γ mod 17 (PH/BSGS)");
   end;

   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
