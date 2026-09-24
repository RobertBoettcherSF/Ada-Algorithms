with Ada.Assertions; use Ada.Assertions;
with Next_Greater_Element_I; use Next_Greater_Element_I;
procedure Tests is
   R : constant Result_Array := Next_Greater ((1 => 2, 2 => 1, 3 => 3, 4 => 0));
begin
   Assert (R (1) = 3 and R (2) = 3 and R (3) = -1 and R (4) = -1);
end Tests;
