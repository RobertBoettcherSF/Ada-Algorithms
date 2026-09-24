pragma Ada_2022;

package body Flatten_Binary_Tree_To_Linked_List_Lite with SPARK_Mode => On is
   function Flatten (Input : Tree) return Tree is
   begin
      return (1 => Input (1), 2 => Input (2), 3 => Input (4),
              4 => Input (8), 5 => Input (9), 6 => Input (5),
              7 => Input (10), 8 => Input (11), 9 => Input (3),
              10 => Input (6), 11 => Input (12), 12 => Input (13),
              13 => Input (7), 14 => Input (14), 15 => Input (15));
   end Flatten;
end Flatten_Binary_Tree_To_Linked_List_Lite;
