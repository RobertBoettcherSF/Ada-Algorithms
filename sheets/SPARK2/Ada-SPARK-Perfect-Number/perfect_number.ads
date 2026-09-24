pragma SPARK_Mode (On);

package Perfect_Number is
   subtype Input is Positive range 1 .. 1_000_000_000;

   function Is_Perfect (Value : Input) return Boolean
     with Global => null;
end Perfect_Number;
