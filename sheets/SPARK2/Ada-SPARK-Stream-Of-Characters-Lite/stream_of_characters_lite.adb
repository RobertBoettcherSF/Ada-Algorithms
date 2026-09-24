pragma Ada_2022;

package body Stream_Of_Characters_Lite with SPARK_Mode => On is
   procedure Push (S : in out Stream; C : in Letter) is
   begin
      if S.Used < Max_Length then
         S.Used := S.Used + 1;
         S.Chars (S.Used) := C;
      else
         for J in Position range 1 .. Max_Length - 1 loop
            S.Chars (J) := S.Chars (J + 1);
         end loop;
         S.Chars (Max_Length) := C;
      end if;
   end Push;

   function Matches_Suffix (S : Stream; W : Word) return Boolean is
   begin
      if W.Len = 0 or else W.Len > S.Used then
         return False;
      end if;
      for J in Position loop
         if J <= W.Len and then S.Chars (S.Used - W.Len + J) /= W.Chars (J) then
            return False;
         end if;
      end loop;
      return True;
   end Matches_Suffix;

   function Query (S : Stream; Words : Word_Array) return Boolean is
   begin
      for I in Word_Index loop
         if Matches_Suffix (S, Words (I)) then
            return True;
         end if;
      end loop;
      return False;
   end Query;
end Stream_Of_Characters_Lite;
