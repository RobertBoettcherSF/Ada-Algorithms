pragma SPARK_Mode (On);

package Maximum_Product_Subarray is
   subtype Length is Natural range 0 .. 4;
   subtype Value is Integer range -10 .. 10;
   subtype Score is Integer range -1_000_000 .. 1_000_000;
   type Values is array (Positive range 1 .. 4) of Value;

   function Best_Product (A : Values; N : Length) return Score
     with Global => null;
end Maximum_Product_Subarray;
