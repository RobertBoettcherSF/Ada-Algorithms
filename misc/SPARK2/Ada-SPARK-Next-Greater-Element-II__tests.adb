with Ada.Assertions; use Ada.Assertions;
with Next_Greater_Element_II; use Next_Greater_Element_II;
procedure Tests is
   R : constant Result_Array := Next_Greater_Circular ((1 => 1, 2 => 2, 3 => 1, 4 => 0));
begin
   Assert (R (1) = 2 and R (2) = -1 and R (3) = 2 and R (4) = 1);
end Tests;
