pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Knapsack_01; use Knapsack_01;
procedure Tests is
   Weights : constant Weight_Array := [2, 3, 4, 5, 9];
   Values : constant Value_Array := [3, 4, 5, 8, 10];
begin
   Assert (Maximum_Value (Weights, Values, 10) = 15);
   Assert (Maximum_Value (Weights, Values, 4) = 5);
   Put_Line ("PASS Knapsack_01");
end Tests;
