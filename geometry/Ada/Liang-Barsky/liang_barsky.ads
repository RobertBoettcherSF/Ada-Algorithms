--  Liang_Barsky — Ada 2023 educational implementation of the
--  Liang–Barsky 2-D line clipping algorithm.
--  Clips a line segment against an axis-aligned rectangular window using the
--  parametric form x = x0 + t Δx, y = y0 + t Δy and the four inequalities
--  t p_i ≤ q_i (left / right / bottom / top). Entering (p < 0) and leaving
--  (p > 0) parameters yield t_enter = max(0, …) and t_leave = min(1, …);
--  parallel edges (p = 0) are rejected when q < 0. More efficient than
--  Cohen–Sutherland by testing before computing intersections.
--  Based on Wikipedia "Liang–Barsky algorithm" and
--  Liang & Barsky, ACM TOG 1984.
--  Related: Nicholl–Lee–Nicholl, Cyrus–Beck, Cohen–Sutherland.

pragma Ada_2022;

package Liang_Barsky
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 6;

   subtype Non_Negative is Real range 0.0 .. Real'Last;

   --  Parametric line parameter on the closed unit interval.
   subtype Parameter is Real range 0.0 .. 1.0;

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

   --  p[1..4], q[1..4] for left / right / bottom / top (Liang–Barsky order).
   type Boundary_Index is range 1 .. 4;

   type PQ_Array is array (Boundary_Index) of Real;

   type PQ_Values is record
      P, Q : PQ_Array := [others => 0.0];
   end record;

   --  Result of Clip_Parameters: accept/reject plus [T_Enter, T_Leave].
   type Parameter_Result is record
      Accepted : Boolean   := False;
      T_Enter  : Parameter := 0.0;
      T_Leave  : Parameter := 1.0;
   end record;

   --  Clip plus retained parametric bounds (for Liang_Barsky_Clip_Params).
   type Clip_Params_Result is record
      Status  : Clip_Status := Clip_Reject;
      Clipped : Segment := ((0.0, 0.0), (0.0, 0.0));
      T0, T1  : Parameter := 0.0;
   end record;

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
   -- 2. Compute_PQ — p_i / q_i for left, right, bottom, top
   ---------------------------------------------------------------------------

   function Compute_PQ
     (S : Segment; W : Clip_Window) return PQ_Values
     with Pre => Is_Valid_Window (W), Global => null;
   --  p1=-Δx,q1=x0-xmin (left); p2=Δx,q2=xmax-x0 (right);
   --  p3=-Δy,q3=y0-ymin (bottom); p4=Δy,q4=ymax-y0 (top).

   ---------------------------------------------------------------------------
   -- 3. Clip_Parameters — t_enter / t_leave (or reject)
   ---------------------------------------------------------------------------

   function Clip_Parameters
     (S : Segment; W : Clip_Window) return Parameter_Result
     with Pre => Is_Valid_Window (W), Global => null;
   --  Accepted ⇒ 0 ≤ T_Enter ≤ T_Leave ≤ 1; Rejected otherwise.

   ---------------------------------------------------------------------------
   -- 6. Point_At_Parameter — (x0,y0) + t (Δx,Δy)
   ---------------------------------------------------------------------------

   function Point_At_Parameter
     (S : Segment; T : Parameter) return Vec2
     with Global => null;

   ---------------------------------------------------------------------------
   -- 4. Liang_Barsky_Clip — main entry
   ---------------------------------------------------------------------------

   function Liang_Barsky_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;
   --  Accept ⇒ Clipped endpoints lie inside W (within Epsilon).

   ---------------------------------------------------------------------------
   -- 5. Liang_Barsky_Clip_Params — clip + retained t0 / t1
   ---------------------------------------------------------------------------

   function Liang_Barsky_Clip_Params
     (S : Segment; W : Clip_Window) return Clip_Params_Result
     with Pre => Is_Valid_Window (W), Global => null;

   ---------------------------------------------------------------------------
   -- 7. Cohen_Sutherland_Clip — in-package reference for tests
   ---------------------------------------------------------------------------

   function Cohen_Sutherland_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;
   --  Classic outcode clip; used to verify Liang–Barsky agreement.

   function Same_Clipped_Segment
     (A, B : Segment; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True if A and B represent the same undirected clipped segment.

end Liang_Barsky;
