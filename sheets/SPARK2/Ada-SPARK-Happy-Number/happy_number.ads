pragma SPARK_Mode (On);

package Happy_Number is
   subtype Number is Positive range 1 .. 2_147_483_647;

   function Is_Happy (N : Number) return Boolean;
end Happy_Number;
