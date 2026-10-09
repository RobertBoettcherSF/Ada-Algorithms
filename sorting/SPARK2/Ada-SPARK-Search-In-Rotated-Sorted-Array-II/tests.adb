pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Search_In_Rotated_Sorted_Array_II; use Search_In_Rotated_Sorted_Array_II;
with Own_Checks;

procedure Tests is
   --  40, 42, .., 62, 0, 2, .., 38: 0 .. 62 even, turned so 0 is at 13.
   Turned : constant Data_Array := [for I in Index => (2 * (I + 19)) mod 64];
   --  21 21 21 24 24 24 27 27 27 30 30 30 0 0 3 3 3 6 6 6 .. 18 18 18:
   --  the sorted base 0 0 3 3 3 6 6 6 .. 30 30 30 turned left by 20.
   Runs   : constant Data_Array := [for I in Index => ((I + 19) mod Length + 1) / 3 * 3];

   --  With distinct values: at most 5 comparisons to find the turn and
   --  1 + 6 + 1 in the part that can hold Target; the bound asserted
   --  here is 2 * (floor (log2 N) + 2) = 14. With duplicates the worst
   --  case is O(N) (all equal but one), so there only the answer is
   --  checked.
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

   procedure Expect (D : Data_Array; Target : Value; Want, Distinct : Boolean; Label : String) is
      R : constant Search_Result := Contains (D, Target);
   begin
      if R.Found /= Want then
         raise Program_Error with Label & " target" & Target'Image & ": found " & R.Found'Image;
      end if;
      if Distinct and then R.Probes > Bound then
         raise Program_Error with Label & " target" & Target'Image & ":" & R.Probes'Image
           & " comparisons, more than 2 * (floor (log2 N) + 2) =" & Bound'Image;
      end if;
   end Expect;
begin
   for T in Value loop
      Expect (Turned, T, T mod 2 = 0 and then T <= 62, True, "0 .. 62 even, turned");
      Expect (Runs, T, T mod 3 = 0 and then T <= 30, False, "runs of 3, turned");
   end loop;
   --  All equal but one: 1 everywhere and a 0 at P (and the reverse).
   for P in Index loop
      for T in 0 .. 2 loop
         Expect ([for I in Index => (if I = P then 0 else 1)], T, T <= 1, False, "single 0 at" & P'Image);
         Expect ([for I in Index => (if I = P then 1 else 0)], T, T <= 1, False, "single 1 at" & P'Image);
      end loop;
   end loop;
   Expect ([others => 7], 7, True, False, "all 7");
   Expect ([others => 7], 6, False, False, "all 7");
   --  Every comparison with an element is counted: the three-way
   --  comparison of Data (Mid) with Data (Hi) is one, and on equal ends
   --  the check whether Data falls into Hi is a second. All 7: 31 shrink
   --  steps make both (62), then 6 halvings and 1 last comparison: 69
   --  (worked by hand, for target 7 and 6). Single 0 at P, target 0: a
   --  step-by-step count of the same rules (done outside the repository;
   --  P = 1 (68) and P = 32 (8) also checked by hand).
   declare
      type Count_Table is array (Index) of Natural;
      Want : constant Count_Table :=
        [68, 65, 61, 58, 54, 50, 46, 43, 39, 35, 31, 27, 23, 19, 15, 12,
         41, 38, 36, 34, 32, 30, 28, 26, 24, 21, 19, 17, 15, 12, 10, 8];
      All_Seven : constant Count_Table := [others => 69];
   begin
      for T in 6 .. 7 loop
         declare
            R : constant Search_Result := Contains ([others => 7], T);
         begin
            if R.Probes /= All_Seven (T) then
               raise Program_Error with "all 7, target" & T'Image & ":" & R.Probes'Image
                 & " comparisons counted, made" & All_Seven (T)'Image;
            end if;
         end;
      end loop;
      for P in Index loop
         declare
            R : constant Search_Result := Contains ([for I in Index => (if I = P then 0 else 1)], 0);
         begin
            if R.Probes /= Want (P) then
               raise Program_Error with "single 0 at" & P'Image & ":" & R.Probes'Image
                 & " comparisons counted, made" & Want (P)'Image;
            end if;
         end;
      end loop;
   end;
   Put_Line ("Search_In_Rotated_Sorted_Array_II: PASS");
   Own_Checks;
end Tests;
