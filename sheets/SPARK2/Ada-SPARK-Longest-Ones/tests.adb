pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Longest_Ones; use Longest_Ones;
procedure Tests is
   A : constant Bit_Array := (1, 0, 1, 1, 0, 1, 1, 1);
   B : constant Bit_Array := (0, 0, 0, 0, 1, 1, 0, 0);
begin
   if Find (A, 1) /= 6 then raise Program_Error; end if;
   if Find (A, 0) /= 3 then raise Program_Error; end if;
   if Find (B, 2) /= 4 then raise Program_Error; end if;
   Put_Line ("Longest ones: PASS");
end Tests;
