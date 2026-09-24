pragma SPARK_Mode (On);

package body Time_Map_Stub is
   function Value_At
     (Entries : Entry_Array; Used : Used_Count;
      Query_Time : Timestamp) return Stored_Value is
      Best_Time : Timestamp := 0;
      Best_Value : Stored_Value := No_Value;
      Found : Boolean := False;
   begin
      for I in Entry_Index loop
         if I <= Used and then Entries (I).Stamp <= Query_Time then
            if not Found or else Entries (I).Stamp >= Best_Time then
               Best_Time := Entries (I).Stamp;
               Best_Value := Entries (I).Value;
               Found := True;
            end if;
         end if;
      end loop;
      return Best_Value;
   end Value_At;
end Time_Map_Stub;
