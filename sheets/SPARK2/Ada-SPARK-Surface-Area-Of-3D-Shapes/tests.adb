with Ada.Text_IO; use Ada.Text_IO;
with Surface_Area_Of_3D_Shapes; use Surface_Area_Of_3D_Shapes;
procedure Tests is
   G : constant Grid := ((1, 0), (2, 3));
begin
   if Surface_Area (G) /= 24 then raise Program_Error; end if;
   Put_Line ("surface area: PASS");
end Tests;
