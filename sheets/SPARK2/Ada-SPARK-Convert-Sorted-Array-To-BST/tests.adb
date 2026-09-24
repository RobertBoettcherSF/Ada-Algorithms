with Ada.Text_IO; use Ada.Text_IO;
with Convert_Sorted_Array_To_BST;
procedure Tests is
   A : Convert_Sorted_Array_To_BST.Sorted_Array := (1, 2, 3, 4, 5, 6, 7);
   T : Convert_Sorted_Array_To_BST.Tree := Convert_Sorted_Array_To_BST.Build (A);
begin
   if Convert_Sorted_Array_To_BST.Node_Value (T, 1) /= 4
     or else Convert_Sorted_Array_To_BST.Node_Value (T, 7) /= 7 then raise Program_Error; end if;
   Put_Line ("convert sorted array: PASS");
end Tests;
