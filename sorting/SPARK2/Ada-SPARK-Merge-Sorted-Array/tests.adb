with Ada.Assertions; use Ada.Assertions;
with Merge_Sorted_Array; use Merge_Sorted_Array;

procedure Tests is
   Left : Values := (1 => 1, 2 => 3, 3 => 5, others => 0);
   Right : Values := (1 => 2, 2 => 4, 3 => 6, others => 0);
begin
   Assert (Merge_Sum (Left, Right, 3) = 6);
end Tests;
