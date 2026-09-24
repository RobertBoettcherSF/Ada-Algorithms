with Interfaces;

package body Blake is
   use Interfaces;

   type U32_Array is array (Natural range <>) of Interfaces.Unsigned_32;
   type U64_Array is array (Natural range <>) of Interfaces.Unsigned_64;

   type Sigma_Row is array (0 .. 15) of Integer;
   type Sigma_Table is array (0 .. 9) of Sigma_Row;

   --  Message permutation matrix shared by all BLAKE variants
   Sigma : constant Sigma_Table :=
     [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
      [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
      [11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
      [7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
      [9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
      [2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
      [12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
      [13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
      [6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
      [10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0]];

   --  Constants for BLAKE-224 and BLAKE-256 (32-bit)
   C_256 : constant U32_Array (0 .. 15) :=
     [16#243F6A88#, 16#85A308D3#, 16#13198A2E#, 16#03707344#,
      16#A4093822#, 16#299F31D0#, 16#082EFA98#, 16#EC4E6C89#,
      16#452821E6#, 16#38D01377#, 16#BE5466CF#, 16#34E90C6C#,
      16#C0AC29B7#, 16#C97C50DD#, 16#3F84D5B5#, 16#B5470917#];

   IV_224 : constant U32_Array (0 .. 7) :=
     [16#C1059ED8#, 16#367CD507#, 16#3070DD17#, 16#F70E5939#,
      16#FFC00B31#, 16#68581511#, 16#64F98FA7#, 16#BEFA4FA4#];

   IV_256 : constant U32_Array (0 .. 7) :=
     [16#6A09E667#, 16#BB67AE85#, 16#3C6EF372#, 16#A54FF53A#,
      16#510E527F#, 16#9B05688C#, 16#1F83D9AB#, 16#5BE0CD19#];

   --  Constants for BLAKE-384 and BLAKE-512 (64-bit)
   C_512 : constant U64_Array (0 .. 15) :=
     [16#243F6A8885A308D3#, 16#13198A2E03707344#,
      16#A4093822299F31D0#, 16#082EFA98EC4E6C89#,
      16#452821E638D01377#, 16#BE5466CF34E90C6C#,
      16#C0AC29B7C97C50DD#, 16#3F84D5B5B5470917#,
      16#9216D5D98979FB1B#, 16#D1310BA698DFB5AC#,
      16#2FFD72DBD01ADFB7#, 16#B8E1AFED6A267E96#,
      16#BA7C9045F12C7F99#, 16#24A19947B3916CF7#,
      16#0801F2E2858EFC16#, 16#636920D871574E69#];

   IV_384 : constant U64_Array (0 .. 7) :=
     [16#CBBB9D5DC1059ED8#, 16#629A292A367CD507#,
      16#9159015A3070DD17#, 16#152FECD8F70E5939#,
      16#67332667FFC00B31#, 16#8EB44A8768581511#,
      16#DB0C2E0D64F98FA7#, 16#47B5481DBEFA4FA4#];

   IV_512 : constant U64_Array (0 .. 7) :=
     [16#6A09E667F3BCC908#, 16#BB67AE8584CAA73B#,
      16#3C6EF372FE94F82B#, 16#A54FF53A5F1D36F1#,
      16#510E527FADE682D1#, 16#9B05688C2B3E6C1F#,
      16#1F83D9ABFB41BD6B#, 16#5BE0CD19137E2179#];

   -----------------------------------------------------------------------------
   --  Compression and Hashing for 32-bit variants (BLAKE-224, BLAKE-256)
   -----------------------------------------------------------------------------

   function Create_Padded_256 (Message : Byte_Array) return Byte_Array is
      L : constant Natural := Message'Length;
      --  Padding requires: 1 bit '1', zeros to reach (L+K)*8 = 448 mod 512,
      --  followed by a 64-bit length. This perfectly translates to bytes:
      K : constant Natural := 64 - ((L + 8) mod 64);
      Padded : Byte_Array (0 .. L + K + 8 - 1) := [others => 0];
      Total_Bits : constant Interfaces.Unsigned_64 :=
        Interfaces.Unsigned_64 (L) * 8;
   begin
      --  Copy original message
      Padded (0 .. L - 1) := Message;
      --  Insert padding boundary bits
      if K = 1 then
         Padded (L) := 16#81#;
      else
         Padded (L) := 16#80#;
         Padded (L + K - 1) := 16#01#;
      end if;
      --  Append message length as 64-bit Big-Endian integer
      for I in 0 .. 7 loop
         Padded (L + K + I) :=
           Byte (Shift_Right (Total_Bits, 56 - I * 8) and 16#FF#);
      end loop;
      return Padded;
   end Create_Padded_256;

   procedure Process_Block_256 (H : in out U32_Array; M_Bytes : Byte_Array; T : Unsigned_64) is
      V : U32_Array (0 .. 15);
      M : U32_Array (0 .. 15);
      T0 : constant Unsigned_32 := Unsigned_32 (T and 16#FFFF_FFFF#);
      T1 : constant Unsigned_32 := Unsigned_32 (Shift_Right (T, 32));
   begin
      --  Parse message block as 16 little-endian 32-bit words
      for I in 0 .. 15 loop
         declare
            Base : constant Natural := M_Bytes'First + I * 4;
         begin
            M (I) := Unsigned_32 (M_Bytes (Base)) or
                     Shift_Left (Unsigned_32 (M_Bytes (Base + 1)), 8) or
                     Shift_Left (Unsigned_32 (M_Bytes (Base + 2)), 16) or
                     Shift_Left (Unsigned_32 (M_Bytes (Base + 3)), 24);
         end;
      end loop;

      --  Initialize internal state V
      V (0 .. 7) := H (0 .. 7);
      V (8 .. 11) := C_256 (0 .. 3);
      V (12) := T0 xor C_256 (4);
      V (13) := T0 xor C_256 (5);
      V (14) := T1 xor C_256 (6);
      V (15) := T1 xor C_256 (7);

      --  14 Rounds of cryptographic mixing
      for R in 0 .. 13 loop
         declare
            SR : Sigma_Row renames Sigma (R mod 10);
            procedure G (A, B, C, D, I : Integer) is
               M1 : constant Unsigned_32 := M (SR (2 * I));
               M2 : constant Unsigned_32 := M (SR (2 * I + 1));
               C1 : constant Unsigned_32 := C_256 (SR (2 * I + 1));
               C2 : constant Unsigned_32 := C_256 (SR (2 * I));
            begin
               V (A) := V (A) + V (B) + (M1 xor C1);
               V (D) := Rotate_Right (V (D) xor V (A), 16);
               V (C) := V (C) + V (D);
               V (B) := Rotate_Right (V (B) xor V (C), 12);
               V (A) := V (A) + V (B) + (M2 xor C2);
               V (D) := Rotate_Right (V (D) xor V (A), 8);
               V (C) := V (C) + V (D);
               V (B) := Rotate_Right (V (B) xor V (C), 7);
            end G;
         begin
            --  Column steps
            G (0, 4, 8, 12, 0);
            G (1, 5, 9, 13, 1);
            G (2, 6, 10, 14, 2);
            G (3, 7, 11, 15, 3);
            --  Diagonal steps
            G (0, 5, 10, 15, 4);
            G (1, 6, 11, 12, 5);
            G (2, 7, 8, 13, 6);
            G (3, 4, 9, 14, 7);
         end;
      end loop;

      --  Update chaining value H (Assuming Salt is 0)
      for I in 0 .. 7 loop
         H (I) := H (I) xor V (I) xor V (I + 8);
      end loop;
   end Process_Block_256;

   procedure State_To_Digest_256 (H : U32_Array; D : out Digest_256) is
   begin
      --  Serialize digest as Big-Endian bytes
      for I in 0 .. 7 loop
         D (I * 4 + 0) := Byte (Shift_Right (H (I), 24) and 16#FF#);
         D (I * 4 + 1) := Byte (Shift_Right (H (I), 16) and 16#FF#);
         D (I * 4 + 2) := Byte (Shift_Right (H (I), 8) and 16#FF#);
         D (I * 4 + 3) := Byte (H (I) and 16#FF#);
      end loop;
   end State_To_Digest_256;

   function Hash_Generic_256 (Message : Byte_Array; IV : U32_Array) return Digest_256 is
      Padded     : constant Byte_Array := Create_Padded_256 (Message);
      Num_Blocks : constant Natural := Padded'Length / 64;
      H          : U32_Array (0 .. 7) := IV;
      Total_Bits : constant Unsigned_64 := Unsigned_64 (Message'Length) * 8;
      D          : Digest_256;
   begin
      for B in 0 .. Num_Blocks - 1 loop
         declare
            --  Counter T represents the number of message bits mapped so far.
            --  It maxes out at the original Total_Bits for padding-only blocks.
            Block_End : constant Unsigned_64 := Unsigned_64 (B + 1) * 512;
            T         : constant Unsigned_64 := (if Block_End < Total_Bits then Block_End else Total_Bits);
            Block     : constant Byte_Array := Padded (Padded'First + B * 64 .. Padded'First + B * 64 + 63);
         begin
            Process_Block_256 (H, Block, T);
         end;
      end loop;
      State_To_Digest_256 (H, D);
      return D;
   end Hash_Generic_256;

   function Hash_224 (Message : Byte_Array) return Digest_224 is
      Full : constant Digest_256 := Hash_Generic_256 (Message, IV_224);
   begin
      return Full (0 .. 27); -- Truncate output per spec
   end Hash_224;

   function Hash_256 (Message : Byte_Array) return Digest_256 is
   begin
      return Hash_Generic_256 (Message, IV_256);
   end Hash_256;

   -----------------------------------------------------------------------------
   --  Compression and Hashing for 64-bit variants (BLAKE-384, BLAKE-512)
   -----------------------------------------------------------------------------

   function Create_Padded_512 (Message : Byte_Array) return Byte_Array is
      L : constant Natural := Message'Length;
      --  Padding: 1 bit '1', zeros to reach (L+K)*8 = 896 mod 1024,
      --  followed by a 128-bit length.
      K : constant Natural := 128 - ((L + 16) mod 128);
      Padded : Byte_Array (0 .. L + K + 16 - 1) := [others => 0];
      Total_Bits : constant Interfaces.Unsigned_64 :=
        Interfaces.Unsigned_64 (L) * 8;
   begin
      Padded (0 .. L - 1) := Message;
      if K = 1 then
         Padded (L) := 16#81#;
      else
         Padded (L) := 16#80#;
         Padded (L + K - 1) := 16#01#;
      end if;
      --  Append message length as 128-bit Big-Endian integer.
      --  Since Ada string length * 8 easily fits in 64 bits, high 64-bits are 0.
      for I in 0 .. 7 loop
         Padded (L + K + I) := 0;
      end loop;
      for I in 0 .. 7 loop
         Padded (L + K + 8 + I) :=
           Byte (Shift_Right (Total_Bits, 56 - I * 8) and 16#FF#);
      end loop;
      return Padded;
   end Create_Padded_512;

   procedure Process_Block_512 (H : in out U64_Array; M_Bytes : Byte_Array; T : Unsigned_64) is
      V : U64_Array (0 .. 15);
      M : U64_Array (0 .. 15);
      --  128-bit counter, high part is 0 for our input sizes
      T_Low  : constant Unsigned_64 := T;
      T_High : constant Unsigned_64 := 0;
   begin
      --  Parse message block as 16 little-endian 64-bit words
      for I in 0 .. 15 loop
         declare
            Base : constant Natural := M_Bytes'First + I * 8;
         begin
            M (I) := Unsigned_64 (M_Bytes (Base)) or
                     Shift_Left (Unsigned_64 (M_Bytes (Base + 1)), 8) or
                     Shift_Left (Unsigned_64 (M_Bytes (Base + 2)), 16) or
                     Shift_Left (Unsigned_64 (M_Bytes (Base + 3)), 24) or
                     Shift_Left (Unsigned_64 (M_Bytes (Base + 4)), 32) or
                     Shift_Left (Unsigned_64 (M_Bytes (Base + 5)), 40) or
                     Shift_Left (Unsigned_64 (M_Bytes (Base + 6)), 48) or
                     Shift_Left (Unsigned_64 (M_Bytes (Base + 7)), 56);
         end;
      end loop;

      --  Initialize internal state V
      V (0 .. 7) := H (0 .. 7);
      V (8 .. 11) := C_512 (0 .. 3);
      V (12) := T_Low  xor C_512 (4);
      V (13) := T_Low  xor C_512 (5);
      V (14) := T_High xor C_512 (6);
      V (15) := T_High xor C_512 (7);

      --  16 Rounds of cryptographic mixing for 512
      for R in 0 .. 15 loop
         declare
            SR : Sigma_Row renames Sigma (R mod 10);
            procedure G (A, B, C, D, I : Integer) is
               M1 : constant Unsigned_64 := M (SR (2 * I));
               M2 : constant Unsigned_64 := M (SR (2 * I + 1));
               C1 : constant Unsigned_64 := C_512 (SR (2 * I + 1));
               C2 : constant Unsigned_64 := C_512 (SR (2 * I));
            begin
               V (A) := V (A) + V (B) + (M1 xor C1);
               V (D) := Rotate_Right (V (D) xor V (A), 32);
               V (C) := V (C) + V (D);
               V (B) := Rotate_Right (V (B) xor V (C), 25);
               V (A) := V (A) + V (B) + (M2 xor C2);
               V (D) := Rotate_Right (V (D) xor V (A), 16);
               V (C) := V (C) + V (D);
               V (B) := Rotate_Right (V (B) xor V (C), 11);
            end G;
         begin
            --  Column steps
            G (0, 4, 8, 12, 0);
            G (1, 5, 9, 13, 1);
            G (2, 6, 10, 14, 2);
            G (3, 7, 11, 15, 3);
            --  Diagonal steps
            G (0, 5, 10, 15, 4);
            G (1, 6, 11, 12, 5);
            G (2, 7, 8, 13, 6);
            G (3, 4, 9, 14, 7);
         end;
      end loop;

      --  Update chaining value H (Assuming Salt is 0)
      for I in 0 .. 7 loop
         H (I) := H (I) xor V (I) xor V (I + 8);
      end loop;
   end Process_Block_512;

   procedure State_To_Digest_512 (H : U64_Array; D : out Digest_512) is
   begin
      --  Serialize digest as Big-Endian bytes
      for I in 0 .. 7 loop
         for J in 0 .. 7 loop
            D (I * 8 + J) := Byte (Shift_Right (H (I), 56 - J * 8) and 16#FF#);
         end loop;
      end loop;
   end State_To_Digest_512;

   function Hash_Generic_512 (Message : Byte_Array; IV : U64_Array) return Digest_512 is
      Padded     : constant Byte_Array := Create_Padded_512 (Message);
      Num_Blocks : constant Natural := Padded'Length / 128;
      H          : U64_Array (0 .. 7) := IV;
      Total_Bits : constant Unsigned_64 := Unsigned_64 (Message'Length) * 8;
      D          : Digest_512;
   begin
      for B in 0 .. Num_Blocks - 1 loop
         declare
            Block_End : constant Unsigned_64 := Unsigned_64 (B + 1) * 1024;
            T         : constant Unsigned_64 := (if Block_End < Total_Bits then Block_End else Total_Bits);
            Block     : constant Byte_Array := Padded (Padded'First + B * 128 .. Padded'First + B * 128 + 127);
         begin
            Process_Block_512 (H, Block, T);
         end;
      end loop;
      State_To_Digest_512 (H, D);
      return D;
   end Hash_Generic_512;

   function Hash_384 (Message : Byte_Array) return Digest_384 is
      Full : constant Digest_512 := Hash_Generic_512 (Message, IV_384);
   begin
      return Full (0 .. 47); -- Truncate output per spec
   end Hash_384;

   function Hash_512 (Message : Byte_Array) return Digest_512 is
   begin
      return Hash_Generic_512 (Message, IV_512);
   end Hash_512;

end Blake;
