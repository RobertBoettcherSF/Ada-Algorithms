--  Own tests for Kth_Smallest_Matrix (written for this repository; see
--  tests/SOURCES.txt). Assumption: Kth returns the wrong entry for some
--  sorted block and K, miscounts its tries or comparisons, depends on
--  entries outside the block, or Sorted_Square accepts or rejects the
--  wrong squares.
--  Reference: the block sorted by insertion (K-th element); for the
--  predicate, every block entry <= its right neighbour and <= the entry
--  below, checked on (I, J) directly.
--  Inputs: 400 random sorted blocks (N = 1 .. 8 in turn, random values
--  outside the block), every K; constant blocks 0 and 1000 for every N
--  and K (exact counts worked by hand); each random block with one entry
--  lowered below a neighbour (predicate); 2,000 random squares
--  (predicate).
--  Random inputs: fixed default seed, printed at start; AA_SEED=<n>
--  overrides it.
pragma Ada_2022;
with Ada.Text_IO;
with Ada.Environment_Variables;
with Kth_Smallest_Matrix; use Kth_Smallest_Matrix;

procedure Own_Checks is
   procedure Put_Line (S : String) renames Ada.Text_IO.Put_Line;
   Failures  : Natural := 0;
   Checked   : Natural := 0;
   Min_Tries : Natural := Natural'Last;
   Max_Tries : Natural := 0;

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

   function Floor_Log2 (X : Positive) return Natural is
      K : Natural := 0;
      R : Positive := X;
   begin
      while R > 1 loop
         R := R / 2;
         K := K + 1;
      end loop;
      return K;
   end Floor_Log2;

   type Flat is array (Rank range <>) of Integer;

   function Sorted_Block (M : Matrix; N : Dimension) return Flat is
      F    : Flat (1 .. N * N) := [others => 0];
      Last : Natural := 0;
      J    : Natural;
   begin
      for R in 1 .. N loop
         for C in 1 .. N loop
            J := Last;
            while J >= 1 and then F (J) > M (R, C) loop
               F (J + 1) := F (J);
               J := J - 1;
            end loop;
            F (J + 1) := M (R, C);
            Last := Last + 1;
         end loop;
      end loop;
      return F;
   end Sorted_Block;

   function Ref_Sorted (S : Square) return Boolean is
   begin
      for I in 1 .. S.N loop
         for J in 1 .. S.N loop
            if (J < S.N and then S.M (I, J) > S.M (I, J + 1))
              or else (I < S.N and then S.M (I, J) > S.M (I + 1, J))
            then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Ref_Sorted;

   procedure Check_Predicate (S : Square; Label : String) is
   begin
      Report ((S in Sorted_Square) = Ref_Sorted (S), "Sorted_Square membership " & Label);
   end Check_Predicate;

   procedure Check_Square (S : Square; Label : String) is
      Want  : constant Flat := Sorted_Block (S.M, S.N);
      Bound : constant Natural := (Floor_Log2 (Value'Last - Value'First + 1) + 1) * 2 * S.N;
   begin
      Report (Ref_Sorted (S) and then S in Sorted_Square, "sorted accepted " & Label);
      if S in Sorted_Square then
         for K in 1 .. S.N * S.N loop
            declare
               R : constant Kth_Result := Kth (S, K);
            begin
               Report (R.Kth = Want (K), Label & " K" & K'Image & ":" & R.Kth'Image & ", expected" & Want (K)'Image);
               Report (R.Probes <= Bound, Label & " K" & K'Image & ":" & R.Probes'Image & " comparisons");
               Min_Tries := Natural'Min (Min_Tries, R.Tries);
               Max_Tries := Natural'Max (Max_Tries, R.Tries);
            end;
         end loop;
      end if;
   end Check_Square;

   function Random_Sorted (N : Dimension; Step : Positive) return Square is
      S    : Square := (N => N, M => [for I in Dimension => [for J in Dimension => Next (0, 1000)]]);
      Base : Integer;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            Base := 0;
            if I > 1 then
               Base := S.M (I - 1, J);
            end if;
            if J > 1 then
               Base := Integer'Max (Base, S.M (I, J - 1));
            end if;
            S.M (I, J) := Integer'Min (Value'Last, Base + Next (0, Step));
         end loop;
      end loop;
      return S;
   end Random_Sorted;

   --  Constant block V: each count compares one entry per row when
   --  X >= V, or walks row 1 down to column 0 when X < V: N comparisons
   --  either way. The value search for V = 0 always halves to the left
   --  (1000 500 250 125 62 31 15 7 3 1 0: 10 counts); for V = 1000 it
   --  always moves right (1000 499 249 124 61 30 14 6 2 0: 9 counts).
   procedure Check_Constant (V : Value; Want_Tries : Natural) is
   begin
      for N in Dimension loop
         for K in 1 .. N * N loop
            declare
               R : constant Kth_Result := Kth (Square'(N => N, M => [others => [others => V]]), K);
            begin
               Report (R.Kth = V and then R.Tries = Want_Tries and then R.Probes = N * Want_Tries,
                       "constant" & V'Image & " N" & N'Image & " K" & K'Image & ":" & R.Kth'Image
                       & R.Tries'Image & " counts" & R.Probes'Image & " comparisons");
            end;
         end loop;
      end loop;
   end Check_Constant;
begin
   Check_Constant (0, 10);
   Check_Constant (1000, 9);
   for Run in 1 .. 400 loop
      declare
         N : constant Dimension := (Run - 1) mod Matrix_Size + 1;
         S : constant Square := Random_Sorted (N, (if Run mod 3 = 0 then 40 else 1 + Run mod 5));
      begin
         Check_Square (S, "random" & Run'Image & " N" & N'Image);
         --  Lower one block entry below its left or upper neighbour.
         if N > 1 then
            declare
               I : constant Dimension := Next (1, N);
               J : constant Dimension := (if I = 1 then Next (2, N) else Next (1, N));
               X : Square := S;
               B : constant Value := (if J > 1 then S.M (I, J - 1) else S.M (I - 1, J));
            begin
               if B > 0 then
                  X.M (I, J) := B - 1;
                  Check_Predicate (X, "lowered, run" & Run'Image);
                  Report (X not in Sorted_Square, "lowered rejected, run" & Run'Image);
               end if;
            end;
         end if;
      end;
   end loop;
   for Run in 1 .. 2000 loop
      declare
         S : Square := (N => Next (1, Matrix_Size), M => [for I in Dimension => [for J in Dimension => Next (0, 1000)]]);
      begin
         if Run mod 2 = 0 then
            S := Random_Sorted (S.N, 3);
            S.M (Next (1, S.N), Next (1, S.N)) := Next (0, 1000);
         end if;
         Check_Predicate (S, "random square" & Run'Image);
      end;
   end loop;
   --  A value search over 0 .. 1000 always makes 9 or 10 counts.
   Report (Min_Tries = 9 and then Max_Tries = 10,
           "counts per search" & Min_Tries'Image & " .." & Max_Tries'Image & ", expected 9 .. 10");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (400 random sorted blocks x every K vs an insertion sort, values outside the block random; constant blocks with exact counts; comparisons <= (floor (log2 1001) + 1) * 2 * N; predicate)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
