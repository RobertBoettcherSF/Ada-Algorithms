package body Fletchers_Checksum is

   -------------------------------------------------
   -- Fletcher-16 Naive
   -------------------------------------------------
   function Fletcher_16_Naive (Data : Byte_Array) return Word16 is
      Sum1 : Word32 := 0;
      Sum2 : Word32 := 0;
   begin
      for B of Data loop
         Sum1 := (Sum1 + Word32 (B)) mod 255;
         Sum2 := (Sum2 + Sum1) mod 255;
      end loop;
      
      -- Shift Sum2 left by 8 bits and append Sum1
      return Word16 (Sum2) * 256 + Word16 (Sum1);
   end Fletcher_16_Naive;

   -------------------------------------------------
   -- Fletcher-16 Optimized
   -------------------------------------------------
   function Fletcher_16_Optimized (Data : Byte_Array) return Word16 is
      Sum1       : Word32 := 0;
      Sum2       : Word32 := 0;
      Chunk_Size : constant := 5000; -- Prevents 32-bit overflow before modulo
      I          : Positive := Data'First;
      End_Idx    : Integer;
   begin
      while I <= Data'Last loop
         if I + Chunk_Size - 1 < Data'Last then
            End_Idx := I + Chunk_Size - 1;
         else
            End_Idx := Data'Last;
         end if;

         -- Perform additions without intermediate modulos
         for J in I .. End_Idx loop
            Sum1 := Sum1 + Word32 (Data (J));
            Sum2 := Sum2 + Sum1;
         end loop;

         -- Apply modulo only at the end of the chunk
         Sum1 := Sum1 mod 255;
         Sum2 := Sum2 mod 255;
         
         I := End_Idx + 1;
      end loop;

      return Word16 (Sum2) * 256 + Word16 (Sum1);
   end Fletcher_16_Optimized;

   -------------------------------------------------
   -- Fletcher-32
   -------------------------------------------------
   function Fletcher_32 (Data : Word16_Array) return Word32 is
      Sum1 : Word64 := 0;
      Sum2 : Word64 := 0;
   begin
      -- Word64 prevents overflow up to extremely large arrays
      for W of Data loop
         Sum1 := (Sum1 + Word64 (W)) mod 65535;
         Sum2 := (Sum2 + Sum1) mod 65535;
      end loop;
      
      -- Shift Sum2 left by 16 bits and append Sum1
      return Word32 (Sum2) * 65536 + Word32 (Sum1);
   end Fletcher_32;

   -------------------------------------------------
   -- Fletcher-64
   -------------------------------------------------
   function Fletcher_64 (Data : Word32_Array) return Word64 is
      Sum1 : Word64 := 0;
      Sum2 : Word64 := 0;
   begin
      for W of Data loop
         Sum1 := (Sum1 + Word64 (W)) mod 4294967295;
         Sum2 := (Sum2 + Sum1) mod 4294967295;
      end loop;
      
      -- Shift Sum2 left by 32 bits and append Sum1
      return (Sum2 * 4294967296) + Sum1;
   end Fletcher_64;

   -------------------------------------------------
   -- Generate Check Bytes 16
   -------------------------------------------------
   function Generate_Check_Bytes_16 (Data : Byte_Array) return Check_Bytes_16 is
      Checksum : constant Word16 := Fletcher_16_Naive (Data);
      C0       : constant Word32 := Word32 (Checksum mod 256);
      C1       : constant Word32 := Word32 (Checksum / 256);
      CB0      : Word32;
      CB1      : Word32;
   begin
      CB0 := 255 - ((C0 + C1) mod 255);
      CB1 := 255 - ((C0 + CB0) mod 255);
      
      return (CB0 => Byte (CB0), CB1 => Byte (CB1));
   end Generate_Check_Bytes_16;

end Fletchers_Checksum;
