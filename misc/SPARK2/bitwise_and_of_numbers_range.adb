pragma Ada_2022;
package body Bitwise_AND_Of_Numbers_Range with SPARK_Mode => On is
   function And_Range (Left, Right : Input) return Byte is
      Result : Byte := Byte'Last;
   begin
      for Value in Left .. Right loop
         Result := Result and Value;
      end loop;
      return Result;
   end And_Range;
end Bitwise_AND_Of_Numbers_Range;
