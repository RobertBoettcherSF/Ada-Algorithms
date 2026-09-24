pragma Ada_2022;

package body Implement_Trie with SPARK_Mode => On is
   function Same (A, B : Word) return Boolean is
   begin
      if A.Len /= B.Len then
         return False;
      end if;
      for J in Position loop
         if J <= A.Len and then A.Chars (J) /= B.Chars (J) then
            return False;
         end if;
      end loop;
      return True;
   end Same;

   procedure Insert (T : in out Trie; W : in Word) is
   begin
      if T.Used < Max_Words then
         T.Used := T.Used + 1;
         T.Words (T.Used) := W;
      end if;
   end Insert;

   function Contains (T : Trie; W : Word) return Boolean is
   begin
      for I in Word_Index loop
         if I <= T.Used and then Same (T.Words (I), W) then
            return True;
         end if;
      end loop;
      return False;
   end Contains;
end Implement_Trie;
