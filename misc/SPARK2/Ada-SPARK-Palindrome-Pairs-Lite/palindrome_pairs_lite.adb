pragma Ada_2022;

package body Palindrome_Pairs_Lite with SPARK_Mode => On is
   function Reverse_Of (A, B : Word) return Boolean is
   begin
      if A.Len = 0 or else B.Len = 0 or else A.Len /= B.Len then
         return False;
      end if;
      for J in Position loop
         if J <= A.Len and then A.Chars (J) /= B.Chars (A.Len - J + 1) then
            return False;
         end if;
      end loop;
      return True;
   end Reverse_Of;

   function Count_Reverse_Pairs (Words : Word_Array) return Natural is
   begin
      return Boolean'Pos (Reverse_Of (Words (1), Words (2)))
        + Boolean'Pos (Reverse_Of (Words (2), Words (1)))
        + Boolean'Pos (Reverse_Of (Words (1), Words (3)))
        + Boolean'Pos (Reverse_Of (Words (3), Words (1)))
        + Boolean'Pos (Reverse_Of (Words (2), Words (3)))
        + Boolean'Pos (Reverse_Of (Words (3), Words (2)));
   end Count_Reverse_Pairs;
end Palindrome_Pairs_Lite;
