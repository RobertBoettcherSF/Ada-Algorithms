pragma Ada_2022;

package Univalued_Binary_Tree with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Index is Positive range 1 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   type Tree is array (Index) of Value;

   function Is_Univalued (Input : Tree) return Boolean
     with Global => null;
end Univalued_Binary_Tree;
