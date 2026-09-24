package body HMAC is

   package body Core is

      -- Magic padding constants defined by RFC 2104
      Ipad : constant Byte := 16#36#;
      Opad : constant Byte := 16#5C#;

      -------------------------------------------------------------------------
      -- Normalize_Key: Ensures the Key is exactly Block_Size bytes long.
      -- If Key > Block_Size, it hashes the key and pads it.
      -- If Key < Block_Size, it simply pads with 0s.
      -------------------------------------------------------------------------
      function Normalize_Key (Key : Byte_Array) return Byte_Array is
         Result : Byte_Array (1 .. Block_Size) := [others => 0];
      begin
         if Key'Length > Block_Size then
            -- Hash keys that are longer than the block size
            declare
               Hashed_Key : constant Byte_Array := Hash (Key);
            begin
               for I in Hashed_Key'Range loop
                  Result (1 + I - Hashed_Key'First) := Hashed_Key (I);
               end loop;
            end;
         else
            -- Directly copy keys that are shorter or equal
            for I in Key'Range loop
               Result (1 + I - Key'First) := Key (I);
            end loop;
         end if;
         return Result;
      end Normalize_Key;

      -------------------------------------------------------------------------
      -- Compute: The primary HMAC function logic.
      -- HMAC(K, m) = H((K' xor opad) || H((K' xor ipad) || m))
      -------------------------------------------------------------------------
      function Compute (Key : Byte_Array; Message : Byte_Array) return Byte_Array is
         K_Prime   : constant Byte_Array := Normalize_Key (Key);
         O_Key_Pad : Byte_Array (1 .. Block_Size);
         I_Key_Pad : Byte_Array (1 .. Block_Size);
      begin
         -- Prepare the inner and outer padded keys
         for I in K_Prime'Range loop
            O_Key_Pad (I) := K_Prime (I) xor Opad;
            I_Key_Pad (I) := K_Prime (I) xor Ipad;
         end loop;

         -- Perform the nested hashes
         declare
            Inner_Data : constant Byte_Array := I_Key_Pad & Message;
            Inner_Hash : constant Byte_Array := Hash (Inner_Data);
            Outer_Data : constant Byte_Array := O_Key_Pad & Inner_Hash;
         begin
            return Hash (Outer_Data);
         end;
      end Compute;

      -------------------------------------------------------------------------
      -- Compute_String: Casts strings to bytes and computes the HMAC.
      -------------------------------------------------------------------------
      function Compute_String (Key : String; Message : String) return Byte_Array is
         K_Bytes : Byte_Array (1 .. Key'Length);
         M_Bytes : Byte_Array (1 .. Message'Length);
      begin
         -- Map Characters to Bytes strictly (1 to 1 mapping)
         for I in Key'Range loop
            K_Bytes (1 + I - Key'First) := Byte (Character'Pos (Key (I)));
         end loop;
         
         for I in Message'Range loop
            M_Bytes (1 + I - Message'First) := Byte (Character'Pos (Message (I)));
         end loop;

         return Compute (K_Bytes, M_Bytes);
      end Compute_String;

   end Core;

end HMAC;
