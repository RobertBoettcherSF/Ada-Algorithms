pragma SPARK_Mode (On);
with Remove_Duplicates_From_Sorted_List; use Remove_Duplicates_From_Sorted_List;
procedure Main is
   L : List := Empty;
begin
   Append (L, 1); Append (L, 1); Append (L, 2); Append (L, 3); Append (L, 3);
   Solve (L);
   pragma Assert (L.Length = 3);
   pragma Assert (Get (L, 1) = 1);
   pragma Assert (Get (L, 2) = 2);
   pragma Assert (Get (L, 3) = 3);
end Main;
