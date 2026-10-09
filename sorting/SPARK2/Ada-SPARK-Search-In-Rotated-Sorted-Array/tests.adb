pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Search_In_Rotated_Sorted_Array; use Search_In_Rotated_Sorted_Array;
with Own_Checks;

procedure Tests is
   --  40, 42, .., 62, 0, 2, .., 38: 0 .. 62 even, turned so 0 is at 13.
   Turned : constant Data_Array := [for I in Index => (2 * (I + 19)) mod 64];
   --  51 .. 82, not turned.
   Plain  : constant Data_Array := [for I in Index => I + 50];
   --  100, 1, 2, .., 31: turned by one.
   By_One : constant Data_Array := [for I in Index => (if I = 1 then 100 else I - 1)];

   --  Finding the turn takes at most log2 N = 5 comparisons and the search
   --  in the sorted part that can hold Target at most 1 + 6 + 1; the
   --  bound asserted here is 2 * (floor (log2 N) + 2) = 14.
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

   procedure Expect (D : Data_Array; Target : Value; Want : Boolean; Label : String) is
      R : constant Search_Result := Contains (D, Target);
   begin
      if R.Found /= Want then
         raise Program_Error with Label & " target" & Target'Image & ": found " & R.Found'Image;
      end if;
      if R.Probes > Bound then
         raise Program_Error with Label & " target" & Target'Image & ":" & R.Probes'Image
           & " comparisons, more than 2 * (floor (log2 N) + 2) =" & Bound'Image;
      end if;
   end Expect;
begin
   Expect (Turned, 0, True, "turned");
   Expect (Turned, 40, True, "turned");      --  first element
   Expect (Turned, 38, True, "turned");      --  last element
   Expect (Turned, 62, True, "turned");      --  just before the turn
   Expect (Turned, 3, False, "turned");
   Expect (Turned, 39, False, "turned");     --  between last and first
   Expect (Turned, 63, False, "turned");     --  above everything
   Expect (Turned, 100, False, "turned");
   Expect (Plain, 51, True, "plain");
   Expect (Plain, 82, True, "plain");
   Expect (Plain, 50, False, "plain");
   Expect (Plain, 83, False, "plain");
   Expect (By_One, 100, True, "turned by one");
   Expect (By_One, 1, True, "turned by one");
   Expect (By_One, 0, False, "turned by one");
   Expect (By_One, 32, False, "turned by one");
   for T in Value loop
      Expect (Turned, T, T mod 2 = 0 and then T <= 62, "turned, every target");
   end loop;
   Put_Line ("Search_In_Rotated_Sorted_Array: PASS");
   Own_Checks;
end Tests;
