--  Standalone test suite for Linear_Congruential_Generator.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Linear_Congruential_Generator;
use Linear_Congruential_Generator;

procedure Tests is

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

   function Create_Raises (P : Parameters; Seed : Value) return Boolean is
      G : Generator;
   begin
      G := Create (P, Seed);
      pragma Unreferenced (G);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Create_Raises;

   function Reset_Raises (G : in out Generator; Seed : Value) return Boolean
   is
   begin
      Reset (G, Seed);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Reset_Raises;

   function Next_Raises (G : in out Generator) return Boolean is
      X : Value;
   begin
      X := Next (G);
      pragma Unreferenced (X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Next_Raises;

   function Next_Float_Raises (G : in out Generator) return Boolean is
      F : Long_Float;
   begin
      F := Next_Float (G);
      pragma Unreferenced (F);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Next_Float_Raises;

   function Step_Raises (State : Value; P : Parameters) return Boolean is
      X : Value;
   begin
      X := Step (State, P);
      pragma Unreferenced (X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Step_Raises;

   function Add_Mod_Raises (X, Y, M : Value) return Boolean is
      R : Value;
   begin
      R := Add_Mod (X, Y, M);
      pragma Unreferenced (R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Mod_Raises;

   function Mul_Mod_Raises (X, Y, M : Value) return Boolean is
      R : Value;
   begin
      R := Mul_Mod (X, Y, M);
      pragma Unreferenced (R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Mul_Mod_Raises;

   function HD_Raises (P : Parameters) return Boolean is
      B : Boolean;
   begin
      B := Hull_Dobell_Satisfied (P);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end HD_Raises;

   function Inc_Coprime_Raises (P : Parameters) return Boolean is
      B : Boolean;
   begin
      B := Increment_Coprime (P);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Inc_Coprime_Raises;

   function Mult_Cond_Raises (P : Parameters) return Boolean is
      B : Boolean;
   begin
      B := Multiplier_Condition (P);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Mult_Cond_Raises;

   function Four_Cond_Raises (P : Parameters) return Boolean is
      B : Boolean;
   begin
      B := Four_Condition (P);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Four_Cond_Raises;

   function PF_Raises (D, M : Value) return Boolean is
      B : Boolean;
   begin
      B := Prime_Factors_Divide (D, M);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end PF_Raises;

   type Value_Array is array (Positive range <>) of Value;

   function Sequence_Matches
     (P : Parameters; Seed : Value; Expected : Value_Array) return Boolean
   is
      G : Generator := Create (P, Seed);
      X : Value;
   begin
      for I in Expected'Range loop
         X := Next (G);
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
      First : constant Value := Next (G);
      X     : Value;
   begin
      for K in 1 .. Limit loop
         X := Next (G);
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
         X := Next (G);
         if X >= P.M then
            return False;
         end if;
      end loop;
      return True;
   end All_In_Range;

   function Floats_In_Unit
     (P : Parameters; Seed : Value; Count : Positive) return Boolean
   is
      G : Generator := Create (P, Seed);
      F : Long_Float;
   begin
      for K in 1 .. Count loop
         F := Next_Float (G);
         if F < 0.0 or else F >= 1.0 then
            return False;
         end if;
      end loop;
      return True;
   end Floats_In_Unit;

   function Params_Equal (A, B : Parameters) return Boolean is
     (A.A = B.A and then A.C = B.C and then A.M = B.M);

   Tiny_Full : constant Parameters := (A => 4, C => 1, M => 9);
   Tiny_8    : constant Parameters := (A => 5, C => 1, M => 8);
   Counter   : constant Parameters := (A => 1, C => 1, M => 10);
   Tiny_Bad  : constant Parameters := (A => 2, C => 1, M => 9);
   Weyl      : constant Parameters := (A => 1, C => 3, M => 10);

   G          : Generator;
   P          : Parameters;
   X, Y, Z    : Value;
   F, F2      : Long_Float;
   B          : Boolean;
   Uninit     : Generator;

begin
   -----------------------------------------------------------------
   Section ("1. Invalid_Argument (M = 0 / bad params / bad seed)");
   -----------------------------------------------------------------
   P := (A => 1, C => 0, M => 0);
   Check (not Is_Valid_Parameters (P), "M=0 invalid");
   Check (Create_Raises (P, 0), "Create M=0");
   Check (HD_Raises (P), "HD M=0");
   Check (Inc_Coprime_Raises (P), "Inc M=0");
   Check (Mult_Cond_Raises (P), "Mult M=0");
   Check (Four_Cond_Raises (P), "Four M=0");
   Check (Step_Raises (0, P), "Step M=0");

   P := (A => 1, C => 0, M => 1);
   Check (not Is_Valid_Parameters (P), "M=1 invalid");
   Check (Create_Raises (P, 0), "Create M=1");

   P := (A => 0, C => 1, M => 10);
   Check (not Is_Valid_Parameters (P), "A=0 invalid");
   Check (Create_Raises (P, 0), "Create A=0");

   P := (A => 10, C => 1, M => 10);
   Check (not Is_Valid_Parameters (P), "A=M invalid");
   Check (Create_Raises (P, 0), "Create A=M");

   P := (A => 11, C => 1, M => 10);
   Check (Is_Valid_Parameters (P), "A>M reduced a=1 valid");
   Check (Reduce (P).A = 1 and then Reduce (P).C = 1, "Reduce A=11 m=10");
   G := Create (P, 0);
   Check (Next (G) = 1, "unreduced A=11 acts as a=1");

   P := (A => 3, C => 10, M => 10);
   Check (Is_Valid_Parameters (P), "C=M reduced c=0 valid");
   Check (Reduce (P).C = 0, "Reduce C=M");

   P := (A => 3, C => 11, M => 10);
   Check (Is_Valid_Parameters (P), "C>M reduced c=1 valid");
   Check (Reduce (P).C = 1, "Reduce C=11 m=10");

   Check (Create_Raises (Tiny_Full, 9), "seed = M");
   Check (Create_Raises (Tiny_Full, 10), "seed > M");
   Check (Create_Raises (Tiny_Full, V (100)), "seed >> M");

   G := Create (Tiny_Full, 0);
   Check (Reset_Raises (G, 9), "Reset seed = M");
   Check (Reset_Raises (G, 20), "Reset seed > M");
   Check (Step_Raises (9, Tiny_Full), "Step state = M");
   Check (Step_Raises (15, Tiny_Full), "Step state > M");

   Check (Add_Mod_Raises (1, 2, 0), "Add_Mod M=0");
   Check (Mul_Mod_Raises (1, 2, 0), "Mul_Mod M=0");
   Check (PF_Raises (4, 0), "Prime_Factors_Divide M=0");

   Check (Next_Raises (Uninit), "Next uninit");
   Check (Next_Float_Raises (Uninit), "Next_Float uninit");
   Check (Reset_Raises (Uninit, 0), "Reset uninit");

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
   X := Next (G);
   Check (X = 1, "tiny_full X1");
   Check (Get_State (G) = 1, "tiny_full state after X1");
   Check (Period_Of (Tiny_Full, 0, 20) = Nat (9), "tiny_full period 9");
   Check (All_In_Range (Tiny_Full, 0, 40), "tiny_full in range");

   --  Every seed yields a permutation of 0 .. 8 over one period.
   for S in 0 .. 8 loop
      declare
         Seen : array (0 .. 8) of Boolean := [others => False];
         GG   : Generator := Create (Tiny_Full, V (Long_Long_Integer (S)));
         W    : Value;
         Ok   : Boolean := True;
      begin
         for K in 1 .. 9 loop
            W := Next (GG);
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
   --  Low bit alternates on full-period power-of-two LCGs.
   G := Create (Tiny_8, 0);
   X := Next (G);
   Y := Next (G);
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
   Check (Next (G) = 3, "Weyl X1");
   Check (Next (G) = 6, "Weyl X2");
   Check (Next (G) = 9, "Weyl X3");
   Check (Next (G) = 2, "Weyl X4");

   -----------------------------------------------------------------
   Section ("5. Reset / determinism / independent generators");
   -----------------------------------------------------------------
   G := Create (Tiny_Full, 3);
   X := Next (G);
   Y := Next (G);
   Reset (G, 3);
   Check (Get_State (G) = 3, "reset state");
   Check (Get_Seed (G) = 3, "reset seed");
   Check (Next (G) = X, "reset X1");
   Check (Next (G) = Y, "reset X2");

   declare
      G1 : Generator := Create (Tiny_Full, 1);
      G2 : Generator := Create (Tiny_Full, 1);
      G3 : Generator := Create (Tiny_Full, 2);
   begin
      Check (Next (G1) = Next (G2), "independent same seed");
      Check (Next (G1) = Next (G2), "independent same seed 2");
      X := Next (G3);
      Check (X < 9, "independent other seed ran");
      Check (Get_Parameters (G1).M = 9, "params M");
      Check (Get_Parameters (G1).A = 4, "params A");
      Check (Get_Parameters (G1).C = 1, "params C");
   end;

   --  Copy preserves state.
   G := Create (Tiny_8, 5);
   X := Next (G);
   declare
      G_Copy : constant Generator := G;
   begin
      Check (Get_State (G_Copy) = X, "copy state");
      Check (Next (G) = Step (X, Tiny_8), "copy then next");
   end;

   -----------------------------------------------------------------
   Section ("6. Next_Float in [0, 1)");
   -----------------------------------------------------------------
   Check (Floats_In_Unit (Tiny_Full, 0, 30), "tiny_full floats");
   Check (Floats_In_Unit (Tiny_8, 0, 20), "tiny_8 floats");
   Check (Floats_In_Unit (Glibc, 1, 20), "glibc floats");
   Check (Floats_In_Unit (Park_Miller, 1, 20), "minstd floats");
   Check (Floats_In_Unit (Numerical_Recipes, 1, 10), "NR floats");
   Check (Floats_In_Unit (Java_Util_Random, 0, 8), "java floats");

   G := Create (Tiny_Full, 0);
   X := Next (G);
   Reset (G, 0);
   F := Next_Float (G);
   Check (F >= 0.0 and then F < 1.0, "float range first");
   Check (abs (F - Long_Float (X) / 9.0) < 1.0E-12, "float = X/M");

   G := Create (Counter, 0);
   F := Next_Float (G);   -- X=1, 1/10
   Check (abs (F - 0.1) < 1.0E-12, "counter float 0.1");
   F := Next_Float (G);
   Check (abs (F - 0.2) < 1.0E-12, "counter float 0.2");

   -----------------------------------------------------------------
   Section ("7. Park–Miller MINSTD known sequence");
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

   --  MCG with seed 0 is a fixed point.
   G := Create (Park_Miller, 0);
   Check (Next (G) = 0, "PM seed0 stays 0");
   Check (Next (G) = 0, "PM seed0 stays 0 again");

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
   Section ("8. glibc / ANSI C known sequence");
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
   Section ("9. Numerical Recipes / Borland / MSVC / Delphi / VB");
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
   Check (Microsoft_Visual_Basic.A > Microsoft_Visual_Basic.M, "VB A>M published");
   Check (Reduce (Microsoft_Visual_Basic).A /= 0, "VB reduced A");
   Check (Sequence_Matches
            (Microsoft_Visual_Basic, 1,
             [12_640_960, 8_124_035, 4_294_458, 3_961_109]),
          "VB sequence");

   -----------------------------------------------------------------
   Section ("10. Java / RANDU / VMS / ZX81");
   -----------------------------------------------------------------
   Check (Hull_Dobell_Satisfied (Java_Util_Random), "Java HD");
   Check (Java_Util_Random.M = 2 ** 48, "Java M=2^48");
   Check (Sequence_Matches
            (Java_Util_Random, 0,
             [11,
              277_363_943_098,
              11_718_085_204_285,
              49_720_483_695_876,
              102_626_409_374_399]),
          "Java seed0 sequence");
   Check (All_In_Range (Java_Util_Random, 0, 20), "Java in range");

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
   X := Next (G);
   Check (X = Step (1, VMS_MTH_Random), "VMS Step vs Next");

   Check (Is_Valid_Parameters (ZX81), "ZX81 valid");
   Check (Sequence_Matches
            (ZX81, 0, [74, 5_624, 28_652, 51_790, 17_641, 12_409, 13_231, 9_344]),
          "ZX81 sequence");
   Check (All_In_Range (ZX81, 0, 30), "ZX81 in range");

   -----------------------------------------------------------------
   Section ("11. Built-in parameter-set validity");
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
   Check (Is_Valid_Parameters (Java_Util_Random), "valid Java");
   Check (Is_Valid_Parameters (VMS_MTH_Random), "valid VMS");
   Check (Is_Valid_Parameters (ZX81), "valid ZX81");

   Check (Numerical_Recipes.M = 2 ** 32, "NR M");
   Check (Glibc.M = 2 ** 31, "glibc M");
   Check (Park_Miller.M = 2 ** 31 - 1, "PM M");
   Check (RANDU.A = 65_539, "RANDU A");
   Check (ZX81.M = 65_537, "ZX81 M");
   Check (Microsoft_Visual_Basic.M = 2 ** 24, "VB M");

   -----------------------------------------------------------------
   Section ("12. Hull–Dobell component conditions");
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

   --  a ≡ 1 (mod 8) fails the “not more than necessary” spectral
   --  advice but still satisfies Hull–Dobell when c is odd.
   declare
      Weak : constant Parameters := (A => 9, C => 1, M => 16);
   begin
      Check (Is_Valid_Parameters (Weak), "weak valid");
      Check (Hull_Dobell_Satisfied (Weak), "weak HD still true");
      Check (Period_Of (Weak, 0, 40) = Nat (16), "weak period 16");
   end;

   --  a ≡ 1 (mod 2) but not (mod 4) with m divisible by 4 fails (3).
   declare
      Fail4 : constant Parameters := (A => 3, C => 1, M => 8);
   begin
      Check (Increment_Coprime (Fail4), "fail4 coprime");
      Check (Multiplier_Condition (Fail4), "fail4 primes (only 2)");
      Check (not Four_Condition (Fail4), "fail4 four fails");
      Check (not Hull_Dobell_Satisfied (Fail4), "fail4 not HD");
   end;

   -----------------------------------------------------------------
   Section ("13. GCD / coprime / prime-factor helper");
   -----------------------------------------------------------------
   Check (Gcd (0, 0) = 0, "gcd(0,0)");
   Check (Gcd (0, 12) = 12, "gcd(0,12)");
   Check (Gcd (12, 0) = 12, "gcd(12,0)");
   Check (Gcd (12, 8) = 4, "gcd(12,8)");
   Check (Gcd (17, 13) = 1, "gcd(17,13)");
   Check (Gcd (21, 14) = 7, "gcd(21,14)");
   Check (Gcd (100, 25) = 25, "gcd(100,25)");
   Check (Gcd (7, 7) = 7, "gcd(7,7)");
   Check (Are_Coprime (7, 13), "coprime 7,13");
   Check (not Are_Coprime (12, 8), "not coprime 12,8");
   Check (Are_Coprime (1, 99), "coprime 1,99");
   Check (not Are_Coprime (0, 10), "not coprime 0,10");
   Check (Are_Coprime (1, 0), "coprime 1,0");

   Check (Prime_Factors_Divide (3, 9), "3 | primes of 9");
   Check (not Prime_Factors_Divide (1, 9), "1 does not cover 9");
   Check (Prime_Factors_Divide (4, 8), "4 | primes of 8");
   Check (Prime_Factors_Divide (2, 8), "2 | primes of 8");
   Check (not Prime_Factors_Divide (2, 10), "2 misses 5 of 10");
   Check (Prime_Factors_Divide (10, 10), "10 | primes of 10");
   Check (Prime_Factors_Divide (1, 1), "M=1 no primes");
   Check (Prime_Factors_Divide (0, 15), "0 divisible by 3,5");
   Check (Prime_Factors_Divide (6, 18), "6 | 2 and 3");
   Check (not Prime_Factors_Divide (4, 18), "4 misses 3");

   -----------------------------------------------------------------
   Section ("14. Add_Mod / Mul_Mod / Step overflow-safe");
   -----------------------------------------------------------------
   Check (Add_Mod (3, 5, 7) = 1, "3+5 mod 7");
   Check (Add_Mod (6, 6, 7) = 5, "6+6 mod 7");
   Check (Add_Mod (0, 0, 7) = 0, "0+0 mod 7");
   Check (Add_Mod (1, 0, 7) = 1, "1+0 mod 7");
   Check (Mul_Mod (3, 5, 7) = 1, "3*5 mod 7");
   Check (Mul_Mod (6, 6, 7) = 1, "6*6 mod 7");
   Check (Mul_Mod (0, 5, 7) = 0, "0*5 mod 7");
   Check (Add_Mod (1, 2, 1) = 0, "add mod 1");
   Check (Mul_Mod (5, 9, 1) = 0, "mul mod 1");

   --  Product that overflows 32-bit and 64-bit naive multiply.
   --  (2^32-1)^2 = 2^64 - 2^33 + 1, reduced mod (2^32-1) = 0? 
   --  (M-1)*(M-1) mod M = 1 for M>1.
   Check (Mul_Mod (2 ** 32 - 1, 2 ** 32 - 1, 2 ** 32) = 1,
          "(2^32-1)^2 mod 2^32");
   Check (Mul_Mod (2 ** 31 - 1, 16_807, 2 ** 31 - 1) = 0,
          "PM mul of M-1");
   --  Large Java-sized multiply.
   X := Mul_Mod (25_214_903_917, 11, 2 ** 48);
   Check (X = (V (25_214_903_917) * 11) rem (2 ** 48),
          "java-sized mul");

   Check (Step (0, Tiny_Full) = 1, "Step(0)");
   Check (Step (1, Tiny_Full) = 5, "Step(1)");
   Check (Step (5, Tiny_Full) = 3, "Step(5)");
   Check (Step (0, Park_Miller) = 0, "Step PM 0");
   Check (Step (1, Park_Miller) = 16_807, "Step PM 1");

   --  Add near the top of a large modulus (no wrap-before-reduce).
   Check (Add_Mod (2 ** 32 - 1, 1, 2 ** 32) = 0, "add wrap 2^32");
   Check (Add_Mod (2 ** 32 - 2, 5, 2 ** 32) = 3, "add wrap 2^32+3");

   -----------------------------------------------------------------
   Section ("15. Inspectors after Create / many Next");
   -----------------------------------------------------------------
   G := Create (Glibc, 42);
   Check (Get_Seed (G) = 42, "seed 42");
   Check (Get_State (G) = 42, "state 42");
   Check (Params_Equal (Get_Parameters (G), Glibc), "params glibc");
   X := Next (G);
   Check (Get_State (G) = X, "state tracks Next");
   Check (Get_Seed (G) = 42, "seed unchanged");
   Reset (G, 7);
   Check (Get_Seed (G) = 7, "seed after reset");
   Check (Get_State (G) = 7, "state after reset");

   Check (All_In_Range (Numerical_Recipes, 99, 80), "NR many");
   Check (All_In_Range (Borland_C, 123, 40), "Borland many");
   Check (All_In_Range (Microsoft_Visual_C, 1, 40), "MSVC many");
   Check (All_In_Range (MINSTD_Rand, 1, 40), "minstd many");
   Check (All_In_Range (ZX81, 1, 100), "ZX81 many");

   -----------------------------------------------------------------
   Section ("16. Step agrees with Next for several parameter sets");
   -----------------------------------------------------------------
   declare
      Sets : constant array (1 .. 8) of Parameters :=
        [Tiny_Full, Tiny_8, Glibc, Park_Miller, Numerical_Recipes,
         Java_Util_Random, RANDU, ZX81];
      Seeds : constant array (1 .. 8) of Value :=
        [0, 0, 1, 1, 1, 0, 1, 0];
   begin
      for I in Sets'Range loop
         G := Create (Sets (I), Seeds (I));
         X := Get_State (G);
         for K in 1 .. 5 loop
            Y := Step (X, Sets (I));
            Z := Next (G);
            Check (Y = Z,
                   "Step=Next set" & Integer'Image (I)
                   & " k" & Integer'Image (K));
            X := Z;
         end loop;
      end loop;
   end;

   -----------------------------------------------------------------
   Section ("17. Next_Float vs Next / M  (small moduli)");
   -----------------------------------------------------------------
   G := Create (Tiny_8, 0);
   for K in 1 .. 8 loop
      declare
         GG : Generator := G;
      begin
         X := Next (G);
         F := Next_Float (GG);
         Check (abs (F - Long_Float (X) / 8.0) < 1.0E-12,
                "float vs X/8 k" & Integer'Image (K));
      end;
   end loop;

   G := Create (ZX81, 0);
   for K in 1 .. 6 loop
      declare
         GG : Generator := G;
      begin
         X := Next (G);
         F := Next_Float (GG);
         Check (abs (F - Long_Float (X) / 65_537.0) < 1.0E-12,
                "float vs ZX81 k" & Integer'Image (K));
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("18. Period / range batch on tiny mixed LCGs");
   -----------------------------------------------------------------
   --  Full-period family: m = 16, a = 5, odd c.
   for C_Inc in 1 .. 15 loop
      if C_Inc rem 2 = 1 then
         P := (A => 5, C => V (Long_Long_Integer (C_Inc)), M => 16);
         Check (Hull_Dobell_Satisfied (P),
                "m16 a5 c" & Integer'Image (C_Inc) & " HD");
         Check (Period_Of (P, 0, 40) = Nat (16),
                "m16 a5 c" & Integer'Image (C_Inc) & " period");
      end if;
   end loop;

   -----------------------------------------------------------------
   Section ("19. Custom parameters + MCG vs mixed");
   -----------------------------------------------------------------
   P := (A => 7, C => 0, M => 11);  -- 7 primitive mod 11?
   Check (Is_Valid_Parameters (P), "MCG 11 valid");
   Check (not Hull_Dobell_Satisfied (P), "MCG 11 not HD");
   G := Create (P, 1);
   Check (Next (G) = 7, "7*1 mod 11");
   Check (Next (G) = 5, "7*7 mod 11");  -- 49 rem 11 = 5
   Check (Next (G) = 2, "7*5 mod 11");  -- 35 rem 11 = 2

   P := (A => 7, C => 1, M => 11);
   Check (not Hull_Dobell_Satisfied (P), "7-1=6 not div by 11");
   P := (A => 12, C => 1, M => 11);
   Check (Hull_Dobell_Satisfied (P), "a=12 c=1 m=11 HD");
   Check (Period_Of (P, 0, 20) = Nat (11), "m=11 full period");

   -----------------------------------------------------------------
   Section ("20. Float endpoints and monotonic mapping");
   -----------------------------------------------------------------
   --  Counter from seed 0: values 1/10, 2/10, … never 1.0
   G := Create (Counter, 0);
   F2 := -1.0;
   B := True;
   for K in 1 .. 9 loop
      F := Next_Float (G);
      if F <= F2 or else F >= 1.0 then
         B := False;
      end if;
      F2 := F;
   end loop;
   Check (B, "counter floats increasing in [0,1)");
   F := Next_Float (G);  -- X = 0
   Check (F = 0.0, "counter wraps to 0.0");

   -----------------------------------------------------------------
   Section ("21. More Invalid_Argument edges");
   -----------------------------------------------------------------
   P := (A => 1, C => 0, M => 2);
   Check (Is_Valid_Parameters (P), "minimal valid a=1 c=0 m=2");
   Check (not Hull_Dobell_Satisfied (P), "minimal MCG not HD");
   G := Create (P, 1);
   Check (Next (G) = 1, "a=1 c=0 stays");
   Check (Create_Raises (P, 2), "seed 2 >= m=2");

   P := (A => 1, C => 1, M => 2);
   Check (Hull_Dobell_Satisfied (P), "m=2 a=1 c=1 HD");
   Check (Period_Of (P, 0, 5) = Nat (2), "m=2 period 2");

   P := (A => Value'Last, C => 0, M => 2);
   Check (Is_Valid_Parameters (P), "A=Value'Last rem 2 = 1");
   Check (Reduce (P).A = 1, "Value'Last reduces to 1");

   -----------------------------------------------------------------
   Section ("22. Glibc / NR Reset reproducibility");
   -----------------------------------------------------------------
   G := Create (Glibc, 99);
   declare
      Buf : array (1 .. 8) of Value;
   begin
      for I in Buf'Range loop
         Buf (I) := Next (G);
      end loop;
      Reset (G, 99);
      B := True;
      for I in Buf'Range loop
         if Next (G) /= Buf (I) then
            B := False;
         end if;
      end loop;
      Check (B, "glibc reset replay");
   end;

   G := Create (Numerical_Recipes, 12345);
   X := Next (G);
   Y := Next (G);
   Reset (G, 12345);
   Check (Next (G) = X and then Next (G) = Y, "NR reset replay");

   -----------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
