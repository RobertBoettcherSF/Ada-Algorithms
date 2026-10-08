pragma SPARK_Mode (On);

package body Topological_Sort_Lite with SPARK_Mode => On is
   function Is_Valid_Order
     (Edges : Graph; Order : Order_Array; N : Vertex) return Boolean is
   begin
      for I in Vertex loop
         if I <= N then
            for J in Vertex loop
               if J <= N and then J > I then
                  if Edges (Order (J), Order (I)) then
                     return False;
                  end if;
               end if;
            end loop;
         end if;
      end loop;
      return True;
   end Is_Valid_Order;
end Topological_Sort_Lite;
