pragma SPARK_Mode (On);

package Surface_Area_Of_3D_Shapes is
   subtype Height is Integer range 0 .. 8;
   type Grid is array (1 .. 2, 1 .. 2) of Height;
   subtype Surface is Natural range 0 .. 192;

   function Surface_Area (G : Grid) return Surface;
end Surface_Area_Of_3D_Shapes;
