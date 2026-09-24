pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Network_Delay_Time_Stub; use Network_Delay_Time_Stub;

procedure Tests is
   Edges : constant Edge_Array :=
     (1 => (From_Node => 1, To_Node => 2, Cost => 1),
      2 => (From_Node => 2, To_Node => 3, Cost => 1),
      3 => (From_Node => 1, To_Node => 3, Cost => 4),
      4 => (From_Node => 3, To_Node => 4, Cost => 1),
      5 => (From_Node => 2, To_Node => 4, Cost => 5));
begin
   if Compute (Edges, 1) /= 2 then raise Program_Error; end if;
   Put_Line ("Network delay time stub: PASS");
end Tests;
