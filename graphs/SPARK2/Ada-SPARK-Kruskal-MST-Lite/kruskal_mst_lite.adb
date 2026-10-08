pragma SPARK_Mode (On);

package body Kruskal_MST_Lite with SPARK_Mode => On is
   function Forest_Cost (Edges : Edge_List; Count : Edge_Count) return Natural is
      subtype Forest_Sum is Natural range 0 .. Capacity * Capacity;
      Total : Forest_Sum := 0;
   begin
      for I in 1 .. Count loop
         if Total <= Forest_Sum'Last - Edges (I).Cost then
            Total := Total + Edges (I).Cost;
         end if;
      end loop;
      return Total;
   end Forest_Cost;
end Kruskal_MST_Lite;
