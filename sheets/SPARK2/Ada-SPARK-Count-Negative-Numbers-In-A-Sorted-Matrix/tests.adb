with Ada.Text_IO; use Ada.Text_IO;
with Count_Negative_Numbers_In_A_Sorted_Matrix; use Count_Negative_Numbers_In_A_Sorted_Matrix;
procedure Tests is
   M : constant Matrix := ((-4, -2, 1, 3), (-3, -1, 2, 4), (-2, 0, 3, 5), (-1, 1, 4, 6));
begin
   if Count_Negatives (M) /= 6 then raise Program_Error; end if;
   Put_Line ("negative count: PASS");
end Tests;
