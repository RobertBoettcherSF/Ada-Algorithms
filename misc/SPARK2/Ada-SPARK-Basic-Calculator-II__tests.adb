with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Basic_Calculator_II; use Basic_Calculator_II;
procedure Tests is begin
   Assert (Evaluate (7, 3, Plus) = 10); Assert (Evaluate (7, 3, Times) = 21); Assert (Evaluate (7, 3, Divide) = 2);
   Put_Line ("PASS Basic_Calculator_II");
end Tests;
