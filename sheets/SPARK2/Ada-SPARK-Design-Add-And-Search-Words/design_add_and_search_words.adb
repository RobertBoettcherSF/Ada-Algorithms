pragma Ada_2022;

package body Design_Add_And_Search_Words with SPARK_Mode => On is
   function Matches (W, P : Word) return Boolean is
   begin
      if W.Len /= P.Len then
         return False;
      end if;
      for J in Position loop
         if J <= W.Len and then P.Chars (J) /= '.' and then W.Chars (J) /= P.Chars (J) then
            return False;
         end if;
      end loop;
      return True;
   end Matches;

   procedure Add_Word (D : in out Dictionary; W : in Word) is
   begin
      if D.Used < Max_Words then
         D.Used := D.Used + 1;
         D.Words (D.Used) := W;
      end if;
   end Add_Word;

   function Search (D : Dictionary; Pattern : Word) return Boolean is
   begin
      for I in Word_Index loop
         if I <= D.Used and then Matches (D.Words (I), Pattern) then
            return True;
         end if;
      end loop;
      return False;
   end Search;
end Design_Add_And_Search_Words;
