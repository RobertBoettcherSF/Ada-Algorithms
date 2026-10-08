pragma Ada_2022;

package body Strstr_Naive with SPARK_Mode => On is
   function Search (Text : Text_Array; Pattern : Pattern_Array)
     return Search_Result is
      Matches : Boolean;
   begin
      for Start in Text_Index range 1 .. Text_Length - Pattern_Length + 1 loop
         Matches := True;
         for Offset in Pattern_Index loop
            if Text (Text_Index (Start + Offset - 1)) /= Pattern (Offset) then
               Matches := False;
               exit;
            end if;
         end loop;
         if Matches then
            return Search_Result (Start);
         end if;
      end loop;
      return 0;
   end Search;
end Strstr_Naive;
