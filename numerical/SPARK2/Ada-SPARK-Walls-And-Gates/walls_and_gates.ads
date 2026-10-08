pragma Ada_2022;

package Walls_And_Gates with SPARK_Mode => On is
   Size : constant := 8;
   subtype Index is Positive range 1 .. Size;
   subtype Cell is Integer range 0 .. 1;
   type Grid is array (Index, Index) of Cell;
   type Count is mod 65;

   --  Count of gates.
   function Gate_Count (G : Grid) return Count with Global => null;
end Walls_And_Gates;
