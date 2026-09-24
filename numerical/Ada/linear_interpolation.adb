--  Linear_Interpolation body — two-point lerp, piecewise-linear tables,
--  optional extrapolation, and inverse lerp; educational Float.

pragma Ada_2022;

package body Linear_Interpolation
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near (A, B : Point; Tol : Float := Near_Tol) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near;

   function Make_Point (X, Y : Float) return Point is
   begin
      return (X => X, Y => Y);
   end Make_Point;

   function Clamp_01 (T : Float) return Float is
   begin
      if T < 0.0 then
         return 0.0;
      elsif T > 1.0 then
         return 1.0;
      else
         return T;
      end if;
   end Clamp_01;

   function Lerp_Unclamped (A, B : Float; T : Float) return Float is
   begin
      return (1.0 - T) * A + T * B;
   end Lerp_Unclamped;

   function Lerp (A, B : Float; T : Float) return Float is
   begin
      return Lerp_Unclamped (A, B, Clamp_01 (T));
   end Lerp;

   function Inverse_Lerp (A, B, V : Float) return Eval_Result is
      R : Eval_Result;
   begin
      if Near (A, B, Epsilon_Tol) then
         R.Stat := Singular;
         R.Success := False;
         R.Value := 0.0;
         return R;
      end if;
      R.Value := (V - A) / (B - A);
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Inverse_Lerp;

   function Interpolate_Two_Points
     (X0, Y0, X1, Y1, X : Float) return Eval_Result
   is
      R : Eval_Result;
      Dx : constant Float := X1 - X0;
   begin
      if abs (Dx) <= Epsilon_Tol then
         R.Stat := Singular;
         R.Success := False;
         R.Value := 0.0;
         return R;
      end if;
      --  y = y0 + (x − x0) · (y1 − y0) / (x1 − x0)
      R.Value := Y0 + (X - X0) * (Y1 - Y0) / Dx;
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Interpolate_Two_Points;

   function Is_Strictly_Increasing (X : Abscissae) return Boolean is
   begin
      if X'Length < 2 then
         return True;
      end if;
      for I in X'First .. X'Last - 1 loop
         if X (I + 1) <= X (I) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Strictly_Increasing;

   function Is_Strictly_Monotone (Y : Ordinates) return Boolean is
      Strict_Inc : Boolean := True;
      Strict_Dec : Boolean := True;
   begin
      if Y'Length < 2 then
         return True;
      end if;
      for I in Y'First .. Y'Last - 1 loop
         if Y (I + 1) <= Y (I) then
            Strict_Inc := False;
         end if;
         if Y (I + 1) >= Y (I) then
            Strict_Dec := False;
         end if;
      end loop;
      return Strict_Inc or else Strict_Dec;
   end Is_Strictly_Monotone;

   function Is_Strictly_Monotone (P : Points) return Boolean is
      Y : Ordinates (P'Range);
   begin
      for I in P'Range loop
         Y (I) := P (I).Y;
      end loop;
      return Is_Strictly_Monotone (Y);
   end Is_Strictly_Monotone;

   function In_Domain (T : Table; X : Float) return Boolean is
   begin
      if not T.Valid or else T.N < 1 then
         return False;
      end if;
      return X >= T.X (0) and then X <= T.X (T.N);
   end In_Domain;

   function Find_Interval (T : Table; X : Float) return Natural is
      Lo  : Natural := 0;
      Hi  : Natural := T.N;
      Mid : Natural;
   begin
      if X >= T.X (T.N) then
         return T.N - 1;
      end if;
      if X <= T.X (0) then
         return 0;
      end if;
      while Hi - Lo > 1 loop
         Mid := (Lo + Hi) / 2;
         if T.X (Mid) <= X then
            Lo := Mid;
         else
            Hi := Mid;
         end if;
      end loop;
      return Lo;
   end Find_Interval;

   -------------------------------------------------------------------------
   -- Fit
   -------------------------------------------------------------------------

   function Fit
     (X            : Abscissae;
      Y            : Ordinates;
      Extrapolate  : Boolean := False) return Fit_Result
   is
      R : Fit_Result;
      N : Natural;
   begin
      R.Stat := Ill_Started;
      R.Success := False;
      R.T.Valid := False;
      R.T.Extrapolate := Extrapolate;

      if X'Length = 0 or else Y'Length = 0 then
         return R;
      end if;
      if X'Length /= Y'Length then
         return R;
      end if;
      if X'Length > Max_Points then
         return R;
      end if;
      if X'Length < 2 then
         R.Stat := Too_Few_Points;
         return R;
      end if;

      N := X'Length - 1;
      R.T.N := N;

      for I in 0 .. N loop
         R.T.X (I) := X (X'First + I);
         R.T.Y (I) := Y (Y'First + I);
      end loop;

      if not Is_Strictly_Increasing (R.T.X (0 .. N)) then
         R.Stat := Duplicate_Or_Unordered;
         return R;
      end if;

      R.T.Valid := True;
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Fit;

   function Fit
     (P            : Points;
      Extrapolate  : Boolean := False) return Fit_Result
   is
      X : Abscissae (P'Range);
      Y : Ordinates (P'Range);
   begin
      if P'Length = 0 then
         declare
            R : Fit_Result;
         begin
            R.Stat := Ill_Started;
            R.Success := False;
            return R;
         end;
      end if;
      for I in P'Range loop
         X (I) := P (I).X;
         Y (I) := P (I).Y;
      end loop;
      return Fit (X, Y, Extrapolate);
   end Fit;

   -------------------------------------------------------------------------
   -- Evaluate
   -------------------------------------------------------------------------

   function Evaluate (T : Table; X : Float) return Eval_Result is
      R  : Eval_Result;
      I  : Natural;
      Dx : Float;
      Tt : Float;
   begin
      if not T.Valid or else T.N < 1 then
         R.Stat := Ill_Started;
         R.Success := False;
         return R;
      end if;

      if not In_Domain (T, X) then
         if not T.Extrapolate then
            R.Stat := Out_Of_Domain;
            R.Success := False;
            return R;
         end if;
         --  Extrapolate on the nearest end segment.
      end if;

      I := Find_Interval (T, X);
      Dx := T.X (I + 1) - T.X (I);
      if abs (Dx) <= Epsilon_Tol then
         --  Should not occur after Fit validation; defensive Singular.
         R.Stat := Singular;
         R.Success := False;
         return R;
      end if;

      Tt := (X - T.X (I)) / Dx;
      R.Value := Lerp_Unclamped (T.Y (I), T.Y (I + 1), Tt);
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Evaluate;

   --  Find interval in Y for inverse: largest i with Y in the segment
   --  [min(Y_i,Y_{i+1}), max(Y_i,Y_{i+1})] preferring the first hit.
   function Find_Y_Interval (T : Table; Y : Float) return Natural is
      Ya, Yb : Float;
   begin
      --  Prefer endpoint segments when outside (for extrapolation).
      if Y <= Float'Min (T.Y (0), T.Y (T.N)) then
         if T.Y (0) <= T.Y (T.N) then
            return 0;           -- increasing: below → first
         else
            return T.N - 1;     -- decreasing: below → last
         end if;
      end if;
      if Y >= Float'Max (T.Y (0), T.Y (T.N)) then
         if T.Y (0) <= T.Y (T.N) then
            return T.N - 1;     -- increasing: above → last
         else
            return 0;           -- decreasing: above → first
         end if;
      end if;

      for I in 0 .. T.N - 1 loop
         Ya := T.Y (I);
         Yb := T.Y (I + 1);
         if (Y >= Ya and then Y <= Yb)
           or else (Y >= Yb and then Y <= Ya)
         then
            return I;
         end if;
      end loop;
      return T.N - 1;
   end Find_Y_Interval;

   function Inverse_Evaluate (T : Table; Y : Float) return Eval_Result is
      R     : Eval_Result;
      I     : Natural;
      Inv   : Eval_Result;
      Y_Min : Float;
      Y_Max : Float;
      In_Y  : Boolean;
   begin
      if not T.Valid or else T.N < 1 then
         R.Stat := Ill_Started;
         R.Success := False;
         return R;
      end if;

      if not Is_Strictly_Monotone (T.Y (0 .. T.N)) then
         R.Stat := Singular;
         R.Success := False;
         return R;
      end if;

      Y_Min := Float'Min (T.Y (0), T.Y (T.N));
      Y_Max := Float'Max (T.Y (0), T.Y (T.N));
      In_Y := Y >= Y_Min and then Y <= Y_Max;

      if not In_Y and then not T.Extrapolate then
         R.Stat := Out_Of_Domain;
         R.Success := False;
         return R;
      end if;

      I := Find_Y_Interval (T, Y);
      Inv := Inverse_Lerp (T.Y (I), T.Y (I + 1), Y);
      if not Inv.Success then
         R.Stat := Singular;
         R.Success := False;
         return R;
      end if;

      R.Value := Lerp_Unclamped (T.X (I), T.X (I + 1), Inv.Value);
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Inverse_Evaluate;

   -------------------------------------------------------------------------
   -- Builders
   -------------------------------------------------------------------------

   function Make_Linear_Data
     (N : Point_Count; X0, X1, Y0, Y1 : Float) return Points
   is
      P : Points (0 .. N - 1);
      U : Float;
   begin
      for I in 0 .. N - 1 loop
         U := Float (I) / Float (N - 1);
         P (I).X := Lerp_Unclamped (X0, X1, U);
         P (I).Y := Lerp_Unclamped (Y0, Y1, U);
      end loop;
      return P;
   end Make_Linear_Data;

   function Make_Increasing_Ramp
     (N : Point_Count; X0, X1, Y0, Y1 : Float) return Points
   is
   begin
      return Make_Linear_Data (N, X0, X1, Y0, Y1);
   end Make_Increasing_Ramp;

   function Make_Decreasing_Ramp
     (N : Point_Count; X0, X1, Y0, Y1 : Float) return Points
   is
   begin
      return Make_Linear_Data (N, X0, X1, Y0, Y1);
   end Make_Decreasing_Ramp;

   function Make_Quadratic_Sample
     (N : Point_Count; X0, X1 : Float) return Points
   is
      P : Points (0 .. N - 1);
      U : Float;
   begin
      for I in 0 .. N - 1 loop
         U := Float (I) / Float (N - 1);
         P (I).X := Lerp_Unclamped (X0, X1, U);
         P (I).Y := U * U;
      end loop;
      return P;
   end Make_Quadratic_Sample;

   function Make_Example (Kind : Example_Kind) return Points is
   begin
      case Kind is
         when Linear_Data =>
            return Make_Linear_Data (5, 0.0, 4.0, 1.0, 9.0);
         when Increasing_Ramp =>
            return Make_Increasing_Ramp (8, 0.0, 1.0, 0.0, 1.0);
         when Decreasing_Ramp =>
            return Make_Decreasing_Ramp (6, 0.0, 5.0, 10.0, 0.0);
         when Quadratic_Sample =>
            return Make_Quadratic_Sample (9, 0.0, 1.0);
      end case;
   end Make_Example;

   procedure Split_XY
     (P : Points; X : out Abscissae; Y : out Ordinates)
   is
   begin
      for I in P'Range loop
         X (I) := P (I).X;
         Y (I) := P (I).Y;
      end loop;
   end Split_XY;

end Linear_Interpolation;
