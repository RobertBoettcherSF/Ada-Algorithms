pragma SPARK_Mode (On);

package body Reversed_Bits is
   function Reversed (Value : Byte) return Byte is
      Work : Byte := Value;
      Result : Byte := 0;
   begin
      for Bit in 1 .. 8 loop
         Result := Result * 2 + Work mod 2;
         Work := Work / 2;
      end loop;
      return Result;
   end Reversed;
end Reversed_Bits;
