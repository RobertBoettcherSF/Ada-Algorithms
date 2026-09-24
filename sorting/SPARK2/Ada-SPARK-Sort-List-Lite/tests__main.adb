pragma SPARK_Mode (On);
with Sort_List_Lite; use Sort_List_Lite;
procedure Main is
   L : List := Empty;
begin
   Append (L, 4); Append (L, 1); Append (L, 3); Append (L, 2);
   Solve (L);
   pragma Assert (Get (L, 1) = 1);
   pragma Assert (Get (L, 2) = 2);
   pragma Assert (Get (L, 3) = 3);
   pragma Assert (Get (L, 4) = 4);
end Main;
