--  Standalone test suite for Baillie_PSW (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Baillie_PSW; use Baillie_PSW;

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
   function I (X : I64) return I64 is (X);

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

   procedure Expect_Invalid_Jacobi (Label : String; A : I64; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Integer := Jacobi (A, N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Jacobi: " & Label);
   end Expect_Invalid_Jacobi;

begin
   Ada.Text_IO.Put_Line ("Baillie_PSW test suite");
   Ada.Text_IO.Put_Line ("======================");

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
   Check (Mod_Pow (U (10), U (9), U (1)) = 0, "Mod_Pow mod 1");
   Check (Gcd (U (0), U (15)) = 15, "Gcd 0,15");
   Check (Gcd (U (48), U (18)) = 6, "Gcd 48,18");
   Check (Gcd (U (17), U (19)) = 1, "Gcd 17,19");

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
   Section ("2. Jacobi symbol");
   ------------------------------------------------------------------
   Check (Jacobi (I (2), U (7)) = 1, "Jacobi(2/7)=1");
   Check (Jacobi (I (3), U (7)) = -1, "Jacobi(3/7)=-1");
   Check (Jacobi (I (5), U (7)) = -1, "Jacobi(5/7)=-1");
   Check (Jacobi (I (1), U (5)) = 1, "Jacobi(1/5)=1");
   Check (Jacobi (I (15), U (17)) = 1, "Jacobi(15/17)=1");
   Check (Jacobi (I (-1), U (5)) = 1, "Jacobi(-1/5)=1");
   Check (Jacobi (I (-1), U (7)) = -1, "Jacobi(-1/7)=-1");
   Check (Jacobi (I (5), U (5)) = 0, "Jacobi(5/5)=0");
   Check (Jacobi (I (-7), U (5)) = -1, "Jacobi(-7/5)=-1");
   Check (Jacobi (I (13), U (11)) = -1, "Jacobi(13/11)=-1");
   Expect_Invalid_Jacobi ("N=0", I (1), U (0));
   Expect_Invalid_Jacobi ("N even", I (1), U (6));

   ------------------------------------------------------------------
   Section ("3. Is_Perfect_Square");
   ------------------------------------------------------------------
   Check (Is_Perfect_Square (U (0)), "square 0");
   Check (Is_Perfect_Square (U (1)), "square 1");
   Check (Is_Perfect_Square (U (4)), "square 4");
   Check (Is_Perfect_Square (U (9)), "square 9");
   Check (Is_Perfect_Square (U (121)), "square 121");
   Check (Is_Perfect_Square (U (1_000_000)), "square 10^6");
   Check (not Is_Perfect_Square (U (2)), "not square 2");
   Check (not Is_Perfect_Square (U (8)), "not square 8");
   Check (not Is_Perfect_Square (U (15)), "not square 15");
   Check (not Is_Perfect_Square (U (50)), "not square 50");

   ------------------------------------------------------------------
   Section ("4. Strong PRP base 2");
   ------------------------------------------------------------------
   Check (Is_Strong_PRP_Base_2 (U (2)), "SPRP2 2");
   Check (Is_Strong_PRP_Base_2 (U (3)), "SPRP2 3");
   Check (Is_Strong_PRP_Base_2 (U (5)), "SPRP2 5");
   Check (Is_Strong_PRP_Base_2 (U (97)), "SPRP2 97");
   Check (not Is_Strong_PRP_Base_2 (U (1)), "SPRP2 1 false");
   Check (not Is_Strong_PRP_Base_2 (U (9)), "SPRP2 9 false");
   Check (not Is_Strong_PRP_Base_2 (U (561)), "SPRP2 Carmichael 561");
   --  2047 = 23·89 is a strong pseudoprime to base 2
   Check (Is_Strong_PRP_Base_2 (U (2047)), "SPRP2 2047 spsp(2) liar");
   Check (not Is_Strong_PRP_Base_2 (U (341)), "SPRP2 341 Fermat psp fails strong");

   ------------------------------------------------------------------
   Section ("5. Selfridge D / strong Lucas");
   ------------------------------------------------------------------
   Check (Choose_Selfridge_D (U (5)) = -7, "Selfridge D(5)=-7");
   Check (Choose_Selfridge_D (U (7)) = 5, "Selfridge D(7)=5");
   Check (Choose_Selfridge_D (U (11)) = 13, "Selfridge D(11)=13");
   Check (Is_Strong_Lucas_PRP (U (5), I (-7)), "Lucas PRP 5");
   Check (Is_Strong_Lucas_PRP (U (7), I (5)), "Lucas PRP 7");
   Check (Is_Strong_Lucas_PRP (U (11), I (13)), "Lucas PRP 11");
   Check (Is_Strong_Lucas_PRP (U (13), Choose_Selfridge_D (U (13))),
          "Lucas PRP 13");

   ------------------------------------------------------------------
   Section ("6. Small primes / composites via BPSW");
   ------------------------------------------------------------------
   Check (Is_Baillie_PSW_Prime (U (2)), "BPSW 2");
   Check (Is_Baillie_PSW_Prime (U (3)), "BPSW 3");
   Check (Is_Baillie_PSW_Prime (U (5)), "BPSW 5");
   Check (Is_Baillie_PSW_Prime (U (7)), "BPSW 7");
   Check (Is_Baillie_PSW_Prime (U (11)), "BPSW 11");
   Check (Is_Baillie_PSW_Prime (U (97)), "BPSW 97");
   Check (not Is_Baillie_PSW_Prime (U (0)), "BPSW 0 false");
   Check (not Is_Baillie_PSW_Prime (U (1)), "BPSW 1 false");
   Check (not Is_Baillie_PSW_Prime (U (4)), "BPSW 4 false");
   Check (not Is_Baillie_PSW_Prime (U (9)), "BPSW 9 false");
   Check (not Is_Baillie_PSW_Prime (U (15)), "BPSW 15 false");
   Check (not Is_Baillie_PSW_Prime (U (25)), "BPSW 25 false");
   Check (not Is_Baillie_PSW_Prime (U (49)), "BPSW 49 false");
   Check (not Is_Baillie_PSW_Prime (U (121)), "BPSW 121 false");

   ------------------------------------------------------------------
   Section ("7. All primes and composites <= 1000");
   ------------------------------------------------------------------
   declare
      All_P, All_C : Boolean := True;
      N_Count      : Natural := 0;
   begin
      for N in U64 range 0 .. 1000 loop
         declare
            Want : constant Boolean := Trial_Is_Prime (N);
            Got  : constant Boolean := Is_Baillie_PSW_Prime (N);
         begin
            if Want /= Got then
               if Want then
                  All_P := False;
               else
                  All_C := False;
               end if;
               Ada.Text_IO.Put_Line
                 ("  mismatch at" & N'Image &
                  " trial=" & Want'Image & " bpsw=" & Got'Image);
            end if;
            N_Count := N_Count + 1;
         end;
      end loop;
      Check (All_P, "all primes <= 1000 → True");
      Check (All_C, "all composites <= 1000 → False");
      Check (N_Count = 1001, "scanned 0..1000");
   end;

   ------------------------------------------------------------------
   Section ("8. Carmichael / Fermat psp");
   ------------------------------------------------------------------
   Check (not Is_Baillie_PSW_Prime (U (561)), "Carmichael 561");
   Check (not Is_Baillie_PSW_Prime (U (1105)), "Carmichael 1105");
   Check (not Is_Baillie_PSW_Prime (U (1729)), "Carmichael 1729");
   Check (not Is_Baillie_PSW_Prime (U (341)), "Fermat psp 341");
   Check (not Is_Baillie_PSW_Prime (U (645)), "Fermat psp 645");
   Check (not Is_Baillie_PSW_Prime (U (2047)), "spsp(2) 2047 fails Lucas");

   ------------------------------------------------------------------
   Section ("9. Large-ish primes");
   ------------------------------------------------------------------
   Check (Is_Baillie_PSW_Prime (U (2_147_483_647)), "Mersenne31 2147483647");
   Check (Is_Baillie_PSW_Prime (U (1_000_000_007)), "prime 1000000007");
   Check (Is_Baillie_PSW_Prime (U (1_000_000_009)), "prime 1000000009");
   Check (not Is_Baillie_PSW_Prime (U (1_000_000_008)), "composite 10^9+8");

   ------------------------------------------------------------------
   Section ("10. Cross-check vs trial division N <= 50_000");
   ------------------------------------------------------------------
   declare
      Mismatches : Natural := 0;
      First_Bad  : U64 := 0;
      Limit      : constant U64 := 50_000;
   begin
      for N in U64 range 0 .. Limit loop
         if Is_Baillie_PSW_Prime (N) /= Trial_Is_Prime (N) then
            Mismatches := Mismatches + 1;
            if First_Bad = 0 then
               First_Bad := N;
            end if;
         end if;
      end loop;
      Check (Mismatches = 0,
             "cross-check 0.." & Limit'Image & " exact match");
      if Mismatches /= 0 then
         Ada.Text_IO.Put_Line
           ("  first mismatch N=" & First_Bad'Image &
            " count=" & Mismatches'Image);
      end if;
   end;

   ------------------------------------------------------------------
   Section ("11. Extra spot checks");
   ------------------------------------------------------------------
   Check (Is_Baillie_PSW_Prime (U (101)), "BPSW 101");
   Check (Is_Baillie_PSW_Prime (U (997)), "BPSW 997");
   Check (not Is_Baillie_PSW_Prime (U (999)), "BPSW 999");
   Check (not Is_Baillie_PSW_Prime (U (1_001)), "BPSW 1001");
   Check (Is_Baillie_PSW_Prime (U (1_009)), "BPSW 1009");
   --  Strong Lucas pseudoprimes (OEIS A217255) fail base-2 SPRP or BPSW
   Check (not Is_Baillie_PSW_Prime (U (5459)), "slpsp 5459 composite");
   Check (not Is_Baillie_PSW_Prime (U (5777)), "slpsp 5777 composite");

   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result:" & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
