pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Find_Minimum_In_Rotated_Sorted_Array_II;
use Find_Minimum_In_Rotated_Sorted_Array_II;
with Own_Checks;

procedure Tests is
   Values : constant Value_Array := [4, 5, 6, 7, 0, 1, 2, 2];
   Negs   : constant Value_Array := [-4, -4, -2, -1, 0, 1, 2, 3];

   --  With distinct values a halving search needs at most log2 8 = 3
   --  comparisons; the bound asserted here is floor (log2 N) + 2 = 5.
   --  With duplicates no comparison-based search can beat N - 1 in the
   --  worst case (all equal but one), so there only the answer is checked.
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

   procedure Expect (V : Value_Array; Want : Value; Distinct : Boolean; Label : String) is
      R : constant Search_Result := Find_Minimum (V);
   begin
      if V (R.Position) /= Want or else Minimum (V) /= Want then
         raise Program_Error with Label & ": minimum" & V (R.Position)'Image & ", expected" & Want'Image;
      end if;
      if Distinct and then R.Probes > Bound then
         raise Program_Error with Label & ":" & R.Probes'Image
           & " comparisons, more than floor (log2 N) + 2 =" & Bound'Image;
      end if;
   end Expect;
begin
   Expect (Values, 0, False, "4 5 6 7 0 1 2 2");
   Expect (Negs, -4, False, "-4 -4 -2 -1 0 1 2 3");
   --  Distinct values: 10, 20, .., 80 turned by every amount.
   for S in 0 .. Length - 1 loop
      Expect ([for I in Index => 10 * ((I - 1 + S) mod Length + 1)], 10, True,
              "10 .. 80 turned by" & S'Image);
   end loop;
   --  All equal but one: 1 1 1 0 1 1 1 1 with the 0 at every position.
   for P in Index loop
      Expect ([for I in Index => (if I = P then 0 else 1)], 0, False, "single 0 at" & P'Image);
   end loop;
   --  All equal.
   Expect ([others => 7], 7, False, "all 7");
   --  Every comparison of two elements is counted: the three-way
   --  comparison of Values (Mid) with Values (Hi) is one, and on equal
   --  ends the check whether Values falls into Hi is a second. Counts
   --  worked by hand for all equal (each of the N - 1 shrink steps makes
   --  both: 14) and for the single 0 at each position.
   declare
      type Count_Table is array (0 .. Length) of Natural;
      --  Index 0: all 7; index P: the single 0 at P.
      Want : constant Count_Table := [14, 13, 10, 6, 3, 8, 6, 4, 3];
   begin
      for P in Count_Table'Range loop
         declare
            V : constant Value_Array :=
              (if P = 0 then [others => 7] else [for I in Index => (if I = P then 0 else 1)]);
            R : constant Search_Result := Find_Minimum (V);
         begin
            if R.Probes /= Want (P) then
               raise Program_Error with "counts, case" & P'Image & ":" & R.Probes'Image
                 & " comparisons counted, made" & Want (P)'Image;
            end if;
         end;
      end loop;
   end;
   Put_Line ("Find_Minimum_In_Rotated_Sorted_Array_II: PASS");
   Own_Checks;
end Tests;
