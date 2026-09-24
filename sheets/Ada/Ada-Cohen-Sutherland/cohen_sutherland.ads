--  Cohen_Sutherland — Ada 2023 educational implementation of the
--  Cohen–Sutherland 2-D (and lite 3-D) line clipping algorithm.
--  Divides the plane into 9 regions with 4-bit outcodes (TOP, BOTTOM,
--  RIGHT, LEFT). Trivial accept when OR of endpoint outcodes = 0;
--  trivial reject when AND ≠ 0; otherwise clip the outside endpoint
--  against a crossed edge, recompute the outcode, and loop.
--  Rectangular clip windows only; the 3-D lite variant uses 6-bit
--  outcodes against an axis-aligned box. Developed 1967 by Danny Cohen
--  and Ivan Sutherland during flight-simulator work.
--  Based on Wikipedia "Cohen–Sutherland algorithm" and
--  Newman & Sproull, Principles of Interactive Computer Graphics.
--  Related: Liang–Barsky, Cyrus–Beck, Nicholl–Lee–Nicholl, Fast clipping.

pragma Ada_2022;

package Cohen_Sutherland
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

   type Vec3 is record
      X, Y, Z : Real := 0.0;
   end record;

   subtype Point3 is Vec3;

   type Segment is record
      P0, P1 : Vec2 := (0.0, 0.0);
   end record;

   type Segment3 is record
      P0, P1 : Vec3 := (0.0, 0.0, 0.0);
   end record;

   type Clip_Window is record
      X_Min, Y_Min, X_Max, Y_Max : Real := 0.0;
   end record;

   --  Axis-aligned 3-D clip box for Cohen_Sutherland_Clip_3D_Lite.
   type Clip_Box is record
      X_Min, Y_Min, Z_Min : Real := 0.0;
      X_Max, Y_Max, Z_Max : Real := 0.0;
   end record;

   --  4-bit region outcode (9 regions). Layout: Left=1, Right=2, Bottom=4, Top=8.
   type Out_Code is mod 2**4;

   Bit_Left   : constant Out_Code := 2#0001#;
   Bit_Right  : constant Out_Code := 2#0010#;
   Bit_Bottom : constant Out_Code := 2#0100#;
   Bit_Top    : constant Out_Code := 2#1000#;

   --  6-bit outcode for 3-D (27 regions). Extra bits: Near=16, Far=32.
   type Out_Code_3D is mod 2**6;

   Bit3_Left   : constant Out_Code_3D := 2#000001#;
   Bit3_Right  : constant Out_Code_3D := 2#000010#;
   Bit3_Bottom : constant Out_Code_3D := 2#000100#;
   Bit3_Top    : constant Out_Code_3D := 2#001000#;
   Bit3_Near   : constant Out_Code_3D := 2#010000#;
   Bit3_Far    : constant Out_Code_3D := 2#100000#;

   type Clip_Status is (Clip_Accept, Clip_Reject);

   type Clip_Result is record
      Status  : Clip_Status := Clip_Reject;
      Clipped : Segment := ((0.0, 0.0), (0.0, 0.0));
   end record;

   type Clip_Result_3D is record
      Status  : Clip_Status := Clip_Reject;
      Clipped : Segment3 := ((0.0, 0.0, 0.0), (0.0, 0.0, 0.0));
   end record;

   --  Which infinite edge line Clip_Against_Edge intersects.
   type Window_Edge is (Left_Edge, Right_Edge, Bottom_Edge, Top_Edge);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;

   ---------------------------------------------------------------------------
   -- Numeric / vector helpers
   ---------------------------------------------------------------------------

   Epsilon : constant Real := 1.0E-5;

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Point (A, B : Vec2; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Point (A, B : Vec3; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function "-" (A, B : Vec2) return Vec2
     with Global => null;

   function "+" (A, B : Vec2) return Vec2
     with Global => null;

   function "*" (S : Real; V : Vec2) return Vec2
     with Global => null;

   function Dot (A, B : Vec2) return Real
     with Global => null;

   function "-" (A, B : Vec3) return Vec3
     with Global => null;

   function "+" (A, B : Vec3) return Vec3
     with Global => null;

   function "*" (S : Real; V : Vec3) return Vec3
     with Global => null;

   function Dot (A, B : Vec3) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- 8. Make_Segment / Length / Point_Inside_Window / Same_Clipped_Segment
   ---------------------------------------------------------------------------

   function Make_Segment (P0, P1 : Vec2) return Segment
     with Post => Make_Segment'Result.P0 = P0
                  and then Make_Segment'Result.P1 = P1,
          Global => null;

   function Make_Segment (P0, P1 : Vec3) return Segment3
     with Post => Make_Segment'Result.P0 = P0
                  and then Make_Segment'Result.P1 = P1,
          Global => null;

   function Length (S : Segment) return Non_Negative
     with Global => null;

   function Length (S : Segment3) return Non_Negative
     with Global => null;

   function Point_Inside_Window
     (P : Vec2; W : Clip_Window) return Boolean
     with Pre => Is_Valid_Window (W), Global => null;
   --  Inclusive of the boundary (within Epsilon).

   function Point_Inside_Box
     (P : Vec3; B : Clip_Box) return Boolean
     with Pre => Is_Valid_Box (B), Global => null;

   function Same_Clipped_Segment
     (A, B : Segment; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True if A and B represent the same undirected clipped segment.

   function Same_Clipped_Segment
     (A, B : Segment3; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- 1. Clip_Window: Make_Window / Is_Valid_Window
   ---------------------------------------------------------------------------

   function Make_Window
     (X_Min, Y_Min, X_Max, Y_Max : Real) return Clip_Window
     with Pre    => X_Max > X_Min and then Y_Max > Y_Min,
          Post   => Is_Valid_Window (Make_Window'Result),
          Global => null;

   function Is_Valid_Window (W : Clip_Window) return Boolean
     with Global => null;
   --  True when X_Max > X_Min and Y_Max > Y_Min.

   function Make_Box
     (X_Min, Y_Min, Z_Min, X_Max, Y_Max, Z_Max : Real) return Clip_Box
     with Pre    => X_Max > X_Min
                    and then Y_Max > Y_Min
                    and then Z_Max > Z_Min,
          Post   => Is_Valid_Box (Make_Box'Result),
          Global => null;

   function Is_Valid_Box (B : Clip_Box) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- 2. Compute_OutCode — 9-region CS-style outcodes
   ---------------------------------------------------------------------------

   function Compute_OutCode
     (P : Vec2; W : Clip_Window) return Out_Code
     with Pre => Is_Valid_Window (W), Global => null;
   --  Left/Right/Bottom/Top bits; 0 means Inside.

   function Compute_OutCode
     (P : Vec3; B : Clip_Box) return Out_Code_3D
     with Pre => Is_Valid_Box (B), Global => null;
   --  6-bit outcode: Left/Right/Bottom/Top/Near/Far.

   ---------------------------------------------------------------------------
   -- 5. Trivial_Accept / Trivial_Reject
   ---------------------------------------------------------------------------

   function Trivial_Accept (Code0, Code1 : Out_Code) return Boolean
     with Global => null;
   --  True when (Code0 or Code1) = 0 — both endpoints inside.

   function Trivial_Reject (Code0, Code1 : Out_Code) return Boolean
     with Global => null;
   --  True when (Code0 and Code1) /= 0 — share an outside half-plane.

   function Trivial_Accept (Code0, Code1 : Out_Code_3D) return Boolean
     with Global => null;

   function Trivial_Reject (Code0, Code1 : Out_Code_3D) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- 4. Clip_Against_Edge — intersect segment with one window edge
   ---------------------------------------------------------------------------

   function Clip_Against_Edge
     (S : Segment; W : Clip_Window; Edge : Window_Edge) return Vec2
     with Pre => Is_Valid_Window (W), Global => null;
   --  Intersection of the infinite line through S with the infinite line of
   --  Edge. Raises Degenerate_Geometry when parallel / coincident to Edge.

   ---------------------------------------------------------------------------
   -- 3. Cohen_Sutherland_Clip — classic iterative 2-D clip
   ---------------------------------------------------------------------------

   function Cohen_Sutherland_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;
   --  Classic outcode loop: trivial accept/reject, else clip outside
   --  endpoint against a crossed edge and recompute.

   ---------------------------------------------------------------------------
   -- 6. Cohen_Sutherland_Clip_3D_Lite — 6-bit outcode vs AABB
   ---------------------------------------------------------------------------

   function Cohen_Sutherland_Clip_3D_Lite
     (S : Segment3; B : Clip_Box) return Clip_Result_3D
     with Pre => Is_Valid_Box (B), Global => null;
   --  Educational 3-D extension: same accept/reject logic with six planes.

   ---------------------------------------------------------------------------
   -- 7. Liang_Barsky_Clip_Lite — parametric reference for 2-D cross-checks
   ---------------------------------------------------------------------------

   function Liang_Barsky_Clip_Lite
     (S : Segment; W : Clip_Window) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;
   --  Minimal parametric t_enter/t_leave clip for agreement tests.

end Cohen_Sutherland;
