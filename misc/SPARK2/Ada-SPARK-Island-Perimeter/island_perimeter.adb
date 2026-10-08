pragma Ada_2022;
package body Island_Perimeter with SPARK_Mode => On is
   function Cell (G : Grid; R, C : Coordinate) return Cell_Value is
   begin
      if not G (R, C) then
         return 0;
      end if;
      return (if R = 1 then 1 elsif not G (R - 1, C) then 1 else 0)
        + (if R = Grid_Size then 1 elsif not G (R + 1, C) then 1 else 0)
        + (if C = 1 then 1 elsif not G (R, C - 1) then 1 else 0)
        + (if C = Grid_Size then 1 elsif not G (R, C + 1) then 1 else 0);
   end Cell;

   function Perimeter (G : Grid) return Perimeter_Value is
   begin
      return Cell (G, 1, 1) + Cell (G, 1, 2) + Cell (G, 1, 3) + Cell (G, 1, 4)
        + Cell (G, 2, 1) + Cell (G, 2, 2) + Cell (G, 2, 3) + Cell (G, 2, 4)
        + Cell (G, 3, 1) + Cell (G, 3, 2) + Cell (G, 3, 3) + Cell (G, 3, 4)
        + Cell (G, 4, 1) + Cell (G, 4, 2) + Cell (G, 4, 3) + Cell (G, 4, 4);
   end Perimeter;
end Island_Perimeter;
