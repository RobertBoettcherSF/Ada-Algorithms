with Ada.Text_IO; use Ada.Text_IO;
with Watershed_Algorithm; use Watershed_Algorithm;

procedure Main is
   Img : constant Image_Grid(1..3, 1..3) := (
      (10, 10, 10),
      (10,  0, 10),
      (10, 10, 10)
   );
   Res : Label_Grid(1..3, 1..3);
begin
   Put_Line("Running Watershed Implementation (Immersion Variant)...");
   Immersion_Watershed(Img, Res);
   Put_Line("Execution successful. Run tests to see full validation suite.");
end Main;
