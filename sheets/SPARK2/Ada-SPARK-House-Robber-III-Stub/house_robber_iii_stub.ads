pragma SPARK_Mode (On);

package House_Robber_III_Stub is
   House_Count : constant := 6;
   subtype Index is Positive range 1 .. House_Count;
   subtype Amount is Integer range 0 .. 100;
   subtype Result is Integer range 0 .. 600;
   type Amount_Array is array (Index) of Amount;

   function Compute (Values : Amount_Array) return Result;
end House_Robber_III_Stub;
