--  Body for Gospers_Algorithm — educational indefinite hypergeometric summation.

pragma Ada_2022;

package body Gospers_Algorithm
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   -- Integer helpers
   ------------------------------------------------------------------

   function Abs_I (N : Integer) return Natural is
   begin
      if N < 0 then
         return Natural (-N);
      else
         return Natural (N);
      end if;
   end Abs_I;

   function Gcd_Nat (A, B : Natural) return Natural is
      X : Natural := A;
      Y : Natural := B;
      T : Natural;
   begin
      while Y /= 0 loop
         T := X rem Y;
         X := Y;
         Y := T;
      end loop;
      return X;
   end Gcd_Nat;

   function Binomial (N, K : Natural) return Integer is
      Result : Integer := 1;
      KK     : Natural := K;
   begin
      if K > N then
         return 0;
      end if;
      if K > N - K then
         KK := N - K;
      end if;
      for I in 1 .. KK loop
         Result := Result * Integer (N - KK + I) / Integer (I);
      end loop;
      return Result;
   end Binomial;

   function Int_Pow (Base : Integer; Exp : Natural) return Integer is
      Result : Integer := 1;
   begin
      for I in 1 .. Exp loop
         Result := Result * Base;
      end loop;
      return Result;
   end Int_Pow;

   ------------------------------------------------------------------
   -- Rationals
   ------------------------------------------------------------------

   function Reduce (R : Rational) return Rational is
      G : Natural;
      N : Integer := R.Num;
      D : Integer := Integer (R.Den);
   begin
      if D = 0 then
         raise Division_By_Zero;
      end if;
      if D < 0 then
         N := -N;
         D := -D;
      end if;
      if N = 0 then
         return Zero_Q;
      end if;
      G := Gcd_Nat (Abs_I (N), Natural (D));
      return (Num => N / Integer (G),
              Den => Positive (Natural (D) / G));
   end Reduce;

   function Make_Rational (Num, Den : Integer) return Rational is
      N : Integer := Num;
      D : Integer := Den;
   begin
      if D = 0 then
         raise Division_By_Zero;
      end if;
      if D < 0 then
         N := -N;
         D := -D;
      end if;
      return Reduce ((Num => N, Den => Positive (D)));
   end Make_Rational;

   function Equal (A, B : Rational) return Boolean is
      RA : constant Rational := Reduce (A);
      RB : constant Rational := Reduce (B);
   begin
      return RA.Num = RB.Num and then RA.Den = RB.Den;
   end Equal;

   function Is_Zero (R : Rational) return Boolean is
   begin
      return Reduce (R).Num = 0;
   end Is_Zero;

   function "+" (A, B : Rational) return Rational is
      RA : constant Rational := Reduce (A);
      RB : constant Rational := Reduce (B);
   begin
      return Make_Rational
        (RA.Num * Integer (RB.Den) + RB.Num * Integer (RA.Den),
         Integer (RA.Den) * Integer (RB.Den));
   end "+";

   function "-" (A : Rational) return Rational is
      RA : constant Rational := Reduce (A);
   begin
      return (Num => -RA.Num, Den => RA.Den);
   end "-";

   function "-" (A, B : Rational) return Rational is
   begin
      return A + (-B);
   end "-";

   function "*" (A, B : Rational) return Rational is
      RA : constant Rational := Reduce (A);
      RB : constant Rational := Reduce (B);
   begin
      return Make_Rational
        (RA.Num * RB.Num, Integer (RA.Den) * Integer (RB.Den));
   end "*";

   function "/" (A, B : Rational) return Rational is
      RB : constant Rational := Reduce (B);
   begin
      if RB.Num = 0 then
         raise Division_By_Zero;
      end if;
      return A * Make_Rational (Integer (RB.Den), RB.Num);
   end "/";

   function Abs_Val (R : Rational) return Rational is
      RR : constant Rational := Reduce (R);
   begin
      if RR.Num < 0 then
         return (Num => -RR.Num, Den => RR.Den);
      else
         return RR;
      end if;
   end Abs_Val;

   function Pow_Nat (Base : Rational; Exp : Natural) return Rational is
      Result : Rational := One_Q;
   begin
      for I in 1 .. Exp loop
         Result := Result * Base;
      end loop;
      return Result;
   end Pow_Nat;

   ------------------------------------------------------------------
   -- Polynomials
   ------------------------------------------------------------------

   function Trim (P : Polynomial) return Polynomial is
      Result : Polynomial := P;
      D      : Integer := Max_Degree;
   begin
      while D >= 0 and then Is_Zero (Result.Coeffs (Degree_Index (D))) loop
         Result.Coeffs (Degree_Index (D)) := Zero_Q;
         D := D - 1;
      end loop;
      for I in Degree_Index loop
         if D >= 0 and then I <= D then
            Result.Coeffs (I) := Reduce (Result.Coeffs (I));
         else
            Result.Coeffs (I) := Zero_Q;
         end if;
      end loop;
      return Result;
   end Trim;

   function Degree (P : Polynomial) return Integer is
      T : constant Polynomial := Trim (P);
   begin
      for I in reverse Degree_Index loop
         if not Is_Zero (T.Coeffs (I)) then
            return I;
         end if;
      end loop;
      return -1;
   end Degree;

   function Is_Zero (P : Polynomial) return Boolean is
   begin
      return Degree (P) < 0;
   end Is_Zero;

   function Leading_Coefficient (P : Polynomial) return Rational is
      D : constant Integer := Degree (P);
   begin
      if D < 0 then
         return Zero_Q;
      end if;
      return Reduce (Trim (P).Coeffs (Degree_Index (D)));
   end Leading_Coefficient;

   function Equal (A, B : Polynomial) return Boolean is
      TA : constant Polynomial := Trim (A);
      TB : constant Polynomial := Trim (B);
   begin
      for I in Degree_Index loop
         if not Equal (TA.Coeffs (I), TB.Coeffs (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Equal;

   function Monomial
     (Coeff : Rational; Power : Natural) return Polynomial
   is
      Result : Polynomial := Zero_Poly;
   begin
      if Power > Max_Degree then
         raise Invalid_Argument;
      end if;
      if not Is_Zero (Coeff) then
         Result.Coeffs (Degree_Index (Power)) := Reduce (Coeff);
      end if;
      return Result;
   end Monomial;

   function Constant_Poly (Coeff : Rational) return Polynomial is
   begin
      return Monomial (Coeff, 0);
   end Constant_Poly;

   function Integer_Poly (C : Integer) return Polynomial is
   begin
      return Constant_Poly (Make_Rational (C, 1));
   end Integer_Poly;

   function Add (A, B : Polynomial) return Polynomial is
      Result : Polynomial := Zero_Poly;
      TA     : constant Polynomial := Trim (A);
      TB     : constant Polynomial := Trim (B);
   begin
      for I in Degree_Index loop
         Result.Coeffs (I) := TA.Coeffs (I) + TB.Coeffs (I);
      end loop;
      return Trim (Result);
   end Add;

   function Sub (A, B : Polynomial) return Polynomial is
      Result : Polynomial := Zero_Poly;
      TA     : constant Polynomial := Trim (A);
      TB     : constant Polynomial := Trim (B);
   begin
      for I in Degree_Index loop
         Result.Coeffs (I) := TA.Coeffs (I) - TB.Coeffs (I);
      end loop;
      return Trim (Result);
   end Sub;

   function Mul (A, B : Polynomial) return Polynomial is
      TA     : constant Polynomial := Trim (A);
      TB     : constant Polynomial := Trim (B);
      DA     : constant Integer := Degree (TA);
      DB     : constant Integer := Degree (TB);
      Result : Polynomial := Zero_Poly;
   begin
      if DA < 0 or else DB < 0 then
         return Zero_Poly;
      end if;
      if DA + DB > Max_Degree then
         raise Invalid_Argument;
      end if;
      for I in 0 .. DA loop
         for J in 0 .. DB loop
            declare
               K    : constant Degree_Index := Degree_Index (I + J);
               Term : constant Rational :=
                 TA.Coeffs (Degree_Index (I)) * TB.Coeffs (Degree_Index (J));
            begin
               Result.Coeffs (K) := Result.Coeffs (K) + Term;
            end;
         end loop;
      end loop;
      return Trim (Result);
   end Mul;

   function Scale (P : Polynomial; S : Rational) return Polynomial is
      Result : Polynomial := Zero_Poly;
      T      : constant Polynomial := Trim (P);
   begin
      if Is_Zero (S) then
         return Zero_Poly;
      end if;
      for I in Degree_Index loop
         Result.Coeffs (I) := T.Coeffs (I) * S;
      end loop;
      return Trim (Result);
   end Scale;

   procedure Divide
     (Dividend  :     Polynomial;
      Divisor   :     Polynomial;
      Quotient  : out Polynomial;
      Remainder : out Polynomial)
   is
      G    : constant Polynomial := Trim (Divisor);
      DG   : constant Integer := Degree (G);
      F    : Polynomial;
      Q    : Polynomial := Zero_Poly;
      LC_G : Rational;
   begin
      if DG < 0 then
         raise Division_By_Zero;
      end if;

      LC_G := Leading_Coefficient (G);
      F := Trim (Dividend);

      while Degree (F) >= DG loop
         declare
            DF      : constant Integer := Degree (F);
            T_Power : constant Natural := Natural (DF - DG);
            T_Coeff : constant Rational :=
              Leading_Coefficient (F) / LC_G;
            T_Poly  : constant Polynomial := Monomial (T_Coeff, T_Power);
            Prod    : constant Polynomial := Mul (T_Poly, G);
         begin
            F := Sub (F, Prod);
            Q := Add (Q, T_Poly);
         end;
      end loop;

      Quotient  := Trim (Q);
      Remainder := Trim (F);
   end Divide;

   function Exact_Quotient (Dividend, Divisor : Polynomial) return Polynomial
   is
      Q, R : Polynomial;
   begin
      Divide (Dividend, Divisor, Q, R);
      if not Is_Zero (R) then
         raise Invalid_Argument;
      end if;
      return Q;
   end Exact_Quotient;

   function Make_Monic (P : Polynomial) return Polynomial is
      D  : constant Integer := Degree (P);
      LC : Rational;
   begin
      if D < 0 then
         return Zero_Poly;
      end if;
      LC := Leading_Coefficient (P);
      if Equal (LC, One_Q) then
         return Trim (P);
      end if;
      return Scale (P, One_Q / LC);
   end Make_Monic;

   function Poly_GCD (A, B : Polynomial) return Polynomial is
      U : Polynomial := Trim (A);
      V : Polynomial := Trim (B);
      Q, R : Polynomial;
   begin
      while not Is_Zero (V) loop
         Divide (U, V, Q, R);
         U := V;
         V := R;
      end loop;
      return Make_Monic (U);
   end Poly_GCD;

   function Shift (P : Polynomial; K : Integer) return Polynomial is
      T      : constant Polynomial := Trim (P);
      D      : constant Integer := Degree (T);
      Result : Polynomial := Zero_Poly;
   begin
      if D < 0 then
         return Zero_Poly;
      end if;
      --  P(n+K) = sum_i p_i (n+K)^i = sum_i p_i sum_j C(i,j) n^j K^{i-j}
      for I in 0 .. D loop
         declare
            Pi : constant Rational := T.Coeffs (Degree_Index (I));
         begin
            if not Is_Zero (Pi) then
               for J in 0 .. I loop
                  declare
                     Bin  : constant Integer := Binomial (Natural (I), Natural (J));
                     Kpow : constant Integer := Int_Pow (K, Natural (I - J));
                     Term : constant Rational :=
                       Pi * Make_Rational (Bin * Kpow, 1);
                  begin
                     if J > Max_Degree then
                        raise Invalid_Argument;
                     end if;
                     Result.Coeffs (Degree_Index (J)) :=
                       Result.Coeffs (Degree_Index (J)) + Term;
                  end;
               end loop;
            end if;
         end;
      end loop;
      return Trim (Result);
   end Shift;

   function Eval (P : Polynomial; N : Integer) return Rational is
      T      : constant Polynomial := Trim (P);
      D      : constant Integer := Degree (T);
      Result : Rational := Zero_Q;
      Pow    : Rational := One_Q;
      NQ     : constant Rational := Make_Rational (N, 1);
   begin
      if D < 0 then
         return Zero_Q;
      end if;
      for I in 0 .. D loop
         Result := Result + T.Coeffs (Degree_Index (I)) * Pow;
         Pow := Pow * NQ;
      end loop;
      return Result;
   end Eval;

   ------------------------------------------------------------------
   -- Term constructors
   ------------------------------------------------------------------

   function Make_Polynomial_Term (P : Polynomial) return Term_Spec is
   begin
      return (Kind   => Polynomial_Term,
              Poly   => Trim (P),
              A      => Integer_Poly (1),
              B      => Integer_Poly (1),
              Ratio  => One_Q,
              Seed_N => 0,
              Seed_T => One_Q);
   end Make_Polynomial_Term;

   function Make_Ratio_Term
     (A, B : Polynomial;
      Seed_N : Integer := 0;
      Seed_T : Rational := One_Q) return Term_Spec
   is
   begin
      if Is_Zero (B) then
         raise Invalid_Argument;
      end if;
      return (Kind   => Ratio_Term,
              Poly   => Zero_Poly,
              A      => Trim (A),
              B      => Trim (B),
              Ratio  => One_Q,
              Seed_N => Seed_N,
              Seed_T => Reduce (Seed_T));
   end Make_Ratio_Term;

   function Make_Geometric_Term (R : Rational) return Term_Spec is
   begin
      return (Kind   => Geometric_Term,
              Poly   => Zero_Poly,
              A      => Constant_Poly (Reduce (R)),
              B      => Integer_Poly (1),
              Ratio  => Reduce (R),
              Seed_N => 0,
              Seed_T => One_Q);
   end Make_Geometric_Term;

   ------------------------------------------------------------------
   -- Gosper normal form
   ------------------------------------------------------------------

   procedure Gosper_Normal_Form
     (A_In, B_In           :     Polynomial;
      A_Out, B_Out, C_Out  : out Polynomial)
   is
      A       : Polynomial := Trim (A_In);
      B       : Polynomial := Trim (B_In);
      C       : Polynomial := Integer_Poly (1);
      Changed : Boolean;
      Bound   : constant Natural := Max_Degree + 1;
      Guard   : Natural := 0;
   begin
      if Is_Zero (B) then
         raise Invalid_Argument;
      end if;

      loop
         Changed := False;
         Guard := Guard + 1;
         if Guard > Bound * Bound + 4 then
            raise Invalid_Argument;
         end if;

         for J in 1 .. Bound loop
            declare
               G : constant Polynomial := Poly_GCD (A, Shift (B, J));
            begin
               if Degree (G) > 0 then
                  A := Exact_Quotient (A, G);
                  B := Exact_Quotient (B, Shift (G, -J));
                  for I in 1 .. J loop
                     C := Mul (C, Shift (G, -I));
                  end loop;
                  Changed := True;
                  exit;
               end if;
            end;
         end loop;

         exit when not Changed;
      end loop;

      A_Out := Trim (A);
      B_Out := Trim (B);
      C_Out := Trim (C);
   end Gosper_Normal_Form;

   ------------------------------------------------------------------
   -- Linear algebra over Q (dense, small)
   ------------------------------------------------------------------

      type Matrix_Q is array
     (Degree_Index, Degree_Index) of Rational;

   type Vector_Q is array (Degree_Index) of Rational;

   --  Gaussian elimination: Mat(0..N_Eq-1, 0..N_Unk-1) * x = RHS(0..N_Eq-1).
   --  Augment with RHS in column N_Unk when N_Unk <= Max_Degree.
   procedure Gaussian_Solve
     (N_Eq, N_Unk : Natural;
      Mat         : in out Matrix_Q;
      RHS         : in out Vector_Q;
      Sol         : out Vector_Q;
      Found       : out Boolean)
   is
   begin
      Sol := [others => Zero_Q];
      Found := False;

      if N_Unk = 0 then
         for I in 0 .. Natural'Max (0, N_Eq) - 1 loop
            if N_Eq > 0 and then not Is_Zero (RHS (Degree_Index (I))) then
               return;
            end if;
         end loop;
         Found := True;
         return;
      end if;

      declare
         Pivot_Row : array (Degree_Index) of Integer := [others => -1];
         Col_Used  : array (Degree_Index) of Boolean := [others => False];
         Row       : Natural := 0;
      begin
         for Col in 0 .. N_Unk - 1 loop
            declare
               Pivot : Integer := -1;
            begin
               for R in Row .. N_Eq - 1 loop
                  if not Is_Zero (Mat (Degree_Index (R), Degree_Index (Col)))
                  then
                     Pivot := Integer (R);
                     exit;
                  end if;
               end loop;

               if Pivot < 0 then
                  null;
               else
                  --  Swap rows Row and Pivot
                  if Pivot /= Integer (Row) then
                     for C in 0 .. N_Unk - 1 loop
                        declare
                           Tmp : constant Rational :=
                             Mat (Degree_Index (Row), Degree_Index (C));
                        begin
                           Mat (Degree_Index (Row), Degree_Index (C)) :=
                             Mat (Degree_Index (Pivot), Degree_Index (C));
                           Mat (Degree_Index (Pivot), Degree_Index (C)) := Tmp;
                        end;
                     end loop;
                     declare
                        Tmp : constant Rational := RHS (Degree_Index (Row));
                     begin
                        RHS (Degree_Index (Row)) :=
                          RHS (Degree_Index (Pivot));
                        RHS (Degree_Index (Pivot)) := Tmp;
                     end;
                  end if;

                  declare
                     PV : constant Rational :=
                       Mat (Degree_Index (Row), Degree_Index (Col));
                  begin
                     for C in 0 .. N_Unk - 1 loop
                        Mat (Degree_Index (Row), Degree_Index (C)) :=
                          Mat (Degree_Index (Row), Degree_Index (C)) / PV;
                     end loop;
                     RHS (Degree_Index (Row)) := RHS (Degree_Index (Row)) / PV;
                  end;

                  for R in 0 .. N_Eq - 1 loop
                     if R /= Row then
                        declare
                           F : constant Rational :=
                             Mat (Degree_Index (R), Degree_Index (Col));
                        begin
                           if not Is_Zero (F) then
                              for C in 0 .. N_Unk - 1 loop
                                 Mat (Degree_Index (R), Degree_Index (C)) :=
                                   Mat (Degree_Index (R), Degree_Index (C))
                                   - F * Mat (Degree_Index (Row),
                                              Degree_Index (C));
                              end loop;
                              RHS (Degree_Index (R)) :=
                                RHS (Degree_Index (R))
                                - F * RHS (Degree_Index (Row));
                           end if;
                        end;
                     end if;
                  end loop;

                  Pivot_Row (Degree_Index (Col)) := Integer (Row);
                  Col_Used (Degree_Index (Col)) := True;
                  Row := Row + 1;
                  exit when Row >= N_Eq;
               end if;
            end;
         end loop;

         --  Consistency: zero rows must have zero RHS
         for R in 0 .. N_Eq - 1 loop
            declare
               All_Zero : Boolean := True;
            begin
               for C in 0 .. N_Unk - 1 loop
                  if not Is_Zero (Mat (Degree_Index (R), Degree_Index (C)))
                  then
                     All_Zero := False;
                     exit;
                  end if;
               end loop;
               if All_Zero and then not Is_Zero (RHS (Degree_Index (R))) then
                  Found := False;
                  return;
               end if;
            end;
         end loop;

         --  Back-substitute free vars = 0; particular solution
         for C in 0 .. N_Unk - 1 loop
            if Col_Used (Degree_Index (C)) then
               Sol (Degree_Index (C)) :=
                 RHS (Degree_Index (Pivot_Row (Degree_Index (C))));
            else
               Sol (Degree_Index (C)) := Zero_Q;
            end if;
         end loop;

         Found := True;
      end;
   end Gaussian_Solve;

   ------------------------------------------------------------------
   -- Solve a(n) X(n+1) - b(n-1) X(n) = c(n)
   ------------------------------------------------------------------

   procedure Solve_Certificate
     (A_G, B_G, C_G :     Polynomial;
      X             : out Polynomial;
      Found         : out Boolean)
   is
      B_M1 : constant Polynomial := Shift (Trim (B_G), -1);
      C    : constant Polynomial := Trim (C_G);
      A    : constant Polynomial := Trim (A_G);
      DA0  : constant Integer := Degree (A);
      DB0  : constant Integer := Degree (B_M1);
      Max_DX : Integer := Max_Degree;
   begin
      X := Zero_Poly;
      Found := False;

      --  Keep A*X(n+1) and B_M1*X inside Max_Degree.
      if DA0 >= 0 then
         Max_DX := Integer'Min (Max_DX, Max_Degree - DA0);
      end if;
      if DB0 >= 0 then
         Max_DX := Integer'Min (Max_DX, Max_Degree - DB0);
      end if;
      if Max_DX < 0 then
         return;
      end if;

      --  Try increasing degree of X from 0 .. Max_DX
      for Deg_X in 0 .. Max_DX loop
         declare
            N_Unk : constant Natural := Deg_X + 1;
            --  LHS degree bound
            Deg_LHS : Integer;
            N_Eq    : Natural;
            Mat     : Matrix_Q := [others => [others => Zero_Q]];
            RHS     : Vector_Q := [others => Zero_Q];
            Sol     : Vector_Q;
            Ok      : Boolean;
            DA      : constant Integer := DA0;
            DB      : constant Integer := DB0;
         begin
            Deg_LHS := Integer'Max (DA, DB) + Deg_X;
            if Deg_LHS < Degree (C) then
               Deg_LHS := Degree (C);
            end if;
            if Deg_LHS < 0 then
               Deg_LHS := 0;
            end if;
            if Deg_LHS > Max_Degree then
               Deg_LHS := Max_Degree;
            end if;
            N_Eq := Natural (Deg_LHS) + 1;

            --  For each unknown coeff x_k of X = sum x_k n^k:
            --  contrib of e_k: A(n)*Shift(n^k,1) - B_M1(n)*n^k
            for K in 0 .. Deg_X loop
               declare
                  EK      : constant Polynomial :=
                    Monomial (One_Q, Natural (K));
                  Shift_E : constant Polynomial := Shift (EK, 1);
                  TermA   : Polynomial;
                  TermB   : Polynomial;
                  Contrib : Polynomial;
               begin
                  if Is_Zero (A) then
                     TermA := Zero_Poly;
                  else
                     TermA := Mul (A, Shift_E);
                  end if;
                  if Is_Zero (B_M1) then
                     TermB := Zero_Poly;
                  else
                     TermB := Mul (B_M1, EK);
                  end if;
                  Contrib := Sub (TermA, TermB);
                  for Row in 0 .. Integer (N_Eq) - 1 loop
                     Mat (Degree_Index (Row), Degree_Index (K)) :=
                       Contrib.Coeffs (Degree_Index (Row));
                  end loop;
               end;
            end loop;

            for Row in 0 .. Integer (N_Eq) - 1 loop
               if Degree (C) >= 0 and then Row <= Degree (C) then
                  RHS (Degree_Index (Row)) := C.Coeffs (Degree_Index (Row));
               else
                  RHS (Degree_Index (Row)) := Zero_Q;
               end if;
            end loop;

            Gaussian_Solve (N_Eq, N_Unk, Mat, RHS, Sol, Ok);

            if Ok then
               --  Verify identity exactly (guards free-variable underdet.)
               declare
                  Cand   : Polynomial := Zero_Poly;
                  CheckA : Polynomial;
                  CheckB : Polynomial;
                  LHS    : Polynomial;
               begin
                  for K in 0 .. Deg_X loop
                     Cand.Coeffs (Degree_Index (K)) := Sol (Degree_Index (K));
                  end loop;
                  Cand := Trim (Cand);
                  CheckA := Mul (A, Shift (Cand, 1));
                  CheckB := Mul (B_M1, Cand);
                  LHS := Sub (CheckA, CheckB);
                  if Equal (LHS, C) then
                     X := Cand;
                     Found := True;
                     return;
                  end if;
               end;
            end if;
         end;
      end loop;
   end Solve_Certificate;

   ------------------------------------------------------------------
   -- Eval helpers for terms / antidifferences
   ------------------------------------------------------------------

   function Eval_Term (Term : Term_Spec; N : Integer) return Rational is
   begin
      case Term.Kind is
         when Polynomial_Term =>
            return Eval (Term.Poly, N);
         when Geometric_Term =>
            if N < 0 then
               raise Invalid_Argument;
            end if;
            return Pow_Nat (Term.Ratio, Natural (N));
         when Ratio_Term =>
            declare
               --  Walk from Seed_N to N multiplying/dividing by A/B
               T    : Rational := Term.Seed_T;
               Step : Integer;
               Cur  : Integer := Term.Seed_N;
            begin
               if N = Term.Seed_N then
                  return T;
               elsif N > Term.Seed_N then
                  Step := 1;
               else
                  Step := -1;
               end if;
               while Cur /= N loop
                  if Step > 0 then
                     --  t(cur+1) = t(cur) * A(cur)/B(cur)
                     declare
                        Av : constant Rational := Eval (Term.A, Cur);
                        Bv : constant Rational := Eval (Term.B, Cur);
                     begin
                        if Is_Zero (Bv) then
                           raise Invalid_Argument;
                        end if;
                        T := T * (Av / Bv);
                     end;
                     Cur := Cur + 1;
                  else
                     --  t(cur) = t(cur-1) * A(cur-1)/B(cur-1)
                     --  => t(cur-1) = t(cur) * B(cur-1)/A(cur-1)
                     declare
                        Av : constant Rational := Eval (Term.A, Cur - 1);
                        Bv : constant Rational := Eval (Term.B, Cur - 1);
                     begin
                        if Is_Zero (Av) then
                           raise Invalid_Argument;
                        end if;
                        T := T * (Bv / Av);
                     end;
                     Cur := Cur - 1;
                  end if;
               end loop;
               return T;
            end;
      end case;
   end Eval_Term;

   function Eval_Antidifference
     (Term : Term_Spec;
      Anti : Antidifference_Spec;
      N    : Integer) return Rational
   is
   begin
      if Anti.Is_Polynomial_Closed then
         return Eval (Anti.S_Poly, N);
      end if;

      --  S(n) = B_Gosper(n-1) * X(n) / C_Gosper(n) * t(n)
      declare
         Bn1 : constant Rational := Eval (Anti.B_Gosper, N - 1);
         Xn  : constant Rational := Eval (Anti.X, N);
         Cn  : constant Rational := Eval (Anti.C_Gosper, N);
         Tn  : constant Rational := Eval_Term (Term, N);
      begin
         if Is_Zero (Cn) then
            raise Invalid_Argument;
         end if;
         return ((Bn1 * Xn) / Cn) * Tn;
      end;
   end Eval_Antidifference;

   function Verify_Telescoping
     (Term : Term_Spec;
      Anti : Antidifference_Spec;
      N    : Integer) return Boolean
   is
      SN   : Rational;
      SN1  : Rational;
      TN   : Rational;
      Diff : Rational;
   begin
      SN  := Eval_Antidifference (Term, Anti, N);
      SN1 := Eval_Antidifference (Term, Anti, N + 1);
      TN  := Eval_Term (Term, N);
      Diff := SN1 - SN;
      return Equal (Diff, TN);
   end Verify_Telescoping;

   ------------------------------------------------------------------
   -- Main Gosper entry
   ------------------------------------------------------------------

   function Try_Gosper_Sum (Term : Term_Spec) return Gosper_Result is
      Result : Gosper_Result;
      A_In, B_In : Polynomial;
      A_G, B_G, C_G : Polynomial;
      X : Polynomial;
      Ok : Boolean;
   begin
      Result.Found := False;

      case Term.Kind is
         when Polynomial_Term =>
            --  t(n)=P(n): use a=1,b=1,c=P  =>  X(n+1)-X(n)=P(n)
            if Degree (Term.Poly) > Max_Degree then
               raise Invalid_Argument;
            end if;
            A_In := Integer_Poly (1);
            B_In := Integer_Poly (1);
            A_G := A_In;
            B_G := B_In;
            C_G := Trim (Term.Poly);
            Solve_Certificate (A_G, B_G, C_G, X, Ok);
            if Ok then
               Result.Found := True;
               Result.Antidifference :=
                 (A_Gosper             => A_G,
                  B_Gosper             => B_G,
                  C_Gosper             =>
                    (if Is_Zero (C_G) then Integer_Poly (1) else C_G),
                  X                    => X,
                  S_Poly               => X,
                  Is_Polynomial_Closed => True);
               --  When C=P and a=b=1: S = b(n-1) X / C * t = X/P * P = X
               if Is_Zero (C_G) then
                  --  t=0 => S=0
                  Result.Antidifference.S_Poly := Zero_Poly;
                  Result.Antidifference.X := Zero_Poly;
                  Result.Antidifference.C_Gosper := Integer_Poly (1);
               end if;
            end if;

         when Geometric_Term =>
            --  t(n)=r^n, ratio = r/1
            A_In := Constant_Poly (Term.Ratio);
            B_In := Integer_Poly (1);
            Gosper_Normal_Form (A_In, B_In, A_G, B_G, C_G);
            Solve_Certificate (A_G, B_G, C_G, X, Ok);
            if Ok then
               Result.Found := True;
               Result.Antidifference :=
                 (A_Gosper             => A_G,
                  B_Gosper             => B_G,
                  C_Gosper             => C_G,
                  X                    => X,
                  S_Poly               => Zero_Poly,
                  Is_Polynomial_Closed => False);
            end if;

         when Ratio_Term =>
            if Is_Zero (Term.B) then
               raise Invalid_Argument;
            end if;
            if Degree (Term.A) > Max_Degree
              or else Degree (Term.B) > Max_Degree
            then
               raise Invalid_Argument;
            end if;
            Gosper_Normal_Form (Term.A, Term.B, A_G, B_G, C_G);
            Solve_Certificate (A_G, B_G, C_G, X, Ok);
            if Ok then
               Result.Found := True;
               Result.Antidifference :=
                 (A_Gosper             => A_G,
                  B_Gosper             => B_G,
                  C_Gosper             => C_G,
                  X                    => X,
                  S_Poly               => Zero_Poly,
                  Is_Polynomial_Closed => False);
            end if;
      end case;

      return Result;
   end Try_Gosper_Sum;

end Gospers_Algorithm;
