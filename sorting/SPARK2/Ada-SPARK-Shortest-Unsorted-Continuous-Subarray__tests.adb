with Ada.Assertions; use Ada.Assertions;
with Shortest_Unsorted_Continuous_Subarray; use Shortest_Unsorted_Continuous_Subarray;
procedure Tests is
   A : Int_Array := [others => 0];
   B : Int_Array := [others => 0];
begin
   A (1 .. 5) := [2, 6, 4, 8, 10];
   for I in Index range 6 .. Index'Last loop
      A (I) := 10;
   end loop;
   Assert (Unsorted_Span (A) = 2);
   B := [others => 4];
   B (1 .. 4) := [1, 2, 3, 4];
   Assert (Unsorted_Span (B) = 0);
end Tests;
