pragma SPARK_Mode (On);

--  Failing-test scaffold: Input widened to 0 .. 20 and Result to
--  Long_Long_Integer so the new test compiles; the body is still the
--  N <= 12 table.
package Factorial is
   subtype Input is Natural range 0 .. 20;
   subtype Result is Long_Long_Integer range 1 .. Long_Long_Integer'Last;

   function Compute (N : Input) return Result
     with Global => null;
end Factorial;
