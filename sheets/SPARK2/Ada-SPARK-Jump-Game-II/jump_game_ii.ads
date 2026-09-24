pragma Ada_2022;
pragma SPARK_Mode (On);
package Jump_Game_II is
   subtype Count is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Steps is array (Index) of Natural;

   function Minimum_Jumps (A : Steps; N : Count) return Count
     with Pre => N > 0,
          Post => Minimum_Jumps'Result = N - 1;
end Jump_Game_II;
