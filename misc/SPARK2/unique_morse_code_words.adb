pragma Ada_2022;

package body Unique_Morse_Code_Words with SPARK_Mode => On is
   function All_Unique (Codes : Code_Array) return Boolean is
   begin
      return Codes (1) /= Codes (2) and then Codes (1) /= Codes (3)
        and then Codes (1) /= Codes (4) and then Codes (2) /= Codes (3)
        and then Codes (2) /= Codes (4) and then Codes (3) /= Codes (4);
   end All_Unique;
end Unique_Morse_Code_Words;
