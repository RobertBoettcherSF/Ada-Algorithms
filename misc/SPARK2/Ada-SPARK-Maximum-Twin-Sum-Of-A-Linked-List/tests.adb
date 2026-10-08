with Ada.Text_IO;
with Maximum_Twin_Sum_Of_A_Linked_List;
with Full_Append_Check;
procedure Tests is
   use Maximum_Twin_Sum_Of_A_Linked_List;
   L : List := Empty;
   Answer : Twin_Sum;
begin
   Append (L, 4); Append (L, 2); Append (L, 7); Append (L, 8);
   Answer := Maximum_Twin_Sum (L);
   pragma Assert (Answer = 12);
   Ada.Text_IO.Put_Line ("Maximum twin sum of a linked list: OK");
   Full_Append_Check;
end Tests;
