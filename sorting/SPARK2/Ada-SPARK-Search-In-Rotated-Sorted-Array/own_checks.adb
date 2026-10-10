--  Own tests for Search_In_Rotated_Sorted_Array (written for this
--  repository; see tests/SOURCES.txt). Assumption: Contains gives a
--  wrong answer for some rotation and target, makes more than
--  2 * (floor (log2 N) + 2) comparisons, or Rotated_Array accepts or
--  rejects the wrong arrays.
--  Reference: a linear membership scan; for the predicate, a count of
--  cyclic non-rises (D (K) >= D (K mod N + 1)), which is exactly 1 for a
--  turned strictly increasing array.
--  Inputs: all 32 rotations of 4 fixed and 100 random strictly
--  increasing arrays, each with every target 0 .. 100; each rotation
--  also with two neighbours swapped and with one neighbour copied
--  (predicate); 2,000 random arrays (predicate).
--  Random inputs: fixed default seed, printed at start; AA_SEED=<n>
--  overrides it.
pragma Ada_2022;
with Ada.Text_IO;
with Ada.Environment_Variables;
with Search_In_Rotated_Sorted_Array; use Search_In_Rotated_Sorted_Array;

procedure Own_Checks is
   procedure Put_Line (S : String) renames Ada.Text_IO.Put_Line;
   Failures   : Natural := 0;
   Checked    : Natural := 0;
   Max_Probes : Natural := 0;
   Max_Turned : Natural := 0;   --  worst case over turned arrays only

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

   function One_Cyclic_Descent (D : Data_Array) return Boolean is
      Steps : Natural := 0;
   begin
      for K in Index loop
         if D (K) >= D (K mod Length + 1) then
            Steps := Steps + 1;
         end if;
      end loop;
      return Steps = 1;
   end One_Cyclic_Descent;

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

   procedure Check_Predicate (D : Data_Array; Label : String) is
   begin
      Report ((D in Rotated_Array) = One_Cyclic_Descent (D), "Rotated_Array membership " & Label);
   end Check_Predicate;

   procedure Check_Base (Base : Data_Array; Label : String) is
   begin
      for S in 0 .. Length - 1 loop
         declare
            D   : constant Data_Array := Turn (Base, S);
            Tag : constant String := Label & " turned" & S'Image;
         begin
            Report (One_Cyclic_Descent (D) and then D in Rotated_Array, "rotation accepted " & Tag);
            if D in Rotated_Array then
               for T in Value loop
                  declare
                     R : constant Search_Result := Contains (D, T);
                  begin
                     Report (R.Found = Linear_Has (D, T), Tag & " target" & T'Image & " found " & R.Found'Image);
                     Report (R.Probes <= Bound, Tag & " target" & T'Image & R.Probes'Image & " comparisons");
                     Max_Probes := Natural'Max (Max_Probes, R.Probes);
                     if D (1) > D (Length) then
                        Max_Turned := Natural'Max (Max_Turned, R.Probes);
                     end if;
                  end;
               end loop;
            end if;
            declare
               J : constant Index := Next (1, Length);
               N : constant Index := J mod Length + 1;
               X : Data_Array := D;
               T : Value;
            begin
               T := X (J);
               X (J) := X (N);
               X (N) := T;
               Check_Predicate (X, "swap " & Tag);
               X := D;
               X (N) := X (J);
               Check_Predicate (X, "copy " & Tag);
               Report (X not in Rotated_Array, "copy rejected " & Tag);
            end;
         end;
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
   Check_Base ([for I in Index => I - 1], "0 .. 31");
   Check_Base ([for I in Index => 2 * (I - 1)], "0, 2 .. 62");
   Check_Base ([for I in Index => 68 + I], "69 .. 100");
   Check_Base ([for I in Index => 3 * I + 4], "7, 10 .. 100");
   for Run in 1 .. 100 loop
      Check_Base (Random_Increasing, "random" & Run'Image);
   end loop;
   for Run in 1 .. 2000 loop
      Check_Predicate ([for I in Index => Next (0, 100)], "random array" & Run'Image);
   end loop;
   --  Measured worst case: 12 comparisons (5 + 6 + 1 when not turned,
   --  5 + 1 + 5 + 1 otherwise, since a part is then at most 31 long).
   Report (Max_Probes = 12, "worst case comparisons" & Max_Probes'Image & ", expected 12");
   --  Turned arrays reach 12 too (5 + 1 + 5 + 1): the comparison picking
   --  the part must be counted.
   Report (Max_Turned = 12, "worst case comparisons on turned arrays" & Max_Turned'Image & ", expected 12");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (all 32 rotations of 104 increasing arrays x 101 targets vs a linear scan; comparisons <= 2 * (floor (log2 N) + 2), worst case 12; predicate)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
