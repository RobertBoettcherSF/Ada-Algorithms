pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO; with Bitset; use Bitset;
procedure Tests is S : Set;
begin Initialize (S); Include (S, 1); Include (S, 7); Include (S, 31); Assert (Contains (S, 7) and then Cardinality (S) = 3); Exclude (S, 7); Assert (not Contains (S, 7) and then Cardinality (S) = 2); Put_Line ("PASS Bitset"); end Tests;
