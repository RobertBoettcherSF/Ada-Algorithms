pragma SPARK_Mode (On);

package String_To_Integer_Atoi_Stub is
   Max_Digit_Values : constant := 6;
   subtype Digit is Natural range 0 .. 9;
   subtype Digit_Count is Positive range 1 .. Max_Digit_Values;
   subtype Parsed_Value is Natural range 0 .. 999_999;
   type Digit_Array is array (Digit_Count) of Digit;
   type Input is record
      Length : Digit_Count;
      Digit_Values : Digit_Array;
   end record;

   function To_Integer (Value : Input) return Parsed_Value
     with Global => null;
end String_To_Integer_Atoi_Stub;
