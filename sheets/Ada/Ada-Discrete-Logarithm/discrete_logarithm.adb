--  Discrete logarithm — Ada 2023 body (educational survey sketches).

pragma Ada_2022;

with Interfaces;

package body Discrete_Logarithm
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Helpers
   ------------------------------------------------------------------

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

   function Mod_Pow (Base, Exp, Modulus : U64) return U64 is
      Result : U64 := 1;
      B      : U64;
      E      : U64 := Exp;
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      if Modulus = 1 then
         return 0;
      end if;
      B := Base rem Modulus;
      while E > 0 loop
         if (E and 1) = 1 then
            Result := Mul_Mod (Result, B, Modulus);
         end if;
         B := Mul_Mod (B, B, Modulus);
         E := E / 2;
      end loop;
      return Result;
   end Mod_Pow;

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

   --  Extended Euclidean on Long_Long_Integer; returns (G, X, Y) with
   --  A*X + B*Y = G and G ≥ 0.
   procedure Extended_Gcd_LL
     (A, B : Long_Long_Integer;
      G, X, Y : out Long_Long_Integer)
   is
      Old_R, R : Long_Long_Integer;
      Old_S, S : Long_Long_Integer;
      Old_T, T : Long_Long_Integer;
      Quotient, Tmp : Long_Long_Integer;
   begin
      Old_R := A;
      R     := B;
      Old_S := 1;
      S     := 0;
      Old_T := 0;
      T     := 1;
      while R /= 0 loop
         Quotient := Old_R / R;
         Tmp := R;
         R := Old_R - Quotient * R;
         Old_R := Tmp;
         Tmp := S;
         S := Old_S - Quotient * S;
         Old_S := Tmp;
         Tmp := T;
         T := Old_T - Quotient * T;
         Old_T := Tmp;
      end loop;
      if Old_R < 0 then
         G := -Old_R;
         X := -Old_S;
         Y := -Old_T;
      else
         G := Old_R;
         X := Old_S;
         Y := Old_T;
      end if;
   end Extended_Gcd_LL;

   function Modular_Inverse (A, M : U64) return U64 is
      AA, MM : Long_Long_Integer;
      G, X, Y : Long_Long_Integer;
      Inv : Long_Long_Integer;
   begin
      if M <= 1 then
         raise Invalid_Argument;
      end if;
      AA := Long_Long_Integer (A rem M);
      MM := Long_Long_Integer (M);
      Extended_Gcd_LL (AA, MM, G, X, Y);
      pragma Unreferenced (Y);
      if G /= 1 then
         raise Invalid_Argument;
      end if;
      Inv := X mod MM;
      if Inv < 0 then
         Inv := Inv + MM;
      end if;
      return U64 (Inv);
   end Modular_Inverse;

   function Floor_Sqrt (N : U64) return U64 is
      use Interfaces;
      Lo, Hi, Mid : U64;
      Prod        : Unsigned_128;
      NN          : constant Unsigned_128 := Unsigned_128 (N);
   begin
      if N <= 1 then
         return N;
      end if;
      Lo := 1;
      Hi := N / 2;
      if Hi > 4_294_967_295 then
         Hi := 4_294_967_295;
      end if;
      while Lo < Hi loop
         Mid  := Lo + (Hi - Lo + 1) / 2;
         Prod := Unsigned_128 (Mid) * Unsigned_128 (Mid);
         if Prod = NN then
            return Mid;
         elsif Prod < NN then
            Lo := Mid;
         else
            Hi := Mid - 1;
         end if;
      end loop;
      return Lo;
   end Floor_Sqrt;

   function Ceil_Sqrt (N : U64) return U64 is
      use Interfaces;
      S    : U64;
      Prod : Unsigned_128;
   begin
      if N = 0 then
         return 0;
      end if;
      S := Floor_Sqrt (N);
      Prod := Unsigned_128 (S) * Unsigned_128 (S);
      if Prod = Unsigned_128 (N) then
         return S;
      else
         return S + 1;
      end if;
   end Ceil_Sqrt;

   function Verify_Discrete_Log
     (Alpha, Beta, Modulus, Log : U64) return Boolean
   is
   begin
      if Modulus <= 1 then
         return False;
      end if;
      return Mod_Pow (Alpha, Log, Modulus) = (Beta rem Modulus);
   end Verify_Discrete_Log;

   ------------------------------------------------------------------
   --  Shared input checks
   ------------------------------------------------------------------

   procedure Check_DL_Domain
     (Alpha, Beta, Modulus, Order : U64;
      A_Alp, B_Bet : out U64)
   is
   begin
      if Modulus < 2 then
         raise Invalid_Argument;
      end if;
      if Order = 0 or else Order > Max_Educational_Order then
         raise Invalid_Argument;
      end if;
      A_Alp := Alpha rem Modulus;
      B_Bet := Beta rem Modulus;
      if A_Alp = 0 or else B_Bet = 0 then
         raise Invalid_Argument;
      end if;
   end Check_DL_Domain;

   ------------------------------------------------------------------
   --  Factorization (trial)
   ------------------------------------------------------------------

   function Factorize_Trial (N : U64) return Factor_Array is
      Remaining : U64;
      Count     : Natural := 0;
      Buf       : Factor_Array (1 .. Max_Factor_Count);
      P         : U64;
      E         : Natural;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if N = 1 then
         return Factor_Array'(1 .. 0 => <>);
      end if;

      Remaining := N;

      if Remaining rem 2 = 0 then
         E := 0;
         while Remaining rem 2 = 0 loop
            Remaining := Remaining / 2;
            E := E + 1;
         end loop;
         Count := Count + 1;
         Buf (Count) := (Prime => 2, Exp => E);
      end if;

      P := 3;
      while P <= Remaining / P loop
         if Remaining rem P = 0 then
            E := 0;
            while Remaining rem P = 0 loop
               Remaining := Remaining / P;
               E := E + 1;
            end loop;
            if Count >= Max_Factor_Count then
               raise Invalid_Argument;
            end if;
            Count := Count + 1;
            Buf (Count) := (Prime => P, Exp => E);
         end if;
         P := P + 2;
      end loop;

      if Remaining > 1 then
         if Count >= Max_Factor_Count then
            raise Invalid_Argument;
         end if;
         Count := Count + 1;
         Buf (Count) := (Prime => Remaining, Exp => 1);
      end if;

      return Buf (1 .. Count);
   end Factorize_Trial;

   ------------------------------------------------------------------
   --  1. Discrete_Log_Trial
   ------------------------------------------------------------------

   function Discrete_Log_Trial
     (Alpha   : U64;
      Beta    : U64;
      Modulus : U64;
      Order   : U64) return U64
   is
      A_Alp : U64;
      B_Bet : U64;
      Cur   : U64;
      Gamma : U64;
   begin
      Check_DL_Domain (Alpha, Beta, Modulus, Order, A_Alp, B_Bet);

      if B_Bet = 1 then
         return 0;
      end if;
      if A_Alp = B_Bet then
         return 1 rem Order;
      end if;

      Cur := 1;
      Gamma := 0;
      while Gamma < Order loop
         if Cur = B_Bet then
            return Gamma;
         end if;
         Cur := Mul_Mod (Cur, A_Alp, Modulus);
         Gamma := Gamma + 1;
      end loop;

      return Order;  --  failure sentinel
   end Discrete_Log_Trial;

   ------------------------------------------------------------------
   --  2. Discrete_Log_BSGS
   ------------------------------------------------------------------

   type Baby_Entry is record
      Value : U64 := 0;
      Exp   : U64 := 0;
   end record;

   type Baby_Table is array (Natural range <>) of Baby_Entry;

   function Lookup_Baby
     (Table : Baby_Table;
      Last  : Natural;
      Value : U64;
      Order : U64) return U64
   is
   begin
      for I in 0 .. Last loop
         if Table (I).Value = Value then
            return Table (I).Exp;
         end if;
      end loop;
      return Order;
   end Lookup_Baby;

   function Discrete_Log_BSGS
     (Alpha   : U64;
      Beta    : U64;
      Modulus : U64;
      Order   : U64) return U64
   is
      A_Alp   : U64;
      B_Bet   : U64;
      M       : U64;
      M_Nat   : Natural;
      Cur     : U64;
      J       : U64;
      Factor  : U64;
      Y       : U64;
      Gamma   : U64;
      Inv_A   : U64;
      Alpha_M : U64;
   begin
      Check_DL_Domain (Alpha, Beta, Modulus, Order, A_Alp, B_Bet);

      if B_Bet = 1 then
         return 0;
      end if;
      if A_Alp = B_Bet then
         return 1 rem Order;
      end if;

      M := Ceil_Sqrt (Order);
      if M = 0 then
         return Order;
      end if;
      M_Nat := Natural (M);

      declare
         Table : Baby_Table (0 .. M_Nat - 1);
      begin
         Cur := 1;
         for Idx in 0 .. M_Nat - 1 loop
            Table (Idx).Value := Cur;
            Table (Idx).Exp   := U64 (Idx);
            Cur := Mul_Mod (Cur, A_Alp, Modulus);
         end loop;

         Alpha_M := Mod_Pow (A_Alp, M, Modulus);
         begin
            Inv_A := Modular_Inverse (Alpha_M, Modulus);
         exception
            when Invalid_Argument =>
               return Order;
         end;
         Factor := Inv_A;

         Y := B_Bet;
         for I in 0 .. M_Nat - 1 loop
            J := Lookup_Baby (Table, M_Nat - 1, Y, Order);
            if J < Order then
               Gamma := U64 (I) * M + J;
               if Gamma < Order
                 and then Verify_Discrete_Log (A_Alp, B_Bet, Modulus, Gamma)
               then
                  return Gamma;
               end if;
            end if;
            Y := Mul_Mod (Y, Factor, Modulus);
         end loop;
      end;

      return Order;
   end Discrete_Log_BSGS;

   ------------------------------------------------------------------
   --  3. Minimal Pohlig–Hellman
   ------------------------------------------------------------------

   --  Find D in 0 .. P−1 such that Base^D ≡ Target (mod Modulus).
   --  Exhaustive only (educational; P ≤ Max_Prime_Factor). Returns P on fail.
   function Discrete_Log_Order_P
     (Base, Target, Modulus, P : U64) return U64
   is
      Cur : U64;
      D   : U64;
      Tgt : U64;
   begin
      if P = 0 then
         return 0;
      end if;

      Tgt := Target rem Modulus;

      if Tgt = 1 then
         return 0;
      end if;
      if (Base rem Modulus) = Tgt then
         return 1 rem P;
      end if;

      Cur := 1;
      D := 0;
      while D < P loop
         if Cur = Tgt then
            return D;
         end if;
         Cur := Mul_Mod (Cur, Base, Modulus);
         D := D + 1;
      end loop;
      return P;
   end Discrete_Log_Order_P;

   --  G has order P^E; H in ⟨G⟩. Return X with G^X = H, or P^E on fail.
   function Discrete_Log_Prime_Power
     (G, H, Modulus, P : U64; E : Natural) return U64
   is
      Pe     : U64 := 1;
      Gamma  : U64;
      Xk     : U64 := 0;
      Hk     : U64;
      Dk     : U64;
      G_Inv  : U64;
      Pk     : U64;
      Exp_Hk : U64;
      Tmp    : U64;
   begin
      for K in 1 .. E loop
         Pe := Pe * P;
      end loop;

      if H rem Modulus = 1 then
         return 0;
      end if;

      Gamma := Mod_Pow (G, Pe / P, Modulus);

      begin
         G_Inv := Modular_Inverse (G, Modulus);
      exception
         when Invalid_Argument =>
            return Pe;
      end;

      Xk := 0;
      Pk := 1;
      for K in 0 .. E - 1 loop
         Tmp := Mod_Pow (G_Inv, Xk, Modulus);
         Tmp := Mul_Mod (Tmp, H, Modulus);
         Exp_Hk := Pe / P;
         for Red in 1 .. K loop
            Exp_Hk := Exp_Hk / P;
            pragma Unreferenced (Red);
         end loop;
         Hk := Mod_Pow (Tmp, Exp_Hk, Modulus);

         Dk := Discrete_Log_Order_P (Gamma, Hk, Modulus, P);
         if Dk >= P then
            return Pe;
         end if;

         Xk := Xk + Dk * Pk;
         Pk := Pk * P;
      end loop;

      return Xk;
   end Discrete_Log_Prime_Power;

   function CRT
     (A : Factor_Array;
      M : Factor_Array;
      N : U64) return U64
   is
      Acc : U64 := 0;
      Ni  : U64;
      Yi  : U64;
      Mi  : U64;
   begin
      for I in A'Range loop
         Mi := 1;
         for K in 1 .. M (I).Exp loop
            Mi := Mi * M (I).Prime;
         end loop;
         Ni := N / Mi;
         begin
            Yi := Modular_Inverse (Ni rem Mi, Mi);
         exception
            when Invalid_Argument =>
               return N;
         end;
         Acc := (Acc + Mul_Mod (Mul_Mod (A (I).Prime, Ni, N), Yi, N)) rem N;
      end loop;
      return Acc;
   end CRT;

   function Is_Smooth_Enough (Factors : Factor_Array) return Boolean is
   begin
      for F of Factors loop
         if F.Prime > Max_Prime_Factor then
            return False;
         end if;
      end loop;
      return True;
   end Is_Smooth_Enough;

   function Product_Of_Factors (Factors : Factor_Array) return U64 is
      Acc : U64 := 1;
      Pw  : U64;
   begin
      for F of Factors loop
         if F.Prime < 2 or else F.Exp = 0 then
            raise Invalid_Argument;
         end if;
         Pw := 1;
         for K in 1 .. F.Exp loop
            if Pw > U64'Last / F.Prime then
               raise Invalid_Argument;
            end if;
            Pw := Pw * F.Prime;
         end loop;
         if Acc > U64'Last / Pw then
            raise Invalid_Argument;
         end if;
         Acc := Acc * Pw;
      end loop;
      return Acc;
   end Product_Of_Factors;


   --  Exact order of Alpha in the cyclic group of claimed Order
   --  (divide out prime factors while Alpha^{Ord/p} ≡ 1).
   function Order_Of (Alpha, Modulus, Order : U64) return U64 is
      Ord : U64 := Order;
      Fac : constant Factor_Array := Factorize_Trial (Order);
      Cand : U64;
   begin
      for F of Fac loop
         for K in 1 .. F.Exp loop
            pragma Unreferenced (K);
            Cand := Ord / F.Prime;
            if Mod_Pow (Alpha, Cand, Modulus) = 1 then
               Ord := Cand;
            else
               exit;
            end if;
         end loop;
      end loop;
      if Ord = 0 then
         return Order;
      end if;
      return Ord;
   end Order_Of;

   function Discrete_Log_Pohlig_Hellman
     (Alpha   : U64;
      Beta    : U64;
      Modulus : U64;
      Order   : U64) return U64
   is
      A_Alp    : U64;
      B_Bet    : U64;
      Gi, Hi   : U64;
      Xi       : U64;
      Ni       : U64;
      Pe       : U64;
      Residues : Factor_Array (1 .. Max_Factor_Count);
      Mods     : Factor_Array (1 .. Max_Factor_Count);
      Result   : U64;
      Last     : Natural;
   begin
      Check_DL_Domain (Alpha, Beta, Modulus, Order, A_Alp, B_Bet);

      declare
         Factors : constant Factor_Array := Factorize_Trial (Order);
      begin
      if Factors'Length = 0 then
         if Order = 1 then
            if B_Bet = 1 then
               return 0;
            else
               return 1;
            end if;
         end if;
         return Order;
      end if;

      if Product_Of_Factors (Factors) /= Order then
         return Order;
      end if;

      if not Is_Smooth_Enough (Factors) then
         return Order;
      end if;

      if B_Bet = 1 then
         return 0;
      end if;
      if A_Alp = B_Bet then
         return 1 rem Order;
      end if;

      Last := 0;
      for I in Factors'Range loop
         Pe := 1;
         for K in 1 .. Factors (I).Exp loop
            Pe := Pe * Factors (I).Prime;
         end loop;
         Ni := Order / Pe;
         Gi := Mod_Pow (A_Alp, Ni, Modulus);
         Hi := Mod_Pow (B_Bet, Ni, Modulus);

         Xi := Discrete_Log_Prime_Power
           (Gi, Hi, Modulus, Factors (I).Prime, Factors (I).Exp);
         if Xi >= Pe then
            return Order;
         end if;

         Last := Last + 1;
         Residues (Last) := (Prime => Xi, Exp => 0);
         Mods (Last)     := Factors (I);
      end loop;

      Result := CRT (Residues (1 .. Last), Mods (1 .. Last), Order);

      if Result >= Order then
         return Order;
      end if;

      if not Verify_Discrete_Log (A_Alp, B_Bet, Modulus, Result) then
         return Order;
      end if;

      --  Canonicalize to the least residue mod the true order of α
      --  (caller may supply a multiple of ord(α)).
      declare
         True_Ord : constant U64 := Order_Of (A_Alp, Modulus, Order);
      begin
         return Result rem True_Ord;
      end;
      end;
   end Discrete_Log_Pohlig_Hellman;

   ------------------------------------------------------------------
   --  4. Driver
   ------------------------------------------------------------------

   function Discrete_Log
     (Alpha   : U64;
      Beta    : U64;
      Modulus : U64;
      Order   : U64) return U64
   is
   begin
      --  Domain checks are delegated to the callees.
      if Order <= Max_Trial_Order then
         return Discrete_Log_Trial (Alpha, Beta, Modulus, Order);
      else
         return Discrete_Log_BSGS (Alpha, Beta, Modulus, Order);
      end if;
   end Discrete_Log;

end Discrete_Logarithm;
