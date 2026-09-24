with Ada.Text_IO; use Ada.Text_IO;
with The_K_Weakest_Rows_In_A_Matrix; use The_K_Weakest_Rows_In_A_Matrix;
procedure Tests is
   M : constant Matrix := ((1, 1, 0, 0), (1, 0, 0, 0), (1, 1, 1, 0), (1, 1, 1, 1));
begin
   if Weakest_Row (M) /= 2 then raise Program_Error; end if;
   Put_Line ("weakest row: PASS");
end Tests;
