pragma SPARK_Mode (On);

package body The_Skyline_Problem_Lite is
   function Skyline_Height (Buildings : Building_Array) return Height is
      Tallest : Height := 0;
   begin
      for I in Buildings'Range loop
         if Buildings (I) > Tallest then
            Tallest := Buildings (I);
         end if;
      end loop;
      return Tallest;
   end Skyline_Height;
end The_Skyline_Problem_Lite;
