with Ada.Assertions; use Ada.Assertions;
with Basic_Calculator_Stub; use Basic_Calculator_Stub;

procedure Tests is
begin
   Assert (Calculate (7, 5, Add) = 12);
   Assert (Calculate (7, 5, Subtract) = 2);
   Assert (Calculate (7, 5, Multiply) = 35);
   Assert (Calculate (20, 5, Divide) = 4);
end Tests;
