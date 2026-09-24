pragma SPARK_Mode (On);

package body Design_HashMap_Stub is
   function Lookup (Map : Table; Search : Key) return Value is
      Result : Value := 0;
      Found : Boolean := False;
   begin
      for I in Map'Range loop
         if not Found and then Map (I).Present
           and then Map (I).Key_Value = Search
         then
            Result := Map (I).Stored_Value;
            Found := True;
         end if;
      end loop;
      return Result;
   end Lookup;
end Design_HashMap_Stub;
