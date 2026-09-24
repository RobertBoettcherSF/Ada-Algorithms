pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Last_Stone_Weight; use Last_Stone_Weight;

procedure Tests is
   Stones : constant Stone_Array := (2, 7, 4, 1, 8, 1);
   Single : constant Stone_Array := (1, 1, 1, 1, 1, 1);
begin
   if Final_Weight (Stones) /= 1 then raise Program_Error; end if;
   if Final_Weight (Single) /= 0 then raise Program_Error; end if;
   Put_Line ("Last stone weight: PASS");
end Tests;
