package body Hash_Functions is

   -- 1. Trivial/Identity Hash
   function Identity_Hash (Key : Hash_32) return Hash_32 is
   begin
      return Key;
   end Identity_Hash;

   -- 2. Division Hash
   function Division_Hash (Key : Hash_32; M : Hash_32) return Hash_32 is
   begin
      if M = 0 then
         raise Hash_Error with "Modulo cannot be zero";
      end if;
      return Key mod M;
   end Division_Hash;

   -- 3. Mid-Square Hash
   function Mid_Square_Hash (Key : Hash_32) return Hash_32 is
      type Hash_64 is mod 2**64;
      Squared : Hash_64;
      Shifted : Hash_64;
   begin
      -- Square the 32-bit integer to a 64-bit space to prevent overflow loss
      Squared := Hash_64 (Key) * Hash_64 (Key);
      
      -- Extract the middle 32 bits (shift right 16 bits)
      Shifted := Squared / (2**16);
      
      -- Mask back down to 32 bits
      return Hash_32 (Shifted and 16#FFFF_FFFF#);
   end Mid_Square_Hash;

   -- 4. DJB2 Hash
   function DJB2_Hash (Key : String) return Hash_32 is
      Hash : Hash_32 := 5381; -- Classic magic initial value
   begin
      for I in Key'Range loop
         -- Hash := (Hash * 33) + c
         Hash := (Hash * 33) + Hash_32 (Character'Pos (Key (I)));
      end loop;
      return Hash;
   end DJB2_Hash;

   -- 5. FNV-1a Hash
   function FNV_1A_Hash (Key : String) return Hash_32 is
      FNV_Prime    : constant Hash_32 := 16#0100_0193#;
      Offset_Basis : constant Hash_32 := 16#811C_9DC5#;
      Hash         : Hash_32 := Offset_Basis;
   begin
      for I in Key'Range loop
         -- XOR byte into the bottom of the hash, then multiply by prime
         Hash := Hash xor Hash_32 (Character'Pos (Key (I)));
         Hash := Hash * FNV_Prime;
      end loop;
      return Hash;
   end FNV_1A_Hash;

   -- 6. Pearson Hash
   function Pearson_Hash (Key : String) return Hash_8 is
      Hash : Hash_8 := 0;
   begin
      for I in Key'Range loop
         -- Lookup table XOR
         Hash := Pearson_Table (Hash xor Hash_8 (Character'Pos (Key (I))));
      end loop;
      return Hash;
   end Pearson_Hash;

   -- 7. Folding Hash
   function Folding_Hash (Key : String) return Hash_32 is
      Result : Hash_32 := 0;
      Chunk  : Hash_32 := 0;
      Shift  : Natural := 0;
   begin
      for I in Key'Range loop
         -- Pack 4 characters into a 32-bit integer
         Chunk := Chunk or (Hash_32 (Character'Pos (Key (I))) * (2 ** Shift));
         Shift := Shift + 8;
         
         -- When we reach 4 bytes, add to total and reset chunk
         if Shift = 32 or else I = Key'Last then
            Result := Result + Chunk;
            Chunk  := 0;
            Shift  := 0;
         end if;
      end loop;
      return Result;
   end Folding_Hash;

end Hash_Functions;
