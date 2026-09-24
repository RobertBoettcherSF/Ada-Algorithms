pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Find_The_City_With_Smallest_Number_Of_Neighbors; use Find_The_City_With_Smallest_Number_Of_Neighbors;
procedure Tests is
   E : Edge_Array := (others => (U => 1, V => 1, W => 0));
   Answer : Node;
begin
   E (1) := (1, 2, 3); E (2) := (2, 3, 1); E (3) := (3, 4, 4);
   E (4) := (4, 5, 2); E (5) := (5, 6, 1); E (6) := (1, 6, 10);
   Compute (E, 4, Answer);
   Assert (Answer = 6);
   Put_Line ("PASS Find_The_City_With_Smallest_Number_Of_Neighbors");
end Tests;
