pragma SPARK_Mode (On);

-- Tiny abs-diff for GNAT Studio notes on-ramp (keeps the sheet non-vapor).
package Studio_Probe
  with SPARK_Mode => On
is
   subtype Value is Integer range -1_000 .. 1_000;
   subtype Non_Neg is Integer range 0 .. 2_000;

   function Abs_Diff (A, B : Value) return Non_Neg
     with
       Post   =>
         Abs_Diff'Result =
           (if A >= B then A - B else B - A),
       Global => null;
end Studio_Probe;
