with Ada.Assertions; use Ada.Assertions;
with Next_Greater_Element_I; use Next_Greater_Element_I;
procedure Tests is
   R : constant Result_Array := Next_Greater ((1 => 2, 2 => 1, 3 => 3, 4 => 0));
   R2 : constant Result_Array := Next_Greater ((1 => 4, 2 => 3, 3 => 2, 4 => 1));
   R3 : constant Result_Array := Next_Greater ((1 => 1, 2 => 3, 3 => 2, 4 => 4));
begin
   Assert (R (1) = 3 and R (2) = 3 and R (3) = -1 and R (4) = -1);
   --  Strictly descending: every next-greater is absent
   Assert (R2 (1) = -1 and R2 (2) = -1 and R2 (3) = -1 and R2 (4) = -1);
   Assert (R3 (1) = 3 and R3 (2) = 4 and R3 (3) = 4 and R3 (4) = -1);
end Tests;
