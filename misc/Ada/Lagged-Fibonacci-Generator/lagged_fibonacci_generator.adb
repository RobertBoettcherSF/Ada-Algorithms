--  Lagged_Fibonacci_Generator body — ring-buffer LFG, LCG seed fill,
--  modular Add / Subtract / Bitwise_Xor helpers.

pragma Ada_2022;

with Interfaces;

package body Lagged_Fibonacci_Generator
  with SPARK_Mode => Off
is

   --  Numerical Recipes LCG parameters for seed-array fill.
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
      return Is_Valid_Lags (Positive (Lags.J), Positive (Lags.K));
   end Is_Valid_Lags;

   function Is_Valid_Modulus (M : Value) return Boolean is
   begin
      return M >= 2;
   end Is_Valid_Modulus;

   procedure Require_Lags (J, K : Lag_Index) is
   begin
      if not Is_Valid_Lags (Positive (J), Positive (K)) then
         raise Invalid_Argument;
      end if;
   end Require_Lags;

   procedure Require_Modulus (M : Value) is
   begin
      if not Is_Valid_Modulus (M) then
         raise Invalid_Argument;
      end if;
   end Require_Modulus;

   procedure Require_Initialised (G : Generator) is
   begin
      if not G.Initialised then
         raise Invalid_Argument;
      end if;
   end Require_Initialised;

   ---------------------------------------------------------------------------
   -- Overflow-safe modular arithmetic
   ---------------------------------------------------------------------------

   function Add_Mod (X, Y, M : Value) return Value is
      use Interfaces;
      XX, YY, MM, Sum : Unsigned_128;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return 0;
      end if;
      XX  := Unsigned_128 (X rem M);
      YY  := Unsigned_128 (Y rem M);
      MM  := Unsigned_128 (M);
      Sum := XX + YY;
      return Value (Unsigned_64 (Sum rem MM));
   end Add_Mod;

   function Sub_Mod (X, Y, M : Value) return Value is
      XX, YY : Value;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return 0;
      end if;
      XX := X rem M;
      YY := Y rem M;
      if XX >= YY then
         return XX - YY;
      else
         return M - (YY - XX);
      end if;
   end Sub_Mod;

   function Xor_Mod (X, Y, M : Value) return Value is
      use Interfaces;
      Z : Unsigned_64;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return 0;
      end if;
      Z := Unsigned_64 (X rem M) xor Unsigned_64 (Y rem M);
      return Value (Z) rem M;
   end Xor_Mod;

   function Combine (X, Y : Value; Op : Binary_Op; M : Value) return Value is
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

   function LCG_Step (State, M : Value) return Value is
      use Interfaces;
      Wide : Unsigned_128;
   begin
      Wide :=
        Unsigned_128 (LCG_A) * Unsigned_128 (State) + Unsigned_128 (LCG_C);
      return Value (Unsigned_64 (Wide rem Unsigned_128 (M)));
   end LCG_Step;

   procedure Fill_From_Seed
     (Buf  : out Buffer_Array;
      K    : Lag_Index;
      M    : Value;
      Seed : Value;
      Op   : Binary_Op)
   is
      X       : Value := Seed rem M;
      Has_Odd : Boolean := False;
   begin
      for I in 1 .. K loop
         X := LCG_Step (X, M);
         Buf (I) := X;
         if X rem 2 = 1 then
            Has_Odd := True;
         end if;
      end loop;
      --  Additive / subtractive LFGs need at least one odd seed word.
      if Op /= Bitwise_Xor and then not Has_Odd then
         if Buf (1) + 1 < M then
            Buf (1) := Buf (1) + 1;
         else
            Buf (1) := 1;
         end if;
      end if;
   end Fill_From_Seed;

   procedure Install_Seeds
     (Buf   : out Buffer_Array;
      K     : Lag_Index;
      M     : Value;
      Seeds : Seed_Array)
   is
   begin
      if Seeds'Length /= Natural (K) then
         raise Invalid_Argument;
      end if;
      for Offset in 0 .. Natural (K) - 1 loop
         declare
            S : constant Value := Seeds (Seeds'First + Offset);
         begin
            if S >= M then
               raise Invalid_Argument;
            end if;
            Buf (Lag_Index (Offset + 1)) := S;
         end;
      end loop;
   end Install_Seeds;

   function Build
     (J   : Lag_Index;
      K   : Lag_Index;
      Op  : Binary_Op;
      M   : Value;
      Buf : Buffer_Array) return Generator
   is
      G : Generator;
   begin
      G.J           := J;
      G.K           := K;
      G.Op          := Op;
      G.M           := M;
      G.Buffer      := Buf;
      G.Cursor      := 0;
      G.Initialised := True;
      return G;
   end Build;

   ---------------------------------------------------------------------------
   -- Create
   ---------------------------------------------------------------------------

   function Create
     (J     : Lag_Index;
      K     : Lag_Index;
      Op    : Binary_Op;
      M     : Value;
      Seeds : Seed_Array) return Generator
   is
      Buf : Buffer_Array := [others => 0];
   begin
      Require_Lags (J, K);
      Require_Modulus (M);
      Install_Seeds (Buf, K, M, Seeds);
      return Build (J, K, Op, M, Buf);
   end Create;

   function Create
     (J    : Lag_Index;
      K    : Lag_Index;
      Op   : Binary_Op;
      M    : Value;
      Seed : Value) return Generator
   is
      Buf : Buffer_Array := [others => 0];
   begin
      Require_Lags (J, K);
      Require_Modulus (M);
      if Seed >= M then
         raise Invalid_Argument;
      end if;
      Fill_From_Seed (Buf, K, M, Seed, Op);
      return Build (J, K, Op, M, Buf);
   end Create;

   function Create
     (Lags  : Lag_Pair;
      Op    : Binary_Op;
      M     : Value;
      Seeds : Seed_Array) return Generator
   is
   begin
      return Create (Lags.J, Lags.K, Op, M, Seeds);
   end Create;

   function Create
     (Lags : Lag_Pair;
      Op   : Binary_Op;
      M    : Value;
      Seed : Value) return Generator
   is
   begin
      return Create (Lags.J, Lags.K, Op, M, Seed);
   end Create;

   ---------------------------------------------------------------------------
   -- Reset
   ---------------------------------------------------------------------------

   procedure Reset (G : in out Generator; Seeds : Seed_Array) is
      Buf : Buffer_Array := [others => 0];
   begin
      Require_Initialised (G);
      Install_Seeds (Buf, G.K, G.M, Seeds);
      G.Buffer := Buf;
      G.Cursor := 0;
   end Reset;

   procedure Reset (G : in out Generator; Seed : Value) is
      Buf : Buffer_Array := [others => 0];
   begin
      Require_Initialised (G);
      if Seed >= G.M then
         raise Invalid_Argument;
      end if;
      Fill_From_Seed (Buf, G.K, G.M, Seed, G.Op);
      G.Buffer := Buf;
      G.Cursor := 0;
   end Reset;

   ---------------------------------------------------------------------------
   -- Next / Next_Float
   ---------------------------------------------------------------------------

   function Next (G : in out Generator) return Value is
      --  Cursor C (0-based) holds X_{n-K}.  X_{n-J} is at
      --  (C + K − J) mod K.  Buffer is 1-based.
      Idx_K : Lag_Index;
      Idx_J : Natural;
      Xj, Xk, Xn : Value;
   begin
      Require_Initialised (G);
      Idx_K := Lag_Index (G.Cursor + 1);
      Idx_J := (G.Cursor + Natural (G.K) - Natural (G.J))
        mod Natural (G.K);
      Xk := G.Buffer (Idx_K);
      Xj := G.Buffer (Lag_Index (Idx_J + 1));
      Xn := Combine (Xj, Xk, G.Op, G.M);
      G.Buffer (Idx_K) := Xn;
      G.Cursor := (G.Cursor + 1) mod Natural (G.K);
      return Xn;
   end Next;

   function Next_Float (G : in out Generator) return Long_Float is
      X : constant Value := Next (G);
   begin
      return Long_Float (X) / Long_Float (G.M);
   end Next_Float;

   ---------------------------------------------------------------------------
   -- Inspectors
   ---------------------------------------------------------------------------

   function Get_J (G : Generator) return Lag_Index is
   begin
      Require_Initialised (G);
      return G.J;
   end Get_J;

   function Get_K (G : Generator) return Lag_Index is
   begin
      Require_Initialised (G);
      return G.K;
   end Get_K;

   function Get_Op (G : Generator) return Binary_Op is
   begin
      Require_Initialised (G);
      return G.Op;
   end Get_Op;

   function Get_Modulus (G : Generator) return Value is
   begin
      Require_Initialised (G);
      return G.M;
   end Get_Modulus;

   function Get_Cursor (G : Generator) return Natural is
   begin
      Require_Initialised (G);
      return G.Cursor;
   end Get_Cursor;

   function Get_Buffer_Word
     (G : Generator; Index : Lag_Index) return Value
   is
   begin
      Require_Initialised (G);
      if Index > G.K then
         raise Invalid_Argument;
      end if;
      return G.Buffer (Index);
   end Get_Buffer_Word;

   function Is_Initialised (G : Generator) return Boolean is
   begin
      return G.Initialised;
   end Is_Initialised;

end Lagged_Fibonacci_Generator;
