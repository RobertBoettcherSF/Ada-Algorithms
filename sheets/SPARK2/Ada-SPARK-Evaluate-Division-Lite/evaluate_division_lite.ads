pragma SPARK_Mode (On);

package Evaluate_Division_Lite with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Variable is Positive range 1 .. Capacity;
   subtype Ratio is Natural range 0 .. Capacity;
   type Relations is array (Variable, Variable) of Ratio;

   function Evaluate
     (Table : Relations; From, To : Variable) return Ratio
     with Global => null;
end Evaluate_Division_Lite;
