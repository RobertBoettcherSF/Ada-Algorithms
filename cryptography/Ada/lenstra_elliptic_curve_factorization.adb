--  Lenstra elliptic-curve factorization (ECM) — Ada 2023 Stage-1 body.

pragma Ada_2022;

with Interfaces;

package body Lenstra_Elliptic_Curve_Factorization
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Helpers
   ------------------------------------------------------------------

   function Gcd (A, B : U64) return U64 is
      X : U64 := A;
      Y : U64 := B;
      T : U64;
   begin
      while Y /= 0 loop
         T := X rem Y;
         X := Y;
         Y := T;
      end loop;
      return X;
   end Gcd;

   function Mul_Mod (A, B, M : U64) return U64 is
      use Interfaces;
      AA, BB, MM, Prod : Unsigned_128;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return 0;
      end if;
      AA   := Unsigned_128 (A rem M);
      BB   := Unsigned_128 (B rem M);
      MM   := Unsigned_128 (M);
      Prod := AA * BB;
      return U64 (Unsigned_64 (Prod rem MM));
   end Mul_Mod;

   function Add_Mod (A, B, M : U64) return U64 is
      AA, BB : U64;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return 0;
      end if;
      AA := A rem M;
      BB := B rem M;
      --  Avoid overflow: AA + BB may wrap in U64 when M is large,
      --  but AA, BB < M ≤ 2^64−1 and AA+BB < 2M, so use rem carefully.
      if AA >= M - BB then
         return AA - (M - BB);
      else
         return AA + BB;
      end if;
   end Add_Mod;

   function Sub_Mod (A, B, M : U64) return U64 is
      AA, BB : U64;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return 0;
      end if;
      AA := A rem M;
      BB := B rem M;
      if AA >= BB then
         return AA - BB;
      else
         return M - (BB - AA);
      end if;
   end Sub_Mod;

   function Floor_Sqrt (N : U64) return U64 is
      Lo, Hi, Mid : U64;
   begin
      if N < 2 then
         return N;
      end if;
      Lo := 1;
      Hi := N / 2 + 1;
      while Lo < Hi loop
         Mid := Lo + (Hi - Lo + 1) / 2;
         if Mid > N / Mid then
            Hi := Mid - 1;
         else
            Lo := Mid;
         end if;
      end loop;
      return Lo;
   end Floor_Sqrt;

   function Is_Prime_Trial (N : U64) return Boolean is
      D : U64;
   begin
      if N < 2 then
         return False;
      end if;
      if N = 2 or else N = 3 then
         return True;
      end if;
      if N rem 2 = 0 or else N rem 3 = 0 then
         return False;
      end if;
      D := 5;
      while D <= N / D loop
         if N rem D = 0 or else N rem (D + 2) = 0 then
            return False;
         end if;
         D := D + 6;
      end loop;
      return True;
   end Is_Prime_Trial;

   function Primes_Up_To (Limit : U64) return U64_Array is
      Count : Natural := 0;
   begin
      if Limit < 2 then
         declare
            Empty : U64_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      for C in U64 range 2 .. Limit loop
         if Is_Prime_Trial (C) then
            Count := Count + 1;
         end if;
      end loop;

      declare
         Result : U64_Array (1 .. Count);
         I      : Natural := 0;
      begin
         for C in U64 range 2 .. Limit loop
            if Is_Prime_Trial (C) then
               I := I + 1;
               Result (I) := C;
            end if;
         end loop;
         return Result;
      end;
   end Primes_Up_To;

   ------------------------------------------------------------------
   --  Modular inverse (extended Euclidean on signed scratch)
   ------------------------------------------------------------------

   function Try_Mod_Inv (A, M : U64) return Inv_Result is
      use Interfaces;
      AA : Unsigned_128;
      MM : Unsigned_128;
      R0, R1, T0, T1, Q, Tmp : Interfaces.Integer_128;
      G   : U64;
      Inv : U64;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return (Kind => Factor_Found, Factor => 1);
      end if;

      AA := Unsigned_128 (A rem M);
      MM := Unsigned_128 (M);
      if AA = 0 then
         return (Kind => Factor_Found, Factor => M);
      end if;

      R0 := Interfaces.Integer_128 (MM);
      R1 := Interfaces.Integer_128 (AA);
      T0 := 0;
      T1 := 1;

      while R1 /= 0 loop
         Q   := R0 / R1;
         Tmp := R1;
         R1  := R0 - Q * R1;
         R0  := Tmp;
         Tmp := T1;
         T1  := T0 - Q * T1;
         T0  := Tmp;
      end loop;

      G := U64 (Unsigned_64 (Interfaces.Unsigned_128 (R0)));
      if G /= 1 then
         return (Kind => Factor_Found, Factor => G);
      end if;

      if T0 < 0 then
         T0 := T0 + Interfaces.Integer_128 (MM);
      end if;
      Inv := U64 (Unsigned_64 (Interfaces.Unsigned_128 (T0)));
      return (Kind => Ok, Inv => Inv);
   end Try_Mod_Inv;

   ------------------------------------------------------------------
   --  Curve law
   ------------------------------------------------------------------

   function Double (P : Point; C : Curve) return Op_Result is
      N   : constant U64 := C.N;
      Num : U64;
      Den : U64;
      Inv : Inv_Result;
      Lam : U64;
      X3, Y3 : U64;
      Three_X2 : U64;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      if P.Infinity then
         return (Kind => Ok, P => (X => 0, Y => 0, Infinity => True));
      end if;

      --  λ = (3x² + A) / (2y)
      Three_X2 := Mul_Mod (3, Mul_Mod (P.X, P.X, N), N);
      Num := Add_Mod (Three_X2, C.A, N);
      Den := Mul_Mod (2, P.Y, N);

      if Den = 0 then
         --  y ≡ 0 ⇒ 2P = O (vertical tangent / order-2 point).
         return (Kind => Ok, P => (X => 0, Y => 0, Infinity => True));
      end if;

      Inv := Try_Mod_Inv (Den, N);
      if Inv.Kind = Factor_Found then
         if Inv.Factor = N then
            return (Kind => Ok, P => (X => 0, Y => 0, Infinity => True));
         end if;
         return (Kind => Factor_Found, Factor => Inv.Factor);
      end if;

      Lam := Mul_Mod (Num, Inv.Inv, N);
      X3  := Sub_Mod (Mul_Mod (Lam, Lam, N), Mul_Mod (2, P.X, N), N);
      Y3  := Sub_Mod (Mul_Mod (Lam, Sub_Mod (P.X, X3, N), N), P.Y, N);
      return (Kind => Ok, P => (X => X3, Y => Y3, Infinity => False));
   end Double;

   function Add (P, Q : Point; C : Curve) return Op_Result is
      N   : constant U64 := C.N;
      Num : U64;
      Den : U64;
      Inv : Inv_Result;
      Lam : U64;
      X3, Y3 : U64;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      if P.Infinity then
         return (Kind => Ok, P => Q);
      end if;
      if Q.Infinity then
         return (Kind => Ok, P => P);
      end if;

      if P.X = Q.X then
         if Add_Mod (P.Y, Q.Y, N) = 0 then
            --  Q = −P ⇒ P + Q = O
            return (Kind => Ok, P => (X => 0, Y => 0, Infinity => True));
         else
            return Double (P, C);
         end if;
      end if;

      --  λ = (yQ − yP) / (xQ − xP)
      Num := Sub_Mod (Q.Y, P.Y, N);
      Den := Sub_Mod (Q.X, P.X, N);
      Inv := Try_Mod_Inv (Den, N);
      if Inv.Kind = Factor_Found then
         if Inv.Factor = N then
            --  Den ≡ 0 mod N but X differed under rem — treat as miss.
            return (Kind => Factor_Found, Factor => N);
         end if;
         return (Kind => Factor_Found, Factor => Inv.Factor);
      end if;

      Lam := Mul_Mod (Num, Inv.Inv, N);
      X3  := Sub_Mod
        (Sub_Mod (Mul_Mod (Lam, Lam, N), P.X, N), Q.X, N);
      Y3  := Sub_Mod (Mul_Mod (Lam, Sub_Mod (P.X, X3, N), N), P.Y, N);
      return (Kind => Ok, P => (X => X3, Y => Y3, Infinity => False));
   end Add;

   function Scalar_Mult (K : U64; P : Point; C : Curve) return Op_Result is
      R : Point := (X => 0, Y => 0, Infinity => True);
      Q : Point := P;
      KK : U64 := K;
      Res : Op_Result;
   begin
      if C.N < 2 then
         raise Invalid_Argument;
      end if;
      if K = 0 or else P.Infinity then
         return (Kind => Ok, P => (X => 0, Y => 0, Infinity => True));
      end if;

      while KK > 0 loop
         if (KK and 1) = 1 then
            Res := Add (R, Q, C);
            if Res.Kind = Factor_Found then
               return Res;
            end if;
            R := Res.P;
         end if;
         Res := Double (Q, C);
         if Res.Kind = Factor_Found then
            return Res;
         end if;
         Q  := Res.P;
         KK := KK / 2;
      end loop;
      return (Kind => Ok, P => R);
   end Scalar_Mult;

   ------------------------------------------------------------------
   --  Stage 1 once / dispatcher
   ------------------------------------------------------------------

   function ECM_Stage1_Once
     (C : Curve; P : Point; B : U64) return U64
   is
      Q  : Point := P;
      PP : U64;
      Res : Op_Result;
      Disc : U64;
      G    : U64;
      Four_A3, Twenty_Seven_B2 : U64;
   begin
      if C.N < 2 or else B < 2 then
         raise Invalid_Argument;
      end if;

      --  Optional early split via discriminant Δ = −16(4A³ + 27B²).
      Four_A3 := Mul_Mod (4, Mul_Mod (C.A, Mul_Mod (C.A, C.A, C.N), C.N), C.N);
      Twenty_Seven_B2 :=
        Mul_Mod (27, Mul_Mod (C.B, C.B, C.N), C.N);
      Disc := Add_Mod (Four_A3, Twenty_Seven_B2, C.N);
      G := Gcd (Disc, C.N);
      if G > 1 and then G < C.N then
         return G;
      end if;

      declare
         Primes : constant U64_Array := Primes_Up_To (B);
      begin
         for Prime of Primes loop
            PP := Prime;
            loop
               Res := Scalar_Mult (Prime, Q, C);
               if Res.Kind = Factor_Found then
                  if Res.Factor > 1 and then Res.Factor < C.N then
                     return Res.Factor;
                  end if;
                  if Res.Factor = C.N then
                     return C.N;
                  end if;
                  --  Factor = 1 (edge) — continue
               else
                  Q := Res.P;
               end if;
               exit when PP > B / Prime;
               PP := PP * Prime;
            end loop;
         end loop;
      end;
      return 1;
   end ECM_Stage1_Once;

   --  Deterministic LCG (Numerical Recipes / glibc-ish constants).
   procedure LCG_Step (State : in out U64) is
   begin
      State := State * 1_103_515_245 + 12_345;
   end LCG_Step;

   function Factor_ECM_Stage1
     (N      : U64;
      B      : U64     := Default_B;
      Curves : Natural := Default_Curves;
      Seed   : U64     := 1) return U64
   is
      State : U64 := Seed;
      A, X0, Y0, Bb : U64;
      C : Curve;
      P : Point;
      F : U64;
   begin
      if N < 2 or else B < 2 or else Curves = 0 then
         raise Invalid_Argument;
      end if;

      if N rem 2 = 0 then
         return 2;
      end if;

      if Is_Prime_Trial (N) then
         return 1;
      end if;

      for Unused in 1 .. Curves loop
         pragma Unreferenced (Unused);
         LCG_Step (State);
         A := State rem N;
         LCG_Step (State);
         X0 := State rem N;
         LCG_Step (State);
         Y0 := State rem N;

         --  Choose B so that (X0, Y0) lies on y² = x³ + A x + B.
         Bb := Sub_Mod
           (Mul_Mod (Y0, Y0, N),
            Add_Mod
              (Mul_Mod (X0, Mul_Mod (X0, X0, N), N),
               Mul_Mod (A, X0, N),
               N),
            N);

         C := (A => A, B => Bb, N => N);
         P := (X => X0, Y => Y0, Infinity => False);

         F := ECM_Stage1_Once (C, P, B);
         if F > 1 and then F < N then
            return F;
         end if;
      end loop;
      return 1;
   end Factor_ECM_Stage1;

   function Factor
     (N    : U64;
      B    : U64 := Default_B;
      Seed : U64 := 1) return U64
   is
   begin
      return Factor_ECM_Stage1
        (N => N, B => B, Curves => Default_Curves, Seed => Seed);
   end Factor;

end Lenstra_Elliptic_Curve_Factorization;
