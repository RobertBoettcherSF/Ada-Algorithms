--  Pseudorandom_Number_Generator body — LCG, small additive LFG,
--  xorshift64, overflow-safe modular helpers, unified Kind dispatcher.

pragma Ada_2022;

with Interfaces;

package body Pseudorandom_Number_Generator
  with SPARK_Mode => Off
is

   --  Internal LCG for filling the LFG seed buffer (Numerical Recipes).
   Fill_A : constant Value := 1_664_525;
   Fill_C : constant Value := 1_013_904_223;
   Fill_M : constant Value := 2 ** 32;

   ---------------------------------------------------------------------------
   -- Modular arithmetic
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

   function Mul_Mod (X, Y, M : Value) return Value is
      use Interfaces;
      XX, YY, MM, Prod : Unsigned_128;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return 0;
      end if;
      XX   := Unsigned_128 (X rem M);
      YY   := Unsigned_128 (Y rem M);
      MM   := Unsigned_128 (M);
      Prod := XX * YY;
      return Value (Unsigned_64 (Prod rem MM));
   end Mul_Mod;

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

   function Congruential (State, A, C, M : Value) return Value is
      use Interfaces;
      Wide : Unsigned_128;
   begin
      Wide :=
        Unsigned_128 (A) * Unsigned_128 (State) + Unsigned_128 (C);
      return Value (Unsigned_64 (Wide rem Unsigned_128 (M)));
   end Congruential;

   ---------------------------------------------------------------------------
   -- LCG validation / step
   ---------------------------------------------------------------------------

   function Is_Valid_LCG_Parameters (Params : LCG_Parameters) return Boolean is
   begin
      if Params.M < 2 then
         return False;
      end if;
      return Params.A rem Params.M /= 0;
   end Is_Valid_LCG_Parameters;

   function Reduce_LCG (Params : LCG_Parameters) return LCG_Parameters is
      R : LCG_Parameters;
   begin
      if Params.M = 0 then
         raise Invalid_Argument;
      end if;
      R.M := Params.M;
      R.A := Params.A rem Params.M;
      R.C := Params.C rem Params.M;
      return R;
   end Reduce_LCG;

   procedure Require_Valid_LCG (Params : LCG_Parameters) is
   begin
      if not Is_Valid_LCG_Parameters (Params) then
         raise Invalid_Argument;
      end if;
   end Require_Valid_LCG;

   function LCG_Step (State : Value; Params : LCG_Parameters) return Value is
      R : constant LCG_Parameters := Reduce_LCG (Params);
   begin
      Require_Valid_LCG (Params);
      if State >= R.M then
         raise Invalid_Argument;
      end if;
      return Congruential (State, R.A, R.C, R.M);
   end LCG_Step;

   ---------------------------------------------------------------------------
   -- Xorshift step
   ---------------------------------------------------------------------------

   function Xorshift_Step (State : Value) return Value is
      use Interfaces;
      X : Unsigned_64;
   begin
      if State = 0 then
         raise Invalid_Argument;
      end if;
      X := Unsigned_64 (State);
      X := X xor Shift_Left (X, XS_A);
      X := X xor Shift_Right (X, XS_B);
      X := X xor Shift_Left (X, XS_C);
      return Value (X);
   end Xorshift_Step;

   ---------------------------------------------------------------------------
   -- Require initialised
   ---------------------------------------------------------------------------

   procedure Require_Initialised (G : Generator) is
   begin
      if not G.Initialised then
         raise Invalid_Argument;
      end if;
   end Require_Initialised;

   ---------------------------------------------------------------------------
   -- LFG seed fill (internal Numerical Recipes LCG into buffer)
   ---------------------------------------------------------------------------

   procedure Fill_LFG_Buffer
     (Buf  : out LFG_Buffer;
      Seed : Value)
   is
      S : Value := Seed rem Fill_M;
   begin
      --  Ensure at least one odd word so an all-even additive LFG on a
      --  power-of-two modulus cannot collapse to the zero subsequence.
      for I in Buf'Range loop
         S := Congruential (S, Fill_A, Fill_C, Fill_M);
         Buf (I) := S;
      end loop;
      if (Buf (1) rem 2) = 0 then
         Buf (1) := Buf (1) + 1;
      end if;
   end Fill_LFG_Buffer;

   ---------------------------------------------------------------------------
   -- Create helpers
   ---------------------------------------------------------------------------

   function Make_LCG
     (Seed : Value; Params : LCG_Parameters) return Generator
   is
      R : constant LCG_Parameters := Reduce_LCG (Params);
      G : Generator;
   begin
      Require_Valid_LCG (Params);
      if Seed >= R.M then
         raise Invalid_Argument;
      end if;
      G.Initialised := True;
      G.Engine      := LCG;
      G.Seed        := Seed;
      G.LCG_A       := R.A;
      G.LCG_C       := R.C;
      G.LCG_M       := R.M;
      G.LCG_State   := Seed;
      return G;
   end Make_LCG;

   function Make_LFG (Seed : Value) return Generator is
      G : Generator;
   begin
      G.Initialised := True;
      G.Engine      := Lagged_Fibonacci;
      G.Seed        := Seed;
      Fill_LFG_Buffer (G.LFG_Buf, Seed);
      G.LFG_Idx := 0;
      return G;
   end Make_LFG;

   function Make_Xorshift (Seed : Value) return Generator is
      G : Generator;
   begin
      if Seed = 0 then
         raise Invalid_Argument;
      end if;
      G.Initialised := True;
      G.Engine      := Xorshift;
      G.Seed        := Seed;
      G.XS_State    := Seed;
      return G;
   end Make_Xorshift;

   function Create
     (Engine : Kind;
      Seed   : Value;
      Params : LCG_Parameters := Default_LCG) return Generator
   is
   begin
      case Engine is
         when LCG =>
            return Make_LCG (Seed, Params);
         when Lagged_Fibonacci =>
            return Make_LFG (Seed);
         when Xorshift =>
            return Make_Xorshift (Seed);
      end case;
   end Create;

   function Create_LCG
     (Seed   : Value;
      Params : LCG_Parameters := Default_LCG) return Generator
   is
   begin
      return Make_LCG (Seed, Params);
   end Create_LCG;

   function Create_Lagged_Fibonacci (Seed : Value) return Generator is
   begin
      return Make_LFG (Seed);
   end Create_Lagged_Fibonacci;

   function Create_Xorshift (Seed : Value) return Generator is
   begin
      return Make_Xorshift (Seed);
   end Create_Xorshift;

   ---------------------------------------------------------------------------
   -- Reset
   ---------------------------------------------------------------------------

   procedure Reset (G : in out Generator; Seed : Value) is
      P : LCG_Parameters;
   begin
      Require_Initialised (G);
      case G.Engine is
         when LCG =>
            P := (A => G.LCG_A, C => G.LCG_C, M => G.LCG_M);
            G := Make_LCG (Seed, P);
         when Lagged_Fibonacci =>
            G := Make_LFG (Seed);
         when Xorshift =>
            G := Make_Xorshift (Seed);
      end case;
   end Reset;

   ---------------------------------------------------------------------------
   -- Next / Next_Float
   ---------------------------------------------------------------------------

   function Next_LCG (G : in out Generator) return Value is
   begin
      G.LCG_State :=
        Congruential (G.LCG_State, G.LCG_A, G.LCG_C, G.LCG_M);
      return G.LCG_State;
   end Next_LCG;

   function Next_LFG (G : in out Generator) return Value is
      --  Ring indices: write at LFG_Idx (0-based). Sample
      --  Buf[idx - J] and Buf[idx - K] (mod K), write sum, advance.
      Idx : constant Natural := G.LFG_Idx;
      --  Convert 0-based lag distance to 1-based buffer index.
      function Buf_At (Lag : Positive) return Value is
         Pos : constant Natural :=
           (Idx + LFG_K - Lag) rem LFG_K;
      begin
         return G.LFG_Buf (Pos + 1);
      end Buf_At;
      X : Value;
   begin
      X := Add_Mod (Buf_At (LFG_J), Buf_At (LFG_K), LFG_Modulus);
      G.LFG_Buf (Idx + 1) := X;
      G.LFG_Idx := (Idx + 1) rem LFG_K;
      return X;
   end Next_LFG;

   function Next_Xorshift (G : in out Generator) return Value is
   begin
      G.XS_State := Xorshift_Step (G.XS_State);
      return G.XS_State;
   end Next_Xorshift;

   function Next (G : in out Generator) return Value is
   begin
      Require_Initialised (G);
      case G.Engine is
         when LCG =>
            return Next_LCG (G);
         when Lagged_Fibonacci =>
            return Next_LFG (G);
         when Xorshift =>
            return Next_Xorshift (G);
      end case;
   end Next;

   function Scale_To_Unit (X, M : Value) return Long_Float is
   begin
      --  M ≥ 2 for LCG/LFG; for xorshift M is notionally 2^64.
      if M = 0 then
         --  Interpret as modulus 2^64: X / 2^64.
         return Long_Float (X) / (2.0 ** 64);
      end if;
      return Long_Float (X) / Long_Float (M);
   end Scale_To_Unit;

   function Next_Float (G : in out Generator) return Long_Float is
      X : Value;
   begin
      Require_Initialised (G);
      X := Next (G);
      case G.Engine is
         when LCG =>
            return Scale_To_Unit (X, G.LCG_M);
         when Lagged_Fibonacci =>
            return Scale_To_Unit (X, LFG_Modulus);
         when Xorshift =>
            return Scale_To_Unit (X, 0);  -- / 2^64
      end case;
   end Next_Float;

   ---------------------------------------------------------------------------
   -- Inspectors
   ---------------------------------------------------------------------------

   function Is_Initialised (G : Generator) return Boolean is
   begin
      return G.Initialised;
   end Is_Initialised;

   function Get_Kind (G : Generator) return Kind is
   begin
      Require_Initialised (G);
      return G.Engine;
   end Get_Kind;

   function Get_Seed (G : Generator) return Value is
   begin
      Require_Initialised (G);
      return G.Seed;
   end Get_Seed;

   function Get_State (G : Generator) return Value is
   begin
      Require_Initialised (G);
      case G.Engine is
         when LCG =>
            return G.LCG_State;
         when Lagged_Fibonacci =>
            --  Most recently written word: previous index.
            declare
               Prev : constant Natural :=
                 (G.LFG_Idx + LFG_K - 1) rem LFG_K;
            begin
               return G.LFG_Buf (Prev + 1);
            end;
         when Xorshift =>
            return G.XS_State;
      end case;
   end Get_State;

   function Get_LCG_Parameters (G : Generator) return LCG_Parameters is
   begin
      Require_Initialised (G);
      if G.Engine /= LCG then
         raise Invalid_Argument;
      end if;
      return (A => G.LCG_A, C => G.LCG_C, M => G.LCG_M);
   end Get_LCG_Parameters;

end Pseudorandom_Number_Generator;
