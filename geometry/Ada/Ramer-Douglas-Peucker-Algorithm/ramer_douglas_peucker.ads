--  Package specification for the Ramer-Douglas-Peucker algorithm.
--  Implements cartesian point simplification in 2D space.

with Ada.Numerics.Generic_Elementary_Functions;

package Ramer_Douglas_Peucker is

   --  Domain types for coordinate geometry
   type Coordinate is new Long_Float;
   type Distance   is new Long_Float range 0.0 .. Long_Float'Last;

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Long_Float);

   type Point_2D is record
      X : Coordinate := 0.0;
      Y : Coordinate := 0.0;
   end record;

   type Point_Array is array (Positive range <>) of Point_2D;
   type Index_Array is array (Positive range <>) of Positive;
   type Boolean_Array is array (Positive range <>) of Boolean;

   --  Exceptions
   Invalid_Epsilon_Error : exception;
   Insufficient_Points   : exception;

   --  Geometry calculation helpers
   function Euclidean_Distance (P1, P2 : Point_2D) return Distance
     with Inline;

   function Perpendicular_Distance
     (P    : Point_2D;
      Line_Start : Point_2D;
      Line_End   : Point_2D) return Distance
     with Inline;

   --  Finds point in Slice with maximum perpendicular distance to the chord
   procedure Find_Maximum_Distance
     (Points       : Point_Array;
      First_Index  : Positive;
      Last_Index   : Positive;
      Max_Idx      : out Positive;
      Max_Dist     : out Distance)
     with
       Pre => First_Index <= Last_Index
              and then First_Index >= Points'First
              and then Last_Index <= Points'Last;

   --  Variant 1: Classic recursive Ramer-Douglas-Peucker algorithm.
   --  Returns a simplified Point_Array.
   function Simplify
     (Points  : Point_Array;
      Epsilon : Distance) return Point_Array
     with
       Pre => Epsilon >= 0.0,
       Post => Simplify'Result'Length >= (if Points'Length <= 2 then Points'Length else 2)
               and then Simplify'Result'Length <= Points'Length;

   --  Variant 2: Non-recursive / Iterative RDP algorithm using an explicit stack.
   --  Useful to eliminate recursion overhead and avoid stack exhaustion on long polylines.
   function Simplify_Iterative
     (Points  : Point_Array;
      Epsilon : Distance) return Point_Array
     with
       Pre => Epsilon >= 0.0,
       Post => Simplify_Iterative'Result'Length >= (if Points'Length <= 2 then Points'Length else 2)
               and then Simplify_Iterative'Result'Length <= Points'Length;

   --  Variant 3: Index-mask variant.
   --  Computes a boolean mask indicating which original points are retained.
   function Simplify_Mask
     (Points  : Point_Array;
      Epsilon : Distance) return Boolean_Array
     with
       Pre => Epsilon >= 0.0,
       Post => Simplify_Mask'Result'Length = Points'Length;

   --  Variant 4: Retained index list variant.
   --  Returns the exact array of original indices retained by the algorithm.
   function Simplify_Indices
     (Points  : Point_Array;
      Epsilon : Distance) return Index_Array
     with
       Pre => Epsilon >= 0.0,
       Post => Simplify_Indices'Result'Length >= (if Points'Length <= 2 then Points'Length else 2)
               and then Simplify_Indices'Result'Length <= Points'Length;

end Ramer_Douglas_Peucker;
