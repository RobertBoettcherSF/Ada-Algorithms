with Single_Number_III; use Single_Number_III;
procedure Tests is
   Values : constant Vector := [4, 1, 7, 4, 1, 9];
   Result : constant Pair := Singles (Values);
begin
   pragma Assert (Result.First = 7);
   pragma Assert (Result.Second = 9);
end Tests;
