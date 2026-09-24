pragma SPARK_Mode (On);

package Min_Cost_Climbing_Stairs is
   Cost_Count : constant := 6;
   subtype Index is Positive range 1 .. Cost_Count;
   subtype Cost is Integer range 0 .. 100;
   subtype Result is Integer range 0 .. 600;
   type Cost_Array is array (Index) of Cost;

   function Compute (Costs : Cost_Array) return Result;
end Min_Cost_Climbing_Stairs;
