package Boundary_Representation is
   pragma Preelaborate;

   -- Geometric coordinate type for strong typing
   type Coordinate is new Float;
   
   -- 3D Point representing the geometry of a vertex
   type Point_3D is record
      X, Y, Z : Coordinate;
   end record;

   -- Topological Identifiers
   type Vertex_ID is new Natural range 0 .. 1000;
   type Edge_ID   is new Natural range 0 .. 1000;
   type Face_ID   is new Natural range 0 .. 1000;

   Invalid_Vertex : constant Vertex_ID := 0;
   Invalid_Edge   : constant Edge_ID   := 0;
   Invalid_Face   : constant Face_ID   := 0;

   -- Array of edges representing the boundary loop of a face
   type Edge_Array is array (Positive range <>) of Edge_ID;

   -- Cyclic vertex sequence of a face, in traversal order
   type Vertex_Array is array (Positive range <>) of Vertex_ID;

   -- Named exceptions for specific B-rep errors
   Topology_Error   : exception;
   Capacity_Error   : exception;
   Invalid_ID_Error : exception;

   -- Core B-Rep Data Structure (Tagged private to enforce API use)
   type B_Rep_Model is private;

   -- Initializes an empty B-Rep model
   procedure Initialize (Model : out B_Rep_Model)
     with Global => null,
          Post   => Active_Vertices (Model) = 0 and then
                    Active_Edges (Model) = 0 and then
                    Active_Faces (Model) = 0;

   -- State queries
   function Active_Vertices (Model : B_Rep_Model) return Natural
     with Global => null;
     
   function Active_Edges (Model : B_Rep_Model) return Natural
     with Global => null;
     
   function Active_Faces (Model : B_Rep_Model) return Natural
     with Global => null;

   -- Core Topologic Builders
   function Make_Vertex (Model : in out B_Rep_Model; P : Point_3D) return Vertex_ID
     with Global => null,
          Pre    => Active_Vertices (Model) < 1000,
          Post   => Active_Vertices (Model) = Active_Vertices (Model'Old) + 1;

   function Make_Edge (Model : in out B_Rep_Model; V1, V2 : Vertex_ID) return Edge_ID
     with Global => null,
          Pre    => Active_Edges (Model) < 1000 and then V1 /= Invalid_Vertex and then V2 /= Invalid_Vertex,
          Post   => Active_Edges (Model) = Active_Edges (Model'Old) + 1;

   function Make_Face (Model : in out B_Rep_Model; Edges : Edge_Array) return Face_ID
     with Global => null,
          Pre    => Active_Faces (Model) < 1000,
          Post   => Active_Faces (Model) = Active_Faces (Model'Old) + 1;
   -- Edges are taken in traversal order. When they form one closed loop
   -- through distinct vertices (each edge sharing a vertex with the next,
   -- the last with the first; at least 3 edges), the face records that
   -- oriented vertex loop, starting at the vertex of Edges (First) not on
   -- the next edge. Otherwise the face has no loop (skeletal faces of the
   -- Euler operators, open chains), and Is_Valid_Manifold is False.

   function Make_Polygon_Face (Model : in out B_Rep_Model; Cycle : Vertex_Array) return Face_ID
     with Global => null,
          Pre    => Active_Faces (Model) < 1000
                    and then Cycle'Length in 3 .. 32,
          Post   => Active_Faces (Model) = Active_Faces (Model'Old) + 1;
   -- Face bounded by the oriented loop Cycle (First) -> ... -> Cycle (Last)
   -- -> Cycle (First). Each consecutive pair reuses an active edge between
   -- the two vertices (the lowest id) or gets a new one. Raises
   -- Invalid_ID_Error for an inactive vertex and Topology_Error for a
   -- repeated vertex.

   -- Variants & Validation (Euler-Poincaré Formula: V - E + F = 2 for single closed shell)
   function Euler_Poincare_Characteristic (Model : B_Rep_Model) return Integer
     with Global => null;

   -- Closed-solid check
   Max_Shells : constant := 1000;
   type Genus_Array is array (1 .. Max_Shells) of Natural;

   type Solid_Failure is
     (None,                 -- a closed orientable 2-manifold
      No_Faces,             -- the model has no face
      Face_Without_Loop,    -- a face has no closed vertex loop
      Dead_Reference,       -- a face uses an inactive edge or vertex
      Edge_Not_Two_Faces,   -- an active edge is not on exactly two faces
      Opposite_Orientation, -- two faces traverse an edge the same way
      Vertex_Not_One_Ring,  -- the faces at a vertex are not one ring
      Isolated_Vertex,      -- an active vertex is on no face
      Odd_Characteristic);  -- a shell has V - E + F odd or above 2

   type Solid_Report is record
      Failure : Solid_Failure := No_Faces;
      Shells  : Natural := 0;            -- edge-connected face sets
      Genus   : Genus_Array := [others => 0];
      -- Genus (S) for S in 1 .. Shells, shells ordered by lowest face
      -- id: V - E + F = 2 - 2 * Genus over that shell's elements.
   end record;

   function Check_Solid (Model : B_Rep_Model) return Solid_Report
     with Global => null;
   -- Classifies the model as a closed orientable 2-manifold surface:
   -- (1) every face has a closed loop of active vertices and edges;
   -- (2) every active edge lies on exactly two face loops, (3) which
   -- traverse it in opposite directions; (4) the faces around every
   -- active vertex form one closed ring (no isolated vertex). The first
   -- violated condition is reported. Then the shells (faces connected
   -- through shared edges) are counted and V - E + F = 2 - 2g gives each
   -- shell's genus g (failure Odd_Characteristic if no such g exists).

   function Is_Valid_Manifold (Model : B_Rep_Model) return Boolean
     with Global => null;
   -- True iff Check_Solid (Model).Failure = None: the model is a closed
   -- orientable 2-manifold surface of any genus and any number of
   -- shells. V - E + F = 2 alone is neither necessary (torus, several
   -- shells) nor sufficient (dangling edge, reversed face).

   -- Euler Operators (Maintain topological consistency)
   
   -- Make Vertex, Face, Shell (MVFS): Initializes a single point solid
   procedure Make_Vertex_Face_Shell 
     (Model : out B_Rep_Model; 
      P     : Point_3D; 
      V     : out Vertex_ID; 
      F     : out Face_ID)
     with Global => null;

   -- Make Edge, Vertex (MEV): Extends a new edge to a new vertex
   procedure Make_Edge_Vertex 
     (Model   : in out B_Rep_Model; 
      V_Start : Vertex_ID; 
      P_End   : Point_3D;
      V_End   : out Vertex_ID; 
      E       : out Edge_ID)
     with Global => null,
          Pre    => V_Start /= Invalid_Vertex and then Active_Vertices (Model) < 1000 and then Active_Edges (Model) < 1000;

   -- Make Edge, Face (MEF): Closes a loop by creating a face bounded by a new edge
   procedure Make_Edge_Face 
     (Model : in out B_Rep_Model; 
      V1    : Vertex_ID; 
      V2    : Vertex_ID;
      E     : out Edge_ID; 
      F_New : out Face_ID)
     with Global => null,
          Pre    => V1 /= Invalid_Vertex and then V2 /= Invalid_Vertex
                    and then Active_Edges (Model) < 1000 and then Active_Faces (Model) < 1000;

   -- Reverse Euler Operators
   -- Kill Edge, Vertex (KEV): Removes a vertex and its connected edge
   procedure Kill_Edge_Vertex (Model : in out B_Rep_Model; E : Edge_ID; V : Vertex_ID)
     with Global => null,
          Pre    => E /= Invalid_Edge and then V /= Invalid_Vertex;

   -- Kill Edge, Face (KEF): Removes a face and one of its bounding edges
   procedure Kill_Edge_Face (Model : in out B_Rep_Model; E : Edge_ID; F : Face_ID)
     with Global => null,
          Pre    => E /= Invalid_Edge and then F /= Invalid_Face;

   -- Geometric Queries
   function Get_Vertex_Point (Model : B_Rep_Model; V : Vertex_ID) return Point_3D
     with Global => null,
          Pre    => V /= Invalid_Vertex;

   function Are_Connected (Model : B_Rep_Model; V1, V2 : Vertex_ID) return Boolean
     with Global => null;

private
   Max_Items      : constant := 1000;
   Max_Face_Edges : constant := 32;

   type Element_State is (Free, Active);

   type Bounded_Edge_Array is record
      Elements : Edge_Array (1 .. Max_Face_Edges) := [others => Invalid_Edge];
      Count    : Natural := 0;
   end record;

   type Vertex_Rec is record
      State : Element_State := Free;
      Point : Point_3D := (0.0, 0.0, 0.0);
   end record;

   type Edge_Rec is record
      State  : Element_State := Free;
      V1, V2 : Vertex_ID := Invalid_Vertex;
   end record;

   type Face_Rec is record
      State    : Element_State := Free;
      Edges    : Bounded_Edge_Array;
      Cycle    : Vertex_Array (1 .. Max_Face_Edges) := [others => Invalid_Vertex];
      Cycle_Len : Natural := 0;  -- 0: no closed vertex loop
   end record;

   type Vertex_Storage is array (Vertex_ID range 1 .. Max_Items) of Vertex_Rec;
   type Edge_Storage   is array (Edge_ID range 1 .. Max_Items) of Edge_Rec;
   type Face_Storage   is array (Face_ID range 1 .. Max_Items) of Face_Rec;

   type B_Rep_Model is record
      Vertices     : Vertex_Storage;
      Edges        : Edge_Storage;
      Faces        : Face_Storage;
      Num_Vertices : Natural := 0;
      Num_Edges    : Natural := 0;
      Num_Faces    : Natural := 0;
      Edge_High    : Edge_ID := 0;  -- highest edge id ever allocated
   end record;

end Boundary_Representation;
