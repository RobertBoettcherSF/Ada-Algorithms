pragma Ada_2022;
package Max_Area_Of_Island with SPARK_Mode => On is
   Size : constant := 8;
   subtype Index is Positive range 1 .. Size;
   subtype Cell is Integer range 0 .. 1;
   type Grid is array (Index, Index) of Cell;
   type Area is mod 65;

   function Max_Area (G : Grid) return Area with Global => null;
end Max_Area_Of_Island;
