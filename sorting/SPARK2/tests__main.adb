pragma SPARK_Mode (On);
with Odd_Even_Linked_List; use Odd_Even_Linked_List;
procedure Main is
   L : List := Empty;
begin
   Append (L, 1); Append (L, 2); Append (L, 3); Append (L, 4);
   Solve (L);
   pragma Assert (Get (L, 1) = 1);
   pragma Assert (Get (L, 2) = 3);
   pragma Assert (Get (L, 3) = 2);
   pragma Assert (Get (L, 4) = 4);
end Main;
