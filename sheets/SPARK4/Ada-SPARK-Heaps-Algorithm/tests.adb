--  Standalone test suite for Heaps_Algorithm (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  Generate fills a static Perm_Store (no access Visit). Max_N = 7.
--  SPARK proves Last = Factorial(N) and each stored row is a permutation;
--  uniqueness / classic order / single-swap chain are checked here.

pragma Ada_2022;

with Ada.Text_IO;
with Heaps_Algorithm;

procedure Tests
  with SPARK_Mode => Off
is
   use Ada.Text_IO;
   package HA renames Heaps_Algorithm;

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
   function Boo (X : Boolean) return Boolean is (X);

   function Image_N (N : Natural) return String is
      S : constant String := Natural'Image (N);
   begin
      if S'Length > 0 and then S (S'First) = ' ' then
         return S (S'First + 1 .. S'Last);
      end if;
      return S;
   end Image_N;

   function Row (Store : HA.Perm_Store; R : Positive; N : Positive)
     return HA.Permutation
   is
      P : HA.Permutation (1 .. N);
   begin
      for J in 1 .. N loop
         P (J) := Store (R, J);
      end loop;
      return P;
   end Row;

   function All_Unique
     (Store : HA.Perm_Store; Len, N : Positive) return Boolean
   is
   begin
      for I in 1 .. Len loop
         for J in I + 1 .. Len loop
            declare
               Same : Boolean := True;
            begin
               for K in 1 .. N loop
                  if Store (I, K) /= Store (J, K) then
                     Same := False;
                     exit;
                  end if;
               end loop;
               if Same then
                  return False;
               end if;
            end;
         end loop;
      end loop;
      return True;
   end All_Unique;

   function All_Are_Permutations
     (Store : HA.Perm_Store; Len, N : Positive) return Boolean
   is
   begin
      for I in 1 .. Len loop
         if not HA.Row_Is_Permutation (Store, I, N) then
            return False;
         end if;
         if not HA.Is_Permutation (Row (Store, I, N)) then
            return False;
         end if;
      end loop;
      return True;
   end All_Are_Permutations;

   function Single_Swap_Chain_OK
     (Store : HA.Perm_Store; Len, N : Positive) return Boolean
   is
   begin
      if Len < 2 then
         return True;
      end if;
      for I in 1 .. Len - 1 loop
         if not HA.Differs_By_Single_Swap
           (Row (Store, I, N), Row (Store, I + 1, N))
         then
            return False;
         end if;
      end loop;
      return True;
   end Single_Swap_Chain_OK;

   function Starts_At_Identity
     (Store : HA.Perm_Store; N : Positive) return Boolean
   is
   begin
      for J in 1 .. N loop
         if Store (1, J) /= J then
            return False;
         end if;
      end loop;
      return True;
   end Starts_At_Identity;

