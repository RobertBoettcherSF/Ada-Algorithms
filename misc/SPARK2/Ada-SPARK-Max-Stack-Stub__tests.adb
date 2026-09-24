pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Max_Stack_Stub; use Max_Stack_Stub;

procedure Tests is
   S : Stack := Empty;
begin
   S := Push (S, 8); S := Push (S, -2); S := Push (S, 5);
   if Max_Value (S) /= 8 or else Top_Value (S) /= 5 then raise Program_Error; end if;
   S := Pop (S);
   if Top_Value (S) /= -2 then raise Program_Error; end if;
   Put_Line ("Maximum stack stub: PASS");
end Tests;
