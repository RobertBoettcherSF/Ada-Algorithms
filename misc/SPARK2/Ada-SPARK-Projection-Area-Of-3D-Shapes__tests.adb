with Ada.Text_IO; use Ada.Text_IO;
with Projection_Area_Of_3D_Shapes; use Projection_Area_Of_3D_Shapes;
procedure Tests is
   G : constant Grid := ((1, 0), (2, 3));
begin
   if Projection_Area (G) /= 12 then raise Program_Error; end if;
   Put_Line ("projection area: PASS");
end Tests;
