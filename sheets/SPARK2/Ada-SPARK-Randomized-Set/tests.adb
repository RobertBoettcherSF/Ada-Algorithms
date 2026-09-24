pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO; with Randomized_Set; use Randomized_Set;
procedure Tests is S : Set; V : Integer;
begin Initialize (S); Insert (S, 4); Insert (S, 4); Insert (S, 9); Assert (Length (S) = 2 and then Contains (S, 9)); Remove_Last (S, V); Assert (V = 9 and then not Contains (S, 9)); Put_Line ("PASS randomized set"); end Tests;
