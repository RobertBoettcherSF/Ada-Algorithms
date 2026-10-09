pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Search_In_Rotated_Sorted_Array_II; use Search_In_Rotated_Sorted_Array_II;

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
   Put_Line ("Search_In_Rotated_Sorted_Array_II: PASS");
end Tests;
