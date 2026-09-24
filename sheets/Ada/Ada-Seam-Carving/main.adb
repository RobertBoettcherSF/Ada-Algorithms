--  main.adb
--  Entry point for application usage.

with Ada.Text_IO; use Ada.Text_IO;
with Seam_Carving;

procedure Main is
begin
   Put_Line ("Seam Carving Algorithm");
   Put_Line ("Please run the tests using 'make test' to verify the logic.");
   Put_Line ("To integrate, use the Seam_Carving package in your image processing pipeline.");
end Main;
