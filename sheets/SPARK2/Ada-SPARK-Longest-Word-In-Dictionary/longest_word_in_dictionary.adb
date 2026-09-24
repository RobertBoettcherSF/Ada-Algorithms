pragma Ada_2022;

package body Longest_Word_In_Dictionary with SPARK_Mode => On is
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

   function Present (Words : Word_Array; Candidate : Word) return Boolean is
   begin
      for I in Word_Index loop
         if Same (Words (I), Candidate) then
            return True;
         end if;
      end loop;
      return False;
   end Present;

   function Complete (Words : Word_Array; Candidate : Word) return Boolean is
      Prefix : Word := Candidate;
   begin
      if Candidate.Len = 0 then
         return True;
      end if;
      for J in Position loop
         if J <= Candidate.Len then
            Prefix.Len := J;
            if not Present (Words, Prefix) then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Complete;

   function Longest_Length (Words : Word_Array) return Length_Range is
      Result : Length_Range := 0;
   begin
      for I in Word_Index loop
         if Words (I).Len > Result and then Complete (Words, Words (I)) then
            Result := Words (I).Len;
         end if;
      end loop;
      return Result;
   end Longest_Length;
end Longest_Word_In_Dictionary;
