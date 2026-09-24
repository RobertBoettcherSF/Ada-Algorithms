-- main.adb
-- Trivial entry point for manual compilation tests.
with Ada.Text_IO; use Ada.Text_IO;

procedure Main is
begin
   Put_Line ("Push-Relabel Algorithm Compiled Successfully.");
   Put_Line ("Please run 'make test' to execute the V&V test suite.");
end Main;
