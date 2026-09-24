pragma SPARK_Mode (On);

package body Browser_History_Stub is
   function Back_Target
     (History : History_Array; Current : History_Index;
      Steps : Back_Steps) return Page_Id is
   begin
      if Steps >= Current - 1 then
         return History (History_Index'First);
      else
         return History (Current - Steps);
      end if;
   end Back_Target;
end Browser_History_Stub;
