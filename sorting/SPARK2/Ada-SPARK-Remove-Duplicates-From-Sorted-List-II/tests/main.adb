pragma SPARK_Mode (On);
with Remove_Duplicates_From_Sorted_List_II; use Remove_Duplicates_From_Sorted_List_II;
with Own_Checks;
procedure Main is
   L : List := Empty;
begin
   --  1 and 3 occur more than once, so only 2 is left
   Append (L, 1); Append (L, 1); Append (L, 1); Append (L, 2); Append (L, 3); Append (L, 3);
   Solve (L);
   pragma Assert (L.Length = 1);
   pragma Assert (Get (L, 1) = 2);
   Own_Checks;
end Main;
