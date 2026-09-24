package body Redundancy_Checks is
   use Interfaces;

   ----------------------------------------------------------
   -- Calculate_Even_Parity
   ----------------------------------------------------------
   function Calculate_Even_Parity (Data : Byte) return Byte is
      Count : Natural := 0;
      Temp  : Byte := Data;
   begin
      -- Count the number of set bits (1s)
      for I in 1 .. 8 loop
         if (Temp and 1) = 1 then
            Count := Count + 1;
         end if;
         Temp := Temp / 2;
      end loop;
      
      -- If odd number of 1s, we need a 1 to make it even.
      return Byte (Count mod 2);
   end Calculate_Even_Parity;

   ----------------------------------------------------------
   -- Calculate_Odd_Parity
   ----------------------------------------------------------
   function Calculate_Odd_Parity (Data : Byte) return Byte is
   begin
      -- Odd parity is the exact inverse of even parity
      if Calculate_Even_Parity (Data) = 1 then
         return 0;
      else
         return 1;
      end if;
   end Calculate_Odd_Parity;

   ----------------------------------------------------------
   -- Calculate_LRC
   ----------------------------------------------------------
   function Calculate_LRC (Data : Byte_Array) return Byte is
      Result : Byte := 0;
   begin
      if Data'Length = 0 then
         raise Empty_Data_Error;
      end if;
      
      for I in Data'Range loop
         Result := Result xor Data (I);
      end loop;
      
      return Result;
   end Calculate_LRC;

   ----------------------------------------------------------
   -- Calculate_Checksum_8
   ----------------------------------------------------------
   function Calculate_Checksum_8 (Data : Byte_Array) return Byte is
      Result : Integer := 0;
   begin
      if Data'Length = 0 then
         raise Empty_Data_Error;
      end if;
      
      for I in Data'Range loop
         Result := (Result + Integer (Data (I))) mod 256;
      end loop;
      
      return Byte (Result);
   end Calculate_Checksum_8;

   ----------------------------------------------------------
   -- Calculate_CRC32
   ----------------------------------------------------------
   function Calculate_CRC32 (Data : Byte_Array) return Interfaces.Unsigned_32 is
      CRC        : Unsigned_32 := 16#FFFF_FFFF#;
      Polynomial : constant Unsigned_32 := 16#EDB8_8320#;
   begin
      for I in Data'Range loop
         CRC := CRC xor Unsigned_32 (Data (I));
         
         for J in 1 .. 8 loop
            if (CRC and 1) /= 0 then
               CRC := (Shift_Right (CRC, 1)) xor Polynomial;
            else
               CRC := Shift_Right (CRC, 1);
            end if;
         end loop;
      end loop;
      
      return not CRC;
   end Calculate_CRC32;

   ----------------------------------------------------------
   -- Calculate_Adler32
   ----------------------------------------------------------
   function Calculate_Adler32 (Data : Byte_Array) return Interfaces.Unsigned_32 is
      MOD_ADLER : constant Unsigned_32 := 65521;
      A         : Unsigned_32 := 1;
      B         : Unsigned_32 := 0;
   begin
      for I in Data'Range loop
         A := (A + Unsigned_32 (Data (I))) mod MOD_ADLER;
         B := (B + A) mod MOD_ADLER;
      end loop;
      
      return Shift_Left (B, 16) or A;
   end Calculate_Adler32;

end Redundancy_Checks;
