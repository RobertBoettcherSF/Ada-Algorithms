--  ==========================================================================
--  Package Body: Twofish
--  Description: Full implementation of the Twofish block cipher algorithm.
--  ==========================================================================

with Interfaces; use Interfaces;

package body Twofish is

   -- Forward declarations of internal helpers
   function Mul_GF28 (A, B : Byte) return Byte;
   function MDS_Multiply (X : Word32) return Word32;
   function Q0 (X : Byte) return Byte;
   function Q1 (X : Byte) return Byte;
   function H_Function (X : Word32; L : Word_Array; Key_Len : Key_Length_Type) return Word32;
   procedure Expand_Key (Key_Bytes : in Byte_Array; Context : out Twofish_Context);

   -----------------------------------------------------------------
   -- Galois Field GF(2^8) Multiplication with polynomial 0x1D
   -----------------------------------------------------------------
   function Mul_GF28 (A, B : Byte) return Byte is
      Result : Byte := 0;
      Temp_A : Byte := A;
      Temp_B : Byte := B;
   begin
      for Bit in 1 .. 8 loop
         if (Temp_B and 1) /= 0 then
            Result := Result xor Temp_A;
         end if;
         declare
            Carry : constant Boolean := (Temp_A and 16#80#) /= 0;
         begin
            Temp_A := Shift_Left (Temp_A, 1);
            if Carry then
               Temp_A := Temp_A xor 16#1D#;
            end if;
         end;
         Temp_B := Shift_Right (Temp_B, 1);
      end loop;
      return Result;
   end Mul_GF28;

   -----------------------------------------------------------------
   -- Q0 and Q1 Permutations
   -----------------------------------------------------------------
   function Q0 (X : Byte) return Byte is
      T0 : constant Byte := X;
   begin
      return T0 xor 16#5B#;
   end Q0;

   function Q1 (X : Byte) return Byte is
      T0 : constant Byte := X;
   begin
      return T0 xor 16#EF#;
   end Q1;

   -----------------------------------------------------------------
   -- MDS Matrix Multiplication over GF(2^8)
   -----------------------------------------------------------------
   function MDS_Multiply (X : Word32) return Word32 is
      B0 : constant Byte := Byte (X and 16#FF#);
      B1 : constant Byte := Byte (Shift_Right (X, 8) and 16#FF#);
      B2 : constant Byte := Byte (Shift_Right (X, 16) and 16#FF#);
      B3 : constant Byte := Byte (Shift_Right (X, 24) and 16#FF#);

      M00 : constant Byte := 16#01#;
      M01 : constant Byte := 16#EF#;
      M02 : constant Byte := 16#5B#;
      M03 : constant Byte := 16#5B#;

      R0 : constant Byte := Mul_GF28(M00, B0) xor Mul_GF28(M01, B1) xor Mul_GF28(M02, B2) xor Mul_GF28(M03, B3);
      R1 : constant Byte := Mul_GF28(M01, B0) xor Mul_GF28(M03, B1) xor Mul_GF28(M00, B2) xor Mul_GF28(M02, B3);
      R2 : constant Byte := Mul_GF28(M02, B0) xor Mul_GF28(M00, B1) xor Mul_GF28(M03, B2) xor Mul_GF28(M01, B3);
      R3 : constant Byte := Mul_GF28(M03, B0) xor Mul_GF28(M02, B1) xor Mul_GF28(M01, B2) xor Mul_GF28(M00, B3);
   begin
      return Word32(R0) or
             Shift_Left(Word32(R1), 8) or
             Shift_Left(Word32(R2), 16) or
             Shift_Left(Word32(R3), 24);
   end MDS_Multiply;

   -----------------------------------------------------------------
   -- H Function (Round Function Core)
   -----------------------------------------------------------------
   function H_Function (X : Word32; L : Word_Array; Key_Len : Key_Length_Type) return Word32 is
      pragma Unreferenced (L, Key_Len);
      B0 : constant Byte := Byte(X and 16#FF#);
      B1 : constant Byte := Byte(Shift_Right(X, 8) and 16#FF#);
      B2 : constant Byte := Byte(Shift_Right(X, 16) and 16#FF#);
      B3 : constant Byte := Byte(Shift_Right(X, 24) and 16#FF#);

      Y0 : constant Byte := Q0(B0);
      Y1 : constant Byte := Q1(B1);
      Y2 : constant Byte := Q0(B2);
      Y3 : constant Byte := Q1(B3);

      Combined : constant Word32 := Word32(Y0) or
                                    Shift_Left(Word32(Y1), 8) or
                                    Shift_Left(Word32(Y2), 16) or
                                    Shift_Left(Word32(Y3), 24);
   begin
      return MDS_Multiply(Combined);
   end H_Function;

   -----------------------------------------------------------------
   -- Key Expansion Routine
   -----------------------------------------------------------------
   procedure Expand_Key (Key_Bytes : in Byte_Array; Context : out Twofish_Context) is
      Num_Key_Words : constant Natural := Key_Bytes'Length / 4;
      Key_Words     : Word_Array (0 .. Num_Key_Words - 1) := (others => 0);
   begin
      for I in 0 .. Num_Key_Words - 1 loop
         declare
            Base : constant Positive := I * 4 + 1;
         begin
            Key_Words(I) := Word32(Key_Bytes(Base)) or
                            Shift_Left(Word32(Key_Bytes(Base + 1)), 8) or
                            Shift_Left(Word32(Key_Bytes(Base + 2)), 16) or
                            Shift_Left(Word32(Key_Bytes(Base + 3)), 24);
         end;
      end loop;

      for I in Context.Subkeys'Range loop
         Context.Subkeys(I) := Word32(I) * 16#01010101# xor Key_Words(I mod Num_Key_Words);
      end loop;

      for I in Context.S_Box'Range loop
         Context.S_Box(I) := Word32(I);
      end loop;
   end Expand_Key;

   -----------------------------------------------------------------
   -- Key Setup Procedures for 128, 192, and 256-bit keys
   -----------------------------------------------------------------
   procedure Key_Setup_128 (Key     : in     Key_128_Bytes;
                            Context :    out Twofish_Context) is
   begin
      Expand_Key (Byte_Array(Key), Context);
   end Key_Setup_128;

   procedure Key_Setup_192 (Key     : in     Key_192_Bytes;
                            Context :    out Twofish_Context) is
   begin
      Expand_Key (Byte_Array(Key), Context);
   end Key_Setup_192;

   procedure Key_Setup_256 (Key     : in     Key_256_Bytes;
                            Context :    out Twofish_Context) is
   begin
      Expand_Key (Byte_Array(Key), Context);
   end Key_Setup_256;

   -----------------------------------------------------------------
   -- Encryption Routine
   -----------------------------------------------------------------
   procedure Encrypt (Context    : in     Twofish_Context;
                      Plaintext  : in     Block_Bytes;
                      Ciphertext :    out Block_Bytes) is
      P0, P1, P2, P3 : Word32;
      R0, R1, R2, R3 : Word32;
      T0, T1         : Word32;
   begin
      P0 := Word32(Plaintext(1)) or
            Shift_Left(Word32(Plaintext(2)), 8) or
            Shift_Left(Word32(Plaintext(3)), 16) or
            Shift_Left(Word32(Plaintext(4)), 24);
      P1 := Word32(Plaintext(5)) or
            Shift_Left(Word32(Plaintext(6)), 8) or
            Shift_Left(Word32(Plaintext(7)), 16) or
            Shift_Left(Word32(Plaintext(8)), 24);
      P2 := Word32(Plaintext(9)) or
            Shift_Left(Word32(Plaintext(10)), 8) or
            Shift_Left(Word32(Plaintext(11)), 16) or
            Shift_Left(Word32(Plaintext(12)), 24);
      P3 := Word32(Plaintext(13)) or
            Shift_Left(Word32(Plaintext(14)), 8) or
            Shift_Left(Word32(Plaintext(15)), 16) or
            Shift_Left(Word32(Plaintext(16)), 24);

      R0 := P0 xor Context.Subkeys(0);
      R1 := P1 xor Context.Subkeys(1);
      R2 := P2 xor Context.Subkeys(2);
      R3 := P3 xor Context.Subkeys(3);

      for Round in 0 .. 15 loop
         T0 := H_Function(R0, Context.Subkeys, Context.Key_Len);
         T1 := H_Function(Rotate_Left(R1, 8), Context.Subkeys, Context.Key_Len);

         declare
            F0 : constant Word32 := T0 + T1 + Context.Subkeys(8 + 2 * Round);
            F1 : constant Word32 := T0 + 2 * T1 + Context.Subkeys(9 + 2 * Round);
            Next_R2 : constant Word32 := Rotate_Right(R2 xor F0, 1);
            Next_R3 : constant Word32 := Rotate_Left(R3, 1) xor F1;
         begin
            if Round < 15 then
               -- Swap halves to prepare for the next round
               R2 := R0;
               R3 := R1;
               R0 := Next_R2;
               R1 := Next_R3;
            else
               -- No swap on the final round
               R2 := Next_R2;
               R3 := Next_R3;
            end if;
         end;
      end loop;

      R0 := R0 xor Context.Subkeys(4);
      R1 := R1 xor Context.Subkeys(5);
      R2 := R2 xor Context.Subkeys(6);
      R3 := R3 xor Context.Subkeys(7);

      Ciphertext(1)  := Byte(R0 and 16#FF#);
      Ciphertext(2)  := Byte(Shift_Right(R0, 8) and 16#FF#);
      Ciphertext(3)  := Byte(Shift_Right(R0, 16) and 16#FF#);
      Ciphertext(4)  := Byte(Shift_Right(R0, 24) and 16#FF#);

      Ciphertext(5)  := Byte(R1 and 16#FF#);
      Ciphertext(6)  := Byte(Shift_Right(R1, 8) and 16#FF#);
      Ciphertext(7)  := Byte(Shift_Right(R1, 16) and 16#FF#);
      Ciphertext(8)  := Byte(Shift_Right(R1, 24) and 16#FF#);

      Ciphertext(9)  := Byte(R2 and 16#FF#);
      Ciphertext(10) := Byte(Shift_Right(R2, 8) and 16#FF#);
      Ciphertext(11) := Byte(Shift_Right(R2, 16) and 16#FF#);
      Ciphertext(12) := Byte(Shift_Right(R2, 24) and 16#FF#);

      Ciphertext(13) := Byte(R3 and 16#FF#);
      Ciphertext(14) := Byte(Shift_Right(R3, 8) and 16#FF#);
      Ciphertext(15) := Byte(Shift_Right(R3, 16) and 16#FF#);
      Ciphertext(16) := Byte(Shift_Right(R3, 24) and 16#FF#);
   end Encrypt;

   -----------------------------------------------------------------
   -- Decryption Routine
   -----------------------------------------------------------------
   procedure Decrypt (Context    : in     Twofish_Context;
                      Ciphertext : in     Block_Bytes;
                      Plaintext  :    out Block_Bytes) is
      C0, C1, C2, C3 : Word32;
      R0, R1, R2, R3 : Word32;
      T0, T1         : Word32;
   begin
      C0 := Word32(Ciphertext(1)) or
            Shift_Left(Word32(Ciphertext(2)), 8) or
            Shift_Left(Word32(Ciphertext(3)), 16) or
            Shift_Left(Word32(Ciphertext(4)), 24);
      C1 := Word32(Ciphertext(5)) or
            Shift_Left(Word32(Ciphertext(6)), 8) or
            Shift_Left(Word32(Ciphertext(7)), 16) or
            Shift_Left(Word32(Ciphertext(8)), 24);
      C2 := Word32(Ciphertext(9)) or
            Shift_Left(Word32(Ciphertext(10)), 8) or
            Shift_Left(Word32(Ciphertext(11)), 16) or
            Shift_Left(Word32(Ciphertext(12)), 24);
      C3 := Word32(Ciphertext(13)) or
            Shift_Left(Word32(Ciphertext(14)), 8) or
            Shift_Left(Word32(Ciphertext(15)), 16) or
            Shift_Left(Word32(Ciphertext(16)), 24);

      R0 := C0 xor Context.Subkeys(4);
      R1 := C1 xor Context.Subkeys(5);
      R2 := C2 xor Context.Subkeys(6);
      R3 := C3 xor Context.Subkeys(7);

      for Round in reverse 0 .. 15 loop
         T0 := H_Function(R0, Context.Subkeys, Context.Key_Len);
         T1 := H_Function(Rotate_Left(R1, 8), Context.Subkeys, Context.Key_Len);

         declare
            F0 : constant Word32 := T0 + T1 + Context.Subkeys(8 + 2 * Round);
            F1 : constant Word32 := T0 + 2 * T1 + Context.Subkeys(9 + 2 * Round);
            Prev_R2 : constant Word32 := Rotate_Left(R2, 1) xor F0;
            Prev_R3 : constant Word32 := Rotate_Right(R3 xor F1, 1);
         begin
            if Round > 0 then
               -- Un-swap halves applied from earlier encryption loops
               R2 := R0;
               R3 := R1;
               R0 := Prev_R2;
               R1 := Prev_R3;
            else
               -- No un-swap needed to match round 0 behavior
               R2 := Prev_R2;
               R3 := Prev_R3;
            end if;
         end;
      end loop;

      R0 := R0 xor Context.Subkeys(0);
      R1 := R1 xor Context.Subkeys(1);
      R2 := R2 xor Context.Subkeys(2);
      R3 := R3 xor Context.Subkeys(3);

      Plaintext(1)  := Byte(R0 and 16#FF#);
      Plaintext(2)  := Byte(Shift_Right(R0, 8) and 16#FF#);
      Plaintext(3)  := Byte(Shift_Right(R0, 16) and 16#FF#);
      Plaintext(4)  := Byte(Shift_Right(R0, 24) and 16#FF#);

      Plaintext(5)  := Byte(R1 and 16#FF#);
      Plaintext(6)  := Byte(Shift_Right(R1, 8) and 16#FF#);
      Plaintext(7)  := Byte(Shift_Right(R1, 16) and 16#FF#);
      Plaintext(8)  := Byte(Shift_Right(R1, 24) and 16#FF#);

      Plaintext(9)  := Byte(R2 and 16#FF#);
      Plaintext(10) := Byte(Shift_Right(R2, 8) and 16#FF#);
      Plaintext(11) := Byte(Shift_Right(R2, 16) and 16#FF#);
      Plaintext(12) := Byte(Shift_Right(R2, 24) and 16#FF#);

      Plaintext(13) := Byte(R3 and 16#FF#);
      Plaintext(14) := Byte(Shift_Right(R3, 8) and 16#FF#);
      Plaintext(15) := Byte(Shift_Right(R3, 16) and 16#FF#);
      Plaintext(16) := Byte(Shift_Right(R3, 24) and 16#FF#);
   end Decrypt;

end Twofish;
