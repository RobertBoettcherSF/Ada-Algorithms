--  Own property tests for Flash_Sort.Sort (written for this repository; see
--  tests/SOURCES.txt). No expected value is taken from the program: every
--  check is a property of a correct sort (output nondecreasing, output a
--  permutation of the input) or a comparison with the own insertion sort
--  below.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Flash_Sort; use Flash_Sort;

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

   --  Own model of flashsort (Neubert, "Flashsort1", Dr. Dobb's Journal,
   --  February 1998): M = 3 classes for 8 keys; class of X is
   --  1 + ((M - 1) * (X - Min)) / (Max - Min); L (K) = end of class K's
   --  region (counts, prefix sums); the maximum is swapped to slot 1; the
   --  cycle-leader permutation holds a key ("flash") and drops it at
   --  L (class), taking the key there, L (class) decreasing, until a drop
   --  lands on the leader's own slot; a final straight insertion sort.
   --  Records every drop slot in order. Written from the published
   --  description with flash / hold variables, not from the body.
   type Model is record
      Moves  : Move_Log (1 .. Index'Last) := [others => 1];
      Count  : Natural := 0;
      Result : Input_Array;
   end record;

   function Run_Model (Input : Input_Array) return Model is
      R     : Model;
      A     : Input_Array := Input;
      Amin  : Value := A (1);
      Nmax  : Index := 1;
      L     : array (1 .. Classes) of Natural := [others => 0];
      K     : Natural;
      J     : Natural;
      Nmove : Natural := 0;
      Flash, Hold : Value;
      function Cls (X : Value) return Natural is (1 + ((Classes - 1) * (X - Amin)) / (A (Nmax) - Amin));
   begin
      for I in Index loop
         if A (I) < Amin then
            Amin := A (I);
         end if;
         if A (I) > A (Nmax) then
            Nmax := I;
         end if;
      end loop;
      if Amin = A (Nmax) then
         R.Result := A;
         return R;
      end if;
      for I in Index loop
         L (Cls (A (I))) := L (Cls (A (I))) + 1;
      end loop;
      for C in 2 .. Classes loop
         L (C) := L (C) + L (C - 1);
      end loop;
      declare
         Max_V : constant Value := A (Nmax);
         function Cl (X : Value) return Natural is (1 + ((Classes - 1) * (X - Amin)) / (Max_V - Amin));
      begin
         Hold := A (Nmax);
         A (Nmax) := A (1);
         A (1) := Hold;
         J := 1;
         K := Classes;
         while Nmove < Index'Last - 1 loop
            while J > L (K) loop
               J := J + 1;
               K := Cl (A (J));
            end loop;
            Flash := A (J);
            while J /= L (K) + 1 loop
               K := Cl (Flash);
               Hold := A (L (K));
               A (L (K)) := Flash;
               R.Count := R.Count + 1;
               R.Moves (R.Count) := L (K);
               Flash := Hold;
               L (K) := L (K) - 1;
               Nmove := Nmove + 1;
            end loop;
         end loop;
      end;
      --  Straight insertion, as Neubert's final pass.
      for I in reverse 1 .. Index'Last - 1 loop
         if A (I + 1) < A (I) then
            Hold := A (I);
            J := I;
            while J < Index'Last and then A (J + 1) < Hold loop
               A (J) := A (J + 1);
               J := J + 1;
            end loop;
            A (J) := Hold;
         end if;
      end loop;
      R.Result := A;
      return R;
   end Run_Model;

   Trace_Failures : Natural := 0;
   procedure Check_Trace (A : Input_Array) is
      Out_A : Input_Array;
      Moves : Move_Log (1 .. Index'Last);
      Count : Natural;
      M     : constant Model := Run_Model (A);
   begin
      Sort_Traced (A, Out_A, Moves, Count);
      if Count /= M.Count or else Moves (1 .. Count) /= M.Moves (1 .. M.Count)
        or else Out_A /= M.Result or else Out_A /= Sort (A)
        or else not Is_Perm (Out_A, A) or else not Is_Sorted (Out_A)
      then
         Trace_Failures := Trace_Failures + 1;
         if Trace_Failures <= 5 then
            Put ("  FAIL flashsort trace: input");
            for X of A loop
               Put (X'Image);
            end loop;
            New_Line;
         end if;
      end if;
   end Check_Trace;

   procedure Check_One (A : Input_Array; Label : String) is
      R      : constant Input_Array := Sort (A);
      type Counts is array (Value) of Natural;
      C_In   : Counts := [others => 0];
      C_Out  : Counts := [others => 0];
      Ok     : Boolean := True;
   begin
      Cases := Cases + 1;
      Check_Trace (A);
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

   A : Input_Array;
begin
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

   --  4. Random inputs, seed 20261009 (flashsort trace and result).
   Seed := 20_261_009;
   for K in 1 .. 3_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'Last);
      end loop;
      Check_One (A, "random 20261009" & K'Image);
   end loop;
   --  Every input over 0 .. 2 (3**8 = 6,561): classes, ties, min = max.
   for C in 0 .. 3 ** 8 - 1 loop
      for I in Index loop
         A (I) := (C / 3 ** (I - 1)) mod 3;
      end loop;
      Check_One (A, "ternary" & C'Image);
   end loop;
   if Trace_Failures > 0 then
      Put_Line ("FAIL flashsort trace:" & Trace_Failures'Image & " of" & Cases'Image);
      Failures := Failures + Trace_Failures;
   else
      Put_Line ("PASS flashsort trace = own Neubert model on" & Cases'Image & " inputs");
   end if;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " inputs (sorted, permutation, own reference)");
end Own_Checks;
