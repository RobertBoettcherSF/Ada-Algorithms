pragma Ada_2022;
package body Excel_Sheet_Column with SPARK_Mode => On is
   function Column_Number (Letter : Character) return Column is
   begin
      case Letter is
         when 'A' .. 'Z' =>
            return Character'Pos (Letter) - Character'Pos ('A') + 1;
         when others =>
            return 1;
      end case;
   end Column_Number;
end Excel_Sheet_Column;
