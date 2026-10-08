pragma Ada_2022;

package Range_Sum_Query_2D_Immutable with SPARK_Mode => On is
   Size : constant := 8;
   subtype Index is Positive range 1 .. Size;
   subtype Cell is Integer range 0 .. 1;
   subtype Sum is Integer range 0 .. Size * Size;
   type Grid is array (Index, Index) of Cell;

   function Sum_All (G : Grid) return Sum with Global => null;
end Range_Sum_Query_2D_Immutable;
