pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Cheapest_Flights_Within_K_Stops; use Cheapest_Flights_Within_K_Stops;
procedure Tests is
   E : Edge_Array := (others => (U => 1, V => 1, Price => 0));
   Answer : Cost;
begin
   E (1) := (1, 2, 100); E (2) := (1, 3, 10); E (3) := (3, 2, 10);
   Compute (E, 1, 2, 0, Answer); Assert (Answer = 100);
   Compute (E, 1, 2, 1, Answer); Assert (Answer = 20);
   Put_Line ("PASS Cheapest_Flights_Within_K_Stops");
end Tests;
