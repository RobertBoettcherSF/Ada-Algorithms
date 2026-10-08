--  Own property tests for Merge_Sorted_Arrays.Merge (see tests/SOURCES.txt).
--  For sorted Left and Right the result must equal the own insertion sort
--  of their concatenation (sorted and a permutation of both inputs).
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Merge_Sorted_Arrays; use Merge_Sorted_Arrays;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Sorted_Input return Input_Array is
      A : Input_Array;
      T : Value;
      J : Input_Index;
   begin
      for I in Input_Index loop
         A (I) := Next (Value'First, Value'Last);
      end loop;
      for I in Input_Index'First + 1 .. Input_Index'Last loop
         T := A (I);
         J := I;
         while J > Input_Index'First and then A (J - 1) > T loop
            A (J) := A (J - 1);
            J := J - 1;
         end loop;
         A (J) := T;
      end loop;
      return A;
   end Sorted_Input;

   --  Own reference: concatenate, then straight insertion sort.
   function Reference (L, R : Input_Array) return Output_Array is
      B : Output_Array;
      T : Value;
      J : Output_Index;
   begin
      for I in Input_Index loop
         B (I) := L (I);
         B (Left_Length + I) := R (I);
      end loop;
      for I in Output_Index'First + 1 .. Output_Index'Last loop
         T := B (I);
         J := I;
         while J > Output_Index'First and then B (J - 1) > T loop
            B (J) := B (J - 1);
            J := J - 1;
         end loop;
         B (J) := T;
      end loop;
      return B;
   end Reference;

   L, R : Input_Array;
begin
   Report (Merge ([others => Value'First], [others => Value'Last]) = Reference ([others => Value'First], [others => Value'Last]), "disjoint low/high");
   Report (Merge ([others => Value'Last], [others => Value'First]) = Reference ([others => Value'Last], [others => Value'First]), "disjoint high/low");
   Report (Merge ([others => 0], [others => 0]) = [Output_Index => 0], "all equal");
   for K in 1 .. 5_000 loop
      L := Sorted_Input;
      R := Sorted_Input;
      Report (Merge (L, R) = Reference (L, R), "random" & K'Image);
   end loop;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " inputs (own merge reference)");
end Own_Checks;
