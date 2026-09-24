--  Body for Multivariate_Division_Algorithm — sparse bivariate division over Q.

pragma Ada_2022;

package body Multivariate_Division_Algorithm
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

   ------------------------------------------------------------------
   -- Monomial comparison
   ------------------------------------------------------------------

   function Compare_Monomials
     (AX, AY, BX, BY : Exp_Type;
      Order          : Monomial_Order) return Integer
   is
   begin
      case Order is
         when Lex =>
            if AX > BX then
               return 1;
            elsif AX < BX then
               return -1;
            elsif AY > BY then
               return 1;
            elsif AY < BY then
               return -1;
            else
               return 0;
            end if;

         when Grevlex =>
            declare
               DA : constant Natural := Natural (AX) + Natural (AY);
               DB : constant Natural := Natural (BX) + Natural (BY);
               DX : constant Integer := Integer (AX) - Integer (BX);
               DY : constant Integer := Integer (AY) - Integer (BY);
            begin
               if DA > DB then
                  return 1;
               elsif DA < DB then
                  return -1;
               end if;
               --  Same total degree: rightmost nonzero of (A−B) negative ⇒ A > B.
               if DY /= 0 then
                  if DY < 0 then
                     return 1;
                  else
                     return -1;
                  end if;
               end if;
               if DX /= 0 then
                  if DX < 0 then
                     return 1;
                  else
                     return -1;
                  end if;
               end if;
               return 0;
            end;
      end case;
   end Compare_Monomials;

   function Monomial_Divides
     (DX, DY, TX, TY : Exp_Type) return Boolean
   is
   begin
      return DX <= TX and then DY <= TY;
   end Monomial_Divides;

   ------------------------------------------------------------------
   -- Internal: find / insert helpers
   ------------------------------------------------------------------

   function Find_Leading_Index
     (P     : Polynomial;
      Order : Monomial_Order) return Natural
   is
      Best : Natural := 0;
   begin
      for I in 1 .. P.Count loop
         if not Is_Zero (P.Terms (I).Coeff) then
            if Best = 0
              or else Compare_Monomials
                (P.Terms (I).Exp_X, P.Terms (I).Exp_Y,
                 P.Terms (Best).Exp_X, P.Terms (Best).Exp_Y,
                 Order) > 0
            then
               Best := I;
            end if;
         end if;
      end loop;
      return Best;
   end Find_Leading_Index;

   procedure Append_Raw (P : in out Polynomial; T : Term) is
   begin
      if Is_Zero (T.Coeff) then
         return;
      end if;
      if P.Count = Max_Terms then
         raise Invalid_Argument;
      end if;
      P.Count := P.Count + 1;
      P.Terms (P.Count) :=
        (Coeff => Reduce (T.Coeff), Exp_X => T.Exp_X, Exp_Y => T.Exp_Y);
   end Append_Raw;

   ------------------------------------------------------------------
   -- Normalize / equality / constructors
   ------------------------------------------------------------------

   function Normalize
     (P     : Polynomial;
      Order : Monomial_Order := Lex) return Polynomial
   is
      Acc    : Polynomial := Zero_Poly;
      Result : Polynomial := Zero_Poly;
      Used   : array (Term_Index) of Boolean := [others => False];
      Found  : Boolean;
   begin
      --  Combine like terms into Acc (unsorted).
      for I in 1 .. P.Count loop
         if not Is_Zero (P.Terms (I).Coeff) then
            Found := False;
            for J in 1 .. Acc.Count loop
               if Acc.Terms (J).Exp_X = P.Terms (I).Exp_X
                 and then Acc.Terms (J).Exp_Y = P.Terms (I).Exp_Y
               then
                  Acc.Terms (J).Coeff :=
                    Acc.Terms (J).Coeff + P.Terms (I).Coeff;
                  Found := True;
                  exit;
               end if;
            end loop;
            if not Found then
               Append_Raw (Acc, P.Terms (I));
            end if;
         end if;
      end loop;

      --  Drop zeros that appeared after combining.
      declare
         Tmp : Polynomial := Zero_Poly;
      begin
         for I in 1 .. Acc.Count loop
            if not Is_Zero (Acc.Terms (I).Coeff) then
               Append_Raw
                 (Tmp,
                  (Coeff => Reduce (Acc.Terms (I).Coeff),
                   Exp_X => Acc.Terms (I).Exp_X,
                   Exp_Y => Acc.Terms (I).Exp_Y));
            end if;
         end loop;
         Acc := Tmp;
      end;

      --  Sort descending by Order (selection).
      for K in 1 .. Acc.Count loop
         declare
            Best : Natural := 0;
         begin
            for I in 1 .. Acc.Count loop
               if not Used (I) then
                  if Best = 0
                    or else Compare_Monomials
                      (Acc.Terms (I).Exp_X, Acc.Terms (I).Exp_Y,
                       Acc.Terms (Best).Exp_X, Acc.Terms (Best).Exp_Y,
                       Order) > 0
                  then
                     Best := I;
                  end if;
               end if;
            end loop;
            exit when Best = 0;
            Used (Best) := True;
            Append_Raw (Result, Acc.Terms (Best));
         end;
      end loop;

      return Result;
   end Normalize;

   function Is_Zero (P : Polynomial) return Boolean is
      N : constant Polynomial := Normalize (P, Lex);
   begin
      return N.Count = 0;
   end Is_Zero;

   function Equal
     (A, B  : Polynomial;
      Order : Monomial_Order := Lex) return Boolean
   is
      NA : constant Polynomial := Normalize (A, Order);
      NB : constant Polynomial := Normalize (B, Order);
   begin
      if NA.Count /= NB.Count then
         return False;
      end if;
      for I in 1 .. NA.Count loop
         if NA.Terms (I).Exp_X /= NB.Terms (I).Exp_X
           or else NA.Terms (I).Exp_Y /= NB.Terms (I).Exp_Y
           or else not Equal (NA.Terms (I).Coeff, NB.Terms (I).Coeff)
         then
            return False;
         end if;
      end loop;
      return True;
   end Equal;

   function Make_Term
     (Coeff : Rational;
      Exp_X : Natural;
      Exp_Y : Natural) return Term
   is
   begin
      if Exp_X > Max_Degree or else Exp_Y > Max_Degree then
         raise Invalid_Argument;
      end if;
      return (Coeff => Reduce (Coeff),
              Exp_X => Exp_Type (Exp_X),
              Exp_Y => Exp_Type (Exp_Y));
   end Make_Term;

   function From_Term (T : Term) return Polynomial is
      P : Polynomial := Zero_Poly;
   begin
      if Is_Zero (T.Coeff) then
         return Zero_Poly;
      end if;
      Append_Raw (P, T);
      return P;
   end From_Term;

   function Monomial
     (Coeff : Rational;
      Exp_X : Natural;
      Exp_Y : Natural) return Polynomial
   is
   begin
      return From_Term (Make_Term (Coeff, Exp_X, Exp_Y));
   end Monomial;

   function Constant_Poly (Coeff : Rational) return Polynomial is
   begin
      return Monomial (Coeff, 0, 0);
   end Constant_Poly;

   function Integer_Poly (C : Integer) return Polynomial is
   begin
      return Constant_Poly (Make_Rational (C, 1));
   end Integer_Poly;

   function Uni_X (Coeff : Rational; Power : Natural) return Polynomial is
   begin
      return Monomial (Coeff, Power, 0);
   end Uni_X;

   function Uni_Y (Coeff : Rational; Power : Natural) return Polynomial is
   begin
      return Monomial (Coeff, 0, Power);
   end Uni_Y;

   ------------------------------------------------------------------
   -- Leading term / monomial / coefficient
   ------------------------------------------------------------------

   function LT (P : Polynomial; Order : Monomial_Order) return Term is
      N : constant Polynomial := Normalize (P, Order);
   begin
      if N.Count = 0 then
         return (Coeff => Zero_Q, Exp_X => 0, Exp_Y => 0);
      end if;
      return N.Terms (1);
   end LT;

   function LM
     (P     : Polynomial;
      Order : Monomial_Order;
      Exp_X : out Exp_Type;
      Exp_Y : out Exp_Type) return Boolean
   is
      T : constant Term := LT (P, Order);
   begin
      if Is_Zero (T.Coeff) then
         Exp_X := 0;
         Exp_Y := 0;
         return False;
      end if;
      Exp_X := T.Exp_X;
      Exp_Y := T.Exp_Y;
      return True;
   end LM;

   function LC (P : Polynomial; Order : Monomial_Order) return Rational is
   begin
      return LT (P, Order).Coeff;
   end LC;

   ------------------------------------------------------------------
   -- Arithmetic
   ------------------------------------------------------------------

   function Add
     (A, B  : Polynomial;
      Order : Monomial_Order := Lex) return Polynomial
   is
      R : Polynomial := Zero_Poly;
   begin
      for I in 1 .. A.Count loop
         Append_Raw (R, A.Terms (I));
      end loop;
      for I in 1 .. B.Count loop
         Append_Raw (R, B.Terms (I));
      end loop;
      return Normalize (R, Order);
   end Add;

   function Sub
     (A, B  : Polynomial;
      Order : Monomial_Order := Lex) return Polynomial
   is
      Neg_B : Polynomial := Zero_Poly;
   begin
      for I in 1 .. B.Count loop
         Append_Raw
           (Neg_B,
            (Coeff => -B.Terms (I).Coeff,
             Exp_X => B.Terms (I).Exp_X,
             Exp_Y => B.Terms (I).Exp_Y));
      end loop;
      return Add (A, Neg_B, Order);
   end Sub;

   function Scale
     (P     : Polynomial;
      S     : Rational;
      Order : Monomial_Order := Lex) return Polynomial
   is
      R : Polynomial := Zero_Poly;
   begin
      if Is_Zero (S) then
         return Zero_Poly;
      end if;
      for I in 1 .. P.Count loop
         Append_Raw
           (R,
            (Coeff => P.Terms (I).Coeff * S,
             Exp_X => P.Terms (I).Exp_X,
             Exp_Y => P.Terms (I).Exp_Y));
      end loop;
      return Normalize (R, Order);
   end Scale;

   function Mul_Term
     (T     : Term;
      P     : Polynomial;
      Order : Monomial_Order := Lex) return Polynomial
   is
      R  : Polynomial := Zero_Poly;
      EX : Natural;
      EY : Natural;
   begin
      if Is_Zero (T.Coeff) or else Is_Zero (P) then
         return Zero_Poly;
      end if;
      for I in 1 .. P.Count loop
         EX := Natural (T.Exp_X) + Natural (P.Terms (I).Exp_X);
         EY := Natural (T.Exp_Y) + Natural (P.Terms (I).Exp_Y);
         if EX > Max_Degree or else EY > Max_Degree then
            raise Invalid_Argument;
         end if;
         Append_Raw
           (R,
            (Coeff => T.Coeff * P.Terms (I).Coeff,
             Exp_X => Exp_Type (EX),
             Exp_Y => Exp_Type (EY)));
      end loop;
      return Normalize (R, Order);
   end Mul_Term;

   function Mul
     (A, B  : Polynomial;
      Order : Monomial_Order := Lex) return Polynomial
   is
      R : Polynomial := Zero_Poly;
      T : Polynomial;
   begin
      if Is_Zero (A) or else Is_Zero (B) then
         return Zero_Poly;
      end if;
      for I in 1 .. A.Count loop
         T := Mul_Term (A.Terms (I), B, Order);
         R := Add (R, T, Order);
      end loop;
      return Normalize (R, Order);
   end Mul;

   ------------------------------------------------------------------
   -- Division algorithm
   ------------------------------------------------------------------

   function Drop_Leading
     (P     : Polynomial;
      Order : Monomial_Order) return Polynomial
   is
      N   : constant Polynomial := Normalize (P, Order);
      R   : Polynomial := Zero_Poly;
      Idx : constant Natural := Find_Leading_Index (N, Order);
   begin
      if Idx = 0 then
         return Zero_Poly;
      end if;
      for I in 1 .. N.Count loop
         if I /= Idx then
            Append_Raw (R, N.Terms (I));
         end if;
      end loop;
      return Normalize (R, Order);
   end Drop_Leading;

   procedure Divide
     (F         :     Polynomial;
      Divisors  :     Poly_Array;
      N         :     Divisor_Count;
      Order     :     Monomial_Order;
      Quotients : out Poly_Array;
      Remainder : out Polynomial)
   is
      G        : Poly_Array := Divisors;
      P        : Polynomial;
      R        : Polynomial := Zero_Poly;
      Q        : Poly_Array := [others => Zero_Poly];
      LT_P     : Term;
      LT_G     : Term;
      T_Term   : Term;
      Found    : Boolean;
      Pick     : Divisor_Index := 1;
      EX, EY   : Natural;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;

      for I in 1 .. N loop
         G (I) := Normalize (Divisors (I), Order);
         if Is_Zero (G (I)) then
            raise Division_By_Zero;
         end if;
      end loop;

      P := Normalize (F, Order);

      while not Is_Zero (P) loop
         LT_P := LT (P, Order);
         Found := False;
         Pick := 1;

         for I in 1 .. N loop
            LT_G := LT (G (I), Order);
            if Monomial_Divides
                 (LT_G.Exp_X, LT_G.Exp_Y, LT_P.Exp_X, LT_P.Exp_Y)
            then
               Found := True;
               Pick := I;
               exit;
            end if;
         end loop;

         if Found then
            LT_G := LT (G (Pick), Order);
            EX := Natural (LT_P.Exp_X) - Natural (LT_G.Exp_X);
            EY := Natural (LT_P.Exp_Y) - Natural (LT_G.Exp_Y);
            T_Term :=
              (Coeff => LT_P.Coeff / LT_G.Coeff,
               Exp_X => Exp_Type (EX),
               Exp_Y => Exp_Type (EY));
            Q (Pick) := Add (Q (Pick), From_Term (T_Term), Order);
            P := Sub (P, Mul_Term (T_Term, G (Pick), Order), Order);
         else
            R := Add (R, From_Term (LT_P), Order);
            P := Drop_Leading (P, Order);
         end if;
      end loop;

      Quotients := [others => Zero_Poly];
      for I in 1 .. N loop
         Quotients (I) := Normalize (Q (I), Order);
      end loop;
      Remainder := Normalize (R, Order);
   end Divide;

end Multivariate_Division_Algorithm;
