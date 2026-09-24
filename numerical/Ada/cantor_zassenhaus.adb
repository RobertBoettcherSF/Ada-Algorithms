--  Cantor–Zassenhaus — implementation (odd characteristic).

pragma Ada_2022;

package body Cantor_Zassenhaus
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Validate_Odd_Prime
   ------------------------------------------------------------------

   procedure Validate_Odd_Prime (P : Natural) is
   begin
      if P < 3 then
         raise Invalid_Argument;
      end if;
      if (P rem 2) = 0 then
         raise Invalid_Argument;
      end if;
      if P <= Max_Trial_Prime and then not Is_Prime_Trial (P) then
         raise Invalid_Argument;
      end if;
   end Validate_Odd_Prime;

   ------------------------------------------------------------------
   --  Is_Prime_Trial / Mul_Mod / Mod_Pow / Mod_Inv
   ------------------------------------------------------------------

   function Is_Prime_Trial (N : Natural) return Boolean is
   begin
      if N < 2 then
         return False;
      end if;
      if N = 2 or else N = 3 then
         return True;
      end if;
      if (N rem 2) = 0 then
         return False;
      end if;
      if (N rem 3) = 0 then
         return False;
      end if;
      declare
         D : Natural := 5;
      begin
         while D <= N / D loop
            if (N rem D) = 0 or else (N rem (D + 2)) = 0 then
               return False;
            end if;
            D := D + 6;
         end loop;
         return True;
      end;
   end Is_Prime_Trial;

   function Mul_Mod (A, B, M : Natural) return Natural is
      use Interfaces;
      AA, BB, MM, Prod : Unsigned_64;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return 0;
      end if;
      AA   := Unsigned_64 (A rem M);
      BB   := Unsigned_64 (B rem M);
      MM   := Unsigned_64 (M);
      Prod := AA * BB;
      return Natural (Prod rem MM);
   end Mul_Mod;

   function Mod_Pow (Base, Exp, Modulus : Natural) return Natural is
      Result : Natural := 1;
      B      : Natural;
      E      : Natural := Exp;
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      if Modulus = 1 then
         return 0;
      end if;
      B := Base rem Modulus;
      while E > 0 loop
         if (E rem 2) = 1 then
            Result := Mul_Mod (Result, B, Modulus);
         end if;
         B := Mul_Mod (B, B, Modulus);
         E := E / 2;
      end loop;
      return Result;
   end Mod_Pow;

   function Mod_Inv (A, P : Natural) return Natural is
      A_Mod : Natural;
   begin
      if P < 3 then
         raise Invalid_Argument;
      end if;
      A_Mod := A rem P;
      if A_Mod = 0 then
         raise Invalid_Argument;
      end if;
      return Mod_Pow (A_Mod, P - 2, P);
   end Mod_Inv;

   ------------------------------------------------------------------
   --  Degree / Is_Zero / Leading / Normalize / Make_Monic / Equal
   ------------------------------------------------------------------

   function Degree (P : Polynomial; Modulus : Natural) return Integer is
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      for I in reverse Degree_Index loop
         if (P.Coeffs (I) rem Modulus) /= 0 then
            return I;
         end if;
      end loop;
      return -1;
   end Degree;

   function Is_Zero (P : Polynomial; Modulus : Natural) return Boolean is
   begin
      return Degree (P, Modulus) < 0;
   end Is_Zero;

   function Leading_Coefficient
     (P : Polynomial; Modulus : Natural) return Natural
   is
      D : constant Integer := Degree (P, Modulus);
   begin
      if D < 0 then
         return 0;
      end if;
      return P.Coeffs (Degree_Index (D)) rem Modulus;
   end Leading_Coefficient;

   function Normalize
     (P : Polynomial; Modulus : Natural) return Polynomial
   is
      R : Polynomial := Zero_Poly;
      D : Integer;
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      for I in Degree_Index loop
         R.Coeffs (I) := P.Coeffs (I) rem Modulus;
      end loop;
      D := Degree (R, Modulus);
      if D < 0 then
         return Zero_Poly;
      end if;
      --  Clear above degree (already zero from rem, but keep tidy).
      for I in Degree_Index (D + 1) .. Max_Degree loop
         R.Coeffs (I) := 0;
      end loop;
      return R;
   end Normalize;

   function Make_Monic
     (P : Polynomial; Modulus : Natural) return Polynomial
   is
      N   : constant Polynomial := Normalize (P, Modulus);
      D   : constant Integer := Degree (N, Modulus);
      Inv : Natural;
      R   : Polynomial;
   begin
      if D < 0 then
         raise Invalid_Argument;
      end if;
      if N.Coeffs (Degree_Index (D)) = 1 then
         return N;
      end if;
      Inv := Mod_Inv (N.Coeffs (Degree_Index (D)), Modulus);
      R := Zero_Poly;
      for I in 0 .. Degree_Index (D) loop
         R.Coeffs (I) := Mul_Mod (N.Coeffs (I), Inv, Modulus);
      end loop;
      return R;
   end Make_Monic;

   function Equal
     (A, B : Polynomial; Modulus : Natural) return Boolean
   is
      NA : constant Polynomial := Normalize (A, Modulus);
      NB : constant Polynomial := Normalize (B, Modulus);
   begin
      for I in Degree_Index loop
         if NA.Coeffs (I) /= NB.Coeffs (I) then
            return False;
         end if;
      end loop;
      return True;
   end Equal;

   function From_Coeffs
     (C       : Coeff_Array;
      Last    : Degree_Index;
      Modulus : Natural) return Polynomial
   is
      R : Polynomial := Zero_Poly;
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      for I in 0 .. Last loop
         R.Coeffs (I) := C (I) rem Modulus;
      end loop;
      return Normalize (R, Modulus);
   end From_Coeffs;

   function Constant_Poly
     (Coeff : Natural; Modulus : Natural) return Polynomial
   is
      R : Polynomial := Zero_Poly;
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      R.Coeffs (0) := Coeff rem Modulus;
      return Normalize (R, Modulus);
   end Constant_Poly;

   function Monomial
     (Coeff : Natural; Power : Natural; Modulus : Natural)
      return Polynomial
   is
      R : Polynomial := Zero_Poly;
   begin
      if Modulus = 0 or else Power > Max_Degree then
         raise Invalid_Argument;
      end if;
      R.Coeffs (Degree_Index (Power)) := Coeff rem Modulus;
      return Normalize (R, Modulus);
   end Monomial;

   ------------------------------------------------------------------
   --  Add / Sub / Mul
   ------------------------------------------------------------------

   function Add
     (A, B : Polynomial; Modulus : Natural) return Polynomial
   is
      R : Polynomial := Zero_Poly;
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      for I in Degree_Index loop
         R.Coeffs (I) :=
           (A.Coeffs (I) rem Modulus + B.Coeffs (I) rem Modulus) rem Modulus;
      end loop;
      return Normalize (R, Modulus);
   end Add;

   function Sub
     (A, B : Polynomial; Modulus : Natural) return Polynomial
   is
      R : Polynomial := Zero_Poly;
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      for I in Degree_Index loop
         R.Coeffs (I) :=
           (A.Coeffs (I) rem Modulus
            + Modulus
            - (B.Coeffs (I) rem Modulus))
           rem Modulus;
      end loop;
      return Normalize (R, Modulus);
   end Sub;

   function Mul
     (A, B : Polynomial; Modulus : Natural) return Polynomial
   is
      DA : constant Integer := Degree (A, Modulus);
      DB : constant Integer := Degree (B, Modulus);
      R  : Polynomial := Zero_Poly;
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      if DA < 0 or else DB < 0 then
         return Zero_Poly;
      end if;
      if DA + DB > Integer (Max_Degree) then
         raise Invalid_Argument;
      end if;
      for I in 0 .. Degree_Index (DA) loop
         for J in 0 .. Degree_Index (DB) loop
            declare
               Idx : constant Degree_Index := I + J;
               Term : constant Natural :=
                 Mul_Mod
                   (A.Coeffs (I) rem Modulus,
                    B.Coeffs (J) rem Modulus,
                    Modulus);
            begin
               R.Coeffs (Idx) := (R.Coeffs (Idx) + Term) rem Modulus;
            end;
         end loop;
      end loop;
      return Normalize (R, Modulus);
   end Mul;

   ------------------------------------------------------------------
   --  Div_Mod / GCD / Mod_Exp / Derivative / Square_Free
   ------------------------------------------------------------------

   procedure Div_Mod
     (Dividend  :     Polynomial;
      Divisor   :     Polynomial;
      Modulus   :     Natural;
      Quotient  : out Polynomial;
      Remainder : out Polynomial)
   is
      DM : constant Integer := Degree (Divisor, Modulus);
      DA : constant Integer := Degree (Dividend, Modulus);
      Buf : Polynomial;
      Q   : Polynomial := Zero_Poly;
      Lead_Inv : Natural;
      Cur_Deg  : Integer;
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      if DM < 0 then
         raise Invalid_Argument;
      end if;
      if DA < 0 then
         Quotient  := Zero_Poly;
         Remainder := Zero_Poly;
         return;
      end if;
      if DA < DM then
         Quotient  := Zero_Poly;
         Remainder := Normalize (Dividend, Modulus);
         return;
      end if;

      Buf := Normalize (Dividend, Modulus);
      Lead_Inv := Mod_Inv (Divisor.Coeffs (Degree_Index (DM)) rem Modulus,
                           Modulus);
      Cur_Deg := DA;

      while Cur_Deg >= DM loop
         declare
            Diff  : constant Natural := Natural (Cur_Deg - DM);
            Scale : constant Natural :=
              Mul_Mod
                (Buf.Coeffs (Degree_Index (Cur_Deg)), Lead_Inv, Modulus);
            MM    : constant Polynomial := Normalize (Divisor, Modulus);
         begin
            Q.Coeffs (Degree_Index (Diff)) :=
              (Q.Coeffs (Degree_Index (Diff)) + Scale) rem Modulus;
            for K in 0 .. Degree_Index (DM) loop
               declare
                  Idx  : constant Degree_Index := K + Degree_Index (Diff);
                  Term : constant Natural :=
                    Mul_Mod (MM.Coeffs (K), Scale, Modulus);
               begin
                  Buf.Coeffs (Idx) :=
                    (Buf.Coeffs (Idx) + Modulus - Term) rem Modulus;
               end;
            end loop;
            Cur_Deg := Degree (Buf, Modulus);
         end;
      end loop;

      Quotient  := Normalize (Q, Modulus);
      Remainder := Normalize (Buf, Modulus);
   end Div_Mod;

   function GCD
     (A, B : Polynomial; Modulus : Natural) return Polynomial
   is
      F : Polynomial := Normalize (A, Modulus);
      G : Polynomial := Normalize (B, Modulus);
      Q, R : Polynomial;
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      while not Is_Zero (G, Modulus) loop
         Div_Mod (F, G, Modulus, Q, R);
         F := G;
         G := R;
      end loop;
      if Is_Zero (F, Modulus) then
         return Zero_Poly;
      end if;
      return Make_Monic (F, Modulus);
   end GCD;

   --  (A * B) mod Modulus_Poly without requiring deg(A)+deg(B) ≤ Max_Degree.
   --  Uses Horner: accumulate B's coefficients with x-shift reductions.
   function Mul_Mod_Poly
     (A, B, Modulus_Poly : Polynomial;
      Modulus            : Natural) return Polynomial
   is
      DB : constant Integer := Degree (B, Modulus);
      Acc : Polynomial := Zero_Poly;
      Q, R : Polynomial;
      X_Mon : constant Polynomial := Monomial (1, 1, Modulus);
      Scaled, Tmp : Polynomial;
   begin
      if DB < 0 then
         return Zero_Poly;
      end if;
      for I in reverse 0 .. Degree_Index (DB) loop
         --  Acc := (Acc * x) mod M
         if not Is_Zero (Acc, Modulus) then
            Tmp := Mul (Acc, X_Mon, Modulus);
            --  deg(Acc) < deg(M) so deg(Acc*x) ≤ deg(M); fits Max_Degree
            --  when deg(M) ≤ Max_Degree (always).
            Div_Mod (Tmp, Modulus_Poly, Modulus, Q, R);
            Acc := R;
         end if;
         if (B.Coeffs (I) rem Modulus) /= 0 then
            Scaled := Zero_Poly;
            declare
               DA : constant Integer := Degree (A, Modulus);
            begin
               if DA >= 0 then
                  for J in 0 .. Degree_Index (DA) loop
                     Scaled.Coeffs (J) :=
                       Mul_Mod
                         (A.Coeffs (J) rem Modulus,
                          B.Coeffs (I) rem Modulus,
                          Modulus);
                  end loop;
               end if;
            end;
            Acc := Add (Acc, Normalize (Scaled, Modulus), Modulus);
            Div_Mod (Acc, Modulus_Poly, Modulus, Q, R);
            Acc := R;
         end if;
      end loop;
      return Normalize (Acc, Modulus);
   end Mul_Mod_Poly;

   function Mod_Exp
     (Base         : Polynomial;
      Exp          : U64;
      Modulus_Poly : Polynomial;
      Modulus      : Natural) return Polynomial
   is
      use type U64;
      E      : U64 := Exp;
      Result : Polynomial;
      B      : Polynomial;
      Q, R   : Polynomial;
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      if Is_Zero (Modulus_Poly, Modulus) then
         raise Invalid_Argument;
      end if;
      Result := Constant_Poly (1, Modulus);
      Div_Mod (Base, Modulus_Poly, Modulus, Q, R);
      B := R;
      while E > 0 loop
         if (E and 1) = 1 then
            Result := Mul_Mod_Poly (Result, B, Modulus_Poly, Modulus);
         end if;
         B := Mul_Mod_Poly (B, B, Modulus_Poly, Modulus);
         E := E / 2;
      end loop;
      return Normalize (Result, Modulus);
   end Mod_Exp;

   function Derivative
     (P : Polynomial; Modulus : Natural) return Polynomial
   is
      D : constant Integer := Degree (P, Modulus);
      R : Polynomial := Zero_Poly;
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      if D < 1 then
         return Zero_Poly;
      end if;
      for I in 1 .. Degree_Index (D) loop
         R.Coeffs (I - 1) := Mul_Mod (P.Coeffs (I) rem Modulus, I, Modulus);
      end loop;
      return Normalize (R, Modulus);
   end Derivative;

   function Square_Free
     (P : Polynomial; Modulus : Natural) return Polynomial
   is
      N   : constant Polynomial := Normalize (P, Modulus);
      Dp  : constant Polynomial := Derivative (N, Modulus);
      G   : constant Polynomial := GCD (N, Dp, Modulus);
      Q, R : Polynomial;
   begin
      if Is_Zero (N, Modulus) then
         raise Invalid_Argument;
      end if;
      if Degree (G, Modulus) = 0 then
         return Make_Monic (N, Modulus);
      end if;
      Div_Mod (N, G, Modulus, Q, R);
      if not Is_Zero (R, Modulus) then
         --  Should divide exactly for characteristic not dividing
         --  multiplicities awkwardly; fall back to monic N.
         return Make_Monic (N, Modulus);
      end if;
      return Make_Monic (Q, Modulus);
   end Square_Free;

   ------------------------------------------------------------------
   --  RNG (LCG) and random polynomial of degree < N
   ------------------------------------------------------------------

   procedure Next_Random (State : in out U64) is
      use type U64;
   begin
      State := State * 6364136223846793005 + 1;
   end Next_Random;

   function Random_Poly
     (Deg_Bound : Natural;
      Modulus  : Natural;
      State    : in out U64) return Polynomial
   is
      use type U64;
      R : Polynomial := Zero_Poly;
      Last : Natural;
   begin
      if Deg_Bound = 0 then
         return Constant_Poly (1, Modulus);
      end if;
      Last := Deg_Bound - 1;
      if Last > Max_Degree then
         Last := Max_Degree;
      end if;
      for I in 0 .. Degree_Index (Last) loop
         Next_Random (State);
         R.Coeffs (I) := Natural (State rem U64 (Modulus));
      end loop;
      --  Ensure not constant 0, ±1 by bumping leading if needed.
      if Is_Zero (R, Modulus) then
         R.Coeffs (0) := 1;
      end if;
      return Normalize (R, Modulus);
   end Random_Poly;

   ------------------------------------------------------------------
   --  Pow_U64: Modulus^D as U64 (educational sizes)
   ------------------------------------------------------------------

   function Pow_Nat_U64 (Base : Natural; Exp : Natural) return U64 is
      use type U64;
      Result : U64 := 1;
      B      : U64 := U64 (Base);
      E      : Natural := Exp;
   begin
      while E > 0 loop
         if (E rem 2) = 1 then
            Result := Result * B;
         end if;
         B := B * B;
         E := E / 2;
      end loop;
      return Result;
   end Pow_Nat_U64;

   ------------------------------------------------------------------
   --  Emit factor helper
   ------------------------------------------------------------------

   procedure Emit
     (F       :        Polynomial;
      Factors : in out Factor_Array;
      Count   : in out Natural)
   is
   begin
      if Count >= Max_Factors then
         raise Invalid_Argument;
      end if;
      Count := Count + 1;
      Factors (Count) := F;
   end Emit;

   ------------------------------------------------------------------
   --  Equal-degree factorization (Cantor–Zassenhaus, odd p)
   --  F is square-free product of r ≥ 1 irreducibles each of degree D.
   ------------------------------------------------------------------

   procedure Equal_Degree_Factor
     (F            :        Polynomial;
      D            :        Natural;
      Modulus      :        Natural;
      Factors      : in out Factor_Array;
      Count        : in out Natural;
      Seed         : in out U64;
      Max_Attempts :        Positive)
   is
      use type U64;
      Deg_F : constant Integer := Degree (F, Modulus);
   begin
      if Deg_F < 0 then
         return;
      end if;
      if Deg_F = Integer (D) then
         Emit (Make_Monic (F, Modulus), Factors, Count);
         return;
      end if;
      if D = 0 or else (Deg_F rem Integer (D)) /= 0 then
         raise Invalid_Argument;
      end if;

      --  Single irreducible already handled; try random splits.
      declare
         Attempts : Natural := 0;
         Split_Ok : Boolean := False;
         Work     : constant Polynomial := Make_Monic (F, Modulus);
         M_Exp    : U64;
         V, W, G1, G2 : Polynomial;
         Q, Remn  : Polynomial;
         One      : constant Polynomial := Constant_Poly (1, Modulus);
      begin
         --  m = (q^d - 1) / 2
         M_Exp := (Pow_Nat_U64 (Modulus, D) - 1) / 2;

         while Attempts < Max_Attempts and then not Split_Ok loop
            Attempts := Attempts + 1;
            V := Random_Poly (Natural (Deg_F), Modulus, Seed);
            --  Skip trivial constants 0, ±1 after reduction mod Work.
            Div_Mod (V, Work, Modulus, Q, Remn);
            V := Remn;
            if Is_Zero (V, Modulus)
              or else Equal (V, One, Modulus)
              or else Equal (V, Constant_Poly (Modulus - 1, Modulus), Modulus)
            then
               goto Continue_Attempt;
            end if;

            W := Mod_Exp (V, M_Exp, Work, Modulus);
            --  gcd(f, w - 1)
            G1 := GCD (Work, Sub (W, One, Modulus), Modulus);
            if Degree (G1, Modulus) > 0
              and then Degree (G1, Modulus) < Deg_F
            then
               Split_Ok := True;
               Equal_Degree_Factor
                 (G1, D, Modulus, Factors, Count, Seed, Max_Attempts);
               Div_Mod (Work, G1, Modulus, Q, Remn);
               Equal_Degree_Factor
                 (Make_Monic (Q, Modulus), D, Modulus,
                  Factors, Count, Seed, Max_Attempts);
            else
               --  Try gcd(f, w + 1)
               G2 := GCD (Work, Add (W, One, Modulus), Modulus);
               if Degree (G2, Modulus) > 0
                 and then Degree (G2, Modulus) < Deg_F
               then
                  Split_Ok := True;
                  Equal_Degree_Factor
                    (G2, D, Modulus, Factors, Count, Seed, Max_Attempts);
                  Div_Mod (Work, G2, Modulus, Q, Remn);
                  Equal_Degree_Factor
                    (Make_Monic (Q, Modulus), D, Modulus,
                     Factors, Count, Seed, Max_Attempts);
               end if;
            end if;
            <<Continue_Attempt>>
         end loop;

         if not Split_Ok then
            raise Invalid_Argument;
         end if;
      end;
   end Equal_Degree_Factor;

   ------------------------------------------------------------------
   --  Distinct-degree factorization then EDF
   ------------------------------------------------------------------

   procedure Distinct_Degree_Then_EDF
     (F            :        Polynomial;
      Modulus      :        Natural;
      Factors      : in out Factor_Array;
      Count        : in out Natural;
      Seed         : in out U64;
      Max_Attempts :        Positive)
   is
      Work : Polynomial := Make_Monic (F, Modulus);
      H    : Polynomial;  -- tracks x^{p^i} mod Work iteratively on shrinking f
      X_Poly : constant Polynomial := Monomial (1, 1, Modulus);
      I    : Natural := 0;
      G_I  : Polynomial;
      Q, R : Polynomial;
      Deg_W : Integer;
   begin
      Deg_W := Degree (Work, Modulus);
      if Deg_W = 0 then
         return;  --  constant unit
      end if;
      if Deg_W = 1 then
         Emit (Work, Factors, Count);
         return;
      end if;

      --  Classic DDF on a shrinking square-free monic Work:
      --  H starts as x; for i = 1,2,... : H := H^p mod Work;
      --  G_i := gcd(H - x, Work); emit/split G_i; Work := Work / G_i.
      H := X_Poly;

      while Degree (Work, Modulus) > 0 loop
         I := I + 1;
         --  H := H^P mod Work
         H := Mod_Exp (H, U64 (Modulus), Work, Modulus);
         G_I := GCD (Sub (H, X_Poly, Modulus), Work, Modulus);

         if Degree (G_I, Modulus) > 0 then
            G_I := Make_Monic (G_I, Modulus);
            --  G_I = product of irreducibles of degree I
            Equal_Degree_Factor
              (G_I, I, Modulus, Factors, Count, Seed, Max_Attempts);
            Div_Mod (Work, G_I, Modulus, Q, R);
            Work := Make_Monic (Q, Modulus);
            --  Reduce H modulo new Work
            if Degree (Work, Modulus) > 0 then
               Div_Mod (H, Work, Modulus, Q, R);
               H := R;
            end if;
         end if;

         --  Remaining irreducible of degree = deg(Work)
         Deg_W := Degree (Work, Modulus);
         if Deg_W > 0 and then Deg_W = Integer (I) then
            --  Should not normally hit before G_I takes it; safety.
            null;
         end if;

         --  Safety: if i exceeds deg, remaining poly is irreducible.
         if I > Natural (Degree (Work, Modulus))
           and then Degree (Work, Modulus) > 0
         then
            Emit (Make_Monic (Work, Modulus), Factors, Count);
            return;
         end if;

         --  Bound iterations
         if I > Max_Degree then
            if Degree (Work, Modulus) > 0 then
               Emit (Make_Monic (Work, Modulus), Factors, Count);
            end if;
            return;
         end if;
      end loop;
   end Distinct_Degree_Then_EDF;

   ------------------------------------------------------------------
   --  Factor (public)
   ------------------------------------------------------------------

   procedure Factor
     (P            :        Natural;
      Poly         :        Polynomial;
      Factors      :    out Factor_Array;
      Count        :    out Natural;
      Seed         : in out U64;
      Max_Attempts :        Positive := Default_Max_Attempts)
   is
      N   : Polynomial;
      SF  : Polynomial;
      Deg : Integer;
   begin
      Validate_Odd_Prime (P);
      N := Normalize (Poly, P);
      Deg := Degree (N, P);
      if Deg < 0 then
         raise Invalid_Argument;
      end if;
      if Deg = 0 then
         --  Nonzero constant: no non-unit irreducible factors.
         Count := 0;
         Factors := [others => Zero_Poly];
         return;
      end if;

      N := Make_Monic (N, P);
      SF := Square_Free (N, P);
      Count := 0;
      Factors := [others => Zero_Poly];

      if Degree (SF, P) = 0 then
         return;
      end if;

      Distinct_Degree_Then_EDF
        (SF, P, Factors, Count, Seed, Max_Attempts);
   end Factor;

end Cantor_Zassenhaus;
