package Constructive_Solid_Geometry is

   -- Constructive Solid Geometry (CSG) is a modeling technique that uses Boolean 
   -- operations to combine simpler solid primitives into complex objects.
   -- This package implements the core CSG algorithm via Signed Distance Fields (SDF).

   type Real is new Float;

   type Point_3D is record
      X, Y, Z : Real;
   end record;

   subtype Non_Negative_Real is Real range 0.0 .. Real'Last;

   -- The supported CSG variants (primitives and Boolean operations)
   type Shape_Kind is 
     (Sphere_Shape, 
      Box_Shape, 
      Union_Shape, 
      Intersection_Shape, 
      Difference_Shape);

   type CSG_Node (Kind : Shape_Kind) is private;
   type CSG_Tree is access all CSG_Node;

   Invalid_Bounds_Error : exception;
   Null_Tree_Error      : exception;

   -- =========================================================================
   -- Primitives (CSG Leaf Nodes)
   -- =========================================================================

   function Create_Sphere (Center : Point_3D; Radius : Non_Negative_Real) return CSG_Tree
     with Post => Create_Sphere'Result /= null;

   function Create_Box (Min_Bounds, Max_Bounds : Point_3D) return CSG_Tree
     with Pre => Min_Bounds.X <= Max_Bounds.X and then
                 Min_Bounds.Y <= Max_Bounds.Y and then
                 Min_Bounds.Z <= Max_Bounds.Z,
          Post => Create_Box'Result /= null;

   -- =========================================================================
   -- Operations (CSG Internal Nodes)
   -- =========================================================================

   -- Union: combines two solids into one
   function Union_Op (Left, Right : CSG_Tree) return CSG_Tree
     with Pre => Left /= null and Right /= null,
          Post => Union_Op'Result /= null;

   -- Intersection: retains only the overlapping volume of two solids
   function Intersection_Op (Left, Right : CSG_Tree) return CSG_Tree
     with Pre => Left /= null and Right /= null,
          Post => Intersection_Op'Result /= null;

   -- Difference: subtracts the Right solid from the Left solid
   function Difference_Op (Left, Right : CSG_Tree) return CSG_Tree
     with Pre => Left /= null and Right /= null,
          Post => Difference_Op'Result /= null;

   -- =========================================================================
   -- Evaluation and Queries
   -- =========================================================================

   -- Evaluates the Signed Distance Field (SDF) of the CSG tree at a given point.
   -- Returns <= 0.0 if the point is inside or on the surface of the solid.
   function Evaluate_SDF (Tree : CSG_Tree; Point : Point_3D) return Real
     with Pre => Tree /= null;

   -- Returns True if the solid described by the CSG tree contains the point.
   function Contains (Tree : CSG_Tree; Point : Point_3D) return Boolean
     with Pre => Tree /= null;

   -- =========================================================================
   -- Memory Management
   -- =========================================================================

   -- Recursively destroys the CSG tree and deallocates memory.
   procedure Destroy_Tree (Tree : in out CSG_Tree)
     with Post => Tree = null;

private

   -- Variant record representing either a primitive or a Boolean operation
   type CSG_Node (Kind : Shape_Kind) is record
      case Kind is
         when Sphere_Shape =>
            Center : Point_3D;
            Radius : Non_Negative_Real;
         when Box_Shape =>
            Min_Bounds : Point_3D;
            Max_Bounds : Point_3D;
         when Union_Shape | Intersection_Shape | Difference_Shape =>
            Left  : CSG_Tree;
            Right : CSG_Tree;
      end case;
   end record;

end Constructive_Solid_Geometry;
