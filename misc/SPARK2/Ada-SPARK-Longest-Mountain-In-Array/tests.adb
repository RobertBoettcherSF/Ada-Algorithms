pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Longest_Mountain_In_Array; use Longest_Mountain_In_Array;
with Own_Checks;
procedure Tests is
   Data : constant Values := [2, 1, 4, 7, 3, 2, 5, others => 0];
   --  Hand-worked (agent A3): 1 2 3 2 1 is one mountain of 5; a plateau
   --  (1 2 2 1) is no mountain; rising only is none; the cell after Length
   --  must not extend a mountain (1 3 2 with 1 after it, Length 3 -> 3).
   Hill    : constant Values := [1, 2, 3, 2, 1, others => 9];
   Plateau : constant Values := [1, 2, 2, 1, others => 0];
   Rising  : constant Values := [1, 2, 3, 4, others => 5];
   Cut     : constant Values := [1, 3, 2, 1, others => 0];
begin
   Assert (Longest (Data, 7) = 5);
   Assert (Longest (Hill, 5) = 5);
   Assert (Longest (Plateau, 4) = 0);
   Assert (Longest (Rising, 4) = 0);
   Assert (Longest (Cut, 3) = 3);
   Assert (Longest (Cut, 4) = 4);
   Assert (Longest (Cut, 2) = 0);
   Own_Checks;
end Tests;
