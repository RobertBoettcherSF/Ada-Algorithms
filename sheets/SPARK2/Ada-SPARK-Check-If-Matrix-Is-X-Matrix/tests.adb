with Ada.Text_IO; use Ada.Text_IO;
with Check_If_Matrix_Is_X_Matrix; use Check_If_Matrix_Is_X_Matrix;
procedure Tests is
   X : constant Matrix := ((1, 0, 0, 1), (0, 1, 1, 0), (0, 1, 1, 0), (1, 0, 0, 1));
   N : constant Matrix := ((1, 0, 0, 1), (0, 1, 0, 0), (0, 1, 1, 0), (1, 0, 0, 1));
begin
   if not Is_X_Matrix (X) or else Is_X_Matrix (N) then raise Program_Error; end if;
   Put_Line ("X matrix: PASS");
end Tests;
