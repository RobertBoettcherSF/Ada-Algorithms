--  Line_Clipping — Ada 2023 educational survey of 2-D line clipping.
--  Comparative umbrella package for the Wikipedia "Line clipping" topic:
--  embed Cohen–Sutherland, Liang–Barsky, Midpoint Subdivision, and a
--  Skala-inspired lite clipper against an axis-aligned rectangular window.
--  Dedicated sibling repos treat individual algorithms in more depth.
--  Based on Wikipedia "Line clipping" and classic textbooks
--  (Newman & Sproull; Foley / van Dam; Hearn & Baker).
--  Related: Cohen–Sutherland, Liang–Barsky, Cyrus–Beck,
--  Nicholl–Lee–Nicholl, Fast clipping, Skala.

pragma Ada_2022;

package Line_Clipping
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 6;

   subtype Non_Negative is Real range 0.0 .. Real'Last;

   type Vec2 is record
      X, Y : Real := 0.0;
   end record;

   subtype Point2 is Vec2;

   type Segment is record
      P0, P1 : Vec2 := (0.0, 0.0);
   end record;

   type Clip_Window is record
      X_Min, Y_Min, X_Max, Y_Max : Real := 0.0;
   end record;

   type Clip_Status is (Clip_Accept, Clip_Reject);

   type Clip_Result is record
      Status  : Clip_Status := Clip_Reject;
      Clipped : Segment := ((0.0, 0.0), (0.0, 0.0));
   end record;

   --  Survey dispatch: which embedded algorithm Clip_With / Compare use.
   type Algorithm_Kind is
     (Cohen_Sutherland,
      Liang_Barsky,
      Midpoint_Subdivision,
      Skala_Lite);

   --  Result of Compare_Algorithms: both clip results plus agreement flag.
   type Agreement_Report is record
      Left, Right       : Clip_Result;
      Same_Status       : Boolean := False;
      Same_Clipped_Seg  : Boolean := False;
      Agree             : Boolean := False;
   end record;

   --  4-bit region outcode (Cohen–Sutherland / Midpoint / Skala-lite).
   type Out_Code is mod 2**4;

   Bit_Left   : constant Out_Code := 2#0001#;
   Bit_Right  : constant Out_Code := 2#0010#;
   Bit_Bottom : constant Out_Code := 2#0100#;
   Bit_Top    : constant Out_Code := 2#1000#;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;

   ---------------------------------------------------------------------------
   -- Numeric / vector helpers
   ---------------------------------------------------------------------------

   Epsilon : constant Real := 1.0E-5;

   --  Default stop length for Midpoint_Subdivision_Clip binary search.
   Midpoint_Epsilon : constant Real := 1.0E-4;

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Point (A, B : Vec2; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function "-" (A, B : Vec2) return Vec2
     with Global => null;

   function "+" (A, B : Vec2) return Vec2
     with Global => null;

   function "*" (S : Real; V : Vec2) return Vec2
     with Global => null;

   function Dot (A, B : Vec2) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- 9. Make_Segment / Length / Same_Clipped_Segment
   ---------------------------------------------------------------------------

   function Make_Segment (P0, P1 : Vec2) return Segment
     with Post => Make_Segment'Result.P0 = P0
                  and then Make_Segment'Result.P1 = P1,
          Global => null;

   function Length (S : Segment) return Non_Negative
     with Global => null;

   function Same_Clipped_Segment
     (A, B : Segment; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True if A and B represent the same undirected clipped segment.

   ---------------------------------------------------------------------------
   -- 1. Clip_Window / Make_Window / Point_Inside_Window
   ---------------------------------------------------------------------------

   function Make_Window
     (X_Min, Y_Min, X_Max, Y_Max : Real) return Clip_Window
     with Pre    => X_Max > X_Min and then Y_Max > Y_Min,
          Post   => Is_Valid_Window (Make_Window'Result),
          Global => null;

   function Is_Valid_Window (W : Clip_Window) return Boolean
     with Global => null;
   --  True when X_Max > X_Min and Y_Max > Y_Min.

   function Point_Inside_Window
     (P : Vec2; W : Clip_Window) return Boolean
     with Pre => Is_Valid_Window (W), Global => null;
   --  Inclusive of the boundary (within Epsilon).

   ---------------------------------------------------------------------------
   -- Outcodes (shared by CS / Midpoint / Skala-lite)
   ---------------------------------------------------------------------------

   function Compute_OutCode
     (P : Vec2; W : Clip_Window) return Out_Code
     with Pre => Is_Valid_Window (W), Global => null;

   function Trivial_Accept (Code0, Code1 : Out_Code) return Boolean
     with Global => null;

   function Trivial_Reject (Code0, Code1 : Out_Code) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- 4. Cohen_Sutherland_Clip — embedded classic outcode loop
   ---------------------------------------------------------------------------

   function Cohen_Sutherland_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;

   ---------------------------------------------------------------------------
   -- 5. Liang_Barsky_Clip — embedded parametric clip
   ---------------------------------------------------------------------------

   function Liang_Barsky_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;

   ---------------------------------------------------------------------------
   -- 6. Midpoint_Subdivision_Clip — textbook binary-search clip
   ---------------------------------------------------------------------------

   function Midpoint_Subdivision_Clip
     (S          : Segment;
      W          : Clip_Window;
      Stop_Eps   : Real := Midpoint_Epsilon) return Clip_Result
     with Pre => Is_Valid_Window (W) and then Stop_Eps > 0.0,
          Global => null;
   --  Recursive midpoint subdivision until each candidate is shorter than
   --  Stop_Eps or trivially accepted/rejected (classic CS companion).

   ---------------------------------------------------------------------------
   -- 7. Skala_Clip_Lite — Skala-inspired region / edge encoding
   ---------------------------------------------------------------------------

   function Skala_Clip_Lite
     (S : Segment; W : Clip_Window) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;
   --  Educational approximate of Skala's encoding-based clip for a
   --  rectangular window: classify the four corners against the line
   --  ax+by+c=0, identify crossed edges, compute intersections, then
   --  retain the [0,1] parameter interval inside W.
   --  Limits: axis-aligned rectangle only; not the full homogeneous /
   --  duality method for arbitrary convex polygons (see Ada-Skala siblings
   --  / literature for the complete algorithm).

   ---------------------------------------------------------------------------
   -- 3. Clip_With — dispatch by Algorithm_Kind
   ---------------------------------------------------------------------------

   function Clip_With
     (S : Segment; W : Clip_Window; Kind : Algorithm_Kind) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;

   ---------------------------------------------------------------------------
   -- 8. Compare_Algorithms — agreement report
   ---------------------------------------------------------------------------

   function Compare_Algorithms
     (S          : Segment;
      W          : Clip_Window;
      Left_Kind  : Algorithm_Kind;
      Right_Kind : Algorithm_Kind;
      Tol        : Real := Epsilon) return Agreement_Report
     with Pre => Is_Valid_Window (W) and then Tol >= 0.0,
          Global => null;
   --  Runs both algorithms; Agree is True when statuses match and, if both
   --  accept, Same_Clipped_Segment holds within Tol.

end Line_Clipping;
