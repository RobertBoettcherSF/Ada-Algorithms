pragma Ada_2022;

package Partition_Around_Pivot with SPARK_Mode => On is
   Length : constant := 5;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -10 .. 10;
   type Value_Array is array (Index) of Value;

   function Partition (Input : Value_Array; Pivot : Value) return Value_Array
     with Global => null;
end Partition_Around_Pivot;
