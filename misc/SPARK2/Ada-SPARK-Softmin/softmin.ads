pragma SPARK_Mode (On);

package Softmin is
   subtype Score is Integer range -100 .. 100;

   function Value (Left, Right : Score) return Score;
end Softmin;
