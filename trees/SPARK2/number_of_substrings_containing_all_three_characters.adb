pragma SPARK_Mode (On);
package body Number_Of_Substrings_Containing_All_Three_Characters is
   function Count (Values : Symbol_Array) return Answer is
      Total : Answer := 0;
      Seen_0 : Boolean;
      Seen_1 : Boolean;
      Seen_2 : Boolean;
   begin
      for Start in Index loop
         Seen_0 := False;
         Seen_1 := False;
         Seen_2 := False;
         for Finish in Index loop
            if Finish >= Start then
               if Values (Finish) = 0 then Seen_0 := True; end if;
               if Values (Finish) = 1 then Seen_1 := True; end if;
               if Values (Finish) = 2 then Seen_2 := True; end if;
               if Seen_0 and then Seen_1 and then Seen_2 and then Total /= Answer'Last then
                  Total := Total + 1;
               end if;
            end if;
         end loop;
      end loop;
      return Total;
   end Count;
end Number_Of_Substrings_Containing_All_Three_Characters;
