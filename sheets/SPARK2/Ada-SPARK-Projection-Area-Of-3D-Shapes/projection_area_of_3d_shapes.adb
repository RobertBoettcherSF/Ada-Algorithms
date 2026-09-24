pragma SPARK_Mode (On);

package body Projection_Area_Of_3D_Shapes is
   function Occupied (H : Height) return Area is
     (if H = 0 then 0 else 1);

   function Max_Height (A, B : Height) return Area is
     (if A >= B then Area (A) else Area (B));

   function Projection_Area (G : Grid) return Area is
   begin
      return Occupied (G (1, 1)) + Occupied (G (1, 2))
        + Occupied (G (2, 1)) + Occupied (G (2, 2))
        + Max_Height (G (1, 1), G (1, 2))
        + Max_Height (G (2, 1), G (2, 2))
        + Max_Height (G (1, 1), G (2, 1))
        + Max_Height (G (1, 2), G (2, 2));
   end Projection_Area;
end Projection_Area_Of_3D_Shapes;
