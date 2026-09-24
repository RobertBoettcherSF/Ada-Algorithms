with Ada.Unchecked_Deallocation;
with Ada.Numerics.Generic_Elementary_Functions;

package body Constructive_Solid_Geometry is

   -- Math utilities for Signed Distance Field calculations
   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   procedure Free is new Ada.Unchecked_Deallocation (Object => CSG_Node, Name => CSG_Tree);

   function Max (A, B : Real) return Real is (if A > B then A else B);
   function Min (A, B : Real) return Real is (if A < B then A else B);

   -- =========================================================================
   -- Primitives
   -- =========================================================================

   function Create_Sphere (Center : Point_3D; Radius : Non_Negative_Real) return CSG_Tree is
   begin
      return new CSG_Node'(Kind => Sphere_Shape, Center => Center, Radius => Radius);
   end Create_Sphere;

   function Create_Box (Min_Bounds, Max_Bounds : Point_3D) return CSG_Tree is
   begin
      -- Dynamic check to ensure correctness even if preconditions are disabled
      if Min_Bounds.X > Max_Bounds.X or else
         Min_Bounds.Y > Max_Bounds.Y or else
         Min_Bounds.Z > Max_Bounds.Z
      then
         raise Invalid_Bounds_Error with "Box Min_Bounds must be <= Max_Bounds";
      end if;
      return new CSG_Node'(Kind => Box_Shape, Min_Bounds => Min_Bounds, Max_Bounds => Max_Bounds);
   end Create_Box;

   -- =========================================================================
   -- Operations
   -- =========================================================================

   function Union_Op (Left, Right : CSG_Tree) return CSG_Tree is
   begin
      if Left = null or else Right = null then
         raise Null_Tree_Error with "Union operands cannot be null";
      end if;
      return new CSG_Node'(Kind => Union_Shape, Left => Left, Right => Right);
   end Union_Op;

   function Intersection_Op (Left, Right : CSG_Tree) return CSG_Tree is
   begin
      if Left = null or else Right = null then
         raise Null_Tree_Error with "Intersection operands cannot be null";
      end if;
      return new CSG_Node'(Kind => Intersection_Shape, Left => Left, Right => Right);
   end Intersection_Op;

   function Difference_Op (Left, Right : CSG_Tree) return CSG_Tree is
   begin
      if Left = null or else Right = null then
         raise Null_Tree_Error with "Difference operands cannot be null";
      end if;
      return new CSG_Node'(Kind => Difference_Shape, Left => Left, Right => Right);
   end Difference_Op;

   -- =========================================================================
   -- Evaluation
   -- =========================================================================

   function Evaluate_SDF (Tree : CSG_Tree; Point : Point_3D) return Real is
   begin
      if Tree = null then
         raise Null_Tree_Error with "Cannot evaluate SDF of a null tree";
      end if;

      case Tree.Kind is
         when Sphere_Shape =>
            declare
               DX : constant Real := Point.X - Tree.Center.X;
               DY : constant Real := Point.Y - Tree.Center.Y;
               DZ : constant Real := Point.Z - Tree.Center.Z;
               Dist : constant Real := Sqrt (DX * DX + DY * DY + DZ * DZ);
            begin
               -- SDF of sphere: distance to center minus radius
               return Dist - Tree.Radius;
            end;

         when Box_Shape =>
            declare
               -- Center of the box
               CX : constant Real := (Tree.Max_Bounds.X + Tree.Min_Bounds.X) * 0.5;
               CY : constant Real := (Tree.Max_Bounds.Y + Tree.Min_Bounds.Y) * 0.5;
               CZ : constant Real := (Tree.Max_Bounds.Z + Tree.Min_Bounds.Z) * 0.5;

               -- Half extents
               HX : constant Real := (Tree.Max_Bounds.X - Tree.Min_Bounds.X) * 0.5;
               HY : constant Real := (Tree.Max_Bounds.Y - Tree.Min_Bounds.Y) * 0.5;
               HZ : constant Real := (Tree.Max_Bounds.Z - Tree.Min_Bounds.Z) * 0.5;

               -- Distance from center projected into the positive quadrant
               PX : constant Real := abs (Point.X - CX) - HX;
               PY : constant Real := abs (Point.Y - CY) - HY;
               PZ : constant Real := abs (Point.Z - CZ) - HZ;

               -- Exterior distance
               Out_X : constant Real := Max (PX, 0.0);
               Out_Y : constant Real := Max (PY, 0.0);
               Out_Z : constant Real := Max (PZ, 0.0);
               Out_Dist : constant Real := Sqrt (Out_X * Out_X + Out_Y * Out_Y + Out_Z * Out_Z);

               -- Interior distance
               In_Dist : constant Real := Min (Max (PX, Max (PY, PZ)), 0.0);
            begin
               return Out_Dist + In_Dist;
            end;

         when Union_Shape =>
            -- Minimum of distances
            return Min (Evaluate_SDF (Tree.Left, Point), Evaluate_SDF (Tree.Right, Point));

         when Intersection_Shape =>
            -- Maximum of distances
            return Max (Evaluate_SDF (Tree.Left, Point), Evaluate_SDF (Tree.Right, Point));

         when Difference_Shape =>
            -- Maximum of Left distance and negative Right distance
            return Max (Evaluate_SDF (Tree.Left, Point), -Evaluate_SDF (Tree.Right, Point));
      end case;
   end Evaluate_SDF;

   function Contains (Tree : CSG_Tree; Point : Point_3D) return Boolean is
   begin
      return Evaluate_SDF (Tree, Point) <= 0.0;
   end Contains;

   -- =========================================================================
   -- Memory Management
   -- =========================================================================

   procedure Destroy_Tree (Tree : in out CSG_Tree) is
   begin
      if Tree /= null then
         case Tree.Kind is
            when Union_Shape | Intersection_Shape | Difference_Shape =>
               Destroy_Tree (Tree.Left);
               Destroy_Tree (Tree.Right);
            when others =>
               null;
         end case;
         Free (Tree);
      end if;
   end Destroy_Tree;

end Constructive_Solid_Geometry;
