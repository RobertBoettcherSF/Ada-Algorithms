-- cyclic_redundancy_check.adb
-- Implementation of the Cyclic Redundancy Check (CRC) algorithm and its variants.

package body Cyclic_Redundancy_Check is

   -- =========================================================================
   -- Helpers (Reflection Algorithms)
   -- =========================================================================
   function Reflect_8 (Value : Unsigned_8) return Unsigned_8 is
      Result : Unsigned_8 := 0;
      Temp   : Unsigned_8 := Value;
   begin
      for I in 1 .. 8 loop
         Result := Shift_Left (Result, 1) or (Temp and 1);
         Temp   := Shift_Right (Temp, 1);
      end loop;
      return Result;
   end Reflect_8;

   function Reflect_32 (Value : Unsigned_32) return Unsigned_32 is
      Result : Unsigned_32 := 0;
      Temp   : Unsigned_32 := Value;
   begin
      for I in 1 .. 32 loop
         Result := Shift_Left (Result, 1) or (Temp and 1);
         Temp   := Shift_Right (Temp, 1);
      end loop;
      return Result;
   end Reflect_32;

   -- =========================================================================
   -- Variant 1: Bit-by-Bit Computation
   -- =========================================================================
   function Compute_Bit_By_Bit
     (Data   : Data_Array;
      Config : CRC_Config) return Unsigned_32
   is
      CRC : Unsigned_32 := Config.Init;
   begin
      if Config.Variant = Normal then
         -- Normal Variant: Shift Left, Process Most Significant Bit (MSB)
         for Byte of Data loop
            CRC := CRC xor Shift_Left (Unsigned_32 (Byte), 24);
            for Bit in 1 .. 8 loop
               if (CRC and 16#8000_0000#) /= 0 then
                  CRC := Shift_Left (CRC, 1) xor Config.Poly;
               else
                  CRC := Shift_Left (CRC, 1);
               end if;
            end loop;
         end loop;
      else 
         -- Reversed Variant: Shift Right, Process Least Significant Bit (LSB)
         for Byte of Data loop
            CRC := CRC xor Unsigned_32 (Byte);
            for Bit in 1 .. 8 loop
               if (CRC and 1) /= 0 then
                  CRC := Shift_Right (CRC, 1) xor Config.Poly;
               else
                  CRC := Shift_Right (CRC, 1);
               end if;
            end loop;
         end loop;
      end if;

      return CRC xor Config.Xor_Out;
   end Compute_Bit_By_Bit;

   -- =========================================================================
   -- Variant 2: Table Generator
   -- =========================================================================
   function Generate_Table (Config : CRC_Config) return CRC_Table is
      Table : CRC_Table;
      CRC   : Unsigned_32;
   begin
      for I in Unsigned_32'(0) .. 255 loop
         if Config.Variant = Normal then
            CRC := Shift_Left (I, 24);
            for Bit in 1 .. 8 loop
               if (CRC and 16#8000_0000#) /= 0 then
                  CRC := Shift_Left (CRC, 1) xor Config.Poly;
               else
                  CRC := Shift_Left (CRC, 1);
               end if;
            end loop;
         else -- Reversed
            CRC := I;
            for Bit in 1 .. 8 loop
               if (CRC and 1) /= 0 then
                  CRC := Shift_Right (CRC, 1) xor Config.Poly;
               else
                  CRC := Shift_Right (CRC, 1);
               end if;
            end loop;
         end if;
         Table (Unsigned_8 (I)) := CRC;
      end loop;
      return Table;
   end Generate_Table;

   -- =========================================================================
   -- Variant 3: Table-Driven Computation
   -- =========================================================================
   function Compute_Table_Driven
     (Data   : Data_Array;
      Config : CRC_Config;
      Table  : CRC_Table) return Unsigned_32
   is
      CRC   : Unsigned_32 := Config.Init;
      Index : Unsigned_8;
   begin
      if Config.Variant = Normal then
         -- Extract highest byte to use as index
         for Byte of Data loop
            Index := Unsigned_8 (Shift_Right (CRC, 24) and 16#FF#) xor Byte;
            CRC   := Shift_Left (CRC, 8) xor Table (Index);
         end loop;
      else 
         -- Extract lowest byte to use as index
         for Byte of Data loop
            Index := Unsigned_8 (CRC and 16#FF#) xor Byte;
            CRC   := Shift_Right (CRC, 8) xor Table (Index);
         end loop;
      end if;

      return CRC xor Config.Xor_Out;
   end Compute_Table_Driven;

end Cyclic_Redundancy_Check;
