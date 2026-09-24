pragma SPARK_Mode (On);

package Reach_A_Number is
   subtype Target is Integer range -100 .. 100;
   subtype Step_Count is Natural range 0 .. 20;

   function Minimum_Steps (Value : Target) return Step_Count
     with Global => null;
end Reach_A_Number;
