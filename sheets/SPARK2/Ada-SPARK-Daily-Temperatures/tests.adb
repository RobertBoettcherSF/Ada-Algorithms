with Ada.Assertions; use Ada.Assertions;
with Daily_Temperatures; use Daily_Temperatures;
procedure Tests is
   T : constant Temperature_Array := (1 => 73, 2 => 74, 3 => 75, 4 => 71,
      5 => 69, 6 => 72, 7 => 76, 8 => 73);
   D : constant Distance_Array := Next_Warmer (T);
begin
   Assert (D (1) = 1 and D (2) = 1 and D (3) = 4 and D (4) = 2);
   Assert (D (5) = 1 and D (6) = 1 and D (7) = 0 and D (8) = 0);
end Tests;
