--  Own tests for Search_In_Rotated_Sorted_Array_II (written for this
--  repository; see tests/SOURCES.txt). Assumption: Contains gives a
--  wrong answer for some rotated non-decreasing array (duplicates
--  allowed) and target, makes more than 2 * (floor (log2 N) + 2)
--  comparisons when the values are distinct, or Rotated_Array accepts
--  or rejects the wrong arrays.
--  Reference: a linear membership scan; for the predicate, at most one
--  cyclic strict fall (D (K) > D (K mod N + 1)).
--  Inputs: all 32 rotations of 60 random non-decreasing arrays (half
--  from 2 or 3 values) and of 30 random strictly increasing ones, each
--  with every target 0 .. 100; all equal but one, the odd value at every
--  position, with targets 0 .. 2; 20,000 random arrays (predicate).
--  Random inputs: fixed default seed, printed at start; AA_SEED=<n>
--  overrides it.
pragma Ada_2022;
with Ada.Text_IO;
with Ada.Environment_Variables;
with Search_In_Rotated_Sorted_Array_II; use Search_In_Rotated_Sorted_Array_II;

procedure Own_Checks is
   procedure Put_Line (S : String) renames Ada.Text_IO.Put_Line;
   Failures     : Natural := 0;
   Checked      : Natural := 0;
   Max_Distinct : Natural := 0;
   Max_Any      : Natural := 0;

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

   function At_Most_One_Fall (D : Data_Array) return Boolean is
      Falls : Natural := 0;
   begin
      for K in Index loop
         if D (K) > D (K mod Length + 1) then
            Falls := Falls + 1;
         end if;
      end loop;
      return Falls <= 1;
   end At_Most_One_Fall;

   function Linear_Has (D : Data_Array; T : Value) return Boolean is
   begin
      for K in Index loop
         if D (K) = T then
            return True;
         end if;
      end loop;
      return False;
   end Linear_Has;

   function Turn (Base : Data_Array; S : Natural) return Data_Array is
     [for I in Index => Base (((I - 1 + S) mod Length) + 1)];

   procedure Sort (A : in out Data_Array) is
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

   procedure Check (D : Data_Array; Lo_T, Hi_T : Value; Distinct : Boolean; Label : String) is
   begin
      Report (D in Rotated_Array, "accepted " & Label);
      if D in Rotated_Array then
         for T in Lo_T .. Hi_T loop
            declare
               R : constant Search_Result := Contains (D, T);
            begin
               Report (R.Found = Linear_Has (D, T), Label & " target" & T'Image & " found " & R.Found'Image);
               if Distinct then
                  Report (R.Probes <= Bound, Label & " target" & T'Image & R.Probes'Image & " comparisons");
                  Max_Distinct := Natural'Max (Max_Distinct, R.Probes);
               end if;
               Max_Any := Natural'Max (Max_Any, R.Probes);
            end;
         end loop;
      end if;
   end Check;

   procedure Check_Base (Base : Data_Array; Distinct : Boolean; Label : String) is
   begin
      for S in 0 .. Length - 1 loop
         Check (Turn (Base, S), Value'First, Value'Last, Distinct, Label & " turned" & S'Image);
      end loop;
   end Check_Base;

   function Random_Increasing return Data_Array is
      Result : Data_Array := [others => 0];
      Need   : Natural := Length;
      Pos    : Natural := 0;
   begin
      for V in Value loop
         if Need > 0 and then Next (1, Value'Last - V + 1) <= Need then
            Pos := Pos + 1;
            Result (Pos) := V;
            Need := Need - 1;
         end if;
      end loop;
      return Result;
   end Random_Increasing;
begin
   for P in Index loop
      Check ([for I in Index => (if I = P then 0 else 1)], 0, 2, False, "single 0 at" & P'Image);
      Check ([for I in Index => (if I = P then 1 else 0)], 0, 2, False, "single 1 at" & P'Image);
   end loop;
   for Run in 1 .. 60 loop
      declare
         Lo : constant Value := Next (0, 99);
         Hi : constant Value := Integer'Min (100, Lo + (if Run mod 2 = 0 then Next (1, 2) else Next (1, 100)));
         B  : Data_Array := [for I in Index => Next (Lo, Hi)];
      begin
         Sort (B);
         Check_Base (B, False, "random" & Run'Image);
      end;
   end loop;
   for Run in 1 .. 30 loop
      Check_Base (Random_Increasing, True, "distinct" & Run'Image);
   end loop;
   for Run in 1 .. 20_000 loop
      declare
         D : constant Data_Array := [for I in Index => (if Next (1, 4) = 1 then Next (0, 3) else 2)];
      begin
         Report ((D in Rotated_Array) = At_Most_One_Fall (D), "Rotated_Array membership, run" & Run'Image);
      end;
   end loop;
   --  Distinct values: 5 + 1 + 5 + 1 or 5 + 6 + 1, so 12 at most.
   Report (Max_Distinct = 12, "worst case comparisons, distinct" & Max_Distinct'Image & ", expected 12");
   Report (Max_Any <= Length + 7, "worst case comparisons" & Max_Any'Image);
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (all rotations of 90 arrays x 101 targets vs a linear scan; distinct: comparisons <= 2 * (floor (log2 N) + 2), worst case 12; with duplicates worst case"
                & Max_Any'Image & "; predicate)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
   end if;
end Own_Checks;
