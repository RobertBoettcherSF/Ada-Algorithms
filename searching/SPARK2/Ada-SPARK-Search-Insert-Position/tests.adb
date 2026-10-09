pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Search_Insert_Position; use Search_Insert_Position;

procedure Tests is
   Data : constant Sorted_Array := [1, 3, 5, 6, others => 100];
   Up   : constant Sorted_Array := [for I in Index => 3 * I];   --  3, 6, .., 96

   --  Searching N = 32 sorted values: N + 1 = 33 insertion points, so a
   --  halving search needs at most floor (log2 33) + 1 = 6 reads; the
   --  bound asserted here is floor (log2 N) + 2 = 7.
   Bound : constant := 7;

   procedure Expect (D : Sorted_Array; Target : Value; Where : Insertion_Index; Label : String) is
      R : constant Search_Result := Position (D, Target);
   begin
      if R.Position /= Where then
         raise Program_Error with Label & ": position" & R.Position'Image & ", expected" & Where'Image;
      end if;
      if R.Probes > Bound then
         raise Program_Error with Label & ":" & R.Probes'Image & " reads, more than floor (log2 N) + 2 =" & Bound'Image;
      end if;
   end Expect;
begin
   Expect (Data, 5, 3, "present");
   Expect (Data, 2, 2, "between 1 and 3");
   Expect (Data, 7, 5, "between 6 and the 100s");
   Expect (Data, 0, 1, "before everything");
   Expect (Data, 100, 5, "first of the equal 100s");
   Expect (Up, 96, 32, "last element");
   Expect (Up, 97, 33, "after everything");
   Expect (Up, 50, 17, "between 48 and 51");
   Put_Line ("Search_Insert_Position: PASS");
end Tests;
