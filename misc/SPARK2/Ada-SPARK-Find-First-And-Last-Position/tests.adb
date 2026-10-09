pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Find_First_And_Last_Position; use Find_First_And_Last_Position;
with Own_Checks;

procedure Tests is
   Data : constant Sorted_Array := [1, 2, 2, 2, 3, others => 100];
   --  0 0 1 1 2 2 .. 15 15: each value twice.
   Pairs : constant Sorted_Array := [for I in Index => (I - 1) / 2];

   --  Two halving searches over the 33 boundaries: at most
   --  2 * (floor (log2 33) + 1) = 12 reads; asserted here is
   --  2 * (floor (log2 N) + 2) = 14.
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

   procedure Expect (D : Sorted_Array; Target : Value; First, Last : Boundary; Label : String) is
      R : constant Match_Range := Locate (D, Target);
   begin
      if R.First /= First or else R.Last /= Last then
         raise Program_Error with Label & ": got" & R.First'Image & R.Last'Image
           & ", expected" & First'Image & Last'Image;
      end if;
      if R.Probes > Bound then
         raise Program_Error with Label & ":" & R.Probes'Image & " reads, more than 2 * (floor (log2 N) + 2) =" & Bound'Image;
      end if;
   end Expect;
begin
   Expect (Data, 2, 2, 4, "run of three 2s");
   Expect (Data, 9, 0, 0, "absent between 3 and 100");
   Expect (Data, 1, 1, 1, "single at the start");
   Expect (Data, 100, 6, 32, "run to the end");
   Expect (Data, 0, 0, 0, "absent before everything");
   Expect (Pairs, 0, 1, 2, "pair at the start");
   Expect (Pairs, 7, 15, 16, "pair in the middle");
   Expect (Pairs, 15, 31, 32, "pair at the end");
   Expect (Pairs, 16, 0, 0, "absent after everything");
   Put_Line ("Find_First_And_Last_Position: PASS");
   Own_Checks;
end Tests;
