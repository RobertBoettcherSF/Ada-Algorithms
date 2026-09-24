--  Hermite_Interpolation body — piecewise cubic Hermite, FD tangents,
--  two-point unique cubic, and small osculatory Newton confluent sketch.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Hermite_Interpolation
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
   -- Single-interval evaluation
   -------------------------------------------------------------------------

   function Evaluate_Cubic_Interval
     (X0, Y0, M0 : Float;
      X1, Y1, M1 : Float;
      X          : Float) return Eval_Result
   is
      R  : Eval_Result;
      Dx : Float;
      T  : Float;
   begin
      R.Value := 0.0;
      R.Stat := Ill_Started;
      R.Success := False;

      Dx := X1 - X0;
      if Dx <= Epsilon_Tol then
         R.Stat := Dimension_Error;
         return R;
      end if;

      if X < X0 or else X > X1 then
         R.Stat := Out_Of_Domain;
         return R;
      end if;

      T := (X - X0) / Dx;
      R.Value :=
        Y0 * H00 (T)
        + Dx * M0 * H10 (T)
        + Y1 * H01 (T)
        + Dx * M1 * H11 (T);
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Evaluate_Cubic_Interval;

   -------------------------------------------------------------------------
   -- Internal: copy X/Y into a Spline shell and validate
   -------------------------------------------------------------------------

   function Copy_XY
     (X : Abscissae; Y : Ordinates; Kind : Fit_Kind) return Fit_Result
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
         R.Stat := Dimension_Error;
         return R;
      end if;
      if X'Length > Max_Points then
         R.Stat := Dimension_Error;
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
   end Copy_XY;

   -------------------------------------------------------------------------
   -- Finite-difference tangents (no Fritsch–Carlson restrict)
   -------------------------------------------------------------------------

   procedure Compute_FD_Tangents
     (X : Abscissae;
      Y : Ordinates;
      N : Natural;
      M : out Tangents)
   is
      Sec : array (0 .. Max_Points - 2) of Float := [others => 0.0];
   begin
      M := [others => 0.0];

      for I in 0 .. N - 1 loop
         Sec (I) := (Y (I + 1) - Y (I)) / (X (I + 1) - X (I));
      end loop;

      M (0) := Sec (0);
      M (N) := Sec (N - 1);

      for K in 1 .. N - 1 loop
         M (K) := 0.5 * (Sec (K - 1) + Sec (K));
      end loop;
   end Compute_FD_Tangents;

   -------------------------------------------------------------------------
   -- Fitters
   -------------------------------------------------------------------------

   function Fit
     (X : Abscissae; Y : Ordinates; M : Tangents) return Fit_Result
   is
      R : Fit_Result;
      N : Natural;
   begin
      if M'Length /= X'Length then
         R.Stat := Dimension_Error;
         R.Success := False;
         return R;
      end if;

      R := Copy_XY (X, Y, User_Tangents);
      if R.Stat /= Ok then
         return R;
      end if;

      N := R.S.N;
      for I in 0 .. N loop
         R.S.M (I) := M (M'First + I);
      end loop;

      R.S.Valid := True;
      R.Success := True;
      R.Stat := Ok;
      return R;
   end Fit;

   function Fit (P : Points; M : Tangents) return Fit_Result is
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
      return Fit (X, Y, M);
   end Fit;

   function Fit_FD
     (X : Abscissae; Y : Ordinates) return Fit_Result
   is
      R : Fit_Result := Copy_XY (X, Y, Finite_Difference);
      M : Tangents (0 .. Max_Points - 1);
      N : Natural;
   begin
      if R.Stat /= Ok then
         return R;
      end if;

      N := R.S.N;
      Compute_FD_Tangents (R.S.X (0 .. N), R.S.Y (0 .. N), N, M);

      for I in 0 .. N loop
         R.S.M (I) := M (I);
      end loop;

      R.S.Valid := True;
      R.Success := True;
      R.Stat := Ok;
      return R;
   end Fit_FD;

   function Fit_FD (P : Points) return Fit_Result is
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
      return Fit_FD (X, Y);
   end Fit_FD;

   function Fit_Two_Point
     (X0, Y0, M0 : Float;
      X1, Y1, M1 : Float) return Fit_Result
   is
      R : Fit_Result;
   begin
      R.Stat := Ill_Started;
      R.Success := False;

      if X1 - X0 <= Epsilon_Tol then
         R.Stat := Dimension_Error;
         return R;
      end if;

      R.S.Kind := Two_Point;
      R.S.N := 1;
      R.S.X (0) := X0;
      R.S.Y (0) := Y0;
      R.S.M (0) := M0;
      R.S.X (1) := X1;
      R.S.Y (1) := Y1;
      R.S.M (1) := M1;
      R.S.Valid := True;
      R.Success := True;
      R.Stat := Ok;
      return R;
   end Fit_Two_Point;

   -------------------------------------------------------------------------
   -- Piecewise evaluation
   -------------------------------------------------------------------------

   function Evaluate (S : Spline; X : Float) return Eval_Result is
      R : Eval_Result;
      I : Natural;
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
      return Evaluate_Cubic_Interval
        (S.X (I), S.Y (I), S.M (I),
         S.X (I + 1), S.Y (I + 1), S.M (I + 1),
         X);
   end Evaluate;

   -------------------------------------------------------------------------
   -- Osculatory Newton confluent (value + first derivative at nodes)
   -------------------------------------------------------------------------

   function Evaluate_Osculatory
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      M_Data : Tangents;
      X      : Float) return Eval_Result
   is
      R   : Eval_Result;
      N   : Natural;
      K   : Natural;  -- last index of doubled table: 2*(N+1)-1
      Z   : array (0 .. 2 * Max_Osculatory_Nodes - 1) of Float;
      --  In-place Newton DD column; after fill, Row(i) = c_i.
      Row : array (0 .. 2 * Max_Osculatory_Nodes - 1) of Float :=
              [others => 0.0];
      Acc : Float;
      Den : Float;
      Jdx : Natural;
   begin
      R.Value := 0.0;
      R.Stat := Ill_Started;
      R.Success := False;

      if X_Data'Length = 0
        or else Y_Data'Length = 0
        or else M_Data'Length = 0
      then
         return R;
      end if;

      if X_Data'Length /= Y_Data'Length
        or else X_Data'Length /= M_Data'Length
      then
         R.Stat := Dimension_Error;
         return R;
      end if;

      if X_Data'Length > Max_Osculatory_Nodes then
         R.Stat := Dimension_Error;
         return R;
      end if;

      if X_Data'Length < 1 then
         R.Stat := Too_Few_Points;
         return R;
      end if;

      N := X_Data'Length - 1;

      --  Strictly increasing nodes required for distinct x_i.
      declare
         Tmp : Abscissae (0 .. N);
      begin
         for I in 0 .. N loop
            Tmp (I) := X_Data (X_Data'First + I);
         end loop;
         if not Is_Strictly_Increasing (Tmp) then
            R.Stat := Not_Strictly_Increasing;
            return R;
         end if;
      end;

      --  Double each node: z_{2i}=z_{2i+1}=x_i; f[z]=y_i.
      K := 2 * (N + 1) - 1;
      for I in 0 .. N loop
         Z (2 * I)       := X_Data (X_Data'First + I);
         Z (2 * I + 1)   := X_Data (X_Data'First + I);
         Row (2 * I)     := Y_Data (Y_Data'First + I);
         Row (2 * I + 1) := Y_Data (Y_Data'First + I);
      end loop;

      --  In-place divided differences (i = K .. Order):
      --  Row(i) := (Row(i) - Row(i-1)) / (Z(i) - Z(i-Order));
      --  when Z(i)=Z(i-Order) and Order=1, Row(i) := m at that node.
      for Order in 1 .. K loop
         for I in reverse Order .. K loop
            Den := Z (I) - Z (I - Order);
            if abs (Den) <= Epsilon_Tol then
               if Order = 1 then
                  Jdx := 0;
                  for T in 0 .. N loop
                     if Near (Z (I), X_Data (X_Data'First + T),
                              Epsilon_Tol)
                     then
                        Jdx := T;
                        exit;
                     end if;
                  end loop;
                  Row (I) := M_Data (M_Data'First + Jdx);
               else
                  R.Stat := Ill_Started;
                  return R;
               end if;
            else
               Row (I) := (Row (I) - Row (I - 1)) / Den;
            end if;
         end loop;
      end loop;

      --  Newton evaluation: H(x) = c0 + c1(x-z0) + c2(x-z0)(x-z1) + ...
      Acc := Row (K);
      for J in reverse 0 .. K - 1 loop
         Acc := Row (J) + (X - Z (J)) * Acc;
      end loop;

      R.Value := Acc;
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Evaluate_Osculatory;

   -------------------------------------------------------------------------
   -- Builders
   -------------------------------------------------------------------------

   function Poly_Cubic (X : Float) return Float is
   begin
      return X * X * X - 2.0 * X * X + X;
   end Poly_Cubic;

   function Poly_Cubic_Deriv (X : Float) return Float is
   begin
      return 3.0 * X * X - 4.0 * X + 1.0;
   end Poly_Cubic_Deriv;

   function Make_Known_Cubic
     (N : Point_Count; X0, X1 : Float) return Fit_Result
   is
      X : Abscissae (0 .. N - 1);
      Y : Ordinates (0 .. N - 1);
      M : Tangents  (0 .. N - 1);
      H : Float;
   begin
      H := (X1 - X0) / Float (N - 1);
      for I in 0 .. N - 1 loop
         X (I) := X0 + Float (I) * H;
         Y (I) := Poly_Cubic (X (I));
         M (I) := Poly_Cubic_Deriv (X (I));
      end loop;
      return Fit (X, Y, M);
   end Make_Known_Cubic;

   function Make_Sine_Sample
     (N : Point_Count; X0, X1 : Float) return Fit_Result
   is
      X : Abscissae (0 .. N - 1);
      Y : Ordinates (0 .. N - 1);
      M : Tangents  (0 .. N - 1);
      H : Float;
   begin
      H := (X1 - X0) / Float (N - 1);
      for I in 0 .. N - 1 loop
         X (I) := X0 + Float (I) * H;
         Y (I) := Math.Sin (X (I));
         M (I) := Math.Cos (X (I));
      end loop;
      return Fit (X, Y, M);
   end Make_Sine_Sample;

   function Make_Linear_Ramp
     (N : Point_Count; X0, X1, Y0, Y1 : Float) return Fit_Result
   is
      X : Abscissae (0 .. N - 1);
      Y : Ordinates (0 .. N - 1);
      M : Tangents  (0 .. N - 1);
      H : Float;
      Slope : Float;
   begin
      H := (X1 - X0) / Float (N - 1);
      Slope := (Y1 - Y0) / (X1 - X0);
      for I in 0 .. N - 1 loop
         X (I) := X0 + Float (I) * H;
         Y (I) := Y0 + Slope * (X (I) - X0);
         M (I) := Slope;
      end loop;
      return Fit (X, Y, M);
   end Make_Linear_Ramp;

   function Make_Example (Kind : Example_Kind) return Fit_Result is
   begin
      case Kind is
         when Known_Cubic =>
            return Make_Known_Cubic (5, 0.0, 2.0);
         when Sine_Sample =>
            return Make_Sine_Sample (9, 0.0, Ada.Numerics.Pi);
         when Linear_Ramp =>
            return Make_Linear_Ramp (6, 0.0, 5.0, 1.0, 11.0);
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

end Hermite_Interpolation;
