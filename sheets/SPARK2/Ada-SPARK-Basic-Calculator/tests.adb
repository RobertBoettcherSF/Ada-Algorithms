with Ada.Assertions; use Ada.Assertions;
with Basic_Calculator; use Basic_Calculator;
procedure Tests is
begin
   Assert (Evaluate (7, 5, Add) = 12);
   Assert (Evaluate (7, 5, Subtract) = 2);
   Assert (Evaluate (-3, 4, Multiply) = -12);
end Tests;
