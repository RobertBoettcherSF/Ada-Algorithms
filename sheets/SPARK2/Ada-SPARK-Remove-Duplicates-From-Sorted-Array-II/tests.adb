with Ada.Assertions; use Ada.Assertions;
with Remove_Duplicates_From_Sorted_Array_II;
use Remove_Duplicates_From_Sorted_Array_II;

procedure Tests is
   Data : Values := (1, 1, 1, 2, 2, 3, others => 0);
   Length : Length_Type := 6;
begin
   Keep_Two (Data, Length);
   Assert (Length = 5 and Data (1) = 1 and Data (2) = 1
           and Data (3) = 2 and Data (4) = 2 and Data (5) = 3);
end Tests;
