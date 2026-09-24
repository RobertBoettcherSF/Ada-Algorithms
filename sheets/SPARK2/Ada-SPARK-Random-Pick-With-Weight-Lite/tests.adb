with Ada.Assertions; use Ada.Assertions;
with Random_Pick_With_Weight_Lite;
use Random_Pick_With_Weight_Lite;

procedure Tests is
   Weights : constant Weight_Array := [1, 3, 2, 4, 1, 2, 3, 4];
begin
   Assert (Pick (Weights, 1) = 1);
   Assert (Pick (Weights, 2) = 2);
   Assert (Pick (Weights, 15) = 7);
end Tests;
