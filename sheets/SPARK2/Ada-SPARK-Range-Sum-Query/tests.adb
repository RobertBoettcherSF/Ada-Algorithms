with Range_Sum_Query;
procedure Tests is
   A : constant Range_Sum_Query.Values :=
     [1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6, 7 => 7, 8 => 8,
      9 => 9, 10 => 10, 11 => 0, 12 => 0, 13 => 0, 14 => 0, 15 => 0, 16 => 0];
begin
   pragma Assert (Range_Sum_Query.Sum (A, 1, 1) = 1);
   pragma Assert (Range_Sum_Query.Sum (A, 2, 5) = 14);
   pragma Assert (Range_Sum_Query.Sum (A, 1, 10) = 55);
end Tests;
