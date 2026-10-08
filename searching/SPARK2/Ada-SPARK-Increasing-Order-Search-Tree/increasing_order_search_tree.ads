pragma Ada_2022;

package Increasing_Order_Search_Tree with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Index is Positive range 1 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   type Tree is array (Index) of Value;

   function Increasing_Order (Input : Tree) return Tree
     with Global => null;
end Increasing_Order_Search_Tree;
