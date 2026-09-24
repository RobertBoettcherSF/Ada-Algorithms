--  Acorn_Generator body — order-k additive sweep, LCG seed fill,
--  overflow-safe modular add.

pragma Ada_2022;

with Interfaces;

package body Acorn_Generator
  with SPARK_Mode => Off
is

   --  Numerical Recipes LCG parameters for single-seed fill.
   LCG_A : constant Value := 1_664_525;
   LCG_C : constant Value := 1_013_904_223;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Is_Valid_Order (K : Positive) return Boolean is
   begin
      return K <= Max_Order;
   end Is_Valid_Order;

   function Is_Valid_Modulus (M : Value) return Boolean is
   begin
      return M >= 2;
   end Is_Valid_Modulus;

   procedure Require_Order (K : Positive) is
   begin
      if not Is_Valid_Order (K) then
         raise Invalid_Argument;
      end if;
   end Require_Order;

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
      K    : Order_Type;
      M    : Value;
      Seed : Value)
   is
      X : Value := Seed rem M;
   begin
      Buf := [others => 0];
      for I in 0 .. Natural (K) loop
         X := LCG_Step (X, M);
         Buf (I) := X;
      end loop;
      --  Literature preference: keep Y[0] odd when M is even so the
      --  state is not trapped in the all-even invariant subspace.
      if M rem 2 = 0 and then Buf (0) rem 2 = 0 then
         if Buf (0) + 1 < M then
            Buf (0) := Buf (0) + 1;
         else
            Buf (0) := 1;
         end if;
      end if;
   end Fill_From_Seed;

   procedure Install_Seeds
     (Buf   : out Buffer_Array;
      K     : Order_Type;
      M     : Value;
      Seeds : State_Array)
   is
      Need : constant Natural := Natural (K) + 1;
   begin
      if Seeds'Length /= Need then
         raise Invalid_Argument;
      end if;
      Buf := [others => 0];
      for Offset in 0 .. Need - 1 loop
         declare
            S : constant Value := Seeds (Seeds'First + Offset);
         begin
            if S >= M then
               raise Invalid_Argument;
            end if;
            Buf (Offset) := S;
         end;
      end loop;
   end Install_Seeds;

   function Build
     (K   : Order_Type;
      M   : Value;
      Buf : Buffer_Array) return Generator
   is
      G : Generator;
   begin
      G.Order       := Natural (K);
      G.M           := M;
      G.Y           := Buf;
      G.Initialised := True;
      return G;
   end Build;

   ---------------------------------------------------------------------------
   -- Create / Reset
   ---------------------------------------------------------------------------

   function Create
     (Order  : Order_Type;
      M      : Value;
      Seeds  : State_Array) return Generator
   is
      Buf : Buffer_Array;
   begin
      Require_Order (Positive (Order));
      Require_Modulus (M);
      Install_Seeds (Buf, Order, M, Seeds);
      return Build (Order, M, Buf);
   end Create;

   function Create
     (Order : Order_Type;
      M     : Value;
      Seed  : Value) return Generator
   is
      Buf : Buffer_Array;
   begin
      Require_Order (Positive (Order));
      Require_Modulus (M);
      if Seed >= M then
         raise Invalid_Argument;
      end if;
      Fill_From_Seed (Buf, Order, M, Seed);
      return Build (Order, M, Buf);
   end Create;

   procedure Reset (G : in out Generator; Seeds : State_Array) is
      Buf : Buffer_Array;
      K   : Order_Type;
   begin
      Require_Initialised (G);
      K := Order_Type (G.Order);
      Install_Seeds (Buf, K, G.M, Seeds);
      G.Y := Buf;
   end Reset;

   procedure Reset (G : in out Generator; Seed : Value) is
      Buf : Buffer_Array;
      K   : Order_Type;
   begin
      Require_Initialised (G);
      if Seed >= G.M then
         raise Invalid_Argument;
      end if;
      K := Order_Type (G.Order);
      Fill_From_Seed (Buf, K, G.M, Seed);
      G.Y := Buf;
   end Reset;

   ---------------------------------------------------------------------------
   -- Next / Next_Float
   ---------------------------------------------------------------------------

   function To_Long_Float (X : Value) return Long_Float is
      use Interfaces;
      U : constant Unsigned_64 := Unsigned_64 (X);
   begin
      if U <= 16#7FFF_FFFF_FFFF_FFFF# then
         return Long_Float (Long_Long_Integer (U));
      end if;
      return Long_Float (Long_Long_Integer (U - 16#8000_0000_0000_0000#))
        + 2.0 ** 63;
   end To_Long_Float;

   function Next (G : in out Generator) return Value is
      K : Natural;
   begin
      Require_Initialised (G);
      K := G.Order;
      --  In-place additive sweep: Y[0] is the fixed seed stream;
      --  for i = 1 .. k, Y[i] ← (Y[i] + Y[i−1]) mod M.
      for I in 1 .. K loop
         G.Y (I) := Add_Mod (G.Y (I), G.Y (I - 1), G.M);
      end loop;
      return G.Y (K);
   end Next;

   function Next_Float (G : in out Generator) return Long_Float is
      X : Value;
   begin
      X := Next (G);
      return To_Long_Float (X) / To_Long_Float (G.M);
   end Next_Float;

   ---------------------------------------------------------------------------
   -- Inspectors
   ---------------------------------------------------------------------------

   function Order_Of (G : Generator) return Order_Type is
   begin
      Require_Initialised (G);
      return Order_Type (G.Order);
   end Order_Of;

   function Modulus_Of (G : Generator) return Value is
   begin
      Require_Initialised (G);
      return G.M;
   end Modulus_Of;

   function Get_State (G : Generator) return State_Array is
      Result : State_Array (0 .. G.Order);
   begin
      Require_Initialised (G);
      for I in 0 .. G.Order loop
         Result (I) := G.Y (I);
      end loop;
      return Result;
   end Get_State;

   function Get_Y (G : Generator; Index : Natural) return Value is
   begin
      Require_Initialised (G);
      if Index > G.Order then
         raise Invalid_Argument;
      end if;
      return G.Y (Index);
   end Get_Y;

   function Is_Initialised (G : Generator) return Boolean is
   begin
      return G.Initialised;
   end Is_Initialised;

end Acorn_Generator;
