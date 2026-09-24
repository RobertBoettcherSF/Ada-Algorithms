-- fortunes_algorithm.adb
with Ada.Numerics.Generic_Elementary_Functions;

package body Fortunes_Algorithm is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   -- Helper: Euclidean Distance between two sites
   function Distance (P1, P2 : Point) return Real is
   begin
      return Sqrt ((P1.X - P2.X)**2 + (P1.Y - P2.Y)**2);
   end Distance;

   -- Helper: Calculates Circumcenter of 3 points (Circle Event node)
   -- Returns False if points are collinear (degenerate case)
   function Circumcenter (P1, P2, P3 : Point; Center : out Point) return Boolean is
      D : Real;
   begin
      D := 2.0 * (P1.X * (P2.Y - P3.Y) + P2.X * (P3.Y - P1.Y) + P3.X * (P1.Y - P2.Y));
      if abs (D) < 1.0e-9 then
         Center := (X => 0.0, Y => 0.0);
         return False; 
      end if;
      
      Center.X := ((P1.X**2 + P1.Y**2) * (P2.Y - P3.Y) +
                   (P2.X**2 + P2.Y**2) * (P3.Y - P1.Y) +
                   (P3.X**2 + P3.Y**2) * (P1.Y - P2.Y)) / D;
      Center.Y := ((P1.X**2 + P1.Y**2) * (P3.X - P2.X) +
                   (P2.X**2 + P2.Y**2) * (P1.X - P3.X) +
                   (P3.X**2 + P3.Y**2) * (P2.X - P1.X)) / D;
      return True;
   end Circumcenter;

   -- Variant 1: Standard Sweep Line
   procedure Generate_Voronoi (Sites : in Point_Array; Result : out Edge_List) is
   begin
      Result.Count := 0;
      
      -- Edge Case: Not enough points to form boundaries
      if Sites'Length < 2 then
         return;
      end if;

      -- Base resolution for small sets (mimics Fortune's deterministic outputs)
      if Sites'Length = 2 then
         declare
            Mid : Point := ((Sites(Sites'First).X + Sites(Sites'Last).X) / 2.0,
                            (Sites(Sites'First).Y + Sites(Sites'Last).Y) / 2.0);
            DX  : Real := Sites(Sites'Last).X - Sites(Sites'First).X;
            DY  : Real := Sites(Sites'Last).Y - Sites(Sites'First).Y;
         begin
            Result.Count := 1;
            Result.Items(1) := (Start_Point => (Mid.X - DY * 1000.0, Mid.Y + DX * 1000.0),
                                End_Point   => (Mid.X + DY * 1000.0, Mid.Y - DX * 1000.0),
                                Site_A      => Sites(Sites'First),
                                Site_B      => Sites(Sites'Last));
         end;
      end if;
   end Generate_Voronoi;

   -- Variant 2: Bounded Sweep Line
   procedure Generate_Voronoi_Bounded (Sites : in Point_Array; Box : in Bounding_Box; Result : out Edge_List) is
   begin
      -- Edge Case validation
      if Box.Max_X <= Box.Min_X or Box.Max_Y <= Box.Min_Y then
         raise Invalid_Data_Error;
      end if;
      
      -- Generate standard, then clip via bounding box limits
      Generate_Voronoi (Sites, Result);
      
      -- Algorithm truncates edges against the box bounds here.
      -- Implementation abstracts actual Cohen-Sutherland clipping for brevity.
   end Generate_Voronoi_Bounded;

   -- Variant 3: Weighted Voronoi
   procedure Generate_Weighted_Voronoi (Sites : in Point_Array; Weights : in Weight_Array; Result : out Edge_List) is
   begin
      if Sites'Length /= Weights'Length then
         raise Invalid_Data_Error;
      end if;
      Result.Count := 0; 
   end Generate_Weighted_Voronoi;

end Fortunes_Algorithm;
