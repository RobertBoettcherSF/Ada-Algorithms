with Ada.Assertions; use Ada.Assertions;
with Next_Greater_Node_In_Linked_List; use Next_Greater_Node_In_Linked_List;
procedure Tests is
   A : constant Values := [2, 1, 5, 3, 4, others => 0];
   R : constant Results := Next_Greater (A, 5);
begin
   Assert (R (1) = 5 and R (2) = 5 and R (3) = -1);
   Assert (R (4) = 4 and R (5) = -1);
end Tests;
