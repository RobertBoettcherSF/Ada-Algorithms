--  Monotone_Cubic_Interpolation body — Fritsch–Carlson monotone cubic
--  Hermite, plain FD Hermite, and piecewise linear; educational Float.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Monotone_Cubic_Interpolation
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Elementary_Functions;

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

   function Lerp (A, B : Float; T : Float) return Float is
   begin
      return (1.0 - T) * A + T * B;
   end Lerp;

   function Make_Point (X, Y : Float) return Point is
   begin
      return (X => X, Y => Y);
   end Make_Point;

   function H00 (T : Float) return Float is
      T2 : constant Float := T * T;
      T3 : constant Float := T2 * T;
   begin
      return 2.0 * T3 - 3.0 * T2 + 1.0;
   end H00;

   function H10 (T : Float) return Float is
      T2 : constant Float := T * T;
      T3 : constant Float := T2 * T;
   begin
      return T3 - 2.0 * T2 + T;
   end H10;

   function H01 (T : Float) return Float is
      T2 : constant Float := T * T;
      T3 : constant Float := T2 * T;
   begin
      return -2.0 * T3 + 3.0 * T2;
   end H01;

   function H11 (T : Float) return Float is
      T2 : constant Float := T * T;
      T3 : constant Float := T2 * T;
   begin
      return T3 - T2;
   end H11;

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

   function Is_Monotone_Samples (Y : Ordinates) return Boolean is
      Non_Dec : Boolean := True;
      Non_Inc : Boolean := True;
   begin
      if Y'Length < 2 then
         return True;
      end if;
      for I in Y'First .. Y'Last - 1 loop
         if Y (I + 1) < Y (I) then
            Non_Dec := False;
         end if;
         if Y (I + 1) > Y (I) then
            Non_Inc := False;
         end if;
      end loop;
      return Non_Dec or else Non_Inc;
   end Is_Monotone_Samples;

   function Is_Monotone_Samples (P : Points) return Boolean is
      Y : Ordinates (P'Range);
   begin
      for I in P'Range loop
         Y (I) := P (I).Y;
      end loop;
      return Is_Monotone_Samples (Y);
   end Is_Monotone_Samples;

   function In_Domain (S : Spline; X : Float) return Boolean is
   begin
      if not S.Valid or else S.N < 1 then
         return False;
      end if;
      return X >= S.X (0) and then X <= S.X (S.N);
   end In_Domain;

   function Find_Interval (S : Spline; X : Float) return Natural is
      Lo  : Natural := 0;
      Hi  : Natural := S.N;
      Mid : Natural;
   begin
      if X >= S.X (S.N) then
         return S.N - 1;
      end if;
      if X <= S.X (0) then
         return 0;
      end if;
      while Hi - Lo > 1 loop
         Mid := (Lo + Hi) / 2;
         if S.X (Mid) <= X then
            Lo := Mid;
         else
            Hi := Mid;
         end if;
      end loop;
      return Lo;
   end Find_Interval;

   -------------------------------------------------------------------------
   -- Internal: copy points into a Spline shell
   -------------------------------------------------------------------------

   function Copy_Points
     (X : Abscissae; Y : Ordinates; Kind : Spline_Kind) return Fit_Result
   is
      R : Fit_Result;
      N : Natural;
   begin
      R.Stat := Ill_Started;
      R.Success := False;

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
      R.S.Kind := Kind;
      R.S.N := N;
      R.S.Valid := False;
      R.S.M := [others => 0.0];

      for I in 0 .. N loop
         R.S.X (I) := X (X'First + I);
         R.S.Y (I) := Y (Y'First + I);
      end loop;

      if not Is_Strictly_Increasing (R.S.X (0 .. N)) then
         R.Stat := Not_Strictly_Increasing;
         return R;
      end if;

      R.Stat := Ok;
      return R;
   end Copy_Points;

   -------------------------------------------------------------------------
   -- Secants and finite-difference / Fritsch–Carlson tangents
   -------------------------------------------------------------------------

   --  Compute provisional FD tangents into M(0..N); Dx(0..N-1) = δ_i.
   procedure Compute_FD_Tangents
     (X     : Abscissae;
      Y     : Ordinates;
      N     : Natural;
      Dx : out Ordinates;
      M     : out Tangents)
   is
   begin
      Dx := [others => 0.0];
      M := [others => 0.0];

      for I in 0 .. N - 1 loop
         Dx (I) := (Y (I + 1) - Y (I)) / (X (I + 1) - X (I));
      end loop;

      M (0) := Dx (0);
      M (N) := Dx (N - 1);

      for K in 1 .. N - 1 loop
         --  Opposite-sign adjacent secants → local extremum → m_k = 0.
         if Dx (K - 1) * Dx (K) < 0.0 then
            M (K) := 0.0;
         elsif abs (Dx (K - 1)) < Epsilon_Tol
           and then abs (Dx (K)) < Epsilon_Tol
         then
            M (K) := 0.0;
         else
            M (K) := 0.5 * (Dx (K - 1) + Dx (K));
         end if;
      end loop;
   end Compute_FD_Tangents;

   --  Fritsch–Carlson restrict on provisional M / Dx (wiki circle of r=3).
   procedure Fritsch_Carlson_Restrict
     (N     : Natural;
      Dx : Ordinates;
      M     : in out Tangents)
   is
      Alpha, Beta, Tau, Sum_Sq : Float;
      Flat : array (0 .. Max_Points - 2) of Boolean := [others => False];
   begin
      --  Flat intervals: δ_k ≈ 0 → m_k = m_{k+1} = 0; skip α/β for those k.
      for K in 0 .. N - 1 loop
         if abs (Dx (K)) < Epsilon_Tol then
            M (K) := 0.0;
            M (K + 1) := 0.0;
            Flat (K) := True;
         end if;
      end loop;

      for K in 0 .. N - 1 loop
         if Flat (K) then
            null;
         else
            Alpha := M (K) / Dx (K);
            Beta  := M (K + 1) / Dx (K);

            --  Negative α or β → local extremum; zero the offending tangent.
            if Alpha < 0.0 then
               M (K) := 0.0;
               Alpha := 0.0;
            end if;
            if Beta < 0.0 then
               M (K + 1) := 0.0;
               Beta := 0.0;
            end if;

            --  Circle restrict: if α²+β² > 9, scale by τ = 3/√(α²+β²).
            Sum_Sq := Alpha * Alpha + Beta * Beta;
            if Sum_Sq > 9.0 then
               Tau := 3.0 / Math.Sqrt (Sum_Sq);
               M (K)     := Tau * Alpha * Dx (K);
               M (K + 1) := Tau * Beta  * Dx (K);
            end if;
         end if;
      end loop;
   end Fritsch_Carlson_Restrict;

   -------------------------------------------------------------------------
   -- Fitters
   -------------------------------------------------------------------------

   function Fit_Monotone
     (X : Abscissae; Y : Ordinates) return Fit_Result
   is
      R     : Fit_Result := Copy_Points (X, Y, Monotone_Cubic);
      Dx : Ordinates (0 .. Max_Points - 1);
      M     : Tangents (0 .. Max_Points - 1);
      N     : Natural;
   begin
      if R.Stat /= Ok then
         return R;
      end if;

      N := R.S.N;
      Compute_FD_Tangents
        (R.S.X (0 .. N), R.S.Y (0 .. N), N, Dx, M);
      Fritsch_Carlson_Restrict (N, Dx, M);

      for I in 0 .. N loop
         R.S.M (I) := M (I);
      end loop;

      R.S.Valid := True;
      R.Success := True;
      R.Stat := Ok;
      return R;
   end Fit_Monotone;

   function Fit
     (X : Abscissae; Y : Ordinates) return Fit_Result
   is
   begin
      return Fit_Monotone (X, Y);
   end Fit;

   function Fit (P : Points) return Fit_Result is
      X : Abscissae (P'Range);
      Y : Ordinates (P'Range);
   begin
      if P'Length = 0 then
         declare
            R : Fit_Result;
         begin
            R.Stat := Ill_Started;
            return R;
         end;
      end if;
      for I in P'Range loop
         X (I) := P (I).X;
         Y (I) := P (I).Y;
      end loop;
      return Fit (X, Y);
   end Fit;

   function Fit_Monotone (P : Points) return Fit_Result is
   begin
      return Fit (P);
   end Fit_Monotone;

   function Fit_Hermite_FD
     (X : Abscissae; Y : Ordinates) return Fit_Result
   is
      R     : Fit_Result :=
                Copy_Points (X, Y, Finite_Difference_Hermite);
      Dx : Ordinates (0 .. Max_Points - 1);
      M     : Tangents (0 .. Max_Points - 1);
      N     : Natural;
   begin
      if R.Stat /= Ok then
         return R;
      end if;

      N := R.S.N;
      Compute_FD_Tangents
        (R.S.X (0 .. N), R.S.Y (0 .. N), N, Dx, M);

      --  Still flatten exact-zero secants (undefined α/β), but no circle
      --  restrict — this is the non-monotone contrast method.
      for K in 0 .. N - 1 loop
         if abs (Dx (K)) < Epsilon_Tol then
            M (K) := 0.0;
            M (K + 1) := 0.0;
         end if;
      end loop;

      for I in 0 .. N loop
         R.S.M (I) := M (I);
      end loop;

      R.S.Valid := True;
      R.Success := True;
      R.Stat := Ok;
      return R;
   end Fit_Hermite_FD;

   function Fit_Hermite_FD (P : Points) return Fit_Result is
      X : Abscissae (P'Range);
      Y : Ordinates (P'Range);
   begin
      if P'Length = 0 then
         declare
            R : Fit_Result;
         begin
            R.Stat := Ill_Started;
            return R;
         end;
      end if;
      for I in P'Range loop
         X (I) := P (I).X;
         Y (I) := P (I).Y;
      end loop;
      return Fit_Hermite_FD (X, Y);
   end Fit_Hermite_FD;

   function Fit_Linear
     (X : Abscissae; Y : Ordinates) return Fit_Result
   is
      R : Fit_Result := Copy_Points (X, Y, Linear);
   begin
      if R.Stat /= Ok then
         return R;
      end if;
      R.S.M := [others => 0.0];
      R.S.Valid := True;
      R.Success := True;
      R.Stat := Ok;
      return R;
   end Fit_Linear;

   function Fit_Linear (P : Points) return Fit_Result is
      X : Abscissae (P'Range);
      Y : Ordinates (P'Range);
   begin
      if P'Length = 0 then
         declare
            R : Fit_Result;
         begin
            R.Stat := Ill_Started;
            return R;
         end;
      end if;
      for I in P'Range loop
         X (I) := P (I).X;
         Y (I) := P (I).Y;
      end loop;
      return Fit_Linear (X, Y);
   end Fit_Linear;

   -------------------------------------------------------------------------
   -- Evaluation
   -------------------------------------------------------------------------

   function Evaluate (S : Spline; X : Float) return Eval_Result is
      R     : Eval_Result;
      I     : Natural;
      Dx : Float;
      T     : Float;
   begin
      R.Value := 0.0;
      R.Stat := Ill_Started;
      R.Success := False;

      if not S.Valid or else S.N < 1 then
         return R;
      end if;

      if X < S.X (0) or else X > S.X (S.N) then
         R.Stat := Out_Of_Domain;
         return R;
      end if;

      I := Find_Interval (S, X);
      Dx := S.X (I + 1) - S.X (I);

      if abs (Dx) < Epsilon_Tol then
         R.Value := S.Y (I);
         R.Stat := Ok;
         R.Success := True;
         return R;
      end if;

      T := (X - S.X (I)) / Dx;

      case S.Kind is
         when Linear =>
            R.Value := Lerp (S.Y (I), S.Y (I + 1), T);
         when Monotone_Cubic | Finite_Difference_Hermite =>
            R.Value :=
              S.Y (I) * H00 (T)
              + Dx * S.M (I) * H10 (T)
              + S.Y (I + 1) * H01 (T)
              + Dx * S.M (I + 1) * H11 (T);
      end case;

      R.Stat := Ok;
      R.Success := True;
      return R;
   end Evaluate;

   -------------------------------------------------------------------------
   -- Builders
   -------------------------------------------------------------------------

   function Make_Linear_Data
     (N : Point_Count; X0, X1, Y0, Y1 : Float) return Points
   is
      P : Points (0 .. N - 1);
      T : Float;
   begin
      for I in 0 .. N - 1 loop
         if N = 1 then
            T := 0.0;
         else
            T := Float (I) / Float (N - 1);
         end if;
         P (I).X := Lerp (X0, X1, T);
         P (I).Y := Lerp (Y0, Y1, T);
      end loop;
      return P;
   end Make_Linear_Data;

   function Make_Increasing_Ramp
     (N : Point_Count; X0, X1, Y0, Y1 : Float) return Points
   is
   begin
      return Make_Linear_Data (N, X0, X1, Y0, Y1);
   end Make_Increasing_Ramp;

   function Make_Sigmoid_Sample
     (N : Point_Count; X0, X1 : Float) return Points
   is
      P : Points (0 .. N - 1);
      T, U, Z : Float;
   begin
      for I in 0 .. N - 1 loop
         T := Float (I) / Float (N - 1);
         P (I).X := Lerp (X0, X1, T);
         U := T;  -- parameter in [0,1]
         Z := -4.0 * (2.0 * U - 1.0);
         P (I).Y := 1.0 / (1.0 + Math.Exp (Z));
      end loop;
      return P;
   end Make_Sigmoid_Sample;

   function Make_Non_Monotone_Sample
     (N : Point_Count; X0, X1 : Float) return Points
   is
      P : Points (0 .. N - 1);
      T : Float;
      Two_Pi : constant Float := 2.0 * Ada.Numerics.Pi;
   begin
      for I in 0 .. N - 1 loop
         T := Float (I) / Float (N - 1);
         P (I).X := Lerp (X0, X1, T);
         P (I).Y := Math.Sin (Two_Pi * T);
      end loop;
      return P;
   end Make_Non_Monotone_Sample;

   function Make_Example (Kind : Example_Kind) return Points is
   begin
      case Kind is
         when Linear_Data =>
            return Make_Linear_Data (5, 0.0, 4.0, 1.0, 9.0);
         when Increasing_Ramp =>
            return Make_Increasing_Ramp (8, 0.0, 1.0, 0.0, 1.0);
         when Sigmoid_Sample =>
            return Make_Sigmoid_Sample (9, -2.0, 2.0);
         when Non_Monotone_Sample =>
            return Make_Non_Monotone_Sample (9, 0.0, 1.0);
      end case;
   end Make_Example;

   procedure Split_XY
     (P : Points; X : out Abscissae; Y : out Ordinates)
   is
   begin
      for I in P'Range loop
         X (X'First + (I - P'First)) := P (I).X;
         Y (Y'First + (I - P'First)) := P (I).Y;
      end loop;
   end Split_XY;

end Monotone_Cubic_Interpolation;
