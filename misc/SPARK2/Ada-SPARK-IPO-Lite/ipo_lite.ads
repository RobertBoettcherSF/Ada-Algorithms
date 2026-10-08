pragma SPARK_Mode (On);

package Ipo_Lite is
   Project_Count : constant := 4;
   subtype Capital is Natural range 0 .. 100;
   subtype Profit is Natural range 0 .. 50;
   type Capital_Array is array (Positive range 1 .. Project_Count) of Capital;
   type Profit_Array is array (Positive range 1 .. Project_Count) of Profit;

   function Best_Affordable_Profit
     (Initial : Capital; Required : Capital_Array; Gain : Profit_Array)
      return Profit;
end Ipo_Lite;
