pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Candy; use Candy;
procedure Tests is
   Ratings : Ratings_Array := [others => 0];
begin
   Ratings (1) := 5;
   Assert (Candy_Count (Ratings, 1) = 1);
   Put_Line ("PASS Ada-SPARK-Candy");
end Tests;
