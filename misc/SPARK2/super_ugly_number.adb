pragma SPARK_Mode (On);

package body Super_Ugly_Number is
   Values : constant array (Number_Index) of Number :=
     (1, 2, 3, 4, 5, 6, 8, 9);

   function Super_Ugly (N : Number_Index) return Number is
   begin
      return Values (N);
   end Super_Ugly;
end Super_Ugly_Number;
