--  PLACEHOLDER: a hard-coded index permutation for one complete-tree shape; no traversal; see tools/vv/hidden_stub.csv
pragma Ada_2022;

package Flatten_Binary_Tree_To_Linked_List_Lite with SPARK_Mode => On is
   Capacity : constant := 15;
   subtype Index is Positive range 1 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   type Tree is array (Index) of Value;

   function Flatten (Input : Tree) return Tree
     with Global => null;
end Flatten_Binary_Tree_To_Linked_List_Lite;
