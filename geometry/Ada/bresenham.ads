package Bresenham with
   SPARK_Mode => On
is

   --  Coordinate system definitions.
   type Coordinate is range -1_000_000 .. 1_000_000;

   type Point is record
      X : Coordinate;
      Y : Coordinate;
   end record;

   type Point_Array is array (Positive range <>) of Point;

   --  Maximum capacity for line point buffers.
   Max_Points : constant := 2_000_001;

   subtype Point_Capacity is Natural range 0 .. Max_Points;

   type Point_List (Capacity : Point_Capacity) is record
      Length : Natural := 0;
      Points : Point_Array (1 .. Capacity);
   end record;

   --  Callback procedure signature for immediate-mode drawing.
   type Plot_Procedure is access procedure (P : Point);

   --  Validation helper functions.
   function Manhattan_Distance (P1, P2 : Point) return Natural is
     (Natural (abs (Long_Integer (P1.X) - Long_Integer (P2.X)) +
               abs (Long_Integer (P1.Y) - Long_Integer (P2.Y))));

   function Chebyshev_Distance (P1, P2 : Point) return Natural is
     (Natural'Max (Natural (abs (Long_Integer (P1.X) - Long_Integer (P2.X))),
                   Natural (abs (Long_Integer (P1.Y) - Long_Integer (P2.Y)))));

   function Expected_Line_Length (P1, P2 : Point) return Positive is
     (Chebyshev_Distance (P1, P2) + 1);

   function Is_Valid_Octant_0_Line (P1, P2 : Point) return Boolean is
     (P1.X <= P2.X and then
      P1.Y <= P2.Y and then
      (P2.X - P1.X) >= (P2.Y - P1.Y));

   --  Variant 1: Basic Bresenham algorithm restricted to the first octant
   --  (0 <= dy <= dx). Points collected into a Point_List buffer.
   procedure Line_Octant_0
     (P1     : Point;
      P2     : Point;
      Result : out Point_List)
   with
      Pre => Is_Valid_Octant_0_Line (P1, P2)
             and then Expected_Line_Length (P1, P2) <= Result.Capacity,
      Post => Result.Length = Expected_Line_Length (P1, P2)
              and then (Result.Length > 0 and then Result.Points (1) = P1)
              and then Result.Points (Result.Length) = P2;

   --  Variant 2: General all-octant Bresenham algorithm using integer
   --  decision variables (dx, dy, sx, sy). Returns points in Point_List.
   procedure Line_General
     (P1     : Point;
      P2     : Point;
      Result : out Point_List)
   with
      Pre => Expected_Line_Length (P1, P2) <= Result.Capacity,
      Post => Result.Length = Expected_Line_Length (P1, P2)
              and then (Result.Length > 0 and then Result.Points (1) = P1)
              and then Result.Points (Result.Length) = P2;

   --  Variant 3: General all-octant Bresenham with an immediate-mode callback,
   --  avoiding buffer allocation.
   procedure Line_General_Callback
     (P1   : Point;
      P2   : Point;
      Plot : Plot_Procedure);

   --  Variant 4: Thick line rasterization via parallel offsetting perpendicular
   --  to the principal direction of the line.
   type Thickness_Type is range 1 .. 256;

   procedure Line_Thick
     (P1        : Point;
      P2        : Point;
      Thickness : Thickness_Type;
      Result    : out Point_List)
   with
      Pre => (Expected_Line_Length (P1, P2) * Natural (Thickness)) <= Result.Capacity,
      Post => Result.Length = Expected_Line_Length (P1, P2) * Natural (Thickness);

end Bresenham;
