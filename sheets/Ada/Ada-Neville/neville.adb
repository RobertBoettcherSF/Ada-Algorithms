--  Neville body — polynomial interpolation evaluation via tableau.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Neville
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
   -- Core Neville (Wikipedia recurrence)
   --   p_{i,i} = y_i
   --   p_{i,j} = ((x-x_i) p_{i+1,j} - (x-x_j) p_{i,j-1}) / (x_j - x_i)
   -- Final: p_{0,n}
   ---------------------------------------------------------------------------

   function Evaluate
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

      --  Degree 0: constant
      if N = 0 then
         return (Value => Y_Data (Y_Data'First), Stat => Ok, Success => True);
      end if;

      declare
         --  Work row: start as ordinates; overwrite in place by increasing d.
         --  Alternate notation: p_{d,i} overwrites previous column.
         P : Ordinates (0 .. N);
         Xi, Xid, Den, New_P : Float;
      begin
         for I in 0 .. N loop
            P (I) := Y_Data (Y_Data'First + I);
         end loop;

         for D in 1 .. N loop
            --  Forward overwrite: new P(I) uses old P(I) and old P(I+1);
            --  P(I+1) is still the previous column when I increases.
            for I in 0 .. N - D loop
               Xi  := X_Data (X_Data'First + I);
               Xid := X_Data (X_Data'First + I + D);
               Den := Xid - Xi;
               --  p_d,i = ((x-x_i) p_{d-1,i+1} - (x-x_{i+d}) p_{d-1,i})
               --          / (x_{i+d} - x_i)
               New_P :=
                 ((X - Xi) * P (I + 1) - (X - Xid) * P (I)) / Den;
               P (I) := New_P;
            end loop;
         end loop;

         return (Value => P (0), Stat => Ok, Success => True);
      end;
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

   function Evaluate_Tableau
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

      --  Diagonal: p_{i,i} = y_i
      for I in 0 .. N loop
         R.Table (I, I) := Y_Data (Y_Data'First + I);
      end loop;

      --  Fill by increasing span j − i
      for Span in 1 .. N loop
         for I in 0 .. N - Span loop
            declare
               J : constant Natural := I + Span;
            begin
               Xi  := X_Data (X_Data'First + I);
               Xj  := X_Data (X_Data'First + J);
               Den := Xj - Xi;
               --  Wikipedia:
               --  p_{i,j} = ((x-x_i)p_{i+1,j} - (x-x_j)p_{i,j-1}) / (x_j-x_i)
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
   end Evaluate_Tableau;

   function Evaluate_Tableau
     (S : Sample; X : Float) return Tableau_Result
   is
      R : Tableau_Result;
   begin
      if not S.Valid then
         R.Stat := Ill_Started;
         R.Success := False;
         return R;
      end if;
      return Evaluate_Tableau (Slice_X (S), Slice_Y (S), X);
   end Evaluate_Tableau;

   ---------------------------------------------------------------------------
   -- Lagrange oracle
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

end Neville;
