--  Own tests for Find_Minimum_In_Rotated_Sorted_Array_II (written for
--  this repository; see tests/SOURCES.txt). Assumption: Find_Minimum or
--  Minimum returns a value that is not the smallest for some rotated
--  non-decreasing array (duplicates allowed), makes more than
--  floor (log2 N) + 2 comparisons when the values are distinct, or
--  Rotated_Array accepts or rejects the wrong arrays.
--  Reference: a linear minimum; for the predicate, a count of cyclic
--  strict falls (D (K) > D (K mod N + 1)), at most 1 for a turned
--  non-decreasing array.
--  Inputs: all 8 rotations of 3,000 random non-decreasing arrays (values
--  from a random range, often only 2 or 3 values, so runs of duplicates
--  are common) and of 1,000 random strictly increasing ones (comparison
--  bound); all equal but one with the odd value at every position, below
--  and above the rest; 20,000 random arrays (predicate).
--  Random inputs: fixed default seed, printed at start; AA_SEED=<n>
--  overrides it.
pragma Ada_2022;
with Ada.Text_IO;
with Ada.Environment_Variables;
with Find_Minimum_In_Rotated_Sorted_Array_II; use Find_Minimum_In_Rotated_Sorted_Array_II;

procedure Own_Checks is
   procedure Put_Line (S : String) renames Ada.Text_IO.Put_Line;
   Failures      : Natural := 0;
   Checked       : Natural := 0;
   Max_Distinct  : Natural := 0;
   Max_Any       : Natural := 0;

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

   Seed : Long_Long_Integer := AA_Seed (20261008);

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

   Bound : constant Natural := Floor_Log2 (Length) + 2;

   function At_Most_One_Fall (D : Value_Array) return Boolean is
      Falls : Natural := 0;
   begin
      for K in Index loop
         if D (K) > D (K mod Length + 1) then
            Falls := Falls + 1;
         end if;
      end loop;
      return Falls <= 1;
   end At_Most_One_Fall;

   function Linear_Min (D : Value_Array) return Value is
      M : Value := D (1);
   begin
      for K in Index loop
         M := Value'Min (M, D (K));
      end loop;
      return M;
   end Linear_Min;

   function Turn (Base : Value_Array; S : Natural) return Value_Array is
     [for I in Index => Base (((I - 1 + S) mod Length) + 1)];

   procedure Sort (A : in out Value_Array) is
      T : Value;
   begin
      for I in 2 .. Length loop
         for J in reverse 2 .. I loop
            exit when A (J - 1) <= A (J);
            T := A (J);
            A (J) := A (J - 1);
            A (J - 1) := T;
         end loop;
      end loop;
   end Sort;

   procedure Check (D : Value_Array; Distinct : Boolean; Label : String) is
   begin
      Report (D in Rotated_Array, "accepted " & Label);
      if D in Rotated_Array then
         declare
            R : constant Search_Result := Find_Minimum (D);
         begin
            Report (D (R.Position) = Linear_Min (D), Label & " got" & D (R.Position)'Image);
            Report (Minimum (D) = Linear_Min (D), "Minimum " & Label);
            if Distinct then
               Report (R.Probes <= Bound, Label & R.Probes'Image & " comparisons");
               Max_Distinct := Natural'Max (Max_Distinct, R.Probes);
            end if;
            Max_Any := Natural'Max (Max_Any, R.Probes);
         end;
      end if;
   end Check;

   procedure Check_Base (Base : Value_Array; Distinct : Boolean; Label : String) is
   begin
      for S in 0 .. Length - 1 loop
         Check (Turn (Base, S), Distinct, Label & " turned" & S'Image);
      end loop;
   end Check_Base;
begin
   for P in Index loop
      Check ([for I in Index => (if I = P then 0 else 1)], False, "single 0 at" & P'Image);
      Check ([for I in Index => (if I = P then 1 else 0)], False, "single 1 at" & P'Image);
   end loop;
   for Run in 1 .. 3000 loop
      declare
         Lo : constant Value := Next (-1000, 1000);
         Hi : constant Value := Integer'Min (1000, Lo + (if Run mod 2 = 0 then Next (1, 2) else Next (1, 2000)));
         B  : Value_Array := [for I in Index => Next (Lo, Hi)];
      begin
         Sort (B);
         Check_Base (B, False, "random" & Run'Image);
      end;
   end loop;
   for Run in 1 .. 1000 loop
      declare
         B : Value_Array;
      begin
         B (1) := Next (-1000, 1000 - 7 * 20);
         for I in 2 .. Length loop
            B (I) := B (I - 1) + Next (1, 20);
         end loop;
         Check_Base (B, True, "distinct" & Run'Image);
      end;
   end loop;
   for Run in 1 .. 20_000 loop
      declare
         D : constant Value_Array := [for I in Index => Next (0, 3)];
      begin
         Report ((D in Rotated_Array) = At_Most_One_Fall (D), "Rotated_Array membership, run" & Run'Image);
      end;
   end loop;
   Report (Max_Distinct = 3, "worst case comparisons, distinct" & Max_Distinct'Image & ", expected 3");
   --  With duplicates: 2 * (N - 1) = 14, reached on all-equal arrays
   --  (each shrink step compares Mid with Hi, then Hi - 1 with Hi).
   Report (Max_Any = 2 * (Length - 1), "worst case comparisons" & Max_Any'Image & ", expected 14");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (all rotations of 4,000 arrays vs a linear minimum; distinct: comparisons <= floor (log2 N) + 2, worst case 3; with duplicates worst case"
                & Max_Any'Image & "; predicate)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
   end if;
end Own_Checks;
