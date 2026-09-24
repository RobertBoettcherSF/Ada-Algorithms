pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Max_Consecutive_Ones_II; use Max_Consecutive_Ones_II;
procedure Tests is
   A : constant Bit_Array := (1, 0, 1, 1, 0, 1, 1, 1);
   B : constant Bit_Array := (0, 0, 0, 0, 0, 0, 0, 0);
   C : constant Bit_Array := (1, 1, 1, 1, 1, 1, 1, 1);
begin
   if Find (A) /= 6 then raise Program_Error; end if;
   if Find (B) /= 1 then raise Program_Error; end if;
   if Find (C) /= 8 then raise Program_Error; end if;
   Put_Line ("Max consecutive ones II: PASS");
end Tests;
