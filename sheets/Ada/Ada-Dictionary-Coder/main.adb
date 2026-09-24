-- main.adb
-- A simple entry point to demonstrate successful compilation.

with Ada.Text_IO; use Ada.Text_IO;

procedure Main is
begin
   Put_Line ("Dictionary Coder Implementation in Ada");
   Put_Line ("--------------------------------------");
   Put_Line ("This project implements Static and Dynamic (LZW) Dictionary Coders.");
   Put_Line ("Execute 'make test' to run the Verification & Validation test suite.");
end Main;
