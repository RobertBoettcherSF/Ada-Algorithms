pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Max_Consecutive_Ones; use Max_Consecutive_Ones;
procedure Tests is
   A : constant Bit_Array := (1, 1, 0, 1, 1, 1, 0, 1);
   B : constant Bit_Array := (0, 0, 0, 0, 0, 0, 0, 0);
   C : constant Bit_Array := (1, 1, 1, 1, 1, 1, 1, 1);
begin
   if Find (A) /= 3 then raise Program_Error; end if;
   if Find (B) /= 0 then raise Program_Error; end if;
   if Find (C) /= 8 then raise Program_Error; end if;
   Put_Line ("Max consecutive ones: PASS");
end Tests;
