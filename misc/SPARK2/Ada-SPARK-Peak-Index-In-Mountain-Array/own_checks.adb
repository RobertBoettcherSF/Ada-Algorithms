--  Own tests for Peak_Index_In_Mountain_Array (written for this
--  repository; see tests/SOURCES.txt). Assumption: Peak_Index returns a
--  wrong peak for some mountain, or makes more than floor (log2 N) + 2
--  comparisons, or Mountain_Array accepts or rejects the wrong arrays.
--  Reference: the index of the largest element (linear arg-max), and
--  for membership a direct existential test (some P such that the array
--  rises strictly up to P and falls strictly after it).
--  Inputs: for every peak position, mountains with steps of 1 and
--  random steps; 20,000 random mountains; 20,000 mountains with one
--  element changed, checked for membership.
--  Random inputs: fixed default seed, printed at start; AA_SEED=<n>
--  overrides it.
pragma Ada_2022;
with Ada.Text_IO;
with Ada.Environment_Variables;
with Peak_Index_In_Mountain_Array; use Peak_Index_In_Mountain_Array;

procedure Own_Checks is
   procedure Put_Line (S : String) renames Ada.Text_IO.Put_Line;
   Failures   : Natural := 0;
   Checked    : Natural := 0;
   Max_Probes : Natural := 0;
   Valid      : Natural := 0;
   Invalid    : Natural := 0;

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

   function Arg_Max (A : Value_Array) return Index is
      Best : Index := 1;
   begin
      for I in Index loop
         if A (I) > A (Best) then
            Best := I;
         end if;
      end loop;
      return Best;
   end Arg_Max;

   function Is_Mountain (A : Value_Array) return Boolean is
   begin
      for P in 2 .. Length - 1 loop
         declare
            Ok : Boolean := True;
         begin
            for I in 1 .. Length - 1 loop
               Ok := Ok and then (if I < P then A (I) < A (I + 1) else A (I) > A (I + 1));
            end loop;
            if Ok then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Is_Mountain;

   --  Peak value Top at P; steps down on each side drawn from 1 .. Step.
   function Random_Mountain (P : Peak_Range; Step : Positive) return Value_Array is
      Top : constant Value := Next (-1000 + 31 * Step, 1000);
      A   : Value_Array;
   begin
      A (P) := Top;
      for I in reverse 1 .. P - 1 loop
         A (I) := A (I + 1) - Next (1, Step);
      end loop;
      for I in P + 1 .. Length loop
         A (I) := A (I - 1) - Next (1, Step);
      end loop;
      return A;
   end Random_Mountain;

   procedure Check (A : Value_Array; Label : String) is
   begin
      Report (A in Mountain_Array, Label & " not accepted as a mountain");
      if A in Mountain_Array then
         declare
            R : constant Search_Result := Peak_Index (A);
         begin
            Report (R.Position = Arg_Max (A), Label & " got" & R.Position'Image
                    & " want" & Arg_Max (A)'Image);
            Report (R.Probes <= Bound, Label & R.Probes'Image & " comparisons");
            Max_Probes := Natural'Max (Max_Probes, R.Probes);
         end;
      end if;
   end Check;
begin
   for P in Peak_Range loop
      Check ([for I in Index => -abs (I - P)], "steps of 1, peak at" & P'Image);
      for Run in 1 .. 50 loop
         Check (Random_Mountain (P, Next (1, 30)), "random steps, peak at" & P'Image);
      end loop;
   end loop;
   for Run in 1 .. 20_000 loop
      Check (Random_Mountain (Next (2, Length - 1), Next (1, 30)), "random mountain" & Run'Image);
   end loop;
   for Run in 1 .. 20_000 loop
      declare
         A : Value_Array := Random_Mountain (Next (2, Length - 1), Next (1, 3));
         I : constant Index := Next (1, Length);
      begin
         A (I) := Integer'Max (Value'First, Integer'Min (Value'Last, A (I) + Next (-6, 6)));
         Report ((A in Mountain_Array) = Is_Mountain (A), "Mountain_Array membership, run" & Run'Image);
         if Is_Mountain (A) then
            Valid := Valid + 1;
         else
            Invalid := Invalid + 1;
         end if;
      end;
   end loop;
   Report (Valid > 1000 and Invalid > 1000, "membership mix" & Valid'Image & " valid," & Invalid'Image & " invalid");
   --  30 candidate slopes need 5 comparisons in the worst case.
   Report (Max_Probes = 5, "worst case comparisons" & Max_Probes'Image & ", expected 5");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (21,530 mountains vs arg-max; comparisons <= floor (log2 N) + 2, worst case 5; predicate vs existential on 20,000 edited mountains)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
