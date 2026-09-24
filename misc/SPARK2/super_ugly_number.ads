pragma SPARK_Mode (On);

package Super_Ugly_Number is
   subtype Number_Index is Positive range 1 .. 8;
   subtype Number is Positive range 1 .. 1000;

   function Super_Ugly (N : Number_Index) return Number;
end Super_Ugly_Number;
