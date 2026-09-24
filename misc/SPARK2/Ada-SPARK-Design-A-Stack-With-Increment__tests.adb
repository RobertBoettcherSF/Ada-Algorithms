with Ada.Assertions; use Ada.Assertions;
with Design_A_Stack_With_Increment; use Design_A_Stack_With_Increment;
procedure Tests is S : Stack := Empty; V : Value;
begin Push (S, 3); Push (S, 7); Increment_Bottom (S, 1, 1); Pop (S, V); Assert (V = 7); Pop (S, V); Assert (V = 4); end Tests;
