pragma SPARK_Mode (On);

package Maximum_Subarray is
   subtype Length is Natural range 0 .. 4;
   subtype Value is Integer range -100 .. 100;
   subtype Score is Integer range -1_000 .. 1_000;
   type Values is array (Positive range 1 .. 4) of Value;

   function Best_Sum (A : Values; N : Length) return Score
     with Global => null;
end Maximum_Subarray;
