--  De_Boor body — B-spline evaluation via De Boor's algorithm.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body De_Boor
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near
     (A, B : Point_2D; Tol : Float := Near_Tol) return Boolean
   is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near;

   function Near
     (A, B : Point_3D; Tol : Float := Near_Tol) return Boolean
   is
   begin
      return Near (A.X, B.X, Tol)
        and then Near (A.Y, B.Y, Tol)
        and then Near (A.Z, B.Z, Tol);
   end Near;

   function Dist (A, B : Point_2D) return Float is
      DX : constant Float := A.X - B.X;
      DY : constant Float := A.Y - B.Y;
   begin
      return Math.Sqrt (DX * DX + DY * DY);
   end Dist;

   function Dist (A, B : Point_3D) return Float is
      DX : constant Float := A.X - B.X;
      DY : constant Float := A.Y - B.Y;
      DZ : constant Float := A.Z - B.Z;
   begin
      return Math.Sqrt (DX * DX + DY * DY + DZ * DZ);
   end Dist;

   function Lerp (A, B : Float; T : Float) return Float is
   begin
      return (1.0 - T) * A + T * B;
   end Lerp;

   function Lerp (A, B : Point_2D; T : Float) return Point_2D is
   begin
      return (X => Lerp (A.X, B.X, T), Y => Lerp (A.Y, B.Y, T));
   end Lerp;

   function Lerp (A, B : Point_3D; T : Float) return Point_3D is
   begin
      return
        (X => Lerp (A.X, B.X, T),
         Y => Lerp (A.Y, B.Y, T),
         Z => Lerp (A.Z, B.Z, T));
   end Lerp;

   function Add (A, B : Point_2D) return Point_2D is
   begin
      return (X => A.X + B.X, Y => A.Y + B.Y);
   end Add;

   function Sub (A, B : Point_2D) return Point_2D is
   begin
      return (X => A.X - B.X, Y => A.Y - B.Y);
   end Sub;

   function Scale (A : Point_2D; S : Float) return Point_2D is
   begin
      return (X => A.X * S, Y => A.Y * S);
   end Scale;

   function Add (A, B : Point_3D) return Point_3D is
   begin
      return (X => A.X + B.X, Y => A.Y + B.Y, Z => A.Z + B.Z);
   end Add;

   function Sub (A, B : Point_3D) return Point_3D is
   begin
      return (X => A.X - B.X, Y => A.Y - B.Y, Z => A.Z - B.Z);
   end Sub;

   function Scale (A : Point_3D; S : Float) return Point_3D is
   begin
      return (X => A.X * S, Y => A.Y * S, Z => A.Z * S);
   end Scale;

   function Make_Point (X, Y : Float) return Point_2D is
   begin
      return (X => X, Y => Y);
   end Make_Point;

   function Make_Point (X, Y, Z : Float) return Point_3D is
   begin
      return (X => X, Y => Y, Z => Z);
   end Make_Point;

   ---------------------------------------------------------------------------
   -- Knot / domain
   ---------------------------------------------------------------------------

   function Expected_Knot_Count
     (Num_Controls : Control_Count; Degree : Degree_Range) return Natural
   is
   begin
      return Num_Controls + Degree + 1;
   end Expected_Knot_Count;

   function Is_Valid_Knots
     (Knots        : Knot_Vector;
      Degree       : Degree_Range;
      Num_Controls : Control_Count) return Boolean
   is
      Need     : Natural;
      Mult     : Natural;
      Run_First : Natural;
      Is_End   : Boolean;
   begin
      if Num_Controls = 0 then
         return False;
      end if;
      Need := Expected_Knot_Count (Num_Controls, Degree);
      if Knots'Length /= Need then
         return False;
      end if;
      if Knots'First /= 0 then
         return False;
      end if;

      --  Nondecreasing
      for I in Knots'First .. Knots'Last - 1 loop
         if Knots (I + 1) < Knots (I) then
            return False;
         end if;
      end loop;

      --  Multiplicity: ends ≤ Degree+1, interior ≤ Degree
      Mult := 1;
      Run_First := Knots'First;
      for I in Knots'First + 1 .. Knots'Last loop
         if abs (Knots (I) - Knots (I - 1)) <= Epsilon_Tol then
            Mult := Mult + 1;
         else
            Is_End := Run_First = Knots'First;
            if Is_End then
               if Mult > Degree + 1 then
                  return False;
               end if;
            else
               if Mult > Degree then
                  return False;
               end if;
            end if;
            Mult := 1;
            Run_First := I;
         end if;
      end loop;
      --  Trailing run is an end multiplicity
      if Mult > Degree + 1 then
         return False;
      end if;

      return True;
   end Is_Valid_Knots;

   function Domain_Low
     (Knots : Knot_Vector; Degree : Degree_Range) return Float
   is
   begin
      return Knots (Knots'First + Degree);
   end Domain_Low;

   function Domain_High
     (Knots        : Knot_Vector;
      Degree       : Degree_Range;
      Num_Controls : Control_Count) return Float
   is
      N : constant Natural := Num_Controls - 1;
   begin
      pragma Unreferenced (Degree);
      return Knots (Knots'First + N + 1);
   end Domain_High;

   function In_Domain
     (Knots        : Knot_Vector;
      Degree       : Degree_Range;
      Num_Controls : Control_Count;
      X            : Float) return Boolean
   is
      Lo, Hi : Float;
   begin
      if Num_Controls = 0
        or else Knots'Length < Expected_Knot_Count (Num_Controls, Degree)
      then
         return False;
      end if;
      Lo := Domain_Low (Knots, Degree);
      Hi := Domain_High (Knots, Degree, Num_Controls);
      return X >= Lo and then X <= Hi;
   end In_Domain;

   function Find_Span
     (Knots        : Knot_Vector;
      Degree       : Degree_Range;
      Num_Controls : Control_Count;
      X            : Float) return Span_Result
   is
      Result : Span_Result;
      N      : Natural;
      Low, High, Mid : Natural;
      U0     : Natural;
   begin
      Result.Success := False;
      Result.Stat    := Ill_Started;
      Result.Index   := 0;

      if Num_Controls = 0 then
         Result.Stat := Dimension_Error;
         return Result;
      end if;
      if not Is_Valid_Knots (Knots, Degree, Num_Controls) then
         Result.Stat := Invalid_Knots;
         return Result;
      end if;

      N  := Num_Controls - 1;
      U0 := Knots'First;

      --  Right endpoint: return n
      if Near (X, Knots (U0 + N + 1), Epsilon_Tol)
        or else X >= Knots (U0 + N + 1) - Epsilon_Tol
      then
         if X > Knots (U0 + N + 1) + Epsilon_Tol then
            Result.Stat := Out_Of_Domain;
            return Result;
         end if;
         Result.Index   := N;
         Result.Stat    := Ok;
         Result.Success := True;
         return Result;
      end if;

      if X < Knots (U0 + Degree) - Epsilon_Tol then
         Result.Stat := Out_Of_Domain;
         return Result;
      end if;

      --  Binary search for k with t_k <= X < t_{k+1}
      Low  := Degree;
      High := N + 1;
      Mid  := (Low + High) / 2;
      while X < Knots (U0 + Mid)
        or else X >= Knots (U0 + Mid + 1)
      loop
         if X < Knots (U0 + Mid) then
            High := Mid;
         else
            Low := Mid;
         end if;
         if High <= Low + 1 and then
           not (X < Knots (U0 + Mid) or else X >= Knots (U0 + Mid + 1))
         then
            exit;
         end if;
         if High = Low then
            exit;
         end if;
         Mid := (Low + High) / 2;
         if Mid = Low and then High = Low + 1 then
            --  Force progress toward the correct side
            if X >= Knots (U0 + Low)
              and then X < Knots (U0 + Low + 1)
            then
               Mid := Low;
               exit;
            elsif X >= Knots (U0 + High)
              and then (High = N + 1
                        or else X < Knots (U0 + High + 1))
            then
               Mid := High;
               exit;
            else
               Mid := Low;
               exit;
            end if;
         end if;
      end loop;

      Result.Index   := Mid;
      Result.Stat    := Ok;
      Result.Success := True;
      return Result;
   end Find_Span;

   ---------------------------------------------------------------------------
   -- Internal: check args shared by Evaluate
   ---------------------------------------------------------------------------

   function Check_Args
     (Num_Controls : Natural;
      Knots        : Knot_Vector;
      Degree       : Degree_Range) return Status
   is
   begin
      if Num_Controls = 0 or else Num_Controls > Max_Controls then
         return Dimension_Error;
      end if;
      if Num_Controls <= Degree then
         return Dimension_Error;
      end if;
      if not Is_Valid_Knots
           (Knots, Degree, Control_Count (Num_Controls))
      then
         return Invalid_Knots;
      end if;
      return Ok;
   end Check_Args;

   ---------------------------------------------------------------------------
   -- Evaluate 1D
   ---------------------------------------------------------------------------

   function Evaluate
     (Controls : Controls_1D;
      Knots    : Knot_Vector;
      Degree   : Degree_Range;
      X        : Float) return Eval_Result_1D
   is
      Result : Eval_Result_1D;
      Stat   : Status;
      Span   : Span_Result;
      N_Ctrl : Natural;
      K, P   : Natural;
      D      : array (0 .. Max_Degree) of Float := [others => 0.0];
      Alpha  : Float;
      Denom  : Float;
      U0     : Natural;
   begin
      Result.Success := False;
      Result.Value   := 0.0;
      N_Ctrl := Controls'Length;
      Stat   := Check_Args (N_Ctrl, Knots, Degree);
      if Stat /= Ok then
         Result.Stat := Stat;
         return Result;
      end if;

      if not In_Domain (Knots, Degree, Control_Count (N_Ctrl), X) then
         Result.Stat := Out_Of_Domain;
         return Result;
      end if;

      Span := Find_Span (Knots, Degree, Control_Count (N_Ctrl), X);
      if not Span.Success then
         Result.Stat := Span.Stat;
         return Result;
      end if;

      K  := Span.Index;
      P  := Degree;
      U0 := Knots'First;

      --  Degree 0: constant on the span
      if P = 0 then
         Result.Value   := Controls (Controls'First + K);
         Result.Stat    := Ok;
         Result.Success := True;
         return Result;
      end if;

      --  d_j := c_{j+k-p}
      for J in 0 .. P loop
         D (J) := Controls (Controls'First + J + K - P);
      end loop;

      --  Optimized De Boor: for r = 1..p; j = p downto r
      for R in 1 .. P loop
         for J in reverse R .. P loop
            Denom := Knots (U0 + J + 1 + K - R)
              - Knots (U0 + J + K - P);
            if abs (Denom) <= Epsilon_Tol then
               Alpha := 0.0;
            else
               Alpha := (X - Knots (U0 + J + K - P)) / Denom;
            end if;
            D (J) := (1.0 - Alpha) * D (J - 1) + Alpha * D (J);
         end loop;
      end loop;

      Result.Value   := D (P);
      Result.Stat    := Ok;
      Result.Success := True;
      return Result;
   end Evaluate;

   ---------------------------------------------------------------------------
   -- Evaluate 2D
   ---------------------------------------------------------------------------

   function Evaluate
     (Controls : Controls_2D;
      Knots    : Knot_Vector;
      Degree   : Degree_Range;
      X        : Float) return Eval_Result_2D
   is
      Result : Eval_Result_2D;
      Stat   : Status;
      Span   : Span_Result;
      N_Ctrl : Natural;
      K, P   : Natural;
      D      : array (0 .. Max_Degree) of Point_2D :=
                 [others => (0.0, 0.0)];
      Alpha  : Float;
      Denom  : Float;
      U0     : Natural;
   begin
      Result.Success := False;
      Result.Point   := (0.0, 0.0);
      N_Ctrl := Controls'Length;
      Stat   := Check_Args (N_Ctrl, Knots, Degree);
      if Stat /= Ok then
         Result.Stat := Stat;
         return Result;
      end if;

      if not In_Domain (Knots, Degree, Control_Count (N_Ctrl), X) then
         Result.Stat := Out_Of_Domain;
         return Result;
      end if;

      Span := Find_Span (Knots, Degree, Control_Count (N_Ctrl), X);
      if not Span.Success then
         Result.Stat := Span.Stat;
         return Result;
      end if;

      K  := Span.Index;
      P  := Degree;
      U0 := Knots'First;

      if P = 0 then
         Result.Point   := Controls (Controls'First + K);
         Result.Stat    := Ok;
         Result.Success := True;
         return Result;
      end if;

      for J in 0 .. P loop
         D (J) := Controls (Controls'First + J + K - P);
      end loop;

      for R in 1 .. P loop
         for J in reverse R .. P loop
            Denom := Knots (U0 + J + 1 + K - R)
              - Knots (U0 + J + K - P);
            if abs (Denom) <= Epsilon_Tol then
               Alpha := 0.0;
            else
               Alpha := (X - Knots (U0 + J + K - P)) / Denom;
            end if;
            D (J) := Lerp (D (J - 1), D (J), Alpha);
         end loop;
      end loop;

      Result.Point   := D (P);
      Result.Stat    := Ok;
      Result.Success := True;
      return Result;
   end Evaluate;

   ---------------------------------------------------------------------------
   -- Evaluate 3D
   ---------------------------------------------------------------------------

   function Evaluate
     (Controls : Controls_3D;
      Knots    : Knot_Vector;
      Degree   : Degree_Range;
      X        : Float) return Eval_Result_3D
   is
      Result : Eval_Result_3D;
      Stat   : Status;
      Span   : Span_Result;
      N_Ctrl : Natural;
      K, P   : Natural;
      D      : array (0 .. Max_Degree) of Point_3D :=
                 [others => (0.0, 0.0, 0.0)];
      Alpha  : Float;
      Denom  : Float;
      U0     : Natural;
   begin
      Result.Success := False;
      Result.Point   := (0.0, 0.0, 0.0);
      N_Ctrl := Controls'Length;
      Stat   := Check_Args (N_Ctrl, Knots, Degree);
      if Stat /= Ok then
         Result.Stat := Stat;
         return Result;
      end if;

      if not In_Domain (Knots, Degree, Control_Count (N_Ctrl), X) then
         Result.Stat := Out_Of_Domain;
         return Result;
      end if;

      Span := Find_Span (Knots, Degree, Control_Count (N_Ctrl), X);
      if not Span.Success then
         Result.Stat := Span.Stat;
         return Result;
      end if;

      K  := Span.Index;
      P  := Degree;
      U0 := Knots'First;

      if P = 0 then
         Result.Point   := Controls (Controls'First + K);
         Result.Stat    := Ok;
         Result.Success := True;
         return Result;
      end if;

      for J in 0 .. P loop
         D (J) := Controls (Controls'First + J + K - P);
      end loop;

      for R in 1 .. P loop
         for J in reverse R .. P loop
            Denom := Knots (U0 + J + 1 + K - R)
              - Knots (U0 + J + K - P);
            if abs (Denom) <= Epsilon_Tol then
               Alpha := 0.0;
            else
               Alpha := (X - Knots (U0 + J + K - P)) / Denom;
            end if;
            D (J) := Lerp (D (J - 1), D (J), Alpha);
         end loop;
      end loop;

      Result.Point   := D (P);
      Result.Stat    := Ok;
      Result.Success := True;
      return Result;
   end Evaluate;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Make_Uniform_Clamped
     (Num_Controls : Control_Count;
      Degree       : Degree_Range;
      T_Min        : Float := 0.0;
      T_Max        : Float := 1.0) return Knot_Vector
   is
      M      : constant Natural := Expected_Knot_Count (Num_Controls, Degree);
      Result : Knot_Vector (0 .. M - 1);
      N      : constant Natural := Num_Controls - 1;
      P      : constant Natural := Degree;
      Interior : Natural;
      Span_W   : Float;
   begin
      --  Clamped: Result(0..p) = T_Min, Result(n+1 .. n+p+1) = T_Max
      for I in 0 .. P loop
         Result (I) := T_Min;
      end loop;
      for I in N + 1 .. N + P + 1 loop
         Result (I) := T_Max;
      end loop;

      Interior := N - P;  --  number of interior knot *values* slots: indices p+1 .. n
      if Interior > 0 then
         Span_W := (T_Max - T_Min) / Float (Interior + 1);
         for J in 1 .. Interior loop
            Result (P + J) := T_Min + Float (J) * Span_W;
         end loop;
      end if;
      return Result;
   end Make_Uniform_Clamped;

   function Make_Bezier_Knots
     (Degree : Degree_Range;
      T_Min  : Float := 0.0;
      T_Max  : Float := 1.0) return Knot_Vector
   is
      P      : constant Natural := Degree;
      Result : Knot_Vector (0 .. 2 * P + 1);
   begin
      for I in 0 .. P loop
         Result (I) := T_Min;
      end loop;
      for I in P + 1 .. 2 * P + 1 loop
         Result (I) := T_Max;
      end loop;
      return Result;
   end Make_Bezier_Knots;

   function Make_Linear_1D (A, B : Float) return Controls_1D is
   begin
      return Controls_1D'(0 => A, 1 => B);
   end Make_Linear_1D;

   function Make_Linear_2D (P0, P1 : Point_2D) return Controls_2D is
   begin
      return Controls_2D'(0 => P0, 1 => P1);
   end Make_Linear_2D;

   function Make_Linear_3D (P0, P1 : Point_3D) return Controls_3D is
   begin
      return Controls_3D'(0 => P0, 1 => P1);
   end Make_Linear_3D;

   function Make_Cubic_Bezier_2D
     (P0, P1, P2, P3 : Point_2D) return Controls_2D
   is
   begin
      return Controls_2D'(0 => P0, 1 => P1, 2 => P2, 3 => P3);
   end Make_Cubic_Bezier_2D;

   function Make_Cubic_Bezier_1D
     (C0, C1, C2, C3 : Float) return Controls_1D
   is
   begin
      return Controls_1D'(0 => C0, 1 => C1, 2 => C2, 3 => C3);
   end Make_Cubic_Bezier_1D;

   function Make_Cubic_Bezier_3D
     (P0, P1, P2, P3 : Point_3D) return Controls_3D
   is
   begin
      return Controls_3D'(0 => P0, 1 => P1, 2 => P2, 3 => P3);
   end Make_Cubic_Bezier_3D;

   function Make_Linear_Interpolant_1D
     (A, B : Float) return Curve_1D
   is
      C : Curve_1D;
      K : constant Knot_Vector := Make_Uniform_Clamped (2, 1);
   begin
      C.Controls (0) := A;
      C.Controls (1) := B;
      C.N_Ctrl  := 2;
      C.Degree  := 1;
      C.N_Knots := K'Length;
      for I in K'Range loop
         C.Knots (I) := K (I);
      end loop;
      return C;
   end Make_Linear_Interpolant_1D;

   function Make_Linear_Interpolant_2D
     (P0, P1 : Point_2D) return Curve_2D
   is
      C : Curve_2D;
      K : constant Knot_Vector := Make_Uniform_Clamped (2, 1);
   begin
      C.Controls (0) := P0;
      C.Controls (1) := P1;
      C.N_Ctrl  := 2;
      C.Degree  := 1;
      C.N_Knots := K'Length;
      for I in K'Range loop
         C.Knots (I) := K (I);
      end loop;
      return C;
   end Make_Linear_Interpolant_2D;

   function Make_Cubic_Bezier_As_BSpline_2D
     (P0, P1, P2, P3 : Point_2D) return Curve_2D
   is
      C : Curve_2D;
      K : constant Knot_Vector := Make_Bezier_Knots (3);
   begin
      C.Controls (0) := P0;
      C.Controls (1) := P1;
      C.Controls (2) := P2;
      C.Controls (3) := P3;
      C.N_Ctrl  := 4;
      C.Degree  := 3;
      C.N_Knots := K'Length;
      for I in K'Range loop
         C.Knots (I) := K (I);
      end loop;
      return C;
   end Make_Cubic_Bezier_As_BSpline_2D;

   function Make_Uniform_Clamped_2D
     (Controls : Controls_2D;
      Degree   : Degree_Range) return Curve_2D
   is
      C    : Curve_2D;
      NC   : constant Control_Count := Controls'Length;
      K    : constant Knot_Vector := Make_Uniform_Clamped (NC, Degree);
      Idx  : Natural := 0;
   begin
      for I in Controls'Range loop
         C.Controls (Idx) := Controls (I);
         Idx := Idx + 1;
      end loop;
      C.N_Ctrl  := NC;
      C.Degree  := Degree;
      C.N_Knots := K'Length;
      for I in K'Range loop
         C.Knots (I) := K (I);
      end loop;
      return C;
   end Make_Uniform_Clamped_2D;

   function Make_Example_2D (Kind : Example_Kind) return Curve_2D is
   begin
      case Kind is
         when Linear_Ramp =>
            return Make_Linear_Interpolant_2D
              (Make_Point (0.0, 0.0), Make_Point (1.0, 1.0));

         when Cubic_Bezier_Unit =>
            return Make_Cubic_Bezier_As_BSpline_2D
              (Make_Point (0.0, 0.0),
               Make_Point (0.0, 1.0),
               Make_Point (1.0, 1.0),
               Make_Point (1.0, 0.0));

         when Uniform_Quadratic =>
            declare
               Ctrl : constant Controls_2D :=
                 [Make_Point (0.0, 0.0),
                  Make_Point (0.0, 1.0),
                  Make_Point (1.0, 1.0),
                  Make_Point (1.0, 0.0)];
            begin
               return Make_Uniform_Clamped_2D (Ctrl, 2);
            end;

         when Clamped_Cubic =>
            declare
               Ctrl : constant Controls_2D :=
                 [Make_Point (0.0, 0.0),
                  Make_Point (0.25, 1.0),
                  Make_Point (0.5, 0.0),
                  Make_Point (0.75, 1.0),
                  Make_Point (1.0, 0.0)];
            begin
               return Make_Uniform_Clamped_2D (Ctrl, 3);
            end;
      end case;
   end Make_Example_2D;

   function Make_Example_1D (Kind : Example_Kind) return Curve_1D is
      C : Curve_1D;
   begin
      case Kind is
         when Linear_Ramp =>
            return Make_Linear_Interpolant_1D (0.0, 1.0);

         when Cubic_Bezier_Unit =>
            declare
               BK : constant Knot_Vector := Make_Bezier_Knots (3);
            begin
               C.Controls (0) := 0.0;
               C.Controls (1) := 0.0;
               C.Controls (2) := 1.0;
               C.Controls (3) := 1.0;
               C.N_Ctrl  := 4;
               C.Degree  := 3;
               C.N_Knots := BK'Length;
               for I in BK'Range loop
                  C.Knots (I) := BK (I);
               end loop;
               return C;
            end;

         when Uniform_Quadratic =>
            declare
               UK : constant Knot_Vector := Make_Uniform_Clamped (4, 2);
            begin
               C.Controls (0) := 0.0;
               C.Controls (1) := 1.0;
               C.Controls (2) := 1.0;
               C.Controls (3) := 0.0;
               C.N_Ctrl  := 4;
               C.Degree  := 2;
               C.N_Knots := UK'Length;
               for I in UK'Range loop
                  C.Knots (I) := UK (I);
               end loop;
               return C;
            end;

         when Clamped_Cubic =>
            declare
               UK : constant Knot_Vector := Make_Uniform_Clamped (5, 3);
            begin
               C.Controls (0) := 0.0;
               C.Controls (1) := 1.0;
               C.Controls (2) := 0.0;
               C.Controls (3) := 1.0;
               C.Controls (4) := 0.0;
               C.N_Ctrl  := 5;
               C.Degree  := 3;
               C.N_Knots := UK'Length;
               for I in UK'Range loop
                  C.Knots (I) := UK (I);
               end loop;
               return C;
            end;
      end case;
   end Make_Example_1D;

   function Evaluate_Curve
     (C : Curve_1D; X : Float) return Eval_Result_1D
   is
      Ctrl : Controls_1D (0 .. C.N_Ctrl - 1);
      Knot : Knot_Vector (0 .. C.N_Knots - 1);
   begin
      if C.N_Ctrl = 0 or else C.N_Knots = 0 then
         return (Value => 0.0, Stat => Dimension_Error, Success => False);
      end if;
      for I in Ctrl'Range loop
         Ctrl (I) := C.Controls (I);
      end loop;
      for I in Knot'Range loop
         Knot (I) := C.Knots (I);
      end loop;
      return Evaluate (Ctrl, Knot, C.Degree, X);
   end Evaluate_Curve;

   function Evaluate_Curve
     (C : Curve_2D; X : Float) return Eval_Result_2D
   is
      Ctrl : Controls_2D (0 .. C.N_Ctrl - 1);
      Knot : Knot_Vector (0 .. C.N_Knots - 1);
   begin
      if C.N_Ctrl = 0 or else C.N_Knots = 0 then
         return
           (Point => (0.0, 0.0), Stat => Dimension_Error, Success => False);
      end if;
      for I in Ctrl'Range loop
         Ctrl (I) := C.Controls (I);
      end loop;
      for I in Knot'Range loop
         Knot (I) := C.Knots (I);
      end loop;
      return Evaluate (Ctrl, Knot, C.Degree, X);
   end Evaluate_Curve;

end De_Boor;
