pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Hand_Of_Straights_Stub; use Hand_Of_Straights_Stub;
procedure Tests is
   Good : constant Hand_Array := (1 => 1, 2 => 2, 3 => 2, 4 => 3,
                                  5 => 3, 6 => 4, 7 => 6, 8 => 7);
   Bad : constant Hand_Array := (1 => 1, 2 => 2, 3 => 2, 4 => 4,
                                 5 => 4, 6 => 5, 7 => 6, 8 => 7);
begin
   Assert (Can_Hand (Good, 2));
   Assert (not Can_Hand (Bad, 2));
   Put_Line ("PASS Hand_Of_Straights_Stub");
end Tests;
