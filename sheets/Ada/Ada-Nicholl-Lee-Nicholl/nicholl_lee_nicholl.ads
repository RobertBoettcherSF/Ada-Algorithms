--  Nicholl_Lee_Nicholl — Ada 2023 educational implementation of the
--  Nicholl–Lee–Nicholl (NLN) 2-D line clipping algorithm.
--  Clips a line segment against an axis-aligned rectangular window by
--  classifying the first endpoint into a small set of canonical regions
--  (Inside / Left / Left_Top), using reflections / a 90° remap when needed,
--  then determining at most one or two clip edges via corner-ray regions
--  (L, LT, LB, TR, …). This reduces repeated intersection work compared
--  with Cohen–Sutherland.
--  Based on Wikipedia "Nicholl–Lee–Nicholl algorithm" and
--  Nicholl, Lee & Nicholl, SIGGRAPH 1987.
--  Related: Liang–Barsky, Cyrus–Beck, Fast clipping, Cohen–Sutherland.
--  Spelling note: some spreadsheets / course notes write "Nicoll"; the
--  published authors are Tina M. Nicholl and Robin A. Nicholl.

pragma Ada_2022;

package Nicholl_Lee_Nicholl
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

   --  Nine-region classification relative to an axis-aligned window
   --  (NLN-style families, richer than bare CS outcodes).
   type Region_Kind is
     (Inside,
      Left, Right, Bottom, Top,
      Left_Bottom, Left_Top, Right_Bottom, Right_Top);

   subtype Region_Code is Region_Kind;

   type Clip_Status is (Clip_Accept, Clip_Reject);

   type Clip_Result is record
      Status  : Clip_Status := Clip_Reject;
      Clipped : Segment := ((0.0, 0.0), (0.0, 0.0));
   end record;

   --  Which window edges a clip may strike (for Intersection_With_Edge).
   type Window_Edge is (Left_Edge, Right_Edge, Bottom_Edge, Top_Edge);

   --  Metadata to undo Canonicalize_Segment (reflections + optional 90° remap).
   type Canonical_Transform is record
      Flip_X : Boolean := False;
      Flip_Y : Boolean := False;
      Rot90  : Boolean := False;
      --  When Rot90, clipping uses a translated / remapped window:
      --  Origin_X/Y = original lower-left; Old_W/Old_H = original size.
      Origin_X, Origin_Y : Real := 0.0;
      Old_W, Old_H       : Real := 0.0;
   end record;

   type Canonical_Family is (Canon_Inside, Canon_Left, Canon_Left_Top);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Not_Canonical       : exception;

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

   function Cross_Z (A, B : Vec2) return Real
     with Global => null;
   --  2-D cross product magnitude: Ax*By − Ay*Bx.

   ---------------------------------------------------------------------------
   -- 8. Make_Segment / Length / Point_Inside_Window
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
   -- 2. Region_Code / Classify_Point (NLN-style nine regions)
   ---------------------------------------------------------------------------

   function Classify_Point
     (P : Vec2; W : Clip_Window) return Region_Kind
     with Pre => Is_Valid_Window (W), Global => null;

   function Region_Is_Corner (R : Region_Kind) return Boolean
     with Global => null;

   function Region_Is_Edge (R : Region_Kind) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- 7. Intersection_With_Edge
   ---------------------------------------------------------------------------

   function Intersection_With_Edge
     (S : Segment; W : Clip_Window; Edge : Window_Edge) return Vec2
     with Pre => Is_Valid_Window (W), Global => null;
   --  Intersection of infinite line through S with the infinite line of Edge.
   --  Raises Degenerate_Geometry when parallel / coincident to that edge.

   ---------------------------------------------------------------------------
   -- 3. Canonicalize_Segment
   ---------------------------------------------------------------------------

   procedure Canonicalize_Segment
     (S           : Segment;
      W           : Clip_Window;
      S_Out       : out Segment;
      W_Out       : out Clip_Window;
      Transform   : out Canonical_Transform;
      Family      : out Canonical_Family)
     with Pre => Is_Valid_Window (W), Global => null;
   --  Reflect / remap so S_Out.P0 lies in Inside, Left, or Left_Top relative
   --  to W_Out. Transform undoes the mapping (Apply_Inverse_Transform).

   function Apply_Inverse_Transform
     (P : Vec2; T : Canonical_Transform; W_Original : Clip_Window) return Vec2
     with Pre => Is_Valid_Window (W_Original), Global => null;

   function Apply_Inverse_Segment
     (S : Segment; T : Canonical_Transform; W_Original : Clip_Window)
      return Segment
     with Pre => Is_Valid_Window (W_Original), Global => null;

   ---------------------------------------------------------------------------
   -- 5. Clip_Without_Canonicalize — P0 already in a canonical family
   ---------------------------------------------------------------------------

   function Clip_Without_Canonicalize
     (S : Segment; W : Clip_Window) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;
   --  Educational direct case table when Classify_Point (S.P0, W) is
   --  Inside, Left, or Left_Top. Raises Not_Canonical otherwise.

   ---------------------------------------------------------------------------
   -- 4. Nicholl_Lee_Nicholl_Clip — main entry
   ---------------------------------------------------------------------------

   function Nicholl_Lee_Nicholl_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;
   --  Canonicalize, clip, inverse-transform. Accept ⇒ Clipped is inside W.

   ---------------------------------------------------------------------------
   -- 6. Cohen_Sutherland_Clip — in-package reference for tests
   ---------------------------------------------------------------------------

   function Cohen_Sutherland_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;
   --  Classic outcode clip; used to verify NLN agreement on fixtures / random.

   function Same_Clipped_Segment
     (A, B : Segment; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True if A and B represent the same undirected clipped segment.

end Nicholl_Lee_Nicholl;
