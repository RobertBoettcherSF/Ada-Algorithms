pragma SPARK_Mode (On);
with Remove_Duplicates_From_Sorted_List_II; use Remove_Duplicates_From_Sorted_List_II;
procedure Main is
   L : List := Empty;
begin
   Append (L, 1); Append (L, 1); Append (L, 1); Append (L, 2); Append (L, 3); Append (L, 3);
   Solve (L);
   pragma Assert (L.Length = 5);
   pragma Assert (Get (L, 1) = 1);
   pragma Assert (Get (L, 2) = 1);
   pragma Assert (Get (L, 3) = 2);
   pragma Assert (Get (L, 4) = 3);
   pragma Assert (Get (L, 5) = 3);
end Main;
