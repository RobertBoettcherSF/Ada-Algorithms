--  Spline_Interpolation body — natural / clamped cubic (Thomas),
--  piecewise linear / quadratic baselines; educational Float.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Spline_Interpolation
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
   begin
      --  Binary search for largest i with S.X(i) ≤ X; clamp to [0, N-1].
      declare
         Lo : Natural := 0;
         Hi : Natural := S.N;
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
      end;
   end Find_Interval;

   -------------------------------------------------------------------------
   -- Thomas algorithm
   -------------------------------------------------------------------------

   procedure Thomas
     (A, B, C, D : in     Ordinates;
      X          :    out Ordinates;
      Stat       :    out Status)
   is
      M : constant Natural := A'Last;
      --  Scratch for modified coefficients (1 .. M).
      Cp : Ordinates (1 .. M);
      Dp : Ordinates (1 .. M);
      Den : Float;
   begin
      X := [others => 0.0];
      Stat := Singular;

      if abs (B (1)) < Epsilon_Tol then
         return;
      end if;

      Cp (1) := C (1) / B (1);
      Dp (1) := D (1) / B (1);

      for I in 2 .. M loop
         Den := B (I) - A (I) * Cp (I - 1);
         if abs (Den) < Epsilon_Tol then
            return;
         end if;
         if I < M then
            Cp (I) := C (I) / Den;
         else
            Cp (I) := 0.0;
         end if;
         Dp (I) := (D (I) - A (I) * Dp (I - 1)) / Den;
      end loop;

      X (M) := Dp (M);
      for I in reverse 1 .. M - 1 loop
         X (I) := Dp (I) - Cp (I) * X (I + 1);
      end loop;

      Stat := Ok;
   end Thomas;

   -------------------------------------------------------------------------
   -- Internal: copy points into a Spline shell
   -------------------------------------------------------------------------

   function Copy_Points
     (X : Abscissae; Y : Ordinates; Kind : Spline_Kind) return Fit_Result
   is
      R : Fit_Result;
      N : Natural;
   begin
      R.Stat := Dimension_Error;
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

      N := X'Length - 1;
      R.S.Kind := Kind;
      R.S.N := N;
      R.S.Valid := False;
      R.S.YP0 := 0.0;
      R.S.YPN := 0.0;
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

   function Points_To_XY
     (P : Points; X : out Abscissae; Y : out Ordinates) return Status
   is
   begin
      if P'Length = 0 then
         return Dimension_Error;
      end if;
      if X'Length /= P'Length or else Y'Length /= P'Length then
         return Dimension_Error;
      end if;
      for I in P'Range loop
         X (X'First + (I - P'First)) := P (I).X;
         Y (Y'First + (I - P'First)) := P (I).Y;
      end loop;
      return Ok;
   end Points_To_XY;

   -------------------------------------------------------------------------
   -- Natural cubic
   -------------------------------------------------------------------------

   function Fit_Natural_Cubic
     (X : Abscissae; Y : Ordinates) return Fit_Result
   is
      R : Fit_Result := Copy_Points (X, Y, Natural_Cubic);
      N : Natural;
   begin
      if R.Stat /= Ok then
         return R;
      end if;

      N := R.S.N;
      if N < 1 then
         R.Stat := Too_Few_Points;
         return R;
      end if;

      --  M_0 = M_n = 0 already.
      if N = 1 then
         R.S.Valid := True;
         R.Success := True;
         R.Stat := Ok;
         return R;
      end if;

      --  Interior system size M = N - 1 for unknowns M_1 .. M_{N-1}.
      declare
         M  : constant Natural := N - 1;
         A  : Ordinates (1 .. M);
         B  : Ordinates (1 .. M);
         C  : Ordinates (1 .. M);
         D  : Ordinates (1 .. M);
         Sol : Ordinates (1 .. M);
         Hi_1, Hi : Float;
         Stat : Status;
      begin
         for I in 1 .. M loop
            Hi_1 := R.S.X (I) - R.S.X (I - 1);
            Hi   := R.S.X (I + 1) - R.S.X (I);
            A (I) := Hi_1 / 6.0;
            B (I) := (Hi_1 + Hi) / 3.0;
            C (I) := Hi / 6.0;
            D (I) := (R.S.Y (I + 1) - R.S.Y (I)) / Hi
              - (R.S.Y (I) - R.S.Y (I - 1)) / Hi_1;
         end loop;
         --  Natural: M_0 = M_n = 0 ⇒ no RHS correction needed
         --  (A(1)*M_0 and C(M)*M_n vanish).
         A (1) := 0.0;
         C (M) := 0.0;

         Thomas (A, B, C, D, Sol, Stat);
         if Stat /= Ok then
            R.Stat := Stat;
            return R;
         end if;

         R.S.M (0) := 0.0;
         R.S.M (N) := 0.0;
         for I in 1 .. M loop
            R.S.M (I) := Sol (I);
         end loop;

         R.S.Valid := True;
         R.Success := True;
         R.Stat := Ok;
      end;

      return R;
   end Fit_Natural_Cubic;

   function Fit_Natural_Cubic (P : Points) return Fit_Result is
      X : Abscissae (P'Range);
      Y : Ordinates (P'Range);
      St : Status;
   begin
      St := Points_To_XY (P, X, Y);
      if St /= Ok then
         return (S => <>, Stat => St, Success => False);
      end if;
      return Fit_Natural_Cubic (X, Y);
   end Fit_Natural_Cubic;

   -------------------------------------------------------------------------
   -- Clamped cubic
   -------------------------------------------------------------------------

   function Fit_Clamped_Cubic
     (X           : Abscissae;
      Y           : Ordinates;
      Left_Deriv  : Float;
      Right_Deriv : Float) return Fit_Result
   is
      R : Fit_Result := Copy_Points (X, Y, Clamped_Cubic);
      N : Natural;
   begin
      if R.Stat /= Ok then
         return R;
      end if;

      N := R.S.N;
      if N < 1 then
         R.Stat := Too_Few_Points;
         return R;
      end if;

      R.S.YP0 := Left_Deriv;
      R.S.YPN := Right_Deriv;

      --  Full system for M_0 .. M_n  (size N+1), indexed 1 .. N+1
      --  mapping j = i+1 so row j corresponds to M_{j-1}.
      declare
         Sz : constant Natural := N + 1;
         A  : Ordinates (1 .. Sz);
         B  : Ordinates (1 .. Sz);
         C  : Ordinates (1 .. Sz);
         D  : Ordinates (1 .. Sz);
         Sol : Ordinates (1 .. Sz);
         H0, Hn : Float;
         Stat : Status;
         Hi_1, Hi : Float;
      begin
         A := [others => 0.0];
         B := [others => 0.0];
         C := [others => 0.0];
         D := [others => 0.0];

         H0 := R.S.X (1) - R.S.X (0);
         Hn := R.S.X (N) - R.S.X (N - 1);

         --  Left clamped row (i=0 → index 1):
         --  2 h0 M0 + h0 M1 = 6 ((y1-y0)/h0 - A)
         B (1) := 2.0 * H0;
         C (1) := H0;
         D (1) := 6.0 * ((R.S.Y (1) - R.S.Y (0)) / H0 - Left_Deriv);

         --  Interior rows i = 1 .. N-1 → indices 2 .. N
         for I in 1 .. N - 1 loop
            Hi_1 := R.S.X (I) - R.S.X (I - 1);
            Hi   := R.S.X (I + 1) - R.S.X (I);
            A (I + 1) := Hi_1 / 6.0;
            B (I + 1) := (Hi_1 + Hi) / 3.0;
            C (I + 1) := Hi / 6.0;
            D (I + 1) := (R.S.Y (I + 1) - R.S.Y (I)) / Hi
              - (R.S.Y (I) - R.S.Y (I - 1)) / Hi_1;
         end loop;

         --  Right clamped row (i=N → index Sz):
         --  h_{n-1} M_{n-1} + 2 h_{n-1} M_n = 6 (B - (yn-y_{n-1})/h)
         A (Sz) := Hn;
         B (Sz) := 2.0 * Hn;
         D (Sz) := 6.0 * (Right_Deriv - (R.S.Y (N) - R.S.Y (N - 1)) / Hn);

         Thomas (A, B, C, D, Sol, Stat);
         if Stat /= Ok then
            R.Stat := Stat;
            return R;
         end if;

         for I in 0 .. N loop
            R.S.M (I) := Sol (I + 1);
         end loop;

         R.S.Valid := True;
         R.Success := True;
         R.Stat := Ok;
      end;

      return R;
   end Fit_Clamped_Cubic;

   function Fit_Clamped_Cubic
     (P           : Points;
      Left_Deriv  : Float;
      Right_Deriv : Float) return Fit_Result
   is
      X : Abscissae (P'Range);
      Y : Ordinates (P'Range);
      St : Status;
   begin
      St := Points_To_XY (P, X, Y);
      if St /= Ok then
         return (S => <>, Stat => St, Success => False);
      end if;
      return Fit_Clamped_Cubic (X, Y, Left_Deriv, Right_Deriv);
   end Fit_Clamped_Cubic;

   -------------------------------------------------------------------------
   -- Linear / quadratic baselines
   -------------------------------------------------------------------------

   function Fit_Linear (X : Abscissae; Y : Ordinates) return Fit_Result is
      R : Fit_Result := Copy_Points (X, Y, Linear);
   begin
      if R.Stat /= Ok then
         return R;
      end if;
      if R.S.N < 1 then
         R.Stat := Too_Few_Points;
         return R;
      end if;
      R.S.Valid := True;
      R.Success := True;
      return R;
   end Fit_Linear;

   function Fit_Linear (P : Points) return Fit_Result is
      X : Abscissae (P'Range);
      Y : Ordinates (P'Range);
      St : Status;
   begin
      St := Points_To_XY (P, X, Y);
      if St /= Ok then
         return (S => <>, Stat => St, Success => False);
      end if;
      return Fit_Linear (X, Y);
   end Fit_Linear;

   function Fit_Quadratic (X : Abscissae; Y : Ordinates) return Fit_Result is
      R : Fit_Result := Copy_Points (X, Y, Quadratic);
   begin
      if R.Stat /= Ok then
         return R;
      end if;
      if R.S.N < 2 then
         R.Stat := Too_Few_Points;
         return R;
      end if;
      R.S.Valid := True;
      R.Success := True;
      return R;
   end Fit_Quadratic;

   function Fit_Quadratic (P : Points) return Fit_Result is
      X : Abscissae (P'Range);
      Y : Ordinates (P'Range);
      St : Status;
   begin
      St := Points_To_XY (P, X, Y);
      if St /= Ok then
         return (S => <>, Stat => St, Success => False);
      end if;
      return Fit_Quadratic (X, Y);
   end Fit_Quadratic;

   -------------------------------------------------------------------------
   -- Evaluation
   -------------------------------------------------------------------------

   function Eval_Cubic_On_Interval
     (S : Spline; I : Natural; X : Float) return Float
   is
      H, DX, RX : Float;
   begin
      H := S.X (I + 1) - S.X (I);
      DX := X - S.X (I);
      RX := S.X (I + 1) - X;
      --  Classic moment form:
      return S.M (I) * RX * RX * RX / (6.0 * H)
        + S.M (I + 1) * DX * DX * DX / (6.0 * H)
        + (S.Y (I) - S.M (I) * H * H / 6.0) * RX / H
        + (S.Y (I + 1) - S.M (I + 1) * H * H / 6.0) * DX / H;
   end Eval_Cubic_On_Interval;

   function Eval_Linear_On_Interval
     (S : Spline; I : Natural; X : Float) return Float
   is
      H, T : Float;
   begin
      H := S.X (I + 1) - S.X (I);
      T := (X - S.X (I)) / H;
      return Lerp (S.Y (I), S.Y (I + 1), T);
   end Eval_Linear_On_Interval;

   function Lagrange2
     (X0, Y0, X1, Y1, X2, Y2, X : Float) return Float
   is
      L0, L1, L2 : Float;
   begin
      L0 := ((X - X1) * (X - X2)) / ((X0 - X1) * (X0 - X2));
      L1 := ((X - X0) * (X - X2)) / ((X1 - X0) * (X1 - X2));
      L2 := ((X - X0) * (X - X1)) / ((X2 - X0) * (X2 - X1));
      return L0 * Y0 + L1 * Y1 + L2 * Y2;
   end Lagrange2;

   function Eval_Quadratic_On_Interval
     (S : Spline; I : Natural; X : Float) return Float
   is
      --  Use triple (I, I+1, I+2) when possible; last interval uses N-2..N.
      J : Natural;
   begin
      if I <= S.N - 2 then
         J := I;
      else
         J := S.N - 2;
      end if;
      return Lagrange2
        (S.X (J), S.Y (J),
         S.X (J + 1), S.Y (J + 1),
         S.X (J + 2), S.Y (J + 2),
         X);
   end Eval_Quadratic_On_Interval;

   function Evaluate (S : Spline; X : Float) return Eval_Result is
      R : Eval_Result;
      I : Natural;
   begin
      R.Stat := Ill_Started;
      R.Success := False;
      R.Value := 0.0;

      if not S.Valid or else S.N < 1 then
         R.Stat := Ill_Started;
         return R;
      end if;

      if X < S.X (0) or else X > S.X (S.N) then
         R.Stat := Out_Of_Domain;
         return R;
      end if;

      I := Find_Interval (S, X);

      case S.Kind is
         when Natural_Cubic | Clamped_Cubic =>
            R.Value := Eval_Cubic_On_Interval (S, I, X);
         when Linear =>
            R.Value := Eval_Linear_On_Interval (S, I, X);
         when Quadratic =>
            R.Value := Eval_Quadratic_On_Interval (S, I, X);
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
         T := Float (I) / Float (N - 1);
         P (I).X := Lerp (X0, X1, T);
         P (I).Y := Lerp (Y0, Y1, T);
      end loop;
      return P;
   end Make_Linear_Data;

   function Make_Quadratic_Sample
     (N : Point_Count; X0, X1 : Float) return Points
   is
      P : Points (0 .. N - 1);
      T, Xi : Float;
   begin
      for I in 0 .. N - 1 loop
         T := Float (I) / Float (N - 1);
         Xi := Lerp (X0, X1, T);
         P (I).X := Xi;
         P (I).Y := Xi * Xi;
      end loop;
      return P;
   end Make_Quadratic_Sample;

   function Make_Sine_Sample
     (N : Point_Count; X0, X1 : Float) return Points
   is
      P : Points (0 .. N - 1);
      T, Xi : Float;
   begin
      for I in 0 .. N - 1 loop
         T := Float (I) / Float (N - 1);
         Xi := Lerp (X0, X1, T);
         P (I).X := Xi;
         P (I).Y := Math.Sin (Xi);
      end loop;
      return P;
   end Make_Sine_Sample;

   function Make_Example (Kind : Example_Kind) return Points is
   begin
      case Kind is
         when Linear_Data =>
            return Make_Linear_Data (5, 0.0, 4.0, 1.0, 9.0);
            --  y = 2x + 1
         when Quadratic_Sample =>
            return Make_Quadratic_Sample (6, -1.0, 1.0);
         when Sine_Sample =>
            return Make_Sine_Sample
              (8, 0.0, Ada.Numerics.Pi);
         when Uneven_Cubic =>
            declare
               P : Points (0 .. 4);
            begin
               P (0) := (0.0, 0.0);
               P (1) := (0.5, 0.8);
               P (2) := (1.2, 1.5);
               P (3) := (2.0, 1.2);
               P (4) := (3.5, 0.3);
               return P;
            end;
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

end Spline_Interpolation;
