pragma SPARK_Mode (On);
with Swap_Nodes_In_Pairs; use Swap_Nodes_In_Pairs;
procedure Main is
   L : List := Empty;
begin
   Append (L, 1); Append (L, 2); Append (L, 3); Append (L, 4);
   Solve (L);
   pragma Assert (Get (L, 1) = 2);
   pragma Assert (Get (L, 2) = 1);
   pragma Assert (Get (L, 3) = 4);
   pragma Assert (Get (L, 4) = 3);
end Main;
