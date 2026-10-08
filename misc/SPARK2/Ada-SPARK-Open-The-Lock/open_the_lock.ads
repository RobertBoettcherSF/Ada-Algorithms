pragma Ada_2022;

package Open_The_Lock with SPARK_Mode => On is
   Size : constant := 8;
   subtype Index is Positive range 1 .. Size;
   subtype Cell is Integer range 0 .. 1;
   type Grid is array (Index, Index) of Cell;
   type Count is mod 65;

   --  Bounded sum of wheel turns.
   function Turn_Sum (G : Grid) return Count with Global => null;
end Open_The_Lock;
