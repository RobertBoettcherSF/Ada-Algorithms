pragma Ada_2022;

package Capacity_To_Ship_Packages with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Weight is Positive range 1 .. 100;
   subtype Capacity is Positive range 1 .. 800;
   subtype Day_Count is Positive range 1 .. Length;
   type Weight_Array is array (Index) of Weight;

   --  Probes: capacities tried, each a greedy pass over Weights.
   type Capacity_Result is record
      Minimum : Capacity;
      Probes  : Natural;
   end record;

   function Minimum_Capacity_Counted
     (Weights : Weight_Array; Days : Day_Count) return Capacity_Result
     with Global => null;

   function Minimum_Capacity
     (Weights : Weight_Array; Days : Day_Count) return Capacity
   is (Minimum_Capacity_Counted (Weights, Days).Minimum)
     with Global => null;
end Capacity_To_Ship_Packages;
