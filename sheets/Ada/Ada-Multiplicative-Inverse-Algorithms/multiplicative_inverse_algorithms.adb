--  Multiplicative_Inverse_Algorithms body — EEA, Fermat, Newton sketches.

pragma Ada_2022;

package body Multiplicative_Inverse_Algorithms
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Integer helpers
   -------------------------------------------------------------------------

   function Abs_LI (N : Long_Integer) return Long_Integer is
   begin
      if N < 0 then
         return -N;
      else
         return N;
      end if;
   end Abs_LI;

   function Mod_Nonneg (A, M : Long_Integer) return Long_Integer is
      R : Long_Integer := A rem M;
   begin
      if R < 0 then
         R := R + M;
      end if;
      return R;
   end Mod_Nonneg;

   function Gcd (A, B : Long_Integer) return Long_Integer is
      U : Long_Integer := Abs_LI (A);
      V : Long_Integer := Abs_LI (B);
      T : Long_Integer;
   begin
      while V /= 0 loop
         T := U rem V;
         U := V;
         V := T;
      end loop;
      return U;
   end Gcd;

   function Extended_Gcd (A, B : Long_Integer) return Extended_Gcd_Result is
      --  Iterative extended Euclidean. Tracks Bézout coefficients so that
      --  at every step Old_R = A*Old_S + B*Old_T and R = A*S + B*T.
      R0 : Long_Integer := A;
      R1 : Long_Integer := B;
      S0 : Long_Integer := 1;
      S1 : Long_Integer := 0;
      T0 : Long_Integer := 0;
      T1 : Long_Integer := 1;
      Q  : Long_Integer;
      Tmp : Long_Integer;
      Res : Extended_Gcd_Result;
   begin
      while R1 /= 0 loop
         Q := R0 / R1;
         Tmp := R0 - Q * R1;
         R0 := R1;
         R1 := Tmp;
         Tmp := S0 - Q * S1;
         S0 := S1;
         S1 := Tmp;
         Tmp := T0 - Q * T1;
         T0 := T1;
         T1 := Tmp;
      end loop;
      --  Normalize so G ≥ 0 (flip signs if needed).
      if R0 < 0 then
         Res.G := -R0;
         Res.X := -S0;
         Res.Y := -T0;
      else
         Res.G := R0;
         Res.X := S0;
         Res.Y := T0;
      end if;
      return Res;
   end Extended_Gcd;

   function Is_Prime (N : Long_Integer) return Boolean is
      D : Long_Integer;
   begin
      if N <= 1 then
         return False;
      elsif N <= 3 then
         return True;
      elsif N rem 2 = 0 or else N rem 3 = 0 then
         return False;
      end if;
      D := 5;
      while D * D <= N loop
         if N rem D = 0 or else N rem (D + 2) = 0 then
            return False;
         end if;
         D := D + 6;
      end loop;
      return True;
   end Is_Prime;

   function Mod_Pow
     (Base, Exp, M : Long_Integer) return Long_Integer
   is
      Result : Long_Integer := 1;
      B      : Long_Integer := Mod_Nonneg (Base, M);
      E      : Long_Integer := Exp;
   begin
      while E > 0 loop
         if E rem 2 = 1 then
            Result := (Result * B) rem M;
         end if;
         B := (B * B) rem M;
         E := E / 2;
      end loop;
      return Result;
   end Mod_Pow;

   -------------------------------------------------------------------------
   -- Modular inverse — Extended Euclidean
   -------------------------------------------------------------------------

   function Inverse_Mod_EEA
     (A, M : Long_Integer) return Inverse_Result
   is
      Res : Inverse_Result;
      EG  : Extended_Gcd_Result;
      A_N : Long_Integer;
   begin
      if M <= 1 then
         Res.Status := Invalid_Input;
         Res.G := 0;
         Res.Value := 0;
         return Res;
      end if;
      A_N := Mod_Nonneg (A, M);
      EG := Extended_Gcd (A_N, M);
      Res.G := EG.G;
      if EG.G /= 1 then
         Res.Status := Not_Invertible;
         Res.Value := 0;
         return Res;
      end if;
      --  EG.X is a Bézout coefficient; normalize to [0, M-1].
      Res.Value := Mod_Nonneg (EG.X, M);
      Res.Status := Found;
      return Res;
   end Inverse_Mod_EEA;

   function Inverse_EEA (A, M : Long_Integer) return Long_Integer is
      R : constant Inverse_Result := Inverse_Mod_EEA (A, M);
   begin
      case R.Status is
         when Found =>
            return R.Value;
         when Not_Invertible =>
            raise No_Inverse;
         when others =>
            raise Invalid_Argument;
      end case;
   end Inverse_EEA;

   -------------------------------------------------------------------------
   -- Modular inverse — Fermat
   -------------------------------------------------------------------------

   function Inverse_Mod_Fermat
     (A, P : Long_Integer) return Inverse_Result
   is
      Res : Inverse_Result;
      A_N : Long_Integer;
   begin
      if P <= 1 then
         Res.Status := Invalid_Input;
         Res.G := 0;
         Res.Value := 0;
         return Res;
      end if;
      A_N := Mod_Nonneg (A, P);
      Res.G := Gcd (A_N, P);
      if A_N = 0 then
         Res.Status := Not_Invertible;
         Res.Value := 0;
         return Res;
      end if;
      --  Fermat: A^{P-2} mod P. When P is prime and A_N ≠ 0 this is the
      --  inverse. When P is composite the result may not be an inverse;
      --  callers should use Is_Prime / Inverse_Mod_EEA for general M.
      Res.Value := Mod_Pow (A_N, P - 2, P);
      if Is_Modular_Inverse (A_N, Res.Value, P) then
         Res.Status := Found;
      else
         --  Composite modulus or gcd ≠ 1: not a true inverse.
         Res.Status := Not_Invertible;
         Res.Value := 0;
      end if;
      return Res;
   end Inverse_Mod_Fermat;

   function Inverse_Fermat (A, P : Long_Integer) return Long_Integer is
      R : constant Inverse_Result := Inverse_Mod_Fermat (A, P);
   begin
      case R.Status is
         when Found =>
            return R.Value;
         when Not_Invertible =>
            raise No_Inverse;
         when others =>
            raise Invalid_Argument;
      end case;
   end Inverse_Fermat;

   -------------------------------------------------------------------------
   -- Real reciprocal — Newton sketch
   -------------------------------------------------------------------------

   function Exact_Reciprocal (A : Float) return Float is
   begin
      if A = 0.0 then
         raise Invalid_Argument;
      end if;
      return 1.0 / A;
   end Exact_Reciprocal;

   function Reciprocal_Newton
     (A        : Float;
      Tol      : Float := Default_Tol;
      Max_Iter : Positive := Default_Max_Iter) return Reciprocal_Result
   is
      Res  : Reciprocal_Result;
      X    : Float;
      Abs_A : Float;
      Scale : Float;
      M     : Float;
      Sign  : Float;
      Iter  : Natural := 0;
   begin
      if A = 0.0 then
         Res.Status := Bad_Domain;
         Res.Value := 0.0;
         Res.Iterations := 0;
         return Res;
      end if;

      --  Simple educational seed: scale |A| into roughly [0.5, 1) by
      --  dyadic factors, then start near 1 (or −1). Full NR-division
      --  seeds live in the sibling Ada-Newton-Multiplicative-Inverse.
      Abs_A := abs (A);
      if A > 0.0 then
         Sign := 1.0;
      else
         Sign := -1.0;
      end if;
      Scale := 1.0;
      M := Abs_A;
      while M >= 1.0 loop
         M := M * 0.5;
         Scale := Scale * 0.5;
      end loop;
      while M < 0.5 and then M > 0.0 loop
         M := M * 2.0;
         Scale := Scale * 2.0;
      end loop;
      --  Seed reciprocal of mantissa ≈ 1.5 − M (linear guess on [0.5,1)).
      X := Sign * Scale * (1.5 - M);

      for I in 1 .. Max_Iter loop
         Iter := I;
         X := X * (2.0 - A * X);
         exit when abs (A * X - 1.0) <= Tol;
      end loop;

      Res.Value := X;
      Res.Iterations := Iter;
      if abs (A * X - 1.0) <= Tol then
         Res.Status := Converged;
      else
         Res.Status := Max_Iterations_Reached;
      end if;
      return Res;
   end Reciprocal_Newton;

   function Reciprocal (A : Float) return Float is
      R : constant Reciprocal_Result := Reciprocal_Newton (A);
   begin
      if R.Status /= Converged then
         raise Invalid_Argument;
      end if;
      return R.Value;
   end Reciprocal;

   -------------------------------------------------------------------------
   -- Verification helpers
   -------------------------------------------------------------------------

   function Is_Modular_Inverse
     (A, Inv, M : Long_Integer) return Boolean
   is
      Prod : Long_Integer;
   begin
      Prod := Mod_Nonneg (A, M);
      Prod := (Prod * Mod_Nonneg (Inv, M)) rem M;
      return Prod = 1;
   end Is_Modular_Inverse;

   function Near
     (A, B : Float; Tol : Float := Default_Tol) return Boolean
   is
   begin
      return abs (A - B) <= Tol
        or else abs (A - B) <= Tol * (1.0 + abs (B));
   end Near;

end Multiplicative_Inverse_Algorithms;
