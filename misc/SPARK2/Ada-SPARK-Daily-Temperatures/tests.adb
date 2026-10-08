with Ada.Assertions; use Ada.Assertions;
with Daily_Temperatures; use Daily_Temperatures;
procedure Tests is
   T : constant Temperature_Array :=
     (1 => 73, 2 => 74, 3 => 75, 4 => 71, 5 => 69, 6 => 72, 7 => 76, 8 => 73);
   D : constant Distance_Array := Next_Warmer (T);
   --  Strictly descending (length fixed at 8 by Position)
   T2 : constant Temperature_Array :=
     (1 => 80, 2 => 70, 3 => 60, 4 => 50, 5 => 40, 6 => 30, 7 => 20, 8 => 10);
   D2 : constant Distance_Array := Next_Warmer (T2);
   T3 : constant Temperature_Array := (others => 50);
   D3 : constant Distance_Array := Next_Warmer (T3);
begin
   Assert (D (1) = 1 and D (2) = 1 and D (3) = 4 and D (4) = 2);
   Assert (D (5) = 1 and D (6) = 1 and D (7) = 0 and D (8) = 0);
   Assert (D2 (1) = 0 and D2 (2) = 0 and D2 (3) = 0 and D2 (4) = 0
           and D2 (5) = 0 and D2 (6) = 0 and D2 (7) = 0 and D2 (8) = 0);
   Assert (D3 (1) = 0 and D3 (2) = 0 and D3 (3) = 0 and D3 (4) = 0
           and D3 (5) = 0 and D3 (6) = 0 and D3 (7) = 0 and D3 (8) = 0);
end Tests;
