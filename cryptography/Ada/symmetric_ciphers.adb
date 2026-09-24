package body Symmetric_Ciphers is

   --  ========================================================================
   --  TEA INTERNAL HELPERS
   --  ========================================================================

   function Shift_Left (Value : Word32; Amount : Natural) return Word32 is
   begin
      return Word32 (Interfaces.Shift_Left (Interfaces.Unsigned_32 (Value), Amount));
   end Shift_Left;

   function Shift_Right (Value : Word32; Amount : Natural) return Word32 is
   begin
      return Word32 (Interfaces.Shift_Right (Interfaces.Unsigned_32 (Value), Amount));
   end Shift_Right;

   function XOR_Blocks (Left, Right : TEA_Block) return TEA_Block is
   begin
      return [Left (0) xor Right (0), Left (1) xor Right (1)];
   end XOR_Blocks;

   --  ========================================================================
   --  TEA PRIMITIVES
   --  ========================================================================

   procedure TEA_Encrypt_Block (Block : in out TEA_Block; Key : TEA_Key) is
      V0        : Word32 := Block (0);
      V1        : Word32 := Block (1);
      Sum       : Word32 := 0;
      TEA_Delta : constant Word32 := 16#9E3779B9#;
   begin
      --  Standard TEA uses 32 rounds
      for I in 1 .. 32 loop
         pragma Unreferenced (I);
         Sum := Sum + TEA_Delta;
         V0 := V0 + ((Shift_Left (V1, 4) + Key (0)) xor (V1 + Sum) xor (Shift_Right (V1, 5) + Key (1)));
         V1 := V1 + ((Shift_Left (V0, 4) + Key (2)) xor (V0 + Sum) xor (Shift_Right (V0, 5) + Key (3)));
      end loop;
      Block (0) := V0;
      Block (1) := V1;
   end TEA_Encrypt_Block;

   procedure TEA_Decrypt_Block (Block : in out TEA_Block; Key : TEA_Key) is
      V0        : Word32 := Block (0);
      V1        : Word32 := Block (1);
      TEA_Delta : constant Word32 := 16#9E3779B9#;
      Sum       : Word32 := 16#C6EF3720#; -- TEA_Delta * 32, precomputed for decryption
   begin
      --  Reversing the 32 rounds
      for I in 1 .. 32 loop
         pragma Unreferenced (I);
         V1 := V1 - ((Shift_Left (V0, 4) + Key (2)) xor (V0 + Sum) xor (Shift_Right (V0, 5) + Key (3)));
         V0 := V0 - ((Shift_Left (V1, 4) + Key (0)) xor (V1 + Sum) xor (Shift_Right (V1, 5) + Key (1)));
         Sum := Sum - TEA_Delta;
      end loop;
      Block (0) := V0;
      Block (1) := V1;
   end TEA_Decrypt_Block;

   --  ========================================================================
   --  TEA MODES OF OPERATION
   --  ========================================================================

   function TEA_Encrypt_ECB (Plaintext : TEA_Block_Array; Key : TEA_Key) return TEA_Block_Array is
      Result : TEA_Block_Array (Plaintext'Range);
   begin
      for I in Plaintext'Range loop
         Result (I) := Plaintext (I);
         TEA_Encrypt_Block (Result (I), Key);
      end loop;
      return Result;
   end TEA_Encrypt_ECB;

   function TEA_Decrypt_ECB (Ciphertext : TEA_Block_Array; Key : TEA_Key) return TEA_Block_Array is
      Result : TEA_Block_Array (Ciphertext'Range);
   begin
      for I in Ciphertext'Range loop
         Result (I) := Ciphertext (I);
         TEA_Decrypt_Block (Result (I), Key);
      end loop;
      return Result;
   end TEA_Decrypt_ECB;

   function TEA_Encrypt_CBC (Plaintext : TEA_Block_Array; Key : TEA_Key; IV : TEA_Block) return TEA_Block_Array is
      Result  : TEA_Block_Array (Plaintext'Range);
      Prev_IV : TEA_Block := IV;
   begin
      for I in Plaintext'Range loop
         Result (I) := XOR_Blocks (Plaintext (I), Prev_IV);
         TEA_Encrypt_Block (Result (I), Key);
         Prev_IV := Result (I);
      end loop;
      return Result;
   end TEA_Encrypt_CBC;

   function TEA_Decrypt_CBC (Ciphertext : TEA_Block_Array; Key : TEA_Key; IV : TEA_Block) return TEA_Block_Array is
      Result  : TEA_Block_Array (Ciphertext'Range);
      Prev_IV : TEA_Block := IV;
   begin
      for I in Ciphertext'Range loop
         Result (I) := Ciphertext (I);
         TEA_Decrypt_Block (Result (I), Key);
         Result (I) := XOR_Blocks (Result (I), Prev_IV);
         Prev_IV := Ciphertext (I);
      end loop;
      return Result;
   end TEA_Decrypt_CBC;

   --  ========================================================================
   --  STREAM CIPHER (ARC4)
   --  ========================================================================

   procedure ARC4_Init (Ctx : out ARC4_Context; Key : Byte_Array) is
      J         : Byte := 0;
      Temp      : Byte;
      Key_Index : Natural;
      Key_Len   : constant Natural := Key'Length;
   begin
      --  Key size validation: stream ciphers like RC4 require 1 to 256 bytes
      if Key_Len = 0 or Key_Len > 256 then
         raise Invalid_Key_Length;
      end if;

      --  Key-Scheduling Algorithm (KSA): initialize identity permutation
      for I in Byte'Range loop
         Ctx.S (I) := I;
      end loop;

      --  Scramble the state using the provided key
      for I in Byte'Range loop
         Key_Index := Key'First + (Natural (I) mod Key_Len);
         J := J + Ctx.S (I) + Key (Key_Index);

         --  Swap S(I) and S(J)
         Temp := Ctx.S (I);
         Ctx.S (I) := Ctx.S (J);
         Ctx.S (J) := Temp;
      end loop;

      --  Reset operational indices
      Ctx.I := 0;
      Ctx.J := 0;
   end ARC4_Init;

   procedure ARC4_Process (Ctx : in out ARC4_Context; Input : Byte_Array; Output : out Byte_Array) is
      Temp    : Byte;
      K       : Byte;
      Out_Idx : Natural := Output'First;
   begin
      --  Strict size enforcement guarantees safe array access across bounds differences
      if Input'Length /= Output'Length then
         raise Invalid_Input_Size;
      end if;

      --  Pseudo-Random Generation Algorithm (PRGA)
      for In_Idx in Input'Range loop
         Ctx.I := Ctx.I + 1;
         Ctx.J := Ctx.J + Ctx.S (Ctx.I);

         --  Swap S(I) and S(J)
         Temp := Ctx.S (Ctx.I);
         Ctx.S (Ctx.I) := Ctx.S (Ctx.J);
         Ctx.S (Ctx.J) := Temp;

         --  Generate keystream byte and XOR with plaintext/ciphertext
         K := Ctx.S (Ctx.S (Ctx.I) + Ctx.S (Ctx.J));
         Output (Out_Idx) := Input (In_Idx) xor K;

         Out_Idx := Out_Idx + 1;
      end loop;
   end ARC4_Process;

end Symmetric_Ciphers;
