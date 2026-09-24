pragma SPARK_Mode (On);

package Prime_Check is
   subtype Input is Positive range 2 .. 1_000;

   function Is_Prime (N : Input) return Boolean
     with Global => null;
end Prime_Check;
