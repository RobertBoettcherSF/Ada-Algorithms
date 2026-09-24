with Ada.Text_IO; use Ada.Text_IO;
with Convert_1D_Array_Into_2D_Array; use Convert_1D_Array_Into_2D_Array;
procedure Tests is
   A : constant One_Dimensional_Array := (1, 2, 3, 4);
   B : constant Two_Dimensional_Array := Convert (A);
begin
   if B /= ((1, 2), (3, 4)) then raise Program_Error; end if;
   Put_Line ("reshape: PASS");
end Tests;
