--  Body for Faugere_F4 — educational bivariate F4 over Q.

pragma Ada_2022;

package body Faugere_F4
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
   -- F4 matrix machinery
   ------------------------------------------------------------------

   type Pair_Rec is record
      I, J   : Poly_Index := 1;
      LCM_X  : Exp_Type := 0;
      LCM_Y  : Exp_Type := 0;
      Deg    : Natural := 0;
      Active : Boolean := False;
   end record;

   type Pair_Array is array (1 .. Max_Pairs) of Pair_Rec;

   type Mono_Rec is record
      Exp_X : Exp_Type := 0;
      Exp_Y : Exp_Type := 0;
   end record;

   type Mono_Array is array (1 .. Max_Matrix) of Mono_Rec;
   type Mat_Row is array (1 .. Max_Matrix) of Rational;
   type Mat_Type is array (1 .. Max_Matrix) of Mat_Row;

   --  Larger row buffer for matrix construction (up to Max_Matrix).
   type Big_Poly_Array is array (1 .. Max_Matrix) of Polynomial;

   function Big_Row_Already
     (Rows  : Big_Poly_Array;
      R_N   : Natural;
      Cand  : Polynomial;
      Order : Monomial_Order) return Boolean
   is
   begin
      for K in 1 .. R_N loop
         if Equal (Rows (K), Cand, Order) then
            return True;
         end if;
      end loop;
      return False;
   end Big_Row_Already;

   procedure Big_Add_Row
     (Rows  : in out Big_Poly_Array;
      R_N   : in out Natural;
      Cand  :        Polynomial;
      Order :        Monomial_Order)
   is
      Nrm : constant Polynomial := Normalize (Cand, Order);
   begin
      if Is_Zero (Nrm) then
         return;
      end if;
      if Big_Row_Already (Rows, R_N, Nrm, Order) then
         return;
      end if;
      if R_N >= Max_Matrix then
         raise Incomplete_Computation;
      end if;
      R_N := R_N + 1;
      Rows (R_N) := Nrm;
   end Big_Add_Row;

   procedure Collect_Monomials
     (Rows  :     Big_Poly_Array;
      R_N   :     Natural;
      Order :     Monomial_Order;
      Mons  : out Mono_Array;
      M_N   : out Natural)
   is
      Found : Boolean;
   begin
      M_N := 0;
      Mons := [others => (Exp_X => 0, Exp_Y => 0)];
      for R in 1 .. R_N loop
         for T in 1 .. Rows (R).Count loop
            Found := False;
            for M in 1 .. M_N loop
               if Mons (M).Exp_X = Rows (R).Terms (T).Exp_X
                 and then Mons (M).Exp_Y = Rows (R).Terms (T).Exp_Y
               then
                  Found := True;
                  exit;
               end if;
            end loop;
            if not Found then
               if M_N >= Max_Matrix then
                  raise Incomplete_Computation;
               end if;
               M_N := M_N + 1;
               Mons (M_N) :=
                 (Exp_X => Rows (R).Terms (T).Exp_X,
                  Exp_Y => Rows (R).Terms (T).Exp_Y);
            end if;
         end loop;
      end loop;

      --  Sort monomials descending by Order (selection sort).
      for A in 1 .. M_N loop
         declare
            Best : Natural := A;
            Tmp  : Mono_Rec;
         begin
            for B in A + 1 .. M_N loop
               if Compare_Monomials
                    (Mons (B).Exp_X, Mons (B).Exp_Y,
                     Mons (Best).Exp_X, Mons (Best).Exp_Y,
                     Order) > 0
               then
                  Best := B;
               end if;
            end loop;
            if Best /= A then
               Tmp := Mons (A);
               Mons (A) := Mons (Best);
               Mons (Best) := Tmp;
            end if;
         end;
      end loop;
   end Collect_Monomials;

   procedure Symbolic_Preprocess
     (Rows   : in out Big_Poly_Array;
      R_N    : in out Natural;
      Basis  :        Poly_Array;
      B_N    :        Poly_Count;
      Order  :        Monomial_Order;
      Max_D  :        Natural)
   is
      Changed : Boolean;
      Mons    : Mono_Array;
      M_N     : Natural;
      LG      : Term;
      EX, EY  : Natural;
      Mult    : Term;
      Cand    : Polynomial;
   begin
      loop
         Changed := False;
         Collect_Monomials (Rows, R_N, Order, Mons, M_N);
         for M in 1 .. M_N loop
            for G in 1 .. B_N loop
               if not Is_Zero (Basis (G)) then
                  LG := LT (Basis (G), Order);
                  if Monomial_Divides
                       (LG.Exp_X, LG.Exp_Y, Mons (M).Exp_X, Mons (M).Exp_Y)
                  then
                     EX := Natural (Mons (M).Exp_X) - Natural (LG.Exp_X);
                     EY := Natural (Mons (M).Exp_Y) - Natural (LG.Exp_Y);
                     if EX + EY <= Max_D then
                        Mult :=
                          (Coeff => One_Q,
                           Exp_X => Exp_Type (EX),
                           Exp_Y => Exp_Type (EY));
                        begin
                           Cand := Mul_Term (Mult, Basis (G), Order);
                           if not Big_Row_Already (Rows, R_N, Cand, Order)
                           then
                              Big_Add_Row (Rows, R_N, Cand, Order);
                              Changed := True;
                           end if;
                        exception
                           when Invalid_Argument =>
                              null;  -- degree overflow on multiply: skip
                        end;
                     end if;
                  end if;
               end if;
            end loop;
         end loop;
         exit when not Changed;
      end loop;
   end Symbolic_Preprocess;

   procedure Build_And_Reduce_Matrix
     (Rows     :     Big_Poly_Array;
      R_N      :     Natural;
      Order    :     Monomial_Order;
      New_Polys : out Poly_Array;
      New_N    : out Poly_Count;
      Basis    :     Poly_Array;
      B_N      :     Poly_Count)
   is
      Mons : Mono_Array;
      M_N  : Natural := 0;
      Mat  : Mat_Type :=
        [others => [others => Zero_Q]];
   begin
      New_Polys := [others => Zero_Poly];
      New_N := 0;

      if R_N = 0 then
         return;
      end if;

      Collect_Monomials (Rows, R_N, Order, Mons, M_N);
      if M_N = 0 then
         return;
      end if;

      --  Fill matrix: row r, column c = coeff of Mons(c) in Rows(r).
      for R in 1 .. R_N loop
         for T in 1 .. Rows (R).Count loop
            for C in 1 .. M_N loop
               if Mons (C).Exp_X = Rows (R).Terms (T).Exp_X
                 and then Mons (C).Exp_Y = Rows (R).Terms (T).Exp_Y
               then
                  Mat (R)(C) := Mat (R)(C) + Rows (R).Terms (T).Coeff;
                  exit;
               end if;
            end loop;
         end loop;
      end loop;

      --  Gaussian elimination to row echelon form (partial pivoting over Q).
      declare
         Row : Natural := 1;
         Col : Natural := 1;
         Best : Natural;
         Tmp_Row : Mat_Row;
         Pivot : Rational;
         Factor : Rational;
      begin
         while Row <= R_N and then Col <= M_N loop
            Best := 0;
            for R in Row .. R_N loop
               if not Is_Zero (Mat (R)(Col)) then
                  Best := R;
                  exit;
               end if;
            end loop;

            if Best = 0 then
               Col := Col + 1;
            else
               if Best /= Row then
                  Tmp_Row := Mat (Row);
                  Mat (Row) := Mat (Best);
                  Mat (Best) := Tmp_Row;
               end if;

               Pivot := Mat (Row)(Col);
               --  Scale pivot row to 1.
               for C in Col .. M_N loop
                  Mat (Row)(C) := Mat (Row)(C) / Pivot;
               end loop;

               --  Eliminate other rows.
               for R in 1 .. R_N loop
                  if R /= Row and then not Is_Zero (Mat (R)(Col)) then
                     Factor := Mat (R)(Col);
                     for C in Col .. M_N loop
                        Mat (R)(C) := Mat (R)(C) - Factor * Mat (Row)(C);
                     end loop;
                  end if;
               end loop;

               Row := Row + 1;
               Col := Col + 1;
            end if;
         end loop;
      end;

      --  Extract nonzero rows whose leading monomial is not in <LT(Basis)>.
      for R in 1 .. R_N loop
         declare
            P     : Polynomial := Zero_Poly;
            Empty : Boolean := True;
         begin
            for C in 1 .. M_N loop
               if not Is_Zero (Mat (R)(C)) then
                  Empty := False;
                  Append_Raw
                    (P,
                     (Coeff => Reduce_Q (Mat (R)(C)),
                      Exp_X => Mons (C).Exp_X,
                      Exp_Y => Mons (C).Exp_Y));
               end if;
            end loop;

            if not Empty then
               P := Normalize (P, Order);
               if not Is_Zero (P)
                 and then not LT_In_Ideal (P, Basis, B_N, Order)
               then
                  if New_N = Max_Polys then
                     raise Incomplete_Computation;
                  end if;
                  New_N := New_N + 1;
                  New_Polys (New_N) := P;
               end if;
            end if;
         end;
      end loop;
   end Build_And_Reduce_Matrix;

   procedure Add_Critical_Pairs
     (Pairs  : in out Pair_Array;
      P_N    : in out Natural;
      Basis  :        Poly_Array;
      B_N    :        Poly_Count;
      New_Idx :       Poly_Index;
      Order  :        Monomial_Order;
      Max_D  :        Natural)
   is
      LI, LJ : Term;
      LX, LY : Exp_Type;
      D      : Natural;
   begin
      for I in 1 .. B_N loop
         if I /= New_Idx and then not Is_Zero (Basis (I))
           and then not Is_Zero (Basis (New_Idx))
         then
            LI := LT (Basis (I), Order);
            LJ := LT (Basis (New_Idx), Order);
            Monomial_LCM
              (LI.Exp_X, LI.Exp_Y, LJ.Exp_X, LJ.Exp_Y, LX, LY);
            D := Natural (LX) + Natural (LY);
            if D <= Max_D then
               if P_N >= Max_Pairs then
                  raise Incomplete_Computation;
               end if;
               P_N := P_N + 1;
               if I < New_Idx then
                  Pairs (P_N) :=
                    (I => I, J => New_Idx,
                     LCM_X => LX, LCM_Y => LY,
                     Deg => D, Active => True);
               else
                  Pairs (P_N) :=
                    (I => New_Idx, J => I,
                     LCM_X => LX, LCM_Y => LY,
                     Deg => D, Active => True);
               end if;
            end if;
         end if;
      end loop;
   end Add_Critical_Pairs;

   ------------------------------------------------------------------
   -- Main F4 driver
   ------------------------------------------------------------------

   procedure Groebner_Basis_F4
     (Generators :     Poly_Array;
      N          :     Poly_Count;
      Order      :     Monomial_Order;
      Basis      : out Poly_Array;
      Basis_N    : out Poly_Count;
      Complete   : out Boolean;
      Max_Deg    :     Natural := 6;
      Max_Steps  :     Natural := 32)
   is
      Cap_Deg : Natural;
      Pairs   : Pair_Array :=
        [others => (I => 1, J => 1, LCM_X => 0, LCM_Y => 0,
                    Deg => 0, Active => False)];
      P_N     : Natural := 0;
      Steps   : Natural := 0;
      Min_Deg : Natural;
      Have_Active : Boolean;
      Rows    : Big_Poly_Array := [others => Zero_Poly];
      R_N     : Natural;
      New_Ps  : Poly_Array;
      New_N   : Poly_Count;
      LI, LJ  : Term;
      LX, LY  : Exp_Type;
      TX, TY  : Natural;
      TF, TG  : Term;
      Left, Right : Polynomial;
   begin
      Basis := [others => Zero_Poly];
      Basis_N := 0;
      Complete := False;

      if N = 0 or else Max_Deg = 0 then
         raise Invalid_Argument;
      end if;

      Cap_Deg := Max_Deg;
      if Cap_Deg > Max_Degree then
         Cap_Deg := Max_Degree;
      end if;

      for I in 1 .. N loop
         declare
            G : constant Polynomial := Normalize (Generators (I), Order);
         begin
            if Is_Zero (G) then
               raise Invalid_Argument;
            end if;
            if Basis_N = Max_Polys then
               raise Incomplete_Computation;
            end if;
            Basis_N := Basis_N + 1;
            Basis (Basis_N) := G;
         end;
      end loop;

      --  Initial critical pairs among generators.
      for I in 1 .. Basis_N loop
         for J in I + 1 .. Basis_N loop
            LI := LT (Basis (I), Order);
            LJ := LT (Basis (J), Order);
            Monomial_LCM
              (LI.Exp_X, LI.Exp_Y, LJ.Exp_X, LJ.Exp_Y, LX, LY);
            declare
               D : constant Natural := Natural (LX) + Natural (LY);
            begin
               if D <= Cap_Deg then
                  if P_N >= Max_Pairs then
                     raise Incomplete_Computation;
                  end if;
                  P_N := P_N + 1;
                  Pairs (P_N) :=
                    (I => I, J => J,
                     LCM_X => LX, LCM_Y => LY,
                     Deg => D, Active => True);
               end if;
            end;
         end loop;
      end loop;

      loop
         Have_Active := False;
         Min_Deg := Natural'Last;
         for K in 1 .. P_N loop
            if Pairs (K).Active then
               Have_Active := True;
               if Pairs (K).Deg < Min_Deg then
                  Min_Deg := Pairs (K).Deg;
               end if;
            end if;
         end loop;

         exit when not Have_Active;

         if Steps >= Max_Steps then
            Complete := False;
            return;
         end if;
         Steps := Steps + 1;

         --  Select all active pairs of minimal LCM degree (F4 degree batch).
         Rows := [others => Zero_Poly];
         R_N := 0;

         for K in 1 .. P_N loop
            if Pairs (K).Active and then Pairs (K).Deg = Min_Deg then
               Pairs (K).Active := False;
               LI := LT (Basis (Pairs (K).I), Order);
               LJ := LT (Basis (Pairs (K).J), Order);
               LX := Pairs (K).LCM_X;
               LY := Pairs (K).LCM_Y;

               TX := Natural (LX) - Natural (LI.Exp_X);
               TY := Natural (LY) - Natural (LI.Exp_Y);
               TF :=
                 (Coeff => One_Q / LI.Coeff,
                  Exp_X => Exp_Type (TX),
                  Exp_Y => Exp_Type (TY));
               Left := Mul_Term (TF, Basis (Pairs (K).I), Order);

               TX := Natural (LX) - Natural (LJ.Exp_X);
               TY := Natural (LY) - Natural (LJ.Exp_Y);
               TG :=
                 (Coeff => One_Q / LJ.Coeff,
                  Exp_X => Exp_Type (TX),
                  Exp_Y => Exp_Type (TY));
               Right := Mul_Term (TG, Basis (Pairs (K).J), Order);

               Big_Add_Row (Rows, R_N, Left, Order);
               Big_Add_Row (Rows, R_N, Right, Order);
            end if;
         end loop;

         Symbolic_Preprocess
           (Rows, R_N, Basis, Basis_N, Order, Cap_Deg);

         Build_And_Reduce_Matrix
           (Rows, R_N, Order, New_Ps, New_N, Basis, Basis_N);

         for U in 1 .. New_N loop
            if Basis_N = Max_Polys then
               raise Incomplete_Computation;
            end if;
            Basis_N := Basis_N + 1;
            Basis (Basis_N) := New_Ps (U);
            Add_Critical_Pairs
              (Pairs, P_N, Basis, Basis_N, Basis_N, Order, Cap_Deg);
         end loop;
      end loop;

      --  Auto-reduce: replace each basis poly by its NF w.r.t. the others.
      declare
         Changed : Boolean := True;
         Passes  : Natural := 0;
         Rest   : Poly_Array;
         R_Cnt  : Poly_Count;
         NF      : Polynomial;
      begin
         while Changed and then Passes < Basis_N + 2 loop
            Changed := False;
            Passes := Passes + 1;
            for I in 1 .. Basis_N loop
               Rest := [others => Zero_Poly];
               R_Cnt := 0;
               for J in 1 .. Basis_N loop
                  if J /= I and then not Is_Zero (Basis (J)) then
                     R_Cnt := R_Cnt + 1;
                     Rest (R_Cnt) := Basis (J);
                  end if;
               end loop;
               if R_Cnt > 0 and then not Is_Zero (Basis (I)) then
                  NF := Normal_Form (Basis (I), Rest, R_Cnt, Order);
                  if not Equal (NF, Basis (I), Order) then
                     Basis (I) := NF;
                     Changed := True;
                  end if;
               end if;
            end loop;
         end loop;

         --  Compact out zeros.
         declare
            Compact : Poly_Array := [others => Zero_Poly];
            C_N     : Poly_Count := 0;
         begin
            for I in 1 .. Basis_N loop
               if not Is_Zero (Basis (I)) then
                  C_N := C_N + 1;
                  Compact (C_N) := Normalize (Basis (I), Order);
               end if;
            end loop;
            Basis := Compact;
            Basis_N := C_N;
         end;
      end;

      Complete := True;
   end Groebner_Basis_F4;

end Faugere_F4;
