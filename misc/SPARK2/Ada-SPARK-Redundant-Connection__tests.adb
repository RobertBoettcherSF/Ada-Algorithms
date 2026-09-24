pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Redundant_Connection; use Redundant_Connection;

procedure Tests is
   Edges : constant Edge_Array :=
     (1 => (From => 1, To => 2), 2 => (From => 1, To => 3),
      3 => (From => 2, To => 3), 4 => (From => 3, To => 4),
      5 => (From => 4, To => 5));
   Answer : constant Edge := Find_Redundant (Edges);
begin
   if Answer /= (From => 2, To => 3) then raise Program_Error; end if;
   Put_Line ("Redundant connection: PASS");
end Tests;
