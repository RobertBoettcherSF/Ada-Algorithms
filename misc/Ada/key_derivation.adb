package body Key_Derivation is

   function To_Bytes (S : String) return Byte_Array is
      Result : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         Result (I - S'First + 1) := Character'Pos (S (I));
      end loop;
      return Result;
   end To_Bytes;

   function To_String (B : Byte_Array) return String is
      Result : String (1 .. B'Length);
   begin
      for I in B'Range loop
         Result (I - B'First + 1) := Character'Val (B (I));
      end loop;
      return Result;
   end To_String;

   -- Simulated cryptographic Hash function (32-byte output)
   -- Provides basic avalanche effect for self-contained demonstration.
   function Hash (Message : Byte_Array) return Byte_Array is
      Result : Byte_Array (1 .. Hash_Output_Length) := [others => 16#C5#];
      Prime  : constant Byte := 16#3D#;
   begin
      if Message'Length > 0 then
         for I in Message'Range loop
            for J in Result'Range loop
               Result (J) := (Result (J) xor Message (I)) * Prime + Byte (J);
            end loop;
            -- Avalanche step to mix state
            for J in 1 .. Result'Last - 1 loop
               Result (J + 1) := Result (J + 1) xor Result (J);
            end loop;
            Result (1) := Result (1) xor Result (Result'Last);
         end loop;
      end if;
      return Result;
   end Hash;

   -- Standard HMAC construction using the local Hash function
   function HMAC (Key : Byte_Array; Message : Byte_Array) return Byte_Array is
      Block_Size   : constant Positive := 64;
      Actual_Key   : Byte_Array (1 .. Block_Size) := [others => 0];
      O_Pad, I_Pad : Byte_Array (1 .. Block_Size);
   begin
      -- Shorten long keys via hash
      if Key'Length > Block_Size then
         declare
            H : constant Byte_Array := Hash (Key);
         begin
            Actual_Key (1 .. H'Length) := H;
         end;
      else
         if Key'Length > 0 then
            Actual_Key (1 .. Key'Length) := Key;
         end if;
      end if;

      -- Construct padding
      for I in 1 .. Block_Size loop
         O_Pad (I) := Actual_Key (I) xor 16#5C#;
         I_Pad (I) := Actual_Key (I) xor 16#36#;
      end loop;

      -- Calculate HMAC = Hash(O_Pad || Hash(I_Pad || Message))
      return Hash (O_Pad & Hash (I_Pad & Message));
   end HMAC;

   function PBKDF2
     (Password   : Byte_Array;
      Salt       : Byte_Array;
      Iterations : Positive;
      Length     : Positive) return Byte_Array
   is
      Blocks_Needed : constant Positive := (Length + Hash_Output_Length - 1) / Hash_Output_Length;
      Result        : Byte_Array (1 .. Blocks_Needed * Hash_Output_Length);
      U, T          : Byte_Array (1 .. Hash_Output_Length);
      Index_Bytes   : Byte_Array (1 .. 4);
      Val           : Natural;
   begin
      if Length > Maximum_Output_Length then
         raise Invalid_Length_Error;
      end if;

      for Block_Index in 1 .. Blocks_Needed loop
         -- Encode block index as 4-byte big-endian integer
         Val := Block_Index;
         Index_Bytes (4) := Byte (Val mod 256); Val := Val / 256;
         Index_Bytes (3) := Byte (Val mod 256); Val := Val / 256;
         Index_Bytes (2) := Byte (Val mod 256); Val := Val / 256;
         Index_Bytes (1) := Byte (Val mod 256);

         -- U_1 = HMAC(Password, Salt || Index)
         U := HMAC (Password, Salt & Index_Bytes);
         T := U;

         -- U_c = HMAC(Password, U_{c-1})
         for Iter in 2 .. Iterations loop
            U := HMAC (Password, U);
            for J in T'Range loop
               T (J) := T (J) xor U (J);
            end loop;
         end loop;

         -- Append block result
         Result ((Block_Index - 1) * Hash_Output_Length + 1 .. Block_Index * Hash_Output_Length) := T;
      end loop;

      return Result (1 .. Length);
   end PBKDF2;

   function HKDF_Extract
     (Salt : Byte_Array;
      IKM  : Byte_Array) return Byte_Array
   is
   begin
      -- If salt is empty, use an array of zeros as salt (per RFC 5869)
      if Salt'Length = 0 then
         return HMAC (Byte_Array'[1 .. Hash_Output_Length => 0], IKM);
      else
         return HMAC (Salt, IKM);
      end if;
   end HKDF_Extract;

   function HKDF_Expand
     (PRK    : Byte_Array;
      Info   : Byte_Array;
      Length : Positive) return Byte_Array
   is
      Blocks_Needed : Positive;
      Counter       : Byte := 1;
   begin
      if PRK'Length < Hash_Output_Length then
         raise Invalid_Key_Error;
      end if;
      
      if Length > Maximum_Output_Length then
         raise Invalid_Length_Error;
      end if;

      Blocks_Needed := (Length + Hash_Output_Length - 1) / Hash_Output_Length;

      declare
         Result : Byte_Array (1 .. Blocks_Needed * Hash_Output_Length);
         Last_T : Byte_Array (1 .. Hash_Output_Length);
      begin
         -- T(1) = HMAC(PRK, Info | 0x01)
         Last_T := HMAC (PRK, Info & Byte_Array'[1 => Counter]);
         Result (1 .. Hash_Output_Length) := Last_T;
         Counter := Counter + 1;

         -- T(N) = HMAC(PRK, T(N-1) | Info | N)
         for I in 2 .. Blocks_Needed loop
            Last_T := HMAC (PRK, Last_T & Info & Byte_Array'[1 => Counter]);
            Result ((I - 1) * Hash_Output_Length + 1 .. I * Hash_Output_Length) := Last_T;
            Counter := Counter + 1;
         end loop;

         return Result (1 .. Length);
      end;
   end HKDF_Expand;

   function Simple_KDF
     (Secret : Byte_Array;
      Info   : Byte_Array;
      Length : Positive) return Byte_Array
   is
      Blocks_Needed : constant Positive := (Length + Hash_Output_Length - 1) / Hash_Output_Length;
      Result        : Byte_Array (1 .. Blocks_Needed * Hash_Output_Length);
      Counter_Bytes : Byte_Array (1 .. 4);
      Val           : Natural;
   begin
      if Length > Maximum_Output_Length then
         raise Invalid_Length_Error;
      end if;

      for Block_Index in 1 .. Blocks_Needed loop
         -- Encode block index
         Val := Block_Index;
         Counter_Bytes (4) := Byte (Val mod 256); Val := Val / 256;
         Counter_Bytes (3) := Byte (Val mod 256); Val := Val / 256;
         Counter_Bytes (2) := Byte (Val mod 256); Val := Val / 256;
         Counter_Bytes (1) := Byte (Val mod 256);

         -- Hash (Secret || Counter || Info)
         Result ((Block_Index - 1) * Hash_Output_Length + 1 .. Block_Index * Hash_Output_Length) :=
           Hash (Secret & Counter_Bytes & Info);
      end loop;

      return Result (1 .. Length);
   end Simple_KDF;

end Key_Derivation;
