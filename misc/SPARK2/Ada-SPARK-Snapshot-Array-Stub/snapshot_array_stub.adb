pragma SPARK_Mode (On);

package body Snapshot_Array_Stub is
   function Snapshot_Total
     (Values : Value_Array; Used : Used_Count) return Natural is
      Total : Natural range 0 .. 4000 := 0;
   begin
      for I in Array_Index loop
         if I <= Used then
            Total := Total + Values (I);
         end if;
      end loop;
      return Total;
   end Snapshot_Total;
end Snapshot_Array_Stub;
