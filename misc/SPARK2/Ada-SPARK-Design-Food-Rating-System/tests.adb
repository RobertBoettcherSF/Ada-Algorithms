pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO; with Design_Food_Rating_System; use Design_Food_Rating_System;
procedure Tests is
begin Initialize; Set_Rating (4); Assert (Current_Rating = 4); Set_Rating (5); Assert (Current_Rating = 5); Put_Line ("PASS food rating"); end Tests;
