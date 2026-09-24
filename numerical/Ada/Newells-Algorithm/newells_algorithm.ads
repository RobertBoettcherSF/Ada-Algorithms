--  Package specification for Newell's Algorithm (Newell-Newell-Sancha 1972)
--  3D Polygon Depth-Sorting for Hidden Surface Removal.
--  Compliant with Ada 2023 (ISO/IEC 8652:2023).

with Ada.Containers; use Ada.Containers;
with Ada.Containers.Indefinite_Vectors;

package Newells_Algorithm with
   SPARK_Mode => Off
is

   --  Exception raised when geometric data is degenerate or inconsistent
   Degenerate_Polygon_Error : exception;

   --  Exception raised when a cyclic overlap cannot be resolved or limit exceeded
   Cyclic_Overlap_Error : exception;

   --  Strongly-typed spatial coordinate scalar
   type Real is new Long_Float;

   --  A 3D spatial vertex (camera space where view direction is down the negative Z-axis,
   --  or viewer is located at +infinity looking toward -infinity).
   type Point_3D is record
      X : Real := 0.0;
      Y : Real := 0.0;
      Z : Real := 0.0;
   end record;

   --  Index range for polygon vertices
   type Vertex_Count is range 3 .. 64;

   --  Array of vertices representing a single planar polygon boundary
   type Vertex_Array is array (Positive range <>) of Point_3D;

   --  Axis-aligned 2D bounding box (Screen XY Projection)
   type Box_2D is record
      Min_X : Real := 0.0;
      Max_X : Real := 0.0;
      Min_Y : Real := 0.0;
      Max_Y : Real := 0.0;
   end record;

   --  Axis-aligned 1D depth interval
   type Depth_Range is record
      Min_Z : Real := 0.0;
      Max_Z : Real := 0.0;
   end record;

   --  Plane equation coefficients: A*X + B*Y + C*Z + D = 0
   type Plane_3D is record
      A : Real := 0.0;
      B : Real := 0.0;
      C : Real := 0.0;
      D : Real := 0.0;
   end record;

   --  Identifies individual polygons
   type Polygon_Id is new Natural;

   --  Internal polygon structure with cached geometric parameters
   type Polygon (Num_Vertices : Positive) is record
      Id          : Polygon_Id;
      Vertices    : Vertex_Array (1 .. Num_Vertices);
      Plane       : Plane_3D;
      Z_Bounds    : Depth_Range;
      XY_Bounds   : Box_2D;
   end record;

   --  A list/sequence of polygons
   package Polygon_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type   => Positive,
      Element_Type => Polygon);

   type Polygon_List is new Polygon_Vectors.Vector with null record;

   --  Cycle resolution strategy variant
   type Splitting_Policy is
     (Fail_On_Cycle,       -- Raise Cyclic_Overlap_Error upon cycle detection
      Bisect_Depth_Span);   -- Split along midpoint of Z span to break the cycle

   ----------------------------------------------------------------------------
   --  Helper & Calculation Functions
   ----------------------------------------------------------------------------

   --  Constructs and validates a Polygon from a vertex array
   function Make_Polygon
     (Id       : Polygon_Id;
      Vertices : Vertex_Array) return Polygon
   with
      Pre => Vertices'Length >= 3,
      Post => Make_Polygon'Result.Num_Vertices = Vertices'Length;

   --  Computes the axis-aligned screen-space bounding box
   function Compute_XY_Bounds (Vertices : Vertex_Array) return Box_2D
   with Pre => Vertices'Length >= 3;

   --  Computes the depth (Z) interval
   function Compute_Z_Bounds (Vertices : Vertex_Array) return Depth_Range
   with Pre => Vertices'Length >= 3;

   --  Calculates the plane equation A*x + B*y + C*z + D = 0 using Newell's method
   function Compute_Plane (Vertices : Vertex_Array) return Plane_3D
   with Pre => Vertices'Length >= 3;

   --  Evaluates signed distance to plane (unnormalized A*x + B*y + C*z + D)
   function Distance_To_Plane (Plane : Plane_3D; Pt : Point_3D) return Real;

   ----------------------------------------------------------------------------
   --  The Five Newell Ordering Tests
   --  Tests whether polygon P can be safely drawn BEFORE polygon Q
   --  (i.e. P is unambiguously behind Q or does not obstruct Q)
   ----------------------------------------------------------------------------

   --  Test 1: Do the Z depth extents not overlap (P completely behind Q)?
   function Test_1_Z_Disjoint (P, Q : Polygon) return Boolean;

   --  Test 2: Are the 2D bounding boxes in the XY projection disjoint?
   function Test_2_XY_Box_Disjoint (P, Q : Polygon) return Boolean;

   --  Test 3: Are all vertices of P completely on the far side of Q's plane?
   function Test_3_P_Behind_Plane_Of_Q (P, Q : Polygon) return Boolean;

   --  Test 4: Are all vertices of Q completely on the near side of P's plane?
   function Test_4_Q_In_Front_Plane_Of_P (P, Q : Polygon) return Boolean;

   --  Test 5: Do the 2D projections of P and Q have disjoint planar areas?
   function Test_5_2D_Polygons_Disjoint (P, Q : Polygon) return Boolean;

   --  Composite test: returns True if ANY of tests 1 through 5 succeed
   function Can_Draw_P_Before_Q (P, Q : Polygon) return Boolean;

   ----------------------------------------------------------------------------
   --  Algorithm Variants
   ----------------------------------------------------------------------------

   --  Standard non-preemptive Newell's depth sort.
   --  Sorts polygons back-to-front for Painter's Algorithm.
   --  Raises Cyclic_Overlap_Error if a mutual overlap cannot be ordered.
   procedure Sort_Polygons_Strict
     (Polygons : in out Polygon_List)
   with
      Post => Polygons.Length = Polygons.Length'Old;

   --  Adaptive Newell's algorithm with splitting policy.
   --  When a cycle is detected, subdivides the obstructing polygon to break
   --  the cyclic overlap loop.
   procedure Sort_Polygons_Adaptive
     (Polygons         : in out Polygon_List;
      Max_Splits       : Natural := 10;
      Splits_Performed : out Natural);

end Newells_Algorithm;
