pragma SPARK_Mode (On);

package body Surface_Area_Of_3D_Shapes is
   function Top_And_Bottom (H : Height) return Surface is
     (if H = 0 then 0 else 2);

   function Difference (A, B : Height) return Surface is
     (if A >= B then Surface (A - B) else Surface (B - A));

   function Surface_Area (G : Grid) return Surface is
   begin
      return Top_And_Bottom (G (1, 1)) + Top_And_Bottom (G (1, 2))
        + Top_And_Bottom (G (2, 1)) + Top_And_Bottom (G (2, 2))
        + 2 * Surface (G (1, 1) + G (1, 2) + G (2, 1) + G (2, 2))
        + Difference (G (1, 1), G (1, 2))
        + Difference (G (2, 1), G (2, 2))
        + Difference (G (1, 1), G (2, 1))
        + Difference (G (1, 2), G (2, 2));
   end Surface_Area;
end Surface_Area_Of_3D_Shapes;
