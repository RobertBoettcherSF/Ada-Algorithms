pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ugly_Number_II; use Ugly_Number_II;

--  Expected values: see tests/SOURCES.txt.
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

   function Only_2_3_5 (V : Positive) return Boolean is
      M : Positive := V;
   begin
      for P of Primes loop
         while M mod P = 0 loop
            M := M / P;
         end loop;
      end loop;
      return M = 1;
   end Only_2_3_5;

   --  The ugly numbers up to 36, listed by hand (7, 11, 13, 14, 17, 19,
   --  21, 22, 23, 26, 28, 29, 31, 33, 34, 35 have another prime factor).
   First_20 : constant Ugly_List (1 .. 20) :=
     [1, 2, 3, 4, 5, 6, 8, 9, 10, 12, 15, 16, 18, 20, 24, 25, 27, 30, 32, 36];
begin
   for K in First_20'Range loop
      Check (Nth_Ugly (K) = First_20 (K), "Nth_Ugly" & K'Image);
   end loop;
   Check (First_Ugly (20) = First_20, "First_Ugly 20");
   Check (First_Ugly (1) = [1 => 1], "First_Ugly 1");
   --  37 .. 60: 40, 45, 48, 50, 54, 60 (by hand), so the 21st .. 26th.
   Check (Nth_Ugly (21) = 40 and then Nth_Ugly (22) = 45 and then Nth_Ugly (23) = 48
          and then Nth_Ugly (24) = 50 and then Nth_Ugly (25) = 54 and then Nth_Ugly (26) = 60,
          "Nth_Ugly 21 .. 26");
   --  The limit: the 1_691st is 2_125_764_000 = 2 ** 5 * 3 ** 12 * 5 ** 3,
   --  the 1_692nd would be 2 ** 31 = Positive'Last + 1.
   Check (Nth_Ugly (Max_N) = 2_125_764_000, "Nth_Ugly 1691");
   declare
      L : constant Ugly_List := First_Ugly (Max_N);
      Ok : Boolean := L'First = 1 and then L'Last = Max_N and then L (1) = 1;
   begin
      for K in L'Range loop
         Ok := Ok and then Only_2_3_5 (L (K)) and then (K = 1 or else L (K - 1) < L (K));
      end loop;
      Check (Ok, "First_Ugly 1691 increasing, only 2, 3, 5");
      Check (L (Max_N) = 2_125_764_000, "First_Ugly 1691 last");
   end;
   if Failures = 0 then
      Put_Line ("PASS Ugly_Number_II");
   else
      Put_Line ("FAIL Ugly_Number_II:" & Failures'Image);
      raise Program_Error;
   end if;
end Tests;
