pragma SPARK_Mode (On);
with Reverse_Linked_List_II; use Reverse_Linked_List_II;
procedure Main is
   L : List := Empty;
begin
   Append (L, 1); Append (L, 2); Append (L, 3); Append (L, 4); Append (L, 5);
   Solve (L, 2, 4);
   pragma Assert (Get (L, 1) = 1);
   pragma Assert (Get (L, 2) = 4);
   pragma Assert (Get (L, 3) = 3);
   pragma Assert (Get (L, 4) = 2);
   pragma Assert (Get (L, 5) = 5);
end Main;
