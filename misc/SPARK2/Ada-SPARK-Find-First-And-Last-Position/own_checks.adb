--  Own tests for Find_First_And_Last_Position (written for this
--  repository; see
--  tests/SOURCES.txt). Assumption: Locate returns a wrong run for some
--  sorted array (with or without duplicates) and target, or reads more
--  than 2 * (floor (log2 N) + 2) elements.
--  Reference: a linear scan recording the first and last position equal
--  to Target (0, 0 if none). Inputs: 2,000 random sorted arrays (values drawn from a
--  random sub-range of 0 .. 100 and sorted, so duplicates are common),
--  all-equal arrays for every value and a 0 / 100 step at every position,
--  each with every target 0 .. 100. Sorted_Array membership is checked
--  against a neighbour test on random unsorted arrays.
--  Random inputs: fixed default seed, printed at start; AA_SEED=<n>
--  overrides it.
pragma Ada_2022;
with Ada.Text_IO;
with Ada.Environment_Variables;
with Find_First_And_Last_Position; use Find_First_And_Last_Position;

procedure Own_Checks is
   procedure Put_Line (S : String) renames Ada.Text_IO.Put_Line;
   Failures  : Natural := 0;
   Checked   : Natural := 0;
   Max_Reads : Natural := 0;

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

   Bound : constant Natural := 2 * (Floor_Log2 (Length) + 2);

   procedure Check_All_Targets (D : Sorted_Array; Label : String) is
   begin
      for T in Value loop
         declare
            First, Last : Boundary := 0;
            R : constant Match_Range := Locate (D, T);
         begin
            for I in Index loop
               if D (I) = T then
                  if First = 0 then
                     First := I;
                  end if;
                  Last := I;
               end if;
            end loop;
            Report (R.First = First and then R.Last = Last,
                    Label & " target" & T'Image & " got" & R.First'Image & R.Last'Image
                    & " want" & First'Image & Last'Image);
            Report (R.Probes <= Bound, Label & " target" & T'Image & " reads" & R.Probes'Image);
            Max_Reads := Natural'Max (Max_Reads, R.Probes);
         end;
      end loop;
   end Check_All_Targets;

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
begin
   for V in Value loop
      Check_All_Targets ([others => V], "all" & V'Image);
   end loop;
   for P in 1 .. Length + 1 loop
      Check_All_Targets ([for I in Index => (if I < P then 0 else 100)], "step at" & P'Image);
   end loop;
   for Run in 1 .. 2000 loop
      declare
         Lo : constant Value := Next (0, 100);
         Hi : constant Value := Next (Lo, 100);
         A  : Value_Array := [for I in Index => Next (Lo, Hi)];
      begin
         Sort (A);
         Check_All_Targets (A, "random" & Run'Image);
      end;
   end loop;
   for Run in 1 .. 2000 loop
      declare
         A      : constant Value_Array := [for I in Index => Next (0, 100)];
         Sorted : Boolean := True;
      begin
         for I in 1 .. Length - 1 loop
            Sorted := Sorted and then A (I) <= A (I + 1);
         end loop;
         Report ((A in Sorted_Array) = Sorted, "Sorted_Array membership, unsorted run" & Run'Image);
      end;
   end loop;
   --  Two searches over 33 boundaries: 12 reads in the worst case.
   Report (Max_Reads = 12, "worst case reads" & Max_Reads'Image & ", expected 12");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (2,134 sorted arrays x 101 targets vs linear scan; reads <= 2 * (floor (log2 N) + 2), worst case 12; predicate)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
