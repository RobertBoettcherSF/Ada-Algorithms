--  Own property tests for Quick_Sort (written for this repository; see
--  tests/SOURCES.txt). No expected value is taken from the program.
--  Sort is checked as a sort (output nondecreasing, a permutation of the
--  input, equal to the own insertion sort below). Partition is checked as
--  one Lomuto step around the last element: values before the pivot index
--  are <= the pivot and values after it are >= the pivot. Three layouts
--  were worked by hand. A full run of the old adjacent compare-exchange
--  passes sorts those three inputs, so it does not match the one-step
--  layout.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Quick_Sort; use Quick_Sort;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

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
      R      : constant Input_Array := Sort (A);
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

   --  Core step. Left of the pivot index is <= the pivot value and the
   --  right is >= it. The pivot value is the original last element.
   procedure Check_Partition (A : Input_Array; Label : String) is
      B  : Input_Array;
      P  : Index;
      type Counts is array (Value) of Natural;
      C_In  : Counts := [others => 0];
      C_Out : Counts := [others => 0];
      Ok    : Boolean := True;
   begin
      Cases := Cases + 1;
      B := A;
      Partition_Range (B, Index'First, Index'Last, P);
      for I in Index loop
         C_In (A (I)) := C_In (A (I)) + 1;
         C_Out (B (I)) := C_Out (B (I)) + 1;
         if I < P and then B (I) > B (P) then
            Ok := False;
         end if;
         if I > P and then B (I) < B (P) then
            Ok := False;
         end if;
      end loop;
      if C_In /= C_Out or else B (P) /= A (Index'Last) then
         Ok := False;
      end if;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put ("  FAIL partition (" & Label & "): input");
            for X of A loop
               Put (X'Image);
            end loop;
            Put (" pivot" & P'Image & " value" & B (P)'Image);
            New_Line;
         end if;
      end if;
   end Check_Partition;

   --  Hand-worked one-step layout. These three results are not sorted, so
   --  the old compare-exchange Sort (which returns a sorted array) fails.
   procedure Check_Layout
     (A : Input_Array; Expected : Input_Array; Expected_Pivot : Index; Label : String)
   is
      B : Input_Array;
      P : Index;
   begin
      Cases := Cases + 1;
      B := A;
      Partition_Range (B, Index'First, Index'Last, P);
      if B /= Expected or else P /= Expected_Pivot then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put ("  FAIL partition layout (" & Label & "): got");
            for X of B loop
               Put (X'Image);
            end loop;
            Put (" pivot" & P'Image & " expected");
            for X of Expected loop
               Put (X'Image);
            end loop;
            Put (" pivot" & Expected_Pivot'Image);
            New_Line;
         end if;
      end if;
   end Check_Layout;

   A : Input_Array;
begin
   --  1. Every 0/1 input (2**8): for comparator networks this alone proves
   --     the network sorts all inputs (0-1 principle, Knuth TAOCP 5.3.4).
   for Mask in 0 .. 2 ** Index'Last - 1 loop
      for I in Index loop
         A (I) := (if (Mask / 2 ** (I - 1)) mod 2 = 1 then 1 else 0);
      end loop;
      Check_One (A, "0/1 mask" & Mask'Image);
      Check_Partition (A, "0/1 mask" & Mask'Image);
   end loop;
   --  2. Edge shapes: all equal, ascending, descending, extremes.
   Check_One ([others => Value'First], "all First");
   Check_One ([others => Value'Last], "all Last");
   Check_One ([for I in Index => Value'First + (I - 1)], "ascending");
   Check_One ([for I in Index => Value'Last - (I - 1)], "descending");
   Check_One ([for I in Index => (if I mod 2 = 0 then Value'First else Value'Last)], "alternating extremes");
   Check_Partition ([others => Value'First], "all First");
   Check_Partition ([others => Value'Last], "all Last");
   Check_Partition ([for I in Index => Value'First + (I - 1)], "ascending");
   Check_Partition ([for I in Index => Value'Last - (I - 1)], "descending");
   Check_Partition ([for I in Index => (if I mod 2 = 0 then Value'First else Value'Last)], "alternating extremes");
   --  Hand-worked Lomuto layouts (pivot = last element). Each result still
   --  has an inversion, so it is not what the compare-exchange passes return.
   Check_Layout ([4, 1, 3, 2, 8, 5, 7, 6], [4, 1, 3, 2, 5, 6, 7, 8], 6, "hand 4 1 3 2 8 5 7 6");
   Check_Layout ([8, 7, 6, 5, 4, 3, 2, 1], [1, 7, 6, 5, 4, 3, 2, 8], 1, "hand reverse");
   Check_Layout ([23, 4, 17, 9, 1, 31, 12, 6], [4, 1, 6, 9, 23, 31, 12, 17], 3, "hand tests example");
   Check_One ([4, 1, 3, 2, 8, 5, 7, 6], "layout input 1");
   Check_One ([8, 7, 6, 5, 4, 3, 2, 1], "layout input reverse");
   Check_One ([23, 4, 17, 9, 1, 31, 12, 6], "layout input example");
   --  3. Random inputs over the whole Value range, and with many duplicates.
   for K in 1 .. 2_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'Last);
      end loop;
      Check_One (A, "random" & K'Image);
      Check_Partition (A, "random" & K'Image);
   end loop;
   for K in 1 .. 1_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'First + 2);
      end loop;
      Check_One (A, "duplicates" & K'Image);
      Check_Partition (A, "duplicates" & K'Image);
   end loop;

   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " inputs (sorted, permutation, own reference, partition)");
end Own_Checks;
