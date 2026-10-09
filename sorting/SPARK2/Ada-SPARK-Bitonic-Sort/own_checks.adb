--  Own property tests for Bitonic_Sort.Sort (written for this repository; see
--  tests/SOURCES.txt). No expected value is taken from the program: every
--  check is a property of a correct sort (output nondecreasing, output a
--  permutation of the input) or a comparison with the own insertion sort
--  below.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Bitonic_Sort; use Bitonic_Sort;

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

   --  The textbook bitonic network for 8 inputs (Batcher 1968; Wikipedia
   --  "Bitonic sorter", alternative representation with every comparator
   --  putting the smaller value at the lower index): for block sizes
   --  K = 2, 4, 8 first the flip comparators (B + I, B + K - 1 - I), then the
   --  half-cleaners (I, I xor J) for J = K / 4, .., 1.
   function Textbook return Network is
      Net : Network (1 .. Network_Size);
      N   : Natural := 0;
      K   : Positive := 2;
      J   : Natural;
   begin
      while K <= 8 loop
         for B in 0 .. 8 / K - 1 loop
            for I in 0 .. K / 2 - 1 loop
               N := N + 1;
               Net (N) := (B * K + I + 1, B * K + K - I);
            end loop;
         end loop;
         J := K / 4;
         while J >= 1 loop
            for I in 0 .. 7 loop
               if (I / J) mod 2 = 0 then
                  N := N + 1;
                  Net (N) := (I + 1, I + J + 1);
               end if;
            end loop;
            J := J / 2;
         end loop;
         K := K * 2;
      end loop;
      return Net;
   end Textbook;

   --  Apply a network (own reference for the trace).
   function Apply (Net : Network; A : Input_Array) return Input_Array is
      B : Input_Array := A;
      T : Value;
   begin
      for C of Net loop
         if B (C.Lo) > B (C.Hi) then
            T := B (C.Lo);
            B (C.Lo) := B (C.Hi);
            B (C.Hi) := T;
         end if;
      end loop;
      return B;
   end Apply;

   procedure Check_Trace (A : Input_Array; Label : String) is
      R     : Input_Array;
      Trace : Network (1 .. Network_Size);
   begin
      Cases := Cases + 1;
      Sort_Traced (A, R, Trace);
      if Trace /= Textbook or else R /= Apply (Textbook, A) or else R /= Sort (A) then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put_Line ("  FAIL own check (" & Label & "): comparators differ from the bitonic network");
         end if;
      end if;
   end Check_Trace;

   A : Input_Array;
begin
   --  0. The comparators Sort runs are exactly the bitonic network (H102):
   --     a correct sort under another name (the old bubble sort) fails here.
   Check_Trace ([1 => 23, 2 => 4, 3 => 17, 4 => 9, 5 => 1, 6 => 31, 7 => 12, 8 => 6], "trace");
   Check_Trace ([others => 0], "trace all equal");
   for K in 1 .. 200 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'Last);
      end loop;
      Check_Trace (A, "trace random" & K'Image);
   end loop;
   --  1. Every 0/1 input (2**8): for comparator networks this alone proves
   --     the network sorts all inputs (0-1 principle, Knuth TAOCP 5.3.4).
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

   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " inputs (sorted, permutation, own reference)");
end Own_Checks;
