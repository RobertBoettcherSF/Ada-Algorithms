-- main.adb
-- Entry point for the standard application binary
with Ada.Text_IO; use Ada.Text_IO;

procedure Main is
begin
   Put_Line("==============================================");
   Put_Line("Fractal Compression Library Initialization");
   Put_Line("==============================================");
   Put_Line("Library loaded successfully. To verify correctness,");
   Put_Line("please run the Verification & Validation test suite");
   Put_Line("using the following command:");
   Put_Line("");
   Put_Line("    make test");
   Put_Line("");
end Main;
