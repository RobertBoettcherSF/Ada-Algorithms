pragma Ada_2022;

package body Keyboard_Row with SPARK_Mode => On is
function Row (C : Character) return Row_Number is
   begin
      case C is
         when 'q' | 'w' | 'e' | 'r' | 't' | 'y' | 'u' | 'i' | 'o' | 'p'
            | 'Q' | 'W' | 'E' | 'R' | 'T' | 'Y' | 'U' | 'I' | 'O' | 'P' =>
            return 1;
         when 'a' | 's' | 'd' | 'f' | 'g' | 'h' | 'j' | 'k' | 'l'
            | 'A' | 'S' | 'D' | 'F' | 'G' | 'H' | 'J' | 'K' | 'L' =>
            return 2;
         when 'z' | 'x' | 'c' | 'v' | 'b' | 'n' | 'm'
            | 'Z' | 'X' | 'C' | 'V' | 'B' | 'N' | 'M' =>
            return 3;
         when others =>
            return 0;
      end case;
   end Row;

   function In_One_Row (Word : Text; Length : Length_Type) return Boolean is
      First : Row_Number := 0;
      Current : Row_Number;
   begin
      for I in Index loop
         exit when I > Length;
         Current := Row (Word (I));
         if Current = 0 then
            return False;
         elsif First = 0 then
            First := Current;
         elsif Current /= First then
            return False;
         end if;
      end loop;
      return True;
   end In_One_Row;
end Keyboard_Row;
