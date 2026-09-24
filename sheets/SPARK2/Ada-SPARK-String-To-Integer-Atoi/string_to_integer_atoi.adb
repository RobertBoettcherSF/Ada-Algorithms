pragma Ada_2022;

package body String_To_Integer_Atoi with SPARK_Mode => On is
   function To_Integer (Value : Input) return Parsed_Value is
      D : constant Digit_Array := Value.Digit_Values;
   begin
      case Value.Length is
         when 1 => return Parsed_Value (D (1));
         when 2 => return Parsed_Value (D (1) * 10 + D (2));
         when 3 => return Parsed_Value (D (1) * 100 + D (2) * 10 + D (3));
         when 4 => return Parsed_Value
           (D (1) * 1_000 + D (2) * 100 + D (3) * 10 + D (4));
         when 5 => return Parsed_Value
           (D (1) * 10_000 + D (2) * 1_000 + D (3) * 100
            + D (4) * 10 + D (5));
         when 6 => return Parsed_Value
           (D (1) * 100_000 + D (2) * 10_000 + D (3) * 1_000
            + D (4) * 100 + D (5) * 10 + D (6));
      end case;
   end To_Integer;
end String_To_Integer_Atoi;
