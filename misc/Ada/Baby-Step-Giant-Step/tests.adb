--  Standalone test suite for Baby_Step_Giant_Step (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Baby_Step_Giant_Step; use Baby_Step_Giant_Step;

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
              Discrete_Log_BSGS (Alpha, Beta, Modulus, Order);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Discrete_Log_BSGS: " & Label);
   end Expect_Invalid_DL;

   procedure Expect_DL
     (Label : String; Alpha, Beta, Modulus, Order, Expected : U64)
   is
      G : constant U64 := Discrete_Log_BSGS (Alpha, Beta, Modulus, Order);
   begin
      Check
        (G = Expected
           and then Verify_Discrete_Log (Alpha, Beta, Modulus, G),
         Label);
   end Expect_DL;

   procedure Expect_Failure
     (Label : String; Alpha, Beta, Modulus, Order : U64)
   is
      G : constant U64 := Discrete_Log_BSGS (Alpha, Beta, Modulus, Order);
   begin
      Check (G = Order, Label);
   end Expect_Failure;

begin
   Ada.Text_IO.Put_Line ("Baby_Step_Giant_Step — Ada 2023 test suite");

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
   Section ("3. Modular_Inverse");
   ------------------------------------------------------------------
   Check (Modular_Inverse (U (3), U (10)) = 7, "3^{-1} mod 10 = 7");
   Check (Modular_Inverse (U (7), U (10)) = 3, "7^{-1} mod 10 = 3");
   Check (Mul_Mod (U (19), Modular_Inverse (U (19), U (509)), U (509)) = 1,
          "19*inv ≡ 1 mod 509");
   Check (Modular_Inverse (U (1), U (1018)) = 1, "1^{-1} = 1");
   Check (Mul_Mod (U (5), Modular_Inverse (U (5), U (22)), U (22)) = 1,
          "5*inv ≡ 1 mod 22");
   Check (Mul_Mod (U (2), Modular_Inverse (U (2), U (101)), U (101)) = 1,
          "2*inv ≡ 1 mod 101");
   Check (Mul_Mod (U (11), Modular_Inverse (U (11), U (1009)), U (1009)) = 1,
          "11*inv ≡ 1 mod 1009");
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
   Check (Floor_Sqrt (U (1414) * U (1414)) = 1414, "floor_sqrt(perfect)");

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
   Section ("6. Discrete_Log_BSGS — verified instances");
   ------------------------------------------------------------------
   Expect_DL ("2^γ≡5 mod 1019, n=1018 → γ=10",
              U (2), U (5), U (1019), U (1018), U (10));
   Expect_DL ("5^γ≡8 mod 23, n=22 → γ=6",
              U (5), U (8), U (23), U (22), U (6));
   Expect_DL ("2^γ≡54 mod 101, n=100 → γ=8",
              U (2), U (54), U (101), U (100), U (8));
   Expect_DL ("3^γ≡9 mod 13, n=12 → γ=2",
              U (3), U (9), U (13), U (12), U (2));
   Expect_DL ("2^γ≡8 mod 13, n=12 → γ=3",
              U (2), U (8), U (13), U (12), U (3));
   Expect_DL ("3^γ≡6 mod 7, n=6 → γ=3",
              U (3), U (6), U (7), U (6), U (3));
   Expect_DL ("2^γ≡3 mod 11, n=10 → γ=8",
              U (2), U (3), U (11), U (10), U (8));
   Expect_DL ("5^γ≡9 mod 17, n=16 → γ=10",
              U (5), U (9), U (17), U (16), U (10));
   Expect_DL ("2^γ≡5 mod 19, n=18 → γ=16",
              U (2), U (5), U (19), U (18), U (16));
   Expect_DL ("2^γ≡16 mod 31, n=30 → γ=4",
              U (2), U (16), U (31), U (30), U (4));
   Expect_DL ("2^γ≡9 mod 29, n=28 → γ=10",
              U (2), U (9), U (29), U (28), U (10));
   Expect_DL ("5^γ≡24 mod 43, n=42 → γ=10",
              U (5), U (24), U (43), U (42), U (10));
   Expect_DL ("5^γ≡17 mod 47, n=46 → γ=16",
              U (5), U (17), U (47), U (46), U (16));
   Expect_DL ("2^γ≡25 mod 37, n=36 → γ=10",
              U (2), U (25), U (37), U (36), U (10));
   Expect_DL ("6^γ≡32 mod 41, n=40 → γ=10",
              U (6), U (32), U (41), U (40), U (10));
   Expect_DL ("11^γ≡510 mod 1009, n=1008 → γ=123",
              U (11), U (510), U (1009), U (1008), U (123));
   Expect_DL ("5^γ≡356 mod 503, n=502 → γ=77",
              U (5), U (356), U (503), U (502), U (77));
   Expect_DL ("2^γ≡553 mod 1019, n=1018 → γ=77",
              U (2), U (553), U (1019), U (1018), U (77));
   Expect_DL ("2^γ≡4 mod 5, n=4 → γ=2",
              U (2), U (4), U (5), U (4), U (2));
   Expect_DL ("3^γ≡4 mod 5, n=4 → γ=2",
              U (3), U (4), U (5), U (4), U (2));
   Expect_DL ("3^γ≡2 mod 7, n=6 → γ=2",
              U (3), U (2), U (7), U (6), U (2));
   Expect_DL ("5^γ≡3 mod 7, n=6 → γ=5",
              U (5), U (3), U (7), U (6), U (5));
   Expect_DL ("2^γ≡10 mod 11, n=10 → γ=5",
              U (2), U (10), U (11), U (10), U (5));
   Expect_DL ("2^γ≡6 mod 11, n=10 → γ=9",
              U (2), U (6), U (11), U (10), U (9));
   Expect_DL ("3^γ≡9 mod 11, n=5 → γ=2",
              U (3), U (9), U (11), U (5), U (2));
   Expect_DL ("4^γ≡5 mod 11, n=5 → γ=2",
              U (4), U (5), U (11), U (5), U (2));
   Expect_DL ("2^γ≡3 mod 13, n=12 → γ=4",
              U (2), U (3), U (13), U (12), U (4));
   Expect_DL ("3^γ≡8 mod 17, n=16 → γ=10",
              U (3), U (8), U (17), U (16), U (10));
   Expect_DL ("7^γ≡2 mod 17, n=16 → γ=10",
              U (7), U (2), U (17), U (16), U (10));
   Expect_DL ("3^γ≡16 mod 19, n=18 → γ=10",
              U (3), U (16), U (19), U (18), U (10));
   Expect_DL ("10^γ≡4 mod 19, n=18 → γ=16",
              U (10), U (4), U (19), U (18), U (16));
   Expect_DL ("5^γ≡3 mod 23, n=22 → γ=16",
              U (5), U (3), U (23), U (22), U (16));
   Expect_DL ("7^γ≡13 mod 23, n=22 → γ=10",
              U (7), U (13), U (23), U (22), U (10));
   Expect_DL ("11^γ≡2 mod 23, n=22 → γ=10",
              U (11), U (2), U (23), U (22), U (10));
   Expect_DL ("3^γ≡5 mod 29, n=28 → γ=10",
              U (3), U (5), U (29), U (28), U (10));
   Expect_DL ("8^γ≡4 mod 29, n=28 → γ=10",
              U (8), U (4), U (29), U (28), U (10));
   Expect_DL ("10^γ≡6 mod 29, n=28 → γ=10",
              U (10), U (6), U (29), U (28), U (10));
   Expect_DL ("3^γ≡25 mod 31, n=30 → γ=10",
              U (3), U (25), U (31), U (30), U (10));
   Expect_DL ("11^γ≡5 mod 31, n=30 → γ=10",
              U (11), U (5), U (31), U (30), U (10));
   Expect_DL ("5^γ≡30 mod 37, n=36 → γ=10",
              U (5), U (30), U (37), U (36), U (10));
   Expect_DL ("5^γ≡34 mod 37, n=36 → γ=16",
              U (5), U (34), U (37), U (36), U (16));
   Expect_DL ("7^γ≡9 mod 41, n=40 → γ=10",
              U (7), U (9), U (41), U (40), U (10));
   Expect_DL ("11^γ≡9 mod 41, n=40 → γ=10",
              U (11), U (9), U (41), U (40), U (10));
   Expect_DL ("3^γ≡10 mod 43, n=42 → γ=10",
              U (3), U (10), U (43), U (42), U (10));
   Expect_DL ("3^γ≡23 mod 43, n=42 → γ=16",
              U (3), U (23), U (43), U (42), U (16));
   Expect_DL ("2^γ≡37 mod 47, n=23 → γ=10",
              U (2), U (37), U (47), U (23), U (10));
   Expect_DL ("5^γ≡12 mod 47, n=46 → γ=10",
              U (5), U (12), U (47), U (46), U (10));
   Expect_DL ("11^γ≡980 mod 1009, n=1008 → γ=10",
              U (11), U (980), U (1009), U (1008), U (10));
   Expect_DL ("11^γ≡485 mod 1009, n=1008 → γ=77",
              U (11), U (485), U (1009), U (1008), U (77));
   Expect_DL ("2^γ≡15 mod 1009, n=504 → γ=10",
              U (2), U (15), U (1009), U (504), U (10));
   Expect_DL ("2^γ≡675 mod 1009, n=504 → γ=77",
              U (2), U (675), U (1009), U (504), U (77));
   Expect_DL ("5^γ≡383 mod 503, n=502 → γ=10",
              U (5), U (383), U (503), U (502), U (10));
   Expect_DL ("10^γ≡37 mod 503, n=502 → γ=123",
              U (10), U (37), U (503), U (502), U (123));
   Expect_DL ("6^γ≡754 mod 1019, n=1018 → γ=10",
              U (6), U (754), U (1019), U (1018), U (10));
   Expect_DL ("7^γ≡297 mod 1019, n=1018 → γ=10",
              U (7), U (297), U (1019), U (1018), U (10));
   Expect_DL ("8^γ≡125 mod 1019, n=1018 → γ=10",
              U (8), U (125), U (1019), U (1018), U (10));
   Expect_DL ("2^γ≡1 mod 1019, n=1018 → γ=0",
              U (2), U (1), U (1019), U (1018), U (0));
   Expect_DL ("5^γ≡1 mod 23, n=22 → γ=0",
              U (5), U (1), U (23), U (22), U (0));
   Expect_DL ("2^γ≡2 mod 101, n=100 → γ=1",
              U (2), U (2), U (101), U (100), U (1));
   Expect_DL ("3^γ≡3 mod 13, n=12 → γ=1",
              U (3), U (3), U (13), U (12), U (1));
   Expect_DL ("2^γ≡2 mod 53, n=52 → γ=1",
              U (2), U (2), U (53), U (52), U (1));
   Expect_DL ("2^γ≡4 mod 53, n=52 → γ=2",
              U (2), U (4), U (53), U (52), U (2));
   Expect_DL ("2^γ≡32 mod 53, n=52 → γ=5",
              U (2), U (32), U (53), U (52), U (5));
   Expect_DL ("2^γ≡17 mod 53, n=52 → γ=10",
              U (2), U (17), U (53), U (52), U (10));
   Expect_DL ("2^γ≡28 mod 53, n=52 → γ=16",
              U (2), U (28), U (53), U (52), U (16));
   Expect_DL ("2^γ≡24 mod 53, n=52 → γ=20",
              U (2), U (24), U (53), U (52), U (20));
   Expect_DL ("2^γ≡37 mod 53, n=52 → γ=30",
              U (2), U (37), U (53), U (52), U (30));
   Expect_DL ("2^γ≡2 mod 59, n=58 → γ=1",
              U (2), U (2), U (59), U (58), U (1));
   Expect_DL ("2^γ≡4 mod 59, n=58 → γ=2",
              U (2), U (4), U (59), U (58), U (2));
   Expect_DL ("2^γ≡32 mod 59, n=58 → γ=5",
              U (2), U (32), U (59), U (58), U (5));
   Expect_DL ("2^γ≡21 mod 59, n=58 → γ=10",
              U (2), U (21), U (59), U (58), U (10));
   Expect_DL ("2^γ≡46 mod 59, n=58 → γ=16",
              U (2), U (46), U (59), U (58), U (16));
   Expect_DL ("2^γ≡28 mod 59, n=58 → γ=20",
              U (2), U (28), U (59), U (58), U (20));
   Expect_DL ("2^γ≡57 mod 59, n=58 → γ=30",
              U (2), U (57), U (59), U (58), U (30));
   Expect_DL ("10^γ≡10 mod 61, n=60 → γ=1",
              U (10), U (10), U (61), U (60), U (1));
   Expect_DL ("10^γ≡39 mod 61, n=60 → γ=2",
              U (10), U (39), U (61), U (60), U (2));
   Expect_DL ("10^γ≡21 mod 61, n=60 → γ=5",
              U (10), U (21), U (61), U (60), U (5));
   Expect_DL ("10^γ≡14 mod 61, n=60 → γ=10",
              U (10), U (14), U (61), U (60), U (10));
   Expect_DL ("10^γ≡12 mod 61, n=60 → γ=16",
              U (10), U (12), U (61), U (60), U (16));
   Expect_DL ("10^γ≡13 mod 61, n=60 → γ=20",
              U (10), U (13), U (61), U (60), U (20));
   Expect_DL ("10^γ≡60 mod 61, n=60 → γ=30",
              U (10), U (60), U (61), U (60), U (30));
   Expect_DL ("2^γ≡2 mod 67, n=66 → γ=1",
              U (2), U (2), U (67), U (66), U (1));
   Expect_DL ("2^γ≡4 mod 67, n=66 → γ=2",
              U (2), U (4), U (67), U (66), U (2));
   Expect_DL ("2^γ≡32 mod 67, n=66 → γ=5",
              U (2), U (32), U (67), U (66), U (5));
   Expect_DL ("2^γ≡19 mod 67, n=66 → γ=10",
              U (2), U (19), U (67), U (66), U (10));
   Expect_DL ("2^γ≡10 mod 67, n=66 → γ=16",
              U (2), U (10), U (67), U (66), U (16));
   Expect_DL ("2^γ≡26 mod 67, n=66 → γ=20",
              U (2), U (26), U (67), U (66), U (20));
   Expect_DL ("2^γ≡25 mod 67, n=66 → γ=30",
              U (2), U (25), U (67), U (66), U (30));
   Expect_DL ("7^γ≡7 mod 71, n=70 → γ=1",
              U (7), U (7), U (71), U (70), U (1));
   Expect_DL ("7^γ≡49 mod 71, n=70 → γ=2",
              U (7), U (49), U (71), U (70), U (2));
   Expect_DL ("7^γ≡51 mod 71, n=70 → γ=5",
              U (7), U (51), U (71), U (70), U (5));
   Expect_DL ("7^γ≡45 mod 71, n=70 → γ=10",
              U (7), U (45), U (71), U (70), U (10));
   Expect_DL ("7^γ≡19 mod 71, n=70 → γ=16",
              U (7), U (19), U (71), U (70), U (16));
   Expect_DL ("7^γ≡37 mod 71, n=70 → γ=20",
              U (7), U (37), U (71), U (70), U (20));
   Expect_DL ("7^γ≡32 mod 71, n=70 → γ=30",
              U (7), U (32), U (71), U (70), U (30));
   Expect_DL ("5^γ≡5 mod 73, n=72 → γ=1",
              U (5), U (5), U (73), U (72), U (1));
   Expect_DL ("5^γ≡25 mod 73, n=72 → γ=2",
              U (5), U (25), U (73), U (72), U (2));
   Expect_DL ("5^γ≡59 mod 73, n=72 → γ=5",
              U (5), U (59), U (73), U (72), U (5));
   Expect_DL ("5^γ≡50 mod 73, n=72 → γ=10",
              U (5), U (50), U (73), U (72), U (10));
   Expect_DL ("5^γ≡4 mod 73, n=72 → γ=16",
              U (5), U (4), U (73), U (72), U (16));
   Expect_DL ("5^γ≡18 mod 73, n=72 → γ=20",
              U (5), U (18), U (73), U (72), U (20));
   Expect_DL ("5^γ≡24 mod 73, n=72 → γ=30",
              U (5), U (24), U (73), U (72), U (30));
   Expect_DL ("3^γ≡3 mod 79, n=78 → γ=1",
              U (3), U (3), U (79), U (78), U (1));
   Expect_DL ("3^γ≡9 mod 79, n=78 → γ=2",
              U (3), U (9), U (79), U (78), U (2));
   Expect_DL ("3^γ≡6 mod 79, n=78 → γ=5",
              U (3), U (6), U (79), U (78), U (5));
   Expect_DL ("3^γ≡36 mod 79, n=78 → γ=10",
              U (3), U (36), U (79), U (78), U (10));
   Expect_DL ("3^γ≡16 mod 79, n=78 → γ=16",
              U (3), U (16), U (79), U (78), U (16));
   Expect_DL ("3^γ≡32 mod 79, n=78 → γ=20",
              U (3), U (32), U (79), U (78), U (20));
   Expect_DL ("3^γ≡46 mod 79, n=78 → γ=30",
              U (3), U (46), U (79), U (78), U (30));
   Expect_DL ("2^γ≡2 mod 83, n=82 → γ=1",
              U (2), U (2), U (83), U (82), U (1));
   Expect_DL ("2^γ≡4 mod 83, n=82 → γ=2",
              U (2), U (4), U (83), U (82), U (2));
   Expect_DL ("2^γ≡32 mod 83, n=82 → γ=5",
              U (2), U (32), U (83), U (82), U (5));
   Expect_DL ("2^γ≡28 mod 83, n=82 → γ=10",
              U (2), U (28), U (83), U (82), U (10));
   Expect_DL ("2^γ≡49 mod 83, n=82 → γ=16",
              U (2), U (49), U (83), U (82), U (16));
   Expect_DL ("2^γ≡37 mod 83, n=82 → γ=20",
              U (2), U (37), U (83), U (82), U (20));
   Expect_DL ("2^γ≡40 mod 83, n=82 → γ=30",
              U (2), U (40), U (83), U (82), U (30));
   Expect_DL ("3^γ≡3 mod 89, n=88 → γ=1",
              U (3), U (3), U (89), U (88), U (1));
   Expect_DL ("3^γ≡9 mod 89, n=88 → γ=2",
              U (3), U (9), U (89), U (88), U (2));
   Expect_DL ("3^γ≡65 mod 89, n=88 → γ=5",
              U (3), U (65), U (89), U (88), U (5));
   Expect_DL ("3^γ≡42 mod 89, n=88 → γ=10",
              U (3), U (42), U (89), U (88), U (10));
   Expect_DL ("3^γ≡2 mod 89, n=88 → γ=16",
              U (3), U (2), U (89), U (88), U (16));
   Expect_DL ("3^γ≡73 mod 89, n=88 → γ=20",
              U (3), U (73), U (89), U (88), U (20));
   Expect_DL ("3^γ≡40 mod 89, n=88 → γ=30",
              U (3), U (40), U (89), U (88), U (30));
   Expect_DL ("5^γ≡5 mod 97, n=96 → γ=1",
              U (5), U (5), U (97), U (96), U (1));
   Expect_DL ("5^γ≡25 mod 97, n=96 → γ=2",
              U (5), U (25), U (97), U (96), U (2));
   Expect_DL ("5^γ≡21 mod 97, n=96 → γ=5",
              U (5), U (21), U (97), U (96), U (5));
   Expect_DL ("5^γ≡53 mod 97, n=96 → γ=10",
              U (5), U (53), U (97), U (96), U (10));
   Expect_DL ("5^γ≡36 mod 97, n=96 → γ=16",
              U (5), U (36), U (97), U (96), U (16));
   Expect_DL ("5^γ≡93 mod 97, n=96 → γ=20",
              U (5), U (93), U (97), U (96), U (20));
   Expect_DL ("5^γ≡79 mod 97, n=96 → γ=30",
              U (5), U (79), U (97), U (96), U (30));

   ------------------------------------------------------------------
   Section ("7. Failure sentinel (β ∉ ⟨α⟩)");
   ------------------------------------------------------------------
   Expect_Failure ("4^γ≢2 mod 11 (order 5)",
                   U (4), U (2), U (11), U (5));
   Expect_Failure ("9^γ≢2 mod 13 (order 3)",
                   U (9), U (2), U (13), U (3));
   Expect_Failure ("4^γ≢2 mod 13 (order 6)",
                   U (4), U (2), U (13), U (6));

   ------------------------------------------------------------------
   Section ("8. Invalid_Argument domain errors");
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
   Section ("9. Exhaustive tiny fields");
   ------------------------------------------------------------------
   declare
      Ok : Boolean := True;
      Got : U64;
      Target : U64;
   begin
      for Exp in U64 range 0 .. 21 loop
         Target := Mod_Pow (U (5), Exp, U (23));
         Got := Discrete_Log_BSGS (U (5), Target, U (23), U (22));
         if Got /= Exp
           or else not Verify_Discrete_Log (U (5), Target, U (23), Got)
         then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "exhaustive 5^γ mod 23 for γ=0..21");
   end;

   declare
      Ok : Boolean := True;
      Got : U64;
      Target : U64;
   begin
      for Exp in U64 range 0 .. 11 loop
         Target := Mod_Pow (U (2), Exp, U (13));
         Got := Discrete_Log_BSGS (U (2), Target, U (13), U (12));
         if Got /= Exp
           or else not Verify_Discrete_Log (U (2), Target, U (13), Got)
         then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "exhaustive 2^γ mod 13 for γ=0..11");
   end;

   declare
      Ok : Boolean := True;
      Got : U64;
      Target : U64;
   begin
      for Exp in U64 range 0 .. 9 loop
         Target := Mod_Pow (U (2), Exp, U (11));
         Got := Discrete_Log_BSGS (U (2), Target, U (11), U (10));
         if Got /= Exp
           or else not Verify_Discrete_Log (U (2), Target, U (11), Got)
         then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "exhaustive 2^γ mod 11 for γ=0..9");
   end;

   declare
      Ok : Boolean := True;
      Got : U64;
      Target : U64;
   begin
      for Exp in U64 range 0 .. 15 loop
         Target := Mod_Pow (U (5), Exp, U (17));
         Got := Discrete_Log_BSGS (U (5), Target, U (17), U (16));
         if Got /= Exp
           or else not Verify_Discrete_Log (U (5), Target, U (17), Got)
         then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "exhaustive 5^γ mod 17 for γ=0..15");
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
