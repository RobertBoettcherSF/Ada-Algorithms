pragma SPARK_Mode (On);

package Target_Sum is
   subtype Length is Natural range 0 .. 4;
   subtype Value is Natural range 0 .. 4;
   subtype Target is Integer range -16 .. 16;
   subtype Count is Natural range 0 .. 100;
   type Values is array (Positive range 1 .. 4) of Value;

   function Ways_To_Target
     (A : Values; N : Length; Goal : Target) return Count
     with Global => null;
end Target_Sum;
