pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Maximum_Performance_Of_A_Team_Lite; use Maximum_Performance_Of_A_Team_Lite;

procedure Tests is
   Speeds : constant Speed_Array := (10, 40, 20, 90, 30, 50, 60, 70);
   Eff    : constant Efficiency_Array := (10, 30, 90, 10, 20, 20, 50, 10);
   Zero   : constant Speed_Array := (others => 0);
   One    : constant Efficiency_Array := (others => 1);
begin
   if Best_Single_Performance (Speeds, Eff) /= 3000 then raise Program_Error; end if;
   if Best_Single_Performance (Zero, One) /= 0 then raise Program_Error; end if;
   Put_Line ("Maximum performance lite: PASS");
end Tests;
