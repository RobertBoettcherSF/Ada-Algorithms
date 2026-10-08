pragma SPARK_Mode (On);

package Self_Dividing_Numbers is
   subtype Input is Positive range 1 .. 1_000_000_000;

   function Is_Self_Dividing (Value : Input) return Boolean
     with Global => null;
end Self_Dividing_Numbers;
