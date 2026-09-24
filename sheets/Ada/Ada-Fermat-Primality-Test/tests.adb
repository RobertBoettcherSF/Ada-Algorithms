--  Standalone test suite for Fermat_Primality_Test (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Fermat_Primality_Test; use Fermat_Primality_Test;

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
            Unused : constant Boolean := Is_Fermat_Witness (N, A);
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

begin
   Ada.Text_IO.Put_Line ("Fermat_Primality_Test test suite");
   Ada.Text_IO.Put_Line ("================================");

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
   --  Fermat FLT spot: 2^{6} ≡ 1 (mod 7)
   Check (Mod_Pow (U (2), U (6), U (7)) = 1, "Mod_Pow FLT 2^6 mod 7");
   Check (Mod_Pow (U (3), U (4), U (5)) = 1, "Mod_Pow FLT 3^4 mod 5");
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

   Check (Gcd (U (0), U (0)) = 0, "Gcd(0,0)=0");
   Check (Gcd (U (0), U (17)) = 17, "Gcd(0,17)=17");
   Check (Gcd (U (48), U (18)) = 6, "Gcd(48,18)=6");
   Check (Gcd (U (17), U (13)) = 1, "Gcd(17,13)=1");
   Check (Gcd (U (561), U (2)) = 1, "Gcd(561,2)=1");
   Check (Gcd (U (561), U (3)) = 3, "Gcd(561,3)=3");
   Check (Gcd (U (15), U (25)) = 5, "Gcd(15,25)=5");

   ------------------------------------------------------------------
   Section ("2. Small primes pass Fermat bases 2, 3");
   ------------------------------------------------------------------
   Check (not Is_Fermat_Witness (U (2), U (1)), "witness 2 base 1 False");
   Check (not Is_Fermat_Witness (U (3), U (2)), "witness 3 base 2 False");
   Check (not Is_Fermat_Witness (U (5), U (2)), "witness 5 base 2 False");
   Check (not Is_Fermat_Witness (U (5), U (3)), "witness 5 base 3 False");
   Check (not Is_Fermat_Witness (U (7), U (2)), "witness 7 base 2 False");
   Check (not Is_Fermat_Witness (U (7), U (3)), "witness 7 base 3 False");
   Check (not Is_Fermat_Witness (U (97), U (2)), "witness 97 base 2 False");
   Check (not Is_Fermat_Witness (U (97), U (3)), "witness 97 base 3 False");

   Check (Is_Fermat_Probable_Prime (U (2)), "prob 2");
   Check (Is_Fermat_Probable_Prime (U (3)), "prob 3");
   Check (Is_Fermat_Probable_Prime (U (5)), "prob 5");
   Check (Is_Fermat_Probable_Prime (U (7)), "prob 7");
   Check (Is_Fermat_Probable_Prime (U (97)), "prob 97");
   Check (Is_Fermat_Probable_Prime (U (2), 1), "prob 2 rounds=1");
   Check (Is_Fermat_Probable_Prime (U (13), 2), "prob 13 rounds=2");
   Check (Is_Fermat_Probable_Prime (U (101), 4), "prob 101 rounds=4");
   Check (Is_Fermat_Probable_Prime (U (2_147_483_647)), "prob Mersenne31");

   declare
      Bases_2_3 : constant Base_List := [2, 3];
   begin
      Check (Is_Fermat_Probable_Prime (U (2), Bases_2_3), "prob bases 2");
      Check (Is_Fermat_Probable_Prime (U (3), Bases_2_3), "prob bases 3");
      Check (Is_Fermat_Probable_Prime (U (5), Bases_2_3), "prob bases 5");
      Check (Is_Fermat_Probable_Prime (U (7), Bases_2_3), "prob bases 7");
      Check (Is_Fermat_Probable_Prime (U (97), Bases_2_3), "prob bases 97");
   end;

   ------------------------------------------------------------------
   Section ("3. Composites fail base 2");
   ------------------------------------------------------------------
   Check (Is_Fermat_Witness (U (9), U (2)), "witness 9 base 2");
   Check (Is_Fermat_Witness (U (15), U (2)), "witness 15 base 2");
   Check (Is_Fermat_Witness (U (21), U (2)), "witness 21 base 2");
   Check (Is_Fermat_Witness (U (25), U (2)), "witness 25 base 2");
   Check (Is_Fermat_Witness (U (27), U (2)), "witness 27 base 2");
   Check (Is_Fermat_Witness (U (33), U (2)), "witness 33 base 2");
   Check (Is_Fermat_Witness (U (35), U (2)), "witness 35 base 2");
   Check (Is_Fermat_Witness (U (49), U (2)), "witness 49 base 2");
   Check (Is_Fermat_Witness (U (4), U (3)), "witness even 4");
   Check (Is_Fermat_Witness (U (8), U (3)), "witness even 8");
   Check (Is_Fermat_Witness (U (9), U (3)), "witness 9 base 3 (gcd=3)");
   Check (Is_Fermat_Witness (U (15), U (5)), "witness 15 base 5 (gcd=5)");

   Check (not Is_Fermat_Probable_Prime (U (9)), "prob 9 False");
   Check (not Is_Fermat_Probable_Prime (U (15)), "prob 15 False");
   Check (not Is_Fermat_Probable_Prime (U (21)), "prob 21 False");
   Check (not Is_Fermat_Probable_Prime (U (0)), "prob 0 False");
   Check (not Is_Fermat_Probable_Prime (U (1)), "prob 1 False");
   Check (not Is_Fermat_Probable_Prime (U (4)), "prob 4 False");
   Check (not Is_Fermat_Probable_Prime (U (100)), "prob 100 False");

   ------------------------------------------------------------------
   Section ("4. Carmichael 561 / Fermat pseudoprime 341");
   ------------------------------------------------------------------
   --  561 = 3·11·17 Carmichael: Fermat PRP to every base coprime to 561
   Check (not Trial_Is_Prime (U (561)), "trial 561 composite");
   Check (not Is_Fermat_Witness (U (561), U (2)),
          "Is_Fermat_Witness(561,2)=False (liar)");
   Check (Is_Fermat_Probable_Prime (U (561), 1),
          "561 Fermat PRP base-2 rounds=1");
   Check (Mod_Pow (U (2), U (560), U (561)) = 1, "2^560 ≡ 1 (mod 561)");
   --  Base 3 shares factor with 561 → broad witness
   Check (Is_Fermat_Witness (U (561), U (3)),
          "Is_Fermat_Witness(561,3)=True (gcd=3)");
   Check (Is_Carmichael_Example (U (561)), "Is_Carmichael_Example 561");
   Check (Is_Carmichael_Example (U (1105)), "Is_Carmichael_Example 1105");
   Check (Is_Carmichael_Example (U (1729)), "Is_Carmichael_Example 1729");
   Check (not Is_Carmichael_Example (U (341)), "341 not Carmichael");
   Check (not Is_Carmichael_Example (U (97)), "97 not Carmichael");

   --  341 = 11·31 Fermat pseudoprime to base 2
   Check (not Trial_Is_Prime (U (341)), "trial 341 composite");
   Check (not Is_Fermat_Witness (U (341), U (2)),
          "Is_Fermat_Witness(341,2)=False (psp2)");
   Check (Mod_Pow (U (2), U (340), U (341)) = 1, "2^340 ≡ 1 (mod 341)");
   Check (Is_Fermat_Witness (U (341), U (3)),
          "Is_Fermat_Witness(341,3)=True");
   Check (Is_Fermat_Probable_Prime (U (341), 1),
          "341 Fermat PRP rounds=1 (base 2 only)");
   Check (not Is_Fermat_Probable_Prime (U (341), 2),
          "341 fails Fermat rounds=2 (base 3)");

   --  Wikipedia example: 221, base 38 liar, base 24 witness
   Check (not Is_Fermat_Witness (U (221), U (38)),
          "221 base 38 Fermat liar");
   Check (Is_Fermat_Witness (U (221), U (24)),
          "221 base 24 Fermat witness");
   Check (Mod_Pow (U (38), U (220), U (221)) = 1, "38^220 ≡ 1 (mod 221)");
   Check (Mod_Pow (U (24), U (220), U (221)) = 81, "24^220 ≡ 81 (mod 221)");

   --  More Carmichael: 1105, 1729 pass base 2
   Check (not Is_Fermat_Witness (U (1105), U (2)), "1105 base 2 liar");
   Check (not Is_Fermat_Witness (U (1729), U (2)), "1729 base 2 liar");
   Check (Is_Fermat_Probable_Prime (U (1105), 1), "1105 PRP rounds=1");
   Check (Is_Fermat_Probable_Prime (U (1729), 1), "1729 PRP rounds=1");

   ------------------------------------------------------------------
   Section ("5. Soundness N≤2000 base 2 + pseudoprime count");
   ------------------------------------------------------------------
   declare
      Sound     : Boolean := True;
      Psp_Count : Natural := 0;
      N         : U64 := 2;
   begin
      while N <= 2000 loop
         if Is_Fermat_Witness (N, U (2)) then
            if Trial_Is_Prime (N) then
               Sound := False;
            end if;
         else
            --  Passed Fermat base 2 (or N=2)
            if N > 2 and then not Trial_Is_Prime (N) then
               --  Composite that is not a Fermat witness for base 2
               --  (either psp2 or even — but even always witnesses)
               if (N and 1) = 1 then
                  Psp_Count := Psp_Count + 1;
               end if;
            end if;
         end if;
         N := N + 1;
      end loop;
      Check (Sound, "soundness: Fermat fail base 2 ⇒ composite (N≤2000)");
      --  Known odd Fermat psp to base 2 below 2000 include at least
      --  341, 561, 645, 1105, 1387, 1729, 1905 (and more).
      Check (Psp_Count >= 7,
             "≥7 odd composites pass base-2 Fermat (N≤2000)");
      Ada.Text_IO.Put_Line
        ("  INFO: odd base-2 Fermat pseudoprimes / Carmichael ≤2000: "
         & Natural'Image (Psp_Count));
   end;

   ------------------------------------------------------------------
   Section ("6. Domain / edge cases");
   ------------------------------------------------------------------
   Expect_Invalid_Witness ("N=0", U (0), U (2));
   Expect_Invalid_Witness ("N=1", U (1), U (2));
   Check (not Is_Fermat_Witness (U (7), U (0)),
          "base 0 rem 7=0 → not witness");
   Check (not Is_Fermat_Witness (U (7), U (14)),
          "base 14 rem 7=0 → not witness");
   Check (not Is_Fermat_Witness (U (7), U (1)),
          "trivial base 1 → not witness");
   Check (not Is_Fermat_Witness (U (7), U (6)),
          "trivial base N-1 → not witness");

   ------------------------------------------------------------------
   Section ("7. Cross-check primes / composites vs trial (N≤300)");
   ------------------------------------------------------------------
   declare
      Ok_Prime : Boolean := True;
      Ok_Comp  : Boolean := True;
      N        : U64 := 2;
      Bases    : constant Base_List := [2, 3, 5, 7];
   begin
      while N <= 300 loop
         if Trial_Is_Prime (N) then
            if not Is_Fermat_Probable_Prime (N, Bases) then
               Ok_Prime := False;
            end if;
         else
            --  Composites may still pass Fermat (Carmichael / psp);
            --  only check that if Fermat fails then composite (already
            --  covered). Here: no false negative for primes.
            null;
         end if;
         N := N + 1;
      end loop;
      Check (Ok_Prime, "all primes ≤300 pass Fermat bases {2,3,5,7}");
      pragma Unreferenced (Ok_Comp);
   end;

   --  Extra individual primes
   Check (Is_Fermat_Probable_Prime (U (11)), "prob 11");
   Check (Is_Fermat_Probable_Prime (U (13)), "prob 13");
   Check (Is_Fermat_Probable_Prime (U (17)), "prob 17");
   Check (Is_Fermat_Probable_Prime (U (19)), "prob 19");
   Check (Is_Fermat_Probable_Prime (U (23)), "prob 23");
   Check (Is_Fermat_Probable_Prime (U (29)), "prob 29");
   Check (Is_Fermat_Probable_Prime (U (31)), "prob 31");
   Check (Is_Fermat_Probable_Prime (U (37)), "prob 37");
   Check (Is_Fermat_Probable_Prime (U (41)), "prob 41");
   Check (Is_Fermat_Probable_Prime (U (43)), "prob 43");
   Check (Is_Fermat_Probable_Prime (U (47)), "prob 47");
   Check (Is_Fermat_Probable_Prime (U (53)), "prob 53");
   Check (Is_Fermat_Probable_Prime (U (59)), "prob 59");
   Check (Is_Fermat_Probable_Prime (U (61)), "prob 61");
   Check (Is_Fermat_Probable_Prime (U (67)), "prob 67");
   Check (Is_Fermat_Probable_Prime (U (71)), "prob 71");
   Check (Is_Fermat_Probable_Prime (U (73)), "prob 73");
   Check (Is_Fermat_Probable_Prime (U (79)), "prob 79");
   Check (Is_Fermat_Probable_Prime (U (83)), "prob 83");
   Check (Is_Fermat_Probable_Prime (U (89)), "prob 89");

   ------------------------------------------------------------------
   --  Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS, "
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
