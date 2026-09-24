pragma SPARK_Mode (On);

package Number_Of_Steps is
   subtype Number is Natural range 0 .. 1_000_000_000;
   subtype Step_Count is Natural range 0 .. 60;

   function Steps_To_Zero (Value : Number) return Step_Count
     with Global => null;
end Number_Of_Steps;
