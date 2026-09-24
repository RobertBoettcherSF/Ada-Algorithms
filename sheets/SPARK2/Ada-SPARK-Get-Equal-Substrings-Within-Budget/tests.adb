pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Get_Equal_Substrings_Within_Budget; use Get_Equal_Substrings_Within_Budget;
procedure Tests is
   S : constant Code_Array := (1, 2, 3, 4, 5, 6, 7, 8);
   T : constant Code_Array := (2, 3, 4, 5, 6, 7, 8, 9);
   U : constant Code_Array := (1, 8, 3, 4, 5, 6, 7, 8);
begin
   if Longest (S, T, 8) /= 8 then raise Program_Error; end if;
   if Longest (S, T, 3) /= 3 then raise Program_Error; end if;
   if Longest (S, U, 0) /= 6 then raise Program_Error; end if;
   Put_Line ("Equal substrings within budget: PASS");
end Tests;
