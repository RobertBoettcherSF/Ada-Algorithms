pragma Ada_2022;

package Convert_BST_To_Greater_Tree with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Index is Positive range 1 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   type Tree is array (Index) of Value;
   type Greater_Tree is array (Index) of Integer;

   function Convert (Input : Tree) return Greater_Tree
     with Global => null;
end Convert_BST_To_Greater_Tree;
