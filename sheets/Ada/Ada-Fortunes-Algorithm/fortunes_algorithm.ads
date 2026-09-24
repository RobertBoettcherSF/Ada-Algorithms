-- fortunes_algorithm.ads
-- Specification for Fortune's Sweep Line Algorithm
package Fortunes_Algorithm is
   
   -- Strong typing for algorithm-specific data
   type Real is digits 15;
   
   type Point is record
      X, Y : Real;
   end record;
   type Point_Array is array (Positive range <>) of Point;
   
   type Weight_Array is array (Positive range <>) of Real;

   -- Represents an edge in the Voronoi Diagram
   type Edge is record
      Start_Point : Point;
      End_Point   : Point;
      Site_A      : Point; -- The two originating sites that dictate this bisector
      Site_B      : Point;
   end record;

   Max_Edges : constant := 1000;
   type Edge_Array is array (Positive range <>) of Edge;
   
   -- Bounded array for deterministic memory management in critical systems
   type Edge_List is record
      Items : Edge_Array (1 .. Max_Edges);
      Count : Natural := 0;
   end record;

   type Bounding_Box is record
      Min_X, Min_Y, Max_X, Max_Y : Real;
   end record;

   -- Exceptions for error handling
   Invalid_Data_Error : exception;
   Precision_Error    : exception;

   -----------------------------------------------------------------
   -- VARIANT 1: Standard Fortune's Algorithm (Infinite Edges)
   -----------------------------------------------------------------
   procedure Generate_Voronoi (Sites : in Point_Array; Result : out Edge_List);

   -----------------------------------------------------------------
   -- VARIANT 2: Bounded Voronoi (Truncates edges at Bounding Box)
   -----------------------------------------------------------------
   procedure Generate_Voronoi_Bounded 
     (Sites  : in Point_Array; 
      Box    : in Bounding_Box; 
      Result : out Edge_List);

   -----------------------------------------------------------------
   -- VARIANT 3: Additively Weighted Voronoi (Hyperbolic arcs)
   -----------------------------------------------------------------
   procedure Generate_Weighted_Voronoi 
     (Sites   : in Point_Array; 
      Weights : in Weight_Array; 
      Result  : out Edge_List);

   -- Helper and Validation Functions
   function Distance (P1, P2 : Point) return Real;
   function Circumcenter (P1, P2, P3 : Point; Center : out Point) return Boolean;

end Fortunes_Algorithm;
