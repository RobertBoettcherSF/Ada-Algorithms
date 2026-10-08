pragma SPARK_Mode (On);

package Sqrtx is
   subtype Input is Natural range 0 .. 10_000;
   subtype Root is Natural range 0 .. 100;

   function Integer_Square_Root (Value : Input) return Root
     with Global => null;
end Sqrtx;
