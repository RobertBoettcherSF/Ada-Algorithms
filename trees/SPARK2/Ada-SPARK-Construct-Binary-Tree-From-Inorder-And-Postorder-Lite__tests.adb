with Ada.Text_IO; use Ada.Text_IO;
with Construct_Inorder_Postorder_Lite;
procedure Tests is
   Ino : Construct_Inorder_Postorder_Lite.Traversal_Array := (2, 1, 3);
   Post : Construct_Inorder_Postorder_Lite.Traversal_Array := (2, 3, 1);
   T : Construct_Inorder_Postorder_Lite.Tree := Construct_Inorder_Postorder_Lite.Build (Ino, Post);
begin
   if Construct_Inorder_Postorder_Lite.Node_Value (T, 1) /= 1
     or else Construct_Inorder_Postorder_Lite.Node_Value (T, 3) /= 3 then raise Program_Error; end if;
   Put_Line ("construct inorder/postorder: PASS");
end Tests;
