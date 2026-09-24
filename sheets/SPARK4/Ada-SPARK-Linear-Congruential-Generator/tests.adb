--  Standalone test suite for Linear_Congruential_Generator (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Linear_Congruential_Generator;
use Linear_Congruential_Generator;

procedure Tests
  with SPARK_Mode => Off
is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function V (X : Long_Long_Integer) return Value is (Value (X));

   type Value_Array is array (Positive range <>) of Value;

   function Next_Val (G : in out Generator) return Value is
      R : Value;
   begin
      Next (G, R);
      return R;
   end Next_Val;

   function Sequence_Matches
     (P : Parameters; Seed : Value; Expected : Value_Array) return Boolean
   is
      G : Generator := Create (P, Seed);
      X : Value;
   begin
      for I in Expected'Range loop
         X := Next_Val (G);
         if X /= Expected (I) then
            return False;
         end if;
      end loop;
      return True;
   end Sequence_Matches;

   function Period_Of
     (P : Parameters; Seed : Value; Limit : Positive) return Natural
   is
      G     : Generator := Create (P, Seed);
      First : constant Value := Next_Val (G);
      X     : Value;
   begin
      for K in 1 .. Limit loop
         X := Next_Val (G);
         if X = First then
            return K;
         end if;
      end loop;
      return 0;
   end Period_Of;

   function All_In_Range
     (P : Parameters; Seed : Value; Count : Positive) return Boolean
   is
      G : Generator := Create (P, Seed);
      X : Value;
   begin
      for K in 1 .. Count loop
         X := Next_Val (G);
         if X >= P.M then
            return False;
         end if;
      end loop;
      return True;
   end All_In_Range;

   function Params_Equal (A, B : Parameters) return Boolean is
     (A.A = B.A and then A.C = B.C and then A.M = B.M);

   Tiny_Full : constant Parameters := (A => 4, C => 1, M => 9);
   Tiny_8    : constant Parameters := (A => 5, C => 1, M => 8);
   Counter   : constant Parameters := (A => 1, C => 1, M => 10);
   Tiny_Bad  : constant Parameters := (A => 2, C => 1, M => 9);
   Weyl      : constant Parameters := (A => 1, C => 3, M => 10);

   G       : Generator;
   P       : Parameters;
   X, Y, Z : Value;
   B       : Boolean;

begin
   -----------------------------------------------------------------
   Section ("1. Validation helpers (Pre-style; no exceptions)");
   -----------------------------------------------------------------
   P := (A => 1, C => 0, M => 0);
   Check (not Is_Valid_Parameters (P), "M=0 invalid");
   Check (not Is_Valid_Modulus (V (0)), "Is_Valid_Modulus 0");
   Check (not Is_Valid_Modulus (V (1)), "Is_Valid_Modulus 1");
   Check (Is_Valid_Modulus (V (2)), "Is_Valid_Modulus 2");
   Check (Is_Valid_Modulus (Default_Modulus), "Is_Valid_Modulus Default");
   Check (not Is_Valid_Modulus (Default_Modulus + 1),
          "Is_Valid_Modulus > Max");

   P := (A => 1, C => 0, M => 1);
   Check (not Is_Valid_Parameters (P), "M=1 invalid");

   P := (A => 0, C => 1, M => 10);
   Check (not Is_Valid_Parameters (P), "A=0 invalid");

   P := (A => 10, C => 1, M => 10);
   Check (not Is_Valid_Parameters (P), "A=M invalid");

   P := (A => 11, C => 1, M => 10);
   Check (Is_Valid_Parameters (P), "A>M reduced a=1 valid");
   Check (Reduce (P).A = 1 and then Reduce (P).C = 1, "Reduce A=11 m=10");
   G := Create (P, 0);
   Check (Get_A (G) = 1, "Create stores reduced A");
   Check (Next_Val (G) = 1, "unreduced A=11 acts as a=1");

   P := (A => 3, C => 10, M => 10);
   Check (Is_Valid_Parameters (P), "C=M reduced c=0 valid");
   Check (Reduce (P).C = 0, "Reduce C=M");

   P := (A => 3, C => 11, M => 10);
   Check (Is_Valid_Parameters (P), "C>M reduced c=1 valid");
   Check (Reduce (P).C = 1, "Reduce C=11 m=10");

   G := Create (Tiny_Full, 0);
   Check (Is_Initialised (G), "tiny_full initialised");

   -----------------------------------------------------------------
   Section ("2. Tiny full-period LCG m=9, a=4, c=1");
   -----------------------------------------------------------------
   Check (Is_Valid_Parameters (Tiny_Full), "tiny_full valid");
   Check (Hull_Dobell_Satisfied (Tiny_Full), "tiny_full HD");
   Check (Sequence_Matches
            (Tiny_Full, 0,
             [1, 5, 3, 4, 8, 6, 7, 2, 0, 1, 5, 3]),
          "tiny_full seed0 sequence");
   G := Create (Tiny_Full, 0);
   Check (Get_State (G) = 0, "tiny_full X0");
   Check (Get_Seed (G) = 0, "tiny_full seed");
   X := Next_Val (G);
   Check (X = 1, "tiny_full X1");
   Check (Get_State (G) = 1, "tiny_full state after X1");
   Check (Period_Of (Tiny_Full, 0, 20) = Nat (9), "tiny_full period 9");
   Check (All_In_Range (Tiny_Full, 0, 40), "tiny_full in range");

   for S in 0 .. 8 loop
      declare
         Seen : array (0 .. 8) of Boolean := [others => False];
         GG   : Generator := Create (Tiny_Full, V (Long_Long_Integer (S)));
         W    : Value;
         Ok   : Boolean := True;
      begin
         for K in 1 .. 9 loop
            W := Next_Val (GG);
            if W > 8 or else Seen (Natural (W)) then
               Ok := False;
            else
               Seen (Natural (W)) := True;
            end if;
         end loop;
         for I in 0 .. 8 loop
            Ok := Ok and then Seen (I);
         end loop;
         Check (Ok, "tiny_full full cycle seed" & Integer'Image (S));
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("3. Tiny LCG m=8, a=5, c=1 (power-of-two)");
   -----------------------------------------------------------------
   Check (Hull_Dobell_Satisfied (Tiny_8), "tiny_8 HD");
   Check (Sequence_Matches
            (Tiny_8, 0, [1, 6, 7, 4, 5, 2, 3, 0, 1, 6]),
          "tiny_8 sequence");
   Check (Period_Of (Tiny_8, 0, 20) = Nat (8), "tiny_8 period 8");
   G := Create (Tiny_8, 0);
   X := Next_Val (G);
   Y := Next_Val (G);
   Check (X rem 2 = 1 and then Y rem 2 = 0, "tiny_8 low bit alt");

   -----------------------------------------------------------------
   Section ("4. Counter / Weyl (a=1) and a non-full tiny LCG");
   -----------------------------------------------------------------
   Check (Hull_Dobell_Satisfied (Counter), "counter HD");
   Check (Sequence_Matches
            (Counter, 0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2]),
          "counter sequence");
   Check (Period_Of (Counter, 0, 20) = Nat (10), "counter period 10");

   Check (not Hull_Dobell_Satisfied (Tiny_Bad), "a=2 c=1 m=9 not HD");
   Check (Sequence_Matches (Tiny_Bad, 0, [1, 3, 7, 6, 4, 0, 1, 3]),
          "tiny_bad sequence");
   Check (Period_Of (Tiny_Bad, 0, 20) = Nat (6), "tiny_bad period 6");

   Check (Hull_Dobell_Satisfied (Weyl), "Weyl HD");
   G := Create (Weyl, 0);
   Check (Next_Val (G) = 3, "Weyl X1");
   Check (Next_Val (G) = 6, "Weyl X2");
   Check (Next_Val (G) = 9, "Weyl X3");
   Check (Next_Val (G) = 2, "Weyl X4");

   -----------------------------------------------------------------
   Section ("5. Reset / determinism / independent generators");
   -----------------------------------------------------------------
   G := Create (Tiny_Full, 3);
   X := Next_Val (G);
   Y := Next_Val (G);
   Reset (G, 3);
   Check (Get_State (G) = 3, "reset state");
   Check (Get_Seed (G) = 3, "reset seed");
   Check (Next_Val (G) = X, "reset X1");
   Check (Next_Val (G) = Y, "reset X2");

   declare
      G1 : Generator := Create (Tiny_Full, 1);
      G2 : Generator := Create (Tiny_Full, 1);
      G3 : Generator := Create (Tiny_Full, 2);
   begin
      Check (Next_Val (G1) = Next_Val (G2), "independent same seed");
      Check (Next_Val (G1) = Next_Val (G2), "independent same seed 2");
      X := Next_Val (G3);
      Check (X < 9, "independent other seed ran");
      Check (Get_Parameters (G1).M = 9, "params M");
      Check (Get_Parameters (G1).A = 4, "params A");
      Check (Get_Parameters (G1).C = 1, "params C");
      Check (Get_A (G1) = 4, "Get_A");
      Check (Get_C (G1) = 1, "Get_C");
      Check (Get_M (G1) = 9, "Get_M");
   end;

   G := Create (Tiny_8, 5);
   X := Next_Val (G);
   declare
      G_Copy : constant Generator := G;
   begin
      Check (Get_State (G_Copy) = X, "copy state");
      Check (Next_Val (G) = Step (X, Tiny_8), "copy then next = Step");
   end;

   -----------------------------------------------------------------
   Section ("6. Park–Miller MINSTD known sequence");
   -----------------------------------------------------------------
   Check (Is_Valid_Parameters (Park_Miller), "PM valid");
   Check (not Hull_Dobell_Satisfied (Park_Miller), "PM MCG not HD");
   Check (Park_Miller.C = 0, "PM is MCG");
   Check (Sequence_Matches
            (Park_Miller, 1,
             [16_807,
              282_475_249,
              1_622_650_073,
              984_943_658,
              1_144_108_930,
              470_211_272,
              101_027_544,
              1_457_850_878,
              1_458_777_923,
              2_007_237_709]),
          "PM seed1 sequence");
   G := Create (Park_Miller, 1);
   Check (Get_State (G) = 1, "PM X0=1");
   Check (All_In_Range (Park_Miller, 1, 50), "PM in range");

   G := Create (Park_Miller, 0);
   Check (Next_Val (G) = 0, "PM seed0 stays 0");
   Check (Next_Val (G) = 0, "PM seed0 stays 0 again");

   Check (Sequence_Matches
            (MINSTD_Rand, 1,
             [48_271,
              182_605_794,
              1_291_394_886,
              1_914_720_637,
              2_078_669_041,
              407_355_683]),
          "minstd_rand sequence");
   Check (not Hull_Dobell_Satisfied (MINSTD_Rand), "minstd_rand not HD");

   -----------------------------------------------------------------
   Section ("7. glibc / ANSI C known sequence");
   -----------------------------------------------------------------
   Check (Params_Equal (Glibc, ANSI_C), "glibc = ANSI_C params");
   Check (Hull_Dobell_Satisfied (Glibc), "glibc HD");
   Check (Sequence_Matches
            (Glibc, 1,
             [1_103_527_590,
              377_401_575,
              662_824_084,
              1_147_902_781,
              2_035_015_474,
              368_800_899,
              1_508_029_952,
              486_256_185]),
          "glibc seed1 sequence");
   Check (All_In_Range (Glibc, 1, 40), "glibc in range");

   -----------------------------------------------------------------
   Section ("8. Numerical Recipes / Borland / MSVC / Delphi / VB");
   -----------------------------------------------------------------
   Check (Hull_Dobell_Satisfied (Numerical_Recipes), "NR HD");
   Check (Sequence_Matches
            (Numerical_Recipes, 1,
             [1_015_568_748,
              1_586_005_467,
              2_165_703_038,
              3_027_450_565,
              217_083_232,
              1_587_069_247]),
          "NR seed1 sequence");

   Check (Hull_Dobell_Satisfied (Borland_C), "Borland_C HD");
   Check (Sequence_Matches
            (Borland_C, 1,
             [22_695_478,
              2_156_045_615,
              2_867_233_980,
              71_484_141,
              2_911_408_402]),
          "Borland_C sequence");

   Check (Hull_Dobell_Satisfied (Borland_Delphi), "Delphi HD");
   Check (Sequence_Matches
            (Borland_Delphi, 0,
             [1,
              134_775_814,
              3_698_175_007,
              870_078_620,
              1_172_187_917]),
          "Delphi sequence");

   Check (Hull_Dobell_Satisfied (Microsoft_Visual_C), "MSVC HD");
   Check (Sequence_Matches
            (Microsoft_Visual_C, 1,
             [2_745_024,
              3_357_800_067,
              415_139_642,
              3_884_216_597,
              3_403_800_452]),
          "MSVC sequence");

   Check (Is_Valid_Parameters (Microsoft_Visual_Basic), "VB valid");
   Check (Microsoft_Visual_Basic.A > Microsoft_Visual_Basic.M,
          "VB A>M published");
   Check (Reduce (Microsoft_Visual_Basic).A /= 0, "VB reduced A");
   Check (Sequence_Matches
            (Microsoft_Visual_Basic, 1,
             [12_640_960, 8_124_035, 4_294_458, 3_961_109]),
          "VB sequence");

   -----------------------------------------------------------------
   Section ("9. RANDU / VMS / ZX81 (Java 2**48 omitted — over Max_Modulus)");
   -----------------------------------------------------------------
   Check (not Hull_Dobell_Satisfied (RANDU), "RANDU MCG not HD");
   Check (Sequence_Matches
            (RANDU, 1,
             [65_539,
              393_225,
              1_769_499,
              7_077_969,
              26_542_323,
              95_552_217]),
          "RANDU sequence");

   Check (Is_Valid_Parameters (VMS_MTH_Random), "VMS valid");
   Check (Hull_Dobell_Satisfied (VMS_MTH_Random), "VMS HD");
   G := Create (VMS_MTH_Random, 1);
   X := Next_Val (G);
   Check (X = Step (1, VMS_MTH_Random), "VMS Step vs Next");

   Check (Is_Valid_Parameters (ZX81), "ZX81 valid");
   Check (Sequence_Matches
            (ZX81, 0,
             [74, 5_624, 28_652, 51_790, 17_641, 12_409, 13_231, 9_344]),
          "ZX81 sequence");
   Check (All_In_Range (ZX81, 0, 30), "ZX81 in range");

   -----------------------------------------------------------------
   Section ("10. Built-in parameter-set validity");
   -----------------------------------------------------------------
   Check (Is_Valid_Parameters (Numerical_Recipes), "valid NR");
   Check (Is_Valid_Parameters (Glibc), "valid glibc");
   Check (Is_Valid_Parameters (ANSI_C), "valid ANSI");
   Check (Is_Valid_Parameters (Borland_C), "valid Borland_C");
   Check (Is_Valid_Parameters (Borland_Delphi), "valid Delphi");
   Check (Is_Valid_Parameters (Microsoft_Visual_C), "valid MSVC");
   Check (Is_Valid_Parameters (Microsoft_Visual_Basic), "valid VB");
   Check (Is_Valid_Parameters (Park_Miller), "valid PM");
   Check (Is_Valid_Parameters (MINSTD_Rand), "valid minstd");
   Check (Is_Valid_Parameters (RANDU), "valid RANDU");
   Check (Is_Valid_Parameters (VMS_MTH_Random), "valid VMS");
   Check (Is_Valid_Parameters (ZX81), "valid ZX81");

   Check (Numerical_Recipes.M = V (2 ** 32), "NR M");
   Check (Glibc.M = V (2 ** 31), "glibc M");
   Check (Park_Miller.M = V (2 ** 31 - 1), "PM M");
   Check (RANDU.A = V (65_539), "RANDU A");
   Check (ZX81.M = V (65_537), "ZX81 M");
   Check (Microsoft_Visual_Basic.M = V (2 ** 24), "VB M");
   Check (Max_Modulus = V (2 ** 32), "Max_Modulus");

   -----------------------------------------------------------------
   Section ("11. Hull–Dobell component conditions");
   -----------------------------------------------------------------
   Check (Increment_Coprime (Tiny_Full), "tiny_full gcd(c,m)=1");
   Check (Multiplier_Condition (Tiny_Full), "tiny_full a-1 primes");
   Check (Four_Condition (Tiny_Full), "tiny_full four (m not *4)");
   Check (not Increment_Coprime (Park_Miller), "PM gcd(0,m)/=1");
   Check (not Increment_Coprime (RANDU), "RANDU gcd(0,m)/=1");
   Check (Increment_Coprime (Glibc), "glibc coprime");
   Check (Multiplier_Condition (Glibc), "glibc a-1");
   Check (Four_Condition (Glibc), "glibc four");
   Check (Increment_Coprime (Numerical_Recipes), "NR coprime");
   Check (Multiplier_Condition (Numerical_Recipes), "NR a-1");
   Check (Four_Condition (Numerical_Recipes), "NR four");
   Check (not Multiplier_Condition (Tiny_Bad), "tiny_bad a-1");
   Check (Four_Condition (Tiny_Bad), "tiny_bad four (9 not *4)");
   Check (Four_Condition (Tiny_8), "tiny_8 four (8=4*2, a-1=4)");

   declare
      Weak : constant Parameters := (A => 9, C => 1, M => 16);
   begin
      Check (Is_Valid_Parameters (Weak), "weak valid");
      Check (Hull_Dobell_Satisfied (Weak), "weak HD still true");
      Check (Period_Of (Weak, 0, 40) = Nat (16), "weak period 16");
   end;

   declare
      Fail4 : constant Parameters := (A => 3, C => 1, M => 8);
   begin
      Check (Increment_Coprime (Fail4), "fail4 coprime");
      Check (Multiplier_Condition (Fail4), "fail4 primes (only 2)");
      Check (not Four_Condition (Fail4), "fail4 four fails");
      Check (not Hull_Dobell_Satisfied (Fail4), "fail4 not HD");
   end;

   -----------------------------------------------------------------
   Section ("12. Add_Mod / Mul_Mod / Gcd helpers");
   -----------------------------------------------------------------
   Check (Add_Mod (V (3), V (5), 7) = 1, "Add_Mod 3+5 mod 7");
   Check (Add_Mod (V (0), V (0), 2) = 0, "Add_Mod 0+0");
   Check (Add_Mod (V (15), V (1), 16) = 0, "Add_Mod wrap power2");
   Check (Add_Mod (Default_Modulus - 1, V (1), Modulus_Type (Default_Modulus))
            = 0,
          "Add_Mod Default_Modulus wrap");
   Check (Add_Mod (Default_Modulus - 1, Default_Modulus - 1,
                   Modulus_Type (Default_Modulus))
            = Default_Modulus - 2,
          "Add_Mod (M-1)+(M-1)");

   Check (Mul_Mod (V (3), V (5), 7) = 1, "Mul_Mod 3*5 mod 7");
   Check (Mul_Mod (V (0), V (5), 7) = 0, "Mul_Mod 0");
   Check (Mul_Mod (V (6), V (6), 7) = 1, "Mul_Mod 6*6 mod 7");
   Check (Mul_Mod (V (15), V (15), 16) = 1, "Mul_Mod power2");
   Check (Mul_Mod (Default_Modulus - 1, V (2), Modulus_Type (Default_Modulus))
            = Default_Modulus - 2,
          "Mul_Mod (M-1)*2");

   Check (Gcd (V (0), V (0)) = 0, "Gcd 0,0");
   Check (Gcd (V (0), V (12)) = 12, "Gcd 0,12");
   Check (Gcd (V (12), V (0)) = 12, "Gcd 12,0");
   Check (Gcd (V (48), V (18)) = 6, "Gcd 48,18");
   Check (Gcd (V (17), V (13)) = 1, "Gcd primes");
   Check (Are_Coprime (V (17), V (13)), "Are_Coprime primes");
   Check (not Are_Coprime (V (48), V (18)), "not Are_Coprime 48,18");
   Check (Prime_Factors_Divide (V (6), V (12)), "PFD 6|factors(12)");
   Check (not Prime_Factors_Divide (V (4), V (12)), "PFD 4 misses 3");
   Check (Prime_Factors_Divide (V (4), V (8)), "PFD 4|factors(8)");

   -----------------------------------------------------------------
   Section ("13. Step pure recurrence");
   -----------------------------------------------------------------
   Check (Step (0, Tiny_Full) = 1, "Step tiny 0");
   Check (Step (1, Tiny_Full) = 5, "Step tiny 1");
   Check (Step (1, Park_Miller) = 16_807, "Step PM");
   Check (Step (0, Numerical_Recipes) =
            (Numerical_Recipes.C rem Numerical_Recipes.M),
          "Step NR seed0 = C");

   -----------------------------------------------------------------
   Section ("14. Many draws stay in range / differ");
   -----------------------------------------------------------------
   G := Create (Numerical_Recipes, 42);
   B := True;
   for I in 1 .. 100 loop
      X := Next_Val (G);
      if X >= Numerical_Recipes.M then
         B := False;
      end if;
   end loop;
   Check (B, "NR 100 draws in range");

   G := Create (Glibc, 7);
   declare
      G2 : Generator := Create (Glibc, 8);
   begin
      B := False;
      for I in 1 .. 20 loop
         if Next_Val (G) /= Next_Val (G2) then
            B := True;
         end if;
      end loop;
      Check (B, "different seeds diverge");
   end;

   G := Create (ZX81, 1);
   X := Next_Val (G);
   Y := Next_Val (G);
   Z := Next_Val (G);
   Reset (G, 1);
   Check (Next_Val (G) = X and then Next_Val (G) = Y
            and then Next_Val (G) = Z,
          "ZX81 reset replay");

   -----------------------------------------------------------------
   -- Summary
   -----------------------------------------------------------------
   New_Line;
   Put_Line ("========================================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   Put_Line ("========================================");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
