--  Standalone test suite for Miller_Rabin (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Miller_Rabin; use Miller_Rabin;

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

   function Trial_Is_Prime (N : U64) return Boolean is
   begin
      if N < 2 then
         return False;
      end if;
      if N = 2 or else N = 3 then
         return True;
      end if;
      if (N and 1) = 0 then
         return False;
      end if;
      declare
         D : U64 := 3;
      begin
         while D * D <= N loop
            if N rem D = 0 then
               return False;
            end if;
            D := D + 2;
         end loop;
         return True;
      end;
   end Trial_Is_Prime;

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

   procedure Expect_Invalid_Witness (Label : String; N, A : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Boolean := Is_Composite_Witness (N, A);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Witness: " & Label);
   end Expect_Invalid_Witness;

   procedure Expect_Invalid_Split (Label : String; N : U64) is
      Raised : Boolean := False;
      S      : Natural;
      D      : U64;
   begin
      begin
         Trial_Split_N_Minus_1 (N, S, D);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Split: " & Label);
   end Expect_Invalid_Split;

begin
   Ada.Text_IO.Put_Line ("Miller_Rabin test suite");
   Ada.Text_IO.Put_Line ("=======================");

   ------------------------------------------------------------------
   Section ("1. Mul_Mod / Mod_Pow");
   ------------------------------------------------------------------
   Check (Mul_Mod (U (3), U (4), U (5)) = 2, "Mul_Mod 3*4 mod 5 = 2");
   Check (Mul_Mod (U (7), U (8), U (9)) = 2, "Mul_Mod 7*8 mod 9 = 2");
   Check (Mul_Mod (U (0), U (99), U (17)) = 0, "Mul_Mod 0");
   Check (Mul_Mod (U (1), U (1), U (1)) = 0, "Mul_Mod mod 1");
   --  Large factors near 2^64 that would overflow naïve U64 multiply
   Check
     (Mul_Mod (U (2**32), U (2**32), U (1_000_000_007)) = 582_344_008,
      "Mul_Mod large 2^32*2^32");
   Check
     (Mul_Mod (U (18_446_744_073_709_551_615), U (2), U (1_000_003)) =
        ((U (18_446_744_073_709_551_615) rem 1_000_003) * 2) rem 1_000_003,
      "Mul_Mod U64'Last * 2");

   Check (Mod_Pow (U (2), U (10), U (1000)) = 24, "Mod_Pow 2^10 mod 1000");
   Check (Mod_Pow (U (3), U (5), U (13)) = 9, "Mod_Pow 3^5 mod 13");
   Check (Mod_Pow (U (2), U (0), U (5)) = 1, "Mod_Pow exp 0");
   Check (Mod_Pow (U (5), U (1), U (7)) = 5, "Mod_Pow exp 1");
   Check (Mod_Pow (U (2), U (31), U (2_147_483_647)) = 1,
          "Mod_Pow 2^31 mod Mersenne31 = 1");
   Check (Mod_Pow (U (10), U (9), U (1)) = 0, "Mod_Pow mod 1");
   Expect_Invalid_Mod_Pow ("modulus 0", U (2), U (3), U (0));

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Mul_Mod (U (1), U (1), U (0));
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Mul_Mod M=0");
   end;

   ------------------------------------------------------------------
   Section ("2. Trial_Split_N_Minus_1");
   ------------------------------------------------------------------
   declare
      S : Natural;
      D : U64;
   begin
      Trial_Split_N_Minus_1 (U (2), S, D);
      Check (S = 0 and then D = 1, "split 2 → 2^0*1");
      Trial_Split_N_Minus_1 (U (3), S, D);
      Check (S = 1 and then D = 1, "split 3 → 2^1*1");
      Trial_Split_N_Minus_1 (U (17), S, D);
      Check (S = 4 and then D = 1, "split 17 → 2^4*1");
      Trial_Split_N_Minus_1 (U (97), S, D);
      Check (S = 5 and then D = 3, "split 97 → 2^5*3");
      Trial_Split_N_Minus_1 (U (2047), S, D);
      Check (S = 1 and then D = 1023, "split 2047 → 2^1*1023");
      Trial_Split_N_Minus_1 (U (561), S, D);
      Check (S = 4 and then D = 35, "split 561 → 2^4*35");
   end;
   Expect_Invalid_Split ("N=0", U (0));
   Expect_Invalid_Split ("N=1", U (1));

   ------------------------------------------------------------------
   Section ("3. Small primes");
   ------------------------------------------------------------------
   Check (Is_Prime_Deterministic_64 (U (2)), "det 2");
   Check (Is_Prime_Deterministic_64 (U (3)), "det 3");
   Check (Is_Prime_Deterministic_64 (U (5)), "det 5");
   Check (Is_Prime_Deterministic_64 (U (7)), "det 7");
   Check (Is_Prime_Deterministic_64 (U (97)), "det 97");
   Check (Is_Prime_Deterministic_64 (U (2_147_483_647)), "det Mersenne31");
   Check (Is_Probable_Prime (U (2)), "prob 2");
   Check (Is_Probable_Prime (U (3)), "prob 3");
   Check (Is_Probable_Prime (U (5)), "prob 5");
   Check (Is_Probable_Prime (U (7)), "prob 7");
   Check (Is_Probable_Prime (U (97)), "prob 97");
   Check (Is_Probable_Prime (U (2_147_483_647)), "prob Mersenne31");
   Check (Is_Probable_Prime (U (13), 1), "prob 13 rounds=1");
   Check (Is_Probable_Prime (U (101), 4), "prob 101 rounds=4");

   ------------------------------------------------------------------
   Section ("4. Composites / Carmichael");
   ------------------------------------------------------------------
   Check (not Is_Prime_Deterministic_64 (U (0)), "det 0 not prime");
   Check (not Is_Prime_Deterministic_64 (U (1)), "det 1 not prime");
   Check (not Is_Prime_Deterministic_64 (U (4)), "det 4");
   Check (not Is_Prime_Deterministic_64 (U (9)), "det 9");
   Check (not Is_Prime_Deterministic_64 (U (15)), "det 15");
   Check (not Is_Prime_Deterministic_64 (U (91)), "det 91=7*13");
   Check (not Is_Prime_Deterministic_64 (U (561)), "det Carmichael 561");
   Check (not Is_Prime_Deterministic_64 (U (1105)), "det 1105");
   Check (not Is_Probable_Prime (U (0)), "prob 0");
   Check (not Is_Probable_Prime (U (1)), "prob 1");
   Check (not Is_Probable_Prime (U (4)), "prob 4");
   Check (not Is_Probable_Prime (U (9)), "prob 9");
   Check (not Is_Probable_Prime (U (15)), "prob 15");
   Check (not Is_Probable_Prime (U (91)), "prob 91");
   Check (not Is_Probable_Prime (U (561), 8), "prob Carmichael 561");
   Check (not Is_Probable_Prime (U (1105), 8), "prob 1105");
   Check (not Is_Probable_Prime (U (6)), "prob 6");
   Check (not Is_Probable_Prime (U (25)), "prob 25");
   Check (not Is_Probable_Prime (U (49)), "prob 49");
   Check (not Is_Probable_Prime (U (121)), "prob 121");

   ------------------------------------------------------------------
   Section ("5. Classic 2047 = 23*89");
   ------------------------------------------------------------------
   --  2047 is a strong pseudoprime to base 2 (A^D ≡ 1), so a=2 is a
   --  *liar*, not a witness. Classic sheet often confuses this with Fermat;
   --  Miller–Rabin needs another base (e.g. 3).
   Check (not Is_Composite_Witness (U (2047), U (2)),
          "a=2 does NOT witness 2047 (strong PSP base 2)");
   Check (Is_Composite_Witness (U (2047), U (3)),
          "a=3 proves 2047=23*89 composite");
   Check (not Is_Prime_Deterministic_64 (U (2047)), "det 2047 composite");
   Check (not Is_Probable_Prime (U (2047)), "prob 2047 composite");
   Check (Is_Probable_Prime (U (2047), 1),
          "prob 2047 rounds=1 (only base 2) falsely probable");

   ------------------------------------------------------------------
   Section ("6. Witness edge / A mod N = 0");
   ------------------------------------------------------------------
   Expect_Invalid_Witness ("N=0", U (0), U (2));
   Expect_Invalid_Witness ("N=1", U (1), U (2));
   Check (not Is_Composite_Witness (U (2), U (1)), "witness 2,a=1 → False");
   Check (not Is_Composite_Witness (U (2), U (2)), "witness 2,a=2 → A mod N=0");
   Check (not Is_Composite_Witness (U (97), U (97)),
          "A mod N = 0 → False (invalid base)");
   Check (not Is_Composite_Witness (U (97), U (194)),
          "A=194 mod 97=0 → False");
   Check (Is_Composite_Witness (U (15), U (2)), "witness 15 base 2");
   Check (Is_Composite_Witness (U (9), U (2)), "witness 9 base 2");
   Check (Is_Composite_Witness (U (8), U (3)), "even N>2 → True");
   Check (not Is_Composite_Witness (U (7), U (2)), "7 is SPRP base 2");
   Check (not Is_Composite_Witness (U (97), U (2)), "97 SPRP base 2");
   Check (not Is_Composite_Witness (U (97), U (1)), "trivial base 1");
   Check (not Is_Composite_Witness (U (97), U (96)), "trivial base N-1");

   ------------------------------------------------------------------
   Section ("7. Deterministic vs trial division N ≤ 10_000");
   ------------------------------------------------------------------
   declare
      Mismatches : Natural := 0;
      Checked    : Natural := 0;
   begin
      for N in U64 range 0 .. 10_000 loop
         declare
            Det   : constant Boolean := Is_Prime_Deterministic_64 (N);
            Trial : constant Boolean := Trial_Is_Prime (N);
         begin
            Checked := Checked + 1;
            if Det /= Trial then
               Mismatches := Mismatches + 1;
            end if;
         end;
      end loop;
      Check (Mismatches = 0,
             "det matches trial for all N in 0..10000");
      Check (Checked = 10_001, "checked 10001 values");
   end;

   ------------------------------------------------------------------
   Section ("8. Probable_Prime vs trial (sample) / more primes");
   ------------------------------------------------------------------
   declare
      Mismatches : Natural := 0;
   begin
      for N in U64 range 0 .. 5_000 loop
         if Is_Probable_Prime (N, 8) /= Trial_Is_Prime (N) then
            Mismatches := Mismatches + 1;
         end if;
      end loop;
      Check (Mismatches = 0, "prob(8) matches trial for N in 0..5000");
   end;

   Check (Is_Prime_Deterministic_64 (U (11)), "det 11");
   Check (Is_Prime_Deterministic_64 (U (13)), "det 13");
   Check (Is_Prime_Deterministic_64 (U (17)), "det 17");
   Check (Is_Prime_Deterministic_64 (U (19)), "det 19");
   Check (Is_Prime_Deterministic_64 (U (23)), "det 23");
   Check (Is_Prime_Deterministic_64 (U (29)), "det 29");
   Check (Is_Prime_Deterministic_64 (U (31)), "det 31");
   Check (Is_Prime_Deterministic_64 (U (37)), "det 37");
   Check (Is_Prime_Deterministic_64 (U (41)), "det 41");
   Check (Is_Prime_Deterministic_64 (U (43)), "det 43");
   Check (Is_Prime_Deterministic_64 (U (47)), "det 47");
   Check (Is_Prime_Deterministic_64 (U (53)), "det 53");
   Check (Is_Prime_Deterministic_64 (U (59)), "det 59");
   Check (Is_Prime_Deterministic_64 (U (61)), "det 61");
   Check (Is_Prime_Deterministic_64 (U (67)), "det 67");
   Check (Is_Prime_Deterministic_64 (U (71)), "det 71");
   Check (Is_Prime_Deterministic_64 (U (73)), "det 73");
   Check (Is_Prime_Deterministic_64 (U (79)), "det 79");
   Check (Is_Prime_Deterministic_64 (U (83)), "det 83");
   Check (Is_Prime_Deterministic_64 (U (89)), "det 89");

   ------------------------------------------------------------------
   Section ("9. Larger known primes / composites");
   ------------------------------------------------------------------
   Check (Is_Prime_Deterministic_64 (U (1_000_003)), "det 1000003 prime");
   Check (not Is_Prime_Deterministic_64 (U (1_000_001)),
          "det 1000001 composite");
   Check (Is_Prime_Deterministic_64 (U (999_983)), "det 999983 prime");
   Check (not Is_Prime_Deterministic_64 (U (994_007)),
          "det 994007 composite");
   --  994007 = 991 * 1003? Let me use known composites
   Check (not Is_Prime_Deterministic_64 (U (1_000_000)), "det 10^6");
   Check (not Is_Prime_Deterministic_64 (U (512)), "det 512");
   Check (Is_Prime_Deterministic_64 (U (65537)), "det Fermat F4=65537");
   Check (not Is_Prime_Deterministic_64 (U (65535)), "det 65535");
   Check (Is_Probable_Prime (U (65537), 5), "prob Fermat F4");
   Check (not Is_Probable_Prime (U (561), 2), "prob 561 with 2 rounds");
   Check (not Is_Probable_Prime (U (1105), 3), "prob 1105 with 3 rounds");

   --  Carmichael numbers
   Check (not Is_Prime_Deterministic_64 (U (1105)), "Carmichael 1105");
   Check (not Is_Prime_Deterministic_64 (U (1729)), "Carmichael 1729");
   Check (not Is_Prime_Deterministic_64 (U (2465)), "Carmichael 2465");
   Check (not Is_Prime_Deterministic_64 (U (2821)), "Carmichael 2821");
   Check (not Is_Prime_Deterministic_64 (U (6601)), "Carmichael 6601");
   Check (not Is_Prime_Deterministic_64 (U (8911)), "Carmichael 8911");

   ------------------------------------------------------------------
   Section ("10. Extended cross-check N ≤ 50_000");
   ------------------------------------------------------------------
   declare
      Mismatches : Natural := 0;
   begin
      for N in U64 range 0 .. 50_000 loop
         if Is_Prime_Deterministic_64 (N) /= Trial_Is_Prime (N) then
            Mismatches := Mismatches + 1;
         end if;
      end loop;
      Check (Mismatches = 0,
             "det matches trial for all N in 0..50000");
   end;

   --  Spot-check a few more Mod_Pow identities
   Check (Mod_Pow (U (2), U (8), U (257)) = 256, "2^8 mod 257 = 256");
   Check (Mod_Pow (U (3), U (4), U (7)) = 4, "3^4 mod 7 = 4");
   Check (Mod_Pow (U (7), U (3), U (13)) = 5, "7^3 mod 13 = 5");

   ------------------------------------------------------------------
   Section ("Summary");
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
