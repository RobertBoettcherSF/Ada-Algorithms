with Ada.Containers.Vectors;

package Watershed_Algorithm is

   type Pixel_Value is range 0 .. 255;
   type Label_Type is range -1 .. Integer'Last;
   
   WATERSHED_LINE : constant Label_Type := -1;
   UNLABELED      : constant Label_Type := 0;

   type Image_Grid is array (Positive range <>, Positive range <>) of Pixel_Value;
   type Label_Grid is array (Positive range <>, Positive range <>) of Label_Type;

   Dimension_Mismatch : exception;
   Empty_Image        : exception;

   -- 1. Marker-Based Watershed (Meyer's Algorithm)
   -- Uses a priority queue to flood the topography from predefined markers.
   procedure Meyer_Watershed (
      Image   : in     Image_Grid;
      Markers : in     Label_Grid;
      Result  :    out Label_Grid
   );

   -- 2. Immersion Watershed (Vincent & Soille - simplified)
   -- Sorts pixels by intensity and simulates water immersion, creating new basins at minima.
   procedure Immersion_Watershed (
      Image  : in     Image_Grid;
      Result :    out Label_Grid
   );

   -- 3. Topological Watershed (Drop of Water Principle)
   -- Assigns labels based on the steepest descent path to local minima.
   procedure Topological_Watershed (
      Image  : in     Image_Grid;
      Result :    out Label_Grid
   );

end Watershed_Algorithm;
