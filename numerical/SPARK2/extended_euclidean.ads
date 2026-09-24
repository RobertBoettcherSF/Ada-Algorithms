pragma SPARK_Mode (On);

package Extended_Euclidean is
   subtype Input is Positive range 1 .. 1_000;

   function GCD (A, B : Input) return Input
     with Global => null;
end Extended_Euclidean;
