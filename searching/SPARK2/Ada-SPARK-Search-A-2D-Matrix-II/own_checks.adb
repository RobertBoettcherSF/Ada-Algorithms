--  Own tests for Search_A_2D_Matrix_II (written for this repository; see
--  tests/SOURCES.txt). Assumption: Contains gives a wrong answer for some
--  row- and column-sorted matrix and target, makes more than
--  Rows + Cols - 1 comparisons, Staircase_Matrix accepts or rejects the
--  wrong matrices, or Cell / Position_Of do not match the entries.
--  Reference: a scan over every row and column of the 2D matrix (it does
--  not use Cell); for the predicate, every entry <= its right neighbour
--  and <= the entry below, checked on (R, C) directly.
--  Inputs: 5 fixed and 300 random sorted matrices, each with every
--  target 0 .. 100, and exact counts below / above every entry and for
--  every target of 1 .. 64; each with one entry lowered below its left or upper
--  neighbour (predicate, always rejected); 2,000 random matrices, half of
--  them sorted with one entry changed (predicate).
--  Random inputs: fixed default seed, printed at start; AA_SEED=<n>
--  overrides it.
pragma Ada_2022;
with Ada.Text_IO;
with Ada.Environment_Variables;
with Search_A_2D_Matrix_II; use Search_A_2D_Matrix_II;

procedure Own_Checks is
   procedure Put_Line (S : String) renames Ada.Text_IO.Put_Line;
   Failures   : Natural := 0;
   Checked    : Natural := 0;
   Max_Probes : Natural := 0;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := 1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646;
      end if;
      Put_Line ("AA_SEED =" & S'Image & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (20261009);

   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Ref_Sorted (M : Matrix) return Boolean is
   begin
      for R in Row loop
         for C in Column loop
            if (C < Cols and then M (R, C) > M (R, C + 1))
              or else (R < Rows and then M (R, C) > M (R + 1, C))
            then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Ref_Sorted;

   function Ref_Has (M : Matrix; T : Value) return Boolean is
   begin
      for R in Row loop
         for C in Column loop
            if M (R, C) = T then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Ref_Has;

   procedure Check_Predicate (M : Matrix; Label : String) is
   begin
      Report ((M in Staircase_Matrix) = Ref_Sorted (M), "Staircase_Matrix membership " & Label);
   end Check_Predicate;

   procedure Check_Matrix (M : Matrix; Label : String) is
   begin
      Report (Ref_Sorted (M) and then M in Staircase_Matrix, "sorted accepted " & Label);
      if M in Staircase_Matrix then
         for T in Value loop
            declare
               Res : constant Search_Result := Contains (M, T);
            begin
               Report (Res.Found = Ref_Has (M, T), Label & " target" & T'Image & " found " & Res.Found'Image);
               Report (Res.Probes >= 1, Label & " target" & T'Image & ": no comparison counted");
               --  The top-right entry is always compared first.
               Report (Res.Probes = 1 or else T /= M (1, Cols),
                       Label & " target" & T'Image & " at the top-right corner:" & Res.Probes'Image);
               Max_Probes := Natural'Max (Max_Probes, Res.Probes);
            end;
         end loop;
         --  Exact counts: below every entry the walk goes left along row 1
         --  (8 comparisons); above every entry it goes down column 8 (8).
         if M (1, 1) > 0 then
            Report (Contains (M, M (1, 1) - 1).Probes = Cols, Label & " below all: count");
         end if;
         if M (Rows, Cols) < Value'Last then
            Report (Contains (M, M (Rows, Cols) + 1).Probes = Rows, Label & " above all: count");
         end if;
      end if;
      --  Lower one entry that has a left or upper neighbour below that
      --  neighbour: never sorted.
      declare
         R : constant Row := Next (1, Rows);
         C : constant Column := (if R = 1 then Next (2, Cols) else Next (1, Cols));
         X : Matrix := M;
         N : constant Value := (if C > 1 then M (R, C - 1) else M (R - 1, C));
      begin
         if N > 0 then
            X (R, C) := N - 1;
            Check_Predicate (X, "lowered " & Label);
            Report (X not in Staircase_Matrix, "lowered rejected " & Label);
         end if;
      end;
   end Check_Matrix;

   function Random_Sorted (Step : Positive) return Matrix is
      Result : Matrix := [others => [others => 0]];
      Base   : Value;
   begin
      for R in Row loop
         for C in Column loop
            Base := 0;
            if R > 1 then
               Base := Result (R - 1, C);
            end if;
            if C > 1 then
               Base := Integer'Max (Base, Result (R, C - 1));
            end if;
            Result (R, C) := Integer'Min (Value'Last, Base + Next (0, Step));
         end loop;
      end loop;
      return Result;
   end Random_Sorted;
begin
   declare
      M : constant Matrix := [for R in Row => [for C in Column => (R - 1) * Cols + C]];
   begin
      for R in Row loop
         for C in Column loop
            Report (Position_Of (R, C) = (R - 1) * Cols + C
                    and then Cell (M, Position_Of (R, C)) = M (R, C),
                    "Position_Of" & R'Image & C'Image);
         end loop;
      end loop;
   end;
   Check_Matrix ([for R in Row => [for C in Column => (R - 1) * Cols + C]], "1 .. 64");
   --  Distinct values 1 .. 64: the walk reaches the cell (R, C) of the
   --  target by R - 1 steps down and Cols - C steps left, one comparison
   --  each, plus the comparison that finds it.
   for R in Row loop
      for C in Column loop
         Report (Contains ([for I in Row => [for J in Column => (I - 1) * Cols + J]], (R - 1) * Cols + C).Probes
                   = (R - 1) + (Cols - C) + 1,
                 "1 .. 64 count at" & R'Image & C'Image);
      end loop;
   end loop;
   Check_Matrix ([for R in Row => [for C in Column => 4 * R + 3 * C]], "4 R + 3 C");
   Check_Matrix ([for R in Row => [for C in Column => R + C]], "R + C");
   Check_Matrix ([for R in Row => [for C in Column => 10 * C + R]], "10 C + R");
   Check_Matrix ([others => [others => 50]], "all 50");
   for Run in 1 .. 300 loop
      Check_Matrix (Random_Sorted (1 + Run mod 6), "random" & Run'Image);
   end loop;
   for Run in 1 .. 2000 loop
      declare
         M : Matrix := [for R in Row => [for C in Column => Next (0, 100)]];
      begin
         if Run mod 2 = 0 then
            M := Random_Sorted (3);
            M (Next (1, Rows), Next (1, Cols)) := Next (0, 100);
         end if;
         Check_Predicate (M, "random matrix" & Run'Image);
      end;
   end loop;
   --  Measured worst case: 15 = Rows + Cols - 1 (the whole staircase).
   Report (Max_Probes = Rows + Cols - 1, "worst case comparisons" & Max_Probes'Image & ", expected 15");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (305 row- and column-sorted 8 x 8 matrices x 101 targets vs a 2D scan; comparisons <= Rows + Cols - 1, worst case 15; predicate; Position_Of)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
