pragma SPARK_Mode (On);

package body Prim_Mst_Lite with SPARK_Mode => On is
   function Mst_Weight (Edges : Graph; N : Vertex) return Total is
      Result : Total := 0;
      Cost : Weight;
   begin
      for V in 2 .. N loop
         Cost := Edges (1, V);
         if Cost = 0 then
            Cost := Edges (V, 1);
         end if;
         if Total (Cost) > Result then
            Result := Total (Cost);
         end if;
      end loop;
      return Result;
   end Mst_Weight;
end Prim_Mst_Lite;
