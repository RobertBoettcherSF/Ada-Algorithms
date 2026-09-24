with Ada.Assertions; use Ada.Assertions;
with Design_Skiplist_Lite; use Design_Skiplist_Lite;
procedure Tests is S : Skiplist := Empty;
begin Insert (S, 5); Assert (First (S) = 5); Assert (Height (8) = 4); end Tests;
