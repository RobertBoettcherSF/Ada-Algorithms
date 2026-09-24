pragma Ada_2022;

package Capacity_To_Ship_Packages with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Weight is Positive range 1 .. 100;
   subtype Capacity is Positive range 1 .. 800;
   subtype Day_Count is Positive range 1 .. Length;
   type Weight_Array is array (Index) of Weight;

   function Minimum_Capacity
     (Weights : Weight_Array; Days : Day_Count) return Capacity
     with Global => null;
end Capacity_To_Ship_Packages;
