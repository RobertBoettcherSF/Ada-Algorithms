--  Body for Polynomial_Long_Division — exact Euclidean division over Q.

pragma Ada_2022;

package body Polynomial_Long_Division
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

   function From_Coeffs
     (C     : Coeff_Array;
      First : Degree_Index := 0;
      Last  : Degree_Index) return Polynomial
   is
      Result : Polynomial := Zero_Poly;
   begin
      for I in First .. Last loop
         Result.Coeffs (I) := Reduce (C (I));
      end loop;
      return Trim (Result);
   end From_Coeffs;

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

end Polynomial_Long_Division;
