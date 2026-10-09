pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Exchange_Sort; use Exchange_Sort;
with Own_Checks;
procedure Tests is
   Input : constant Input_Array := [1 => 23, 2 => 4, 3 => 17, 4 => 9,
                                    5 => 1, 6 => 31, 7 => 12, 8 => 6];
   Result : constant Input_Array := Sort (Input);
   Dups   : constant Input_Array := [3, 1, 3, 0, 1, 3, 0, 31];
begin
   for I in Index loop
      if I < Index'Last then
         Assert (Result (I) <= Result (I + 1));
      end if;
   end loop;
   Assert (Result = [1, 4, 6, 9, 12, 17, 23, 31]);
   Assert (Sort (Dups) = [0, 0, 1, 1, 3, 3, 3, 31]);

   --  The contract predicates of the spec: Sort's Post is
   --  Is_Sorted (Result) and Is_Perm (Result, Input).
   Assert (Is_Sorted (Result) and then Is_Perm (Result, Input));
   Assert (Is_Sorted (Sort (Dups)) and then Is_Perm (Sort (Dups), Dups));
   --  They are not vacuous: an unsorted array, a sorted non-permutation
   --  (the all-zeros array, or the input with one value replaced) and a
   --  permutation with a changed multiplicity are rejected.
   Assert (not Is_Sorted (Input));
   Assert (Is_Sorted ([others => 0]) and then not Is_Perm ([others => 0], Input));
   Assert (not Is_Perm ([1, 4, 6, 9, 12, 17, 23, 23], Input));
   Assert (not Is_Perm ([0, 0, 1, 1, 3, 3, 31, 31], Dups));
   Assert (Is_Perm (Input, Result));
   --  Occ counts occurrences in A (1 .. Last).
   Assert (Occ (Dups, 3, 8) = 3 and then Occ (Dups, 3, 2) = 1
           and then Occ (Dups, 31, 7) = 0 and then Occ (Dups, 5, 8) = 0);
   Put_Line ("PASS Exchange_Sort");
   Own_Checks;
end Tests;
