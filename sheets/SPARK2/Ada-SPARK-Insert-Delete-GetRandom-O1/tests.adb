pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO; with Insert_Delete_GetRandom_O1; use Insert_Delete_GetRandom_O1;
procedure Tests is S : Set; V : Integer;
begin Initialize (S); Insert (S, 3); Insert (S, 8); Assert (Get_At (S, 2) = 8); Delete_Last (S, V); Assert (V = 8 and then Length (S) = 1); Put_Line ("PASS insert delete random"); end Tests;