begin
   Put_Line ("Heaps_Algorithm (SPARK) tests");
   Put_Line ("==============================");
   Put_Line ("Max_N =" & HA.Max_N'Image
             & "  Max_Count =" & HA.Max_Count'Image
             & "  (NOT heapsort)");

   ------------------------------------------------------------------
   Section ("1. Factorial");
   ------------------------------------------------------------------
   Check (Nat (HA.Factorial (0)) = 1, "0! = 1");
   Check (Nat (HA.Factorial (1)) = 1, "1! = 1");
   Check (Nat (HA.Factorial (2)) = 2, "2! = 2");
   Check (Nat (HA.Factorial (3)) = 6, "3! = 6");
   Check (Nat (HA.Factorial (4)) = 24, "4! = 24");
   Check (Nat (HA.Factorial (5)) = 120, "5! = 120");
   Check (Nat (HA.Factorial (6)) = 720, "6! = 720");
   Check (Nat (HA.Factorial (7)) = 5_040, "7! = 5040");
   Check (Nat (HA.Factorial (HA.Max_N)) = HA.Max_Count,
          "Factorial(Max_N) = Max_Count");

   ------------------------------------------------------------------
   Section ("2. Count vs N!");
   ------------------------------------------------------------------
   for N in 1 .. HA.Max_N loop
      Check (HA.Count (N) = HA.Factorial (N),
             "Count(" & Image_N (N) & ") = N!");
   end loop;

   ------------------------------------------------------------------
   Section ("3. N = 1 (identity only)");
   ------------------------------------------------------------------
   declare
      Store : HA.Perm_Store;
      Last  : Natural;
   begin
      HA.Generate (1, Store, Last);
      Check (Nat (Last) = 1, "N=1 yields 1 permutation");
      Check (Nat (Last) = HA.Factorial (1), "N=1 Last = Factorial(1)");
      Check (Store (1, 1) = 1, "N=1 permutation is (1)");
      Check (Boo (HA.Is_Permutation (Row (Store, 1, 1))),
             "N=1 is a permutation");
      Check (Boo (HA.Row_Is_Permutation (Store, 1, 1)),
             "N=1 Row_Is_Permutation");
   end;

   ------------------------------------------------------------------
   Section ("4. N = 2");
   ------------------------------------------------------------------
   declare
      Store : HA.Perm_Store;
      Last  : Natural;
   begin
      HA.Generate (2, Store, Last);
      Check (Nat (Last) = 2, "N=2 yields 2 permutations");
      Check (Store (1, 1) = 1 and then Store (1, 2) = 2,
             "N=2 first is identity (1 2)");
      Check (Store (2, 1) = 2 and then Store (2, 2) = 1,
             "N=2 second is (2 1)");
      Check (Single_Swap_Chain_OK (Store, Last, 2),
             "N=2 consecutive pair is a single swap");
      Check (All_Unique (Store, Last, 2), "N=2 all unique");
   end;

   ------------------------------------------------------------------
   Section ("5. N = 3 classic Heap order");
   ------------------------------------------------------------------
   declare
      Store : HA.Perm_Store;
      Last  : Natural;
      Expected : constant array (1 .. 6, 1 .. 3) of Positive :=
        [1 => [1, 2, 3],
         2 => [2, 1, 3],
         3 => [3, 1, 2],
         4 => [1, 3, 2],
         5 => [2, 3, 1],
         6 => [3, 2, 1]];
      Order_OK : Boolean := True;
   begin
      HA.Generate (3, Store, Last);
      Check (Nat (Last) = 6, "N=3 yields 6 permutations");
      for I in 1 .. 6 loop
         for J in 1 .. 3 loop
            if Store (I, J) /= Expected (I, J) then
               Order_OK := False;
            end if;
         end loop;
      end loop;
      Check (Order_OK, "N=3 matches classic Heap sequence");
      Check (All_Unique (Store, Last, 3), "N=3 all unique");
      Check (All_Are_Permutations (Store, Last, 3),
             "N=3 every row is a permutation");
      Check (Single_Swap_Chain_OK (Store, Last, 3),
             "N=3 each step is a single swap");
   end;

   ------------------------------------------------------------------
   Section ("6. N = 4 count, uniqueness, single-swap chain");
   ------------------------------------------------------------------
   declare
      Store : HA.Perm_Store;
      Last  : Natural;
   begin
      HA.Generate (4, Store, Last);
      Check (Nat (Last) = 24, "N=4 yields 24 permutations");
      Check (Nat (Last) = HA.Count (4), "N=4 Last = Count(4)");
      Check (All_Are_Permutations (Store, Last, 4),
             "N=4 every row is a permutation");
      Check (All_Unique (Store, Last, 4), "N=4 all unique");
      Check (Single_Swap_Chain_OK (Store, Last, 4),
             "N=4 each step is a single swap");
      Check (Starts_At_Identity (Store, 4), "N=4 starts at identity");
   end;

   ------------------------------------------------------------------
   Section ("7. N = 5 count, uniqueness, single-swap chain");
   ------------------------------------------------------------------
   declare
      Store : HA.Perm_Store;
      Last  : Natural;
   begin
      HA.Generate (5, Store, Last);
      Check (Nat (Last) = 120, "N=5 yields 120 permutations");
      Check (All_Are_Permutations (Store, Last, 5),
             "N=5 every row is a permutation");
      Check (All_Unique (Store, Last, 5), "N=5 all unique");
      Check (Single_Swap_Chain_OK (Store, Last, 5),
             "N=5 each step is a single swap");
   end;

   ------------------------------------------------------------------
   Section ("8. N = 6 count, uniqueness, single-swap chain");
   ------------------------------------------------------------------
   declare
      Store : HA.Perm_Store;
      Last  : Natural;
   begin
      HA.Generate (6, Store, Last);
      Check (Nat (Last) = 720, "N=6 yields 720 permutations");
      Check (Nat (Last) = HA.Count (6), "N=6 Last = Count(6)");
      Check (All_Are_Permutations (Store, Last, 6),
             "N=6 every row is a permutation");
      Check (All_Unique (Store, Last, 6), "N=6 all unique");
      Check (Single_Swap_Chain_OK (Store, Last, 6),
             "N=6 each step is a single swap");
      Check (Starts_At_Identity (Store, 6), "N=6 starts at identity");
   end;

   ------------------------------------------------------------------
   Section ("9. Differs_By_Single_Swap helper");
   ------------------------------------------------------------------
   declare
      A : constant HA.Permutation := [1, 2, 3];
      B : constant HA.Permutation := [1, 3, 2];
      C : constant HA.Permutation := [2, 1, 3];
      D : constant HA.Permutation := [3, 2, 1];
      E : constant HA.Permutation := [1, 2];
      F : constant HA.Permutation := [1, 2, 3, 4];
      G : constant HA.Permutation := [3, 1, 2];
      One_A : constant HA.Permutation := [1 => 1];
      One_B : constant HA.Permutation := [1 => 1];
   begin
      Check (Boo (HA.Differs_By_Single_Swap (A, B)),
             "(1 2 3) vs (1 3 2) is a single swap");
      Check (Boo (HA.Differs_By_Single_Swap (A, C)),
             "(1 2 3) vs (2 1 3) is a single swap");
      Check (Boo (HA.Differs_By_Single_Swap (A, D)),
             "(1 2 3) vs (3 2 1) is a single (non-adjacent) swap");
      Check (not HA.Differs_By_Single_Swap (A, G),
             "(1 2 3) vs (3 1 2) is NOT a single swap (cycle)");
      Check (not HA.Differs_By_Single_Swap (A, A),
             "identical permutations are not a transposition");
      Check (not HA.Differs_By_Single_Swap (A, E),
             "different lengths -> False");
      Check (not HA.Differs_By_Single_Swap (A, F),
             "different lengths (3 vs 4) -> False");
      Check (not HA.Differs_By_Single_Swap (One_A, One_B),
             "length-1 pair -> False");
   end;

   ------------------------------------------------------------------
   Section ("10. Is_Permutation helper");
   ------------------------------------------------------------------
   Check (Boo (HA.Is_Permutation ([1, 2, 3])), "(1 2 3) is a permutation");
   Check (Boo (HA.Is_Permutation ([3, 1, 2])), "(3 1 2) is a permutation");
   Check (not HA.Is_Permutation ([1, 2, 2]), "(1 2 2) is not");
   Check (not HA.Is_Permutation ([1, 2, 4]), "(1 2 4) is not for N=3");
   Check (not HA.Is_Permutation ([1 => 2]), "(2) is not for N=1");
   declare
      Empty : HA.Permutation (1 .. 0);
   begin
      Check (not HA.Is_Permutation (Empty), "empty is not a permutation");
   end;
   Check (Boo (HA.Is_Permutation ([1, 2, 3, 4, 5, 6, 7])),
          "(1..7) is a permutation");
   Check (not HA.Is_Permutation ([7, 6, 5, 4, 3, 2, 2]),
          "dup at Max_N is not");

   ------------------------------------------------------------------
   Section ("11. Max_N Generate");
   ------------------------------------------------------------------
   declare
      Store : HA.Perm_Store;
      Last  : Natural;
   begin
      HA.Generate (HA.Max_N, Store, Last);
      Check (Nat (Last) = HA.Max_Count,
             "Generate(Max_N) yields Max_Count permutations");
      Check (Nat (Last) = HA.Factorial (HA.Max_N),
             "Generate(Max_N) Last = Factorial(Max_N)");
      Check (Nat (HA.Count (HA.Max_N)) = HA.Max_Count,
             "Count(Max_N) = Max_Count");
      Check (Starts_At_Identity (Store, HA.Max_N),
             "Max_N starts at identity");
      Check (All_Are_Permutations (Store, Last, HA.Max_N),
             "Max_N every row is a permutation");
      Check (Single_Swap_Chain_OK (Store, Last, HA.Max_N),
             "Max_N each step is a single swap");
      declare
         Same_As_Last : Boolean := True;
      begin
         for K in 1 .. HA.Max_N loop
            if Store (1, K) /= Store (Last, K) then
               Same_As_Last := False;
               exit;
            end if;
         end loop;
         Check (not Same_As_Last, "Max_N first row differs from last");
      end;
   end;

   ------------------------------------------------------------------
   Section ("12. First permutation always identity");
   ------------------------------------------------------------------
   for N in 1 .. HA.Max_N loop
      declare
         Store : HA.Perm_Store;
         Last  : Natural;
      begin
         HA.Generate (N, Store, Last);
         Check (Starts_At_Identity (Store, N),
                "N=" & Image_N (N) & " starts with identity");
         Check (Nat (Last) = HA.Factorial (N),
                "N=" & Image_N (N) & " Last = N!");
      end;
   end loop;

   New_Line;
   Put_Line
     ("Results:" & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
