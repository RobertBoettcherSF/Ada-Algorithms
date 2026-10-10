--  Own tests for Search_2D_Matrix (written for this repository; see
--  tests/SOURCES.txt). Assumption: Contains gives a wrong answer for some
--  sorted matrix and target, makes more than floor (log2 64) + 2
--  comparisons, Sorted_Matrix accepts or rejects the wrong matrices, or
--  Cell / Position_Of do not match the matrix entries.
--  Reference: a scan over every row and column of the 2D matrix (it does
--  not use Cell); for the predicate, rows non-decreasing and each row's
--  last entry <= the next row's first entry.
--  Inputs: 5 fixed and 200 random sorted matrices (with repeats), each
--  with every target 0 .. 99; each with one random pair of unequal
--  row-major neighbours swapped (predicate); 2,000 random matrices
--  (predicate).
--  Random inputs: fixed default seed, printed at start; AA_SEED=<n>
--  overrides it.
pragma Ada_2022;
with Ada.Text_IO;
with Ada.Environment_Variables;
with Search_2D_Matrix; use Search_2D_Matrix;

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

   function Floor_Log2 (N : Positive) return Natural is
      K : Natural := 0;
      M : Positive := N;
   begin
      while M > 1 loop
         M := M / 2;
         K := K + 1;
      end loop;
      return K;
   end Floor_Log2;

   Bound : constant Natural := Floor_Log2 (Rows * Cols) + 2;

   function Ref_Sorted (M : Matrix) return Boolean is
   begin
      for R in Row loop
         for C in 1 .. Cols - 1 loop
            if M (R, C) > M (R, C + 1) then
               return False;
            end if;
         end loop;
         if R < Rows and then M (R, Cols) > M (R + 1, 1) then
            return False;
         end if;
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
      Report ((M in Sorted_Matrix) = Ref_Sorted (M), "Sorted_Matrix membership " & Label);
   end Check_Predicate;

   --  Exact counts on three paths, worked by hand. Target <= every cell:
   --  the search always goes left (64 32 16 8 4 2 1 0: 7 halvings) and
   --  compares cell 1 once more: 8. Target > every cell: always right
   --  (64 31 15 7 3 1 0: 6 halvings), no cell left to compare: 6. Target
   --  above cell 63 but not above cell 64: right five times, then left
   --  (64 31 15 7 3 1 0), and cell 64 is compared: 7.
   procedure Check_Counts (M : Matrix; Label : String) is
      procedure Expect_Count (T : Value; Want : Natural; Path : String) is
         Res : constant Search_Result := Contains (M, T);
      begin
         Report (Res.Probes = Want, Label & " target" & T'Image & " (" & Path & "):"
                 & Res.Probes'Image & " comparisons counted, made" & Want'Image);
      end Expect_Count;
   begin
      Expect_Count (M (1, 1), 8, "smallest");
      if M (1, 1) > 0 then
         Expect_Count (M (1, 1) - 1, 8, "below all");
      end if;
      if M (Rows, Cols) < Value'Last then
         Expect_Count (M (Rows, Cols) + 1, 6, "above all");
      end if;
      if M (Rows, Cols - 1) < M (Rows, Cols) then
         Expect_Count (M (Rows, Cols), 7, "last cell");
         Expect_Count (M (Rows, Cols - 1) + 1, 7, "above cell 63");
      end if;
   end Check_Counts;

   procedure Check_Matrix (M : Matrix; Label : String) is
   begin
      Report (Ref_Sorted (M) and then M in Sorted_Matrix, "sorted accepted " & Label);
      if M in Sorted_Matrix then
         for T in Value loop
            declare
               Res : constant Search_Result := Contains (M, T);
            begin
               Report (Res.Found = Ref_Has (M, T), Label & " target" & T'Image & " found " & Res.Found'Image);
               Report (Res.Probes <= Bound, Label & " target" & T'Image & Res.Probes'Image & " comparisons");
               Max_Probes := Natural'Max (Max_Probes, Res.Probes);
            end;
         end loop;
         Check_Counts (M, Label);
      end if;
      --  Swap one pair of unequal row-major neighbours: never sorted.
      declare
         Start : constant Cell_Index := Next (1, Cells - 1);
         X     : Matrix := M;
         Tmp   : Value;
      begin
         for D in 0 .. Cells - 2 loop
            declare
               K  : constant Cell_Index := (Start - 1 + D) mod (Cells - 1) + 1;
               R1 : constant Row := (K - 1) / Cols + 1;
               C1 : constant Column := (K - 1) mod Cols + 1;
               R2 : constant Row := K / Cols + 1;
               C2 : constant Column := K mod Cols + 1;
            begin
               if X (R1, C1) /= X (R2, C2) then
                  Tmp := X (R1, C1);
                  X (R1, C1) := X (R2, C2);
                  X (R2, C2) := Tmp;
                  Check_Predicate (X, "swap " & Label);
                  Report (X not in Sorted_Matrix, "swap rejected " & Label);
                  exit;
               end if;
            end;
         end loop;
      end;
   end Check_Matrix;

   function Random_Sorted return Matrix is
      Result : Matrix := [others => [others => 0]];
      V      : Value := Next (0, 20);
   begin
      for R in Row loop
         for C in Column loop
            Result (R, C) := V;
            V := Integer'Min (Value'Last, V + Next (0, 3));
         end loop;
      end loop;
      return Result;
   end Random_Sorted;
begin
   --  Cell and Position_Of against the matrix entries.
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
   Check_Matrix ([for R in Row => [for C in Column => (R - 1) * Cols + C - 1]], "0 .. 63");
   Check_Matrix ([for R in Row => [for C in Column => ((R - 1) * Cols + C - 1) * 3 / 2 + 1]], "steps");
   Check_Matrix ([for R in Row => [for C in Column => 10 * R]], "rows of equal values");
   Check_Matrix ([others => [others => 0]], "all 0");
   Check_Matrix ([others => [others => 99]], "all 99");
   for Run in 1 .. 200 loop
      Check_Matrix (Random_Sorted, "random" & Run'Image);
   end loop;
   for Run in 1 .. 2000 loop
      declare
         M : Matrix := [for R in Row => [for C in Column => Next (0, 99)]];
      begin
         if Run mod 2 = 0 then
            --  Mostly sorted: sorted, then one entry changed.
            M := Random_Sorted;
            M (Next (1, Rows), Next (1, Cols)) := Next (0, 99);
         end if;
         Check_Predicate (M, "random matrix" & Run'Image);
      end;
   end loop;
   --  Measured worst case: 8 (7 halvings of 65 insertion points + 1).
   Report (Max_Probes = 8, "worst case comparisons" & Max_Probes'Image & ", expected 8");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (205 sorted 8 x 8 matrices x 100 targets vs a 2D scan; comparisons <= floor (log2 64) + 2, worst case 8; predicate; Position_Of)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
