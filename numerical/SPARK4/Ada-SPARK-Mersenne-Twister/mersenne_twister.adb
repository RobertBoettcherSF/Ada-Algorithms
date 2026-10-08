--  Mersenne_Twister body — MT19937 init fill, three-loop Twist (no mod),
--  Temper, Next. SPARK Level 4: bounded for-loops, no heap, no exceptions.
--  Twist follows the reference C split (0 .. N−M−1), (N−M .. N−2), N−1
--  so every index is a static offset — easier for GNATprove than I mod N.

package body Mersenne_Twister
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Temper
   ---------------------------------------------------------------------------

   function Temper (Y : Unsigned_32) return Unsigned_32 is
      T : Unsigned_32 := Y;
   begin
      T := T xor Shift_Right (T, 11);
      T := T xor (Shift_Left (T, 7) and Temper_B);
      T := T xor (Shift_Left (T, 15) and Temper_C);
      T := T xor Shift_Right (T, 18);
      return T;
   end Temper;

   ---------------------------------------------------------------------------
   -- Seed fill (Knuth multiplier f = 1812433253)
   ---------------------------------------------------------------------------

   procedure Fill_State (MT : out MT_Array; Seed : Unsigned_32)
     with
       Global => null,
       Post   => MT (0) = Seed;

   procedure Fill_State (MT : out MT_Array; Seed : Unsigned_32) is
   begin
      MT := [others => 0];
      MT (0) := Seed;
      for I in 1 .. MT_Index'(N - 1) loop
         pragma Loop_Invariant (MT (0) = Seed);
         pragma Loop_Invariant
           (for all J in I .. MT_Index'(N - 1) => MT (J) = 0);
         --  MT[i] := f * (MT[i−1] xor (MT[i−1] >> 30)) + i  (mod 2**32)
         MT (I) :=
           Init_F
             * (MT (I - 1) xor Shift_Right (MT (I - 1), 30))
             + Unsigned_32 (I);
      end loop;
   end Fill_State;

   ---------------------------------------------------------------------------
   -- Twist — three loops matching mt19937ar.c (avoids I mod N)
   ---------------------------------------------------------------------------

   procedure Twist (G : in out Generator)
     with
       Global  => null,
       Depends => (G => G),
       Pre     => Is_Initialised (G),
       Post    => Is_Initialised (G)
                  and then Get_Index (G) = 0
                  and then Get_Seed (G) = Get_Seed (G'Old);

   procedure Twist (G : in out Generator) is
      Y : Unsigned_32;
   begin
      --  First segment: I ∈ 0 .. N−M−1  (0 .. 226)
      --    next = I+1 ∈ 1 .. 227;  far = I+M ∈ 397 .. 623
      for I in 0 .. N - M - 1 loop
         pragma Loop_Invariant (G.Initialised);
         pragma Loop_Invariant (G.Seed = G.Seed'Loop_Entry);
         Y := (G.MT (I) and Upper_Mask)
           or (G.MT (I + 1) and Lower_Mask);
         G.MT (I) :=
           G.MT (I + M)
             xor Shift_Right (Y, 1)
             xor (if (Y and 1) = 0 then 0 else Matrix_A);
      end loop;

      --  Second segment: I ∈ N−M .. N−2  (227 .. 622)
      --    next = I+1 ∈ 228 .. 623;  far = I+(M−N) = I−227 ∈ 0 .. 395
      for I in N - M .. N - 2 loop
         pragma Loop_Invariant (G.Initialised);
         pragma Loop_Invariant (G.Seed = G.Seed'Loop_Entry);
         Y := (G.MT (I) and Upper_Mask)
           or (G.MT (I + 1) and Lower_Mask);
         G.MT (I) :=
           G.MT (I - (N - M))
             xor Shift_Right (Y, 1)
             xor (if (Y and 1) = 0 then 0 else Matrix_A);
      end loop;

      --  Wrap: last word uses MT(0) as “next” and MT(M−1) as “far”
      Y := (G.MT (N - 1) and Upper_Mask)
        or (G.MT (0) and Lower_Mask);
      G.MT (N - 1) :=
        G.MT (M - 1)
          xor Shift_Right (Y, 1)
          xor (if (Y and 1) = 0 then 0 else Matrix_A);

      G.Index := 0;
   end Twist;

   ---------------------------------------------------------------------------
   -- Create / Init / Reset
   ---------------------------------------------------------------------------

   function Create (Seed : Unsigned_32) return Generator is
      G : Generator;
   begin
      Fill_State (G.MT, Seed);
      G.Index := N;
      G.Seed := Seed;
      G.Initialised := True;
      return G;
   end Create;

   procedure Init (G : out Generator; Seed : Unsigned_32) is
   begin
      Fill_State (G.MT, Seed);
      G.Index := N;
      G.Seed := Seed;
      G.Initialised := True;
   end Init;

   procedure Reset (G : in out Generator; Seed : Unsigned_32) is
   begin
      Fill_State (G.MT, Seed);
      G.Index := N;
      G.Seed := Seed;
      --  Initialised stays True (Pre)
   end Reset;

   ---------------------------------------------------------------------------
   -- Next
   ---------------------------------------------------------------------------

   procedure Next (G : in out Generator; Result : out Unsigned_32) is
      Idx : MT_Index;
      Y   : Unsigned_32;
   begin
      if G.Index = N then
         Twist (G);
      end if;
      --  After Twist, Index = 0; otherwise Index ∈ 0 .. N−1
      pragma Assert (G.Index < N);
      Idx := G.Index;
      Y := Temper (G.MT (Idx));
      G.Index := Idx + 1;
      Result := Y;
   end Next;

end Mersenne_Twister;
