-- main.adb
with Ada.Text_IO; use Ada.Text_IO;
with Error_Diffusion; use Error_Diffusion;

procedure Main is
   Input : Image_Matrix(1..2, 1..2) := ((100.0, 200.0), (50.0, 150.0));
   Output : Image_Matrix(1..2, 1..2);
begin
   Put_Line("Running Error Diffusion Demo...");
   Diffuse_Image(Input, Output, Floyd_Steinberg);
   Put_Line("Processing Complete.");
end Main;
