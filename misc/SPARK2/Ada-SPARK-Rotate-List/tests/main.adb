pragma SPARK_Mode (On);
with Rotate_List; use Rotate_List;
with Own_Checks;
procedure Main is
   L : List := Empty;
begin
   Append (L, 1); Append (L, 2); Append (L, 3); Append (L, 4);
   Solve (L, 2);
   pragma Assert (Get (L, 1) = 3);
   pragma Assert (Get (L, 2) = 4);
   pragma Assert (Get (L, 3) = 1);
   pragma Assert (Get (L, 4) = 2);
   Own_Checks;
end Main;
