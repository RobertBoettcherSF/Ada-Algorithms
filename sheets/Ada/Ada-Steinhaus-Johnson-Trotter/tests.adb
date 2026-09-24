--  Standalone test suite for Steinhaus_Johnson_Trotter (main program).

pragma Ada_2022;

with Ada.Text_IO;
with Steinhaus_Johnson_Trotter;

procedure Tests is

   use Ada.Text_IO;
   package SJT renames Steinhaus_Johnson_Trotter;

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

   function Count_Raises (N : Natural) return Boolean is
      Unused : Natural;
   begin
      Unused := SJT.Count (N);
      pragma Unreferenced (Unused);
      return False;
   exception
      when SJT.Invalid_Argument =>
         return True;
   end Count_Raises;

   function Factorial_Raises (N : Natural) return Boolean is
      Unused : Natural;
   begin
      Unused := SJT.Factorial (N);
      pragma Unreferenced (Unused);
      return False;
   exception
      when SJT.Invalid_Argument =>
         return True;
   end Factorial_Raises;

   function Generate_Raises (N : Natural) return Boolean is
      procedure Dummy (P : SJT.Permutation) is
         pragma Unreferenced (P);
      begin
         null;
      end Dummy;
   begin
      SJT.Generate (N, Dummy'Access);
      return False;
   exception
      when SJT.Invalid_Argument =>
         return True;
   end Generate_Raises;

   type Perm_Table is array (Positive range <>, Positive range <>) of Positive;

   procedure Collect
     (N     : Positive;
      Table : out Perm_Table;
      Len   : out Natural)
   is
      Idx : Natural := 0;

      procedure Visit (P : SJT.Permutation) is
      begin
         Idx := Idx + 1;
         if Idx <= Table'Length (1) then
            for J in 1 .. N loop
               Table (Idx, J) := P (J);
            end loop;
         end if;
      end Visit;
   begin
      SJT.Generate (N, Visit'Access);
      Len := Idx;
   end Collect;

   function Row (Table : Perm_Table; R : Positive; N : Positive)
     return SJT.Permutation
   is
      P : SJT.Permutation (1 .. N);
   begin
      for J in 1 .. N loop
         P (J) := Table (R, J);
      end loop;
      return P;
   end Row;

   function All_Unique (Table : Perm_Table; Len, N : Positive) return Boolean is
   begin
      for I in 1 .. Len loop
         for J in I + 1 .. Len loop
            declare
               Same : Boolean := True;
            begin
               for K in 1 .. N loop
                  if Table (I, K) /= Table (J, K) then
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
     (Table : Perm_Table; Len, N : Positive) return Boolean
   is
   begin
      for I in 1 .. Len loop
         if not SJT.Is_Permutation (Row (Table, I, N)) then
            return False;
         end if;
      end loop;
      return True;
   end All_Are_Permutations;

   function Adjacent_Chain_OK
     (Table : Perm_Table; Len, N : Positive) return Boolean
   is
   begin
      if Len < 2 then
         return True;
      end if;
      for I in 1 .. Len - 1 loop
         if not SJT.Differs_By_Adjacent_Transposition
           (Row (Table, I, N), Row (Table, I + 1, N))
         then
            return False;
         end if;
      end loop;
      return True;
   end Adjacent_Chain_OK;

   function Image_N (N : Natural) return String is
      S : constant String := Natural'Image (N);
   begin
      if S'Length > 0 and then S (S'First) = ' ' then
         return S (S'First + 1 .. S'Last);
      end if;
      return S;
   end Image_N;

begin
   ------------------------------------------------------------------
   Section ("1. Factorial");
   ------------------------------------------------------------------
   Check (SJT.Factorial (0) = 1, "0! = 1");
   Check (SJT.Factorial (1) = 1, "1! = 1");
   Check (SJT.Factorial (2) = 2, "2! = 2");
   Check (SJT.Factorial (3) = 6, "3! = 6");
   Check (SJT.Factorial (4) = 24, "4! = 24");
   Check (SJT.Factorial (5) = 120, "5! = 120");
   Check (SJT.Factorial (6) = 720, "6! = 720");
   Check (SJT.Factorial (7) = 5_040, "7! = 5040");
   Check (Factorial_Raises (SJT.Max_N + 1),
          "Factorial(Max_N+1) raises Invalid_Argument");

   ------------------------------------------------------------------
   Section ("2. Count vs N!");
   ------------------------------------------------------------------
   for N in 1 .. 5 loop
      Check (SJT.Count (N) = SJT.Factorial (N),
             "Count(" & Image_N (N) & ") = N!");
   end loop;
   Check (Count_Raises (0), "Count(0) raises Invalid_Argument");
   Check (Count_Raises (SJT.Max_N + 1),
          "Count(Max_N+1) raises Invalid_Argument");
   Check (Generate_Raises (0), "Generate(0) raises Invalid_Argument");
   Check (Generate_Raises (SJT.Max_N + 1),
          "Generate(Max_N+1) raises Invalid_Argument");

   ------------------------------------------------------------------
   Section ("3. N = 1 (identity only)");
   ------------------------------------------------------------------
   declare
      Table : Perm_Table (1 .. 1, 1 .. 1);
      Len   : Natural;
   begin
      Collect (1, Table, Len);
      Check (Len = 1, "N=1 yields 1 permutation");
      Check (Table (1, 1) = 1, "N=1 permutation is (1)");
      Check (SJT.Is_Permutation (Row (Table, 1, 1)), "N=1 is a permutation");
   end;

   ------------------------------------------------------------------
   Section ("4. N = 2");
   ------------------------------------------------------------------
   declare
      Table : Perm_Table (1 .. 2, 1 .. 2);
      Len   : Natural;
   begin
      Collect (2, Table, Len);
      Check (Len = 2, "N=2 yields 2 permutations");
      Check (Table (1, 1) = 1 and then Table (1, 2) = 2,
             "N=2 first is identity (1 2)");
      Check (Table (2, 1) = 2 and then Table (2, 2) = 1,
             "N=2 second is (2 1)");
      Check (Adjacent_Chain_OK (Table, Len, 2),
             "N=2 consecutive pair is adjacent transposition");
      Check (All_Unique (Table, Len, 2), "N=2 all unique");
   end;

   ------------------------------------------------------------------
   Section ("5. N = 3 classic SJT order");
   ------------------------------------------------------------------
   declare
      Table : Perm_Table (1 .. 6, 1 .. 3);
      Len   : Natural;
      Expected : constant array (1 .. 6, 1 .. 3) of Positive :=
        [1 => [1, 2, 3],
         2 => [1, 3, 2],
         3 => [3, 1, 2],
         4 => [3, 2, 1],
         5 => [2, 3, 1],
         6 => [2, 1, 3]];
      Order_OK : Boolean := True;
   begin
      Collect (3, Table, Len);
      Check (Len = 6, "N=3 yields 6 permutations");
      for I in 1 .. 6 loop
         for J in 1 .. 3 loop
            if Table (I, J) /= Expected (I, J) then
               Order_OK := False;
            end if;
         end loop;
      end loop;
      Check (Order_OK, "N=3 matches classic SJT sequence");
      Check (All_Unique (Table, Len, 3), "N=3 all unique");
      Check (All_Are_Permutations (Table, Len, 3),
             "N=3 every row is a permutation");
      Check (Adjacent_Chain_OK (Table, Len, 3),
             "N=3 each step is an adjacent transposition");
   end;

   ------------------------------------------------------------------
   Section ("6. N = 4 count, uniqueness, adjacency");
   ------------------------------------------------------------------
   declare
      Table : Perm_Table (1 .. 24, 1 .. 4);
      Len   : Natural;
   begin
      Collect (4, Table, Len);
      Check (Len = 24, "N=4 yields 24 permutations");
      Check (Len = SJT.Count (4), "N=4 collected length = Count(4)");
      Check (All_Are_Permutations (Table, Len, 4),
             "N=4 every row is a permutation");
      Check (All_Unique (Table, Len, 4), "N=4 all unique");
      Check (Adjacent_Chain_OK (Table, Len, 4),
             "N=4 each step is an adjacent transposition");
      Check (Table (1, 1) = 1 and then Table (1, 2) = 2
             and then Table (1, 3) = 3 and then Table (1, 4) = 4,
             "N=4 starts at identity");
   end;

   ------------------------------------------------------------------
   Section ("7. N = 5 count, uniqueness, adjacency");
   ------------------------------------------------------------------
   declare
      Table : Perm_Table (1 .. 120, 1 .. 5);
      Len   : Natural;
   begin
      Collect (5, Table, Len);
      Check (Len = 120, "N=5 yields 120 permutations");
      Check (All_Are_Permutations (Table, Len, 5),
             "N=5 every row is a permutation");
      Check (All_Unique (Table, Len, 5), "N=5 all unique");
      Check (Adjacent_Chain_OK (Table, Len, 5),
             "N=5 each step is an adjacent transposition");
   end;

   ------------------------------------------------------------------
   Section ("8. Streaming Count for N = 6 (no full store)");
   ------------------------------------------------------------------
   declare
      Seen : Natural := 0;
      Prev : SJT.Permutation (1 .. 6) := [others => 1];
      Have_Prev : Boolean := False;
      Adj_OK : Boolean := True;
      All_Perm_OK : Boolean := True;

      procedure Visit (P : SJT.Permutation) is
      begin
         if not SJT.Is_Permutation (P) then
            All_Perm_OK := False;
         end if;
         if Have_Prev then
            if not SJT.Differs_By_Adjacent_Transposition (Prev, P) then
               Adj_OK := False;
            end if;
         end if;
         Prev := P;
         Have_Prev := True;
         Seen := Seen + 1;
      end Visit;
   begin
      SJT.Generate (6, Visit'Access);
      Check (Seen = 720, "N=6 streams 720 permutations");
      Check (Seen = SJT.Count (6), "N=6 stream count = Count(6)");
      Check (All_Perm_OK, "N=6 every streamed value is a permutation");
      Check (Adj_OK, "N=6 consecutive streamed pairs are adjacent swaps");
   end;

   ------------------------------------------------------------------
   Section ("9. Differs_By_Adjacent_Transposition helper");
   ------------------------------------------------------------------
   declare
      A : constant SJT.Permutation := [1, 2, 3];
      B : constant SJT.Permutation := [1, 3, 2];
      C : constant SJT.Permutation := [2, 1, 3];
      D : constant SJT.Permutation := [3, 2, 1];
      E : constant SJT.Permutation := [1, 2];
      F : constant SJT.Permutation := [1, 2, 3, 4];
      One_A : constant SJT.Permutation := [1 => 1];
      One_B : constant SJT.Permutation := [1 => 1];
   begin
      Check (SJT.Differs_By_Adjacent_Transposition (A, B),
             "(1 2 3) vs (1 3 2) is adjacent swap");
      Check (SJT.Differs_By_Adjacent_Transposition (A, C),
             "(1 2 3) vs (2 1 3) is adjacent swap");
      Check (not SJT.Differs_By_Adjacent_Transposition (A, D),
             "(1 2 3) vs (3 2 1) is NOT a single adjacent swap");
      Check (not SJT.Differs_By_Adjacent_Transposition (A, A),
             "identical permutations are not a transposition");
      Check (not SJT.Differs_By_Adjacent_Transposition (A, E),
             "different lengths → False");
      Check (not SJT.Differs_By_Adjacent_Transposition (A, F),
             "different lengths (3 vs 4) → False");
      Check (not SJT.Differs_By_Adjacent_Transposition (One_A, One_B),
             "length-1 pair → False");
   end;

   ------------------------------------------------------------------
   Section ("10. Is_Permutation helper");
   ------------------------------------------------------------------
   Check (SJT.Is_Permutation ([1, 2, 3]), "(1 2 3) is a permutation");
   Check (SJT.Is_Permutation ([3, 1, 2]), "(3 1 2) is a permutation");
   Check (not SJT.Is_Permutation ([1, 2, 2]), "(1 2 2) is not");
   Check (not SJT.Is_Permutation ([1, 2, 4]), "(1 2 4) is not for N=3");
   Check (not SJT.Is_Permutation ([1 => 2]), "(2) is not for N=1");
   declare
      Empty : SJT.Permutation (1 .. 0);
   begin
      Check (not SJT.Is_Permutation (Empty), "empty is not a permutation");
   end;

   ------------------------------------------------------------------
   Section ("11. Max_N streaming Generate");
   ------------------------------------------------------------------
   declare
      Seen : Natural := 0;
      procedure Visit (P : SJT.Permutation) is
         pragma Unreferenced (P);
      begin
         Seen := Seen + 1;
      end Visit;
   begin
      SJT.Generate (SJT.Max_N, Visit'Access);
      Check (Seen = SJT.Max_Count,
             "Generate(Max_N) yields Max_Count permutations");
      Check (Seen = SJT.Factorial (SJT.Max_N),
             "Generate(Max_N) count equals Factorial(Max_N)");
      Check (SJT.Count (SJT.Max_N) = SJT.Max_Count,
             "Count(Max_N) = Max_Count");
   end;

   ------------------------------------------------------------------
   Section ("12. First permutation always identity");
   ------------------------------------------------------------------
   for N in 1 .. 5 loop
      declare
         First_OK : Boolean := False;
         Got      : Boolean := False;

         procedure Visit (P : SJT.Permutation) is
            OK : Boolean := True;
         begin
            if Got then
               return;
            end if;
            Got := True;
            for I in 1 .. N loop
               if P (I) /= I then
                  OK := False;
               end if;
            end loop;
            First_OK := OK;
         end Visit;
      begin
         SJT.Generate (N, Visit'Access);
         Check (First_OK,
                "N=" & Image_N (N) & " starts with identity");
      end;
   end loop;

   New_Line;
   Put_Line
     ("Results:" & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");
end Tests;
