package body Message_Authentication_Code is

   -----------------------------------------------------------------------------
   --  Internal Helper: Bitwise XOR for Blocks
   -----------------------------------------------------------------------------
   function XOR_Blocks (L, R : Block_Array) return Block_Array is
      Result : Block_Array;
   begin
      for I in Block_Array'Range loop
         Result (I) := L (I) xor R (I);
      end loop;
      return Result;
   end XOR_Blocks;

   -----------------------------------------------------------------------------
   --  Primitive: Simple Custom Hash Function
   --  Processes data in 16-byte chunks.
   -----------------------------------------------------------------------------
   function Simple_Hash (Message : Byte_Array) return Hash_Array is
      State : Hash_Array := [others => 16#A5#]; -- Initial fixed state
      I     : Positive   := Message'First;
      Len   : Natural    := Message'Length;
      Chunk : Hash_Array;

      --  Helper to diffuse bits extensively across the state
      procedure Mix (S : in out Hash_Array) is
         T : Hash_Array;
      begin
         for Pass in 1 .. 4 loop
            T := S;
            for J in 1 .. Hash_Output_Size loop
               S (J) := T (if J = Hash_Output_Size then 1 else J + 1) + T (J);
               S (J) := (S (J) * 8) or (S (J) / 32); -- Rotate left by 3
               S (J) := S (J) xor 16#33#;
            end loop;
         end loop;
      end Mix;
   begin
      --  Process full blocks iteratively
      while Len >= Hash_Block_Size loop
         for J in 1 .. Hash_Block_Size loop
            Chunk (J) := Message (I + J - 1);
         end loop;

         State := XOR_Blocks (State, Chunk);
         Mix (State);

         I   := I + Hash_Block_Size;
         Len := Len - Hash_Block_Size;
      end loop;

      --  Process final remaining bytes with standard 0x80 padding
      Chunk := [others => 0];
      for J in 1 .. Len loop
         Chunk (J) := Message (I + J - 1);
      end loop;
      
      --  Append 16#80# marker
      Chunk (Len + 1) := 16#80#;

      State := XOR_Blocks (State, Chunk);
      Mix (State);

      return State;
   end Simple_Hash;

   -----------------------------------------------------------------------------
   --  Primitive: Simple 10-Round Block Cipher
   -----------------------------------------------------------------------------
   function Simple_Encrypt (Key : Block_Array; Block : Block_Array) return Block_Array is
      State : Block_Array := Block;
      Temp  : Block_Array;
   begin
      for Round in 1 .. 10 loop
         State := XOR_Blocks (State, Key);
         Temp  := State;
         for J in Block_Array'Range loop
            --  Add adjacent byte to ensure cascade/diffusion across the block
            State (J) := Temp (J) + Temp (if J = 1 then Block_Array'Last else J - 1);
            --  Modular left rotate by 3 bits and round constant addition
            State (J) := ((State (J) * 8) or (State (J) / 32)) xor Byte (Round);
         end loop;
      end loop;
      return State;
   end Simple_Encrypt;

   -----------------------------------------------------------------------------
   --  Variant 1: HMAC (Hash-based Message Authentication Code)
   -----------------------------------------------------------------------------
   function HMAC
     (Key     : Byte_Array;
      Message : Byte_Array) return Hash_Array
   is
      K         : Block_Array := [others => 0];
      I_Pad     : constant Block_Array := [others => 16#36#];
      O_Pad     : constant Block_Array := [others => 16#5C#];
      I_Key_Pad : Block_Array;
      O_Key_Pad : Block_Array;
      
      Inner_Hash : Hash_Array;
      Inner_Msg  : Byte_Array (1 .. Hash_Block_Size + Message'Length);
      Outer_Msg  : Byte_Array (1 .. Hash_Block_Size + Hash_Output_Size);
   begin
      if Key'Length = 0 then
         raise Invalid_Key_Error with "HMAC key cannot be empty";
      end if;

      --  1. Pad or hash the key to fit the block size exactly
      if Key'Length > Hash_Block_Size then
         K (1 .. Hash_Output_Size) := Simple_Hash (Key);
      else
         for J in 1 .. Key'Length loop
            K (J) := Key (Key'First + J - 1);
         end loop;
      end if;

      --  2. Compute inner and outer padded keys
      I_Key_Pad := XOR_Blocks (K, I_Pad);
      O_Key_Pad := XOR_Blocks (K, O_Pad);

      --  3. Execute Inner Hash: Hash(I_Key_Pad || Message)
      Inner_Msg (1 .. Hash_Block_Size) := I_Key_Pad;
      for J in 1 .. Message'Length loop
         Inner_Msg (Hash_Block_Size + J) := Message (Message'First + J - 1);
      end loop;
      Inner_Hash := Simple_Hash (Inner_Msg);

      --  4. Execute Outer Hash: Hash(O_Key_Pad || Inner_Hash)
      Outer_Msg (1 .. Hash_Block_Size) := O_Key_Pad;
      for J in 1 .. Hash_Output_Size loop
         Outer_Msg (Hash_Block_Size + J) := Inner_Hash (J);
      end loop;

      return Simple_Hash (Outer_Msg);
   end HMAC;

   -----------------------------------------------------------------------------
   --  Variant 2: CBC-MAC (Cipher Block Chaining MAC)
   -----------------------------------------------------------------------------
   function CBC_MAC
     (Key     : Block_Array;
      Message : Byte_Array) return Block_Array
   is
      State : Block_Array := [others => 0];
      I     : Positive;
      Len   : Natural;
      Chunk : Block_Array;
   begin
      if Message'Length = 0 then
         raise Invalid_Message_Error with "CBC-MAC message cannot be empty";
      end if;

      I   := Message'First;
      Len := Message'Length;

      --  Process all fully formed blocks
      while Len >= Hash_Block_Size loop
         for J in 1 .. Hash_Block_Size loop
            Chunk (J) := Message (I + J - 1);
         end loop;
         
         State := XOR_Blocks (State, Chunk);
         State := Simple_Encrypt (Key, State);
         
         I   := I + Hash_Block_Size;
         Len := Len - Hash_Block_Size;
      end loop;

      --  Apply Padding block (append 0x80, followed by zeroes to fill block)
      --  Note: Even if exact multiple, standard CBC-MAC often appends a padded
      --  block to prevent length extension vulnerabilities.
      Chunk := [others => 0];
      for J in 1 .. Len loop
         Chunk (J) := Message (I + J - 1);
      end loop;
      Chunk (Len + 1) := 16#80#;
      
      State := XOR_Blocks (State, Chunk);
      State := Simple_Encrypt (Key, State);

      return State;
   end CBC_MAC;

   -----------------------------------------------------------------------------
   --  Variant 3: Prefix-MAC (Secret Prefix MAC)
   -----------------------------------------------------------------------------
   function Prefix_MAC
     (Key     : Byte_Array;
      Message : Byte_Array) return Hash_Array
   is
      Msg : Byte_Array (1 .. Key'Length + Message'Length);
   begin
      if Key'Length = 0 then
         raise Invalid_Key_Error with "Prefix-MAC key cannot be empty";
      end if;
      
      --  Concatenate Key and Message
      for J in 1 .. Key'Length loop
         Msg (J) := Key (Key'First + J - 1);
      end loop;
      
      for J in 1 .. Message'Length loop
         Msg (Key'Length + J) := Message (Message'First + J - 1);
      end loop;
      
      return Simple_Hash (Msg);
   end Prefix_MAC;

end Message_Authentication_Code;
