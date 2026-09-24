with Ada.Assertions; use Ada.Assertions;
with Remove_K_Digits; use Remove_K_Digits;
procedure Tests is
   V : constant Digit_Array := (1 => 1, 2 => 4, 3 => 3, 4 => 2,
      5 => 2, 6 => 1, 7 => 9, 8 => 0);
   R : constant Digit_Array := Remove_K (V, 3);
begin
   Assert (R (1) = 1 and R (2) = 4 and R (3) = 3 and R (4) = 2);
   Assert (R (5) = 2 and R (6) = 0 and R (7) = 0 and R (8) = 0);
end Tests;
