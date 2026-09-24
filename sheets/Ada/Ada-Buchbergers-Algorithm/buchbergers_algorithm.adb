--  Body for Buchbergers_Algorithm — educational bivariate Buchberger over Q.

pragma Ada_2022;

package body Buchbergers_Algorithm
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

   function Reduce_Q (R : Rational) return Rational is
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
   end Reduce_Q;

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
      return Reduce_Q ((Num => N, Den => Positive (D)));
   end Make_Rational;

   function Equal (A, B : Rational) return Boolean is
      RA : constant Rational := Reduce_Q (A);
      RB : constant Rational := Reduce_Q (B);
   begin
      return RA.Num = RB.Num and then RA.Den = RB.Den;
   end Equal;

   function Is_Zero (R : Rational) return Boolean is
   begin
      return Reduce_Q (R).Num = 0;
   end Is_Zero;

   function "+" (A, B : Rational) return Rational is
      RA : constant Rational := Reduce_Q (A);
      RB : constant Rational := Reduce_Q (B);
   begin
      return Make_Rational
        (RA.Num * Integer (RB.Den) + RB.Num * Integer (RA.Den),
         Integer (RA.Den) * Integer (RB.Den));
   end "+";

   function "-" (A : Rational) return Rational is
      RA : constant Rational := Reduce_Q (A);
   begin
      return (Num => -RA.Num, Den => RA.Den);
   end "-";

   function "-" (A, B : Rational) return Rational is
   begin
      return A + (-B);
   end "-";

   function "*" (A, B : Rational) return Rational is
      RA : constant Rational := Reduce_Q (A);
      RB : constant Rational := Reduce_Q (B);
   begin
      return Make_Rational
        (RA.Num * RB.Num, Integer (RA.Den) * Integer (RB.Den));
   end "*";

   function "/" (A, B : Rational) return Rational is
      RB : constant Rational := Reduce_Q (B);
   begin
      if RB.Num = 0 then
         raise Division_By_Zero;
      end if;
      return A * Make_Rational (Integer (RB.Den), RB.Num);
   end "/";

   ------------------------------------------------------------------
   -- Monomial comparison / LCM
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

   procedure Monomial_LCM
     (AX, AY, BX, BY :     Exp_Type;
      LX, LY         : out Exp_Type)
   is
   begin
      if AX >= BX then
         LX := AX;
      else
         LX := BX;
      end if;
      if AY >= BY then
         LY := AY;
      else
         LY := BY;
      end if;
   end Monomial_LCM;

   ------------------------------------------------------------------
   -- Internal poly helpers
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
        (Coeff => Reduce_Q (T.Coeff), Exp_X => T.Exp_X, Exp_Y => T.Exp_Y);
   end Append_Raw;

   function Normalize
     (P     : Polynomial;
      Order : Monomial_Order := Grevlex) return Polynomial
   is
      Acc    : Polynomial := Zero_Poly;
      Result : Polynomial := Zero_Poly;
      Used   : array (Term_Index) of Boolean := [others => False];
      Found  : Boolean;
   begin
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

      declare
         Tmp : Polynomial := Zero_Poly;
      begin
         for I in 1 .. Acc.Count loop
            if not Is_Zero (Acc.Terms (I).Coeff) then
               Append_Raw
                 (Tmp,
                  (Coeff => Reduce_Q (Acc.Terms (I).Coeff),
                   Exp_X => Acc.Terms (I).Exp_X,
                   Exp_Y => Acc.Terms (I).Exp_Y));
            end if;
         end loop;
         Acc := Tmp;
      end;

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
      Order : Monomial_Order := Grevlex) return Boolean
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
      return (Coeff => Reduce_Q (Coeff),
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

   function Add
     (A, B  : Polynomial;
      Order : Monomial_Order := Grevlex) return Polynomial
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
      Order : Monomial_Order := Grevlex) return Polynomial
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
      Order : Monomial_Order := Grevlex) return Polynomial
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
      Order : Monomial_Order := Grevlex) return Polynomial
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
      Order : Monomial_Order := Grevlex) return Polynomial
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

   ------------------------------------------------------------------
   -- Normal form / S-polynomial / LT ideal
   ------------------------------------------------------------------

   function Normal_Form
     (F        : Polynomial;
      Divisors : Poly_Array;
      N        : Poly_Count;
      Order    : Monomial_Order) return Polynomial
   is
      G      : Poly_Array := Divisors;
      P      : Polynomial;
      R      : Polynomial := Zero_Poly;
      LT_P   : Term;
      LT_G   : Term;
      T_Term : Term;
      Found  : Boolean;
      Pick   : Poly_Index := 1;
      EX, EY : Natural;
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
            P := Sub (P, Mul_Term (T_Term, G (Pick), Order), Order);
         else
            R := Add (R, From_Term (LT_P), Order);
            P := Drop_Leading (P, Order);
         end if;
      end loop;

      return Normalize (R, Order);
   end Normal_Form;

   function S_Polynomial
     (F, G  : Polynomial;
      Order : Monomial_Order) return Polynomial
   is
      NF : constant Polynomial := Normalize (F, Order);
      NG : constant Polynomial := Normalize (G, Order);
      LF : Term;
      LG : Term;
      LX, LY : Exp_Type;
      TX, TY : Natural;
      TF, TG : Term;
      Left, Right : Polynomial;
   begin
      if Is_Zero (NF) or else Is_Zero (NG) then
         raise Invalid_Argument;
      end if;
      LF := LT (NF, Order);
      LG := LT (NG, Order);
      Monomial_LCM (LF.Exp_X, LF.Exp_Y, LG.Exp_X, LG.Exp_Y, LX, LY);

      TX := Natural (LX) - Natural (LF.Exp_X);
      TY := Natural (LY) - Natural (LF.Exp_Y);
      TF := (Coeff => One_Q / LF.Coeff, Exp_X => Exp_Type (TX),
             Exp_Y => Exp_Type (TY));

      TX := Natural (LX) - Natural (LG.Exp_X);
      TY := Natural (LY) - Natural (LG.Exp_Y);
      TG := (Coeff => One_Q / LG.Coeff, Exp_X => Exp_Type (TX),
             Exp_Y => Exp_Type (TY));

      Left  := Mul_Term (TF, NF, Order);
      Right := Mul_Term (TG, NG, Order);
      return Sub (Left, Right, Order);
   end S_Polynomial;

   function LT_In_Ideal
     (F     : Polynomial;
      Basis : Poly_Array;
      N     : Poly_Count;
      Order : Monomial_Order) return Boolean
   is
      LF : constant Term := LT (F, Order);
      LG : Term;
   begin
      if Is_Zero (F) then
         return True;
      end if;
      for I in 1 .. N loop
         if not Is_Zero (Basis (I)) then
            LG := LT (Basis (I), Order);
            if Monomial_Divides
                 (LG.Exp_X, LG.Exp_Y, LF.Exp_X, LF.Exp_Y)
            then
               return True;
            end if;
         end if;
      end loop;
      return False;
   end LT_In_Ideal;

   ------------------------------------------------------------------
   -- Classic Buchberger loop
   ------------------------------------------------------------------

   type Pair_Rec is record
      I, J   : Poly_Index := 1;
      Active : Boolean := False;
   end record;

   type Pair_Array is array (1 .. Max_Pairs) of Pair_Rec;

   --  First Buchberger criterion: LTs share no variables ⇒ S reduces to 0.
   function Coprime_LTs
     (F, G  : Polynomial;
      Order : Monomial_Order) return Boolean
   is
      LF : constant Term := LT (F, Order);
      LG : constant Term := LT (G, Order);
   begin
      --  Share no variables: for each var, at least one exponent is 0.
      return (LF.Exp_X = 0 or else LG.Exp_X = 0)
        and then (LF.Exp_Y = 0 or else LG.Exp_Y = 0);
   end Coprime_LTs;

   procedure Enqueue_Pair
     (Pairs : in out Pair_Array;
      P_N   : in out Natural;
      I, J  :        Poly_Index;
      G     :        Poly_Array;
      Order :        Monomial_Order)
   is
      A, B : Poly_Index;
   begin
      if I = J then
         return;
      end if;
      if I < J then
         A := I;
         B := J;
      else
         A := J;
         B := I;
      end if;
      if Is_Zero (G (A)) or else Is_Zero (G (B)) then
         return;
      end if;
      if Coprime_LTs (G (A), G (B), Order) then
         return;
      end if;
      for K in 1 .. P_N loop
         if Pairs (K).Active
           and then Pairs (K).I = A
           and then Pairs (K).J = B
         then
            return;
         end if;
      end loop;
      if P_N >= Max_Pairs then
         raise Incomplete_Computation;
      end if;
      P_N := P_N + 1;
      Pairs (P_N) := (I => A, J => B, Active => True);
   end Enqueue_Pair;

   function Next_Active_Pair
     (Pairs : Pair_Array;
      P_N   : Natural) return Natural
   is
   begin
      for K in 1 .. P_N loop
         if Pairs (K).Active then
            return K;
         end if;
      end loop;
      return 0;
   end Next_Active_Pair;

   procedure Groebner_Basis
     (Generators :     Poly_Array;
      N          :     Poly_Count;
      Order      :     Monomial_Order;
      Basis      : out Poly_Array;
      Basis_N    : out Poly_Count;
      Complete   : out Boolean;
      Max_Steps  :     Natural := 256)
   is
      G      : Poly_Array := [others => Zero_Poly];
      G_N    : Poly_Count := 0;
      Pairs  : Pair_Array := [others => (I => 1, J => 1, Active => False)];
      P_N    : Natural := 0;
      Steps  : Natural := 0;
      Idx    : Natural;
      I, J   : Poly_Index;
      S_Poly : Polynomial;
      Rmd    : Polynomial;
      New_P  : Polynomial;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;

      for K in 1 .. N loop
         New_P := Normalize (Generators (K), Order);
         if Is_Zero (New_P) then
            raise Invalid_Argument;
         end if;
         if G_N = Max_Polys then
            raise Incomplete_Computation;
         end if;
         G_N := G_N + 1;
         G (G_N) := New_P;
      end loop;

      --  Initial critical pairs
      for A in 1 .. G_N loop
         for B in A + 1 .. G_N loop
            Enqueue_Pair (Pairs, P_N, A, B, G, Order);
         end loop;
      end loop;

      while Steps < Max_Steps loop
         Idx := Next_Active_Pair (Pairs, P_N);
         exit when Idx = 0;

         Pairs (Idx).Active := False;
         I := Pairs (Idx).I;
         J := Pairs (Idx).J;
         Steps := Steps + 1;

         if not Is_Zero (G (I)) and then not Is_Zero (G (J)) then
            S_Poly := S_Polynomial (G (I), G (J), Order);
            Rmd := Normal_Form (S_Poly, G, G_N, Order);

            if not Is_Zero (Rmd) then
               if G_N = Max_Polys then
                  raise Incomplete_Computation;
               end if;
               G_N := G_N + 1;
               G (G_N) := Normalize (Rmd, Order);
               for A in 1 .. G_N - 1 loop
                  Enqueue_Pair (Pairs, P_N, A, G_N, G, Order);
               end loop;
            end if;
         end if;
      end loop;

      Complete := Next_Active_Pair (Pairs, P_N) = 0;
      Basis := G;
      Basis_N := G_N;
   end Groebner_Basis;

   function Is_Groebner
     (Basis : Poly_Array;
      N     : Poly_Count;
      Order : Monomial_Order) return Boolean
   is
      S  : Polynomial;
      NF : Polynomial;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      for K in 1 .. N loop
         if Is_Zero (Basis (K)) then
            raise Invalid_Argument;
         end if;
      end loop;
      if N < 2 then
         return True;
      end if;
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            S := S_Polynomial (Basis (I), Basis (J), Order);
            NF := Normal_Form (S, Basis, N, Order);
            if not Is_Zero (NF) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Groebner;

end Buchbergers_Algorithm;
