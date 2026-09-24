package body IDEA is

   -----------------------------------------------------------------------------
   -- Mathematical Helpers
   -----------------------------------------------------------------------------

   function Mul (A, B : Word16) return Word16 is
      -- Use 64-bit intermediate type to prevent overflow. 65536 * 65536 = 2**32
      -- which overflows a 32-bit modular integer to exactly 0 before modulo.
      type Word64 is mod 2**64;
      A64 : constant Word64 := (if A = 0 then 65536 else Word64 (A));
      B64 : constant Word64 := (if B = 0 then 65536 else Word64 (B));
      P64 : constant Word64 := (A64 * B64) mod 65537;
   begin
      -- Result of 65536 maps back to 0.
      return (if P64 = 65536 then 0 else Word16 (P64));
   end Mul;

   function Add_Inv (X : Word16) return Word16 is
   begin
      -- The modular type handles the two's complement inversion correctly.
      return (-X);
   end Add_Inv;

   function Mul_Inv (X : Word16) return Word16 is
      -- Calculates the multiplicative inverse modulo 65537 using the
      -- Extended Euclidean Algorithm.
      T     : Integer := 0;
      New_T : Integer := 1;
      R     : Integer := 65537;
      New_R : Integer := (if X = 0 then 65536 else Integer (X));
      Q     : Integer;
      Temp  : Integer;
   begin
      while New_R /= 0 loop
         Q := R / New_R;

         Temp := T - Q * New_T;
         T := New_T;
         New_T := Temp;

         Temp := R - Q * New_R;
         R := New_R;
         New_R := Temp;
      end loop;

      if T < 0 then
         T := T + 65537;
      end if;

      if T = 65536 then
         return 0;
      else
         return Word16 (T);
      end if;
   end Mul_Inv;

   function Parse_Key (Hex : String) return Key_Block is
      Result : Key_Block;
      Temp   : Integer;
   begin
      if Hex'Length /= 32 then
         raise Invalid_Key_Format with "Key must be exactly 32 hexadecimal characters.";
      end if;

      for I in 1 .. 8 loop
         begin
            Temp := Integer'Value ("16#" & Hex (Hex'First + (I - 1) * 4 .. Hex'First + (I - 1) * 4 + 3) & "#");
            Result (I) := Word16 (Temp);
         exception
            when Constraint_Error =>
               raise Invalid_Key_Format with "Non-hexadecimal character detected in key.";
         end;
      end loop;

      return Result;
   end Parse_Key;

   -----------------------------------------------------------------------------
   -- Key Schedule Generation
   -----------------------------------------------------------------------------

   -- Rotates a 128-bit key (represented as 8x16-bit blocks) left by 25 bits.
   function Rotate_Left_25 (K : Key_Block) return Key_Block is
      Result : Key_Block;
      Idx1   : Integer;
      Idx2   : Integer;
   begin
      for I in 1 .. 8 loop
         Idx1 := (I mod 8) + 1;
         Idx2 := ((I + 1) mod 8) + 1;
         -- A left shift of 25 bits across 16-bit boundaries maps cleanly to:
         -- (Next_Word << 9) OR (Word_After_Next >> 7)
         Result (I) := (K (Idx1) * 512) or (K (Idx2) / 128);
      end loop;
      return Result;
   end Rotate_Left_25;

   function Generate_Encryption_Keys (Key : Key_Block) return Subkey_Array is
      Subkeys     : Subkey_Array;
      Current_Key : Key_Block := Key;
      Idx         : Positive := 1;
   begin
      -- Generate keys in 7 batches of 8, terminating at 52 keys.
      for Group in 0 .. 6 loop
         for J in 1 .. 8 loop
            if Idx <= 52 then
               Subkeys (Idx) := Current_Key (J);
               Idx := Idx + 1;
            end if;
         end loop;
         Current_Key := Rotate_Left_25 (Current_Key);
      end loop;
      return Subkeys;
   end Generate_Encryption_Keys;

   function Generate_Decryption_Keys (Encrypt_Keys : Subkey_Array) return Subkey_Array is
      D     : Subkey_Array;
      Idx_E : Positive;
   begin
      -- Decryption keys are derived by reversing the encryption keys, applying
      -- multiplicative/additive inverses, and compensating for block swapping.

      -- Round 1 (Undo Half-Round 9)
      D (1) := Mul_Inv (Encrypt_Keys (49));
      D (2) := Add_Inv (Encrypt_Keys (50));
      D (3) := Add_Inv (Encrypt_Keys (51));
      D (4) := Mul_Inv (Encrypt_Keys (52));
      D (5) := Encrypt_Keys (47);
      D (6) := Encrypt_Keys (48);

      -- Rounds 2 through 8 (Undo Rounds 8 through 2)
      for R in 2 .. 8 loop
         Idx_E := (9 - R) * 6 + 1;
         D ((R - 1) * 6 + 1) := Mul_Inv (Encrypt_Keys (Idx_E));
         D ((R - 1) * 6 + 2) := Add_Inv (Encrypt_Keys (Idx_E + 2)); -- Swap inner keys
         D ((R - 1) * 6 + 3) := Add_Inv (Encrypt_Keys (Idx_E + 1)); -- Swap inner keys
         D ((R - 1) * 6 + 4) := Mul_Inv (Encrypt_Keys (Idx_E + 3));
         D ((R - 1) * 6 + 5) := Encrypt_Keys (Idx_E - 2);
         D ((R - 1) * 6 + 6) := Encrypt_Keys (Idx_E - 1);
      end loop;

      -- Round 9 (Undo Round 1)
      D (49) := Mul_Inv (Encrypt_Keys (1));
      D (50) := Add_Inv (Encrypt_Keys (2)); -- No swap for the final stage
      D (51) := Add_Inv (Encrypt_Keys (3));
      D (52) := Mul_Inv (Encrypt_Keys (4));

      return D;
   end Generate_Decryption_Keys;

   -----------------------------------------------------------------------------
   -- Core Cipher Logic
   -----------------------------------------------------------------------------

   procedure Round (X1, X2, X3, X4 : in out Word16;
                    K1, K2, K3, K4, K5, K6 : Word16) is
      Y1, Y2, Y3, Y4, Y5, Y6, Y7, Y8, Y9, Y10 : Word16;
   begin
      Y1 := Mul (X1, K1);
      Y2 := X2 + K2;
      Y3 := X3 + K3;
      Y4 := Mul (X4, K4);

      Y5 := Y1 xor Y3;
      Y6 := Y2 xor Y4;

      Y7 := Mul (Y5, K5);
      Y8 := Y6 + Y7;
      Y9 := Mul (Y8, K6);
      Y10 := Y7 + Y9;

      -- X2 and X3 effectively swap paths here
      X1 := Y1 xor Y9;
      X2 := Y3 xor Y9;
      X3 := Y2 xor Y10;
      X4 := Y4 xor Y10;
   end Round;

   procedure Half_Round (X1, X2, X3, X4 : in out Word16;
                         K1, K2, K3, K4 : Word16) is
      T1, T2, T3, T4 : Word16;
   begin
      -- Un-swap X2 and X3 before final output logic
      T1 := Mul (X1, K1);
      T2 := X3 + K2;
      T3 := X2 + K3;
      T4 := Mul (X4, K4);

      X1 := T1;
      X2 := T2;
      X3 := T3;
      X4 := T4;
   end Half_Round;

   procedure Process_Block (Data    : in out Data_Block;
                            Subkeys : in Subkey_Array) is
      X1, X2, X3, X4 : Word16;
      K_Idx          : Positive := 1;
   begin
      X1 := Data (1);
      X2 := Data (2);
      X3 := Data (3);
      X4 := Data (4);

      -- Apply 8 full rounds
      for R in 1 .. 8 loop
         Round (X1, X2, X3, X4,
                Subkeys (K_Idx),     Subkeys (K_Idx + 1),
                Subkeys (K_Idx + 2), Subkeys (K_Idx + 3),
                Subkeys (K_Idx + 4), Subkeys (K_Idx + 5));
         K_Idx := K_Idx + 6;
      end loop;

      -- Apply the final half-round transformation
      Half_Round (X1, X2, X3, X4,
                  Subkeys (K_Idx),     Subkeys (K_Idx + 1),
                  Subkeys (K_Idx + 2), Subkeys (K_Idx + 3));

      Data (1) := X1;
      Data (2) := X2;
      Data (3) := X3;
      Data (4) := X4;
   end Process_Block;

   procedure Encrypt_Block (Data : in out Data_Block; Key : in Key_Block) is
      Subkeys : constant Subkey_Array := Generate_Encryption_Keys (Key);
   begin
      Process_Block (Data, Subkeys);
   end Encrypt_Block;

   procedure Decrypt_Block (Data : in out Data_Block; Key : in Key_Block) is
      Enc_Keys : constant Subkey_Array := Generate_Encryption_Keys (Key);
      Dec_Keys : constant Subkey_Array := Generate_Decryption_Keys (Enc_Keys);
   begin
      Process_Block (Data, Dec_Keys);
   end Decrypt_Block;

end IDEA;
