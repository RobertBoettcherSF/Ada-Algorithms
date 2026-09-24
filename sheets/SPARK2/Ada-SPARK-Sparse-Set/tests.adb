pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO; with Sparse_Set; use Sparse_Set;
procedure Tests is S : Set;
begin Initialize (S); Include (S, 3); Include (S, 7); Include (S, 11); Assert (Contains (S, 7) and then Length (S) = 3); Exclude (S, 7); Assert (not Contains (S, 7) and then Contains (S, 11) and then Length (S) = 2); Put_Line ("PASS Sparse_Set"); end Tests;
