pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Min_Cost_Connect_Cities_Stub; use Min_Cost_Connect_Cities_Stub;

procedure Tests is
   Edges : constant Edge_Array :=
     (1 => (From => 1, To => 2, Cost => 1),
      2 => (From => 1, To => 3, Cost => 2),
      3 => (From => 2, To => 3, Cost => 2),
      4 => (From => 2, To => 4, Cost => 3),
      5 => (From => 3, To => 4, Cost => 4),
      6 => (From => 1, To => 4, Cost => 5));
begin
   if Minimum_Cost (Edges) /= 6 then raise Program_Error; end if;
   Put_Line ("Minimum cost connect cities: PASS");
end Tests;
