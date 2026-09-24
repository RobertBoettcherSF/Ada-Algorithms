--  Baby-step giant-step (Shanks) — Ada 2023 implementation (educational).

pragma Ada_2022;

with Interfaces;

package body Baby_Step_Giant_Step
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
      --  Binary search for largest K with K*K ≤ N (Unsigned_128 product).
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
         --  √(2^64−1) < 2^32, so clamp upper bound.
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
   --  Baby table: (Value, Exp) pairs; linear O(m) lookup
   ------------------------------------------------------------------

   type Baby_Entry is record
      Value : U64 := 0;
      Exp   : U64 := 0;
   end record;

   type Baby_Table is array (Natural range <>) of Baby_Entry;

   --  Return the baby exponent j if Value appears in Table (0 .. Last),
   --  or Order as a not-found sentinel (caller passes Order).
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

   ------------------------------------------------------------------
   --  Discrete_Log_BSGS
   ------------------------------------------------------------------

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

      --  Trivial / quick cases
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
         --  Baby steps: Table(j) = (α^j, j) for j = 0 .. m−1
         Cur := 1;
         for Idx in 0 .. M_Nat - 1 loop
            Table (Idx).Value := Cur;
            Table (Idx).Exp   := U64 (Idx);
            Cur := Mul_Mod (Cur, A_Alp, Modulus);
         end loop;

         --  Giant-step factor: α^{-m} = (α^m)^{-1} mod Modulus
         Alpha_M := Mod_Pow (A_Alp, M, Modulus);
         begin
            Inv_A := Modular_Inverse (Alpha_M, Modulus);
         exception
            when Invalid_Argument =>
               return Order;
         end;
         Factor := Inv_A;

         --  Giant steps: y_i = β · (α^{-m})^i; look up in baby table
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
               --  Match found but does not verify (β ∉ ⟨α⟩) — keep searching
            end if;
            Y := Mul_Mod (Y, Factor, Modulus);
         end loop;
      end;

      return Order;  --  failure sentinel
   end Discrete_Log_BSGS;

end Baby_Step_Giant_Step;
