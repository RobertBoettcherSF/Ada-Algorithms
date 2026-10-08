--  Acorn_Generator body — order-k additive sweep, LCG seed fill,
--  overflow-safe modular add. SPARK Level 4: bounded loops, no heap,
--  no exceptions, modulus capped so arithmetic stays wrap-free.

package body Acorn_Generator
  with SPARK_Mode => On
is

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
      return M >= 2 and then M <= Max_Modulus;
   end Is_Valid_Modulus;

   function Seeds_In_Range
     (Order : Order_Type;
      M     : Modulus_Type;
      Seeds : State_Array) return Boolean
   is
   begin
      for I in 0 .. Natural (Order) loop
         pragma Loop_Invariant
           (for all K in 0 .. I - 1 => Seeds (K) < M);
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
     (Buf  : out State_Array;
      K    : Order_Type;
      M    : Modulus_Type;
      Seed : Value)
     with
       Global => null,
       Pre    => Seed < M,
       Post   => (for all I in 0 .. Natural (K) => Buf (I) < M)
                 and then
                   (for all I in Natural (K) + 1 .. Max_Order =>
                      Buf (I) = 0);

   procedure Fill_From_Seed
     (Buf  : out State_Array;
      K    : Order_Type;
      M    : Modulus_Type;
      Seed : Value)
   is
      X : Value := Seed;
   begin
      Buf := [others => 0];
      for I in 0 .. Natural (K) loop
         pragma Loop_Invariant (X < M);
         pragma Loop_Invariant
           (for all J in 0 .. I - 1 => Buf (J) < M);
         pragma Loop_Invariant
           (for all J in I .. Max_Order => Buf (J) = 0);
         X := LCG_Step (X, M);
         Buf (I) := X;
      end loop;

      if M rem 2 = 0 and then Buf (0) rem 2 = 0 then
         if Buf (0) < M - 1 then
            Buf (0) := Buf (0) + 1;
         else
            Buf (0) := 1;
         end if;
      end if;
   end Fill_From_Seed;

   procedure Install_Seeds
     (Buf   : out State_Array;
      K     : Order_Type;
      M     : Modulus_Type;
      Seeds : State_Array)
     with
       Global => null,
       Pre    => Seeds_In_Range (K, M, Seeds),
       Post   => (for all I in 0 .. Natural (K) => Buf (I) = Seeds (I))
                 and then
                   (for all I in Natural (K) + 1 .. Max_Order =>
                      Buf (I) = 0)
                 and then
                   (for all I in 0 .. Natural (K) => Buf (I) < M);

   procedure Install_Seeds
     (Buf   : out State_Array;
      K     : Order_Type;
      M     : Modulus_Type;
      Seeds : State_Array)
   is
   begin
      Buf := [others => 0];
      for I in 0 .. Natural (K) loop
         pragma Loop_Invariant
           (for all J in 0 .. I - 1 => Buf (J) = Seeds (J));
         pragma Loop_Invariant
           (for all J in 0 .. I - 1 => Buf (J) < M);
         pragma Loop_Invariant
           (for all J in I .. Max_Order => Buf (J) = 0);
         pragma Assert (Seeds (I) < M);
         Buf (I) := Seeds (I);
      end loop;
   end Install_Seeds;

   function Build
     (K   : Order_Type;
      M   : Modulus_Type;
      Buf : State_Array) return Generator
     with
       Global => null,
       Pre    => (for all I in 0 .. Natural (K) => Buf (I) < M),
       Post   => Build'Result.Initialised
                 and then Build'Result.Order = Natural (K)
                 and then Build'Result.M = M
                 and then
                   (for all I in 0 .. Natural (K) =>
                      Build'Result.Y (I) = Buf (I));

   function Build
     (K   : Order_Type;
      M   : Modulus_Type;
      Buf : State_Array) return Generator
   is
   begin
      return
        (Order       => Natural (K),
         M           => M,
         Y           => Buf,
         Initialised => True);
   end Build;

   ---------------------------------------------------------------------------
   -- Create / Reset
   ---------------------------------------------------------------------------

   function Create
     (Order : Order_Type;
      M     : Modulus_Type;
      Seeds : State_Array) return Generator
   is
      Buf : State_Array;
   begin
      Install_Seeds (Buf, Order, M, Seeds);
      return Build (Order, M, Buf);
   end Create;

   function Create
     (Order : Order_Type;
      M     : Modulus_Type;
      Seed  : Value) return Generator
   is
      Buf : State_Array;
   begin
      Fill_From_Seed (Buf, Order, M, Seed);
      return Build (Order, M, Buf);
   end Create;

   procedure Reset (G : in out Generator; Seeds : State_Array) is
      Buf : State_Array;
      K   : constant Order_Type := Order_Of (G);
      Mv  : constant Modulus_Type := Modulus_Of (G);
   begin
      Install_Seeds (Buf, K, Mv, Seeds);
      G.Y := Buf;
   end Reset;

   procedure Reset (G : in out Generator; Seed : Value) is
      Buf : State_Array;
      K   : constant Order_Type := Order_Of (G);
      Mv  : constant Modulus_Type := Modulus_Of (G);
   begin
      Fill_From_Seed (Buf, K, Mv, Seed);
      G.Y := Buf;
   end Reset;

   ---------------------------------------------------------------------------
   -- Next
   ---------------------------------------------------------------------------

   procedure Next (G : in out Generator; Result : out Value) is
      K  : constant Natural := G.Order;
      Mv : constant Modulus_Type := Modulus_Of (G);
      Y0 : constant Value := G.Y (0);
   begin
      for I in 1 .. K loop
         pragma Loop_Invariant (G.Initialised);
         pragma Loop_Invariant (G.Order = K);
         pragma Loop_Invariant (G.M = Value (Mv));
         pragma Loop_Invariant (G.Y (0) = Y0);
         pragma Loop_Invariant
           (for all J in 0 .. K => G.Y (J) < Mv);
         G.Y (I) := Add_Mod (G.Y (I), G.Y (I - 1), Mv);
      end loop;
      Result := G.Y (K);
   end Next;

   ---------------------------------------------------------------------------
   -- Copy_State
   ---------------------------------------------------------------------------

   procedure Copy_State (G : Generator; Buf : out State_Array) is
      K : constant Natural := G.Order;
   begin
      Buf := [others => 0];
      for I in 0 .. K loop
         pragma Loop_Invariant
           (for all J in 0 .. I - 1 => Buf (J) = G.Y (J));
         pragma Loop_Invariant
           (for all J in I .. Max_Order => Buf (J) = 0);
         Buf (I) := G.Y (I);
      end loop;
   end Copy_State;

end Acorn_Generator;
