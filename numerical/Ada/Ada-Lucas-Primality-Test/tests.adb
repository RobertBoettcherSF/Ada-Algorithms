--  Standalone test suite for Lucas_Primality_Test (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Lucas_Primality_Test; use Lucas_Primality_Test;

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

   procedure Expect_Invalid_Factors (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Factor_List := Factors_Of_N_Minus_1 (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Factors: " & Label);
   end Expect_Invalid_Factors;

   procedure Expect_Invalid_Lucas
     (Label   : String;
      N       : U64;
      Factors : Factor_List)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Boolean := Is_Prime_Lucas (N, Factors);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Lucas: " & Label);
   end Expect_Invalid_Lucas;

   procedure Expect_Invalid_Auto (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Boolean := Is_Prime_Lucas_Auto (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Auto: " & Label);
   end Expect_Invalid_Auto;

   function Factors_Equal
     (Got : Factor_List; Expected : Factor_List) return Boolean
   is
   begin
      if Got'Length /= Expected'Length then
         return False;
      end if;
      for I in Expected'Range loop
         declare
            Found : Boolean := False;
         begin
            for J in Got'Range loop
               if Got (J) = Expected (I) then
                  Found := True;
                  exit;
               end if;
            end loop;
            if not Found then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Factors_Equal;

begin
   Ada.Text_IO.Put_Line ("Lucas_Primality_Test test suite");
   Ada.Text_IO.Put_Line ("===============================");

   ------------------------------------------------------------------
   Section ("1. Mul_Mod / Mod_Pow");
   ------------------------------------------------------------------
   Check (Mul_Mod (U (3), U (4), U (5)) = 2, "Mul_Mod 3*4 mod 5 = 2");
   Check (Mul_Mod (U (7), U (8), U (9)) = 2, "Mul_Mod 7*8 mod 9 = 2");
   Check (Mul_Mod (U (0), U (99), U (17)) = 0, "Mul_Mod 0");
   Check (Mul_Mod (U (1), U (1), U (1)) = 0, "Mul_Mod mod 1");
   Check
     (Mul_Mod (U (2**32), U (2**32), U (2**32 + 1)) = 1,
      "Mul_Mod 2^32*2^32 mod (2^32+1)");
   Check (Mod_Pow (U (2), U (10), U (1000)) = 24, "Mod_Pow 2^10 mod 1000");
   Check (Mod_Pow (U (3), U (5), U (13)) = 9, "Mod_Pow 3^5 mod 13");
   Check (Mod_Pow (U (5), U (0), U (7)) = 1, "Mod_Pow exp 0");
   Check (Mod_Pow (U (7), U (1), U (11)) = 7, "Mod_Pow exp 1");
   Check (Mod_Pow (U (2), U (70), U (71)) = 1, "Mod_Pow 2^70 mod 71");
   Check (Mod_Pow (U (17), U (70), U (71)) = 1, "Mod_Pow 17^70 mod 71");
   Check (Mod_Pow (U (11), U (70), U (71)) = 1, "Mod_Pow 11^70 mod 71");
   Check (Mod_Pow (U (17), U (35), U (71)) = 70, "Mod_Pow 17^35 mod 71 = 70");
   Check (Mod_Pow (U (17), U (10), U (71)) = 1, "Mod_Pow 17^10 mod 71 = 1");
   Check (Mod_Pow (U (11), U (10), U (71)) /= 1, "Mod_Pow 11^10 mod 71 /= 1");
   Expect_Invalid_Mod_Pow ("modulus 0", U (2), U (3), U (0));
   Expect_Invalid_Mul_Mod ("modulus 0", U (2), U (3), U (0));

   ------------------------------------------------------------------
   Section ("2. Factors_Of_N_Minus_1");
   ------------------------------------------------------------------
   declare
      F2 : constant Factor_List := Factors_Of_N_Minus_1 (U (2));
   begin
      Check (F2'Length = 0, "Factors of 2-1 empty");
   end;
   Check
     (Factors_Equal (Factors_Of_N_Minus_1 (U (31)), Factor_List'(2, 3, 5)),
      "Factors of 30 = 2,3,5");
   Check
     (Factors_equal (Factors_Of_N_Minus_1 (U (71)), Factor_List'(2, 5, 7)),
      "Factors of 70 = 2,5,7");
   Check
     (Factors_equal (Factors_Of_N_Minus_1 (U (97)), Factor_List'(2, 3)),
      "Factors of 96 = 2,3");
   Check
     (Factors_equal (Factors_Of_N_Minus_1 (U (101)), Factor_List'(2, 5)),
      "Factors of 100 = 2,5");
   Check
     (Factors_equal (Factors_Of_N_Minus_1 (U (13)), Factor_List'(2, 3)),
      "Factors of 12 = 2,3");
   Check
     (Factors_equal (Factors_Of_N_Minus_1 (U (17)), Factor_List'(1 => 2)),
      "Factors of 16 = 2");
   Expect_Invalid_Factors ("N=0", U (0));
   Expect_Invalid_Factors ("N=1", U (1));
   Expect_Invalid_Factors ("N too large", U (1_000_001));

   ------------------------------------------------------------------
   Section ("3. Known primes — Is_Prime_Lucas_Auto");
   ------------------------------------------------------------------
   declare
      Primes : constant array (Positive range <>) of U64 :=
        [3, 5, 7, 11, 13, 17, 31, 97, 101];
   begin
      for P of Primes loop
         Check
           (Is_Prime_Lucas_Auto (P),
            "Auto prime " & U64'Image (P));
         declare
            F : constant Factor_List := Factors_Of_N_Minus_1 (P);
            W : constant U64 := Find_Lucas_Witness (P, F);
         begin
            Check (W /= 0, "witness exists for" & U64'Image (P));
            Check
              (Lucas_Witness (P, W, F),
               "Lucas_Witness holds for" & U64'Image (P));
         end;
      end loop;
   end;
   Check (Is_Prime_Lucas_Auto (U (2)), "Auto prime 2");
   Check (Is_Prime_Small (U (71)), "Is_Prime_Small 71");

   ------------------------------------------------------------------
   Section ("4. Composites — Auto False");
   ------------------------------------------------------------------
   declare
      Composites : constant array (Positive range <>) of U64 :=
        [9, 15, 21, 25, 27, 91, 561];
   begin
      for C of Composites loop
         Check
           (not Is_Prime_Lucas_Auto (C),
            "Auto composite" & U64'Image (C));
      end loop;
   end;
   Check (not Is_Prime_Lucas_Auto (U (4)), "Auto composite 4");
   Check (not Is_Prime_Lucas_Auto (U (1)), "Auto N=1 False");
   Check (not Is_Prime_Lucas_Auto (U (0)), "Auto N=0 False");

   ------------------------------------------------------------------
   Section ("5. Explicit factors / Wikipedia example N=71");
   ------------------------------------------------------------------
   declare
      F31 : constant Factor_List := [2, 3, 5];
      F71 : constant Factor_List := [2, 5, 7];
   begin
      Check (Is_Prime_Lucas (U (31), F31), "Is_Prime_Lucas 31 with 2,3,5");
      Check
        (Is_Prime_With_Factors (U (31), F31),
         "Is_Prime_With_Factors 31");
      Check (Lucas_Witness (U (31), U (3), F31), "witness A=3 for 31");
      Check
        (Find_Lucas_Witness (U (31), F31) /= 0,
         "Find_Lucas_Witness 31 nonzero");

      --  Wikipedia: A=17 fails (17^10 ≡ 1), A=11 succeeds for N=71
      Check
        (not Lucas_Witness (U (71), U (17), F71),
         "A=17 is NOT a Lucas witness for 71");
      Check
        (Lucas_Witness (U (71), U (11), F71),
         "A=11 IS a Lucas witness for 71");
      Check (Is_Prime_Lucas (U (71), F71), "Is_Prime_Lucas 71");
      Check
        (Find_Lucas_Witness (U (71), F71) = 7
           or else Find_Lucas_Witness (U (71), F71) = 11
           or else Find_Lucas_Witness (U (71), F71) /= 0,
         "Find_Lucas_Witness 71 finds some base");
   end;

   ------------------------------------------------------------------
   Section ("6. Domain / Invalid_Argument");
   ------------------------------------------------------------------
   declare
      Empty : Factor_List (1 .. 0);
      Bad   : constant Factor_List := [2, 3, 7];  -- 7 does not divide 30
   begin
      Expect_Invalid_Lucas ("N=0", U (0), Empty);
      Expect_Invalid_Lucas ("N=1", U (1), Empty);
      Expect_Invalid_Lucas ("empty factors for 31", U (31), Empty);
      Expect_Invalid_Lucas ("factor not dividing N-1", U (31), Bad);
      Expect_Invalid_Auto ("N > Max_Auto_N", U (1_000_001));
   end;
   Check (not Lucas_Witness (U (31), U (1), [2, 3, 5]), "A=1 not witness");
   Check
     (not Lucas_Witness (U (31), U (31), [2, 3, 5]),
      "A=N not witness");
   Check (Find_Lucas_Witness (U (2), Factor_List'(1 .. 0 => <>)) = 0,
          "Find witness for 2 is 0");

   ------------------------------------------------------------------
   Section ("7. Cross-check Auto vs trial (odd N ≤ 2000)");
   ------------------------------------------------------------------
   declare
      Mismatches : Natural := 0;
      Checked    : Natural := 0;
      N          : U64 := 3;
   begin
      while N <= 2000 loop
         Checked := Checked + 1;
         if Is_Prime_Lucas_Auto (N) /= Trial_Is_Prime (N) then
            Mismatches := Mismatches + 1;
            Ada.Text_IO.Put_Line
              ("  MISMATCH at" & U64'Image (N));
         end if;
         N := N + 2;
      end loop;
      Check (Mismatches = 0,
             "Auto vs trial: 0 mismatches in" & Natural'Image (Checked)
             & " odd N ≤ 2000");
      Check (Checked = 999, "checked 999 odd values 3..2000");
   end;

   ------------------------------------------------------------------
   Section ("8. Cross-check Auto vs trial (odd N ≤ 5000)");
   ------------------------------------------------------------------
   declare
      Mismatches : Natural := 0;
      Checked    : Natural := 0;
      N          : U64 := 3;
   begin
      while N <= 5000 loop
         Checked := Checked + 1;
         if Is_Prime_Lucas_Auto (N) /= Trial_Is_Prime (N) then
            Mismatches := Mismatches + 1;
            Ada.Text_IO.Put_Line
              ("  MISMATCH at" & U64'Image (N));
         end if;
         N := N + 2;
      end loop;
      Check (Mismatches = 0,
             "Auto vs trial: 0 mismatches in" & Natural'Image (Checked)
             & " odd N ≤ 5000");
   end;

   ------------------------------------------------------------------
   Section ("9. Even / edge cases with explicit API");
   ------------------------------------------------------------------
   declare
      F : constant Factor_List := [1 => 2];
   begin
      Check (Is_Prime_Lucas (U (2), Factor_List'(1 .. 0 => <>)),
             "Is_Prime_Lucas 2 with empty factors");
      Check (not Is_Prime_Lucas (U (15), Factors_Of_N_Minus_1 (U (15))),
             "Is_Prime_Lucas 15 False");
      Check (not Is_Prime_Lucas (U (9), Factors_Of_N_Minus_1 (U (9))),
             "Is_Prime_Lucas 9 False");
      Check (not Is_Prime_Lucas (U (4), F), "Is_Prime_Lucas 4 False");
      Check (not Is_Prime_Lucas (U (6), F), "Is_Prime_Lucas 6 False");
   end;

   ------------------------------------------------------------------
   Section ("10. Additional primes / composites");
   ------------------------------------------------------------------
   declare
      More_P : constant array (Positive range <>) of U64 :=
        [19, 23, 29, 37, 41, 43, 47, 53, 59, 61, 67, 73, 79, 83, 89];
      More_C : constant array (Positive range <>) of U64 :=
        [33, 35, 39, 45, 49, 51, 55, 57, 63, 65, 69, 75, 77, 85, 87,
         93, 95, 99, 121, 143, 169, 187, 289, 341, 561, 645, 1105];
   begin
      for P of More_P loop
         Check (Is_Prime_Lucas_Auto (P), "extra prime" & U64'Image (P));
      end loop;
      for C of More_C loop
         Check
           (not Is_Prime_Lucas_Auto (C),
            "extra composite" & U64'Image (C));
      end loop;
   end;

   ------------------------------------------------------------------
   --  Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result:" & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   elsif Pass_Count < 80 then
      Ada.Text_IO.Put_Line
        ("ERROR: expected at least 80 PASS, got"
         & Natural'Image (Pass_Count));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
