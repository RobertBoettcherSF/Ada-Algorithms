--  De_Casteljau body — Bézier evaluation / subdivision.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body De_Casteljau
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Elementary_Functions;

   function Classify_T (T : Float) return Status is
   begin
      if In_Unit_Interval (T) then
         return Ok;
      else
         return Extrapolated;
      end if;
   end Classify_T;

   function Check_Controls_Len (Len : Natural) return Status is
   begin
      if Len = 0 then
         return Empty;
      elsif Len > Max_Controls then
         return Degree_Too_High;
      else
         return Ok;
      end if;
   end Check_Controls_Len;

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

   function Degree_Of (C : Controls_1D) return Degree_Range is
   begin
      return C'Length - 1;
   end Degree_Of;

   function Degree_Of (C : Controls_2D) return Degree_Range is
   begin
      return C'Length - 1;
   end Degree_Of;

   function Degree_Of (C : Controls_3D) return Degree_Range is
   begin
      return C'Length - 1;
   end Degree_Of;

   function In_Unit_Interval (T : Float) return Boolean is
   begin
      return T >= 0.0 and then T <= 1.0;
   end In_Unit_Interval;

   ---------------------------------------------------------------------------
   -- Bernstein
   ---------------------------------------------------------------------------

   function Binomial (N, K : Natural) return Float is
      Result : Float := 1.0;
      KK     : Natural := K;
   begin
      if KK > N - KK then
         KK := N - KK;
      end if;
      for I in 1 .. KK loop
         Result := Result * Float (N - KK + I) / Float (I);
      end loop;
      return Result;
   end Binomial;

   function Bernstein (I, N : Natural; T : Float) return Float is
      One_Minus : constant Float := 1.0 - T;
      Pow_T     : Float := 1.0;
      Pow_S     : Float := 1.0;
   begin
      for J in 1 .. I loop
         Pow_T := Pow_T * T;
      end loop;
      for J in 1 .. (N - I) loop
         Pow_S := Pow_S * One_Minus;
      end loop;
      return Binomial (N, I) * Pow_S * Pow_T;
   end Bernstein;

   function Evaluate_Bernstein
     (Controls : Controls_1D; T : Float) return Eval_Result_1D
   is
      Len  : constant Natural := Controls'Length;
      Stat : constant Status := Check_Controls_Len (Len);
      N    : Degree_Range;
      Acc  : Float := 0.0;
      Lo   : Control_Index;
   begin
      if Stat /= Ok then
         return (Value => 0.0, Stat => Stat, Success => False);
      end if;
      N  := Len - 1;
      Lo := Controls'First;
      for I in 0 .. N loop
         Acc := Acc + Controls (Lo + I) * Bernstein (I, N, T);
      end loop;
      return
        (Value => Acc, Stat => Classify_T (T), Success => True);
   end Evaluate_Bernstein;

   function Evaluate_Bernstein
     (Controls : Controls_2D; T : Float) return Eval_Result_2D
   is
      Len  : constant Natural := Controls'Length;
      Stat : constant Status := Check_Controls_Len (Len);
      N    : Degree_Range;
      Acc  : Point_2D := (0.0, 0.0);
      Lo   : Control_Index;
      W    : Float;
   begin
      if Stat /= Ok then
         return (Point => (0.0, 0.0), Stat => Stat, Success => False);
      end if;
      N  := Len - 1;
      Lo := Controls'First;
      for I in 0 .. N loop
         W   := Bernstein (I, N, T);
         Acc := Add (Acc, Scale (Controls (Lo + I), W));
      end loop;
      return
        (Point => Acc, Stat => Classify_T (T), Success => True);
   end Evaluate_Bernstein;

   function Evaluate_Bernstein
     (Controls : Controls_3D; T : Float) return Eval_Result_3D
   is
      Len  : constant Natural := Controls'Length;
      Stat : constant Status := Check_Controls_Len (Len);
      N    : Degree_Range;
      Acc  : Point_3D := (0.0, 0.0, 0.0);
      Lo   : Control_Index;
      W    : Float;
   begin
      if Stat /= Ok then
         return
           (Point => (0.0, 0.0, 0.0), Stat => Stat, Success => False);
      end if;
      N  := Len - 1;
      Lo := Controls'First;
      for I in 0 .. N loop
         W   := Bernstein (I, N, T);
         Acc := Add (Acc, Scale (Controls (Lo + I), W));
      end loop;
      return
        (Point => Acc, Stat => Classify_T (T), Success => True);
   end Evaluate_Bernstein;

   ---------------------------------------------------------------------------
   -- De Casteljau Evaluate
   ---------------------------------------------------------------------------

   function Evaluate
     (Controls : Controls_1D; T : Float) return Eval_Result_1D
   is
      Len  : constant Natural := Controls'Length;
      Stat : constant Status := Check_Controls_Len (Len);
      N    : Degree_Range;
      Work : Controls_1D (0 .. Max_Degree);
      Lo   : Control_Index;
   begin
      if Stat /= Ok then
         return (Value => 0.0, Stat => Stat, Success => False);
      end if;
      N  := Len - 1;
      Lo := Controls'First;
      for I in 0 .. N loop
         Work (I) := Controls (Lo + I);
      end loop;
      for R in 1 .. N loop
         for I in 0 .. N - R loop
            Work (I) := Lerp (Work (I), Work (I + 1), T);
         end loop;
      end loop;
      return
        (Value => Work (0), Stat => Classify_T (T), Success => True);
   end Evaluate;

   function Evaluate
     (Controls : Controls_2D; T : Float) return Eval_Result_2D
   is
      Len  : constant Natural := Controls'Length;
      Stat : constant Status := Check_Controls_Len (Len);
      N    : Degree_Range;
      Work : Controls_2D (0 .. Max_Degree);
      Lo   : Control_Index;
   begin
      if Stat /= Ok then
         return (Point => (0.0, 0.0), Stat => Stat, Success => False);
      end if;
      N  := Len - 1;
      Lo := Controls'First;
      for I in 0 .. N loop
         Work (I) := Controls (Lo + I);
      end loop;
      for R in 1 .. N loop
         for I in 0 .. N - R loop
            Work (I) := Lerp (Work (I), Work (I + 1), T);
         end loop;
      end loop;
      return
        (Point => Work (0), Stat => Classify_T (T), Success => True);
   end Evaluate;

   function Evaluate
     (Controls : Controls_3D; T : Float) return Eval_Result_3D
   is
      Len  : constant Natural := Controls'Length;
      Stat : constant Status := Check_Controls_Len (Len);
      N    : Degree_Range;
      Work : Controls_3D (0 .. Max_Degree);
      Lo   : Control_Index;
   begin
      if Stat /= Ok then
         return
           (Point => (0.0, 0.0, 0.0), Stat => Stat, Success => False);
      end if;
      N  := Len - 1;
      Lo := Controls'First;
      for I in 0 .. N loop
         Work (I) := Controls (Lo + I);
      end loop;
      for R in 1 .. N loop
         for I in 0 .. N - R loop
            Work (I) := Lerp (Work (I), Work (I + 1), T);
         end loop;
      end loop;
      return
        (Point => Work (0), Stat => Classify_T (T), Success => True);
   end Evaluate;

   ---------------------------------------------------------------------------
   -- Split
   ---------------------------------------------------------------------------

   function Split
     (Controls : Controls_1D; T : Float) return Split_Result_1D
   is
      Len  : constant Natural := Controls'Length;
      Stat : constant Status := Check_Controls_Len (Len);
      N    : Degree_Range;
      Work : Controls_1D (0 .. Max_Degree);
      Res  : Split_Result_1D;
      Lo   : Control_Index;
   begin
      if Stat /= Ok then
         Res.Stat    := Stat;
         Res.Success := False;
         return Res;
      end if;
      N  := Len - 1;
      Lo := Controls'First;
      for I in 0 .. N loop
         Work (I) := Controls (Lo + I);
      end loop;
      Res.Left (0) := Work (0);
      for R in 1 .. N loop
         for I in 0 .. N - R loop
            Work (I) := Lerp (Work (I), Work (I + 1), T);
         end loop;
         Res.Left (R) := Work (0);
      end loop;
      --  Rebuild pyramid once more to harvest the right polygon.
      --  Right[j] = P_j^{(n-j)}. Recompute by storing diagonals.
      for I in 0 .. N loop
         Work (I) := Controls (Lo + I);
      end loop;
      Res.Right (N) := Work (N);
      for R in 1 .. N loop
         for I in 0 .. N - R loop
            Work (I) := Lerp (Work (I), Work (I + 1), T);
         end loop;
         --  After row R, Work (N-R) is P_{N-R}^{(R)} = Right entry.
         Res.Right (N - R) := Work (N - R);
      end loop;
      Res.Degree  := N;
      Res.Stat    := Classify_T (T);
      Res.Success := True;
      return Res;
   end Split;

   function Split
     (Controls : Controls_2D; T : Float) return Split_Result_2D
   is
      Len  : constant Natural := Controls'Length;
      Stat : constant Status := Check_Controls_Len (Len);
      N    : Degree_Range;
      Work : Controls_2D (0 .. Max_Degree);
      Res  : Split_Result_2D;
      Lo   : Control_Index;
   begin
      if Stat /= Ok then
         Res.Stat    := Stat;
         Res.Success := False;
         return Res;
      end if;
      N  := Len - 1;
      Lo := Controls'First;
      for I in 0 .. N loop
         Work (I) := Controls (Lo + I);
      end loop;
      Res.Left (0) := Work (0);
      for R in 1 .. N loop
         for I in 0 .. N - R loop
            Work (I) := Lerp (Work (I), Work (I + 1), T);
         end loop;
         Res.Left (R) := Work (0);
      end loop;
      for I in 0 .. N loop
         Work (I) := Controls (Lo + I);
      end loop;
      Res.Right (N) := Work (N);
      for R in 1 .. N loop
         for I in 0 .. N - R loop
            Work (I) := Lerp (Work (I), Work (I + 1), T);
         end loop;
         Res.Right (N - R) := Work (N - R);
      end loop;
      Res.Degree  := N;
      Res.Stat    := Classify_T (T);
      Res.Success := True;
      return Res;
   end Split;

   function Split
     (Controls : Controls_3D; T : Float) return Split_Result_3D
   is
      Len  : constant Natural := Controls'Length;
      Stat : constant Status := Check_Controls_Len (Len);
      N    : Degree_Range;
      Work : Controls_3D (0 .. Max_Degree);
      Res  : Split_Result_3D;
      Lo   : Control_Index;
   begin
      if Stat /= Ok then
         Res.Stat    := Stat;
         Res.Success := False;
         return Res;
      end if;
      N  := Len - 1;
      Lo := Controls'First;
      for I in 0 .. N loop
         Work (I) := Controls (Lo + I);
      end loop;
      Res.Left (0) := Work (0);
      for R in 1 .. N loop
         for I in 0 .. N - R loop
            Work (I) := Lerp (Work (I), Work (I + 1), T);
         end loop;
         Res.Left (R) := Work (0);
      end loop;
      for I in 0 .. N loop
         Work (I) := Controls (Lo + I);
      end loop;
      Res.Right (N) := Work (N);
      for R in 1 .. N loop
         for I in 0 .. N - R loop
            Work (I) := Lerp (Work (I), Work (I + 1), T);
         end loop;
         Res.Right (N - R) := Work (N - R);
      end loop;
      Res.Degree  := N;
      Res.Stat    := Classify_T (T);
      Res.Success := True;
      return Res;
   end Split;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Make_Point (X, Y : Float) return Point_2D is
   begin
      return (X => X, Y => Y);
   end Make_Point;

   function Make_Point (X, Y, Z : Float) return Point_3D is
   begin
      return (X => X, Y => Y, Z => Z);
   end Make_Point;

   function Make_Line_1D (A, B : Float) return Controls_1D is
   begin
      return Controls_1D'(0 => A, 1 => B);
   end Make_Line_1D;

   function Make_Line_2D (P0, P1 : Point_2D) return Controls_2D is
   begin
      return Controls_2D'(0 => P0, 1 => P1);
   end Make_Line_2D;

   function Make_Line_3D (P0, P1 : Point_3D) return Controls_3D is
   begin
      return Controls_3D'(0 => P0, 1 => P1);
   end Make_Line_3D;

   function Make_Quadratic_2D
     (P0, P1, P2 : Point_2D) return Controls_2D
   is
   begin
      return Controls_2D'(0 => P0, 1 => P1, 2 => P2);
   end Make_Quadratic_2D;

   function Make_Cubic_2D
     (P0, P1, P2, P3 : Point_2D) return Controls_2D
   is
   begin
      return Controls_2D'(0 => P0, 1 => P1, 2 => P2, 3 => P3);
   end Make_Cubic_2D;

   function Make_Cubic_3D
     (P0, P1, P2, P3 : Point_3D) return Controls_3D
   is
   begin
      return Controls_3D'(0 => P0, 1 => P1, 2 => P2, 3 => P3);
   end Make_Cubic_3D;

   function Make_Example_2D (Kind : Example_Kind) return Controls_2D is
   begin
      case Kind is
         when Line_Segment =>
            return Make_Line_2D
              (Make_Point (0.0, 0.0), Make_Point (1.0, 0.0));
         when Quadratic_Arch =>
            return Make_Quadratic_2D
              (Make_Point (0.0, 0.0),
               Make_Point (0.5, 1.0),
               Make_Point (1.0, 0.0));
         when Cubic_Unit_Square =>
            return Make_Cubic_2D
              (Make_Point (0.0, 0.0),
               Make_Point (0.0, 1.0),
               Make_Point (1.0, 1.0),
               Make_Point (1.0, 0.0));
         when Cubic_S_Curve =>
            return Make_Cubic_2D
              (Make_Point (0.0, 0.0),
               Make_Point (1.0, 0.0),
               Make_Point (0.0, 1.0),
               Make_Point (1.0, 1.0));
      end case;
   end Make_Example_2D;

   function Make_Example_1D (Kind : Example_Kind) return Controls_1D is
   begin
      case Kind is
         when Line_Segment =>
            return Make_Line_1D (0.0, 1.0);
         when Quadratic_Arch =>
            return Controls_1D'(0 => 0.0, 1 => 0.5, 2 => 1.0);
         when Cubic_Unit_Square =>
            return Controls_1D'(0 => 0.0, 1 => 0.0, 2 => 1.0, 3 => 1.0);
         when Cubic_S_Curve =>
            return Controls_1D'(0 => 0.0, 1 => 1.0, 2 => 0.0, 3 => 1.0);
      end case;
   end Make_Example_1D;

end De_Casteljau;
