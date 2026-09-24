pragma Ada_2022;

package body Map_Sum_Pairs with SPARK_Mode => On is
   function Has_Prefix (Prefix, Key : Word) return Boolean is
   begin
      if Prefix.Len > Key.Len then
         return False;
      end if;
      for J in Position loop
         if J <= Prefix.Len and then Prefix.Chars (J) /= Key.Chars (J) then
            return False;
         end if;
      end loop;
      return True;
   end Has_Prefix;

   function Sum (M : Map; Prefix : Word) return Integer is
      Result : Integer range -800 .. 800 := 0;
   begin
      for I in Map_Index loop
         pragma Loop_Invariant (Result in -100 * Integer (I - 1) .. 100 * Integer (I - 1));
         if Has_Prefix (Prefix, M (I).Key) then
            Result := Result + M (I).Value;
         end if;
      end loop;
      return Result;
   end Sum;
end Map_Sum_Pairs;
