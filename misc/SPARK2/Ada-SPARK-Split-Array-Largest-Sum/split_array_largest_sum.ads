pragma Ada_2022;

package Split_Array_Largest_Sum with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Element is Positive range 1 .. 100;
   subtype Limit is Positive range 1 .. 800;
   subtype Part_Count is Positive range 1 .. Length;
   type Input_Array is array (Index) of Element;

   function Largest_Sum
     (Input : Input_Array; Parts : Part_Count) return Limit
     with Global => null;
end Split_Array_Largest_Sum;
