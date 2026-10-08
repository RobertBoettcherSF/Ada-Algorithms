with Ada.Assertions; use Ada.Assertions;
with Pattern_132; use Pattern_132;
procedure Tests is
   Yes : constant Values := [3, 1, 4, 2, others => 0];
   No : constant Values := [1, 2, 3, 4, others => 0];
begin
   Assert (Exists (Yes, 4));
   Assert (not Exists (No, 4));
   Assert (not Exists (Yes, 0));
end Tests;
