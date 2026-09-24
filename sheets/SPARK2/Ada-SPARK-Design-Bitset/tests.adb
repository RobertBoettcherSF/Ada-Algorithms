pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO; with Design_Bitset; use Design_Bitset;
procedure Tests is S : Set;
begin Initialize (S); Include (S, 2); Include (S, 31); Assert (Cardinality (S) = 2); Exclude (S, 2); Assert (not Contains (S, 2) and then Contains (S, 31)); Put_Line ("PASS bitset"); end Tests;
