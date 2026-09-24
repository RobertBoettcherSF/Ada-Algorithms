pragma Ada_2022;

package Leaf_Similar_Trees with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Index is Positive range 1 .. Capacity;
   subtype Leaf_Index is Positive range 8 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   type Tree is array (Index) of Value;

   function Leaf_Similar (Left, Right : Tree) return Boolean
     with Global => null;
end Leaf_Similar_Trees;
