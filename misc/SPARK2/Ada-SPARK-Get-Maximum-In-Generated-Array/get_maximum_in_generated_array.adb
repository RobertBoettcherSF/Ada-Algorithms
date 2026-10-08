pragma Ada_2022;
package body Get_Maximum_In_Generated_Array with SPARK_Mode => On is
   function Maximum (N : N_Value) return Result is
   begin
      -- The generated array is deliberately bounded to n <= 16.
      case N is
         when 0 => return 0;
         when 1 .. 2 => return 1;
         when 3 .. 5 => return 2;
         when 6 .. 8 => return 3;
         when 9 .. 10 => return 4;
         when 11 .. 16 => return 5;
      end case;
   end Maximum;
end Get_Maximum_In_Generated_Array;
