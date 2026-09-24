pragma SPARK_Mode (On);

package Projection_Area_Of_3D_Shapes is
   subtype Height is Integer range 0 .. 8;
   type Grid is array (1 .. 2, 1 .. 2) of Height;
   subtype Area is Natural range 0 .. 64;

   function Projection_Area (G : Grid) return Area;
end Projection_Area_Of_3D_Shapes;
