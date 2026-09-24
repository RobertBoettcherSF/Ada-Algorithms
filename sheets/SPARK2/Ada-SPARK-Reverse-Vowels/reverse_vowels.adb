pragma Ada_2022;

package body Reverse_Vowels with SPARK_Mode => On is
   function Is_Vowel (C : Character) return Boolean is
   begin
      return C = 'a' or else C = 'e' or else C = 'i' or else C = 'o' or else C = 'u'
        or else C = 'A' or else C = 'E' or else C = 'I' or else C = 'O' or else C = 'U';
   end Is_Vowel;

   procedure Reverse_Vowels (Input : Text; Length : Length_Type;
                             Output : out Text; Output_Length : out Length_Type) is
      Left : Length_Type := 1;
      Right : Length_Type := Length;
      Temp : Character;
   begin
      Output := Input;
      while Left < Right loop
         pragma Loop_Invariant (Left in 1 .. 32 and then Right in 0 .. 32);
         if not Is_Vowel (Output (Index (Left))) then
            Left := Left + 1;
         elsif not Is_Vowel (Output (Index (Right))) then
            Right := Right - 1;
         else
            Temp := Output (Index (Left));
            Output (Index (Left)) := Output (Index (Right));
            Output (Index (Right)) := Temp;
            Left := Left + 1;
            Right := Right - 1;
         end if;
      end loop;
      Output_Length := Length;
   end Reverse_Vowels;
end Reverse_Vowels;
