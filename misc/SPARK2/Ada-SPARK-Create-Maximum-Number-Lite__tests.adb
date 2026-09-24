with Ada.Assertions; use Ada.Assertions;
with Create_Maximum_Number_Lite; use Create_Maximum_Number_Lite;
procedure Tests is
   A : constant Digit_Array := [3, 4, 6, 5, others => 0];
   B : constant Digit_Array := [9, 1, 2, 5, others => 0];
   R : constant Digit_Array := Maximum_Prefix (A, B, 4);
begin
   Assert (Maximum_Digit (A, B, 4) = 9);
   Assert (R (1) = 9 and R (2) = 4 and R (3) = 6 and R (4) = 5);
end Tests;
