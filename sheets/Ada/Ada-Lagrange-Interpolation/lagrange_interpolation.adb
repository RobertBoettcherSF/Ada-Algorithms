--  Lagrange_Interpolation body — classical basis + barycentric forms.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Lagrange_Interpolation
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
   -- Validation
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

   ---------------------------------------------------------------------------
   -- Barycentric weights
   ---------------------------------------------------------------------------

   function Build_Weights (X : Abscissae) return Weight_Result is
      R : Weight_Result;
      N : Natural;
      Prod : Float;
   begin
      if X'Length = 0 then
         R.Stat := Too_Few_Points;
         R.Success := False;
         return R;
      elsif X'Length > Max_Points then
         R.Stat := Dimension_Error;
         R.Success := False;
         return R;
      elsif not Is_Distinct (X) then
         R.Stat := Duplicate_Abscissa;
         R.Success := False;
         return R;
      end if;

      N := X'Length - 1;
      R.N := N;

      for I in 0 .. N loop
         Prod := 1.0;
         for J in 0 .. N loop
            if J /= I then
               Prod := Prod
                 * (X (X'First + I) - X (X'First + J));
            end if;
         end loop;
         R.W (I) := 1.0 / Prod;
      end loop;

      R.Stat := Ok;
      R.Success := True;
      return R;
   end Build_Weights;

   function Build_Weights (S : Sample) return Weight_Result is
      R : Weight_Result;
   begin
      if not S.Valid then
         R.Stat := Ill_Started;
         R.Success := False;
         return R;
      end if;
      return Build_Weights (Slice_X (S));
   end Build_Weights;

   ---------------------------------------------------------------------------
   -- Classical Lagrange
   ---------------------------------------------------------------------------

   function Evaluate
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
   end Evaluate;

   function Evaluate
     (S : Sample; X : Float) return Eval_Result
   is
   begin
      if not S.Valid then
         return (Value => 0.0, Stat => Ill_Started, Success => False);
      end if;
      return Evaluate (Slice_X (S), Slice_Y (S), X);
   end Evaluate;

   function Basis_Polynomial
     (X_Data : Abscissae;
      I      : Point_Index;
      X      : Float) return Eval_Result
   is
      N  : Natural;
      Li : Float := 1.0;
      Xi : Float;
   begin
      if X_Data'Length = 0 then
         return (Value => 0.0, Stat => Too_Few_Points, Success => False);
      elsif X_Data'Length > Max_Points then
         return (Value => 0.0, Stat => Dimension_Error, Success => False);
      elsif not Is_Distinct (X_Data) then
         return (Value => 0.0, Stat => Duplicate_Abscissa, Success => False);
      end if;

      N := X_Data'Length - 1;
      if Natural (I) > N then
         return (Value => 0.0, Stat => Dimension_Error, Success => False);
      end if;

      Xi := X_Data (X_Data'First + Natural (I));
      for J in 0 .. N loop
         if J /= Natural (I) then
            Li := Li
              * (X - X_Data (X_Data'First + J))
              / (Xi - X_Data (X_Data'First + J));
         end if;
      end loop;

      return (Value => Li, Stat => Ok, Success => True);
   end Basis_Polynomial;

   ---------------------------------------------------------------------------
   -- Barycentric evaluation
   ---------------------------------------------------------------------------

   function Evaluate_Barycentric
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      W      : Weights;
      X      : Float;
      Form   : Barycentric_Form := Second_Form) return Eval_Result
   is
      Stat : constant Status := Validate (X_Data, Y_Data);
      N    : Natural;
      Diff : Float;
      Num  : Float := 0.0;
      Den  : Float := 0.0;
      Ell  : Float := 1.0;
      Term : Float;
   begin
      if Stat /= Ok then
         return (Value => 0.0, Stat => Stat, Success => False);
      end if;

      if W'Length /= X_Data'Length then
         return (Value => 0.0, Stat => Dimension_Error, Success => False);
      end if;

      N := X_Data'Length - 1;

      --  Exact hit at a node: return y_k (avoids 0/0).
      for K in 0 .. N loop
         if Near (X, X_Data (X_Data'First + K), Distinct_Tol) then
            return
              (Value   => Y_Data (Y_Data'First + K),
               Stat    => Ok,
               Success => True);
         end if;
      end loop;

      case Form is
         when Second_Form =>
            for I in 0 .. N loop
               Diff := X - X_Data (X_Data'First + I);
               Term := W (W'First + I) / Diff;
               Num  := Num + Term * Y_Data (Y_Data'First + I);
               Den  := Den + Term;
            end loop;
            return (Value => Num / Den, Stat => Ok, Success => True);

         when First_Form =>
            for J in 0 .. N loop
               Ell := Ell * (X - X_Data (X_Data'First + J));
            end loop;
            for I in 0 .. N loop
               Diff := X - X_Data (X_Data'First + I);
               Term := W (W'First + I) / Diff;
               Num  := Num + Term * Y_Data (Y_Data'First + I);
            end loop;
            return (Value => Ell * Num, Stat => Ok, Success => True);
      end case;
   end Evaluate_Barycentric;

   function Evaluate_Barycentric
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float;
      Form   : Barycentric_Form := Second_Form) return Eval_Result
   is
      WR : constant Weight_Result := Build_Weights (X_Data);
   begin
      if not WR.Success then
         return (Value => 0.0, Stat => WR.Stat, Success => False);
      end if;
      return Evaluate_Barycentric
        (X_Data, Y_Data, WR.W (0 .. WR.N), X, Form);
   end Evaluate_Barycentric;

   function Evaluate_Barycentric
     (S    : Sample;
      X    : Float;
      Form : Barycentric_Form := Second_Form) return Eval_Result
   is
   begin
      if not S.Valid then
         return (Value => 0.0, Stat => Ill_Started, Success => False);
      end if;
      return Evaluate_Barycentric (Slice_X (S), Slice_Y (S), X, Form);
   end Evaluate_Barycentric;

   ---------------------------------------------------------------------------
   -- Forms agree
   ---------------------------------------------------------------------------

   function Forms_Agree
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float;
      Tol    : Float := Near_Tol) return Boolean
   is
      R_C : constant Eval_Result := Evaluate (X_Data, Y_Data, X);
      R_1 : constant Eval_Result :=
        Evaluate_Barycentric (X_Data, Y_Data, X, First_Form);
      R_2 : constant Eval_Result :=
        Evaluate_Barycentric (X_Data, Y_Data, X, Second_Form);
   begin
      if not (R_C.Success and R_1.Success and R_2.Success) then
         return False;
      end if;
      return Near (R_C.Value, R_1.Value, Tol)
        and then Near (R_C.Value, R_2.Value, Tol)
        and then Near (R_1.Value, R_2.Value, Tol);
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

end Lagrange_Interpolation;
