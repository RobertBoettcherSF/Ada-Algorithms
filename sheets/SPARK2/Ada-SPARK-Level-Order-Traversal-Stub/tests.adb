pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Level_Order_Traversal_Stub; use Level_Order_Traversal_Stub;

procedure Tests is
   T : Tree := Empty;
   U : Tree := Empty;
begin
   Set_Node (T, 1, 1, 2, 3);
   Set_Node (T, 2, 2, 4, 5);
   Set_Node (T, 3, 3, 0, 6);
   Set_Node (T, 4, 4, 0, 0);
   Set_Node (T, 5, 5, 0, 0);
   Set_Node (T, 6, 6, 0, 0);
   if Level_Count (T, 1, 0) /= 1 or else
     Level_Count (T, 1, 1) /= 2 or else
     Level_Count (T, 1, 2) /= 3 then
      raise Program_Error;
   end if;
   Put_Line ("Level Order Traversal Stub: PASS");
end Tests;
