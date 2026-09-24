pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Ipo_Lite; use Ipo_Lite;

procedure Tests is
   Required : constant Capital_Array := (4, 1, 7, 2);
   Gain     : constant Profit_Array := (8, 5, 20, 6);
   None     : constant Capital_Array := (9, 9, 9, 9);
   Zero     : constant Profit_Array := (0, 0, 0, 0);
begin
   if Best_Affordable_Profit (3, Required, Gain) /= 6 then raise Program_Error; end if;
   if Best_Affordable_Profit (3, None, Zero) /= 0 then raise Program_Error; end if;
   Put_Line ("IPO lite: PASS");
end Tests;
