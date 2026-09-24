with Ada.Containers.Vectors;

package Generalised_Hough_Transform is

   -- Strong typing for algorithm-specific data
   type Coordinate is new Float;
   type Angle_Radian is new Float;
   type Angle_Degree is mod 360;
   type Scale_Factor is new Float;
   
   type Point is record
      X : Coordinate;
      Y : Coordinate;
   end record;

   type Edge_Point is record
      Location           : Point;
      Gradient_Direction : Angle_Radian; -- Direction in radians [0, 2pi)
   end record;

   type Edge_Point_Array is array (Positive range <>) of Edge_Point;
   type Scale_Array is array (Positive range <>) of Scale_Factor;
   type Rotation_Array is array (Positive range <>) of Angle_Radian;

   -- R-Table entry structure
   type R_Table_Entry is record
      Radius : Coordinate;
      Alpha  : Angle_Radian; -- Angle from reference point to edge point
   end record;

   package R_Table_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => R_Table_Entry);

   -- R-Table maps discretized gradient angles (0..359) to a list of vectors
   type R_Table_Array is array (Angle_Degree) of R_Table_Vectors.Vector;
   type R_Table is record
      Entries : R_Table_Array;
   end record;

   -- Output structures
   type Detection_Result is record
      Reference_Point : Point;
      Votes           : Natural;
      Scale           : Scale_Factor;
      Rotation        : Angle_Radian;
   end record;

   -- Exceptions for edge cases
   Invalid_Data_Error : exception;
   Invalid_Bounds_Error : exception;

   -----------------------------------------------------------------------------
   -- Core Subprograms
   -----------------------------------------------------------------------------

   -- 1. Build the R-Table from a template shape
   function Build_R_Table
     (Template_Edges  : Edge_Point_Array;
      Reference_Point : Point) return R_Table;

   -- 2. Standard GHT (Translation only)
   function Detect_Translation
     (Target_Edges : Edge_Point_Array;
      Table        : R_Table;
      Min_X, Max_X : Integer;
      Min_Y, Max_Y : Integer) return Detection_Result;

   -- 3. Extended GHT (Translation, Scaling, and Rotation)
   function Detect_Extended
     (Target_Edges : Edge_Point_Array;
      Table        : R_Table;
      Min_X, Max_X : Integer;
      Min_Y, Max_Y : Integer;
      Scales       : Scale_Array;
      Rotations    : Rotation_Array) return Detection_Result;

end Generalised_Hough_Transform;
