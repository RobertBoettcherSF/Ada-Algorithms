pragma SPARK_Mode (On);

package Paint_House_Stub is
   House_Count : constant := 4;
   Color_Count : constant := 3;
   subtype House is Positive range 1 .. House_Count;
   subtype Color is Positive range 1 .. Color_Count;
   subtype Cost is Integer range 0 .. 100;
   subtype Result is Integer range 0 .. 400;
   type Cost_Matrix is array (House, Color) of Cost;

   function Compute (Costs : Cost_Matrix) return Result;
end Paint_House_Stub;
