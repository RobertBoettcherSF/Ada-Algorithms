pragma SPARK_Mode (On);
with Partition_List; use Partition_List;
procedure Main is
   L : List := Empty;
begin
   Append (L, 3); Append (L, 5); Append (L, 8); Append (L, 5); Append (L, 10);
   Solve (L, 5);
   pragma Assert (Get (L, 1) = 3);
   pragma Assert (Get (L, 2) = 5);
   pragma Assert (Get (L, 3) = 8);
   pragma Assert (Get (L, 4) = 5);
   pragma Assert (Get (L, 5) = 10);
end Main;
