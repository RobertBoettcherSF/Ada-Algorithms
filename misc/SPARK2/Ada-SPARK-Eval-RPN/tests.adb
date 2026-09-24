with Ada.Assertions; use Ada.Assertions;
with Eval_RPN; use Eval_RPN;

procedure Tests is
begin
   Assert (Evaluate (2, 3, Add) = 5);
   Assert (Evaluate (8, 3, Subtract) = 5);
   Assert (Evaluate (6, 7, Multiply) = 42);
end Tests;
