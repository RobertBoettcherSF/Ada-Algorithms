pragma SPARK_Mode (On);

package body My_Calendar_Stub is
   function Can_Book
     (Events : Event_Array; Used : Used_Count;
      New_Event : Event) return Boolean is
   begin
      for I in Event_Index loop
         if I <= Used then
            if New_Event.Start_Time < Events (I).Finish_Time
              and then Events (I).Start_Time < New_Event.Finish_Time
            then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Can_Book;
end My_Calendar_Stub;
