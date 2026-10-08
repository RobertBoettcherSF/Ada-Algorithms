pragma SPARK_Mode (On);

package body Design_Twitter_Lite is
   function Feed_Size
     (Messages : Message_Array; Active : Active_Array) return Natural
   is
      pragma Unreferenced (Messages);
      Size : Natural := 0;
   begin
      for I in Active'Range loop
         if Active (I) then
            Size := Size + 1;
         end if;
      end loop;
      return Size;
   end Feed_Size;
end Design_Twitter_Lite;
