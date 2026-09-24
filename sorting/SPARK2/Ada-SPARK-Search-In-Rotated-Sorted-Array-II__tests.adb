with Search_In_Rotated_Sorted_Array_II;
procedure Tests is
   Data : constant Search_In_Rotated_Sorted_Array_II.Data_Array :=
     (4, 5, 6, 7, 0, 1, 2, others => 100);
begin
   pragma Assert (Search_In_Rotated_Sorted_Array_II.Contains (Data, 0));
   pragma Assert (not Search_In_Rotated_Sorted_Array_II.Contains (Data, 3));
end Tests;
