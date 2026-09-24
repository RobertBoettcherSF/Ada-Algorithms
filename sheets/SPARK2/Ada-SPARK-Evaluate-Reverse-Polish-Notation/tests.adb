with Ada.Assertions; use Ada.Assertions;
with Evaluate_Reverse_Polish_Notation; use Evaluate_Reverse_Polish_Notation;
procedure Tests is
begin
   Assert (Evaluate (2, 3, Add) = 5);
   Assert (Evaluate (8, 4, Subtract) = 4);
   Assert (Evaluate (3, 4, Multiply) = 12);
end Tests;
