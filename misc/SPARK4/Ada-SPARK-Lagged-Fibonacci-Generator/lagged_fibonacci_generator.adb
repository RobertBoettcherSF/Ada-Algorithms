--  Lagged_Fibonacci_Generator body — ring-buffer LFG, LCG seed fill,
--  overflow-safe modular Add / Subtract / Bitwise_Xor. SPARK Level 4:
--  bounded loops, no heap, no exceptions, modulus capped so arithmetic
--  stays wrap-free.

package body Lagged_Fibonacci_Generator
  with SPARK_Mode => On
is

   LCG_A : constant Value := 1_664_525;
   LCG_C : constant Value := 1_013_904_223;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Is_Valid_Lags (J, K : Positive) return Boolean is
   begin
      return J < K and then K <= Max_Lag;
   end Is_Valid_Lags;

   function Is_Valid_Lags (Lags : Lag_Pair) return Boolean is
   begin
      return Lags.J < Lags.K;
   end Is_Valid_Lags;

   function Is_Valid_Modulus (M : Value) return Boolean is
   begin
      return M >= 2 and then M <= Max_Modulus;
   end Is_Valid_Modulus;

   function Seeds_In_Range
     (K     : Lag_Index;
      M     : Modulus_Type;
      Seeds : Seed_Array) return Boolean
   is
   begin
      for I in 1 .. K loop
         pragma Loop_Invariant
           (for all J in 1 .. I - 1 => Seeds (J) < M);
         if Seeds (I) >= M then
            return False;
         end if;
      end loop;
      return True;
   end Seeds_In_Range;

   ---------------------------------------------------------------------------
   -- Overflow-safe modular arithmetic
   ---------------------------------------------------------------------------

   function Add_Mod (X, Y : Value; M : Modulus_Type) return Value is
      Sum : Value;
   begin
      --  X < M ≤ 2**32 and Y < M ⇒ X+Y < 2**33 < 2**64 (no wrap).
      Sum := X + Y;
      if Sum >= M then
         return Sum - M;
      else
         return Sum;
      end if;
   end Add_Mod;

   function Sub_Mod (X, Y : Value; M : Modulus_Type) return Value is
   begin
      if X >= Y then
         return X - Y;
      else
         return M - (Y - X);
      end if;
   end Sub_Mod;

   function Xor_Mod (X, Y : Value; M : Modulus_Type) return Value is
   begin
      return (X xor Y) rem M;
   end Xor_Mod;

   function Combine
     (X, Y : Value; Op : Binary_Op; M : Modulus_Type) return Value
   is
   begin
      case Op is
         when Add =>
            return Add_Mod (X, Y, M);
         when Subtract =>
            return Sub_Mod (X, Y, M);
         when Bitwise_Xor =>
            return Xor_Mod (X, Y, M);
      end case;
   end Combine;

   ---------------------------------------------------------------------------
   -- LCG seed fill
   ---------------------------------------------------------------------------

   function LCG_Step (State : Value; M : Modulus_Type) return Value
     with
       Global => null,
       Pre    => State < M,
       Post   => LCG_Step'Result < M;

   function LCG_Step (State : Value; M : Modulus_Type) return Value is
      Wide : Value;
   begin
      --  A·State + C < 1664525·(2**32−1) + 1013904223 < 2**54 < 2**64.
      Wide := LCG_A * State + LCG_C;
      return Wide rem M;
   end LCG_Step;

   procedure Fill_From_Seed
     (Buf  : out Seed_Array;
      K    : Lag_Index;
      M    : Modulus_Type;
      Seed : Value;
      Op   : Binary_Op)
     with
       Global => null,
       Pre    => Seed < M,
       Post   => (for all I in 1 .. K => Buf (I) < M)
                 and then
                   (for all I in K + 1 .. Max_Lag => Buf (I) = 0);

   procedure Fill_From_Seed
     (Buf  : out Seed_Array;
      K    : Lag_Index;
      M    : Modulus_Type;
      Seed : Value;
      Op   : Binary_Op)
   is
      X       : Value := Seed;
      Has_Odd : Boolean := False;
   begin
      Buf := [others => 0];
      for I in 1 .. K loop
         pragma Loop_Invariant (X < M);
         pragma Loop_Invariant
           (for all J in 1 .. I - 1 => Buf (J) < M);
         pragma Loop_Invariant
           (for all J in I .. Max_Lag => Buf (J) = 0);
         X := LCG_Step (X, M);
         Buf (I) := X;
         if X rem 2 = 1 then
            Has_Odd := True;
         end if;
      end loop;

      --  Additive / subtractive LFGs need at least one odd seed word.
      if Op /= Bitwise_Xor and then not Has_Odd then
         if Buf (1) < M - 1 then
            Buf (1) := Buf (1) + 1;
         else
            Buf (1) := 1;
         end if;
      end if;
   end Fill_From_Seed;

   procedure Install_Seeds
     (Buf   : out Seed_Array;
      K     : Lag_Index;
      M     : Modulus_Type;
      Seeds : Seed_Array)
     with
       Global => null,
       Pre    => Seeds_In_Range (K, M, Seeds),
       Post   => (for all I in 1 .. K => Buf (I) = Seeds (I))
                 and then
                   (for all I in K + 1 .. Max_Lag => Buf (I) = 0)
                 and then
                   (for all I in 1 .. K => Buf (I) < M);

   procedure Install_Seeds
     (Buf   : out Seed_Array;
      K     : Lag_Index;
      M     : Modulus_Type;
      Seeds : Seed_Array)
   is
   begin
      Buf := [others => 0];
      for I in 1 .. K loop
         pragma Loop_Invariant
           (for all J in 1 .. I - 1 => Buf (J) = Seeds (J));
         pragma Loop_Invariant
           (for all J in 1 .. I - 1 => Buf (J) < M);
         pragma Loop_Invariant
           (for all J in I .. Max_Lag => Buf (J) = 0);
         pragma Assert (Seeds (I) < M);
         Buf (I) := Seeds (I);
      end loop;
   end Install_Seeds;

   function Build
     (J   : Lag_Index;
      K   : Lag_Index;
      Op  : Binary_Op;
      M   : Modulus_Type;
      Buf : Seed_Array) return Generator
     with
       Global => null,
       Pre    => J < K
                 and then (for all I in 1 .. K => Buf (I) < M),
       Post   => Build'Result.Initialised
                 and then Build'Result.J = J
                 and then Build'Result.K = K
                 and then Build'Result.Op = Op
                 and then Build'Result.M = M
                 and then Build'Result.Cursor = 0
                 and then
                   (for all I in 1 .. K =>
                      Build'Result.Buffer (I) = Buf (I));

   function Build
     (J   : Lag_Index;
      K   : Lag_Index;
      Op  : Binary_Op;
      M   : Modulus_Type;
      Buf : Seed_Array) return Generator
   is
   begin
      return
        (J           => J,
         K           => K,
         Op          => Op,
         M           => M,
         Buffer      => Buf,
         Cursor      => 0,
         Initialised => True);
   end Build;

   ---------------------------------------------------------------------------
   -- Create / Reset
   ---------------------------------------------------------------------------

   function Create
     (J     : Lag_Index;
      K     : Lag_Index;
      Op    : Binary_Op;
      M     : Modulus_Type;
      Seeds : Seed_Array) return Generator
   is
      Buf : Seed_Array;
   begin
      Install_Seeds (Buf, K, M, Seeds);
      return Build (J, K, Op, M, Buf);
   end Create;

   function Create
     (J    : Lag_Index;
      K    : Lag_Index;
      Op   : Binary_Op;
      M    : Modulus_Type;
      Seed : Value) return Generator
   is
      Buf : Seed_Array;
   begin
      Fill_From_Seed (Buf, K, M, Seed, Op);
      return Build (J, K, Op, M, Buf);
   end Create;

   function Create
     (Lags  : Lag_Pair;
      Op    : Binary_Op;
      M     : Modulus_Type;
      Seeds : Seed_Array) return Generator
   is
   begin
      return Create (Lags.J, Lags.K, Op, M, Seeds);
   end Create;

   function Create
     (Lags : Lag_Pair;
      Op   : Binary_Op;
      M    : Modulus_Type;
      Seed : Value) return Generator
   is
   begin
      return Create (Lags.J, Lags.K, Op, M, Seed);
   end Create;

   procedure Reset (G : in out Generator; Seeds : Seed_Array) is
      Buf : Seed_Array;
      Kv  : constant Lag_Index := Get_K (G);
      Mv  : constant Modulus_Type := Get_Modulus (G);
   begin
      Install_Seeds (Buf, Kv, Mv, Seeds);
      G.Buffer := Buf;
      G.Cursor := 0;
   end Reset;

   procedure Reset (G : in out Generator; Seed : Value) is
      Buf : Seed_Array;
      Kv  : constant Lag_Index := Get_K (G);
      Mv  : constant Modulus_Type := Get_Modulus (G);
      Opv : constant Binary_Op := Get_Op (G);
   begin
      Fill_From_Seed (Buf, Kv, Mv, Seed, Opv);
      G.Buffer := Buf;
      G.Cursor := 0;
   end Reset;

   ---------------------------------------------------------------------------
   -- Next
   ---------------------------------------------------------------------------

   procedure Next (G : in out Generator; Result : out Value) is
      Kv    : constant Lag_Index := G.K;
      Jv    : constant Lag_Index := G.J;
      Mv    : constant Modulus_Type := Modulus_Type (G.M);
      Opv   : constant Binary_Op := G.Op;
      C     : constant Natural := G.Cursor;
      Idx_K : constant Lag_Index := Lag_Index (C + 1);
      --  X_{n-J} sits at (C + K − J) mod K (0-based).
      Idx_J0 : constant Natural :=
        (C + Natural (Kv) - Natural (Jv)) rem Natural (Kv);
      Idx_J  : constant Lag_Index := Lag_Index (Idx_J0 + 1);
      Xj, Xk, Xn : Value;
   begin
      Xk := G.Buffer (Idx_K);
      Xj := G.Buffer (Idx_J);
      Xn := Combine (Xj, Xk, Opv, Mv);
      G.Buffer (Idx_K) := Xn;
      G.Cursor := (C + 1) rem Natural (Kv);
      Result := Xn;
   end Next;

end Lagged_Fibonacci_Generator;
