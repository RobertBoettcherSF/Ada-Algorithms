pragma SPARK_Mode (On);

package body Alert_Using_Same_Key_Card_Stub is
   function Has_Three_Within_Hour
     (Swipes : Swipe_Times; Length : Swipe_Count) return Boolean is
   begin
      if Length < 3 then
         return False;
      end if;
      for I in Swipes'First .. Swipes'Last - 2 loop
         pragma Loop_Invariant (I >= Swipes'First);
         if I + 2 <= Length and then Swipes (I + 2) - Swipes (I) <= 3_600 then
            return True;
         end if;
      end loop;
      return False;
   end Has_Three_Within_Hour;
end Alert_Using_Same_Key_Card_Stub;
