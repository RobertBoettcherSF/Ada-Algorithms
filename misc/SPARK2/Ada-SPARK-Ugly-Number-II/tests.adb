pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;
with Ugly_Number_II; use Ugly_Number_II;

--  Expected values: see tests/SOURCES.txt.
with Own_Checks;
procedure Tests is
   Failures : Natural := 0;

   procedure Check (Ok : Boolean; Label : String) is
   begin
      if not Ok then
         Failures := Failures + 1;
         Put_Line ("FAIL " & Label);
      end if;
   end Check;

   --  Own test: V has no prime factor other than 2, 3 and 5.
   Primes : constant array (1 .. 3) of Positive := [2, 3, 5];

   function Only_2_3_5 (V : Big_Integer) return Boolean is
      M : Big_Integer := V;
   begin
      if V < 1 then
         return False;
      end if;
      for P of Primes loop
         while M mod To_Big_Integer (P) = 0 loop
            M := M / To_Big_Integer (P);
         end loop;
      end loop;
      return M = 1;
   end Only_2_3_5;

   --  The ugly numbers up to 36, listed by hand (7, 11, 13, 14, 17, 19,
   --  21, 22, 23, 26, 28, 29, 31, 33, 34, 35 have another prime factor).
   type Big_Array is array (Positive range <>) of Big_Integer;
   First_20 : constant Big_Array (1 .. 20) :=
     [1, 2, 3, 4, 5, 6, 8, 9, 10, 12, 15, 16, 18, 20, 24, 25, 27, 30, 32, 36];
begin
   for K in First_20'Range loop
      Check (Nth_Ugly (K) = First_20 (K), "Nth_Ugly" & K'Image);
   end loop;
   declare
      L  : constant Ugly_List := First_Ugly (20);
      Ok : Boolean := L'First = 1 and then L'Last = 20;
   begin
      for K in 1 .. 20 loop
         Ok := Ok and then L (K).Value = First_20 (K);
      end loop;
      Check (Ok, "First_Ugly 20");
      --  The exponents of 1, 30 and 36, by hand.
      Check (L (1).Two = 0 and then L (1).Three = 0 and then L (1).Five = 0, "exponents of 1");
      Check (L (18).Two = 1 and then L (18).Three = 1 and then L (18).Five = 1, "exponents of 30");
      Check (L (20).Two = 2 and then L (20).Three = 2 and then L (20).Five = 0, "exponents of 36");
      --  Positions of the multiples, by hand from the list: 2, 3, 5 times
      --  1 are the 2nd, 3rd, 5th; 2 * 12 = 24 is the 15th, 3 * 12 = 36 the
      --  20th; 5 * 12 = 60 is above 36, so not listed.
      Check (L (1).At_2 = 2 and then L (1).At_3 = 3 and then L (1).At_5 = 5, "positions for 1");
      Check (L (10).At_2 = 15 and then L (10).At_3 = 20 and then L (10).At_5 = 0, "positions for 12");
   end;
   Check (First_Ugly (1)'Length = 1 and then First_Ugly (1) (1).Value = 1, "First_Ugly 1");
   --  37 .. 60: 40, 45, 48, 50, 54, 60 (by hand), so the 21st .. 26th.
   Check (Nth_Ugly (21) = 40 and then Nth_Ugly (22) = 45 and then Nth_Ugly (23) = 48
          and then Nth_Ugly (24) = 50 and then Nth_Ugly (25) = 54 and then Nth_Ugly (26) = 60,
          "Nth_Ugly 21 .. 26");
   --  One call at the limit (each call costs O (N ** 2) with assertions on):
   --  the last value that fits Positive, the 1_691st, is 2_125_764_000 =
   --  2 ** 5 * 3 ** 12 * 5 ** 3; the 1_692nd is 2 ** 31 = Positive'Last + 1;
   --  the 2_000th is 8_062_156_800 = 2 ** 14 * 3 ** 9 * 5 ** 2 (see
   --  tests/SOURCES.txt for the source of these three values).
   declare
      L : constant Ugly_List := First_Ugly (Max_N);
      Ok : Boolean := L'First = 1 and then L'Last = Max_N and then L (1).Value = 1;
   begin
      for K in L'Range loop
         Ok := Ok and then Only_2_3_5 (L (K).Value) and then (K = 1 or else L (K - 1).Value < L (K).Value);
      end loop;
      Check (Ok, "First_Ugly Max_N increasing, only 2, 3, 5");
      Check (L (1_691).Value = 2_125_764_000, "1691st");
      Check (L (1_692).Value = 2_147_483_648, "1692nd");
      Check (L (Max_N).Value = 8_062_156_800, "2000th");
   end;
   Check (Nth_Ugly (Max_N) = 8_062_156_800, "Nth_Ugly 2000");
   if Failures = 0 then
      Put_Line ("PASS Ugly_Number_II");
   else
      Put_Line ("FAIL Ugly_Number_II:" & Failures'Image);
      raise Program_Error;
   end if;
   Own_Checks;
end Tests;
