pragma Ada_2022;
package body Title_To_Number with SPARK_Mode => On is
   function Title_Number (Letter : Character) return Column is
   begin
      case Letter is
         when 'A' .. 'Z' =>
            return Character'Pos (Letter) - Character'Pos ('A') + 1;
         when others =>
            return 1;
      end case;
   end Title_Number;
end Title_To_Number;
