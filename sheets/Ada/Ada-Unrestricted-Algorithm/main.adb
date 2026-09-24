-- main.adb
with Ada.Text_IO; use Ada.Text_IO;
with Unrestricted_Algorithms; use Unrestricted_Algorithms;

procedure Main is
   Precision : constant Positive := 50;
   E_Result  : Digit_Array := Compute_E(Precision);
begin
   Put_Line("===========================================");
   Put_Line("Unrestricted Algorithm Demonstration");
   Put_Line("===========================================");
   Put("Euler's Number (e) to " & Positive'Image(Precision) & " decimal places: ");
   Print_Number(E_Result);
   Put_Line("");
   Put_Line("===========================================");
end Main;
