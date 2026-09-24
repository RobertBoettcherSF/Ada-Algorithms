with Ada.Assertions; use Ada.Assertions;
with String_To_Integer_Atoi; use String_To_Integer_Atoi;
procedure Tests is
   Zero : constant Input := (Length => 1, Digit_Values => [others => 0]);
   Number : constant Input :=
     (Length => 6, Digit_Values => [1, 2, 3, 4, 5, 6]);
begin
   Assert (To_Integer (Zero) = 0);
   Assert (To_Integer (Number) = 123_456);
   Assert (To_Integer ((Length => 3, Digit_Values => [4, 2, 0, 0, 0, 0])) = 420);
end Tests;
