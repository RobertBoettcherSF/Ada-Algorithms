pragma SPARK_Mode (On);

package Last_Stone_Weight is
   Stone_Count : constant := 6;
   subtype Weight is Natural range 0 .. 100;
   type Stone_Array is array (Positive range 1 .. Stone_Count) of Weight;

   function Final_Weight (Stones : Stone_Array) return Weight;
end Last_Stone_Weight;
