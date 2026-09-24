--  Line_Clipping body — window helpers, embedded Cohen–Sutherland,
--  Liang–Barsky, Midpoint Subdivision, Skala-lite, Clip_With, Compare.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Line_Clipping
  with SPARK_Mode => Off
is

   -----------------------------------------------------------------------
   -- Internal numeric helpers
   -----------------------------------------------------------------------

   function Sqrt_Safe (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      else
         return Real (Sqrt (Float (X)));
      end if;
   end Sqrt_Safe;

   function Clamp (V, Lo, Hi : Real) return Real is
   begin
      if V < Lo then
         return Lo;
      elsif V > Hi then
         return Hi;
      else
         return V;
      end if;
   end Clamp;

   function Accepted (A, B : Vec2) return Clip_Result is
   begin
      return (Status => Clip_Accept, Clipped => (A, B));
   end Accepted;

   function Rejected return Clip_Result is
   begin
      return (Status => Clip_Reject, Clipped => ((0.0, 0.0), (0.0, 0.0)));
   end Rejected;

   function Midpoint (A, B : Vec2) return Vec2 is
   begin
      return (0.5 * (A.X + B.X), 0.5 * (A.Y + B.Y));
   end Midpoint;

   -----------------------------------------------------------------------
   -- Vector helpers
   -----------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point (A, B : Vec2; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near_Point;

   function "-" (A, B : Vec2) return Vec2 is
   begin
      return (A.X - B.X, A.Y - B.Y);
   end "-";

   function "+" (A, B : Vec2) return Vec2 is
   begin
      return (A.X + B.X, A.Y + B.Y);
   end "+";

   function "*" (S : Real; V : Vec2) return Vec2 is
   begin
      return (S * V.X, S * V.Y);
   end "*";

   function Dot (A, B : Vec2) return Real is
   begin
      return A.X * B.X + A.Y * B.Y;
   end Dot;

   -----------------------------------------------------------------------
   -- Segment helpers
   -----------------------------------------------------------------------

   function Make_Segment (P0, P1 : Vec2) return Segment is
   begin
      return (P0, P1);
   end Make_Segment;

   function Length (S : Segment) return Non_Negative is
      D : constant Vec2 := S.P1 - S.P0;
   begin
      return Sqrt_Safe (D.X * D.X + D.Y * D.Y);
   end Length;

   function Same_Clipped_Segment
     (A, B : Segment; Tol : Real := Epsilon) return Boolean
   is
   begin
      return
        (Near_Point (A.P0, B.P0, Tol) and then Near_Point (A.P1, B.P1, Tol))
        or else
        (Near_Point (A.P0, B.P1, Tol) and then Near_Point (A.P1, B.P0, Tol));
   end Same_Clipped_Segment;

   -----------------------------------------------------------------------
   -- Window construction
   -----------------------------------------------------------------------

   function Is_Valid_Window (W : Clip_Window) return Boolean is
   begin
      return W.X_Max > W.X_Min and then W.Y_Max > W.Y_Min;
   end Is_Valid_Window;

   function Make_Window
     (X_Min, Y_Min, X_Max, Y_Max : Real) return Clip_Window
   is
   begin
      if not (X_Max > X_Min and then Y_Max > Y_Min) then
         raise Invalid_Argument with "Make_Window requires positive extents";
      end if;
      return (X_Min, Y_Min, X_Max, Y_Max);
   end Make_Window;

   function Point_Inside_Window
     (P : Vec2; W : Clip_Window) return Boolean
   is
   begin
      return P.X >= W.X_Min - Epsilon
        and then P.X <= W.X_Max + Epsilon
        and then P.Y >= W.Y_Min - Epsilon
        and then P.Y <= W.Y_Max + Epsilon;
   end Point_Inside_Window;

   -----------------------------------------------------------------------
   -- Outcodes
   -----------------------------------------------------------------------

   function Compute_OutCode
     (P : Vec2; W : Clip_Window) return Out_Code
   is
      C : Out_Code := 0;
   begin
      if P.X < W.X_Min then
         C := C or Bit_Left;
      elsif P.X > W.X_Max then
         C := C or Bit_Right;
      end if;
      if P.Y < W.Y_Min then
         C := C or Bit_Bottom;
      elsif P.Y > W.Y_Max then
         C := C or Bit_Top;
      end if;
      return C;
   end Compute_OutCode;

   function Trivial_Accept (Code0, Code1 : Out_Code) return Boolean is
   begin
      return (Code0 or Code1) = 0;
   end Trivial_Accept;

   function Trivial_Reject (Code0, Code1 : Out_Code) return Boolean is
   begin
      return (Code0 and Code1) /= 0;
   end Trivial_Reject;

   -----------------------------------------------------------------------
   -- Cohen_Sutherland_Clip
   -----------------------------------------------------------------------

   function Cohen_Sutherland_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      X0 : Real := S.P0.X;
      Y0 : Real := S.P0.Y;
      X1 : Real := S.P1.X;
      Y1 : Real := S.P1.Y;
      C0 : Out_Code := Compute_OutCode ((X0, Y0), W);
      C1 : Out_Code := Compute_OutCode ((X1, Y1), W);
      C_Out : Out_Code;
      X, Y  : Real;
      Accept_Flag : Boolean := False;
      Done        : Boolean := False;
      Steps       : Natural := 0;
   begin
      loop
         if Trivial_Accept (C0, C1) then
            Accept_Flag := True;
            Done := True;
         elsif Trivial_Reject (C0, C1) then
            Done := True;
         else
            Steps := Steps + 1;
            if Steps > 8 then
               Done := True;
            else
               C_Out := (if C0 /= 0 then C0 else C1);

               if (C_Out and Bit_Top) /= 0 then
                  X := X0 + (X1 - X0) * (W.Y_Max - Y0) / (Y1 - Y0);
                  Y := W.Y_Max;
               elsif (C_Out and Bit_Bottom) /= 0 then
                  X := X0 + (X1 - X0) * (W.Y_Min - Y0) / (Y1 - Y0);
                  Y := W.Y_Min;
               elsif (C_Out and Bit_Right) /= 0 then
                  Y := Y0 + (Y1 - Y0) * (W.X_Max - X0) / (X1 - X0);
                  X := W.X_Max;
               else
                  Y := Y0 + (Y1 - Y0) * (W.X_Min - X0) / (X1 - X0);
                  X := W.X_Min;
               end if;

               if C_Out = C0 then
                  X0 := X;
                  Y0 := Y;
                  C0 := Compute_OutCode ((X0, Y0), W);
               else
                  X1 := X;
                  Y1 := Y;
                  C1 := Compute_OutCode ((X1, Y1), W);
               end if;
            end if;
         end if;
         exit when Done;
      end loop;

      if Accept_Flag then
         return Accepted ((X0, Y0), (X1, Y1));
      else
         return Rejected;
      end if;
   end Cohen_Sutherland_Clip;

   -----------------------------------------------------------------------
   -- Liang_Barsky_Clip
   -----------------------------------------------------------------------

   function Liang_Barsky_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      DX : constant Real := S.P1.X - S.P0.X;
      DY : constant Real := S.P1.Y - S.P0.Y;
      T_Enter : Real := 0.0;
      T_Leave : Real := 1.0;
      P, Q, U : Real;
      A, B    : Vec2;

      procedure Update_Bounds (Pi, Qi : Real; Rejected_Out : in out Boolean) is
      begin
         if Rejected_Out then
            return;
         end if;
         if Near (Pi, 0.0) then
            if Qi < 0.0 then
               Rejected_Out := True;
            end if;
         else
            U := Qi / Pi;
            if Pi < 0.0 then
               if U > T_Enter then
                  T_Enter := U;
               end if;
            else
               if U < T_Leave then
                  T_Leave := U;
               end if;
            end if;
         end if;
      end Update_Bounds;

      Rejected_Flag : Boolean := False;
   begin
      --  left, right, bottom, top
      P := -DX; Q := S.P0.X - W.X_Min;
      Update_Bounds (P, Q, Rejected_Flag);
      P := DX; Q := W.X_Max - S.P0.X;
      Update_Bounds (P, Q, Rejected_Flag);
      P := -DY; Q := S.P0.Y - W.Y_Min;
      Update_Bounds (P, Q, Rejected_Flag);
      P := DY; Q := W.Y_Max - S.P0.Y;
      Update_Bounds (P, Q, Rejected_Flag);

      if Rejected_Flag or else T_Enter > T_Leave then
         return Rejected;
      end if;

      T_Enter := Clamp (T_Enter, 0.0, 1.0);
      T_Leave := Clamp (T_Leave, 0.0, 1.0);
      if T_Enter > T_Leave then
         return Rejected;
      end if;

      A := (S.P0.X + T_Enter * DX, S.P0.Y + T_Enter * DY);
      B := (S.P0.X + T_Leave * DX, S.P0.Y + T_Leave * DY);
      A.X := Clamp (A.X, W.X_Min, W.X_Max);
      A.Y := Clamp (A.Y, W.Y_Min, W.Y_Max);
      B.X := Clamp (B.X, W.X_Min, W.X_Max);
      B.Y := Clamp (B.Y, W.Y_Min, W.Y_Max);
      return Accepted (A, B);
   end Liang_Barsky_Clip;

   -----------------------------------------------------------------------
   -- Midpoint_Subdivision_Clip
   -----------------------------------------------------------------------

   --  Collect visible endpoints along the original segment by recursive
   --  midpoint subdivision (textbook CS companion). When a candidate is
   --  shorter than Stop_Eps we accept it only if at least one endpoint
   --  (or the midpoint) lies inside the closed window.

   procedure Subdivide
     (P0, P1     : Vec2;
      W          : Clip_Window;
      Stop_Eps   : Real;
      Found_First : in out Boolean;
      First, Last : in out Vec2;
      Depth      : Natural)
   is
      C0 : constant Out_Code := Compute_OutCode (P0, W);
      C1 : constant Out_Code := Compute_OutCode (P1, W);
      M  : Vec2;
      Seg_Len : Real;
   begin
      if Depth > 48 then
         return;
      end if;

      if Trivial_Reject (C0, C1) then
         return;
      end if;

      Seg_Len := Length (Make_Segment (P0, P1));

      if Trivial_Accept (C0, C1) then
         if not Found_First then
            First := P0;
            Found_First := True;
         end if;
         Last := P1;
         return;
      end if;

      if Seg_Len <= Stop_Eps then
         --  Tiny straddling stub: keep if either end / mid is inside.
         M := Midpoint (P0, P1);
         if Point_Inside_Window (P0, W)
           or else Point_Inside_Window (P1, W)
           or else Point_Inside_Window (M, W)
         then
            if not Found_First then
               if Point_Inside_Window (P0, W) then
                  First := P0;
               elsif Point_Inside_Window (M, W) then
                  First := M;
               else
                  First := P1;
               end if;
               Found_First := True;
            end if;
            if Point_Inside_Window (P1, W) then
               Last := P1;
            elsif Point_Inside_Window (M, W) then
               Last := M;
            else
               Last := P0;
            end if;
         end if;
         return;
      end if;

      M := Midpoint (P0, P1);
      Subdivide (P0, M, W, Stop_Eps, Found_First, First, Last, Depth + 1);
      Subdivide (M, P1, W, Stop_Eps, Found_First, First, Last, Depth + 1);
   end Subdivide;

   function Midpoint_Subdivision_Clip
     (S          : Segment;
      W          : Clip_Window;
      Stop_Eps   : Real := Midpoint_Epsilon) return Clip_Result
   is
      Found : Boolean := False;
      First, Last : Vec2 := (0.0, 0.0);
   begin
      if Stop_Eps <= 0.0 then
         raise Invalid_Argument with "Stop_Eps must be positive";
      end if;

      Subdivide (S.P0, S.P1, W, Stop_Eps, Found, First, Last, 0);

      if not Found then
         return Rejected;
      end if;

      --  Nudge onto the closed window to absorb float noise from bisection.
      First.X := Clamp (First.X, W.X_Min, W.X_Max);
      First.Y := Clamp (First.Y, W.Y_Min, W.Y_Max);
      Last.X  := Clamp (Last.X,  W.X_Min, W.X_Max);
      Last.Y  := Clamp (Last.Y,  W.Y_Min, W.Y_Max);
      return Accepted (First, Last);
   end Midpoint_Subdivision_Clip;

   -----------------------------------------------------------------------
   -- Skala_Clip_Lite — corner classification + edge intersections
   -----------------------------------------------------------------------

   --  Homogeneous line coefficients for the infinite line through S:
   --  a x + b y + c = 0 with (a,b,c) ~ P0 × P1 in 2-D homogeneous form.
   --  Sign at a window corner classifies the half-space; edges whose
   --  endpoints disagree are intersected. Intersections are converted to
   --  parametric t on the segment and merged with [0,1] against the
   --  rectangular window (LB-style bounds for robustness).

   function Skala_Clip_Lite
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      --  For educational clarity and lattice agreement with CS/LB on
      --  rectangles, compute corner signs of the supporting line, then
      --  fall through to a parametric clip of the segment against W.
      --  The corner encoding documents Skala's "which edges are hit"
      --  idea; the final interval uses the same inequalities as LB so
      --  the lite variant stays consistent on axis-aligned windows.
      --
      --  Full Skala (homogeneous duality, convex polygons) is deeper —
      --  see literature / dedicated treatments.

      DX : constant Real := S.P1.X - S.P0.X;
      DY : constant Real := S.P1.Y - S.P0.Y;
      --  Line: a x + b y + c = 0 from P0 × P1 (w=1):
      A_Coeff : constant Real := S.P0.Y - S.P1.Y;          -- = -DY
      B_Coeff : constant Real := S.P1.X - S.P0.X;          -- =  DX
      C_Coeff : constant Real :=
        S.P0.X * S.P1.Y - S.P1.X * S.P0.Y;

      type Corner_Index is range 0 .. 3;
      Corners : constant array (Corner_Index) of Vec2 :=
        [(W.X_Min, W.Y_Min),   -- 0 bottom-left
         (W.X_Max, W.Y_Min),   -- 1 bottom-right
         (W.X_Max, W.Y_Max),   -- 2 top-right
         (W.X_Min, W.Y_Max)];  -- 3 top-left

      Signs : array (Corner_Index) of Integer;
      Crossed_Edges : Natural := 0;
      Side          : Real;
      T_Enter       : Real := 0.0;
      T_Leave       : Real := 1.0;
      P, Q, U       : Real;
      Rejected_Flag : Boolean := False;
      Pt_A, Pt_B    : Vec2;

      function Sign_Of (V : Real) return Integer is
      begin
         if V > Epsilon then
            return 1;
         elsif V < -Epsilon then
            return -1;
         else
            return 0;
         end if;
      end Sign_Of;

      procedure Update_Bounds (Pi, Qi : Real) is
      begin
         if Rejected_Flag then
            return;
         end if;
         if Near (Pi, 0.0) then
            if Qi < 0.0 then
               Rejected_Flag := True;
            end if;
         else
            U := Qi / Pi;
            if Pi < 0.0 then
               if U > T_Enter then
                  T_Enter := U;
               end if;
            else
               if U < T_Leave then
                  T_Leave := U;
               end if;
            end if;
         end if;
      end Update_Bounds;

   begin
      --  Degenerate point segment: accept iff inside.
      if Near (DX, 0.0) and then Near (DY, 0.0) then
         if Point_Inside_Window (S.P0, W) then
            return Accepted (S.P0, S.P1);
         else
            return Rejected;
         end if;
      end if;

      --  Skala-inspired corner encoding against the supporting line.
      for I in Corner_Index loop
         Side := A_Coeff * Corners (I).X
           + B_Coeff * Corners (I).Y
           + C_Coeff;
         Signs (I) := Sign_Of (Side);
      end loop;

      --  Count edges whose endpoints differ in sign (crossed by the line).
      for I in Corner_Index loop
         declare
            J : constant Corner_Index :=
              Corner_Index ((Integer (I) + 1) rem 4);
         begin
            if Signs (I) * Signs (J) = -1
              or else (Signs (I) = 0 xor Signs (J) = 0)
            then
               Crossed_Edges := Crossed_Edges + 1;
            elsif Signs (I) = 0 and then Signs (J) = 0 then
               --  Line coincident with an edge — still a hit.
               Crossed_Edges := Crossed_Edges + 1;
            end if;
         end;
      end loop;

      --  If the infinite line misses the window entirely, reject unless
      --  the segment is already inside (handled by parametric path below
      --  which also catches fully-inside cases with Crossed_Edges = 0).
      pragma Assert (Crossed_Edges <= 4);

      --  Parametric clip against the rectangle (reliable for AA window).
      P := -DX; Q := S.P0.X - W.X_Min;
      Update_Bounds (P, Q);
      P := DX; Q := W.X_Max - S.P0.X;
      Update_Bounds (P, Q);
      P := -DY; Q := S.P0.Y - W.Y_Min;
      Update_Bounds (P, Q);
      P := DY; Q := W.Y_Max - S.P0.Y;
      Update_Bounds (P, Q);

      if Rejected_Flag or else T_Enter > T_Leave then
         return Rejected;
      end if;

      T_Enter := Clamp (T_Enter, 0.0, 1.0);
      T_Leave := Clamp (T_Leave, 0.0, 1.0);
      if T_Enter > T_Leave then
         return Rejected;
      end if;

      Pt_A := (S.P0.X + T_Enter * DX, S.P0.Y + T_Enter * DY);
      Pt_B := (S.P0.X + T_Leave * DX, S.P0.Y + T_Leave * DY);
      Pt_A.X := Clamp (Pt_A.X, W.X_Min, W.X_Max);
      Pt_A.Y := Clamp (Pt_A.Y, W.Y_Min, W.Y_Max);
      Pt_B.X := Clamp (Pt_B.X, W.X_Min, W.X_Max);
      Pt_B.Y := Clamp (Pt_B.Y, W.Y_Min, W.Y_Max);

      --  Silence unused-warning concerns: Crossed_Edges documents encoding.
      if Crossed_Edges = 0
        and then not Point_Inside_Window (S.P0, W)
        and then not Point_Inside_Window (S.P1, W)
      then
         --  Line parallel / outside without edge crossings — already
         --  rejected by parametric path when applicable; keep Accepted
         --  only when the parametric path said so (inside parallel).
         null;
      end if;

      return Accepted (Pt_A, Pt_B);
   end Skala_Clip_Lite;

   -----------------------------------------------------------------------
   -- Clip_With
   -----------------------------------------------------------------------

   function Clip_With
     (S : Segment; W : Clip_Window; Kind : Algorithm_Kind) return Clip_Result
   is
   begin
      case Kind is
         when Cohen_Sutherland =>
            return Cohen_Sutherland_Clip (S, W);
         when Liang_Barsky =>
            return Liang_Barsky_Clip (S, W);
         when Midpoint_Subdivision =>
            return Midpoint_Subdivision_Clip (S, W);
         when Skala_Lite =>
            return Skala_Clip_Lite (S, W);
      end case;
   end Clip_With;

   -----------------------------------------------------------------------
   -- Compare_Algorithms
   -----------------------------------------------------------------------

   function Compare_Algorithms
     (S          : Segment;
      W          : Clip_Window;
      Left_Kind  : Algorithm_Kind;
      Right_Kind : Algorithm_Kind;
      Tol        : Real := Epsilon) return Agreement_Report
   is
      R : Agreement_Report;
   begin
      R.Left  := Clip_With (S, W, Left_Kind);
      R.Right := Clip_With (S, W, Right_Kind);
      R.Same_Status := R.Left.Status = R.Right.Status;
      if not R.Same_Status then
         R.Same_Clipped_Seg := False;
         R.Agree := False;
      elsif R.Left.Status = Clip_Reject then
         R.Same_Clipped_Seg := True;
         R.Agree := True;
      else
         R.Same_Clipped_Seg :=
           Same_Clipped_Segment (R.Left.Clipped, R.Right.Clipped, Tol);
         R.Agree := R.Same_Clipped_Seg;
      end if;
      return R;
   end Compare_Algorithms;

end Line_Clipping;
