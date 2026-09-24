pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Clone_Graph_Stub; use Clone_Graph_Stub;

procedure Tests is
   Input : constant Graph :=
     (1 => (1 => False, 2 => True, 3 => False, 4 => False),
      2 => (1 => True, 2 => False, 3 => True, 4 => False),
      3 => (1 => False, 2 => True, 3 => False, 4 => True),
      4 => (1 => False, 2 => False, 3 => True, 4 => False));
begin
   if Clone (Input) /= Input then raise Program_Error; end if;
   Put_Line ("Clone graph stub: PASS");
end Tests;
