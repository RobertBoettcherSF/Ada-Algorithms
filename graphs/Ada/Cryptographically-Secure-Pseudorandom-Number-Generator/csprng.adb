package body Csprng is

   use type Interfaces.Unsigned_32;

   -- Helper: Rotate Left for 32-bit words
   function Rol (Value : Word; Amount : Natural) return Word is
   begin
      return Word (Interfaces.Rotate_Left (Interfaces.Unsigned_32 (Value), Amount));
   end Rol;


   -- =========================================================================
   -- BBS Implementation
   -- =========================================================================

   function Bbs_Initialize (P, Q : Word; Seed : Long_Word) return Bbs_State is
      State : Bbs_State;
   begin
      -- Edge case: validate prime congruences and distinctness
      if P = Q then
         raise Invalid_Prime_Exception with "P and Q must be distinct";
      end if;

      if P mod 4 /= 3 or else Q mod 4 /= 3 then
         raise Invalid_Prime_Exception with "P and Q must be congruent to 3 mod 4";
      end if;

      State.M := Long_Word (P) * Long_Word (Q);

      -- Edge case: validate seed against M, P, and Q to ensure it is coprime
      if Seed = 0 or else Seed mod Long_Word (P) = 0 or else Seed mod Long_Word (Q) = 0 then
         raise Invalid_Seed_Exception with "Seed must be coprime to M and non-zero";
      end if;

      -- Initial state X_0 = Seed^2 mod M
      State.X := (Seed * Seed) mod State.M;
      return State;
   end Bbs_Initialize;

   procedure Bbs_Next_Bit (State : in out Bbs_State; Result : out Boolean) is
   begin
      -- X_{n+1} = X_n^2 mod M
      State.X := (State.X * State.X) mod State.M;
      
      -- Extract parity bit (least significant bit)
      Result := (State.X mod 2) = 1;
   end Bbs_Next_Bit;

   procedure Bbs_Generate_Byte (State : in out Bbs_State; Result : out Byte) is
      Bit : Boolean;
      Accumulator : Byte := 0;
   begin
      for I in 1 .. 8 loop
         pragma Unreferenced (I);
         Bbs_Next_Bit (State, Bit);
         Accumulator := Accumulator * 2;
         if Bit then
            Accumulator := Accumulator + 1;
         end if;
      end loop;
      Result := Accumulator;
   end Bbs_Generate_Byte;


   -- =========================================================================
   -- ChaCha20 Implementation
   -- =========================================================================

   -- Helper: Quarter Round function applying non-linear transformations
   procedure QR (A, B, C, D : in out Word) is
   begin
      A := A + B; D := D xor A; D := Rol (D, 16);
      C := C + D; B := B xor C; B := Rol (B, 12);
      A := A + B; D := D xor A; D := Rol (D, 8);
      C := C + D; B := B xor C; B := Rol (B, 7);
   end QR;

   -- Helper: Generate next 64-byte block of pseudo-random keystream
   procedure Chacha_Block (State : in out Chacha_State) is
      Working : Chacha_Internal_State := State.State;
      Output_Index : Natural := 0;
      W : Word;
   begin
      -- 20 rounds (10 iterations of column and diagonal double-rounds)
      for I in 1 .. 10 loop
         pragma Unreferenced (I);
         -- Column rounds
         QR (Working (0), Working (4), Working (8),  Working (12));
         QR (Working (1), Working (5), Working (9),  Working (13));
         QR (Working (2), Working (6), Working (10), Working (14));
         QR (Working (3), Working (7), Working (11), Working (15));
         -- Diagonal rounds
         QR (Working (0), Working (5), Working (10), Working (15));
         QR (Working (1), Working (6), Working (11), Working (12));
         QR (Working (2), Working (7), Working (8),  Working (13));
         QR (Working (3), Working (4), Working (9),  Working (14));
      end loop;

      -- Add working state to original state and serialize to little-endian bytes
      for I in 0 .. 15 loop
         Working (I) := Working (I) + State.State (I);
         W := Working (I);
         State.Buffer (Output_Index)     := Byte (W and 16#FF#);
         State.Buffer (Output_Index + 1) := Byte (Interfaces.Shift_Right (Interfaces.Unsigned_32 (W), 8) and 16#FF#);
         State.Buffer (Output_Index + 2) := Byte (Interfaces.Shift_Right (Interfaces.Unsigned_32 (W), 16) and 16#FF#);
         State.Buffer (Output_Index + 3) := Byte (Interfaces.Shift_Right (Interfaces.Unsigned_32 (W), 24) and 16#FF#);
         Output_Index := Output_Index + 4;
      end loop;

      -- Increment 64-bit block counter (words 12 and 13)
      State.State (12) := State.State (12) + 1;
      if State.State (12) = 0 then
         State.State (13) := State.State (13) + 1;
      end if;

      State.Available := 64;
   end Chacha_Block;

   function Chacha_Initialize (Key : Key_Type; Nonce : Nonce_Type) return Chacha_State is
      State : Chacha_State;
   begin
      -- Standard ChaCha20 Constants "expand 32-byte k"
      State.State (0) := 16#61707865#;
      State.State (1) := 16#3320646e#;
      State.State (2) := 16#79622d32#;
      State.State (3) := 16#6b206574#;

      -- Key setup
      for I in 0 .. 7 loop
         State.State (4 + I) := Key (I);
      end loop;

      -- Counter setup (starts at 0)
      State.State (12) := 0;
      State.State (13) := 0;

      -- Nonce setup
      State.State (14) := Nonce (0);
      State.State (15) := Nonce (1);

      State.Available := 0;
      return State;
   end Chacha_Initialize;

   procedure Chacha_Generate_Bytes (State : in out Chacha_State; Buffer : out Byte_Array) is
      Idx     : Natural := Buffer'First;
      To_Copy : Natural;
   begin
      -- Edge case: Empty buffer requested, do nothing
      if Buffer'Length = 0 then
         return;
      end if;

      while Idx <= Buffer'Last loop
         if State.Available = 0 then
            Chacha_Block (State);
         end if;

         -- Copy bytes from the generated block buffer
         To_Copy := Natural'Min (Buffer'Last - Idx + 1, State.Available);
         for I in 1 .. To_Copy loop
            pragma Unreferenced (I);
            Buffer (Idx) := State.Buffer (64 - State.Available);
            Idx := Idx + 1;
            State.Available := State.Available - 1;
         end loop;
      end loop;
   end Chacha_Generate_Bytes;

   procedure Chacha_Reseed (State : in out Chacha_State; New_Key : Key_Type) is
   begin
      -- Update key material
      for I in 0 .. 7 loop
         State.State (4 + I) := New_Key (I);
      end loop;
      -- Reset the counter to 0 to prevent block collision, preserve nonce
      State.State (12) := 0;
      State.State (13) := 0;
      State.Available := 0; -- Discard unused keystream to strictly separate sequences
   end Chacha_Reseed;

end Csprng;
