pragma Ada_2022;

package Trim_Binary_Search_Tree with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Index is Positive range 1 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   type Tree is array (Index) of Value;

   function Trim (Input : Tree; Low, High : Value) return Tree
     with Pre => Low <= High, Global => null;
end Trim_Binary_Search_Tree;
