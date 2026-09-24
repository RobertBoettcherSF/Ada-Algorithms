pragma Ada_2022;
pragma SPARK_Mode (On);
package Jump_Game is
   subtype Count is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Steps is array (Index) of Natural;

   function Can_Jump (A : Steps; N : Count) return Boolean
     with Pre => N > 0,
          Post => Can_Jump'Result = (A (Index (N)) > 0);
end Jump_Game;
