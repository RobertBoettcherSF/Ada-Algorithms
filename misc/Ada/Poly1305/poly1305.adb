package body Poly1305 is
   use Interfaces;
   
   -----------------------------------------------------------------------------
   --  Helper: To_U32
   --  Reads 4 bytes from a Byte_Array starting at Offset in Little-Endian order.
   -----------------------------------------------------------------------------
   function To_U32 (B : Byte_Array; Offset : Natural) return Unsigned_32 is
   begin
      return Unsigned_32 (B (Offset)) or
             Shift_Left (Unsigned_32 (B (Offset + 1)), 8) or
             Shift_Left (Unsigned_32 (B (Offset + 2)), 16) or
             Shift_Left (Unsigned_32 (B (Offset + 3)), 24);
   end To_U32;

   -----------------------------------------------------------------------------
   --  Helper: Process_Block
   --  Core Poly1305 block processing logic using base 2^26 radix arithmetic.
   -----------------------------------------------------------------------------
   procedure Process_Block (Ctx : in out Context; Block : Byte_Array; Length : Natural) is
      C : Byte_Array (0 .. 16) := [others => 0];
      T0, T1, T2, T3, T4 : Unsigned_32;
      c0, c1, c2, c3, c4 : Unsigned_64;
      d0, d1, d2, d3, d4 : Unsigned_64;
   begin
      --  Load block data (up to 16 bytes) and append the pad bit (0x01)
      for I in 0 .. Length - 1 loop
         C (I) := Block (Block'First + I);
      end loop;
      C (Length) := 1;
      
      --  Form 32-bit limbs (Little-Endian)
      T0 := To_U32 (C, 0);
      T1 := To_U32 (C, 4);
      T2 := To_U32 (C, 8);
      T3 := To_U32 (C, 12);
      T4 := Unsigned_32 (C (16));
      
      --  Convert the padded block into base 2^26 representation
      c0 := Unsigned_64 (T0 and 16#3FFFFFF#);
      c1 := Unsigned_64 ((Shift_Right (T0, 26) or Shift_Left (T1, 6)) and 16#3FFFFFF#);
      c2 := Unsigned_64 ((Shift_Right (T1, 20) or Shift_Left (T2, 12)) and 16#3FFFFFF#);
      c3 := Unsigned_64 ((Shift_Right (T2, 14) or Shift_Left (T3, 18)) and 16#3FFFFFF#);
      c4 := Unsigned_64 ((Shift_Right (T3, 8)  or Shift_Left (T4, 24)) and 16#3FFFFFF#);
      
      --  Add chunk to accumulator
      Ctx.h0 := Ctx.h0 + c0;
      Ctx.h1 := Ctx.h1 + c1;
      Ctx.h2 := Ctx.h2 + c2;
      Ctx.h3 := Ctx.h3 + c3;
      Ctx.h4 := Ctx.h4 + c4;
      
      --  Multiply (Accumulator = Accumulator * r)
      --  Takes advantage of precomputed s_i = r_i * 5 to implicitly reduce modulo 2^130 - 5.
      d0 := Ctx.h0 * Ctx.r0 + Ctx.h1 * Ctx.s4 + Ctx.h2 * Ctx.s3 + Ctx.h3 * Ctx.s2 + Ctx.h4 * Ctx.s1;
      d1 := Ctx.h0 * Ctx.r1 + Ctx.h1 * Ctx.r0 + Ctx.h2 * Ctx.s4 + Ctx.h3 * Ctx.s3 + Ctx.h4 * Ctx.s2;
      d2 := Ctx.h0 * Ctx.r2 + Ctx.h1 * Ctx.r1 + Ctx.h2 * Ctx.r0 + Ctx.h3 * Ctx.s4 + Ctx.h4 * Ctx.s3;
      d3 := Ctx.h0 * Ctx.r3 + Ctx.h1 * Ctx.r2 + Ctx.h2 * Ctx.r1 + Ctx.h3 * Ctx.r0 + Ctx.h4 * Ctx.s4;
      d4 := Ctx.h0 * Ctx.r4 + Ctx.h1 * Ctx.r3 + Ctx.h2 * Ctx.r2 + Ctx.h3 * Ctx.r1 + Ctx.h4 * Ctx.r0;
      
      --  Propagate carries across base-26 limbs and reduce
      Ctx.h0 := d0 and 16#3FFFFFF#;
      d1 := d1 + Shift_Right (d0, 26);
      
      Ctx.h1 := d1 and 16#3FFFFFF#;
      d2 := d2 + Shift_Right (d1, 26);
      
      Ctx.h2 := d2 and 16#3FFFFFF#;
      d3 := d3 + Shift_Right (d2, 26);
      
      Ctx.h3 := d3 and 16#3FFFFFF#;
      d4 := d4 + Shift_Right (d3, 26);
      
      Ctx.h4 := d4 and 16#3FFFFFF#;
      Ctx.h0 := Ctx.h0 + Shift_Right (d4, 26) * 5;
      
      --  Final carry from wrap-around modulo P
      Ctx.h1 := Ctx.h1 + Shift_Right (Ctx.h0, 26);
      Ctx.h0 := Ctx.h0 and 16#3FFFFFF#;
   end Process_Block;

   -----------------------------------------------------------------------------
   --  API: Init
   -----------------------------------------------------------------------------
   procedure Init (Ctx : out Context; Key : Key_Type) is
      C_R : Byte_Array (0 .. 15);
      T0, T1, T2, T3 : Unsigned_32;
   begin
      Ctx := (Initialized => True, others => <>);
      
      for I in 0 .. 15 loop
         C_R (I) := Key (Key'First + I);
         Ctx.S_Key (I) := Key (Key'First + 16 + I);
      end loop;
      
      --  Apply clamping rules to r (first 16 bytes of the key)
      C_R (3)  := C_R (3) and 15;
      C_R (4)  := C_R (4) and 252;
      C_R (7)  := C_R (7) and 15;
      C_R (8)  := C_R (8) and 252;
      C_R (11) := C_R (11) and 15;
      C_R (12) := C_R (12) and 252;
      C_R (15) := C_R (15) and 15;
      
      T0 := To_U32 (C_R, 0);
      T1 := To_U32 (C_R, 4);
      T2 := To_U32 (C_R, 8);
      T3 := To_U32 (C_R, 12);
      
      --  Convert clamped r to base 2^26
      Ctx.r0 := Unsigned_64 (T0 and 16#3FFFFFF#);
      Ctx.r1 := Unsigned_64 ((Shift_Right (T0, 26) or Shift_Left (T1, 6)) and 16#3FFFFFF#);
      Ctx.r2 := Unsigned_64 ((Shift_Right (T1, 20) or Shift_Left (T2, 12)) and 16#3FFFFFF#);
      Ctx.r3 := Unsigned_64 ((Shift_Right (T2, 14) or Shift_Left (T3, 18)) and 16#3FFFFFF#);
      Ctx.r4 := Unsigned_64 (Shift_Right (T3, 8) and 16#3FFFFFF#);
      
      --  Precompute scaled values (r * 5)
      Ctx.s1 := Ctx.r1 * 5;
      Ctx.s2 := Ctx.r2 * 5;
      Ctx.s3 := Ctx.r3 * 5;
      Ctx.s4 := Ctx.r4 * 5;
   end Init;

   -----------------------------------------------------------------------------
   --  API: Update
   -----------------------------------------------------------------------------
   procedure Update (Ctx : in out Context; Message : Byte_Array) is
      Idx : Natural := Message'First;
      Remain : Natural := Message'Length;
      Copied : Natural;
   begin
      if not Ctx.Initialized then
         raise State_Error with "Cannot Update: Context not initialized";
      end if;
      
      while Remain > 0 loop
         if Ctx.Leftover = 0 and then Remain >= 16 then
            --  Process full 16-byte blocks efficiently without buffering
            Process_Block (Ctx, Message (Idx .. Idx + 15), 16);
            Idx := Idx + 16;
            Remain := Remain - 16;
         else
            --  Fill the residual buffer up to 16 bytes
            Copied := 16 - Ctx.Leftover;
            if Copied > Remain then
               Copied := Remain;
            end if;
            
            for I in 0 .. Copied - 1 loop
               Ctx.Buffer (Ctx.Leftover + I) := Message (Idx + I);
            end loop;
            
            Ctx.Leftover := Ctx.Leftover + Copied;
            Idx := Idx + Copied;
            Remain := Remain - Copied;
            
            --  If buffer is now full, consume it
            if Ctx.Leftover = 16 then
               declare
                  Temp_Block : constant Byte_Array := Ctx.Buffer;
               begin
                  Process_Block (Ctx, Temp_Block, 16);
               end;
               Ctx.Leftover := 0;
            end if;
         end if;
      end loop;
   end Update;

   -----------------------------------------------------------------------------
   --  API: Final
   -----------------------------------------------------------------------------
   procedure Final (Ctx : in out Context; MAC : out MAC_Type) is
      g0, g1, g2, g3, g4 : Unsigned_64;
      b, Borrow, Mask    : Unsigned_64;
      T0, T1, T2, T3     : Unsigned_64;
      S0, S1, S2, S3     : Unsigned_64;
      Sum0, Sum1, Sum2, Sum3 : Unsigned_64;
   begin
      if not Ctx.Initialized then
         raise State_Error with "Cannot Finalize: Context not initialized";
      end if;
      
      --  Process any remaining data in the buffer
      if Ctx.Leftover > 0 then
         declare
            Temp_Block : constant Byte_Array := Ctx.Buffer (0 .. Ctx.Leftover - 1);
         begin
            Process_Block (Ctx, Temp_Block, Ctx.Leftover);
         end;
      end if;
      
      --  Fully carry-propagate to ensure strictly reduced base-26 limbs
      Ctx.h2 := Ctx.h2 + Shift_Right (Ctx.h1, 26); Ctx.h1 := Ctx.h1 and 16#3FFFFFF#;
      Ctx.h3 := Ctx.h3 + Shift_Right (Ctx.h2, 26); Ctx.h2 := Ctx.h2 and 16#3FFFFFF#;
      Ctx.h4 := Ctx.h4 + Shift_Right (Ctx.h3, 26); Ctx.h3 := Ctx.h3 and 16#3FFFFFF#;
      Ctx.h0 := Ctx.h0 + Shift_Right (Ctx.h4, 26) * 5; Ctx.h4 := Ctx.h4 and 16#3FFFFFF#;
      Ctx.h1 := Ctx.h1 + Shift_Right (Ctx.h0, 26); Ctx.h0 := Ctx.h0 and 16#3FFFFFF#;
      
      --  Compute g = h - (2^130 - 5). We do this by adding 5 and subtracting 2^130.
      g0 := Ctx.h0 + 5;
      b  := Shift_Right (g0, 26); g0 := g0 and 16#3FFFFFF#;
      g1 := Ctx.h1 + b;
      b  := Shift_Right (g1, 26); g1 := g1 and 16#3FFFFFF#;
      g2 := Ctx.h2 + b;
      b  := Shift_Right (g2, 26); g2 := g2 and 16#3FFFFFF#;
      g3 := Ctx.h3 + b;
      b  := Shift_Right (g3, 26); g3 := g3 and 16#3FFFFFF#;
      g4 := Ctx.h4 + b - Shift_Left (Unsigned_64 (1), 26);
      
      --  Constant-time check for borrow. If g4 borrowed, bit 63 is set.
      Borrow := Shift_Right (g4, 63);
      
      --  If Borrow=1, Mask becomes 0x000...000. If Borrow=0, Mask becomes 0xFFF...FFF.
      --  Modular arithmetic on Unsigned_64 strictly wraps.
      Mask := Borrow - 1;
      
      --  Select between h and g based on the mask
      Ctx.h0 := (g0 and Mask) or (Ctx.h0 and not Mask);
      Ctx.h1 := (g1 and Mask) or (Ctx.h1 and not Mask);
      Ctx.h2 := (g2 and Mask) or (Ctx.h2 and not Mask);
      Ctx.h3 := (g3 and Mask) or (Ctx.h3 and not Mask);
      Ctx.h4 := (g4 and Mask) or (Ctx.h4 and not Mask);
      
      --  Convert base-26 back to 32-bit limbs (128 bits total, top 2 bits dropped)
      T0 := (Ctx.h0 or Shift_Left (Ctx.h1, 26)) and 16#FFFF_FFFF#;
      T1 := (Shift_Right (Ctx.h1, 6) or Shift_Left (Ctx.h2, 20)) and 16#FFFF_FFFF#;
      T2 := (Shift_Right (Ctx.h2, 12) or Shift_Left (Ctx.h3, 14)) and 16#FFFF_FFFF#;
      T3 := (Shift_Right (Ctx.h3, 18) or Shift_Left (Ctx.h4, 8)) and 16#FFFF_FFFF#;
      
      --  Read the second half of the key (s)
      S0 := Unsigned_64 (To_U32 (Ctx.S_Key, 0));
      S1 := Unsigned_64 (To_U32 (Ctx.S_Key, 4));
      S2 := Unsigned_64 (To_U32 (Ctx.S_Key, 8));
      S3 := Unsigned_64 (To_U32 (Ctx.S_Key, 12));
      
      --  Add s to the result modulo 2^128
      Sum0 := T0 + S0;
      Sum1 := T1 + S1 + Shift_Right (Sum0, 32);
      Sum2 := T2 + S2 + Shift_Right (Sum1, 32);
      Sum3 := T3 + S3 + Shift_Right (Sum2, 32);
      
      --  Pack Result into MAC output (Little-Endian)
      MAC (0)  := Byte (Sum0 and 16#FF#);
      MAC (1)  := Byte (Shift_Right (Sum0, 8) and 16#FF#);
      MAC (2)  := Byte (Shift_Right (Sum0, 16) and 16#FF#);
      MAC (3)  := Byte (Shift_Right (Sum0, 24) and 16#FF#);
      
      MAC (4)  := Byte (Sum1 and 16#FF#);
      MAC (5)  := Byte (Shift_Right (Sum1, 8) and 16#FF#);
      MAC (6)  := Byte (Shift_Right (Sum1, 16) and 16#FF#);
      MAC (7)  := Byte (Shift_Right (Sum1, 24) and 16#FF#);
      
      MAC (8)  := Byte (Sum2 and 16#FF#);
      MAC (9)  := Byte (Shift_Right (Sum2, 8) and 16#FF#);
      MAC (10) := Byte (Shift_Right (Sum2, 16) and 16#FF#);
      MAC (11) := Byte (Shift_Right (Sum2, 24) and 16#FF#);
      
      MAC (12) := Byte (Sum3 and 16#FF#);
      MAC (13) := Byte (Shift_Right (Sum3, 8) and 16#FF#);
      MAC (14) := Byte (Shift_Right (Sum3, 16) and 16#FF#);
      MAC (15) := Byte (Shift_Right (Sum3, 24) and 16#FF#);
      
      --  Wipe internal state to protect sensitive cryptographic keying material
      Ctx := (Initialized => False, others => <>);
   end Final;

   -----------------------------------------------------------------------------
   --  API: Is_Initialized
   -----------------------------------------------------------------------------
   function Is_Initialized (Ctx : Context) return Boolean is
   begin
      return Ctx.Initialized;
   end Is_Initialized;

   -----------------------------------------------------------------------------
   --  API: Generate_MAC (Static/Single-Shot)
   -----------------------------------------------------------------------------
   function Generate_MAC (Message : Byte_Array; Key : Key_Type) return MAC_Type is
      Ctx : Context;
      MAC : MAC_Type;
   begin
      Init (Ctx, Key);
      Update (Ctx, Message);
      Final (Ctx, MAC);
      return MAC;
   end Generate_MAC;

end Poly1305;
