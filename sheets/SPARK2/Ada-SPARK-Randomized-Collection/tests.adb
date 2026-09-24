with Ada.Assertions; use Ada.Assertions;
with Randomized_Collection; use Randomized_Collection;
procedure Tests is
   C : Collection := Empty; S : Seed := 0; V : Value;
begin
   Add (C, 12); Add (C, -4); Assert (Contains (C, 12)); Assert (not Contains (C, 7));
   Next (S, V); Assert (V = -99); Assert (Size (C) = 2);
end Tests;
