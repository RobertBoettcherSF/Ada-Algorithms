pragma Ada_2022;
package Maximal_Square with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 4;
   subtype Bit is Natural range 0 .. 1;
   type Matrix is array (Index, Index) of Bit;
   subtype Side is Natural range 0 .. 4;
   function Largest_Side (A : Matrix) return Side with Global => null;
end Maximal_Square;
