-- main.adb
-- A simple entry point to fulfill compilation constraints.
with Ada.Text_IO; use Ada.Text_IO;

procedure Main is
begin
   Put_Line("Dithering Library built successfully.");
   Put_Line("Run 'make test' to execute the V&V test suite.");
end Main;
