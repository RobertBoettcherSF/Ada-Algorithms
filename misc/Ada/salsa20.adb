with Interfaces; use Interfaces;

package body Salsa20 is

   -- Constants for 256-bit and 128-bit key expansion strings ("expand 32-byte k" and "expand 16-byte k")
   Sigma_0 : constant Word := 16#61707865#; -- "expa"
   Sigma_1 : constant Word := 16#3320646e#; -- "nd 3"
   Sigma_2 : constant Word := 16#79622d32#; -- "2-by"
   Sigma_3 : constant Word := 16#6b206574#; -- "te k"

   Tau_0   : constant Word := 16#61707865#; -- "expa"
   Tau_1   : constant Word := 16#3120646e#; -- "nd 1"
   Tau_2   : constant Word := 16#79622d36#; -- "6-by"
   Tau_3   : constant Word := 16#6b206574#; -- "te k"

   -- Helper: Little-endian conversion of 4 bytes to Word (32-bit unsigned)
   -- Using B'First handles Ada's array sliding preservation when slices are passed
   function Bytes_To_Word (B : Byte_Array) return Word is
      F : constant Natural := B'First;
   begin
      return Word (B (F)) or
            (Word (B (F + 1)) * 2**8) or
            (Word (B (F + 2)) * 2**16) or
            (Word (B (F + 3)) * 2**24);
   end Bytes_To_Word;

   -- Helper: Little-endian conversion of Word to 4 bytes
   procedure Word_To_Bytes (W : Word; B : in out Block_Bytes; Offset : Natural) is
   begin
      B (Offset)     := Byte (W and 16#FF#);
      B (Offset + 1) := Byte (Shift_Right (W, 8) and 16#FF#);
      B (Offset + 2) := Byte (Shift_Right (W, 16) and 16#FF#);
      B (Offset + 3) := Byte (Shift_Right (W, 24) and 16#FF#);
   end Word_To_Bytes;

   -- Quarter Round operation as specified in Salsa20 (ARX: Add-Rotate-XOR)
   procedure Quarter_Round (Y0, Y1, Y2, Y3 : in out Word) is
   begin
      Y1 := Y1 xor Rotate_Left (Y0 + Y3, 7);
      Y2 := Y2 xor Rotate_Left (Y1 + Y0, 9);
      Y3 := Y3 xor Rotate_Left (Y2 + Y1, 13);
      Y0 := Y0 xor Rotate_Left (Y3 + Y2, 18);
   end Quarter_Round;

   -- Salsa20 core function transforming a 16-word state
   procedure Salsa20_Core (In_State : in Word_Array; Out_State : out Word_Array; Rounds : Positive) is
      St : Word_Array := In_State;
   begin
      if Rounds mod 2 /= 0 then
         raise Invalid_Round_Count;
      end if;

      for R in 1 .. Rounds / 2 loop
         -- Column round
         Quarter_Round (St (0), St (4), St (8), St (12));
         Quarter_Round (St (5), St (9), St (13), St (1));
         Quarter_Round (St (10), St (14), St (2), St (6));
         Quarter_Round (St (15), St (3), St (7), St (11));
         -- Row round
         Quarter_Round (St (0), St (1), St (2), St (3));
         Quarter_Round (St (5), St (6), St (7), St (4));
         Quarter_Round (St (10), St (11), St (8), St (9));
         Quarter_Round (St (15), St (12), St (13), St (14));
      end loop;

      for I in St'Range loop
         Out_State (I) := St (I) + In_State (I);
      end loop;
   end Salsa20_Core;

   -- Generate a single 64-byte keystream block for 256-bit key
   procedure Generate_Block (
      Rounds  : in Positive;
      Key     : in Key_256;
      Nonce   : in Nonce_64;
      Counter : in Unsigned_64;
      Block   : out Block_Bytes
   ) is
      St     : Word_Array;
      Out_St : Word_Array;
   begin
      if Rounds mod 2 /= 0 then
         raise Invalid_Round_Count;
      end if;

      -- Construct initial 16-word state for 256-bit key
      St (0)  := Sigma_0;
      St (1)  := Bytes_To_Word (Byte_Array (Key (0 .. 3)));
      St (2)  := Bytes_To_Word (Byte_Array (Key (4 .. 7)));
      St (3)  := Bytes_To_Word (Byte_Array (Key (8 .. 11)));
      St (4)  := Bytes_To_Word (Byte_Array (Key (12 .. 15)));
      St (5)  := Sigma_1;
      St (6)  := Bytes_To_Word (Byte_Array (Nonce (0 .. 3)));
      St (7)  := Bytes_To_Word (Byte_Array (Nonce (4 .. 7)));
      St (8)  := Unsigned_32 (Counter and 16#FFFFFFFF#);
      St (9)  := Unsigned_32 (Shift_Right (Counter, 32) and 16#FFFFFFFF#);
      St (10) := Sigma_2;
      St (11) := Bytes_To_Word (Byte_Array (Key (16 .. 19)));
      St (12) := Bytes_To_Word (Byte_Array (Key (20 .. 23)));
      St (13) := Bytes_To_Word (Byte_Array (Key (24 .. 27)));
      St (14) := Bytes_To_Word (Byte_Array (Key (28 .. 31)));
      St (15) := Sigma_3;

      Salsa20_Core (St, Out_St, Rounds);

      for I in 0 .. 15 loop
         Word_To_Bytes (Out_St (I), Block, I * 4);
      end loop;
   end Generate_Block;

   -- Helper for 128-bit key block generation
   procedure Generate_Block_128 (
      Rounds  : in Positive;
      Key     : in Key_128;
      Nonce   : in Nonce_64;
      Counter : in Unsigned_64;
      Block   : out Block_Bytes
   ) is
      St     : Word_Array;
      Out_St : Word_Array;
   begin
      if Rounds mod 2 /= 0 then
         raise Invalid_Round_Count;
      end if;

      -- Construct initial 16-word state for 128-bit key (repeats key and uses tau constants)
      St (0)  := Tau_0;
      St (1)  := Bytes_To_Word (Byte_Array (Key (0 .. 3)));
      St (2)  := Bytes_To_Word (Byte_Array (Key (4 .. 7)));
      St (3)  := Bytes_To_Word (Byte_Array (Key (8 .. 11)));
      St (4)  := Bytes_To_Word (Byte_Array (Key (12 .. 15)));
      St (5)  := Tau_1;
      St (6)  := Bytes_To_Word (Byte_Array (Nonce (0 .. 3)));
      St (7)  := Bytes_To_Word (Byte_Array (Nonce (4 .. 7)));
      St (8)  := Unsigned_32 (Counter and 16#FFFFFFFF#);
      St (9)  := Unsigned_32 (Shift_Right (Counter, 32) and 16#FFFFFFFF#);
      St (10) := Tau_2;
      St (11) := Bytes_To_Word (Byte_Array (Key (0 .. 3)));
      St (12) := Bytes_To_Word (Byte_Array (Key (4 .. 7)));
      St (13) := Bytes_To_Word (Byte_Array (Key (8 .. 11)));
      St (14) := Bytes_To_Word (Byte_Array (Key (12 .. 15)));
      St (15) := Tau_3;

      Salsa20_Core (St, Out_St, Rounds);

      for I in 0 .. 15 loop
         Word_To_Bytes (Out_St (I), Block, I * 4);
      end loop;
   end Generate_Block_128;

   -- General encryption / decryption engine for 256-bit key
   procedure Encrypt_General (
      Rounds  : in Positive;
      Key     : in Key_256;
      Nonce   : in Nonce_64;
      Counter : in Unsigned_64;
      Input   : in Byte_Array;
      Output  : out Byte_Array
   ) is
      Cur_Counter : Unsigned_64 := Counter;
      Block       : Block_Bytes;
      Bytes_Left  : Natural := Input'Length;
      Input_Idx   : Natural := Input'First;
      Output_Idx  : Natural := Output'First;
      Chunk_Size  : Natural;
   begin
      if Rounds mod 2 /= 0 then
         raise Invalid_Round_Count;
      end if;

      if Input'Length /= Output'Length then
         raise Invalid_Data_Length;
      end if;

      while Bytes_Left > 0 loop
         Generate_Block (Rounds, Key, Nonce, Cur_Counter, Block);
         if Bytes_Left >= 64 then
            Chunk_Size := 64;
         else
            Chunk_Size := Bytes_Left;
         end if;

         for I in 0 .. Chunk_Size - 1 loop
            Output (Output_Idx + I) := Input (Input_Idx + I) xor Block (I);
         end loop;

         Bytes_Left  := Bytes_Left - Chunk_Size;
         Input_Idx   := Input_Idx + Chunk_Size;
         Output_Idx  := Output_Idx + Chunk_Size;
         Cur_Counter := Cur_Counter + 1;
      end loop;
   end Encrypt_General;

   -- Specific variant wrappers
   procedure Encrypt_256_20 (
      Key     : in Key_256;
      Nonce   : in Nonce_64;
      Counter : in Unsigned_64;
      Input   : in Byte_Array;
      Output  : out Byte_Array
   ) is
   begin
      Encrypt_General (20, Key, Nonce, Counter, Input, Output);
   end Encrypt_256_20;

   procedure Encrypt_256_12 (
      Key     : in Key_256;
      Nonce   : in Nonce_64;
      Counter : in Unsigned_64;
      Input   : in Byte_Array;
      Output  : out Byte_Array
   ) is
   begin
      Encrypt_General (12, Key, Nonce, Counter, Input, Output);
   end Encrypt_256_12;

   procedure Encrypt_256_8 (
      Key     : in Key_256;
      Nonce   : in Nonce_64;
      Counter : in Unsigned_64;
      Input   : in Byte_Array;
      Output  : out Byte_Array
   ) is
   begin
      Encrypt_General (8, Key, Nonce, Counter, Input, Output);
   end Encrypt_256_8;

   procedure Encrypt_128_20 (
      Key     : in Key_128;
      Nonce   : in Nonce_64;
      Counter : in Unsigned_64;
      Input   : in Byte_Array;
      Output  : out Byte_Array
   ) is
      Cur_Counter : Unsigned_64 := Counter;
      Block       : Block_Bytes;
      Bytes_Left  : Natural := Input'Length;
      Input_Idx   : Natural := Input'First;
      Output_Idx  : Natural := Output'First;
      Chunk_Size  : Natural;
   begin
      if Input'Length /= Output'Length then
         raise Invalid_Data_Length;
      end if;

      while Bytes_Left > 0 loop
         Generate_Block_128 (20, Key, Nonce, Cur_Counter, Block);
         if Bytes_Left >= 64 then
            Chunk_Size := 64;
         else
            Chunk_Size := Bytes_Left;
         end if;

         for I in 0 .. Chunk_Size - 1 loop
            Output (Output_Idx + I) := Input (Input_Idx + I) xor Block (I);
         end loop;

         Bytes_Left  := Bytes_Left - Chunk_Size;
         Input_Idx   := Input_Idx + Chunk_Size;
         Output_Idx  := Output_Idx + Chunk_Size;
         Cur_Counter := Cur_Counter + 1;
      end loop;
   end Encrypt_128_20;

end Salsa20;
