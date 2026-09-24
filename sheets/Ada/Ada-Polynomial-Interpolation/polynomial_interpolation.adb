--  Polynomial_Interpolation body — Lagrange / Newton / Neville / monomial.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Polynomial_Interpolation
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

   function Is_Distinct
     (X : Abscissae; Tol : Float := Distinct_Tol) return Boolean
   is
   begin
      for I in X'Range loop
         for J in X'Range loop
            if J > I and then abs (X (I) - X (J)) <= Tol then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Distinct;

   function Degree_Of (X : Abscissae) return Degree_Range is
   begin
      return X'Length - 1;
   end Degree_Of;

   function Degree_Of (Y : Ordinates) return Degree_Range is
   begin
      return Y'Length - 1;
   end Degree_Of;

   function Slice_X (S : Sample) return Abscissae is
   begin
      return S.X (0 .. S.N);
   end Slice_X;

   function Slice_Y (S : Sample) return Ordinates is
   begin
      return S.Y (0 .. S.N);
   end Slice_Y;

   ---------------------------------------------------------------------------
   -- Validation / taxonomy
   ---------------------------------------------------------------------------

   function Validate (X : Abscissae; Y : Ordinates) return Status is
   begin
      if X'Length = 0 or else Y'Length = 0 then
         return Too_Few_Points;
      elsif X'Length /= Y'Length then
         return Dimension_Error;
      elsif X'Length > Max_Points then
         return Dimension_Error;
      elsif not Is_Distinct (X) then
         return Duplicate_Abscissa;
      else
         return Ok;
      end if;
   end Validate;

   function Recommend (Kind : Method_Kind; N : Degree_Range) return String is
   begin
      case Kind is
         when Lagrange_Form =>
            if N > 10 then
               return "Lagrange: O(n^2) per eval; Float products lose "
                 & "accuracy for large n. Prefer Newton for many queries; "
                 & "for Runge / high n prefer Ada-Spline-Interpolation.";
            else
               return "Lagrange: explicit barycentric-style basis; good "
                 & "oracle for tiny n. Same unique interpolant as Newton.";
            end if;
         when Newton_Form =>
            if N > 12 then
               return "Newton: build DD once O(n^2), then O(n) nested "
                 & "evals. Still a global degree-n poly — Runge risk; "
                 & "prefer Ada-Spline-Interpolation for equispaced data.";
            else
               return "Newton: divided differences + Horner-like nested "
                 & "form; efficient for many queries; easy to add a point.";
            end if;
         when Neville_Form =>
            return "Neville: tableau evaluates p(x) without forming "
              & "coefficients; O(n^2) per query. Sibling Ada-Neville "
              & "focuses on this form alone. Runge → prefer spline.";
         when Monomial_Vandermonde =>
            return "Monomial via Vandermonde+GEPP: catalogue risk "
              & "(ill-conditioned). Only for tiny n ≤ 8; prefer Newton "
              & "/ Neville. High n / Runge → Ada-Spline-Interpolation.";
      end case;
   end Recommend;

   ---------------------------------------------------------------------------
   -- Lagrange
   ---------------------------------------------------------------------------

   function Evaluate_Lagrange
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float) return Eval_Result
   is
      Stat : constant Status := Validate (X_Data, Y_Data);
      N    : Natural;
      Acc  : Float := 0.0;
      Li   : Float;
      Xi   : Float;
   begin
      if Stat /= Ok then
         return (Value => 0.0, Stat => Stat, Success => False);
      end if;

      N := X_Data'Length - 1;

      for I in 0 .. N loop
         Li := 1.0;
         Xi := X_Data (X_Data'First + I);
         for J in 0 .. N loop
            if J /= I then
               Li := Li
                 * (X - X_Data (X_Data'First + J))
                 / (Xi - X_Data (X_Data'First + J));
            end if;
         end loop;
         Acc := Acc + Y_Data (Y_Data'First + I) * Li;
      end loop;

      return (Value => Acc, Stat => Ok, Success => True);
   end Evaluate_Lagrange;

   function Evaluate_Lagrange
     (S : Sample; X : Float) return Eval_Result
   is
   begin
      if not S.Valid then
         return (Value => 0.0, Stat => Ill_Started, Success => False);
      end if;
      return Evaluate_Lagrange (Slice_X (S), Slice_Y (S), X);
   end Evaluate_Lagrange;

   ---------------------------------------------------------------------------
   -- Newton divided differences
   ---------------------------------------------------------------------------

   function Build_Divided_Differences
     (X_Data : Abscissae; Y_Data : Ordinates) return DD_Result
   is
      Stat : constant Status := Validate (X_Data, Y_Data);
      R    : DD_Result;
      N    : Natural;
      Den  : Float;
   begin
      if Stat /= Ok then
         R.Stat := Stat;
         R.Success := False;
         return R;
      end if;

      N := X_Data'Length - 1;
      R.N := N;

      --  Order-0 column: f[x_i] = y_i
      for I in 0 .. N loop
         R.Table (I, 0) := Y_Data (Y_Data'First + I);
      end loop;

      --  Higher orders
      for K in 1 .. N loop
         for I in 0 .. N - K loop
            Den :=
              X_Data (X_Data'First + I + K)
              - X_Data (X_Data'First + I);
            R.Table (I, K) :=
              (R.Table (I + 1, K - 1) - R.Table (I, K - 1)) / Den;
         end loop;
      end loop;

      for K in 0 .. N loop
         R.Coeffs (K) := R.Table (0, K);
      end loop;

      R.Stat := Ok;
      R.Success := True;
      return R;
   end Build_Divided_Differences;

   function Build_Divided_Differences (S : Sample) return DD_Result is
      R : DD_Result;
   begin
      if not S.Valid then
         R.Stat := Ill_Started;
         R.Success := False;
         return R;
      end if;
      return Build_Divided_Differences (Slice_X (S), Slice_Y (S));
   end Build_Divided_Differences;

   function Evaluate_Newton
     (X_Data : Abscissae;
      Coeffs : Newton_Coeffs;
      X      : Float) return Eval_Result
   is
      N : Natural;
      P : Float;
   begin
      if X_Data'Length = 0 or else Coeffs'Length = 0 then
         return (Value => 0.0, Stat => Too_Few_Points, Success => False);
      elsif X_Data'Length /= Coeffs'Length then
         return (Value => 0.0, Stat => Dimension_Error, Success => False);
      elsif X_Data'Length > Max_Points then
         return (Value => 0.0, Stat => Dimension_Error, Success => False);
      elsif not Is_Distinct (X_Data) then
         return
           (Value => 0.0, Stat => Duplicate_Abscissa, Success => False);
      end if;

      N := X_Data'Length - 1;
      if N = 0 then
         return
           (Value   => Coeffs (Coeffs'First),
            Stat    => Ok,
            Success => True);
      end if;

      P := Coeffs (Coeffs'First + N);

      for K in reverse 0 .. N - 1 loop
         P :=
           Coeffs (Coeffs'First + K)
           + (X - X_Data (X_Data'First + K)) * P;
      end loop;

      return (Value => P, Stat => Ok, Success => True);
   end Evaluate_Newton;

   function Evaluate_Newton
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float) return Eval_Result
   is
      DD : constant DD_Result :=
        Build_Divided_Differences (X_Data, Y_Data);
   begin
      if not DD.Success then
         return (Value => 0.0, Stat => DD.Stat, Success => False);
      end if;
      return Evaluate_Newton
        (X_Data, DD.Coeffs (0 .. DD.N), X);
   end Evaluate_Newton;

   function Evaluate_Newton
     (S : Sample; X : Float) return Eval_Result
   is
   begin
      if not S.Valid then
         return (Value => 0.0, Stat => Ill_Started, Success => False);
      end if;
      return Evaluate_Newton (Slice_X (S), Slice_Y (S), X);
   end Evaluate_Newton;

   ---------------------------------------------------------------------------
   -- Neville (inline)
   ---------------------------------------------------------------------------

   function Evaluate_Neville
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float) return Eval_Result
   is
      Stat : constant Status := Validate (X_Data, Y_Data);
      N    : Natural;
   begin
      if Stat /= Ok then
         return (Value => 0.0, Stat => Stat, Success => False);
      end if;

      N := X_Data'Length - 1;

      if N = 0 then
         return (Value => Y_Data (Y_Data'First), Stat => Ok, Success => True);
      end if;

      declare
         P : Ordinates (0 .. N);
         Xi, Xid, Den, New_P : Float;
      begin
         for I in 0 .. N loop
            P (I) := Y_Data (Y_Data'First + I);
         end loop;

         for D in 1 .. N loop
            for I in 0 .. N - D loop
               Xi  := X_Data (X_Data'First + I);
               Xid := X_Data (X_Data'First + I + D);
               Den := Xid - Xi;
               New_P :=
                 ((X - Xi) * P (I + 1) - (X - Xid) * P (I)) / Den;
               P (I) := New_P;
            end loop;
         end loop;

         return (Value => P (0), Stat => Ok, Success => True);
      end;
   end Evaluate_Neville;

   function Evaluate_Neville
     (S : Sample; X : Float) return Eval_Result
   is
   begin
      if not S.Valid then
         return (Value => 0.0, Stat => Ill_Started, Success => False);
      end if;
      return Evaluate_Neville (Slice_X (S), Slice_Y (S), X);
   end Evaluate_Neville;

   function Evaluate_Neville_Tableau
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float) return Tableau_Result
   is
      Stat : constant Status := Validate (X_Data, Y_Data);
      R    : Tableau_Result;
      N    : Natural;
      Xi, Xj, Den : Float;
   begin
      if Stat /= Ok then
         R.Stat := Stat;
         R.Success := False;
         return R;
      end if;

      N := X_Data'Length - 1;
      R.N := N;

      for I in 0 .. N loop
         R.Table (I, I) := Y_Data (Y_Data'First + I);
      end loop;

      for Span in 1 .. N loop
         for I in 0 .. N - Span loop
            declare
               J : constant Natural := I + Span;
            begin
               Xi  := X_Data (X_Data'First + I);
               Xj  := X_Data (X_Data'First + J);
               Den := Xj - Xi;
               R.Table (I, J) :=
                 ((X - Xi) * R.Table (I + 1, J)
                  - (X - Xj) * R.Table (I, J - 1))
                 / Den;
            end;
         end loop;
      end loop;

      R.Value   := R.Table (0, N);
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Evaluate_Neville_Tableau;

   function Evaluate_Neville_Tableau
     (S : Sample; X : Float) return Tableau_Result
   is
      R : Tableau_Result;
   begin
      if not S.Valid then
         R.Stat := Ill_Started;
         R.Success := False;
         return R;
      end if;
      return Evaluate_Neville_Tableau (Slice_X (S), Slice_Y (S), X);
   end Evaluate_Neville_Tableau;

   ---------------------------------------------------------------------------
   -- Monomial Vandermonde + GEPP (tiny n)
   ---------------------------------------------------------------------------

   function Fit_Monomial
     (X_Data : Abscissae; Y_Data : Ordinates) return Monomial_Result
   is
      Stat : constant Status := Validate (X_Data, Y_Data);
      R    : Monomial_Result;
      N    : Natural;
   begin
      if Stat /= Ok then
         R.Stat := Stat;
         R.Success := False;
         return R;
      end if;

      N := X_Data'Length - 1;
      if N > Max_Monomial_Degree then
         R.Stat := Dimension_Error;
         R.Success := False;
         return R;
      end if;

      R.N := N;

      declare
         --  Augmented matrix A(0..N, 0..N+1): columns 0..N powers, N+1 = RHS
         type Row is array (0 .. Max_Monomial_Degree + 1) of Float;
         type Mat is array (0 .. Max_Monomial_Degree) of Row;
         A     : Mat := [others => [others => 0.0]];
         Pivot : Float;
         Best  : Natural;
         Tmp   : Float;
         Factor : Float;
         Xi    : Float;
         Pow   : Float;
      begin
         for I in 0 .. N loop
            Xi  := X_Data (X_Data'First + I);
            Pow := 1.0;
            for J in 0 .. N loop
               A (I)(J) := Pow;
               Pow := Pow * Xi;
            end loop;
            A (I)(N + 1) := Y_Data (Y_Data'First + I);
         end loop;

         --  GEPP forward elimination
         for K in 0 .. N loop
            Best := K;
            Pivot := abs (A (K)(K));
            for I in K + 1 .. N loop
               if abs (A (I)(K)) > Pivot then
                  Pivot := abs (A (I)(K));
                  Best := I;
               end if;
            end loop;

            if Pivot <= Pivot_Tol then
               R.Stat := Singular;
               R.Success := False;
               return R;
            end if;

            if Best /= K then
               for J in K .. N + 1 loop
                  Tmp := A (K)(J);
                  A (K)(J) := A (Best)(J);
                  A (Best)(J) := Tmp;
               end loop;
            end if;

            for I in K + 1 .. N loop
               Factor := A (I)(K) / A (K)(K);
               for J in K .. N + 1 loop
                  A (I)(J) := A (I)(J) - Factor * A (K)(J);
               end loop;
            end loop;
         end loop;

         --  Back substitution
         for I in reverse 0 .. N loop
            Tmp := A (I)(N + 1);
            for J in I + 1 .. N loop
               Tmp := Tmp - A (I)(J) * R.Coeffs (J);
            end loop;
            if abs (A (I)(I)) <= Pivot_Tol then
               R.Stat := Singular;
               R.Success := False;
               return R;
            end if;
            R.Coeffs (I) := Tmp / A (I)(I);
         end loop;
      end;

      R.Stat := Ok;
      R.Success := True;
      return R;
   end Fit_Monomial;

   function Fit_Monomial (S : Sample) return Monomial_Result is
      R : Monomial_Result;
   begin
      if not S.Valid then
         R.Stat := Ill_Started;
         R.Success := False;
         return R;
      end if;
      return Fit_Monomial (Slice_X (S), Slice_Y (S));
   end Fit_Monomial;

   function Evaluate_Monomial
     (Coeffs : Monomial_Coeffs; X : Float) return Float
   is
      P : Float;
   begin
      if Coeffs'Length = 0 then
         return 0.0;
      elsif Coeffs'Length = 1 then
         return Coeffs (Coeffs'First);
      end if;
      P := Coeffs (Coeffs'Last);
      for K in reverse Coeffs'First .. Coeffs'Last - 1 loop
         P := Coeffs (K) + X * P;
      end loop;
      return P;
   end Evaluate_Monomial;

   function Evaluate_Monomial
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float) return Eval_Result
   is
      Fit : constant Monomial_Result := Fit_Monomial (X_Data, Y_Data);
   begin
      if not Fit.Success then
         return (Value => 0.0, Stat => Fit.Stat, Success => False);
      end if;
      return
        (Value   => Evaluate_Monomial (Fit.Coeffs (0 .. Fit.N), X),
         Stat    => Ok,
         Success => True);
   end Evaluate_Monomial;

   function Evaluate_Monomial
     (S : Sample; X : Float) return Eval_Result
   is
   begin
      if not S.Valid then
         return (Value => 0.0, Stat => Ill_Started, Success => False);
      end if;
      return Evaluate_Monomial (Slice_X (S), Slice_Y (S), X);
   end Evaluate_Monomial;

   ---------------------------------------------------------------------------
   -- Cross-check
   ---------------------------------------------------------------------------

   function Forms_Agree
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float;
      Tol    : Float := Near_Tol) return Boolean
   is
      L : constant Eval_Result := Evaluate_Lagrange (X_Data, Y_Data, X);
      Nt : constant Eval_Result := Evaluate_Newton (X_Data, Y_Data, X);
      Nv : constant Eval_Result := Evaluate_Neville (X_Data, Y_Data, X);
   begin
      if not (L.Success and Nt.Success and Nv.Success) then
         return False;
      end if;
      return Near (L.Value, Nt.Value, Tol)
        and then Near (L.Value, Nv.Value, Tol)
        and then Near (Nt.Value, Nv.Value, Tol);
   end Forms_Agree;

   function Forms_Agree
     (S : Sample; X : Float; Tol : Float := Near_Tol) return Boolean
   is
   begin
      if not S.Valid then
         return False;
      end if;
      return Forms_Agree (Slice_X (S), Slice_Y (S), X, Tol);
   end Forms_Agree;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Linspace
     (N : Point_Count; A, B : Float) return Abscissae
   is
      Result : Abscissae (0 .. N - 1);
      Den    : constant Float := Float (N - 1);
   begin
      if N = 1 then
         Result (0) := A;
         return Result;
      end if;
      for I in 0 .. N - 1 loop
         Result (I) := A + (B - A) * Float (I) / Den;
      end loop;
      return Result;
   end Linspace;

   function Make_Linear
     (N : Point_Count; X0, X1, Y0, Y1 : Float) return Sample
   is
      S  : Sample;
      Xs : constant Abscissae := Linspace (N, X0, X1);
      T  : Float;
   begin
      S.N := N - 1;
      for I in 0 .. S.N loop
         S.X (I) := Xs (I);
         T := (Xs (I) - X0) / (X1 - X0);
         S.Y (I) := (1.0 - T) * Y0 + T * Y1;
      end loop;
      S.Valid := True;
      return S;
   end Make_Linear;

   function Make_Quadratic_Sample
     (N : Point_Count; X0, X1 : Float) return Sample
   is
      S  : Sample;
      Xs : constant Abscissae := Linspace (N, X0, X1);
   begin
      S.N := N - 1;
      for I in 0 .. S.N loop
         S.X (I) := Xs (I);
         S.Y (I) := Xs (I) * Xs (I);
      end loop;
      S.Valid := True;
      return S;
   end Make_Quadratic_Sample;

   function Make_Runge_Sample (N : Point_Count) return Sample is
      S  : Sample;
      Xs : constant Abscissae := Linspace (N, -1.0, 1.0);
      XX : Float;
   begin
      S.N := N - 1;
      for I in 0 .. S.N loop
         S.X (I) := Xs (I);
         XX := Xs (I);
         S.Y (I) := 1.0 / (1.0 + 25.0 * XX * XX);
      end loop;
      S.Valid := True;
      return S;
   end Make_Runge_Sample;

   function Make_Sine_Sample (N : Point_Count) return Sample is
      S  : Sample;
      Xs : constant Abscissae := Linspace (N, 0.0, Ada.Numerics.Pi);
   begin
      S.N := N - 1;
      for I in 0 .. S.N loop
         S.X (I) := Xs (I);
         S.Y (I) := Math.Sin (Xs (I));
      end loop;
      S.Valid := True;
      return S;
   end Make_Sine_Sample;

   function Make_Example
     (Kind : Example_Kind; N : Point_Count) return Sample
   is
   begin
      case Kind is
         when Linear_Data =>
            return Make_Linear (N, 0.0, 1.0, 0.0, 1.0);
         when Quadratic_Sample =>
            return Make_Quadratic_Sample (N, -1.0, 1.0);
         when Runge_Sample =>
            return Make_Runge_Sample (N);
         when Sine_Sample =>
            return Make_Sine_Sample (N);
      end case;
   end Make_Example;

end Polynomial_Interpolation;
