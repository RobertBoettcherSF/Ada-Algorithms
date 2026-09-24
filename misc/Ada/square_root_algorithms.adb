--  Square_Root_Algorithms body — Heron, bisection, digit-by-digit,
--  inverse-sqrt Newton sketches.

pragma Ada_2022;

package body Square_Root_Algorithms
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near
     (A, B : Long_Float; Tol : Long_Float := Near_Tol) return Boolean
   is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Abs_Error (A, B : Long_Float) return Long_Float is
   begin
      return abs (A - B);
   end Abs_Error;

   function Fail_Domain return Sqrt_Result is
   begin
      return (Value => 0.0, Iterations => 0, Status => Bad_Domain);
   end Fail_Domain;

   --  Crude positive initial guess for √S (S > 0).
   function Initial_Guess (S : Long_Float) return Long_Float is
      G     : Long_Float := 1.0;
      Guard : Natural := 0;
   begin
      if S = 1.0 then
         return 1.0;
      elsif S > 1.0 then
         loop
            exit when G * G >= S or else G >= S;
            G := G * 2.0;
            Guard := Guard + 1;
            exit when Guard > 64;
         end loop;
         if G > 1.0 and then G * G > S then
            G := G / 2.0;
         end if;
         if G < 1.0 then
            G := 1.0;
         end if;
      else
         --  0 < S < 1: shrink from 1.
         loop
            exit when G * G <= S or else G <= S;
            G := G * 0.5;
            Guard := Guard + 1;
            exit when Guard > 64;
         end loop;
         if G <= 0.0 then
            G := S;
         end if;
      end if;
      return G;
   end Initial_Guess;

   function Is_Perfect_Square (N : Natural) return Boolean is
      R : constant Natural := Sqrt_Digit_By_Digit (N);
   begin
      return R * R = N;
   end Is_Perfect_Square;

   ---------------------------------------------------------------------------
   -- Heron
   ---------------------------------------------------------------------------

   function Sqrt_Heron
     (S        : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Sqrt_Result
   is
      X      : Long_Float;
      X_Next : Long_Float;
      Rel    : Long_Float;
   begin
      if S < 0.0 then
         return Fail_Domain;
      end if;

      if S = 0.0 then
         return (Value => 0.0, Iterations => 0, Status => Converged);
      end if;

      X := Initial_Guess (S);
      if X = 0.0 then
         X := 1.0;
      end if;

      for Iter in 1 .. Max_Iter loop
         X_Next := 0.5 * (X + S / X);
         Rel := abs (X_Next - X);
         X := X_Next;

         if Rel <= Tol or else Rel <= Tol * abs (X) then
            return
              (Value      => X,
               Iterations => Iter,
               Status     => Converged);
         end if;
      end loop;

      return
        (Value      => X,
         Iterations => Max_Iter,
         Status     => Max_Iterations_Reached);
   end Sqrt_Heron;

   ---------------------------------------------------------------------------
   -- Bisection
   ---------------------------------------------------------------------------

   function Sqrt_Bisection
     (S        : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Sqrt_Result
   is
      Lo  : Long_Float;
      Hi  : Long_Float;
      Mid : Long_Float;
   begin
      if S < 0.0 then
         return Fail_Domain;
      end if;

      if S = 0.0 then
         return (Value => 0.0, Iterations => 0, Status => Converged);
      end if;

      Lo := 0.0;
      if S >= 1.0 then
         Hi := S;
      else
         Hi := 1.0;
      end if;

      for Iter in 1 .. Max_Iter loop
         Mid := 0.5 * (Lo + Hi);
         if Mid * Mid > S then
            Hi := Mid;
         else
            Lo := Mid;
         end if;

         if Hi - Lo <= Tol then
            Mid := 0.5 * (Lo + Hi);
            return
              (Value      => Mid,
               Iterations => Iter,
               Status     => Converged);
         end if;
      end loop;

      Mid := 0.5 * (Lo + Hi);
      return
        (Value      => Mid,
         Iterations => Max_Iter,
         Status     => Max_Iterations_Reached);
   end Sqrt_Bisection;

   ---------------------------------------------------------------------------
   -- Digit-by-digit integer floor (binary)
   ---------------------------------------------------------------------------

   --  Classic bit-by-bit / restoring algorithm (Wikipedia isqrt sketch):
   --  walk powers of 4 from the highest fitting bit pair down to 1.
   function Sqrt_Digit_By_Digit (N : Natural) return Natural is
      Op   : Natural := N;
      Res  : Natural := 0;
      One  : Natural := 1;
      Sum  : Natural;
   begin
      if N < 2 then
         return N;
      end if;

      --  Largest power of 4 ≤ N: shift One left by 2 until overflow risk.
      while One <= N / 4 loop
         One := One * 4;
      end loop;

      while One /= 0 loop
         Sum := Res + One;
         if Op >= Sum then
            Op  := Op - Sum;
            Res := Res / 2 + One;
         else
            Res := Res / 2;
         end if;
         One := One / 4;
      end loop;

      return Res;
   end Sqrt_Digit_By_Digit;

   ---------------------------------------------------------------------------
   -- Digit Float (scaled integer floor)
   ---------------------------------------------------------------------------

   function Sqrt_Digit_Float
     (S         : Long_Float;
      Num_Digits : Positive := 6) return Sqrt_Result
   is
      Cap       : constant Positive := 9;
      Places    : Positive;
      Scale     : Long_Float;
      Scaled_S  : Long_Float;
      Int_Part  : Natural;
      Root_Int  : Natural;
      Value     : Long_Float;
   begin
      if S < 0.0 then
         return Fail_Domain;
      end if;

      if S = 0.0 then
         return (Value => 0.0, Iterations => 0, Status => Converged);
      end if;

      if Num_Digits > Cap then
         Places := Cap;
      else
         Places := Num_Digits;
      end if;

      --  Scale so √(S · 10^{2p}) / 10^p ≈ √S with p decimal places.
      Scale := 1.0;
      for I in 1 .. Places loop
         Scale := Scale * 10.0;
      end loop;

      Scaled_S := S * Scale * Scale;
      if Scaled_S > Long_Float (Natural'Last) then
         --  Fall back to Heron when scaled integer would overflow.
         declare
            H : constant Sqrt_Result := Sqrt_Heron (S);
         begin
            return H;
         end;
      end if;

      Int_Part := Natural (Long_Float'Truncation (Scaled_S));
      --  Guard truncation of values extremely close to an integer from below.
      if Long_Float (Int_Part) + 1.0 <= Scaled_S then
         Int_Part := Int_Part + 1;
      end if;

      Root_Int := Sqrt_Digit_By_Digit (Int_Part);
      Value := Long_Float (Root_Int) / Scale;

      return
        (Value      => Value,
         Iterations => Places,
         Status     => Converged);
   end Sqrt_Digit_Float;

   ---------------------------------------------------------------------------
   -- Inverse-sqrt Newton
   ---------------------------------------------------------------------------

   function Sqrt_Inv_Newton
     (S        : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Sqrt_Result
   is
      X      : Long_Float;
      X_Next : Long_Float;
      Sqrt_S : Long_Float;
      Rel    : Long_Float;
   begin
      if S < 0.0 then
         return Fail_Domain;
      end if;

      if S = 0.0 then
         return (Value => 0.0, Iterations => 0, Status => Converged);
      end if;

      --  Seed inv-sqrt ≈ 1 / Initial_Guess(S); stabilize with one Heron-like
      --  step on the reciprocal when the guess is crude.
      declare
         G : constant Long_Float := Initial_Guess (S);
      begin
         if G = 0.0 then
            X := 1.0;
         else
            X := 1.0 / G;
         end if;
      end;

      for Iter in 1 .. Max_Iter loop
         --  x ← x * (3/2 − (S/2) * x^2); keep positive (principal branch).
         X_Next := X * (1.5 - 0.5 * S * X * X);
         if X_Next <= 0.0 then
            --  Overshoot: pull back toward 1/Initial_Guess.
            X_Next := 0.5 * abs (X);
            if X_Next = 0.0 then
               X_Next := 1.0 / Initial_Guess (S);
            end if;
         end if;
         Rel := abs (X_Next - X);
         X := X_Next;

         Sqrt_S := abs (S * X);
         if Rel <= Tol or else Rel <= Tol * abs (X)
           or else abs (Sqrt_S * Sqrt_S - S) <= Tol * (1.0 + S)
         then
            return
              (Value      => Sqrt_S,
               Iterations => Iter,
               Status     => Converged);
         end if;
      end loop;

      return
        (Value      => abs (S * X),
         Iterations => Max_Iter,
         Status     => Max_Iterations_Reached);
   end Sqrt_Inv_Newton;

   ---------------------------------------------------------------------------
   -- Convenience
   ---------------------------------------------------------------------------

   function Sqrt (S : Long_Float) return Long_Float is
      R : constant Sqrt_Result := Sqrt_Heron (S);
   begin
      if R.Status /= Converged then
         raise Invalid_Argument
           with "square root: invalid argument or no converge";
      end if;
      return R.Value;
   end Sqrt;

end Square_Root_Algorithms;
