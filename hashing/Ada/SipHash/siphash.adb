package body SipHash is

   use Interfaces;

   -- The internal 256-bit state of SipHash (4 x 64-bit words)
   type State is array (0 .. 3) of Word64;

   -- "somepseu", "dorandom", "lygenera", "tedbytes" in ASCII (little-endian)
   Init_0 : constant Word64 := 16#736f6d6570736575#;
   Init_1 : constant Word64 := 16#646f72616e646f6d#;
   Init_2 : constant Word64 := 16#6c7967656e657261#;
   Init_3 : constant Word64 := 16#7465646279746573#;

   -- Helper to rotate a 64-bit word left by a specific amount
   function Rotl (Value : Word64; Amount : Natural) return Word64 is
   begin
      return Word64 (Rotate_Left (Unsigned_64 (Value), Amount));
   end Rotl;

   -- Helper to load 8 bytes from an unaligned array into a little-endian Word64
   function Load_LE (Data : Byte_Array; Start_Idx : Natural) return Word64 is
      Res : Word64 := 0;
   begin
      for I in Integer range 0 .. 7 loop
         Res := Res or Word64 (Shift_Left (Unsigned_64 (Data (Start_Idx + I)), Natural (I * 8)));
      end loop;
      return Res;
   end Load_LE;

   -- The core ARX (Add-Rotate-Xor) network permutation for SipHash
   procedure Sip_Round (V : in out State) is
   begin
      V(0) := V(0) + V(1);
      V(1) := Rotl (V(1), 13);
      V(1) := V(1) xor V(0);
      V(0) := Rotl (V(0), 32);

      V(2) := V(2) + V(3);
      V(3) := Rotl (V(3), 16);
      V(3) := V(3) xor V(2);

      V(0) := V(0) + V(3);
      V(3) := Rotl (V(3), 21);
      V(3) := V(3) xor V(0);

      V(2) := V(2) + V(1);
      V(1) := Rotl (V(1), 17);
      V(1) := V(1) xor V(2);
      V(2) := Rotl (V(2), 32);
   end Sip_Round;

   -- Initializes the internal state with the standard constants and the 128-bit key.
   -- SipHash128 XORs V(1) with 0xEE to isolate its outputs from the 64-bit variant.
   procedure Init_State (V : out State; Key : Key_Type; Is_128 : Boolean) is
      K0 : constant Word64 := Load_LE (Key, Key'First);
      K1 : constant Word64 := Load_LE (Key, Key'First + 8);
   begin
      V(0) := Init_0 xor K0;
      V(1) := Init_1 xor K1;
      V(2) := Init_2 xor K0;
      V(3) := Init_3 xor K1;
      
      if Is_128 then
         V(1) := V(1) xor Word64 (16#ee#);
      end if;
   end Init_State;

   -- Core processing loop: consumes full 64-bit blocks of the message, 
   -- then constructs and processes the final padded block.
   procedure Process_Message (V : in out State; Message : Byte_Array; C : Positive) is
      Blocks   : constant Integer := Message'Length / 8;
      Leftover : constant Integer := Message'Length mod 8;
      M_Idx    : Natural := Message'First;
      M_Block  : Word64;
      B        : Word64;
   begin
      -- Process all complete 8-byte blocks
      for I in Integer range 1 .. Blocks loop
         pragma Unreferenced (I);
         M_Block := Load_LE (Message, M_Idx);
         V(3) := V(3) xor M_Block;
         
         for R in Integer range 1 .. C loop
            pragma Unreferenced (R);
            Sip_Round (V);
         end loop;
         
         V(0) := V(0) xor M_Block;
         M_Idx := M_Idx + 8;
      end loop;

      -- Construct final block B
      -- The MSB is the message length mod 256. The remaining bytes are the leftover message bytes.
      B := Word64 (Shift_Left (Unsigned_64 (Message'Length mod 256), 56));
      
      for I in Integer range 0 .. Leftover - 1 loop
         B := B or Word64 (Shift_Left (Unsigned_64 (Message (M_Idx + I)), Natural (I * 8)));
      end loop;

      -- Process the final padded block
      V(3) := V(3) xor B;
      for R in Integer range 1 .. C loop
         pragma Unreferenced (R);
         Sip_Round (V);
      end loop;
      V(0) := V(0) xor B;
   end Process_Message;

   -- Computes the standard 64-bit MAC
   function Hash_64
     (Key     : Key_Type;
      Message : Byte_Array;
      C       : Positive := Default_C;
      D       : Positive := Default_D) return Word64
   is
      V : State;
   begin
      Init_State (V, Key, False);
      Process_Message (V, Message, C);
      
      -- Finalization for 64-bit tag
      V(2) := V(2) xor Word64 (16#ff#);
      for R in Integer range 1 .. D loop
         pragma Unreferenced (R);
         Sip_Round (V);
      end loop;
      
      return V(0) xor V(1) xor V(2) xor V(3);
   end Hash_64;

   -- Computes the 128-bit MAC by performing a two-phase finalization
   function Hash_128
     (Key     : Key_Type;
      Message : Byte_Array;
      C       : Positive := Default_C;
      D       : Positive := Default_D) return Tag_128
   is
      V   : State;
      Res : Tag_128;
   begin
      Init_State (V, Key, True);
      Process_Message (V, Message, C);
      
      -- Phase 1 Finalization for the low 64-bits
      V(2) := V(2) xor Word64 (16#ee#);
      for R in Integer range 1 .. D loop
         pragma Unreferenced (R);
         Sip_Round (V);
      end loop;
      Res.Low := V(0) xor V(1) xor V(2) xor V(3);

      -- Phase 2 Finalization for the high 64-bits
      V(1) := V(1) xor Word64 (16#dd#);
      for R in Integer range 1 .. D loop
         pragma Unreferenced (R);
         Sip_Round (V);
      end loop;
      Res.High := V(0) xor V(1) xor V(2) xor V(3);

      return Res;
   end Hash_128;

end SipHash;
