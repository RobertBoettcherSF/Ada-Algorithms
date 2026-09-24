pragma SPARK_Mode (On);
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Product_Of_Numbers_Stub; use Product_Of_Numbers_Stub;

procedure Tests is
   Values : constant Number_Array := (1, 2, 1, 2, 2);
   With_Zero : constant Number_Array := (1, 0, 2, 2, 1);
begin
   Assert (Product (Values) = 8);
   Assert (Product (With_Zero) = 0);
   Put_Line ("Product Of Numbers: PASS");
end Tests;
