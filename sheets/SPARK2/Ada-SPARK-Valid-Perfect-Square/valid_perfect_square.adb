pragma Ada_2022;
package body Valid_Perfect_Square with SPARK_Mode => On is
   function Is_Perfect_Square (N : Number) return Boolean is
   begin
      case N is
         when 0 | 1 | 4 | 9 | 16 | 25 | 36 | 49 | 64 | 81 | 100 =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Perfect_Square;
end Valid_Perfect_Square;
