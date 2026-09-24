with Ada.Assertions; use Ada.Assertions;
with Add_Without_Plus; use Add_Without_Plus;

procedure Tests is
begin
   Assert (Add (0, 0) = 0);
   Assert (Add (25, 17) = 42);
   Assert (Add (-25, 17) = -8);
   Assert (Add (25, -17) = 8);
   Assert (Add (-100, 100) = 0);
end Tests;
