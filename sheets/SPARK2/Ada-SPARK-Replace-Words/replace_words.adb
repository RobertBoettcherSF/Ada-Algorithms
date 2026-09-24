pragma Ada_2022;

package body Replace_Words with SPARK_Mode => On is
   function Prefix (Root, Token : Word) return Boolean is
   begin
      if Root.Len > Token.Len then
         return False;
      end if;
      for J in Position loop
         if J <= Root.Len and then Root.Chars (J) /= Token.Chars (J) then
            return False;
         end if;
      end loop;
      return True;
   end Prefix;

   function Replace (Token : Word; Roots : Word_Array) return Word is
      Result : Word := Token;
      Best : Length_Range := Token.Len;
   begin
      for I in Word_Index loop
         if Roots (I).Len > 0 and then Prefix (Roots (I), Token) and then Roots (I).Len < Best then
            Result := Roots (I);
            Best := Roots (I).Len;
         end if;
      end loop;
      return Result;
   end Replace;
end Replace_Words;
