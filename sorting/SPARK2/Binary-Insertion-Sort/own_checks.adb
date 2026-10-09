--  Own property tests for Binary_Insertion_Sort.Sort (written for this repository; see
--  tests/SOURCES.txt). No expected value is taken from the program: every
--  check is a property of a correct sort (output nondecreasing, output a
--  permutation of the input), a comparison with the own insertion sort
--  below, the comparison bound, or an exact comparison count worked by
--  hand.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Binary_Insertion_Sort; use Binary_Insertion_Sort;

procedure Own_Checks is
   Failures   : Natural := 0;
   Cases      : Natural := 0;
   Max_Probes : Natural := 0;
   --  Binary insertion of element I + 1 into I sorted ones: at most
   --  floor (log2 I) + 1 comparisons; 17 in all for 8 elements.
   Bound : constant := 17;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20_261_008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;

   --  Own reference: straight insertion sort.
   function Reference (A : Input_Array) return Input_Array is
      B : Input_Array := A;
      T : Value;
      J : Index;
   begin
      for I in Index'First + 1 .. Index'Last loop
         T := B (I);
         J := I;
         while J > Index'First and then B (J - 1) > T loop
            B (J) := B (J - 1);
            J := J - 1;
         end loop;
         B (J) := T;
      end loop;
      return B;
   end Reference;

   procedure Check_One (A : Input_Array; Label : String) is
      S      : constant Sort_Result := Sort (A);
      R      : constant Input_Array := S.Sorted;
      type Counts is array (Value) of Natural;
      C_In   : Counts := [others => 0];
      C_Out  : Counts := [others => 0];
      Ok     : Boolean := True;
   begin
      Cases := Cases + 1;
      for I in Index loop
         C_In (A (I)) := C_In (A (I)) + 1;
         C_Out (R (I)) := C_Out (R (I)) + 1;
         if I < Index'Last and then R (I) > R (I + 1) then
            Ok := False;
         end if;
      end loop;
      if C_In /= C_Out or else R /= Reference (A) then
         Ok := False;
      end if;
      Max_Probes := Natural'Max (Max_Probes, S.Probes);
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put ("  FAIL own check (" & Label & "): input");
            for X of A loop
               Put (X'Image);
            end loop;
            New_Line;
         end if;
      end if;
   end Check_One;

   A : Input_Array;
begin
   --  1. Every 0/1 input (2**8). (Binary insertion sort is not a fixed
   --     comparator network, so the 0-1 principle does not apply; these are
   --     just many inputs with ties.)
   for Mask in 0 .. 2 ** Index'Last - 1 loop
      for I in Index loop
         A (I) := (if (Mask / 2 ** (I - 1)) mod 2 = 1 then 1 else 0);
      end loop;
      Check_One (A, "0/1 mask" & Mask'Image);
   end loop;
   --  2. Edge shapes: all equal, ascending, descending, extremes.
   Check_One ([others => Value'First], "all First");
   Check_One ([others => Value'Last], "all Last");
   Check_One ([for I in Index => Value'First + (I - 1)], "ascending");
   Check_One ([for I in Index => Value'Last - (I - 1)], "descending");
   Check_One ([for I in Index => (if I mod 2 = 0 then Value'First else Value'Last)], "alternating extremes");
   --  3. Random inputs over the whole Value range, and with many duplicates.
   for K in 1 .. 2_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'Last);
      end loop;
      Check_One (A, "random" & K'Image);
   end loop;
   for K in 1 .. 1_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'First + 2);
      end loop;
      Check_One (A, "duplicates" & K'Image);
   end loop;

   --  4. Exact counts worked by hand. Ascending or all equal: each new
   --     element is >= the prefix, so every search step moves right
   --     (widths 1 .. 7 take 1 1 2 2 2 2 3 steps): 13. Strictly descending:
   --     every step moves left (1 2 2 3 3 3 3): 17, the bound.
   declare
      procedure Count (A : Input_Array; Want : Natural; Label : String) is
         S : constant Sort_Result := Sort (A);
      begin
         Cases := Cases + 1;
         if S.Probes /= Want then
            Failures := Failures + 1;
            Put_Line ("  FAIL own check (" & Label & "):" & S.Probes'Image & " comparisons counted, made" & Want'Image);
         end if;
      end Count;
   begin
      Count ([for I in Index => I], 13, "ascending");
      Count ([others => 5], 13, "all equal");
      Count ([for I in Index => 9 - I], 17, "descending");
   end;
   Cases := Cases + 1;
   if Max_Probes /= Bound then
      Failures := Failures + 1;
      Put_Line ("  FAIL own check: worst case" & Max_Probes'Image & " comparisons, expected" & Bound'Image);
   end if;

   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " checks (sorted, permutation, own reference; comparisons <= 17, worst case 17, exact counts)");
end Own_Checks;
