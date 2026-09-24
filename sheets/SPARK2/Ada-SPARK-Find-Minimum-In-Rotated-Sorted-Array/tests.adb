with Find_Minimum_In_Rotated_Sorted_Array;
procedure Tests is
   Data : constant Find_Minimum_In_Rotated_Sorted_Array.Data_Array :=
     (4, 5, 6, 7, 0, 1, 2, others => 100);
begin
   pragma Assert (Find_Minimum_In_Rotated_Sorted_Array.Minimum (Data) = 0);
end Tests;
