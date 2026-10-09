--  Own tests for Find_Peak_Element (written for this repository; see
--  tests/SOURCES.txt). Assumption: Find_Peak returns an index that is
--  not a peak for some array with distinct neighbours, or makes more
--  than floor (log2 N) + 2 comparisons, or Input_Array accepts or
--  rejects the wrong arrays.
--  Reference: the set of all peaks, found by a linear pass that compares
--  every element with both neighbours (ends: one neighbour), written
--  here without using Is_Peak.
--  Inputs: a single peak at every position; strictly rising and falling
--  arrays; 50,000 random arrays with distinct neighbours (values from a
--  random range, as narrow as 2 values, so peaks are many and dense);
--  membership on 20,000 random arrays.
--  Random inputs: fixed default seed, printed at start; AA_SEED=<n>
--  overrides it.
pragma Ada_2022;
with Ada.Text_IO;
with Ada.Environment_Variables;
with Find_Peak_Element; use Find_Peak_Element;

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

   type Peak_Set is array (Index) of Boolean;

   function Peaks (A : Value_Array) return Peak_Set is
      S : Peak_Set := [others => True];
   begin
      for I in 1 .. Length - 1 loop
         if A (I) < A (I + 1) then
            S (I) := False;       --  I has a larger right neighbour
         else
            S (I + 1) := False;   --  I + 1 has a larger (or equal) left neighbour
         end if;
      end loop;
      return S;
   end Peaks;

   procedure Check (A : Value_Array; Label : String; Only : Natural := 0) is
   begin
      Report (A in Input_Array, Label & " not accepted");
      if A in Input_Array then
         declare
            R : constant Search_Result := Find_Peak (A);
            S : constant Peak_Set := Peaks (A);
         begin
            Report (S (R.Position), Label & " got" & R.Position'Image & ", not a peak");
            Report (Only = 0 or else R.Position = Only, Label & " got" & R.Position'Image
                    & ", only peak" & Only'Image);
            Report (R.Probes <= Bound, Label & R.Probes'Image & " comparisons");
            Max_Probes := Natural'Max (Max_Probes, R.Probes);
         end;
      end if;
   end Check;

   function Random_Distinct (Lo, Hi : Value) return Value_Array is
      A : Value_Array;
   begin
      A (1) := Next (Lo, Hi);
      for I in 2 .. Length loop
         A (I) := Next (Lo, Hi - 1);
         if A (I) >= A (I - 1) then
            A (I) := A (I) + 1;   --  uniform over Lo .. Hi without A (I - 1)
         end if;
      end loop;
      return A;
   end Random_Distinct;
begin
   for P in Index loop
      Check ([for I in Index => -abs (I - P)], "single peak at" & P'Image, Only => P);
      Check ([for I in Index => (if I <= P then I - P else -3 * (I - P))], "skewed peak at" & P'Image, Only => P);
   end loop;
   Check ([for I in Index => I], "rising", Only => Length);
   Check ([for I in Index => -I], "falling", Only => 1);
   for Run in 1 .. 50_000 loop
      declare
         Lo : constant Value := Next (-1000, 999);
         Hi : constant Value := Next (Lo + 1, Integer'Min (1000, Lo + (if Run mod 2 = 0 then 3 else 2000)));
      begin
         Check (Random_Distinct (Lo, Hi), "random" & Run'Image);
      end;
   end loop;
   for Run in 1 .. 20_000 loop
      declare
         A        : constant Value_Array := [for I in Index => Next (0, 30)];
         Distinct : Boolean := True;
      begin
         for I in 1 .. Length - 1 loop
            Distinct := Distinct and then A (I) /= A (I + 1);
         end loop;
         Report ((A in Input_Array) = Distinct, "Input_Array membership, run" & Run'Image);
      end;
   end loop;
   --  32 candidates need 5 comparisons in the worst case.
   Report (Max_Probes = 5, "worst case comparisons" & Max_Probes'Image & ", expected 5");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (50,066 arrays vs the set of all peaks; comparisons <= floor (log2 N) + 2, worst case 5; predicate)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
   end if;
end Own_Checks;
