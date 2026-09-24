pragma SPARK_Mode (On);

package body Arranging_Coins is
   function Full_Rows (Value : Coins) return Rows is
      Remaining : Coins := Value;
      Result : Rows := 0;
   begin
      for Row in 1 .. 44_721 loop
         pragma Loop_Invariant (Result <= Row - 1);
         pragma Loop_Invariant (Remaining <= Value);
         exit when Remaining < Row;
         Remaining := Remaining - Row;
         Result := Result + 1;
      end loop;
      return Result;
   end Full_Rows;
end Arranging_Coins;
