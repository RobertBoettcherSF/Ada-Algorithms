pragma Ada_2022;

package Sum_Root_To_Leaf_Numbers with SPARK_Mode => On is
   Capacity : constant := 15;
   subtype Index is Positive range 1 .. Capacity;
   subtype Digit is Integer range 0 .. 9;
   type Tree is array (Index) of Digit;

   function Sum_Root_To_Leaf (Input : Tree) return Integer
     with Global => null;
end Sum_Root_To_Leaf_Numbers;
