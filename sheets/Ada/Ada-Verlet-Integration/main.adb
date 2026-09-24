-- main.adb
-- A dummy entry point if someone runs the main executable instead of tests.
with Ada.Text_IO; use Ada.Text_IO;

procedure Main is
begin
   Put_Line ("========================================");
   Put_Line (" Verlet Integration Library - Main Stub");
   Put_Line ("========================================");
   Put_Line ("This codebase is primarily a library.");
   Put_Line ("Please run 'make test' to verify the physics and mathematics.");
end Main;
