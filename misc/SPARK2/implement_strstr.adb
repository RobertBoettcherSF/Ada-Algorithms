pragma Ada_2022;
package body Implement_StrStr with SPARK_Mode => On is
   function Find (Hay : Haystack; Need : Needle) return Result_Index is
      Match : Boolean;
   begin
      for Start in Hay_Index range 1 .. Haystack_Length - Needle_Length + 1 loop
         Match := True;
         for Offset in Needle_Index loop
            if Hay (Start + Offset - 1) /= Need (Offset) then
               Match := False;
            end if;
         end loop;
         if Match then return Start; end if;
      end loop;
      return 0;
   end Find;
end Implement_StrStr;
