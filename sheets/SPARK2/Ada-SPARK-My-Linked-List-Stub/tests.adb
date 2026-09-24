with Ada.Assertions; use Ada.Assertions;
with My_Linked_List_Stub; use My_Linked_List_Stub;
procedure Tests is
   Values : constant Elements := (10, 20, 30, others => 0);
begin
   Assert (Get (Values, 3, 1) = 10);
   Assert (Get (Values, 3, 3) = 30);
   Assert (Length_Of (3) = 3);
end Tests;
