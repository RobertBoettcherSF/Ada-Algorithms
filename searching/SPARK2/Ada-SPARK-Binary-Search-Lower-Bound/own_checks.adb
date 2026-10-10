--  Own tests for Binary_Search_Lower_Bound (written for this repository; see
--  tests/SOURCES.txt). Assumption: Position returns a wrong insertion
--  point for some sorted array (with or without duplicates) and target,
--  or reads more than floor (log2 N) + 2 elements.
--  Reference: a linear scan for the first element >= Target (Length + 1
--  if none). Inputs: 2,000 random sorted arrays (values drawn from a
--  random sub-range of -100 .. 100 and sorted, so duplicates are common),
--  all-equal arrays for every value and a -100 / 100 step at every position,
--  each with every target -100 .. 100. Input_Array membership is checked
--  against a neighbour test on random unsorted arrays.
--  Random inputs: fixed default seed, printed at start; AA_SEED=<n>
--  overrides it.
pragma Ada_2022;
with Ada.Text_IO;
with Ada.Environment_Variables;
with Binary_Search_Lower_Bound; use Binary_Search_Lower_Bound;

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

   Bound : constant Natural := Floor_Log2 (Length) + 2;

   procedure Check_All_Targets (D : Input_Array; Label : String) is
   begin
      for T in Target_Value loop
         declare
            Want : Result_Index := Length + 1;
            R    : constant Search_Result := Find (D, T);
         begin
            for I in reverse Index loop
               if D (I) >= T then
                  Want := I;
               end if;
            end loop;
            Report (R.Position = Want, Label & " target" & T'Image & " got" & R.Position'Image
                    & " want" & Want'Image);
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
      Check_All_Targets ([for I in Index => (if I < P then -100 else 100)], "step at" & P'Image);
   end loop;
   for Run in 1 .. 2000 loop
      declare
         Lo : constant Value := Next (-100, 100);
         Hi : constant Value := Next (Lo, 100);
         A  : Value_Array := [for I in Index => Next (Lo, Hi)];
      begin
         Sort (A);
         Check_All_Targets (A, "random" & Run'Image);
      end;
   end loop;
   for Run in 1 .. 2000 loop
      declare
         A      : constant Value_Array := [for I in Index => Next (-100, 100)];
         Sorted : Boolean := True;
      begin
         for I in 1 .. Length - 1 loop
            Sorted := Sorted and then A (I) <= A (I + 1);
         end loop;
         Report ((A in Input_Array) = Sorted, "Input_Array membership, unsorted run" & Run'Image);
      end;
   end loop;
   --  33 candidate positions need 6 reads in the worst case.
   Report (Max_Reads = 6, "worst case reads" & Max_Reads'Image & ", expected 6");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (2,234 sorted arrays x 201 targets vs linear scan; reads <= floor (log2 N) + 2, worst case 6; predicate)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
