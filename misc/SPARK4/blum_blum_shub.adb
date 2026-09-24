--  Blum_Blum_Shub body — BBS recurrence x ← x² mod M, overflow-safe
--  modular square (M ≤ 2**32), Blum-prime trial division. SPARK Level 4:
--  bounded loops, no heap, no exceptions, primes capped so arithmetic
--  stays wrap-free inside a single mod-2**64 word.

package body Blum_Blum_Shub
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Is_Prime / Is_Blum_Prime
   ---------------------------------------------------------------------------

   function Is_Prime (N : Value) return Boolean is
      --  ceil(sqrt(Max_Prime)) = 256. Bounded for-loop ⇒ termination
      --  is immediate for GNATprove (same pattern as LCG Prime_Factors).
      Max_Trial : constant Positive := 256;
      P         : Value;
   begin
      if N < 2 or else N > Max_Prime then
         return False;
      end if;
      if N = 2 or else N = 3 then
         return True;
      end if;
      if N rem 2 = 0 or else N rem 3 = 0 then
         return False;
      end if;

      for Trial in 5 .. Max_Trial loop
         pragma Loop_Invariant (N >= 5 and then N <= Max_Prime);
         P := Value (Trial);
         if P > N / P then
            return True;
         end if;
         if N rem P = 0 then
            return False;
         end if;
      end loop;
      return True;
   end Is_Prime;

   function Is_Blum_Prime (N : Value) return Boolean is
   begin
      return Is_Prime (N) and then N rem 4 = 3;
   end Is_Blum_Prime;

   ---------------------------------------------------------------------------
   -- GCD
   ---------------------------------------------------------------------------

   function Gcd (X, Y : Value) return Value is
      A : Value := X;
      B : Value := Y;
      T : Value;
   begin
      while B /= 0 loop
         pragma Loop_Variant (Decreases => B);
         T := A rem B;
         A := B;
         B := T;
      end loop;
      return A;
   end Gcd;

   function Are_Coprime (X, Y : Value) return Boolean is
   begin
      return Gcd (X, Y) = 1;
   end Are_Coprime;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Is_Valid_Modulus (M : Value) return Boolean is
   begin
      return M >= 2 and then M <= Max_Modulus;
   end Is_Valid_Modulus;

   function Is_Valid_Blum_Pair (P, Q : Value) return Boolean is
      Prod : Value;
   begin
      if P > Max_Prime or else Q > Max_Prime then
         return False;
      end if;
      if P = Q then
         return False;
      end if;
      if not Is_Blum_Prime (P) or else not Is_Blum_Prime (Q) then
         return False;
      end if;
      --  P,Q ≤ 2**16 ⇒ P·Q ≤ 2**32 = Max_Modulus (no wrap in Value).
      Prod := P * Q;
      return Prod >= 2 and then Prod <= Max_Modulus;
   end Is_Valid_Blum_Pair;

   function Is_Valid_Seed (Seed, M : Value) return Boolean is
   begin
      return Seed > 1 and then Seed < M and then Are_Coprime (Seed, M);
   end Is_Valid_Seed;

   ---------------------------------------------------------------------------
   -- Overflow-safe modular arithmetic
   ---------------------------------------------------------------------------

   function Mul_Mod (X, Y : Value; M : Modulus_Type) return Value is
      Prod : Value;
   begin
      --  X,Y < M ≤ 2**32 ⇒ X·Y ≤ (M−1)² = M²−2M+1 ≤ 2**64−2**33+1
      --  which fits in Value without modular wrap.
      Prod := X * Y;
      return Prod rem M;
   end Mul_Mod;

   function Square_Mod (X : Value; M : Modulus_Type) return Value is
   begin
      return Mul_Mod (X, X, M);
   end Square_Mod;

   ---------------------------------------------------------------------------
   -- Create / Initialize / Reset
   ---------------------------------------------------------------------------

   function Create (P, Q, Seed : Value) return Generator is
      M     : constant Value := P * Q;
      State : constant Value := Square_Mod (Seed, Modulus_Type (M));
   begin
      return
        (P           => P,
         Q           => Q,
         M           => M,
         State       => State,
         Seed        => Seed,
         Initialised => True);
   end Create;

   procedure Initialize
     (Gen  : out Generator;
      P    : Value;
      Q    : Value;
      Seed : Value)
   is
   begin
      Gen := Create (P, Q, Seed);
   end Initialize;

   procedure Reset (G : in out Generator; Seed : Value) is
   begin
      G.Seed  := Seed;
      G.State := Square_Mod (Seed, Modulus_Type (G.M));
   end Reset;

   ---------------------------------------------------------------------------
   -- Next_Bit / Next_Byte / Next_Bits
   ---------------------------------------------------------------------------

   procedure Next_Bit (G : in out Generator; Result : out Boolean) is
   begin
      G.State := Square_Mod (G.State, Modulus_Type (G.M));
      Result  := G.State rem 2 /= 0;
   end Next_Bit;

   procedure Next_Byte (G : in out Generator; Result : out Value) is
      Acc : Value := 0;
      Bit : Boolean;
   begin
      for I in 1 .. 8 loop
         pragma Loop_Invariant (Is_Initialised (G));
         pragma Loop_Invariant (G.P = G.P'Loop_Entry);
         pragma Loop_Invariant (G.Q = G.Q'Loop_Entry);
         pragma Loop_Invariant (G.M = G.M'Loop_Entry);
         pragma Loop_Invariant (G.Seed = G.Seed'Loop_Entry);
         pragma Loop_Invariant (G.State < G.M);
         pragma Loop_Invariant (Acc < Value (2) ** (I - 1));
         Next_Bit (G, Bit);
         Acc := Acc * 2;
         if Bit then
            Acc := Acc + 1;
         end if;
      end loop;
      Result := Acc;
   end Next_Byte;

   procedure Next_Bits
     (G      : in out Generator;
      Count  : Bit_Count;
      Result : out Value)
   is
      Acc : Value := 0;
      Bit : Boolean;
   begin
      for I in 1 .. Count loop
         pragma Loop_Invariant (Is_Initialised (G));
         pragma Loop_Invariant (G.P = G.P'Loop_Entry);
         pragma Loop_Invariant (G.Q = G.Q'Loop_Entry);
         pragma Loop_Invariant (G.M = G.M'Loop_Entry);
         pragma Loop_Invariant (G.Seed = G.Seed'Loop_Entry);
         pragma Loop_Invariant (G.State < G.M);
         Next_Bit (G, Bit);
         Acc := Acc * 2;
         if Bit then
            Acc := Acc + 1;
         end if;
      end loop;
      Result := Acc;
   end Next_Bits;

end Blum_Blum_Shub;
