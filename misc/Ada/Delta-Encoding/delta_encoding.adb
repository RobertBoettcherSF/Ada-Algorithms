package body Delta_Encoding is

   -------------------------------------------------
   -- Arithmetic Delta Encoding (Differencing)
   -------------------------------------------------
   function Encode_Integer_Delta (Input : Integer_Array) return Integer_Array is
      Result : Integer_Array (Input'Range);
   begin
      if Input'Length = 0 then
         raise Empty_Input_Error with "Cannot encode an empty integer array.";
      end if;

      -- First element remains absolute
      Result (Input'First) := Input (Input'First);
      
      -- Calculate difference for subsequent elements
      for I in Input'First + 1 .. Input'Last loop
         Result (I) := Input (I) - Input (I - 1);
      end loop;
      
      return Result;
   end Encode_Integer_Delta;

   function Decode_Integer_Delta (Input : Integer_Array) return Integer_Array is
      Result : Integer_Array (Input'Range);
   begin
      if Input'Length = 0 then
         raise Empty_Input_Error with "Cannot decode an empty integer array.";
      end if;

      -- First element is absolute
      Result (Input'First) := Input (Input'First);
      
      -- Reconstruct subsequent elements
      for I in Input'First + 1 .. Input'Last loop
         Result (I) := Result (I - 1) + Input (I);
      end loop;
      
      return Result;
   end Decode_Integer_Delta;

   -------------------------------------------------
   -- Logical XOR Delta Encoding
   -------------------------------------------------
   function Encode_Byte_XOR_Delta (Input : Byte_Array) return Byte_Array is
      Result : Byte_Array (Input'Range);
   begin
      if Input'Length = 0 then
         raise Empty_Input_Error with "Cannot encode an empty byte array.";
      end if;

      Result (Input'First) := Input (Input'First);
      
      for I in Input'First + 1 .. Input'Last loop
         Result (I) := Input (I) xor Input (I - 1);
      end loop;
      
      return Result;
   end Encode_Byte_XOR_Delta;

   function Decode_Byte_XOR_Delta (Input : Byte_Array) return Byte_Array is
      Result : Byte_Array (Input'Range);
   begin
      if Input'Length = 0 then
         raise Empty_Input_Error with "Cannot decode an empty byte array.";
      end if;

      Result (Input'First) := Input (Input'First);
      
      for I in Input'First + 1 .. Input'Last loop
         -- XOR is its own inverse
         Result (I) := Result (I - 1) xor Input (I);
      end loop;
      
      return Result;
   end Decode_Byte_XOR_Delta;

end Delta_Encoding;
