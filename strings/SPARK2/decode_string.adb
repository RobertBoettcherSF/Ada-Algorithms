pragma Ada_2022;

package body Decode_String with SPARK_Mode => On is
   function At_Char (Symbol : Character; Count : Repeat_Count; I : Position) return Character is
   begin
      if I <= Count then return Symbol; else return ' '; end if;
   end At_Char;

   function Repeat_Symbol (Symbol : Character; Count : Repeat_Count) return Text is
   begin
      return (1 => At_Char (Symbol, Count, 1), 2 => At_Char (Symbol, Count, 2),
              3 => At_Char (Symbol, Count, 3), 4 => At_Char (Symbol, Count, 4),
              5 => At_Char (Symbol, Count, 5), 6 => At_Char (Symbol, Count, 6),
              7 => At_Char (Symbol, Count, 7), 8 => At_Char (Symbol, Count, 8));
   end Repeat_Symbol;
end Decode_String;
