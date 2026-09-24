pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Remove_Nth_Node_From_End; use Remove_Nth_Node_From_End;

procedure Tests is
   L : List := Empty;
begin
   Append (L, 1); Append (L, 2); Append (L, 3); Append (L, 4); Append (L, 5); Remove_Nth (L, 2);
   if Length (L) /= 4 or else Element (L, 4) /= 5 then raise Program_Error; end if;
   Put_Line ("Remove nth node from end: PASS");
end Tests;
