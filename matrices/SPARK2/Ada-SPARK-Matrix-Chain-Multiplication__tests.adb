pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Matrix_Chain_Multiplication; use Matrix_Chain_Multiplication;
procedure Tests is
   D : constant Dimension_Array := [10, 20, 20, 20];
begin
   Assert (Minimum_Cost (D) = 8_000);
   Put_Line ("PASS Matrix_Chain_Multiplication");
end Tests;
