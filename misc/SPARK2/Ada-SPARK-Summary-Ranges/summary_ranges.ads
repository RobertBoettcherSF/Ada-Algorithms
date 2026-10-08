pragma Ada_2022;
package Summary_Ranges with SPARK_Mode => On is
   -- Number of missing runs for the fixed sorted sample (0, 1, 3, 5, 6, 10).
   subtype Number is Natural range 0 .. 10;
   subtype Range_Count is Natural range 0 .. 3;
   function Summary (N : Number) return Range_Count with Global => null;
end Summary_Ranges;
