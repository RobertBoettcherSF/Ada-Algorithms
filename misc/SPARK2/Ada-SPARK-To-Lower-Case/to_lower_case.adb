pragma Ada_2022;

package body To_Lower_Case with SPARK_Mode => On is
function Lower (C : Character) return Character is
   begin
      if C in 'A' .. 'Z' then
         return Character'Val (Character'Pos (C) + 32);
      else
         return C;
      end if;
   end Lower;

   procedure Lower_Case
     (Input  : Text;
      Length : Length_Type;
      Output : out Text) is
   begin
      Output := Input;
      for I in Index loop
         exit when I > Length;
         Output (I) := Lower (Input (I));
      end loop;
   end Lower_Case;
end To_Lower_Case;
