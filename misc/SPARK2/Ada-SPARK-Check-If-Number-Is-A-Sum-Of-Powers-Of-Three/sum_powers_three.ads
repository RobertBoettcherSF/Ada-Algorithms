pragma SPARK_Mode (On);

package Sum_Powers_Three is
   subtype Number is Natural range 0 .. 1_000_000_000;

   function Is_Sum_Of_Powers_Of_Three (Value : Number) return Boolean
     with Global => null;
end Sum_Powers_Three;
