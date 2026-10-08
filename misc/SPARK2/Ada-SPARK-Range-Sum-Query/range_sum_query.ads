pragma Ada_2022;
package Range_Sum_Query with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 16;
   subtype Cell is Natural range 0 .. 10;
   type Values is array (Index) of Cell;
   function Sum (A : Values; Left, Right : Index) return Natural
     with Pre => Left <= Right, Global => null;
end Range_Sum_Query;
