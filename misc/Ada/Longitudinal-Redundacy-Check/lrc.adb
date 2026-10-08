-- lrc.adb
-- Implementation of the Longitudinal Redundancy Check (LRC) algorithms.

package body LRC is

   -- =========================================================================
   -- Variant 1: Standard XOR-based LRC
   -- =========================================================================
   function Calculate_XOR_LRC (Data : Byte_Array) return Byte is
      Result : Byte := 0;
   begin
      if Data'Length = 0 then
         raise Empty_Data_Error with "LRC cannot be calculated for an empty data set.";
      end if;

      for B of Data loop
         Result := Result xor B;
      end loop;
      
      return Result;
   end Calculate_XOR_LRC;

   function Verify_XOR_LRC (Data : Byte_Array; Expected : Byte) return Boolean is
   begin
      return Calculate_XOR_LRC (Data) = Expected;
   end Verify_XOR_LRC;


   -- =========================================================================
   -- Variant 2: Modbus ASCII style LRC (2's Complement of Sum)
   -- =========================================================================
   function Calculate_Modbus_LRC (Data : Byte_Array) return Byte is
      Sum : Byte := 0;
   begin
      if Data'Length = 0 then
         raise Empty_Data_Error with "LRC cannot be calculated for an empty data set.";
      end if;

      for B of Data loop
         -- Byte is a modular type, so addition naturally wraps around mod 256.
         Sum := Sum + B;
      end loop;
      
      -- In Ada modular arithmetic, unary minus computes the 2's complement.
      return -Sum;
   end Calculate_Modbus_LRC;

   function Verify_Modbus_LRC (Data : Byte_Array; Expected : Byte) return Boolean is
   begin
      return Calculate_Modbus_LRC (Data) = Expected;
   end Verify_Modbus_LRC;


   -- =========================================================================
   -- Variant 3: Odd Parity XOR-based LRC
   -- =========================================================================
   function Calculate_Odd_Parity_LRC (Data : Byte_Array) return Byte is
   begin
      -- Odd parity is strictly the bitwise complement (NOT) of the XOR sum (Even Parity).
      return not Calculate_XOR_LRC (Data);
   end Calculate_Odd_Parity_LRC;

   function Verify_Odd_Parity_LRC (Data : Byte_Array; Expected : Byte) return Boolean is
   begin
      return Calculate_Odd_Parity_LRC (Data) = Expected;
   end Verify_Odd_Parity_LRC;

end LRC;
