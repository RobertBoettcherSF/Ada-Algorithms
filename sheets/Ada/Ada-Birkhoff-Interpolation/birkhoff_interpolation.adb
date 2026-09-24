--  Birkhoff_Interpolation body — monomial incidence system + GEPP + Horner.

pragma Ada_2022;

package body Birkhoff_Interpolation is

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Make_Condition
     (Node : Float; Derivative_Order : Natural; Value : Float)
      return Condition
   is
   begin
      return (Node => Node, Derivative_Order => Derivative_Order, Value => Value);
   end Make_Condition;

   function Monomial_Derivative_Entry
     (K, D : Natural; X : Float) return Float
   is
      Falling : Float;
      Pow     : Float;
      Exp     : Natural;
   begin
      if K < D then
         return 0.0;
      end if;

      --  Falling factorial K (K-1) ... (K-D+1) = K! / (K-D)!
      Falling := 1.0;
      for I in 0 .. D - 1 loop
         Falling := Falling * Float (K - I);
      end loop;

      Exp := K - D;
      if Exp = 0 then
         return Falling;
      end if;

      --  X^Exp (educational; Exp ≤ Max_Degree)
      Pow := 1.0;
      for I in 1 .. Exp loop
         Pow := Pow * X;
      end loop;
      return Falling * Pow;
   end Monomial_Derivative_Entry;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Validate (C : Conditions) return Status is
   begin
      if C'Length = 0 then
         return Ill_Started;
      elsif C'Length > Max_Conditions then
         return Too_Many_Conditions;
      else
         return Ok;
      end if;
   end Validate;

   function Validate (L : Condition_List) return Status is
   begin
      if not L.Valid then
         return Ill_Started;
      elsif L.Count = 0 then
         return Ill_Started;
      else
         return Ok;
      end if;
   end Validate;

   ---------------------------------------------------------------------------
   -- Fit (GEPP on monomial incidence matrix)
   ---------------------------------------------------------------------------

   function Fit (C : Conditions) return Fit_Result is
      Stat : constant Status := Validate (C);
      R    : Fit_Result;
      N    : Natural;
   begin
      if Stat /= Ok then
         R.Stat := Stat;
         R.Success := False;
         return R;
      end if;

      N := C'Length;
      R.Poly.N := N;

      declare
         --  Augmented matrix A(1..N, 1..N+1): cols 1..N coeffs, N+1 = RHS
         type Row is array (1 .. Max_Conditions + 1) of Float;
         type Mat is array (1 .. Max_Conditions) of Row;
         A      : Mat := [others => [others => 0.0]];
         Pivot  : Float;
         Best   : Natural;
         Tmp    : Float;
         Factor : Float;
         Cond   : Condition;
         Order  : Natural;
         Xi     : Float;
         Rhs_Nz : Boolean;
      begin
         --  Fill rows from incidence conditions
         for I in 1 .. N loop
            Cond  := C (C'First + (I - 1));
            Order := Cond.Derivative_Order;
            Xi    := Cond.Node;
            for J in 0 .. N - 1 loop
               A (I)(J + 1) := Monomial_Derivative_Entry (J, Order, Xi);
            end loop;
            A (I)(N + 1) := Cond.Value;
         end loop;

         --  GEPP forward elimination
         for K in 1 .. N loop
            Best := K;
            Pivot := abs (A (K)(K));
            for I in K + 1 .. N loop
               if abs (A (I)(K)) > Pivot then
                  Pivot := abs (A (I)(K));
                  Best := I;
               end if;
            end loop;

            if Pivot <= Pivot_Tol then
               --  Distinguish inconsistent (nonzero RHS remaining)
               --  from singular / non-unique (zero block, zero RHS).
               Rhs_Nz := False;
               for I in K .. N loop
                  if abs (A (I)(N + 1)) > Pivot_Tol then
                     Rhs_Nz := True;
                  end if;
               end loop;
               if Rhs_Nz then
                  R.Stat := Inconsistent;
               else
                  R.Stat := Singular;
               end if;
               R.Success := False;
               R.Poly.Valid := False;
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
         for I in reverse 1 .. N loop
            Tmp := A (I)(N + 1);
            for J in I + 1 .. N loop
               Tmp := Tmp - A (I)(J) * R.Poly.Coeffs (J - 1);
            end loop;
            if abs (A (I)(I)) <= Pivot_Tol then
               if abs (Tmp) > Pivot_Tol then
                  R.Stat := Inconsistent;
               else
                  R.Stat := Singular;
               end if;
               R.Success := False;
               R.Poly.Valid := False;
               return R;
            end if;
            R.Poly.Coeffs (I - 1) := Tmp / A (I)(I);
         end loop;
      end;

      --  Clear unused high coefficients
      for K in N .. Max_Degree loop
         R.Poly.Coeffs (K) := 0.0;
      end loop;

      R.Poly.Valid := True;
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Fit;

   function Fit (L : Condition_List) return Fit_Result is
      R : Fit_Result;
   begin
      if not L.Valid or else L.Count = 0 then
         R.Stat := Ill_Started;
         R.Success := False;
         return R;
      end if;
      return Fit (L.Data (1 .. L.Count));
   end Fit;

   ---------------------------------------------------------------------------
   -- Evaluation (Horner)
   ---------------------------------------------------------------------------

   function Evaluate (P : Polynomial; X : Float) return Eval_Result is
      Acc : Float;
   begin
      if not P.Valid or else P.N = 0 then
         return (Value => 0.0, Stat => Ill_Started, Success => False);
      end if;

      Acc := P.Coeffs (P.N - 1);
      for K in reverse 0 .. P.N - 2 loop
         Acc := P.Coeffs (K) + X * Acc;
      end loop;

      return (Value => Acc, Stat => Ok, Success => True);
   end Evaluate;

   function Evaluate_Derivative
     (P : Polynomial; Order : Natural; X : Float) return Eval_Result
   is
      Acc : Float := 0.0;
      Term : Float;
   begin
      if not P.Valid or else P.N = 0 then
         return (Value => 0.0, Stat => Ill_Started, Success => False);
      end if;

      if Order = 0 then
         return Evaluate (P, X);
      end if;

      if Order >= P.N then
         return (Value => 0.0, Stat => Ok, Success => True);
      end if;

      --  Sum_k Monomial_Derivative_Entry(k, Order, X) * c_k
      for K in Order .. P.N - 1 loop
         Term := Monomial_Derivative_Entry (K, Order, X) * P.Coeffs (K);
         Acc := Acc + Term;
      end loop;

      return (Value => Acc, Stat => Ok, Success => True);
   end Evaluate_Derivative;

   function Matches_Condition
     (P : Polynomial; C : Condition; Tol : Float := Near_Tol) return Boolean
   is
      E : Eval_Result;
   begin
      if not P.Valid then
         return False;
      end if;
      E := Evaluate_Derivative (P, C.Derivative_Order, C.Node);
      return E.Success and then Near (E.Value, C.Value, Tol);
   end Matches_Condition;

   function Matches_All
     (P : Polynomial; C : Conditions; Tol : Float := Near_Tol) return Boolean
   is
   begin
      if not P.Valid or else C'Length = 0 then
         return False;
      end if;
      for I in C'Range loop
         if not Matches_Condition (P, C (I), Tol) then
            return False;
         end if;
      end loop;
      return True;
   end Matches_All;

   function Matches_All
     (P : Polynomial; L : Condition_List; Tol : Float := Near_Tol)
      return Boolean
   is
   begin
      if not L.Valid or else L.Count = 0 then
         return False;
      end if;
      return Matches_All (P, L.Data (1 .. L.Count), Tol);
   end Matches_All;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Make_Lagrange_Conditions
     (X : Abscissae; Y : Ordinates) return Condition_List
   is
      L : Condition_List;
      N : Natural;
   begin
      if X'Length = 0 or else Y'Length = 0 then
         L.Stat := Ill_Started;
         L.Valid := False;
         return L;
      end if;
      if X'Length /= Y'Length then
         L.Stat := Dimension_Error;
         L.Valid := False;
         return L;
      end if;
      if X'Length > Max_Conditions then
         L.Stat := Too_Many_Conditions;
         L.Valid := False;
         return L;
      end if;

      N := X'Length;
      L.Count := N;
      for I in 0 .. N - 1 loop
         L.Data (I + 1) := Make_Condition
           (X (X'First + I), 0, Y (Y'First + I));
      end loop;
      L.Valid := True;
      L.Stat := Ok;
      return L;
   end Make_Lagrange_Conditions;

   function Make_Hermite_Two_Point
     (X0, Y0, M0 : Float;
      X1, Y1, M1 : Float) return Condition_List
   is
      L : Condition_List;
   begin
      L.Count := 4;
      L.Data (1) := Make_Condition (X0, 0, Y0);
      L.Data (2) := Make_Condition (X0, 1, M0);
      L.Data (3) := Make_Condition (X1, 0, Y1);
      L.Data (4) := Make_Condition (X1, 1, M1);
      L.Valid := True;
      L.Stat := Ok;
      return L;
   end Make_Hermite_Two_Point;

   function Make_Birkhoff_Polya_Regular
     (X_Left, Y_Left_Deriv   : Float;
      X_Mid,  Y_Mid          : Float;
      X_Right, Y_Right_Deriv : Float) return Condition_List
   is
      L : Condition_List;
   begin
      L.Count := 3;
      L.Data (1) := Make_Condition (X_Left, 1, Y_Left_Deriv);
      L.Data (2) := Make_Condition (X_Mid, 0, Y_Mid);
      L.Data (3) := Make_Condition (X_Right, 1, Y_Right_Deriv);
      L.Valid := True;
      L.Stat := Ok;
      return L;
   end Make_Birkhoff_Polya_Regular;

   function Make_Birkhoff_Singular_Example
     (X_Left, Y_Left        : Float;
      X_Mid,  Y_Mid_Deriv   : Float;
      X_Right, Y_Right      : Float) return Condition_List
   is
      L : Condition_List;
   begin
      L.Count := 3;
      L.Data (1) := Make_Condition (X_Left, 0, Y_Left);
      L.Data (2) := Make_Condition (X_Mid, 1, Y_Mid_Deriv);
      L.Data (3) := Make_Condition (X_Right, 0, Y_Right);
      L.Valid := True;
      L.Stat := Ok;
      return L;
   end Make_Birkhoff_Singular_Example;

   function Make_Example (Kind : Example_Kind) return Fit_Result is
      L : Condition_List;
   begin
      case Kind is
         when Lagrange_Quadratic =>
            declare
               X : constant Abscissae := [-1.0, 0.0, 1.0];
               Y : constant Ordinates := [1.0, 0.0, 1.0];
            begin
               L := Make_Lagrange_Conditions (X, Y);
               return Fit (L);
            end;

         when Hermite_Two_Point_Cubic =>
            --  p(x)=x³−2x²+x ; p'=3x²−4x+1 at 0 and 1
            --  p(0)=0, p'(0)=1, p(1)=0, p'(1)=0
            L := Make_Hermite_Two_Point (0.0, 0.0, 1.0, 1.0, 0.0, 0.0);
            return Fit (L);

         when Birkhoff_Polya_Regular =>
            --  Target P(x)=x²: P'(-1)=-2, P(0)=0, P'(1)=2
            L := Make_Birkhoff_Polya_Regular
              (-1.0, -2.0, 0.0, 0.0, 1.0, 2.0);
            return Fit (L);

         when Known_Cubic_Lagrange =>
            declare
               X : constant Abscissae :=
                 [0.0, 0.5, 1.0, 1.5, 2.0];
               Y : constant Ordinates :=
                 [0.0, 0.125, 0.0, 0.375, 2.0];
               --  p(x)=x³−2x²+x
               --  p(0)=0, p(0.5)=0.125, p(1)=0, p(1.5)=0.375, p(2)=2
            begin
               L := Make_Lagrange_Conditions (X, Y);
               return Fit (L);
            end;
      end case;
   end Make_Example;

   function Slice (L : Condition_List) return Conditions is
   begin
      return L.Data (1 .. L.Count);
   end Slice;

end Birkhoff_Interpolation;
