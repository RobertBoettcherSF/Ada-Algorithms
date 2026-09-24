with Ada.Assertions; use Ada.Assertions;
with Remove_Duplicates_From_Sorted_Array; use Remove_Duplicates_From_Sorted_Array;

procedure Tests is
   Data : Values := (1 => 1, 2 => 1, 3 => 2, 4 => 2, 5 => 3, 6 => 3, others => 0);
   Length : Length_Type := 6;
begin
   Compact (Data, Length);
   Assert (Length = 3 and Data (1) = 1 and Data (2) = 2 and Data (3) = 3);
end Tests;
