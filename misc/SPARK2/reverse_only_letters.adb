pragma Ada_2022;

package body Reverse_Only_Letters with SPARK_Mode => On is
function Is_Letter (C : Character) return Boolean is
   begin
      return C in 'a' .. 'z' or else C in 'A' .. 'Z';
   end Is_Letter;

   procedure Reverse_Letters
     (Input  : Text;
      Length : Length_Type;
      Output : out Text) is
      Left  : Index := 1;
      Right : Length_Type := Length;
      Temp  : Character;
   begin
      Output := Input;
      while Length_Type (Left) < Right loop
         if Is_Letter (Output (Left)) then
            if Is_Letter (Output (Index (Right))) then
               Temp := Output (Left);
               Output (Left) := Output (Index (Right));
               Output (Index (Right)) := Temp;
               Left := Left + 1;
               Right := Right - 1;
            else
               Right := Right - 1;
            end if;
         else
            Left := Left + 1;
         end if;
      end loop;
   end Reverse_Letters;
end Reverse_Only_Letters;
