--  Fast_Clipping — Ada 2023 educational implementation of the
--  Sobkow–Pospisil–Yang "Fast clipping" 2-D line clipping algorithm
--  (line encoding). Endpoints are classified into the classic 9-region
--  Cohen–Sutherland grid; the pair of outcodes forms a line encoding.
--  A case / lookup on that encoding decides trivial Accept, trivial Reject,
--  or Need_Clip with suggested edges — aiming for fewer intersections than
--  iterative Cohen–Sutherland (which may revisit the same segment several
--  times). Based on Wikipedia "Line clipping" § Fast clipping and
--  Sobkow, Pospisil & Yang, Computers & Graphics 1987.
--  Related: Cohen–Sutherland, Liang–Barsky, Cyrus–Beck, Nicholl–Lee–Nicholl,
--  Skala, O(lg N).

pragma Ada_2022;

package Fast_Clipping
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

   --  Cohen–Sutherland style 4-bit region outcode (9 regions).
   --  Bit layout: Left=1, Right=2, Bottom=4, Top=8.
   type Out_Code is mod 16;

   Bit_Left   : constant Out_Code := 2#0001#;
   Bit_Right  : constant Out_Code := 2#0010#;
   Bit_Bottom : constant Out_Code := 2#0100#;
   Bit_Top    : constant Out_Code := 2#1000#;

   type Clip_Status is (Clip_Accept, Clip_Reject);

   type Clip_Result is record
      Status  : Clip_Status := Clip_Reject;
      Clipped : Segment := ((0.0, 0.0), (0.0, 0.0));
   end record;

   --  Which infinite edge line Clip_Against_Edge intersects.
   type Window_Edge is (Left_Edge, Right_Edge, Bottom_Edge, Top_Edge);

   --  Fast_Clip_Case outcome for a (code0, code1) pair.
   type Clip_Case_Kind is (Case_Accept, Case_Reject, Case_Need_Clip);

   type Fast_Clip_Decision is record
      Kind     : Clip_Case_Kind := Case_Reject;
      Edges_P0 : Out_Code := 0;  -- suggested edges to clip start against
      Edges_P1 : Out_Code := 0;  -- suggested edges to clip end against
   end record;

   --  Packed line encoding: high nibble = code0, low nibble = code1.
   type Line_Code is mod 256;

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

   function "-" (A, B : Vec2) return Vec2
     with Global => null;

   function "+" (A, B : Vec2) return Vec2
     with Global => null;

   function "*" (S : Real; V : Vec2) return Vec2
     with Global => null;

   function Dot (A, B : Vec2) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- 8. Make_Segment / Length / Point_Inside_Window / Same_Clipped_Segment
   ---------------------------------------------------------------------------

   function Make_Segment (P0, P1 : Vec2) return Segment
     with Post => Make_Segment'Result.P0 = P0
                  and then Make_Segment'Result.P1 = P1,
          Global => null;

   function Length (S : Segment) return Non_Negative
     with Global => null;

   function Point_Inside_Window
     (P : Vec2; W : Clip_Window) return Boolean
     with Pre => Is_Valid_Window (W), Global => null;
   --  Inclusive of the boundary (within Epsilon).

   function Same_Clipped_Segment
     (A, B : Segment; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True if A and B represent the same undirected clipped segment.

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

   ---------------------------------------------------------------------------
   -- 2. Region_Outcode / Classify_Point — 9-region CS-style outcodes
   ---------------------------------------------------------------------------

   function Region_Outcode
     (P : Vec2; W : Clip_Window) return Out_Code
     with Pre => Is_Valid_Window (W), Global => null;
   --  Left/Right/Bottom/Top bits; 0 means Inside.

   function Classify_Point
     (P : Vec2; W : Clip_Window) return Out_Code
     with Pre => Is_Valid_Window (W), Global => null;
   --  Alias of Region_Outcode (CS nine-region classification).

   function Encode_Line (Code0, Code1 : Out_Code) return Line_Code
     with Global => null;
   --  Pack (code0, code1) into an 8-bit line encoding (high/low nibble).

   ---------------------------------------------------------------------------
   -- 3. Fast_Clip_Case — Accept / Reject / Need_Clip + suggested edges
   ---------------------------------------------------------------------------

   function Fast_Clip_Case
     (Code0, Code1 : Out_Code) return Fast_Clip_Decision
     with Global => null;
   --  Trivial Accept when both codes are 0; Trivial Reject when they share
   --  a common outside bit; otherwise Need_Clip with Edges_P0=Code0 and
   --  Edges_P1=Code1 (the edges each endpoint should be clipped against).

   ---------------------------------------------------------------------------
   -- 5. Clip_Against_Edge — intersect segment with one window edge
   ---------------------------------------------------------------------------

   function Clip_Against_Edge
     (S : Segment; W : Clip_Window; Edge : Window_Edge) return Vec2
     with Pre => Is_Valid_Window (W), Global => null;
   --  Intersection of the infinite line through S with the infinite line of
   --  Edge. Raises Degenerate_Geometry when parallel / coincident to Edge.

   ---------------------------------------------------------------------------
   -- 4. Fast_Clip — main line clip using the fast case table / logic
   ---------------------------------------------------------------------------

   function Fast_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;
   --  Classify endpoints, Fast_Clip_Case dispatch, then clip against the
   --  suggested edges (no multi-pass region reclassification loop).

   ---------------------------------------------------------------------------
   -- 6. Cohen_Sutherland_Clip — in-package reference for tests
   ---------------------------------------------------------------------------

   function Cohen_Sutherland_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;
   --  Classic iterative outcode clip; used to verify Fast_Clip agreement.

   ---------------------------------------------------------------------------
   -- 7. Liang_Barsky_Clip_Lite — small parametric reference
   ---------------------------------------------------------------------------

   function Liang_Barsky_Clip_Lite
     (S : Segment; W : Clip_Window) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;
   --  Minimal parametric t_enter/t_leave clip for cross-checks.

end Fast_Clipping;
