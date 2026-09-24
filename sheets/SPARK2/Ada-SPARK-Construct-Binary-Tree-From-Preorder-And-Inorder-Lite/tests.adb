with Ada.Text_IO; use Ada.Text_IO;
with Construct_Preorder_Inorder_Lite;
procedure Tests is
   Pre : Construct_Preorder_Inorder_Lite.Traversal_Array := (1, 2, 3);
   Ino : Construct_Preorder_Inorder_Lite.Traversal_Array := (2, 1, 3);
   T : Construct_Preorder_Inorder_Lite.Tree := Construct_Preorder_Inorder_Lite.Build (Pre, Ino);
begin
   if Construct_Preorder_Inorder_Lite.Node_Value (T, 1) /= 1
     or else Construct_Preorder_Inorder_Lite.Node_Value (T, 2) /= 2 then raise Program_Error; end if;
   Put_Line ("construct preorder/inorder: PASS");
end Tests;
