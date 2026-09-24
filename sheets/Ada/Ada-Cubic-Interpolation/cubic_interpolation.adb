--  Cubic_Interpolation body — Catmull–Rom / Keys, four-point Newton,
--  and thin FD Hermite.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Cubic_Interpolation
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

   function Lerp (A, B : Float; T : Float) return Float is
   begin
      return (1.0 - T) * A + T * B;
   end Lerp;

   --  Uniform Catmull–Rom ≡ Keys cubic convolution with a = −1/2.
   function Cubic_1D
     (P0, P1, P2, P3 : Float; T : Float) return Float
   is
      T2 : constant Float := T * T;
      T3 : constant Float := T2 * T;
   begin
      return 0.5 *
        ((2.0 * P1)
         + (-P0 + P2) * T
         + (2.0 * P0 - 5.0 * P1 + 4.0 * P2 - P3) * T2
         + (-P0 + 3.0 * P1 - 3.0 * P2 + P3) * T3);
   end Cubic_1D;

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

   function Is_Valid_Grid (G : Grid_1D) return Boolean is
   begin
      return G.Valid and then G.N >= 1;
   end Is_Valid_Grid;

   function Large_Enough_Catmull_Rom (G : Grid_1D) return Boolean is
   begin
      return Is_Valid_Grid (G) and then G.N >= 4;
   end Large_Enough_Catmull_Rom;

   function In_Domain (G : Grid_1D; X : Float) return Boolean is
   begin
      if not Is_Valid_Grid (G) then
         return False;
      end if;
      return X >= 0.0 and then X <= Float (G.N - 1);
   end In_Domain;

   function Is_Strictly_Increasing
     (X : Abscissae; Tol : Float := Distinct_Tol) return Boolean
   is
   begin
      if X'Length < 2 then
         return True;
      end if;
      for I in X'First .. X'Last - 1 loop
         if X (I + 1) - X (I) <= Tol then
            return False;
         end if;
      end loop;
      return True;
   end Is_Strictly_Increasing;

   function In_Domain (S : Sample_1D; X : Float) return Boolean is
   begin
      if not S.Valid or else S.N < 1 then
         return False;
      end if;
      return X >= S.X (0) and then X <= S.X (S.N);
   end In_Domain;

   function In_Domain (S : Hermite_Spline; X : Float) return Boolean is
   begin
      if not S.Valid or else S.N < 1 then
         return False;
      end if;
      return X >= S.X (0) and then X <= S.X (S.N);
   end In_Domain;

   function Get (G : Grid_1D; I : Sample_Index) return Float is
   begin
      return G.Values (I);
   end Get;

   procedure Set
     (G     : in out Grid_1D;
      I     : Sample_Index;
      Value : Float)
   is
   begin
      G.Values (I) := Value;
   end Set;

   --  Odd (value) reflection so affine samples stay exact on the closed
   --  domain: V(−1)=2V(0)−V(1), V(N)=2V(N−1)−V(N−2).
   function Sample (G : Grid_1D; I : Integer) return Float
     with Pre => Is_Valid_Grid (G)
   is
      Last : constant Integer := Integer (G.N) - 1;
   begin
      if I < 0 then
         return 2.0 * Sample (G, 0) - Sample (G, -I);
      elsif I > Last then
         return 2.0 * Sample (G, Last) - Sample (G, 2 * Last - I);
      else
         return G.Values (Sample_Index (I));
      end if;
   end Sample;

   procedure Cell_Origin
     (Coord : Float; N : Sample_Count; I0 : out Integer; T : out Float)
     with Pre => N >= 2
   is
      Last : constant Float := Float (N - 1);
   begin
      if Coord >= Last then
         I0 := Integer (N) - 2;
         T  := 1.0;
      elsif Coord <= 0.0 then
         I0 := 0;
         T  := 0.0;
      else
         I0 := Integer (Float'Floor (Coord));
         T  := Coord - Float (I0);
      end if;
   end Cell_Origin;

   ---------------------------------------------------------------------------
   -- Catmull–Rom / Keys on Grid_1D
   ---------------------------------------------------------------------------

   function Evaluate_Catmull_Rom
     (G : Grid_1D; X : Float) return Eval_Result
   is
      R      : Eval_Result;
      I0     : Integer;
      T      : Float;
      P0, P1, P2, P3 : Float;
   begin
      R.Value := 0.0;
      R.Stat := Ill_Started;
      R.Success := False;

      if not Is_Valid_Grid (G) then
         return R;
      end if;
      if G.N < 4 then
         R.Stat := Too_Few_Points;
         return R;
      end if;
      if not In_Domain (G, X) then
         R.Stat := Out_Of_Domain;
         return R;
      end if;

      Cell_Origin (X, G.N, I0, T);
      P0 := Sample (G, I0 - 1);
      P1 := Sample (G, I0);
      P2 := Sample (G, I0 + 1);
      P3 := Sample (G, I0 + 2);
      R.Value := Cubic_1D (P0, P1, P2, P3, T);
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Evaluate_Catmull_Rom;

   ---------------------------------------------------------------------------
   -- Four-point Newton
   ---------------------------------------------------------------------------

   function Interpolate_Four_Points
     (X0, Y0, X1, Y1, X2, Y2, X3, Y3 : Float;
      X                              : Float) return Eval_Result
   is
      R  : Eval_Result;
      A0, A1, A2, A3 : Float;
      D01, D12, D23  : Float;
      D012, D123     : Float;
   begin
      R.Value := 0.0;
      R.Stat := Ill_Started;
      R.Success := False;

      if abs (X1 - X0) <= Distinct_Tol
        or else abs (X2 - X1) <= Distinct_Tol
        or else abs (X3 - X2) <= Distinct_Tol
        or else abs (X2 - X0) <= Distinct_Tol
        or else abs (X3 - X1) <= Distinct_Tol
        or else abs (X3 - X0) <= Distinct_Tol
      then
         R.Stat := Duplicate_Abscissa;
         return R;
      end if;

      --  Newton divided differences for degree ≤ 3.
      A0  := Y0;
      D01 := (Y1 - Y0) / (X1 - X0);
      D12 := (Y2 - Y1) / (X2 - X1);
      D23 := (Y3 - Y2) / (X3 - X2);
      A1  := D01;
      D012 := (D12 - D01) / (X2 - X0);
      D123 := (D23 - D12) / (X3 - X1);
      A2  := D012;
      A3  := (D123 - D012) / (X3 - X0);

      R.Value :=
        A0
        + A1 * (X - X0)
        + A2 * (X - X0) * (X - X1)
        + A3 * (X - X0) * (X - X1) * (X - X2);
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Interpolate_Four_Points;

   function Interpolate_Four_Points
     (X_Data : Abscissae; Y_Data : Ordinates; X : Float) return Eval_Result
   is
      R : Eval_Result;
   begin
      R.Value := 0.0;
      R.Stat := Ill_Started;
      R.Success := False;

      if X_Data'Length = 0 or else Y_Data'Length = 0 then
         return R;
      end if;
      if X_Data'Length /= Y_Data'Length then
         return R;
      end if;
      if X_Data'Length < 4 then
         R.Stat := Too_Few_Points;
         return R;
      end if;
      if X_Data'Length > 4 then
         --  Educational API is exactly four points.
         return R;
      end if;
      if X_Data'First /= Y_Data'First then
         return R;
      end if;

      return Interpolate_Four_Points
        (X_Data (X_Data'First),     Y_Data (Y_Data'First),
         X_Data (X_Data'First + 1), Y_Data (Y_Data'First + 1),
         X_Data (X_Data'First + 2), Y_Data (Y_Data'First + 2),
         X_Data (X_Data'First + 3), Y_Data (Y_Data'First + 3),
         X);
   end Interpolate_Four_Points;

   ---------------------------------------------------------------------------
   -- Thin FD Hermite
   ---------------------------------------------------------------------------

   procedure Compute_FD_Tangents
     (X : Abscissae;
      Y : Ordinates;
      N : Natural;
      M : in out Ordinates)
     with Pre =>
       N >= 1
       and then X'First = 0
       and then Y'First = 0
       and then M'First = 0
       and then X'Last >= N
       and then Y'Last >= N
       and then M'Last >= N
   is
      type Secant_Arr is array (0 .. Max_N - 2) of Float;
      Sec : Secant_Arr := [others => 0.0];
   begin
      for I in 0 .. N - 1 loop
         Sec (I) := (Y (I + 1) - Y (I)) / (X (I + 1) - X (I));
      end loop;
      M (0) := Sec (0);
      M (N) := Sec (N - 1);
      if N >= 2 then
         for K in 1 .. N - 1 loop
            M (K) := 0.5 * (Sec (K - 1) + Sec (K));
         end loop;
      end if;
   end Compute_FD_Tangents;

   function Fit_FD
     (X : Abscissae; Y : Ordinates) return Fit_Result
   is
      R : Fit_Result;
      N : Natural;
   begin
      R.Stat := Ill_Started;
      R.Success := False;
      R.S.Valid := False;
      R.S.M := [others => 0.0];

      if X'Length = 0 or else Y'Length = 0 then
         return R;
      end if;
      if X'Length /= Y'Length then
         return R;
      end if;
      if X'Length > Max_N then
         return R;
      end if;
      if X'Length < 2 then
         R.Stat := Too_Few_Points;
         return R;
      end if;

      N := X'Length - 1;
      R.S.N := N;
      for I in 0 .. N loop
         R.S.X (I) := X (X'First + I);
         R.S.Y (I) := Y (Y'First + I);
      end loop;

      if not Is_Strictly_Increasing (R.S.X (0 .. N)) then
         R.Stat := Duplicate_Abscissa;
         return R;
      end if;

      Compute_FD_Tangents (R.S.X, R.S.Y, N, R.S.M);
      R.S.Valid := True;
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Fit_FD;

   function Find_Interval (S : Hermite_Spline; X : Float) return Natural
     with Pre => S.Valid and then S.N >= 1
   is
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

   function Evaluate_FD_Hermite
     (S : Hermite_Spline; X : Float) return Eval_Result
   is
      R  : Eval_Result;
      I  : Natural;
      Dx : Float;
      T  : Float;
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

      I  := Find_Interval (S, X);
      Dx := S.X (I + 1) - S.X (I);
      if Dx <= Epsilon_Tol then
         R.Stat := Duplicate_Abscissa;
         return R;
      end if;
      T := (X - S.X (I)) / Dx;
      R.Value :=
        S.Y (I) * H00 (T)
        + Dx * S.M (I) * H10 (T)
        + S.Y (I + 1) * H01 (T)
        + Dx * S.M (I + 1) * H11 (T);
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Evaluate_FD_Hermite;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Make_Empty_Grid (N : Sample_Count) return Grid_1D is
      G : Grid_1D;
   begin
      G.N := N;
      G.Values := [others => 0.0];
      G.Valid := True;
      return G;
   end Make_Empty_Grid;

   function Make_Ramp_Grid
     (N : Sample_Count; Y0, Y1 : Float) return Grid_1D
   is
      G : Grid_1D := Make_Empty_Grid (N);
   begin
      if N = 1 then
         G.Values (0) := Y0;
      else
         for I in 0 .. N - 1 loop
            G.Values (I) :=
              Lerp (Y0, Y1, Float (I) / Float (N - 1));
         end loop;
      end if;
      return G;
   end Make_Ramp_Grid;

   function Poly_Cubic (T : Float) return Float is
   begin
      return T * T * T - 2.0 * T * T + T;
   end Poly_Cubic;

   function Make_Known_Cubic_Grid
     (N : Sample_Count; X0, X1 : Float) return Grid_1D
   is
      G : Grid_1D := Make_Empty_Grid (N);
      T : Float;
   begin
      if N = 1 then
         G.Values (0) := Poly_Cubic (X0);
      else
         for I in 0 .. N - 1 loop
            T := Lerp (X0, X1, Float (I) / Float (N - 1));
            G.Values (I) := Poly_Cubic (T);
         end loop;
      end if;
      return G;
   end Make_Known_Cubic_Grid;

   function Make_Sine_Grid
     (N : Sample_Count; X0, X1 : Float) return Grid_1D
   is
      G : Grid_1D := Make_Empty_Grid (N);
      T : Float;
   begin
      if N = 1 then
         G.Values (0) := Math.Sin (X0);
      else
         for I in 0 .. N - 1 loop
            T := Lerp (X0, X1, Float (I) / Float (N - 1));
            G.Values (I) := Math.Sin (T);
         end loop;
      end if;
      return G;
   end Make_Sine_Grid;

   procedure Make_Known_Cubic_Four
     (X0, X1 : Float;
      Xs     : out Abscissae;
      Ys     : out Ordinates)
   is
      T : Float;
   begin
      for K in 0 .. 3 loop
         T := Lerp (X0, X1, Float (K) / 3.0);
         Xs (Xs'First + K) := T;
         Ys (Ys'First + K) := Poly_Cubic (T);
      end loop;
   end Make_Known_Cubic_Four;

   function Make_Example_Grid (Kind : Example_Kind) return Grid_1D is
   begin
      case Kind is
         when Linear_Ramp =>
            return Make_Ramp_Grid (8, 0.0, 7.0);
         when Known_Cubic =>
            return Make_Known_Cubic_Grid (9, 0.0, 2.0);
         when Sine_Sample =>
            return Make_Sine_Grid (9, 0.0, Ada.Numerics.Pi);
      end case;
   end Make_Example_Grid;

   function Make_Example_FD (Kind : Example_Kind) return Fit_Result is
      X : Abscissae (0 .. Max_N - 1) := [others => 0.0];
      Y : Ordinates (0 .. Max_N - 1) := [others => 0.0];
      N : Natural;
      T : Float;
      X0, X1 : Float;
   begin
      case Kind is
         when Linear_Ramp =>
            N := 5;  -- last index; 6 points
            X0 := 0.0;
            X1 := 5.0;
            for I in 0 .. N loop
               X (I) := Lerp (X0, X1, Float (I) / Float (N));
               Y (I) := 2.0 * X (I) + 1.0;
            end loop;
         when Known_Cubic =>
            N := 4;
            X0 := 0.0;
            X1 := 2.0;
            for I in 0 .. N loop
               X (I) := Lerp (X0, X1, Float (I) / Float (N));
               Y (I) := Poly_Cubic (X (I));
            end loop;
         when Sine_Sample =>
            N := 8;
            X0 := 0.0;
            X1 := Ada.Numerics.Pi;
            for I in 0 .. N loop
               T := Lerp (X0, X1, Float (I) / Float (N));
               X (I) := T;
               Y (I) := Math.Sin (T);
            end loop;
      end case;
      return Fit_FD (X (0 .. N), Y (0 .. N));
   end Make_Example_FD;

end Cubic_Interpolation;
